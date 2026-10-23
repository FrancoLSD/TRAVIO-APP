import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_icon.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/currency_badge.dart';
import '../../../core/widgets/keyboard_done_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../rates/data/rates_repository.dart';
import '../data/trips_repository.dart';
import '../domain/expense.dart';
import '../domain/trip.dart';
import 'expense_sheet.dart';
import 'trip_format.dart';

TextStyle _mono(BuildContext context) =>
    TextStyle(fontFamily: AppFonts.mono, color: context.colors.textSecondary);
const _visibleExpenses = 6;

/// Detalle de un viaje (design/TRIP DETAIL.png): presupuesto, conversión rápida, categorías y gastos.
class TripDetailScreen extends ConsumerStatefulWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  final _amount = TextEditingController();
  final _amountFocus = FocusNode();

  /// false: se escribe en moneda local (JPY → EUR); true: en la de casa (EUR → JPY).
  bool _fromHome = false;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  double? get _typed {
    final value = double.tryParse(_amount.text.replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete this trip?',
      message:
          "This deletes ${trip.destination} and all its expenses. It can't be undone.",
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    ref
        .read(tripsRepositoryProvider)
        .deleteTrip(ref.read(authRepositoryProvider).uid!, trip.id)
        .catchError((Object _) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text("Couldn't delete the trip. Please try again."),
            ),
          );
        });
    context.go('/trips');
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripsProvider);
    final trip = trips.value?.where((t) => t.id == widget.tripId).firstOrNull;
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: context.colors.background),
        body: Center(
          child: trips.isLoading
              ? const CircularProgressIndicator()
              : Text(
                  'This trip no longer exists.',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
        ),
      );
    }
    final expenses =
        ref.watch(expensesProvider(trip.id)).value ?? const <Expense>[];
    final rates = ref.watch(ratesProvider).value;
    final today = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      _CircleButton(
                        tooltip: 'Back',
                        icon: Icons.chevron_left,
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/trips'),
                      ),
                      const Spacer(),
                      // Menú propio estilo iOS: tarjeta con borde y sombra suave bajo el botón, sin onda de Material.
                      Theme(
                        data: Theme.of(context).copyWith(
                          splashFactory: NoSplash.splashFactory,
                          highlightColor: Colors.transparent,
                        ),
                        child: PopupMenuButton<String>(
                          tooltip: 'Trip options',
                          position: PopupMenuPosition.under,
                          offset: const Offset(0, 8),
                          color: context.colors.card,
                          surfaceTintColor: Colors.transparent,
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.12),
                          menuPadding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 210),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: context.colors.border),
                          ),
                          popUpAnimationStyle: const AnimationStyle(
                            duration: Duration(milliseconds: 220),
                            reverseDuration: Duration(milliseconds: 150),
                          ),
                          onSelected: (_) => _deleteTrip(trip),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'delete',
                              height: 46,
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                height: 46,
                                decoration: BoxDecoration(
                                  color: context.colors.destructive.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Delete trip',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: context.colors.destructive,
                                        ),
                                      ),
                                    ),
                                    AppIcon(
                                      'delete',
                                      size: 20,
                                      color: context.colors.destructive,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          child: const _CircleButton(icon: Icons.more_horiz),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: trip.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusLine(trip, today),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trip.destination,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatTripDates(trip.startDate, trip.endDate)} · ${trip.homeCurrency} → ${trip.localCurrency}',
                    style: TextStyle(
                      fontSize: 15,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SpentCard(trip: trip, today: today),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(child: _Title('Quick convert')),
                      if (rates?.convert(
                            1,
                            trip.homeCurrency,
                            trip.localCurrency,
                          )
                          case final rate?)
                        Text(
                          '1 ${trip.homeCurrency} = ${NumberFormat('#,##0.####', 'en_US').format(rate)} ${trip.localCurrency}',
                          style: _mono(context).copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _quickConvert(trip, rates, today),
                  const SizedBox(height: 28),
                  const _Title('By category'),
                  const SizedBox(height: 12),
                  _byCategory(trip, expenses),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(child: _Title('Expenses')),
                      if (expenses.length > _visibleExpenses)
                        TextButton(
                          onPressed: () => setState(() => _showAll = !_showAll),
                          style: TextButton.styleFrom(
                            foregroundColor: context.colors.accent,
                          ),
                          child: Text(
                            _showAll ? 'Show less' : 'See all',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _expenseList(trip, expenses),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_done_outlined,
                        size: 16,
                        color: context.colors.textSecondary,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Works offline with your saved rates',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_amountFocus.hasFocus)
              KeyboardDoneBar(onDone: _amountFocus.unfocus),
          ],
        ),
      ),
    );
  }

  static String _statusLine(Trip trip, DateTime today) => switch (trip.statusOn(
    today,
  )) {
    TripStatus.active =>
      'ACTIVE · DAY ${trip.daysElapsedOn(today)} OF ${trip.totalDays}',
    TripStatus.upcoming => () {
      final days = trip.startDate.difference(DateUtils.dateOnly(today)).inDays;
      return 'UPCOMING · IN $days ${days == 1 ? 'DAY' : 'DAYS'}';
    }(),
    TripStatus.previous =>
      'ENDED · ${trip.totalDays} ${trip.totalDays == 1 ? 'DAY' : 'DAYS'}',
  };

  Widget _quickConvert(Trip trip, Rates? rates, DateTime today) {
    final from = _fromHome ? trip.homeCurrency : trip.localCurrency;
    final to = _fromHome ? trip.localCurrency : trip.homeCurrency;
    final typed = _typed;
    final converted = typed == null ? null : rates?.convert(typed, from, to);
    // El gasto siempre se guarda en moneda local.
    final local = _fromHome ? converted : typed;
    final canLog = trip.expenseDaysOn(today) != null;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CurrencyPill(from),
              IconButton(
                tooltip: 'Swap currencies',
                onPressed: () => setState(() => _fromHome = !_fromHome),
                icon: Icon(
                  Icons.sync_alt,
                  size: 18,
                  color: context.colors.accent,
                ),
              ),
              _CurrencyPill(to),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                currencySymbol(from),
                style: _amountStyle(
                  context,
                ).copyWith(color: context.colors.textSecondary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _amount,
                  focusNode: _amountFocus,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,9}([.,]\d{0,2})?'),
                    ),
                  ],
                  style: _amountStyle(context),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: context.colors.textSecondary),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            converted == null
                ? (rates == null ? 'Rates unavailable' : ' ')
                : '≈ ${formatMoney(converted, to, decimals: 2)}',
            style: _mono(context).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.accent,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save as expense',
            onPressed: canLog && local != null
                ? () async {
                    _amountFocus.unfocus();
                    await showSaveExpenseSheet(
                      context,
                      trip,
                      double.parse(local.toStringAsFixed(2)),
                    );
                    if (mounted) setState(_amount.clear);
                  }
                : null,
          ),
          if (!canLog) ...[
            const SizedBox(height: 10),
            Text(
              'You can log expenses once the trip starts.',
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static TextStyle _amountStyle(BuildContext context) => TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 38,
    fontWeight: FontWeight.w600,
    color: context.colors.text,
  );

  Widget _byCategory(Trip trip, List<Expense> expenses) {
    return _Rows([
      for (final category in ExpenseCategory.values)
        () {
          final items = expenses.where((e) => e.category == category);
          final local = items.fold(0.0, (sum, e) => sum + e.amountLocal);
          final home = items.fold(0.0, (sum, e) => sum + e.amountHome);
          return _Row(
            icon: category.icon,
            title: category.label,
            amount: formatMoney(local, trip.localCurrency),
            equivalent: '≈ ${formatMoney(home, trip.homeCurrency)}',
          );
        }(),
    ]);
  }

  Widget _expenseList(Trip trip, List<Expense> expenses) {
    if (expenses.isEmpty) {
      return _Card(
        child: Text(
          'No expenses yet. Convert an amount above and save it as an expense.',
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: context.colors.textSecondary,
          ),
        ),
      );
    }
    final visible = _showAll ? expenses : expenses.take(_visibleExpenses);
    return _Rows([
      for (final expense in visible)
        _Row(
          key: ValueKey(expense.id),
          // Tocar un gasto abre su edición, que también permite borrarlo.
          onTap: () => showEditExpenseSheet(context, trip, expense),
          icon: expense.category.icon,
          title: expense.name,
          subtitle: DateFormat(
            "MMM d '·' HH:mm",
            'en_US',
          ).format(expense.dateTime),
          amount: formatMoney(
            expense.amountLocal,
            trip.localCurrency,
            decimals: _decimals(expense.amountLocal),
          ),
          equivalent:
              '≈ ${formatMoney(expense.amountHome, trip.homeCurrency, decimals: 2)}',
        ),
    ]);
  }

  static int _decimals(double amount) =>
      amount == amount.roundToDouble() ? 0 : 2;
}

class _SpentCard extends StatelessWidget {
  const _SpentCard({required this.trip, required this.today});

  final Trip trip;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final budget = trip.budget != null && trip.budget! > 0 ? trip.budget : null;
    final status = trip.statusOn(today);
    final elapsed = trip.daysElapsedOn(today);
    final spentLocal = '≈ ${formatMoney(trip.spentLocal, trip.localCurrency)}';
    final left = budget == null ? 0.0 : budget - trip.spentHome;
    // Días que quedan contando hoy.
    final daysLeft = trip.totalDays - elapsed + 1;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatMoney(trip.spentHome, trip.homeCurrency),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: context.colors.text,
                  ),
                ),
                if (budget != null)
                  TextSpan(
                    text: '  / ${formatMoney(budget, trip.homeCurrency)}',
                    style: const TextStyle(fontSize: 16),
                  ),
              ],
            ),
            style: _mono(context),
          ),
          if (budget != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (trip.spentHome / budget).clamp(0.0, 1.0),
                minHeight: 6,
                color: trip.color,
                backgroundColor: trip.color.withValues(alpha: 0.18),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$spentLocal · ${(trip.spentHome / budget * 100).round()}% used',
                    style: _mono(context).copyWith(fontSize: 13),
                  ),
                ),
                Text(
                  left >= 0
                      ? '${formatMoney(left, trip.homeCurrency)} left'
                      : '${formatMoney(-left, trip.homeCurrency)} over',
                  style: _mono(context).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: left >= 0
                        ? context.colors.text
                        : context.colors.destructive,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              '$spentLocal spent',
              style: _mono(context).copyWith(fontSize: 13),
            ),
          ],
          if (status != TripStatus.upcoming) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: context.colors.border),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    'Average per day',
                    formatMoney(trip.spentHome / elapsed, trip.homeCurrency),
                  ),
                ),
                if (budget != null && status == TripStatus.active)
                  Expanded(
                    child: _Stat(
                      'Left per day',
                      formatMoney(
                        left > 0 ? left / daysLeft : 0,
                        trip.homeCurrency,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: _mono(context).copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.colors.text,
          ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      color: context.colors.text,
    ),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onPressed, this.tooltip});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.colors.card,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.border),
      ),
      child: Icon(icon, color: context.colors.text),
    );
    if (onPressed == null) return circle;
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(onTap: onPressed, child: circle),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: context.colors.fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyBadge(currencyByCode(code), size: 24),
          const SizedBox(width: 6),
          Text(
            code,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.colors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}

/// Tarjeta blanca con filas separadas por líneas.
class _Rows extends StatelessWidget {
  const _Rows(this.rows);

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 64, color: context.colors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    this.onTap,
    required this.icon,
    required this.title,
    required this.amount,
    required this.equivalent,
    this.subtitle,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final String amount;
  final String equivalent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: context.colors.fill,
            child: AppIcon(icon, size: 18, color: context.colors.text),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.colors.text,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: _mono(context).copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: _mono(context).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.text,
                ),
              ),
              Text(equivalent, style: _mono(context).copyWith(fontSize: 12)),
            ],
          ),
          // Indica que el gasto se puede tocar para editarlo.
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 20, color: context.colors.chevron),
          ],
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
