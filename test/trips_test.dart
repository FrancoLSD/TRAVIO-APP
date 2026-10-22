import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travio_app/features/trips/domain/trip.dart';
import 'package:travio_app/features/trips/presentation/trip_format.dart';

import 'test_app.dart';

Trip trip(
  String destination,
  DateTime start,
  DateTime end, {
  String country = 'JP',
  double? budget,
}) => Trip(
  id: destination,
  destination: destination,
  countryCode: country,
  homeCurrency: 'EUR',
  localCurrency: 'JPY',
  startDate: start,
  endDate: end,
  budget: budget,
);

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  DateTime day(int offset) => today.add(Duration(days: offset));

  test('estado según las fechas, con ambos días incluidos', () {
    final t = trip(
      'Tokyo, Japan',
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 26),
    );
    expect(t.statusOn(DateTime(2026, 10, 11, 23)), TripStatus.upcoming);
    expect(t.statusOn(DateTime(2026, 10, 12, 8)), TripStatus.active);
    expect(t.statusOn(DateTime(2026, 10, 26, 23)), TripStatus.active);
    expect(t.statusOn(DateTime(2026, 10, 27)), TripStatus.previous);
  });

  test('resultado del presupuesto', () {
    expect(budgetResult(1420, null), isNull);
    expect(budgetResult(1000, 1250), BudgetResult.under);
    expect(budgetResult(1245, 1250), BudgetResult.on);
    expect(budgetResult(1400, 1250), BudgetResult.over);
  });

  test('fechas con el año solo cuando hace falta', () {
    final now = DateTime(2026, 10, 20);
    expect(
      formatTripDates(
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 26),
        today: now,
      ),
      'Oct 12 — Oct 26',
    );
    expect(
      formatTripDates(
        DateTime(2025, 11, 14),
        DateTime(2025, 11, 21),
        today: now,
      ),
      'Nov 14 — Nov 21, 2025',
    );
    expect(
      formatTripDates(DateTime(2026, 12, 28), DateTime(2027, 1, 4), today: now),
      'Dec 28, 2026 — Jan 4, 2027',
    );
  });

  test('el mismo país siempre tiene el mismo color', () {
    expect(tripColor('JP'), const Color(0xFFE86A6A));
    expect(tripColor('VN'), tripColor('VN'));
  });

  Future<void> openTrips(
    WidgetTester tester,
    FakeTripsRepository trips, [
    Map<String, Object> saved = const {},
  ]) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      await testApp(
        {'onboarding_completed': true, ...saved},
        auth: FakeAuthRepository(uid: 'test-user'),
        trips: trips,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trips').last);
    await tester.pumpAndSettle();
  }

  testWidgets('sin viajes muestra el estado vacío', (tester) async {
    await openTrips(tester, FakeTripsRepository());
    expect(find.text('No trips yet'), findsOneWidget);
    expect(find.text('New Trip'), findsOneWidget);
  });

  testWidgets('agrupa por fechas y pliega Previous recordándolo', (
    tester,
  ) async {
    final trips = FakeTripsRepository([
      trip('Tokyo, Japan', day(-3), day(5), budget: 1250),
      trip('London, United Kingdom', day(20), day(27), country: 'GB'),
      trip('New York, USA', day(-60), day(-50), country: 'US', budget: 3000),
    ]);
    await openTrips(tester, trips);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(
      find.textContaining('€0  / €1,250', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('SCHEDULED'), findsOneWidget);
    expect(find.text('Under budget by €3,000'), findsOneWidget);

    await tester.tap(find.text('PREVIOUS'));
    await tester.pumpAndSettle();
    expect(find.text('New York, USA'), findsNothing);

    // Al volver a abrir la app sigue plegada.
    await openTrips(tester, trips, {'expanded_trips_previous': false});
    expect(find.text('New York, USA'), findsNothing);
    expect(find.text('Tokyo, Japan'), findsOneWidget);
  });

  testWidgets('New Trip: busca el destino, deduce la moneda y crea el viaje', (
    tester,
  ) async {
    final trips = FakeTripsRepository();
    await openTrips(tester, trips, {'home_currency': 'EUR'});
    await tester.tap(find.text('New Trip'));
    await tester.pumpAndSettle();

    final create = find.widgetWithText(FilledButton, 'Create Trip');
    expect(tester.widget<FilledButton>(create).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'tok');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tokyo, Japan'));
    await tester.pumpAndSettle();
    expect(find.text('JPY  Japanese Yen', findRichText: true), findsOneWidget);
    expect(find.text('EUR  Euro', findRichText: true), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1000');
    await tester.pumpAndSettle();
    expect(find.text('≈ ¥177,630 JPY'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      tester.widget<FilledButton>(create).onPressed,
      isNull,
    ); // faltan las fechas

    // La cabecera del selector de Flutter desborda con la fuente ancha de los tests (no con SF Pro).
    tester.view.physicalSize = const Size(1800, 2532);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    // Se escriben las fechas en el modo de texto del selector: del 10 al 12 del mes actual.
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    String typed(int d) =>
        '${today.month.toString().padLeft(2, '0')}/$d/${today.year}';
    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), typed(10));
    await tester.enterText(fields.at(1), typed(12));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(create);
    await tester.pumpAndSettle();
    await tester.tap(create);
    await tester.pumpAndSettle();

    final created = trips.trips.single;
    expect(created.destination, 'Tokyo, Japan');
    expect(created.countryCode, 'JP');
    expect((created.homeCurrency, created.localCurrency), ('EUR', 'JPY'));
    expect(created.budget, 1000);
    expect(
      (created.startDate, created.endDate),
      (
        DateTime(today.year, today.month, 10),
        DateTime(today.year, today.month, 12),
      ),
    );
    expect(find.text('Tokyo, Japan'), findsOneWidget); // de vuelta en Trips
  });

  testWidgets(
    'New Trip: si la moneda del país no tiene tasa, hay que elegirla',
    (tester) async {
      await openTrips(tester, FakeTripsRepository());
      await tester.tap(find.text('New Trip'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'cara');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Caracas, Venezuela'));
      await tester.pumpAndSettle();
      expect(find.text('--  Select', findRichText: true), findsOneWidget);
    },
  );

  testWidgets('New Trip: la barra Done solo sale al escribir el presupuesto', (
    tester,
  ) async {
    await openTrips(tester, FakeTripsRepository());
    await tester.tap(find.text('New Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
    await tester.tap(find.text('0'));
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Done'), findsNothing);
  });
}
