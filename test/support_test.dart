import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:travio_app/core/utils/app_info.dart';
import 'package:travio_app/features/you/data/mail_composer.dart';
import 'package:travio_app/features/you/presentation/contact_support_screen.dart';

import 'test_app.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'TRAVIO',
      packageName: 'com.flsd.travio',
      version: '1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> openHelp(WidgetTester tester, {MailComposer? mail}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      await testApp(
        {'onboarding_completed': true},
        auth: FakeAuthRepository(uid: 'test-user'),
        mail: mail,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('You').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help & Support'));
    await tester.pumpAndSettle();
  }

  Future<void> writeAndSend(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Contact support'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Contact support'));
    await tester.pumpAndSettle();
    final send = find.widgetWithText(FilledButton, 'Send message');
    await tester.tap(find.text('Trips & expenses'));
    await tester.enterText(
      find.byType(TextField),
      'My expense shows the wrong rate.',
    );
    await tester.pump();
    // Done cierra el teclado del mensaje.
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Done'), findsNothing);
    await tester.scrollUntilVisible(
      send,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ContactSupportScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(send);
    await tester.pumpAndSettle();
  }

  test('versión de iOS', () {
    expect(iosVersion('Version 26.0 (Build 23A341)'), '26.0');
    expect(iosVersion('Version 18.6.2 (Build 22G100)'), '18.6.2');
  });

  testWidgets('preguntas: la primera abierta y las demás se despliegan', (
    tester,
  ) async {
    await openHelp(tester);
    expect(
      find.textContaining('Daily reference rates from central banks'),
      findsOneWidget,
    );
    expect(find.textContaining('Each expense keeps the rate'), findsNothing);
    await tester.tap(find.text('Why does an expense use a past rate?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Each expense keeps the rate'), findsOneWidget);
  });

  testWidgets('enviado: prepara el correo y muestra Message sent', (
    tester,
  ) async {
    final mail = FakeMailComposer();
    await openHelp(tester, mail: mail);
    await writeAndSend(tester);

    final email = mail.sent.single;
    expect(email.to, 'flsd.support@gmail.com');
    expect(email.subject, 'TRAVIO support · Trips & expenses');
    expect(email.body, contains('My expense shows the wrong rate.'));
    expect(email.body, contains('App version: 1.0 (1)'));
    expect(email.body, contains('Plan: Annual'));
    expect(find.text('Message sent'), findsOneWidget);
    expect(
      find.text('Trips & expenses'),
      findsOneWidget,
    ); // en la tarjeta Topic

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR PLAN'), findsOneWidget);
  });

  testWidgets('cancelado en Mail: sigue en el formulario', (tester) async {
    await openHelp(tester, mail: FakeMailComposer(MailResult.cancelled));
    await writeAndSend(tester);
    expect(find.text('Message sent'), findsNothing);
    expect(find.text('Send message'), findsOneWidget); // sigue el formulario
  });

  testWidgets('sin Mail configurado: avisa con la dirección', (tester) async {
    await openHelp(tester, mail: FakeMailComposer(MailResult.unavailable));
    await writeAndSend(tester);
    expect(
      find.text(
        'Mail isn’t set up on this iPhone. Write to flsd.support@gmail.com',
      ),
      findsOneWidget,
    );
    expect(find.text('Copy'), findsOneWidget);
  });
}
