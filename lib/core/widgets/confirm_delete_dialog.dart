import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_icon.dart';

/// Diálogo de borrar (referencias en design/SVG ICONS/DELETE CONFIRMATION EXAMPLES):
/// papelera ilustrada que entra con un pequeño rebote, texto centrado y dos botones. true si confirma.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final confirmed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, _) => _ConfirmDeleteDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    ),
  );
  return confirmed ?? false;
}

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TrashIllustration(),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    'Cancel',
                    background: colors.fillStrong,
                    foreground: colors.text,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    confirmLabel,
                    background: colors.destructive,
                    foreground: colors.onAccent,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Papelera sobre un círculo rojo suave, con destellos y sombra, como en las referencias.
class _TrashIllustration extends StatelessWidget {
  const _TrashIllustration();

  @override
  Widget build(BuildContext context) {
    final red = context.colors.destructive;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: 150,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 92,
              height: 10,
              decoration: BoxDecoration(
                color: red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          for (final (x, y, plus) in const [
            (-62.0, -18.0, true),
            (54.0, -34.0, true),
            (-46.0, 22.0, false),
            (60.0, 14.0, false),
            (-8.0, -48.0, false),
          ])
            Transform.translate(
              offset: Offset(x, y),
              child: plus
                  ? Icon(Icons.add, size: 14, color: red.withValues(alpha: 0.6))
                  : Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (context, t, child) => Transform.rotate(
              // Un pequeño balanceo al aparecer.
              angle: (1 - t) * -0.35 * sin(t * pi),
              child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
            ),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AppIcon('delete', size: 38, color: red),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton(
    this.label, {
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
