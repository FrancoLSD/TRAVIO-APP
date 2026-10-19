import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Cabecera de las pestañas: logo TRAVIO y botón de perfil (lleva a You).
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.sync_alt, size: 22, color: AppColors.accent),
        const SizedBox(width: 12),
        const Text(
          'TRAVIO',
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: AppColors.accent,
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Profile',
          child: GestureDetector(
            onTap: () => context.go('/you'),
            child: const CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person_outline, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
