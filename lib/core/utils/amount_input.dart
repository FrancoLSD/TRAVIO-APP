import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Decimales habituales de la moneda (JPY 0, EUR 2, BHD 3).
int currencyDecimals(String code) =>
    NumberFormat.currency(locale: 'en_US', name: code).decimalDigits ?? 2;

/// '1234.5' o '1,234.5' → 1234.5.
double? parseAmount(String text) => double.tryParse(text.replaceAll(',', ''));

/// '43,705', '250.50'; sin '.00' cuando no hacen falta (informe §5.1).
String formatAmount(double value, int decimals) {
  final text = NumberFormat.decimalPatternDigits(
    locale: 'en_US',
    decimalDigits: decimals,
  ).format(value);
  return decimals > 0 && text.endsWith('.${'0' * decimals}')
      ? text.substring(0, text.length - decimals - 1)
      : text;
}

/// Separa los miles mientras se escribe y limita los decimales de la moneda.
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter(this.decimals);

  final int decimals;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    // Con el iPhone en español, la tecla decimal escribe una coma: es el decimal, no los miles.
    if (text.length == oldValue.text.length + 1 && text.endsWith(',')) {
      text = '${text.substring(0, text.length - 1)}.';
    }
    final raw = text.replaceAll(',', '');
    if (raw.isEmpty) return const TextEditingValue();
    final valid = decimals == 0
        ? RegExp(r'^\d{0,12}$')
        : RegExp('^\\d{0,12}(\\.\\d{0,$decimals})?\$');
    if (!valid.hasMatch(raw)) return oldValue;
    final parts = raw.split('.');
    final whole = parts[0].isEmpty
        ? ''
        : NumberFormat('#,##0', 'en_US').format(int.parse(parts[0]));
    final formatted = parts.length > 1 ? '$whole.${parts[1]}' : whole;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
