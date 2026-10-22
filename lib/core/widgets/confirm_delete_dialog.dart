import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Diálogo de borrar con el estilo de design/ALERTS - DELETE ALL DIALOG.png. true si confirma.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: context.colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: context.colors.destructive.withValues(
                alpha: 0.1,
              ),
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: context.colors.destructive,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    'Cancel',
                    background: context.colors.fillStrong,
                    foreground: context.colors.text,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    confirmLabel,
                    background: context.colors.destructive,
                    foreground: context.colors.onAccent,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
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
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
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
