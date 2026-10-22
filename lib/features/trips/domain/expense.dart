import 'package:flutter/material.dart';

enum ExpenseCategory {
  food('Food', Icons.restaurant_outlined),
  transport('Transport', Icons.train_outlined),
  hotel('Hotel', Icons.hotel_outlined),
  shopping('Shopping', Icons.shopping_bag_outlined),
  entertainment('Entertainment', Icons.local_activity_outlined),
  other('Other', Icons.more_horiz);

  const ExpenseCategory(this.label, this.icon);

  final String label;
  // shortcut: iconos Material; cambiarlos por los iconos propios de TRAVIO cuando estén exportados.
  final IconData icon;
}

/// Gasto de un viaje. El importe va siempre en la moneda local del viaje.
class Expense {
  const Expense({
    required this.id,
    required this.name,
    required this.category,
    required this.amountLocal,
    required this.rate,
    required this.rateDate,
    required this.dateTime,
    this.rateOffline = false,
  });

  final String id;
  final String name;
  final ExpenseCategory category;
  final double amountLocal;

  /// Moneda local por 1 de la moneda de casa (1 EUR = 174.82 JPY → 174.82), del día del gasto.
  /// Se guarda y no se recalcula (informe §5.10).
  final double rate;

  /// Día de la tasa usada, 'yyyy-MM-dd'.
  final String rateDate;

  /// true si se guardó sin conexión con la última tasa disponible en el iPhone.
  final bool rateOffline;
  final DateTime dateTime;

  double get amountHome => amountLocal / rate;
}
