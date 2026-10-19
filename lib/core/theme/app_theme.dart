import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF7F7F5);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE7E7E3);
  static const text = Color(0xFF151515);
  static const textSecondary = Color(0xFF6B6B67);
  static const brand = Color(0xFF3B9C9C);
  static const accent = Color(0xFF00695F);
  static const destructive = Color(0xFFC0392B);
}

abstract final class AppFonts {
  static const mono = 'IBMPlexMono';
}

// Sin fontFamily: en iOS Flutter ya usa la fuente del sistema (SF Pro).
final appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    primary: AppColors.accent,
    surface: AppColors.background,
    onSurface: AppColors.text,
    error: AppColors.destructive,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
      letterSpacing: -0.5,
    ),
    bodyMedium: TextStyle(fontSize: 15, color: AppColors.textSecondary),
  ),
);
