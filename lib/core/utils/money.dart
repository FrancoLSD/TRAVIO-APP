import 'package:intl/intl.dart';

import '../constants/currencies.dart';

/// '€', '¥'; el código si la moneda no está en la lista.
String currencySymbol(String currencyCode) =>
    findCurrency(currencyCode)?.symbol ?? currencyCode;

/// '€1,250', '¥92,400'. Con una moneda desconocida usa el código ('VES 10').
String formatMoney(double amount, String currencyCode, {int decimals = 0}) {
  final symbol = findCurrency(currencyCode)?.symbol ?? '$currencyCode ';
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: symbol,
    decimalDigits: decimals,
  ).format(amount);
}
