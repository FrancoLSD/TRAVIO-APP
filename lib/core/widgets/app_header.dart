import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'brand_logo.dart';

/// Cabecera de las pestañas: logo TRAVIO y botón de perfil (lleva a You).
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BrandLogo(),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Profile',
          child: GestureDetector(
            onTap: () => context.go('/you'),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: context.colors.accent,
              child: Icon(
                Icons.person_outline,
                size: 20,
                color: context.colors.onAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
