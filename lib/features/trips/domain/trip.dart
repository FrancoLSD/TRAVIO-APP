import 'package:flutter/material.dart' show Color, DateTimeRange;

enum TripStatus { active, upcoming, previous }

class Trip {
  const Trip({
    required this.id,
    required this.destination,
    required this.countryCode,
    required this.homeCurrency,
    required this.localCurrency,
    required this.startDate,
    required this.endDate,
    this.budget,
    this.spentHome = 0,
    this.spentLocal = 0,
  });

  final String id;

  /// 'Tokyo, Japan'; también es el nombre del viaje.
  final String destination;
  final String countryCode;
  final String homeCurrency;
  final String localCurrency;

  /// Fechas sin hora (00:00 local), ambas incluidas en el viaje.
  final DateTime startDate;
  final DateTime endDate;

  /// En la moneda de casa; null = sin presupuesto.
  final double? budget;

  TripStatus statusOn(DateTime day) {
    final today = DateTime(day.year, day.month, day.day);
    if (today.isBefore(startDate)) return TripStatus.upcoming;
    if (today.isAfter(endDate)) return TripStatus.previous;
    return TripStatus.active;
  }

  /// Totales de los gastos, que Firestore mantiene al guardar cada gasto.
  final double spentHome;
  final double spentLocal;

  Color get color => tripColor(countryCode);

  int get totalDays => endDate.difference(startDate).inDays + 1;

  /// Días del viaje ya empezados hasta [day] (incluido), entre 0 y [totalDays].
  int daysElapsedOn(DateTime day) {
    final today = DateTime(day.year, day.month, day.day);
    return (today.difference(startDate).inDays + 1).clamp(0, totalDays);
  }

  /// 'Tokyo' de 'Tokyo, Japan'.
  String get city => destination.split(',').first.trim();

  /// Días en los que se puede registrar un gasto: del inicio hasta hoy o el fin del viaje.
  /// null si el viaje aún no ha empezado.
  DateTimeRange? expenseDaysOn(DateTime day) {
    final today = DateTime(day.year, day.month, day.day);
    if (today.isBefore(startDate)) return null;
    return DateTimeRange(
      start: startDate,
      end: today.isAfter(endDate) ? endDate : today,
    );
  }
}

enum BudgetResult { under, on, over }

/// Resultado de un viaje terminado; null si no tiene presupuesto.
/// «On budget» si la diferencia es menor que el 1 % del presupuesto.
BudgetResult? budgetResult(double spent, double? budget) {
  if (budget == null || budget <= 0) return null;
  if ((spent - budget).abs() < budget * 0.01) return BudgetResult.on;
  return spent < budget ? BudgetResult.under : BudgetResult.over;
}

// Colores ya explorados en las maquetas; el resto sale de una paleta fija según el país.
const _countryColors = {
  'JP': Color(0xFFE86A6A),
  'US': Color(0xFF5B7CFA),
  'GB': Color(0xFF5969C9),
  'FR': Color(0xFF6B8FD4),
  'IT': Color(0xFF6FAF8A),
};
const _palette = [
  Color(0xFFE86A6A),
  Color(0xFF5B7CFA),
  Color(0xFF6FAF8A),
  Color(0xFFE0A050),
  Color(0xFF9B7AD8),
  Color(0xFF4FAFC0),
  Color(0xFFD87AA8),
  Color(0xFF8C9A5B),
];

/// Siempre el mismo color para el mismo país.
Color tripColor(String countryCode) =>
    _countryColors[countryCode] ??
    _palette[countryCode.codeUnits.fold(0, (a, b) => a + b) % _palette.length];
