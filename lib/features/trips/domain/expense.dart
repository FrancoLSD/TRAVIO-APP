enum ExpenseCategory {
  food('Food'),
  transport('Transport'),
  hotel('Hotel'),
  shopping('Shopping'),
  entertainment('Entertainment'),
  other('Other');

  const ExpenseCategory(this.label);

  final String label;

  /// Icono propio en assets/icons (mismo nombre que la categoría).
  String get icon => name;
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
