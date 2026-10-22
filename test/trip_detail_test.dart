import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travio_app/features/rates/data/rates_repository.dart';
import 'package:travio_app/features/trips/domain/expense.dart';
import 'package:travio_app/features/trips/domain/trip.dart';
import 'package:travio_app/features/trips/presentation/trip_detail_screen.dart';

import 'test_app.dart';

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  DateTime day(int offset) => today.add(Duration(days: offset));

  Trip tokyo({int startOffset = -3, int endOffset = 5}) => Trip(
    id: 'tokyo',
    destination: 'Tokyo, Japan',
    countryCode: 'JP',
    homeCurrency: 'EUR',
    localCurrency: 'JPY',
    startDate: day(startOffset),
    endDate: day(endOffset),
    budget: 1250,
  );

  Expense ramen() => Expense(
    id: 'ramen',
    name: 'Ramen',
    category: ExpenseCategory.food,
    amountLocal: 1200,
    rate: 174.82,
    rateDate: '2026-10-16',
    dateTime: DateTime.now().subtract(const Duration(hours: 1)),
  );

  /// Abre Trip Detail del viaje [trip] desde la lista de Trips.
  Future<FakeTripsRepository> openDetail(
    WidgetTester tester,
    Trip trip, {
    List<Expense> expenses = const [],
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final trips = FakeTripsRepository([trip]);
    for (final expense in expenses) {
      await trips.addExpense('test-user', trip.id, expense);
    }
    await tester.pumpWidget(
      await testApp(
        {'onboarding_completed': true},
        auth: FakeAuthRepository(uid: 'test-user'),
        trips: trips,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trips').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(trip.destination));
    await tester.pumpAndSettle();
    return trips;
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        // La lista de la pantalla, no la de dentro de un campo de texto.
        scrollable: find
            .descendant(
              of: find.byType(TripDetailScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );

  test(
    'tasas de un día concreto: se guardan y sin conexión usan la última',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var calls = 0;
      final online = RatesRepository(
        prefs,
        fetch: (_) async {
          calls++;
          return sampleRates;
        },
      );
      final first = await online.on(DateTime(2026, 10, 16), {'EUR', 'JPY'});
      expect(
        (first.offline, first.rates.convert(1, 'EUR', 'JPY')),
        (false, 177.63),
      );
      await online.on(DateTime(2026, 10, 16), {'JPY', 'EUR'});
      expect(calls, 1); // la segunda vez sale de la caché

      final offline = RatesRepository(
        prefs,
        fetch: (_) async => throw Exception('offline'),
      );
      final fallback = await offline.on(DateTime(2026, 10, 15), {'EUR', 'JPY'});
      expect(fallback.offline, isTrue);
      expect(fallback.rates.convert(1, 'EUR', 'JPY'), 177.63);

      final euro = await offline.on(DateTime(2026, 10, 15), {'EUR'});
      expect(euro.rates.convert(5, 'EUR', 'EUR'), 5);
    },
  );

  testWidgets('muestra estado, presupuesto y categorías', (tester) async {
    await openDetail(tester, tokyo(), expenses: [ramen()]);
    expect(find.text('ACTIVE · DAY 4 OF 9'), findsOneWidget);
    expect(
      find.textContaining('€7  / €1,250', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('€1,243 left'), findsOneWidget);
    await scrollTo(tester, find.text('Entertainment'));
    expect(find.text('¥1,200'), findsWidgets); // fila Food y fila del gasto
  });

  testWidgets('Quick convert → Save expense guarda el gasto en moneda local', (
    tester,
  ) async {
    final trips = await openDetail(tester, tokyo());
    await tester.enterText(find.byType(TextField), '1000');
    await tester.pumpAndSettle();
    expect(find.text('≈ €5.63'), findsOneWidget);

    // Invertido: se escribe en EUR y el gasto se guarda en JPY.
    await tester.tap(find.byTooltip('Swap currencies'));
    await tester.enterText(find.byType(TextField), '10');
    await tester.pumpAndSettle();
    expect(find.text('≈ ¥1,776.30'), findsOneWidget);

    await tester.ensureVisible(find.text('Save as expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save as expense'));
    await tester.pumpAndSettle();
    expect(find.text('Rate for Oct 20: 177.63'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Ramen'),
      'Sushi',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Shopping'),
      ),
    );
    await tester.ensureVisible(find.text('Save to Tokyo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to Tokyo'));
    await tester.pumpAndSettle();

    final saved = trips.expenses['tokyo']!.single;
    expect(
      (saved.name, saved.category, saved.amountLocal),
      ('Sushi', ExpenseCategory.shopping, 1776.3),
    );
    expect(saved.amountHome, closeTo(10, 0.001));
    expect(trips.trips.single.spentHome, closeTo(10, 0.001));
  });

  testWidgets('tocar un gasto lo edita, y desde ahí se borra tras confirmar', (
    tester,
  ) async {
    final trips = await openDetail(tester, tokyo(), expenses: [ramen()]);
    Future<void> openRamen() async {
      await scrollTo(tester, find.text('Ramen'));
      await tester.tap(find.text('Ramen'));
      await tester.pumpAndSettle();
    }

    Future<void> tapInSheet(String label) async {
      final button = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(label),
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await openRamen();
    expect(find.text('Edit expense'), findsOneWidget);
    expect(find.text('Rate for Oct 16: 174.82'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '1200'), '2400');
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tapInSheet('Save changes');
    final edited = trips.expenses['tokyo']!.single;
    expect(
      (edited.amountLocal, edited.rate),
      (2400, 174.82),
    ); // misma tasa guardada
    expect(trips.trips.single.spentLocal, 2400); // 1200 + (2400 - 1200)

    // Cancelar la confirmación no borra nada.
    await openRamen();
    await tapInSheet('Delete expense');
    expect(find.text('Delete this expense?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(trips.expenses['tokyo'], hasLength(1));
    expect(find.byType(BottomSheet), findsOneWidget); // sigue en la hoja

    await tapInSheet('Delete expense');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(trips.expenses['tokyo'], isEmpty);
    expect(trips.trips.single.spentLocal, 0);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Delete trip borra el viaje y vuelve a Trips', (tester) async {
    final trips = await openDetail(tester, tokyo(), expenses: [ramen()]);
    await tester.tap(find.byTooltip('Trip options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(trips.trips, isEmpty);
    expect(trips.expenses, isEmpty);
    expect(find.text('No trips yet'), findsOneWidget);
  });

  testWidgets(
    'viaje que aún no empieza: se convierte pero no se registran gastos',
    (tester) async {
      await openDetail(tester, tokyo(startOffset: 10, endOffset: 15));
      expect(find.text('UPCOMING · IN 10 DAYS'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '1000');
      await tester.pumpAndSettle();
      expect(find.text('≈ €5.63'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save as expense'),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.text('You can log expenses once the trip starts.'),
        findsOneWidget,
      );
    },
  );
}
