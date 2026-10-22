import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botón principal de ancho completo con flecha («Continue →»).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Muestra un indicador en lugar del texto y no deja pulsar.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.accent,
          foregroundColor: context.colors.onAccent,
          disabledBackgroundColor: loading ? context.colors.accent : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.colors.onAccent,
                  semanticsLabel: 'Processing',
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}
