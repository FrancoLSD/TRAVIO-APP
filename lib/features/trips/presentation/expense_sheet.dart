import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_icon.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/keyboard_done_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_label.dart';
import '../../auth/data/auth_repository.dart';
import '../../rates/data/rates_repository.dart';
import '../data/trips_repository.dart';
import '../domain/expense.dart';
import '../domain/trip.dart';

/// Hoja «Save expense» (design/TRIP DETAIL - SAVE EXPENSE.png) para un importe en moneda local.
Future<void> showSaveExpenseSheet(
  BuildContext context,
  Trip trip,
  double amountLocal,
) => _show(context, _ExpenseSheet(trip: trip, amountLocal: amountLocal));

/// La misma hoja para editar nombre, categoría e importe, o borrar el gasto; la fecha y la tasa no cambian (informe §5.10).
Future<void> showEditExpenseSheet(
  BuildContext context,
  Trip trip,
  Expense expense,
) => _show(
  context,
  _ExpenseSheet(trip: trip, amountLocal: expense.amountLocal, editing: expense),
);

Future<void> _show(BuildContext context, Widget sheet) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => sheet,
    );

/// Tasa aplicada: moneda local por 1 de la moneda de casa.
typedef _Rate = ({double rate, String date, bool offline});

class _ExpenseSheet extends ConsumerStatefulWidget {
  const _ExpenseSheet({
    required this.trip,
    required this.amountLocal,
    this.editing,
  });

  final Trip trip;
  final double amountLocal;
  final Expense? editing;

  @override
  ConsumerState<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<_ExpenseSheet> {
  late final _name = TextEditingController(text: widget.editing?.name);
  late final _amount = TextEditingController(text: _plain(widget.amountLocal));
  final _amountFocus = FocusNode();
  late ExpenseCategory _category =
      widget.editing?.category ?? ExpenseCategory.food;
  late DateTime _dateTime = widget.editing?.dateTime ?? _defaultDateTime();

  /// null mientras carga; la de un gasto editado es la suya.
  _Rate? _rate;
  bool _rateFailed = false;

  bool get _editing => widget.editing != null;
  Trip get _trip => widget.trip;

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(() => setState(() {}));
    final editing = widget.editing;
    if (editing != null) {
      _rate = (
        rate: editing.rate,
        date: editing.rateDate,
        offline: editing.rateOffline,
      );
    } else {
      _loadRate();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  /// Ahora, o el último día posible del viaje con la hora actual si ya terminó.
  DateTime _defaultDateTime() {
    final now = DateTime.now();
    final last = _trip.expenseDaysOn(now)!.end;
    return DateUtils.isSameDay(last, now)
        ? now
        : DateTime(last.year, last.month, last.day, now.hour, now.minute);
  }

  /// '1200' o '6.5', sin ceros de sobra, para el campo de importe.
  static String _plain(double value) =>
      NumberFormat('0.##', 'en_US').format(value);

  double? get _amountLocal {
    if (!_editing) return widget.amountLocal;
    final value = double.tryParse(_amount.text.replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  Future<void> _loadRate() async {
    setState(() {
      _rate = null;
      _rateFailed = false;
    });
    final day = _dateTime;
    try {
      final result = await ref.read(ratesRepositoryProvider).on(day, {
        _trip.homeCurrency,
        _trip.localCurrency,
      });
      final rate = result.rates.convert(
        1,
        _trip.homeCurrency,
        _trip.localCurrency,
      );
      if (!mounted || day != _dateTime) return;
      setState(() {
        _rate = rate == null
            ? null
            : (rate: rate, date: result.rates.date, offline: result.offline);
        _rateFailed = rate == null;
      });
    } catch (_) {
      if (mounted && day == _dateTime) setState(() => _rateFailed = true);
    }
  }

  Future<void> _changeDateTime() async {
    final days = _trip.expenseDaysOn(DateTime.now())!;
    final date = await showDatePicker(
      context: context,
      firstDate: days.start,
      lastDate: days.end,
      initialDate: DateUtils.dateOnly(_dateTime),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      // Solo escribir la hora, sin la esfera del reloj.
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );
    if (!mounted) return;
    var picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? _dateTime.hour,
      time?.minute ?? _dateTime.minute,
    );
    // Hoy no se puede elegir una hora que aún no ha llegado.
    if (picked.isAfter(DateTime.now())) picked = DateTime.now();
    final dayChanged = !DateUtils.isSameDay(picked, _dateTime);
    setState(() => _dateTime = picked);
    if (dayChanged) _loadRate();
  }

  void _save() {
    final rate = _rate!;
    final name = _name.text.trim();
    final expense = Expense(
      id: widget.editing?.id ?? '',
      name: name.isEmpty ? _category.label : name,
      category: _category,
      amountLocal: _amountLocal!,
      rate: rate.rate,
      rateDate: rate.date,
      rateOffline: rate.offline,
      dateTime: _dateTime,
    );
    final uid = ref.read(authRepositoryProvider).uid!;
    final repository = ref.read(tripsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    // Sin await: Firestore guarda en local al momento y sincroniza al volver la conexión.
    final saving = _editing
        ? repository.updateExpense(uid, _trip.id, widget.editing!, expense)
        : repository.addExpense(uid, _trip.id, expense);
    saving.catchError((Object _) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't save the expense. Please try again."),
        ),
      );
    });
    if (!_editing) HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final expense = widget.editing!;
    final confirmed = await confirmDelete(
      context,
      title: 'Delete this expense?',
      message:
          "${expense.name} (${formatMoney(expense.amountLocal, _trip.localCurrency)}) will be removed. It can't be undone.",
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    ref
        .read(tripsRepositoryProvider)
        .deleteExpense(ref.read(authRepositoryProvider).uid!, _trip.id, expense)
        .catchError((Object _) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text("Couldn't delete the expense. Please try again."),
            ),
          );
        });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amountLocal;
    final rate = _rate;
    final canSave = amount != null && rate != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _editing ? 'Edit expense' : 'Save expense',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: context.colors.text,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.fillStrong,
                      ),
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: context.colors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Box(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _editing
                                ? _amountField()
                                : Text(
                                    formatMoney(
                                      amount!,
                                      _trip.localCurrency,
                                      decimals: _decimals(amount),
                                    ),
                                    style: _bigAmount(context),
                                  ),
                            const SizedBox(height: 4),
                            Text(
                              _rateLabel(),
                              style: TextStyle(
                                fontFamily: AppFonts.mono,
                                fontSize: 12,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (amount != null && rate != null)
                        Text(
                          '≈ ${formatMoney(amount / rate.rate, _trip.homeCurrency, decimals: 2)}',
                          style: TextStyle(
                            fontFamily: AppFonts.mono,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: context.colors.accent,
                          ),
                        ),
                    ],
                  ),
                ),
                const SectionLabel('NAME'),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(fontSize: 17, color: context.colors.text),
                  decoration: InputDecoration(
                    hintText: 'e.g. Ramen',
                    hintStyle: TextStyle(color: context.colors.textSecondary),
                    filled: true,
                    fillColor: context.colors.card,
                    enabledBorder: _border(context.colors.border),
                    focusedBorder: _border(context.colors.accent),
                  ),
                ),
                const SectionLabel('CATEGORY'),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    for (final category in ExpenseCategory.values)
                      _CategoryTile(
                        category: category,
                        selected: category == _category,
                        onTap: () => setState(() => _category = category),
                      ),
                  ],
                ),
                const SectionLabel('DATE & TIME'),
                _Box(
                  padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat(
                            "MMM d '·' HH:mm",
                            'en_US',
                          ).format(_dateTime),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: context.colors.text,
                          ),
                        ),
                      ),
                      if (!_editing)
                        TextButton(
                          onPressed: _changeDateTime,
                          style: TextButton.styleFrom(
                            foregroundColor: context.colors.accent,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _editing
                      ? "The date and rate of a saved expense can't be changed."
                      : 'Uses the rate from the day you pick.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _editing ? 'Save changes' : 'Save to ${_trip.city}',
                  onPressed: canSave ? _save : null,
                ),
                if (_editing) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _delete,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.colors.destructive,
                        foregroundColor: context.colors.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const AppIcon('delete', size: 20),
                      label: const Text(
                        'Delete expense',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_amountFocus.hasFocus)
            KeyboardDoneBar(onDone: _amountFocus.unfocus),
        ],
      ),
    );
  }

  static TextStyle _bigAmount(BuildContext context) => TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: context.colors.text,
  );

  /// Decimales solo si el importe los tiene (¥1,200 pero €6.50).
  static int _decimals(double amount) =>
      amount == amount.roundToDouble() ? 0 : 2;

  Widget _amountField() {
    return Row(
      children: [
        Text(
          currencySymbol(_trip.localCurrency),
          style: _bigAmount(context).copyWith(color: context.colors.accent),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: _amount,
            focusNode: _amountFocus,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d{0,9}([.,]\d{0,2})?'),
              ),
            ],
            style: _bigAmount(context),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
      ],
    );
  }

  String _rateLabel() {
    if (_rateFailed) {
      return 'No rate available for ${_trip.localCurrency}. Check your connection.';
    }
    final rate = _rate;
    if (rate == null) return 'Getting the rate…';
    final day = DateFormat('MMM d', 'en_US').format(DateTime.parse(rate.date));
    final value = NumberFormat('#,##0.####', 'en_US').format(rate.rate);
    return rate.offline
        ? 'Rate for $day (saved offline): $value'
        : 'Rate for $day: $value';
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color),
  );
}

class _Box extends StatelessWidget {
  const _Box({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.accent : context.colors.text;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? context.colors.accent.withValues(alpha: 0.09)
            : context.colors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? context.colors.accent : context.colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(category.icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
