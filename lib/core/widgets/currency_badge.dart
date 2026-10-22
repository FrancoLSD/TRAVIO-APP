import 'package:flutter/material.dart';

import '../constants/currencies.dart';
import '../theme/app_theme.dart';

/// Círculo con el símbolo de la moneda, en [color] (por defecto el azul de las monedas).
class CurrencyBadge extends StatelessWidget {
  const CurrencyBadge(this.currency, {super.key, this.size = 40, this.color});

  final Currency currency;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.badge;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Text(
        currency.symbol,
        maxLines: 1,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
