import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/legal_pages.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../trips/domain/trip.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription.dart';
import 'subscription_controller.dart';

/// Paywall a pantalla completa (design/SCREENS/5 - PAYWALL V2.png), sin botón de cerrar
/// porque toda la app es de pago. Precios y prueba gratis vienen de RevenueCat; Annual preseleccionado.
/// Al activarse la suscripción, el router lleva a la app.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selectedId;

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _restore() async {
    final active = await ref
        .read(subscriptionControllerProvider.notifier)
        .restore();
    if (!active &&
        mounted &&
        !ref.read(subscriptionControllerProvider).hasError) {
      _show('No active subscription found for this Apple ID.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(subscriptionControllerProvider, (_, state) {
      if (state.hasError && !state.isLoading) {
        _show(purchaseErrorMessage(state.error!));
      }
    });
    final colors = context.colors;
    final busy = ref.watch(subscriptionControllerProvider).isLoading;
    final plans = ref.watch(plansProvider);
    final options = plans.value ?? const <PlanOption>[];
    final selected =
        options.where((p) => p.id == _selectedId).firstOrNull ??
        options.firstOrNull;
    final saving = annualSaving(options);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Para entrar con otra cuenta que sí tenga la suscripción.
                TextButton(
                  onPressed: busy
                      ? null
                      : () => ref.read(authRepositoryProvider).signOut(),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                  ),
                  child: const Text(
                    'Sign out',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : _restore,
                  style: TextButton.styleFrom(foregroundColor: colors.text),
                  child: const Text(
                    'Restore',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const _Hero(),
            const SizedBox(height: 10),
            const _BenefitRow(
              _Benefit(Icons.sync_alt, 'Offline converter'),
              _Benefit(Icons.luggage_outlined, 'Trip budgets & expenses'),
            ),
            const SizedBox(height: 8),
            const _BenefitRow(
              _Benefit(Icons.star_border, 'Favorite pairs'),
              _Benefit(Icons.history, 'Rate saved per expense'),
            ),
            const SizedBox(height: 12),
            if (options.isEmpty)
              _PlansUnavailable(
                loading: plans.isLoading,
                onRetry: () => ref.invalidate(plansProvider),
              )
            else
              for (final plan in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PlanCard(
                    plan: plan,
                    save: plan.period == PlanPeriod.annual ? saving : null,
                    selected: plan == selected,
                    onTap: () => setState(() => _selectedId = plan.id),
                  ),
                ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: selected?.trialDays != null
                  ? 'Start ${selected!.trialDays}-day free trial'
                  : 'Subscribe',
              loading: busy,
              onPressed: selected == null
                  ? null
                  : () => ref
                        .read(subscriptionControllerProvider.notifier)
                        .purchase(selected),
            ),
            const SizedBox(height: 10),
            if (selected != null)
              Text(
                _legal(selected),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: colors.textSecondary,
                ),
              ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FooterLink('Terms of Use', openTermsOfUse),
                SizedBox(width: 8),
                _FooterLink('Privacy Policy', openPrivacyPolicy),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _legal(PlanOption plan) {
    final price = '${plan.price} per ${plan.period.unit}';
    return plan.trialDays != null
        ? '${plan.trialDays} days free, then $price. Renews automatically. Cancel anytime in Settings › Apple ID.'
        : '$price. Renews automatically. Cancel anytime in Settings › Apple ID.';
  }
}

/// Mientras cargan los planes o si no se pudieron cargar.
class _PlansUnavailable extends StatelessWidget {
  const _PlansUnavailable({required this.loading, required this.onRetry});

  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            "Couldn't load the plans. Check your connection.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// Cabecera verde con el viaje de ejemplo de la maqueta.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mono = TextStyle(fontFamily: AppFonts.mono, color: colors.text);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: colors.accent,
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -40,
              child: ExcludeSemantics(
                child: Icon(
                  Icons.sync_alt,
                  size: 150,
                  color: colors.onAccent.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TRAVIO PRO',
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: colors.onAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Know what every trip really costs.',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: colors.onAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Ilustración: no es un viaje del usuario.
                  ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 4,
                                backgroundColor: tripColor('JP'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tokyo, Japan',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.text,
                                  ),
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '¥92,400',
                                      style: mono.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' / ¥200,000',
                                      style: mono.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.46,
                              minHeight: 6,
                              color: colors.accent,
                              backgroundColor: colors.track,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '1 EUR = 174.82 JPY',
                                  style: mono.copyWith(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '≈ €528 spent',
                                  style: mono.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow(this.left, this.right);

  final _Benefit left;
  final _Benefit right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 8),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: colors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.save,
    required this.selected,
    required this.onTap,
  });

  final PlanOption plan;
  final int? save;
  final bool selected;
  final VoidCallback onTap;

  String? get _trialLine {
    if (plan.trialDays == null) return null;
    final free = '${plan.trialDays} days free';
    return plan.period == PlanPeriod.annual && plan.pricePerMonth != null
        ? '$free · ${plan.pricePerMonth}/mo'
        : free;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.accent : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                selected
                    ? CircleAvatar(
                        radius: 11,
                        backgroundColor: colors.accent,
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: colors.onAccent,
                        ),
                      )
                    : Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.control, width: 1.5),
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            plan.period.label,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                          if (save != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.highlight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SAVE $save%',
                                style: TextStyle(
                                  fontFamily: AppFonts.mono,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: colors.card,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _trialLine ?? 'No free trial',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _trialLine != null
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: _trialLine != null
                              ? colors.accent
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.price,
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      'per ${plan.period.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
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

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: context.colors.text),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
