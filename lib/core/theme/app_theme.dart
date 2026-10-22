import 'package:flutter/material.dart';

/// Colores de la app para el modo claro y el oscuro (informe §11.3 y §11.4).
/// Se leen con `context.colors`.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.brand,
    required this.accent,
    required this.onAccent,
    required this.destructive,
    required this.fill,
    required this.fillStrong,
    required this.track,
    required this.chevron,
    required this.control,
    required this.badge,
    required this.highlight,
    required this.appleButton,
    required this.onAppleButton,
  });

  final Color background;
  final Color card;
  final Color border;
  final Color text;
  final Color textSecondary;
  final Color brand;

  /// Botones y elemento activo.
  final Color accent;

  /// Texto e iconos sobre [accent].
  final Color onAccent;
  final Color destructive;

  /// Fondos suaves: cajas de importe, píldoras de moneda, círculos de icono.
  final Color fill;

  /// Algo más marcado que [fill]: botones secundarios, contadores, píldoras.
  final Color fillStrong;

  /// Fondo de las barras de progreso.
  final Color track;
  final Color chevron;

  /// Borde de controles sin marcar (círculos de selección).
  final Color control;

  /// Símbolo de los círculos de moneda.
  final Color badge;

  /// Etiqueta de ahorro del paywall («SAVE 16%»), con el texto en [card].
  final Color highlight;

  /// Apple pide el botón negro en modo claro y blanco en oscuro.
  final Color appleButton;
  final Color onAppleButton;

  static const light = AppColors(
    background: Color(0xFFF7F7F5),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE7E7E3),
    text: Color(0xFF151515),
    textSecondary: Color(0xFF6B6B67),
    brand: Color(0xFF3B9C9C),
    accent: Color(0xFF00695F),
    onAccent: Color(0xFFFFFFFF),
    destructive: Color(0xFFC0392B),
    fill: Color(0xFFF2F2EF),
    fillStrong: Color(0xFFEDEDE9),
    track: Color(0xFFEEEEEA),
    chevron: Color(0xFFB0B0AB),
    control: Color(0xFFCFCFCB),
    badge: Color(0xFF4C5DB0),
    highlight: Color(0xFFC9843A),
    appleButton: Color(0xFF000000),
    onAppleButton: Color(0xFFFFFFFF),
  );

  // Base de §11.4; el resto elegido para mantener la misma calidez sin negro puro.
  static const dark = AppColors(
    background: Color(0xFF0F1010),
    card: Color(0xFF171918),
    border: Color(0xFF2A2D2B),
    text: Color(0xFFF4F4F0),
    textSecondary: Color(0xFF929692),
    brand: Color(0xFF58B9B3),
    accent: Color(0xFF58B9B3),
    // Texto oscuro sobre el acento claro: el blanco no llega al contraste mínimo.
    onAccent: Color(0xFF0F1010),
    destructive: Color(0xFFE5675A),
    fill: Color(0xFF1F2221),
    fillStrong: Color(0xFF262A28),
    track: Color(0xFF262A28),
    chevron: Color(0xFF5E625F),
    control: Color(0xFF4A4E4B),
    badge: Color(0xFF9AA6F0),
    highlight: Color(0xFFB8732C),
    appleButton: Color(0xFFFFFFFF),
    onAppleButton: Color(0xFF000000),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

abstract final class AppFonts {
  static const mono = 'IBMPlexMono';
}

// Sin fontFamily: en iOS Flutter ya usa la fuente del sistema (SF Pro).
ThemeData appTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    extensions: [colors],
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      surface: colors.background,
      onSurface: colors.text,
      error: colors.destructive,
    ),
    dividerColor: colors.border,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: colors.text,
        letterSpacing: -0.5,
      ),
      bodyMedium: TextStyle(fontSize: 15, color: colors.textSecondary),
    ),
  );
}
