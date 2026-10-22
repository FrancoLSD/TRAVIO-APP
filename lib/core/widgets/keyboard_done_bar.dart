import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra encima del teclado con el botón Done: el teclado numérico de iOS no tiene tecla para cerrarse.
/// Se coloca al final del cuerpo del Scaffold, que el teclado empuja hacia arriba.
class KeyboardDoneBar extends StatelessWidget {
  const KeyboardDoneBar({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: TextButton(
        onPressed: onDone,
        style: TextButton.styleFrom(foregroundColor: context.colors.accent),
        child: const Text(
          'Done',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
