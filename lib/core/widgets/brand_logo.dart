import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'logo_mark.dart';

/// Símbolo y nombre TRAVIO.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TRAVIO',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoMark(),
            SizedBox(width: 10),
            Text(
              'TRAVIO',
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
      ),
    );
  }
}
