import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('el menú cambia entre las 4 pestañas', (tester) async {
    await tester.pumpWidget(
      await testApp({
        'onboarding_completed': true,
      }, auth: FakeAuthRepository(uid: 'test-user')),
    );
    await tester.pumpAndSettle();
    expect(find.text('TRAVIO'), findsOneWidget);

    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();
    expect(find.text('No trips yet'), findsOneWidget);

    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('Rate alerts are on the way'), findsOneWidget);

    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR PLAN'), findsOneWidget);
  });
}
