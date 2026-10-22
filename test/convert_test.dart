import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travio_app/core/utils/amount_input.dart';
import 'package:travio_app/features/convert/presentation/convert_screen.dart';
import 'package:travio_app/features/trips/domain/trip.dart';

import 'test_app.dart';

void main() {
  final today = DateUtils.dateOnly(DateTime.now());

  /// Abre Convert (pestaña inicial) con el iPhone en EUR.
  Future<({FakeFavoritesRepository favorites})> openConvert(
    WidgetTester tester, {
    Map<String, Object> saved = const {},
    List<Trip> trips = const [],
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final favorites = FakeFavoritesRepository();
    await tester.pumpWidget(
      await testApp(
        {'onboarding_completed': true, 'home_currency': 'EUR', ...saved},
        auth: FakeAuthRepository(uid: 'test-user'),
        trips: FakeTripsRepository(trips),
        favorites: favorites,
      ),
    );
    await tester.pumpAndSettle();
    return (favorites: favorites);
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ConvertScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );

  Finder amountField(int i) => find
      .descendant(
        of: find.byType(ConvertScreen),
        matching: find.byType(TextField),
      )
      .at(i);

  String amountText(WidgetTester tester, int i) =>
      tester.widget<TextField>(amountField(i)).controller!.text;

  group('importes', () {
    TextEditingValue type(
      AmountInputFormatter f,
      String before,
      String after,
    ) => f.formatEditUpdate(
      TextEditingValue(text: before),
      TextEditingValue(text: after),
    );

    test('separa miles y limita decimales', () {
      final euros = AmountInputFormatter(2);
      expect(type(euros, '123', '1234').text, '1,234');
      expect(type(euros, '1,234', '1,234.5').text, '1,234.5');
      expect(
        type(euros, '1,234.56', '1,234.567').text,
        '1,234.56',
      ); // no deja un tercer decimal
      expect(
        type(euros, '12', '12,').text,
        '12.',
      ); // la coma del teclado español es el decimal
      expect(
        type(AmountInputFormatter(0), '12', '12.').text,
        '12',
      ); // el yen no tiene decimales
    });

    test('formato sin decimales de sobra', () {
      expect(formatAmount(43705, 0), '43,705');
      expect(formatAmount(290, 2), '290');
      expect(formatAmount(250.5, 2), '250.50');
      expect(parseAmount('1,234.5'), 1234.5);
      expect(currencyDecimals('JPY'), 0);
    });
  });

  testWidgets(
    'sin viaje: EUR → USD, convierte en los dos sentidos e invierte el par',
    (tester) async {
      await openConvert(tester);
      expect(find.text('No trips yet'), findsOneWidget);
      expect(
        find.textContaining('Rates for Oct 20', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('1 EUR = 1.16 USD', findRichText: true),
        findsOneWidget,
      );

      await tester.enterText(amountField(0), '250');
      await tester.pump();
      expect(amountText(tester, 1), '290');

      await tester.enterText(amountField(1), '11.6');
      await tester.pump();
      expect(amountText(tester, 0), '10');

      await tester.tap(find.bySemanticsLabel('Swap currencies'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('1 USD = 0.8621 EUR', findRichText: true),
        findsOneWidget,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('convert_pair'),
        'USD-EUR',
      );
    },
  );

  testWidgets('con viaje activo: usa su moneda y la tarjeta lleva al viaje', (
    tester,
  ) async {
    await openConvert(
      tester,
      trips: [
        Trip(
          id: 'tokyo',
          destination: 'Tokyo, Japan',
          countryCode: 'JP',
          homeCurrency: 'EUR',
          localCurrency: 'JPY',
          startDate: today.subtract(const Duration(days: 2)),
          endDate: today.add(const Duration(days: 5)),
          budget: 1250,
        ),
      ],
    );
    expect(
      find.textContaining('1 EUR = 177.63 JPY', findRichText: true),
      findsOneWidget,
    );
    await tester.enterText(amountField(0), '250');
    await tester.pump();
    expect(amountText(tester, 1), '44,408'); // sin decimales en yenes

    await tester.tap(find.text('Done'));
    await tester.pump();
    await scrollTo(tester, find.text('Tokyo, Japan'));
    await tester.tap(find.text('Tokyo, Japan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ACTIVE · DAY 3 OF 8'), findsOneWidget);
  });

  testWidgets('recuerda el último par usado', (tester) async {
    await openConvert(tester, saved: {'convert_pair': 'JPY-USD'});
    expect(
      find.textContaining('1 JPY = 0.0065 USD', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('favoritos: el corazón añade y quita, y tocar uno lo carga', (
    tester,
  ) async {
    final app = await openConvert(tester);
    await scrollTo(tester, find.text('No active favorites'));
    expect(find.text('No active favorites'), findsOneWidget);
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    expect(app.favorites.favorites, [(from: 'EUR', to: 'USD')]);
    expect(find.text('EUR / USD'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Swap currencies'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('EUR / USD'));
    await tester.tap(find.text('EUR / USD'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('1 EUR = 1.16 USD', findRichText: true),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byTooltip('Remove from favorites'));
    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pumpAndSettle();
    expect(app.favorites.favorites, isEmpty);
  });

  testWidgets('cambiar moneda con el selector', (tester) async {
    await openConvert(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('Change US Dollar')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'yen');
    await tester.pump();
    await tester.tap(find.text('Japanese Yen'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('1 EUR = 177.63 JPY', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('Done cierra el teclado del importe', (tester) async {
    await openConvert(tester);
    await tester.tap(amountField(0));
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Done'), findsNothing);
    expect(SystemChannels.textInput, isNotNull);
  });
}
