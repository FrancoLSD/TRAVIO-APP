import 'package:flutter/material.dart';

import '../constants/currencies.dart';
import '../theme/app_theme.dart';
import 'currency_badge.dart';
import 'section_label.dart';

/// Lista de monedas con buscador: una destacada arriba ([pinned]) y el resto debajo.
class CurrencySelector extends StatefulWidget {
  const CurrencySelector({
    super.key,
    required this.header,
    required this.pinned,
    required this.pinnedLabel,
    required this.othersLabel,
    required this.selected,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  /// Título y texto que van encima del buscador.
  final List<Widget> header;
  final Currency pinned;
  final String pinnedLabel;
  final String othersLabel;
  final Currency selected;
  final ValueChanged<Currency> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  State<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> {
  String _query = '';

  bool _matches(Currency c) {
    final q = _query.trim().toLowerCase();
    return c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final showSuggested = _matches(widget.pinned);
    final others = currencies
        .where((c) => c.code != widget.pinned.code && _matches(c))
        .toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: widget.padding,
      children: [
        ...widget.header,
        const SizedBox(height: 24),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 17, color: context.colors.text),
          decoration: InputDecoration(
            hintText: 'Search currency',
            hintStyle: TextStyle(color: context.colors.textSecondary),
            prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
            filled: true,
            fillColor: context.colors.card,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: _border(context.colors.border),
            focusedBorder: _border(context.colors.accent),
          ),
        ),
        if (showSuggested) ...[
          SectionLabel(widget.pinnedLabel),
          Material(
            color: context.colors.card,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: widget.selected.code == widget.pinned.code
                    ? context.colors.accent
                    : context.colors.border,
              ),
            ),
            child: _row(widget.pinned),
          ),
        ],
        if (others.isNotEmpty) ...[
          SectionLabel(widget.othersLabel),
          Material(
            color: context.colors.card,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: context.colors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < others.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 68,
                      color: context.colors.border,
                    ),
                  _row(others[i]),
                ],
              ],
            ),
          ),
        ],
        if (!showSuggested && others.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 32),
            child: Text(
              'No currencies found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.colors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color),
  );

  Widget _row(Currency c) {
    final selected = c.code == widget.selected.code;
    return Semantics(
      selected: selected,
      child: InkWell(
        onTap: () => widget.onSelected(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CurrencyBadge(c, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: context.colors.text,
                      ),
                    ),
                    Text(
                      c.code,
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check, color: context.colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
