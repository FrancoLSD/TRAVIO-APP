import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Título de sección en mayúsculas (PREFERENCES, SUPPORT…).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
