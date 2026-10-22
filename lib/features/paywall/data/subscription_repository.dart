import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../core/constants/revenuecat.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/subscription.dart';

/// Errores de compra que la pantalla explica al usuario.
enum PurchaseFailure { network, pending, notAllowed, other }

class PurchaseException implements Exception {
  const PurchaseException(this.failure);

  final PurchaseFailure failure;
}

/// Suscripciones con RevenueCat. El usuario de RevenueCat es el uid de Firebase,
/// así la suscripción sigue a la cuenta y no al iPhone.
class SubscriptionRepository {
  /// Una vez al arrancar, antes de runApp.
  static Future<void> configure({String? uid}) async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(
      PurchasesConfiguration(revenueCatApiKey)..appUserID = uid,
    );
  }

  Future<void> logIn(String uid) => Purchases.logIn(uid);

  /// Resultado de comprar o restaurar: llega antes que el aviso del listener de RevenueCat,
  /// así el paywall da paso a la app en cuanto termina la compra.
  final _ownUpdates = StreamController<CustomerInfo>.broadcast();

  /// El estado actual (de la caché del SDK si no hay conexión) y cada cambio:
  /// compras, renovaciones, cancelaciones o caducidad.
  Stream<Subscription> watch() {
    late final StreamController<Subscription> controller;
    void onUpdate(CustomerInfo info) => controller.add(_subscription(info));
    StreamSubscription<CustomerInfo>? own;
    controller = StreamController(
      onListen: () async {
        Purchases.addCustomerInfoUpdateListener(onUpdate);
        own = _ownUpdates.stream.listen(onUpdate);
        try {
          controller.add(_subscription(await Purchases.getCustomerInfo()));
        } catch (e, s) {
          controller.addError(e, s);
        }
      },
      onCancel: () {
        Purchases.removeCustomerInfoUpdateListener(onUpdate);
        own?.cancel();
      },
    );
    return controller.stream;
  }

  /// Planes de la oferta actual de RevenueCat, en el orden del paywall.
  Future<List<PlanOption>> plans() async {
    final offering = (await Purchases.getOfferings()).current;
    if (offering == null) return const [];
    final packages = {
      PlanPeriod.annual: offering.annual,
      PlanPeriod.monthly: offering.monthly,
      PlanPeriod.weekly: offering.weekly,
    };
    final products = [
      for (final p in packages.values)
        if (p != null) p.storeProduct.identifier,
    ];
    // Apple da una sola prueba por grupo de suscripción: quien ya la usó no la ve.
    final eligibility =
        await Purchases.checkTrialOrIntroductoryPriceEligibility(products);
    return [
      for (final MapEntry(key: period, value: package) in packages.entries)
        if (package != null)
          PlanOption(
            id: package.identifier,
            period: period,
            price: package.storeProduct.priceString,
            priceValue: package.storeProduct.price,
            pricePerMonth: package.storeProduct.pricePerMonthString,
            trialDays:
                eligibility[package.storeProduct.identifier]?.status ==
                    IntroEligibilityStatus.introEligibilityStatusEligible
                ? _trialDays(package.storeProduct.introductoryPrice)
                : null,
          ),
    ];
  }

  /// Compra el plan. false si el usuario la cancela.
  Future<bool> purchase(PlanOption plan) async {
    final offering = (await Purchases.getOfferings()).current;
    final package = offering?.getPackage(plan.id);
    if (package == null) {
      throw const PurchaseException(PurchaseFailure.other);
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _ownUpdates.add(result.customerInfo);
      return _subscription(result.customerInfo).active;
    } on PlatformException catch (e) {
      return switch (PurchasesErrorHelper.getErrorCode(e)) {
        PurchasesErrorCode.purchaseCancelledError => false,
        PurchasesErrorCode.paymentPendingError => throw const PurchaseException(
          PurchaseFailure.pending,
        ),
        PurchasesErrorCode.purchaseNotAllowedError =>
          throw const PurchaseException(PurchaseFailure.notAllowed),
        PurchasesErrorCode.networkError ||
        PurchasesErrorCode.offlineConnectionError =>
          throw const PurchaseException(PurchaseFailure.network),
        _ => throw const PurchaseException(PurchaseFailure.other),
      };
    }
  }

  /// true si el Apple ID tiene una suscripción activa.
  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      _ownUpdates.add(info);
      return _subscription(info).active;
    } on PlatformException catch (e) {
      throw PurchaseException(switch (PurchasesErrorHelper.getErrorCode(e)) {
        PurchasesErrorCode.networkError ||
        PurchasesErrorCode.offlineConnectionError => PurchaseFailure.network,
        _ => PurchaseFailure.other,
      });
    }
  }

  /// Customer Center de RevenueCat: cambiar o cancelar plan, reembolsos, restaurar.
  Future<void> showCustomerCenter() => RevenueCatUI.presentCustomerCenter();

  static Subscription _subscription(CustomerInfo info) {
    final pro = info.entitlements.all[proEntitlement];
    if (pro == null || !pro.isActive) return Subscription.none;
    final product = pro.productIdentifier.toLowerCase();
    return Subscription(
      active: true,
      period: product.contains('week')
          ? PlanPeriod.weekly
          : product.contains('month')
          ? PlanPeriod.monthly
          : PlanPeriod.annual,
      trial: pro.periodType == PeriodType.trial,
      willRenew: pro.willRenew,
      expiresAt: DateTime.tryParse(pro.expirationDate ?? '')?.toLocal(),
    );
  }

  static int? _trialDays(IntroductoryPrice? intro) {
    if (intro == null || intro.price > 0) return null;
    final days = switch (intro.periodUnit) {
      PeriodUnit.day => 1,
      PeriodUnit.week => 7,
      PeriodUnit.month => 30,
      PeriodUnit.year => 365,
      PeriodUnit.unknown => 0,
    };
    final total = days * intro.periodNumberOfUnits;
    return total > 0 ? total : null;
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(),
);

/// Suscripción de la cuenta con sesión iniciada.
final subscriptionProvider = StreamProvider<Subscription>((ref) async* {
  final uid = ref.watch(authUidProvider).value;
  if (uid == null) {
    yield Subscription.none;
    return;
  }
  final repository = ref.watch(subscriptionRepositoryProvider);
  try {
    await repository.logIn(uid);
  } catch (_) {
    // Sin conexión: sigue con el usuario ya identificado y su estado en caché.
  }
  yield* repository.watch();
});

final plansProvider = FutureProvider<List<PlanOption>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).plans(),
);
