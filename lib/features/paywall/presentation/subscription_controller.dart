import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/subscription_repository.dart';
import '../domain/subscription.dart';

/// Comprar y restaurar. Con la suscripción activa, el router sale solo del paywall.
class SubscriptionController extends AsyncNotifier<void> {
  @override
  void build() {}

  /// false si el usuario cancela la compra.
  Future<bool> purchase(PlanOption plan) =>
      _run(() => ref.read(subscriptionRepositoryProvider).purchase(plan));

  /// false si el Apple ID no tiene ninguna suscripción activa.
  Future<bool> restore() =>
      _run(ref.read(subscriptionRepositoryProvider).restore);

  Future<bool> _run(Future<bool> Function() action) async {
    state = const AsyncLoading();
    try {
      final result = await action();
      state = const AsyncData(null);
      return result;
    } catch (e, s) {
      state = AsyncError(e, s);
      return false;
    }
  }
}

final subscriptionControllerProvider =
    AsyncNotifierProvider<SubscriptionController, void>(
      SubscriptionController.new,
    );

/// Mensaje para un error de compra o restauración.
String purchaseErrorMessage(Object error) => switch (error) {
  PurchaseException(failure: PurchaseFailure.network) =>
    'No connection. Check your internet and try again.',
  PurchaseException(failure: PurchaseFailure.pending) =>
    'Your purchase is pending approval. You’ll get access once it’s approved.',
  PurchaseException(failure: PurchaseFailure.notAllowed) =>
    'Purchases aren’t allowed on this iPhone. Check Screen Time restrictions.',
  _ => 'Something went wrong. Please try again.',
};
