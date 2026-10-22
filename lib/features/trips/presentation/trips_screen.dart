import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_header.dart';
import '../data/trips_repository.dart';
import '../domain/trip.dart';
import 'trip_format.dart';

TextStyle _mono(BuildContext context) =>
    TextStyle(fontFamily: AppFonts.mono, color: context.colors.textSecondary);

/// Viajes en Active, Upcoming y Previous (design/TRIPS.png y TRIPS - EMPTY.png, que es la variante plegada).
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  void _toggle(String section) {
    final prefs = ref.read(appPreferencesProvider);
    // SharedPreferences actualiza su caché al momento, así que build ya lee el valor nuevo.
    prefs.setSectionExpanded(section, !prefs.isSectionExpanded(section));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final trips = ref.watch(tripsProvider);

    final today = DateTime.now();
    final all = trips.value ?? const <Trip>[];
    List<Trip> withStatus(TripStatus status) =>
        all.where((t) => t.statusOn(today) == status).toList();
    final active = withStatus(TripStatus.active)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final upcoming = withStatus(TripStatus.upcoming)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final previous = withStatus(TripStatus.previous)
      ..sort((a, b) => b.endDate.compareTo(a.endDate));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/new-trip'),
        backgroundColor: context.colors.accent,
        foregroundColor: context.colors.onAccent,
        elevation: 2,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: const Text(
          'New Trip',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList.list(
                children: [const AppHeader(), const SizedBox(height: 12)],
              ),
            ),
            if (trips.hasError && all.isEmpty)
              const _Message(
                "Couldn't load your trips. Check your connection and try again.",
              )
            else if (trips.isLoading && all.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (all.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 96),
                    child: _EmptyCard(),
                  ),
                ),
              )
            else
              SliverPadding(
                // Espacio inferior para que el botón flotante no tape la última tarjeta.
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                sliver: SliverList.list(
                  children: [
                    if (active.isNotEmpty) ...[
                      const _SectionHeader(label: 'ACTIVE', dot: true),
                      for (final trip in active) _ActiveCard(trip),
                    ],
                    if (upcoming.isNotEmpty)
                      ..._collapsible(
                        'UPCOMING',
                        'trips_upcoming',
                        upcoming.map(_UpcomingCard.new),
                        upcoming.length,
                        prefs,
                      ),
                    if (previous.isNotEmpty)
                      ..._collapsible(
                        'PREVIOUS',
                        'trips_previous',
                        previous.map(_PreviousCard.new),
                        previous.length,
                        prefs,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _collapsible(
    String label,
    String key,
    Iterable<Widget> cards,
    int count,
    AppPreferences prefs,
  ) {
    final expanded = prefs.isSectionExpanded(key);
    return [
      _SectionHeader(
        label: label,
        count: count,
        expanded: expanded,
        onTap: () => _toggle(key),
      ),
      if (expanded) ...cards,
    ];
  }
}

class _Message extends StatelessWidget {
  const _Message(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: context.colors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    this.dot = false,
    this.count,
    this.expanded,
    this.onTap,
  });

  final String label;
  final bool dot;
  final int? count;

  /// null = no se puede plegar.
  final bool? expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Row(
        children: [
          if (dot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.colors.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: context.colors.text,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: context.colors.fillStrong,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: _mono(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const Spacer(),
          if (expanded != null)
            Icon(
              expanded! ? Icons.expand_more : Icons.chevron_right,
              color: context.colors.textSecondary,
            ),
        ],
      ),
    );
    if (onTap == null) return header;
    return Semantics(
      button: true,
      expanded: expanded,
      // Sin efecto de pulsación: el cambio de la flecha y de la lista ya lo indica.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: header,
      ),
    );
  }
}

/// Tarjeta blanca con la línea de color del viaje a la izquierda.
class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.children, this.trailing});

  final Trip trip;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.colors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.colors.border),
        ),
        child: InkWell(
          onTap: () => context.push('/trips/${trip.id}'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: trip.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                trip.destination,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.text,
                                ),
                              ),
                            ),
                            if (trailing != null) ...[
                              const SizedBox(width: 8),
                              trailing!,
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatTripDates(trip.startDate, trip.endDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Importe grande en mono con un texto gris al lado ('€528 / €1,250', '€1,420 spent').
class _Amount extends StatelessWidget {
  const _Amount(this.amount, this.suffix);

  final String amount;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: amount,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: context.colors.text,
              ),
            ),
            TextSpan(text: suffix, style: const TextStyle(fontSize: 15)),
          ],
        ),
        style: _mono(context),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard(this.trip);

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final spent = formatMoney(trip.spentHome, trip.homeCurrency);
    final spentLocal =
        '≈ ${formatMoney(trip.spentLocal, trip.localCurrency)} spent';
    final budget = trip.budget;
    if (budget == null || budget <= 0) {
      return _TripCard(
        trip: trip,
        children: [
          _Amount(spent, '  spent'),
          const SizedBox(height: 6),
          Text(
            spentLocal,
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
          ),
        ],
      );
    }
    final progress = (trip.spentHome / budget).clamp(0.0, 1.0);
    return _TripCard(
      trip: trip,
      children: [
        _Amount(spent, '  / ${formatMoney(budget, trip.homeCurrency)}'),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            color: trip.color,
            backgroundColor: trip.color.withValues(alpha: 0.18),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$spentLocal · ${(trip.spentHome / budget * 100).round()}%',
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard(this.trip);

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return _TripCard(
      trip: trip,
      trailing: _Pill(
        'SCHEDULED',
        background: context.colors.fillStrong,
        foreground: context.colors.textSecondary,
      ),
      children: const [],
    );
  }
}

class _PreviousCard extends StatelessWidget {
  const _PreviousCard(this.trip);

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final budget = trip.budget;
    final difference = budget == null
        ? ''
        : formatMoney((budget - trip.spentHome).abs(), trip.homeCurrency);
    final pill = switch (budgetResult(trip.spentHome, budget)) {
      BudgetResult.under => _Pill(
        'Under budget by $difference',
        background: context.colors.accent.withValues(alpha: 0.09),
        foreground: context.colors.accent,
      ),
      BudgetResult.on => _Pill(
        'On budget',
        background: context.colors.accent.withValues(alpha: 0.09),
        foreground: context.colors.accent,
      ),
      BudgetResult.over => _Pill(
        'Over budget by $difference',
        background: context.colors.destructive.withValues(alpha: 0.09),
        foreground: context.colors.destructive,
      ),
      null => null,
    };
    return _TripCard(
      trip: trip,
      trailing: pill,
      children: [
        _Amount(formatMoney(trip.spentHome, trip.homeCurrency), '  spent'),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 2,
        style: _mono(context).copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}

/// Sin viajes: propuesta sin maqueta, con el estilo de la tarjeta Coming soon de Alerts.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: context.colors.accent.withValues(alpha: 0.09),
            child: Icon(
              Icons.luggage_outlined,
              size: 30,
              color: context.colors.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No trips yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.colors.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap New Trip to set a budget and see what you spend in your own currency.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
