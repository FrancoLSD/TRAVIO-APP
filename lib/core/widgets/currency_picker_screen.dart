import 'package:flutter/material.dart';

import '../constants/currencies.dart';
import 'back_header.dart';
import 'currency_selector.dart';

/// Abre el selector de moneda a pantalla completa (design/SETTINGS - HOME CURRENCY.png).
/// Devuelve la elegida, o null si vuelve atrás.
Future<Currency?> pickCurrency(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Currency selected,
}) {
  return Navigator.of(context, rootNavigator: true).push<Currency>(
    MaterialPageRoute(
      builder: (context) => _CurrencyPickerScreen(
        title: title,
        subtitle: subtitle,
        selected: selected,
      ),
    ),
  );
}

class _CurrencyPickerScreen extends StatelessWidget {
  const _CurrencyPickerScreen({
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final Currency selected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(title: title),
            Expanded(
              child: CurrencySelector(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                header: [
                  Text(title, style: text.headlineLarge),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: text.bodyMedium?.copyWith(fontSize: 16, height: 1.4),
                  ),
                ],
                pinned: selected,
                pinnedLabel: 'SELECTED',
                othersLabel: 'ALL CURRENCIES',
                selected: selected,
                onSelected: (c) => Navigator.pop(context, c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
