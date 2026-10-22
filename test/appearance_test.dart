import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';

void main() {
  Future<void> openYou(WidgetTester tester, Map<String, Object> saved) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      await testApp({
        'onboarding_completed': true,
        ...saved,
      }, auth: FakeAuthRepository(uid: 'test-user')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('You').last);
    await tester.pumpAndSettle();
  }

  ThemeMode themeMode(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

  testWidgets('elegir Dark cambia el tema, se ve en You y se recuerda', (
    tester,
  ) async {
    await openYou(tester, {});
    expect(themeMode(tester), ThemeMode.system);
    expect(find.text('System'), findsOneWidget);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose how TRAVIO looks on your iPhone.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(themeMode(tester), ThemeMode.dark);
    expect(
      (await SharedPreferences.getInstance()).getString('theme_mode'),
      'dark',
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsOneWidget); // valor de la fila Appearance

    // Al volver a abrir la app sigue en oscuro.
    await openYou(tester, {'theme_mode': 'dark'});
    expect(themeMode(tester), ThemeMode.dark);
  });
}
