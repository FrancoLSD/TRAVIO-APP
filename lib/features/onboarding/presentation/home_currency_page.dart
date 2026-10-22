import 'package:flutter/material.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/widgets/currency_selector.dart';

/// Paso 3: moneda de casa, con la de la región ya marcada.
class HomeCurrencyPage extends StatelessWidget {
  const HomeCurrencyPage({
    super.key,
    required this.selected,
    required this.suggested,
    required this.onSelected,
  });

  final Currency selected;
  final Currency suggested;
  final ValueChanged<Currency> onSelected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CurrencySelector(
      padding: const EdgeInsets.only(top: 40, bottom: 8),
      header: [
        Text('Your home currency', style: text.headlineLarge),
        const SizedBox(height: 10),
        Text(
          'We’ll show amounts in this currency. You can change it later in You.',
          style: text.bodyMedium?.copyWith(fontSize: 17, height: 1.4),
        ),
      ],
      pinned: suggested,
      pinnedLabel: 'SUGGESTED FOR YOUR REGION',
      othersLabel: 'OTHER CURRENCIES',
      selected: selected,
      onSelected: onSelected,
    );
  }
}
