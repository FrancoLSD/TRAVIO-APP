import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cabecera de las pantallas hijas: botón atrás y título en mayúsculas centrado
/// (design/SETTINGS - HOME CURRENCY.png, SETTINGS - THEME.png).
class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton.filled(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              style: IconButton.styleFrom(
                backgroundColor: context.colors.fillStrong,
              ),
              icon: Icon(Icons.chevron_left, color: context.colors.text),
            ),
          ),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: context.colors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
