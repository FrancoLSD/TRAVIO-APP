import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travio_app/features/rates/data/rates_repository.dart';

import 'test_app.dart';

void main() {
  test('convierte entre dos monedas pasando por el euro', () {
    final rates = Rates.fromFrankfurter(sampleRates);
    expect(rates.date, '2026-10-20');
    expect(rates.convert(10, 'EUR', 'JPY'), closeTo(1776.3, 0.001));
    expect(rates.convert(1.16, 'USD', 'JPY'), closeTo(177.63, 0.001));
    expect(rates.convert(1, 'EUR', 'XXX'), isNull);
  });

  test('rechaza respuestas con forma inesperada', () {
    expect(() => Rates.fromFrankfurter('[]'), throwsFormatException);
    expect(
      () => Rates.fromFrankfurter(
        '[{"quote":"JPY","rate":-1,"date":"2026-10-20"}]',
      ),
      throwsFormatException,
    );
  });

  test('sin conexión usa la última tasa guardada', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await RatesRepository(prefs, fetch: (_) async => sampleRates).latest();
    // Caché caducada y sin red.
    await prefs.setString('rates_fetched_at', DateTime(2020).toIso8601String());
    final offline = RatesRepository(
      prefs,
      fetch: (_) async => throw Exception('offline'),
    );
    expect((await offline.latest()).convert(1, 'EUR', 'JPY'), 177.63);
  });

  test('una respuesta inválida no sustituye la caché', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await RatesRepository(prefs, fetch: (_) async => sampleRates).latest();
    await prefs.setString('rates_fetched_at', DateTime(2020).toIso8601String());
    final broken = RatesRepository(prefs, fetch: (_) async => '{"error":true}');
    expect((await broken.latest()).convert(1, 'EUR', 'JPY'), 177.63);
  });

  test('sin caché y sin red da error', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final offline = RatesRepository(
      prefs,
      fetch: (_) async => throw Exception('offline'),
    );
    expect(offline.latest(), throwsException);
  });
}
