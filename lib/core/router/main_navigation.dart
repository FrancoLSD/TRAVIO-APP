import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Menú principal (design/MENÚ DE NAVEGACIÓN.png): 4 pestañas, activa en acento, sin indicador.
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.background,
          border: Border(
            top: BorderSide(color: context.colors.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: shell.currentIndex,
          // Volver a tocar la pestaña activa la devuelve a su raíz.
          onTap: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          type: BottomNavigationBarType.fixed,
          backgroundColor: context.colors.background,
          elevation: 0,
          selectedItemColor: context.colors.accent,
          unselectedItemColor: context.colors.textSecondary,
          selectedFontSize: 13,
          unselectedFontSize: 13,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          iconSize: 26,
          // shortcut: iconos Material, sustituir por los iconos propios de TRAVIO cuando estén exportados.
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sync_alt),
              label: 'Convert',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.luggage_outlined),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              label: 'You',
            ),
          ],
        ),
      ),
    );
  }
}
