import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

/// Menú principal (design/MENÚ DE NAVEGACIÓN.png): 4 pestañas con iconos propios (design/SVG ICONS).
/// La activa va en acento sobre una píldora; al pulsar, el icono se encoge y rebota (sin onda de Material).
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    ('convert', 'Convert'),
    ('trips', 'Trips'),
    ('alerts', 'Alerts'),
    ('you', 'You'),
  ];

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
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                for (final (i, (icon, label)) in _tabs.indexed)
                  Expanded(
                    child: _NavItem(
                      icon: icon,
                      label: label,
                      selected: i == shell.currentIndex,
                      onTap: () {
                        if (i != shell.currentIndex) {
                          HapticFeedback.selectionClick();
                        }
                        // Volver a tocar la pestaña activa la devuelve a su raíz.
                        shell.goBranch(
                          i,
                          initialLocation: i == shell.currentIndex,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  var _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = widget.selected ? colors.accent : colors.textSecondary;
    const duration = Duration(milliseconds: 220);
    return Semantics(
      button: true,
      selected: widget.selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.85 : 1,
          // Al soltar vuelve con un rebote suave.
          duration: _pressed ? const Duration(milliseconds: 90) : duration * 2,
          curve: _pressed ? Curves.easeOut : Curves.elasticOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(
                    alpha: widget.selected ? 0.12 : 0,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: AppIcon(widget.icon, size: 24, color: color),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: duration,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
