import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  Future<FakeUserProfileRepository> openYou(
    WidgetTester tester, {
    FakeSubscriptionRepository? subscription,
  }) async {
    tester.view.physicalSize = const Size(
      1170,
      2532,
    ); // iPhone, para que quepa toda la pantalla
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final profiles = FakeUserProfileRepository()
      ..homeCurrencies['test-user'] = 'EUR';
    await tester.pumpWidget(
      await testApp(
        {'onboarding_completed': true},
        auth: FakeAuthRepository(uid: 'test-user'),
        profiles: profiles,
        subscription: subscription,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('You').last);
    await tester.pumpAndSettle();
    return profiles;
  }

  testWidgets('muestra el plan, la moneda de casa y la cuenta', (tester) async {
    await openYou(tester);
    expect(find.text('TRAVIO Annual'), findsOneWidget);
    expect(find.text('US\$29.99 / year'), findsOneWidget);
    expect(find.text('Renews Mar 4, 2027'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('EUR · Euro', findRichText: true), findsOneWidget);
    await tester.scrollUntilVisible(find.text('traveler@example.com'), 200);
    expect(find.text('traveler@example.com'), findsOneWidget);
  });

  testWidgets('Manage subscription abre el Customer Center', (tester) async {
    final subscription = FakeSubscriptionRepository();
    await openYou(tester, subscription: subscription);
    await tester.tap(find.text('Manage subscription'));
    await tester.pump();
    expect(subscription.customerCenterShown, isTrue);
  });

  testWidgets('Sign out lleva a Sign in', (tester) async {
    await openYou(tester);
    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Apple'), findsOneWidget);
  });

  testWidgets('Delete account pide confirmación y borra los datos', (
    tester,
  ) async {
    final profiles = await openYou(tester);
    // El pie queda debajo: así Delete account no se queda tapado por el menú.
    await tester.scrollUntilVisible(
      find.textContaining('Currency & Travel'),
      200,
    );
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(profiles.homeCurrencies, contains('test-user'));

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(profiles.homeCurrencies, isEmpty);
    expect(find.text('Continue with Apple'), findsOneWidget);
  });

  testWidgets(
    'Home currency: elegir otra la guarda en la cuenta y la muestra en You',
    (tester) async {
      final profiles = await openYou(tester);
      await tester.tap(find.text('Home currency'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Used by default in new trips. You can change it for each trip.',
        ),
        findsOneWidget,
      );
      expect(find.text('SELECTED'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'yen');
      await tester.pump();
      await tester.tap(find.text('Japanese Yen'));
      await tester.pumpAndSettle();
      expect(profiles.homeCurrencies['test-user'], 'JPY');
      expect(
        find.text('JPY · Japanese Yen', findRichText: true),
        findsOneWidget,
      );
    },
  );
}
