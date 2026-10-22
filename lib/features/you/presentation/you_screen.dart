import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_info.dart';
import '../../../core/utils/legal_pages.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/section_label.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_profile_repository.dart';
import '../../paywall/data/subscription_repository.dart';
import '../../paywall/domain/subscription.dart';
import '../../paywall/presentation/subscription_controller.dart';
import 'account_controller.dart';
import 'appearance_screen.dart';

/// Pestaña You (design/SETTINGS.png) más la sección ACCOUNT (sin diseño propio; exigida por App Store).
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(accountControllerProvider, (_, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    });
    final auth = ref.watch(authRepositoryProvider);
    final homeCurrency = ref.watch(homeCurrencyProvider).value;
    final busy = ref.watch(accountControllerProvider).isLoading;
    final account = ref.read(accountControllerProvider.notifier);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const AppHeader(),
          const SizedBox(height: 20),
          const _PlanCard(),
          const SectionLabel('PREFERENCES'),
          _Group([
            _Row(
              icon: Icons.home_outlined,
              title: 'Home currency',
              value: homeCurrency == null
                  ? null
                  : _CurrencyValue(currencyByCode(homeCurrency)),
              onTap: () => context.push('/you/home-currency'),
            ),
            _Row(
              icon: Icons.contrast,
              title: 'Appearance',
              value: _Value(themeModeLabel(ref.watch(themeModeProvider))),
              onTap: () => context.push('/you/appearance'),
            ),
          ]),
          const SectionLabel('SUPPORT'),
          _Group([
            _Row(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => context.push('/you/help'),
            ),
            _Row(
              icon: Icons.restore,
              title: 'Restore purchases',
              onTap: () => _restore(context, ref),
            ),
            _Row(
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              onTap: openPrivacyPolicy,
            ),
            _Row(
              icon: Icons.description_outlined,
              title: 'Terms of Use',
              onTap: openTermsOfUse,
            ),
          ]),
          const SectionLabel('ACCOUNT'),
          _Group([
            _Row(
              icon: Icons.person_outline,
              title: auth.email ?? 'Signed in',
              value: auth.providerName == null
                  ? null
                  : _Value(auth.providerName!),
            ),
            _Row(
              icon: Icons.logout,
              title: 'Sign out',
              onTap: busy ? null : account.signOut,
            ),
            _Row(
              icon: Icons.delete_outline,
              title: 'Delete account',
              color: context.colors.destructive,
              onTap: busy
                  ? null
                  : () async {
                      if (await confirmDelete(
                        context,
                        title: 'Delete your account?',
                        message:
                            "This permanently deletes your account, trips and expenses. It can't be undone. "
                            'Your subscription is managed by Apple: cancel it in your Apple ID settings.',
                      )) {
                        account.deleteAccount();
                      }
                    },
            ),
          ]),
          const SizedBox(height: 32),
          Text(
            switch (ref.watch(appVersionProvider).value) {
              final version? => 'TRAVIO $version',
              null => '',
            },
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 13,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Currency & Travel',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta verde del plan.
Future<void> _restore(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final controller = ref.read(subscriptionControllerProvider.notifier);
  final active = await controller.restore();
  final state = ref.read(subscriptionControllerProvider);
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        state.hasError
            ? purchaseErrorMessage(state.error!)
            : active
            ? 'Your subscription is restored.'
            : 'No active subscription found for this Apple ID.',
      ),
    ),
  );
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard();

  static TextStyle _mono(BuildContext context) =>
      TextStyle(fontFamily: AppFonts.mono, color: context.colors.onAccent);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sin suscripción activa el router no deja llegar aquí; none solo mientras carga.
    final sub = ref.watch(subscriptionProvider).value ?? Subscription.none;
    final period = sub.period ?? PlanPeriod.annual;
    final price = ref
        .watch(plansProvider)
        .value
        ?.where((p) => p.period == period)
        .firstOrNull
        ?.price;
    final date = sub.expiresAt == null
        ? null
        : DateFormat.yMMMd('en_US').format(sub.expiresAt!);
    final status = sub.trial
        ? 'Trial'
        : sub.willRenew
        ? 'Active'
        : 'Cancelled';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.accent,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR PLAN',
                      style: _mono(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: context.colors.onAccent.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TRAVIO ${period.label}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: context.colors.onAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.colors.onAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'Active')
                      Icon(
                        Icons.check,
                        size: 14,
                        color: context.colors.onAccent,
                      ),
                    if (status == 'Active') SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.onAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (price != null)
            Text(
              '$price / ${period.unit}',
              style: _mono(context).copyWith(fontSize: 15),
            ),
          const SizedBox(height: 2),
          if (date != null)
            Text(
              sub.trial && sub.willRenew
                  ? 'Trial ends $date'
                  : sub.willRenew
                  ? 'Renews $date'
                  : 'Ends $date',
              style: _mono(context).copyWith(
                fontSize: 14,
                color: context.colors.onAccent.withValues(alpha: 0.7),
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () =>
                  ref.read(subscriptionRepositoryProvider).showCustomerCenter(),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.onAccent,
                foregroundColor: context.colors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Manage subscription',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta blanca con filas separadas por líneas.
class _Group extends StatelessWidget {
  const _Group(this.rows);

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: context.colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 66, color: context.colors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final Widget? value;
  final VoidCallback? onTap;

  /// null = color de texto normal.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: context.colors.fill,
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Flexible(child: value!),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: context.colors.chevron,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontSize: 15, color: context.colors.textSecondary),
  );
}

class _CurrencyValue extends StatelessWidget {
  const _CurrencyValue(this.currency);

  final Currency currency;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: currency.code,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.text,
            ),
          ),
          TextSpan(text: ' · ${currency.name}'),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 15, color: context.colors.textSecondary),
    );
  }
}
