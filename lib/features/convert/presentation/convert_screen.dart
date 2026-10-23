import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_icon.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/amount_input.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/currency_badge.dart';
import '../../../core/widgets/currency_picker_screen.dart';
import '../../../core/widgets/keyboard_done_bar.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_profile_repository.dart';
import '../../rates/data/rates_repository.dart';
import '../../trips/data/trips_repository.dart';
import '../../trips/domain/trip.dart';
import '../data/favorites_repository.dart';

/// Pestaña Convert (design/HOME.png y HOME - EMPTY.png): conversor, viaje activo y favoritos.
/// Sin variación del par ni «hace X minutos» (decisiones del 18 oct 2026).
class ConvertScreen extends ConsumerStatefulWidget {
  const ConvertScreen({super.key});

  @override
  ConsumerState<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends ConsumerState<ConvertScreen> {
  final _top = TextEditingController();
  final _bottom = TextEditingController();
  final _topFocus = FocusNode();
  final _bottomFocus = FocusNode();

  /// Par elegido por el usuario; null = el par por defecto (ver [_defaultPair]).
  CurrencyPair? _pair;

  /// Qué importe escribió el usuario; el otro se calcula.
  bool _typedTop = true;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(appPreferencesProvider).lastPair;
    if (saved != null) _pair = (from: saved.$1, to: saved.$2);
    for (final focus in [_topFocus, _bottomFocus]) {
      focus.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_top, _bottom]) {
      c.dispose();
    }
    for (final f in [_topFocus, _bottomFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  /// Primera vez: moneda de casa → la del viaje activo, o USD (EUR si la de casa es USD).
  CurrencyPair _defaultPair(List<Trip> activeTrips) {
    final home =
        ref.watch(homeCurrencyProvider).value ??
        ref.read(appPreferencesProvider).homeCurrency ??
        suggestedCurrency(PlatformDispatcher.instance.locale.toString()).code;
    final tripCurrency = activeTrips
        .map((t) => t.localCurrency)
        .where((c) => c != home)
        .firstOrNull;
    return (from: home, to: tripCurrency ?? (home == 'USD' ? 'EUR' : 'USD'));
  }

  void _setPair(CurrencyPair pair, Rates? rates) {
    setState(() => _pair = pair);
    ref.read(appPreferencesProvider).setLastPair(pair.from, pair.to);
    _recalculate(pair, rates);
  }

  /// Rehace el importe calculado a partir del que escribió el usuario.
  void _recalculate(CurrencyPair pair, Rates? rates) {
    final source = _typedTop ? _top : _bottom;
    final target = _typedTop ? _bottom : _top;
    final value = parseAmount(source.text);
    final converted = value == null
        ? null
        : rates?.convert(
            value,
            _typedTop ? pair.from : pair.to,
            _typedTop ? pair.to : pair.from,
          );
    target.text = converted == null
        ? ''
        : formatAmount(
            converted,
            currencyDecimals(_typedTop ? pair.to : pair.from),
          );
  }

  Future<void> _changeCurrency(
    CurrencyPair pair,
    Rates? rates, {
    required bool from,
  }) async {
    final picked = await pickCurrency(
      context,
      title: from ? 'Convert from' : 'Convert to',
      subtitle: 'Pick the currency to convert ${from ? 'from' : 'to'}.',
      selected: currencyByCode(from ? pair.from : pair.to),
    );
    if (picked == null) return;
    _setPair(
      from
          ? (from: picked.code, to: pair.to)
          : (from: pair.from, to: picked.code),
      rates,
    );
  }

  void _toggleFavorite(CurrencyPair pair, bool isFavorite) {
    final uid = ref.read(authRepositoryProvider).uid!;
    final repository = ref.read(favoritesRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    // Sin await: Firestore guarda en local al momento y sincroniza al volver la conexión.
    (isFavorite ? repository.remove(uid, pair) : repository.add(uid, pair))
        .catchError((Object _) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                "Couldn't update your favorites. Please try again.",
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final rates = ref.watch(ratesProvider);
    final allTrips = ref.watch(tripsProvider).value ?? const <Trip>[];
    final today = DateTime.now();
    final activeTrips =
        allTrips.where((t) => t.statusOn(today) == TripStatus.active).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final favorites =
        ref.watch(favoritesProvider).value ?? const <CurrencyPair>[];
    final pair = _pair ?? _defaultPair(activeTrips);
    final isFavorite = favorites.contains(pair);

    // Las tasas pueden llegar después de escribir (primera descarga).
    ref.listen(ratesProvider, (_, next) => _recalculate(pair, next.value));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const AppHeader(),
                  const SizedBox(height: 20),
                  _converterCard(pair, rates, isFavorite),
                  const SizedBox(height: 20),
                  const _SectionTitle('Active Trips'),
                  const SizedBox(height: 12),
                  if (activeTrips.isEmpty)
                    _EmptyCard(
                      icon: 'trips',
                      title: allTrips.isEmpty
                          ? 'No trips yet'
                          : 'No active trips',
                      subtitle: 'Track budgets & spendings',
                      action: 'Create Trip',
                      onPressed: () => context.push('/new-trip'),
                    )
                  else
                    for (final trip in activeTrips) _ActiveTripCard(trip),
                  const SizedBox(height: 16),
                  const _SectionTitle('Favorites'),
                  const SizedBox(height: 12),
                  if (favorites.isEmpty)
                    _EmptyCard(
                      icon: 'favorite',
                      title: 'No active favorites',
                      subtitle: 'Pin currency pairs for quick access',
                      action: 'Add Favorite',
                      onPressed: () => _toggleFavorite(pair, false),
                    )
                  else
                    _FavoritesCard(
                      favorites: favorites,
                      rates: rates.value,
                      onTap: (favorite) => _setPair(favorite, rates.value),
                    ),
                  const SizedBox(height: 24),
                  if (ref.watch(ratesRepositoryProvider).savedAt
                      case final savedAt?)
                    _OfflineReady(savedAt),
                ],
              ),
            ),
            if (_topFocus.hasFocus || _bottomFocus.hasFocus)
              KeyboardDoneBar(onDone: () => FocusScope.of(context).unfocus()),
          ],
        ),
      ),
    );
  }

  Widget _converterCard(
    CurrencyPair pair,
    AsyncValue<Rates> rates,
    bool isFavorite,
  ) {
    final colors = context.colors;
    final rate = rates.value?.convert(1, pair.from, pair.to);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  _AmountBox(
                    currency: currencyByCode(pair.from),
                    controller: _top,
                    focusNode: _topFocus,
                    onCurrencyTap: () =>
                        _changeCurrency(pair, rates.value, from: true),
                    onChanged: () {
                      _typedTop = true;
                      _recalculate(pair, rates.value);
                    },
                  ),
                  const SizedBox(height: 8),
                  _AmountBox(
                    currency: currencyByCode(pair.to),
                    controller: _bottom,
                    focusNode: _bottomFocus,
                    onCurrencyTap: () =>
                        _changeCurrency(pair, rates.value, from: false),
                    onChanged: () {
                      _typedTop = false;
                      _recalculate(pair, rates.value);
                    },
                  ),
                ],
              ),
              Semantics(
                button: true,
                label: 'Swap currencies',
                child: GestureDetector(
                  onTap: () =>
                      _setPair((from: pair.to, to: pair.from), rates.value),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      Icons.swap_vert,
                      size: 22,
                      color: colors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: rate == null
                      ? Text(
                          rates.isLoading
                              ? 'Getting rates…'
                              : 'No rates yet. Connect to the internet to download them.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        )
                      : Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '1 ${pair.from} = ${NumberFormat('#,##0.####', 'en_US').format(rate)} ${pair.to}',
                                style: TextStyle(
                                  fontFamily: AppFonts.mono,
                                  color: colors.text,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '  ·  Rates for ${DateFormat('MMM d', 'en_US').format(DateTime.parse(rates.value!.date))}',
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                ),
              ),
              IconButton(
                tooltip: isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onPressed: () => _toggleFavorite(pair, isFavorite),
                icon: AppIcon(
                  isFavorite ? 'favorite-filled' : 'favorite',
                  color: isFavorite ? colors.accent : colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountBox extends StatelessWidget {
  const _AmountBox({
    required this.currency,
    required this.controller,
    required this.focusNode,
    required this.onCurrencyTap,
    required this.onChanged,
  });

  final Currency currency;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCurrencyTap;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Change ${currency.name}',
            child: GestureDetector(
              onTap: onCurrencyTap,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencyBadge(currency, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      currency.code,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            currencySymbol(currency.code),
            style: TextStyle(fontSize: 20, color: colors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (_) => onChanged(),
              textAlign: TextAlign.end,
              keyboardType: TextInputType.numberWithOptions(
                decimal: currencyDecimals(currency.code) > 0,
              ),
              inputFormatters: [
                AmountInputFormatter(currencyDecimals(currency.code)),
              ],
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: colors.textSecondary),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resumen compacto del viaje activo; lleva a su detalle.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: context.colors.text,
    ),
  );
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard(this.trip);

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final budget = trip.budget != null && trip.budget! > 0 ? trip.budget : null;
    final mono = TextStyle(
      fontFamily: AppFonts.mono,
      fontSize: 13,
      color: colors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: () => context.go('/trips/${trip.id}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: trip.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip.destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colors.text,
                        ),
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: formatMoney(
                              trip.spentHome,
                              trip.homeCurrency,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                          ),
                          if (budget != null)
                            TextSpan(
                              text:
                                  ' / ${formatMoney(budget, trip.homeCurrency)}',
                            ),
                        ],
                      ),
                      style: mono,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (budget != null) ...[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (trip.spentHome / budget).clamp(0.0, 1.0),
                            minHeight: 6,
                            color: trip.color,
                            backgroundColor: colors.track,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ] else
                      const Spacer(),
                    Text(
                      budget == null
                          ? '≈ ${formatMoney(trip.spentLocal, trip.localCurrency)} spent'
                          : '≈ ${formatMoney(trip.spentLocal, trip.localCurrency)} spent '
                                '(${(trip.spentHome / budget * 100).round()}%)',
                      style: mono,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesCard extends StatelessWidget {
  const _FavoritesCard({
    required this.favorites,
    required this.rates,
    required this.onTap,
  });

  final List<CurrencyPair> favorites;
  final Rates? rates;
  final ValueChanged<CurrencyPair> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < favorites.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 84, color: colors.border),
            _favoriteRow(context, favorites[i]),
          ],
        ],
      ),
    );
  }

  Widget _favoriteRow(BuildContext context, CurrencyPair pair) {
    final colors = context.colors;
    final rate = rates?.convert(1, pair.from, pair.to);
    return InkWell(
      onTap: () => onTap(pair),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Dos círculos solapados, como en la maqueta.
            SizedBox(
              width: 54,
              height: 36,
              child: Stack(
                children: [
                  CurrencyBadge(currencyByCode(pair.from), size: 36),
                  Positioned(
                    left: 18,
                    child: CurrencyBadge(currencyByCode(pair.to), size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${pair.from} / ${pair.to}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: colors.text,
                ),
              ),
            ),
            Text(
              rate == null
                  ? '—'
                  : NumberFormat('#,##0.####', 'en_US').format(rate),
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío de viaje o favoritos, con su acción.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onPressed,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.fill,
                child: AppIcon(icon, size: 20, color: colors.textSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent.withValues(alpha: 0.09),
                foregroundColor: colors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                action,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Offline ready · 12:42» (hoy) u «Offline ready · Oct 19»: cuándo se guardaron las tasas.
class _OfflineReady extends StatelessWidget {
  const _OfflineReady(this.savedAt);

  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final when = DateUtils.isSameDay(savedAt, DateTime.now())
        ? DateFormat('HH:mm', 'en_US').format(savedAt)
        : DateFormat('MMM d', 'en_US').format(savedAt);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_done_outlined, size: 16, color: colors.textSecondary),
        const SizedBox(width: 6),
        Text(
          'Offline ready · $when',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
      ],
    );
  }
}
