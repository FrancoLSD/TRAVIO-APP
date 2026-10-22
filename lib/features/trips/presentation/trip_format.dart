import 'package:intl/intl.dart';

/// 'Oct 12 — Oct 26'; con el año si no es el actual ('Nov 14 — Nov 21, 2025')
/// y en ambas fechas si el viaje cambia de año.
String formatTripDates(DateTime start, DateTime end, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final short = DateFormat('MMM d', 'en_US');
  final long = DateFormat('MMM d, y', 'en_US');
  if (start.year != end.year) {
    return '${long.format(start)} — ${long.format(end)}';
  }
  if (end.year != now.year) {
    return '${short.format(start)} — ${long.format(end)}';
  }
  return '${short.format(start)} — ${short.format(end)}';
}
