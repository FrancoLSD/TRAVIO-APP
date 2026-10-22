import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/currency_picker_screen.dart';
import '../../../core/widgets/keyboard_done_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_label.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_profile_repository.dart';
import '../../rates/data/rates_repository.dart';
import '../data/destination_repository.dart';
import '../data/trips_repository.dart';
import '../domain/trip.dart';
import 'trip_format.dart';

/// Crear un viaje en una sola pantalla (design/NEW TRIP.png y NEW TRIP - EMPTY.png), sin la foto del destino.
class NewTripScreen extends ConsumerStatefulWidget {
  const NewTripScreen({super.key});

  @override
  ConsumerState<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends ConsumerState<NewTripScreen> {
  Destination? _destination;
  DateTimeRange? _dates;
  late Currency? _home = _defaultHomeCurrency();
  Currency? _local;
  final _budget = TextEditingController();
  final _budgetFocus = FocusNode();

  Currency? _defaultHomeCurrency() {
    final code =
        ref.read(homeCurrencyProvider).value ??
        ref.read(appPreferencesProvider).homeCurrency ??
        suggestedCurrency(PlatformDispatcher.instance.locale.toString()).code;
    return findCurrency(code);
  }

  /// null si está vacío o no es un número positivo.
  double? get _budgetAmount {
    final value = double.tryParse(_budget.text.replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  bool get _canCreate =>
      _destination != null && _dates != null && _home != null && _local != null;

  @override
  void initState() {
    super.initState();
    // La barra Done solo se ve mientras se escribe el presupuesto.
    _budgetFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _budget.dispose();
    _budgetFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _dates,
      helpText: 'Travel dates',
    );
    if (picked != null) setState(() => _dates = picked);
  }

  Future<void> _pickCurrency({required bool home}) async {
    final current = home ? _home : _local;
    final picked = await pickCurrency(
      context,
      title: home ? 'Home currency' : 'Destination currency',
      subtitle: home
          ? 'Used for this trip’s budget.'
          : 'The currency you’ll spend at your destination.',
      selected: current ?? currencyByCode('USD'),
    );
    if (picked == null) return;
    setState(() => home ? _home = picked : _local = picked);
  }

  void _create() {
    final uid = ref.read(authRepositoryProvider).uid;
    final destination = _destination!;
    final dates = _dates!;
    final trip = Trip(
      id: '',
      destination: destination.name,
      countryCode: destination.countryCode,
      homeCurrency: _home!.code,
      localCurrency: _local!.code,
      startDate: DateUtils.dateOnly(dates.start),
      endDate: DateUtils.dateOnly(dates.end),
      budget: _budgetAmount,
    );
    final messenger = ScaffoldMessenger.of(context);
    // Sin await: Firestore guarda en local al momento y sincroniza al volver la conexión.
    ref.read(tripsRepositoryProvider).createTrip(uid!, trip).catchError((
      Object _,
    ) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't save your trip. Please try again."),
        ),
      );
    });
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                      const BrandLogo(),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.close, color: context.colors.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('New Trip', style: text.headlineLarge),
                  const _Label('1. DESTINATION'),
                  _destination == null
                      ? _DestinationSearch(
                          onSelected: (d) => setState(() {
                            _destination = d;
                            // Moneda del país si el proveedor de tasas la cubre; si no, la elige el usuario.
                            _local = d.currencyCode == null
                                ? null
                                : findCurrency(d.currencyCode!);
                          }),
                        )
                      : _Card(
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: context.colors.accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _destination!.name,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w500,
                                    color: context.colors.text,
                                  ),
                                ),
                              ),
                              IconButton.filled(
                                tooltip: 'Change destination',
                                onPressed: () =>
                                    setState(() => _destination = null),
                                style: IconButton.styleFrom(
                                  backgroundColor: context.colors.fillStrong,
                                ),
                                icon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                  const _Label('2. DATES & DURATION'),
                  _Card(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.colors.fillStrong,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _dates == null
                                ? 'Select travel dates'
                                : formatTripDates(_dates!.start, _dates!.end),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: _dates == null
                                  ? FontWeight.w400
                                  : FontWeight.w500,
                              color: _dates == null
                                  ? context.colors.textSecondary
                                  : context.colors.text,
                            ),
                          ),
                        ),
                        _SmallButton(
                          _dates == null ? 'Select' : 'Change',
                          onPressed: _pickDates,
                        ),
                      ],
                    ),
                  ),
                  const _Label('3. CURRENCY PAIR', trailing: 'Home ⇄ Spending'),
                  _Card(
                    child: Row(
                      children: [
                        Expanded(
                          child: _CurrencyBox(
                            label: 'HOME BASE',
                            currency: _home,
                            onTap: () => _pickCurrency(home: true),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: context.colors.fillStrong,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.sync_alt,
                            size: 18,
                            color: context.colors.accent,
                          ),
                        ),
                        Expanded(
                          child: _CurrencyBox(
                            label: 'DESTINATION',
                            currency: _local,
                            onTap: () => _pickCurrency(home: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _Label(
                    '4. TOTAL BUDGET (OPTIONAL)',
                    trailing: 'Target limit',
                  ),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _home?.symbol ?? '—',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w600,
                                color: context.colors.accent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _budget,
                                focusNode: _budgetFocus,
                                onChanged: (_) => setState(() {}),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d{0,9}([.,]\d{0,2})?'),
                                  ),
                                ],
                                style: TextStyle(
                                  fontFamily: AppFonts.mono,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.text,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: context.colors.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _budgetHint(),
                          style: TextStyle(
                            fontFamily: AppFonts.mono,
                            fontSize: 14,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Create Trip',
                    onPressed: _canCreate ? _create : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ready for offline conversion, quick logging & budget tracking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // El teclado numérico de iOS no tiene tecla para cerrarse.
            if (_budgetFocus.hasFocus)
              KeyboardDoneBar(onDone: _budgetFocus.unfocus),
          ],
        ),
      ),
    );
  }

  /// '≈ ¥222,037 JPY' con la tasa de hoy, o 'No limit set'.
  String _budgetHint() {
    final amount = _budgetAmount;
    if (amount == null) return 'No limit set';
    final home = _home;
    final local = _local;
    if (home == null || local == null || home.code == local.code) {
      return 'Total budget';
    }
    final converted = ref
        .watch(ratesProvider)
        .value
        ?.convert(amount, home.code, local.code);
    return converted == null
        ? 'Total budget'
        : '≈ ${formatMoney(converted, local.code)} ${local.code}';
  }
}

class _DestinationSearch extends ConsumerStatefulWidget {
  const _DestinationSearch({required this.onSelected});

  final ValueChanged<Destination> onSelected;

  @override
  ConsumerState<_DestinationSearch> createState() => _DestinationSearchState();
}

class _DestinationSearchState extends ConsumerState<_DestinationSearch> {
  Timer? _debounce;
  String _query = '';
  List<Destination> _results = const [];
  bool _failed = false;
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value.trim();
      _searching = _query.length >= 2;
      if (!_searching) _results = const [];
    });
    if (!_searching) return;
    // Apple Maps limita las búsquedas: se busca cuando el usuario deja de escribir.
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(_query));
  }

  Future<void> _search(String query) async {
    try {
      final results = await ref
          .read(destinationRepositoryProvider)
          .search(query);
      if (mounted && query == _query) {
        setState(() {
          _results = results;
          _failed = false;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted && query == _query) {
        setState(() {
          _results = const [];
          _failed = true;
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _failed
        ? "Search isn't available right now. Check your connection."
        : (_query.length >= 2 && _results.isEmpty && !_searching
              ? 'No places found'
              : null);
    return Column(
      children: [
        TextField(
          autofocus: false,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 17, color: context.colors.text),
          decoration: InputDecoration(
            hintText: 'Search destination (e.g. Tokyo, Paris)',
            hintStyle: TextStyle(color: context.colors.textSecondary),
            prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
            filled: true,
            fillColor: context.colors.card,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: _border(context.colors.border),
            focusedBorder: _border(context.colors.accent),
          ),
        ),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: context.colors.card,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: context.colors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _results.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 52,
                        color: context.colors.border,
                      ),
                    InkWell(
                      onTap: () => widget.onSelected(_results[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: context.colors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _results[i].name,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
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
}

class _Label extends StatelessWidget {
  const _Label(this.label, {this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    if (trailing == null) return SectionLabel(label);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: SectionLabel(label)),
        Text(
          trailing!,
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton(this.label, {required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: context.colors.fillStrong,
        foregroundColor: context.colors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

class _CurrencyBox extends StatelessWidget {
  const _CurrencyBox({
    required this.label,
    required this.currency,
    required this.onTap,
  });

  final String label;
  final Currency? currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.fill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: currency?.code ?? '--',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: context.colors.text,
                      ),
                    ),
                    TextSpan(text: '  ${currency?.name ?? 'Select'}'),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
