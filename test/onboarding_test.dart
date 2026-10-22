import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:travio_app/core/constants/currencies.dart';
import 'package:travio_app/features/paywall/domain/subscription.dart';
import 'package:travio_app/features/paywall/presentation/paywall_screen.dart';

import 'test_app.dart';

void main() {
  testWidgets(
    'primer arranque: onboarding → sign in → paywall → compra, y no vuelve a salir',
    (tester) async {
      final profiles = FakeUserProfileRepository();
      final subscription = FakeSubscriptionRepository(active: false);
      await tester.pumpWidget(
        await testApp({}, profiles: profiles, subscription: subscription),
      );
      await tester.pumpAndSettle();
      expect(find.text('Convert in seconds, anywhere.'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Know what every trip costs.'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Your home currency'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'swiss');
      await tester.pump();
      await tester.tap(find.text('Swiss Franc'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Continue with Apple'), findsOneWidget);

      await tester.ensureVisible(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text('Know what every trip really costs.'), findsOneWidget);
      expect(profiles.homeCurrencies['test-user'], 'CHF');
      expect(find.text('SAVE 16%'), findsOneWidget);
      expect(find.text('7 days free · US\$2.50/mo'), findsOneWidget);

      // Sin suscripción no se puede salir del paywall.
      final router = GoRouter.of(tester.element(find.byType(PaywallScreen)));
      router.go('/trips');
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Weekly'));
      await tester.tap(find.text('Weekly'));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Subscribe'), 200);
      expect(find.text('Subscribe'), findsOneWidget);
      await tester.ensureVisible(find.text('Annual'));
      await tester.tap(find.text('Annual'));
      await tester.pump();
      await tester.ensureVisible(find.text('Start 7-day free trial'));
      await tester.tap(find.text('Start 7-day free trial'));
      await tester.pumpAndSettle();
      expect(subscription.purchased, [r'$rc_annual']);
      expect(find.byType(PaywallScreen), findsNothing);
      expect(find.text('Convert'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isTrue);
      expect(prefs.getString('home_currency'), 'CHF');

      // Reabrir la app con sesión iniciada: entra directo a Convert.
      await tester.pumpWidget(
        await testApp({
          'onboarding_completed': true,
        }, auth: FakeAuthRepository(uid: 'test-user')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Convert in seconds, anywhere.'), findsNothing);
      expect(find.text('Convert'), findsOneWidget);
    },
  );

  testWidgets('onboarding hecho pero sin sesión: abre en Sign in', (
    tester,
  ) async {
    await tester.pumpWidget(await testApp({'onboarding_completed': true}));
    await tester.pumpAndSettle();
    expect(find.text('Every currency.\nEvery trip.'), findsOneWidget);
  });

  testWidgets('restaurar sin suscripción avisa y sigue en el paywall', (
    tester,
  ) async {
    await tester.pumpWidget(
      await testApp(
        {'onboarding_completed': true},
        auth: FakeAuthRepository(uid: 'test-user'),
        subscription: FakeSubscriptionRepository(active: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(
      find.text('No active subscription found for this Apple ID.'),
      findsOneWidget,
    );
    expect(find.byType(PaywallScreen), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Apple'), findsOneWidget);
  });

  test('ahorro del anual frente al mensual', () {
    PlanOption plan(PlanPeriod period, double price) => PlanOption(
      id: period.name,
      period: period,
      price: '\$price',
      priceValue: price,
    );
    expect(
      annualSaving([
        plan(PlanPeriod.annual, 29.99),
        plan(PlanPeriod.monthly, 2.99),
      ]),
      16,
    );
    expect(annualSaving([plan(PlanPeriod.annual, 29.99)]), isNull);
    expect(
      annualSaving([
        plan(PlanPeriod.annual, 40),
        plan(PlanPeriod.monthly, 2.99),
      ]),
      isNull,
    );
  });

  test('moneda sugerida según la región', () {
    expect(suggestedCurrency('es_ES').code, 'EUR');
    expect(suggestedCurrency('en_US').code, 'USD');
    expect(suggestedCurrency('ja_JP').code, 'JPY');
    expect(suggestedCurrency('xx_YY').code, 'USD');
  });
}
