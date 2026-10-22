import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias guardadas en el dispositivo.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _homeCurrencyKey = 'home_currency';

  bool get onboardingCompleted =>
      _prefs.getBool(_onboardingCompletedKey) ?? false;

  String? get homeCurrency => _prefs.getString(_homeCurrencyKey);

  Future<void> completeOnboarding({required String homeCurrency}) async {
    await _prefs.setString(_homeCurrencyKey, homeCurrency);
    await _prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Si una sección plegable (ej. 'trips_upcoming') está abierta; abierta por defecto.
  bool isSectionExpanded(String section) =>
      _prefs.getBool('expanded_$section') ?? true;

  Future<void> setSectionExpanded(String section, bool expanded) =>
      _prefs.setBool('expanded_$section', expanded);

  /// Último par del conversor, ej. ('EUR', 'JPY'); null si nunca se ha cambiado.
  (String, String)? get lastPair {
    final codes = _prefs.getString('convert_pair')?.split('-');
    return codes?.length == 2 ? (codes![0], codes[1]) : null;
  }

  Future<void> setLastPair(String from, String to) =>
      _prefs.setString('convert_pair', '$from-$to');

  /// Se guarda en el iPhone y no en la cuenta: hace falta desde el arranque, antes de iniciar sesión.
  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_prefs.getString('theme_mode')] ??
      ThemeMode.system;

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString('theme_mode', mode.name);
}

/// Se sobrescribe en main() con la instancia ya cargada.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final appPreferencesProvider = Provider<AppPreferences>(
  (ref) => AppPreferences(ref.watch(sharedPreferencesProvider)),
);

/// Apariencia elegida en You > Appearance.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(appPreferencesProvider).themeMode;

  void set(ThemeMode mode) {
    ref.read(appPreferencesProvider).setThemeMode(mode);
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
