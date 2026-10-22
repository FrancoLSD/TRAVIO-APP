import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/preferences/app_preferences.dart';

/// Tasas del día respecto al euro (Frankfurter).
class Rates {
  Rates._(this.date, this._perEur);

  /// Fecha de las tasas, 'yyyy-MM-dd'.
  final String date;
  final Map<String, double> _perEur;

  /// Valida la respuesta de /v2/rates?base=EUR: lanza FormatException si no tiene la forma esperada.
  factory Rates.fromFrankfurter(String body) {
    final perEur = <String, double>{'EUR': 1};
    var date = '';
    final items = jsonDecode(body);
    if (items is! List) {
      throw const FormatException('Unexpected Frankfurter response');
    }
    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Unexpected Frankfurter rate');
      }
      final quote = item['quote'];
      final rate = item['rate'];
      final itemDate = item['date'];
      if (quote is! String ||
          rate is! num ||
          rate <= 0 ||
          itemDate is! String) {
        throw const FormatException('Unexpected Frankfurter rate');
      }
      perEur[quote] = rate.toDouble();
      if (itemDate.compareTo(date) > 0) date = itemDate;
    }
    if (perEur.length < 2) {
      throw const FormatException('Empty Frankfurter response');
    }
    return Rates._(date, perEur);
  }

  /// Para un par EUR/EUR, que no necesita ninguna tasa.
  Rates.euroOnly(this.date) : _perEur = const {'EUR': 1};

  /// null si alguna de las dos monedas no tiene tasa.
  double? convert(double amount, String from, String to) {
    final fromRate = _perEur[from];
    final toRate = _perEur[to];
    if (fromRate == null || toRate == null) return null;
    return amount / fromRate * toRate;
  }
}

/// Descarga las tasas y las guarda en el iPhone para usarlas sin conexión.
class RatesRepository {
  RatesRepository(this._prefs, {Future<String> Function(Uri uri)? fetch})
    : _fetch = fetch ?? _get;

  final SharedPreferences _prefs;
  final Future<String> Function(Uri uri) _fetch;

  static const _cacheKey = 'rates_latest';
  static const _fetchedAtKey = 'rates_fetched_at';
  // Frankfurter publica una vez al día; no hace falta pedir más a menudo.
  static const _maxAge = Duration(hours: 6);

  /// Cuándo se descargaron las últimas tasas guardadas en el iPhone.
  DateTime? get savedAt =>
      DateTime.tryParse(_prefs.getString(_fetchedAtKey) ?? '');

  Future<Rates> latest() async {
    final cached = _prefs.getString(_cacheKey);
    final fetchedAt = DateTime.tryParse(_prefs.getString(_fetchedAtKey) ?? '');
    if (cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _maxAge) {
      return Rates.fromFrankfurter(cached);
    }
    try {
      final body = await _fetch(
        Uri.parse('https://api.frankfurter.dev/v2/rates?base=EUR'),
      );
      final rates = Rates.fromFrankfurter(
        body,
      ); // valida antes de sustituir la caché
      await _prefs.setString(_cacheKey, body);
      await _prefs.setString(_fetchedAtKey, DateTime.now().toIso8601String());
      return rates;
    } catch (_) {
      // Sin conexión: la última guardada.
      if (cached != null) {
        return Rates.fromFrankfurter(cached);
      }
      rethrow;
    }
  }

  /// Tasas de [day] para [codes] (informe §5.10), guardadas para siempre porque no cambian.
  /// Si el día aún no tiene tasa, la última publicada; sin conexión, la última guardada (offline).
  Future<({Rates rates, bool offline})> on(
    DateTime day,
    Set<String> codes,
  ) async {
    final date = _day(day);
    final quotes = (codes.toList()..remove('EUR'))..sort();
    if (quotes.isEmpty) return (rates: Rates.euroOnly(date), offline: false);
    final key = 'rates_on_${date}_${quotes.join(',')}';
    final cached = _prefs.getString(key);
    if (cached != null) {
      return (rates: Rates.fromFrankfurter(cached), offline: false);
    }
    final String body;
    try {
      body = await _fetch(
        Uri.parse(
          'https://api.frankfurter.dev/v2/rates?base=EUR&date=$date&quotes=${quotes.join(',')}',
        ),
      );
    } catch (_) {
      return (rates: await _lastSaved(quotes), offline: true);
    }
    try {
      final rates = Rates.fromFrankfurter(body);
      await _prefs.setString(key, body);
      return (rates: rates, offline: false);
    } on FormatException {
      return (
        rates: await latest(),
        offline: false,
      ); // día sin publicar todavía
    }
  }

  /// Sin conexión: las tasas del día más reciente guardadas, ya sean las de hoy o las de un gasto anterior.
  Future<Rates> _lastSaved(List<String> quotes) async {
    try {
      return await latest();
    } catch (_) {
      final suffix = '_${quotes.join(',')}';
      final days =
          _prefs
              .getKeys()
              .where((k) => k.startsWith('rates_on_') && k.endsWith(suffix))
              .toList()
            ..sort();
      if (days.isEmpty) rethrow;
      return Rates.fromFrankfurter(_prefs.getString(days.last)!);
    }
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<String> _get(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final response = await (await client.getUrl(uri)).close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }
}

final ratesRepositoryProvider = Provider<RatesRepository>(
  (ref) => RatesRepository(ref.watch(sharedPreferencesProvider)),
);

final ratesProvider = FutureProvider<Rates>(
  (ref) => ref.watch(ratesRepositoryProvider).latest(),
);
