import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/legal_pages.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/currency_badge.dart';
import 'sign_in_controller.dart';

/// Sign in / Sign up con Apple o Google (design/0 - SIGN UP.png). Va tras el onboarding y antes del paywall.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(signInControllerProvider, (_, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't sign in. Please try again.")),
        );
      }
    });
    final loading = ref.watch(signInControllerProvider).isLoading;
    final controller = ref.read(signInControllerProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const BrandLogo(),
                      const SizedBox(height: 24),
                      const ExcludeSemantics(child: _ConverterCard()),
                      const SizedBox(height: 40),
                      Text(
                        'Every currency.\nEvery trip.',
                        style: text.headlineLarge?.copyWith(height: 1.1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sign in to sync your trips, budgets and rate alerts across devices.',
                        style: text.bodyMedium?.copyWith(
                          fontSize: 17,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 12),
                    child: Column(
                      children: [
                        _SignInButton(
                          label: 'Continue with Apple',
                          icon: Icon(
                            Icons.apple,
                            size: 24,
                            color: context.colors.onAppleButton,
                          ),
                          background: context.colors.appleButton,
                          foreground: context.colors.onAppleButton,
                          onPressed: loading
                              ? null
                              : controller.signInWithApple,
                        ),
                        const SizedBox(height: 12),
                        _SignInButton(
                          label: 'Continue with Google',
                          icon: Image.asset(
                            'assets/images/google_g.png',
                            width: 20,
                            height: 20,
                          ),
                          background: context.colors.card,
                          foreground: context.colors.text,
                          border: context.colors.border,
                          onPressed: loading
                              ? null
                              : controller.signInWithGoogle,
                        ),
                        const SizedBox(height: 24),
                        const _LegalText(),
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
                                'Works offline · No card needed',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.border,
  });

  final String label;
  final Widget icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.6),
          disabledForegroundColor: foreground.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: border == null ? BorderSide.none : BorderSide(color: border!),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 10),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText();

  @override
  Widget build(BuildContext context) {
    final link = TextStyle(
      fontWeight: FontWeight.w700,
      color: context.colors.accent,
    );
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: context.colors.textSecondary,
        ),
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          TextSpan(
            text: 'Terms of Use',
            style: link,
            recognizer: TapGestureRecognizer()..onTap = openTermsOfUse,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: link,
            recognizer: TapGestureRecognizer()..onTap = openPrivacyPolicy,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Ilustración: el conversor de la app con un ejemplo EUR → JPY.
class _ConverterCard extends StatelessWidget {
  const _ConverterCard();

  static TextStyle _mono(BuildContext context) =>
      TextStyle(fontFamily: AppFonts.mono, color: context.colors.textSecondary);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  _amountBox(
                    context,
                    currencyByCode('EUR'),
                    context.colors.badge,
                    '250',
                  ),
                  const SizedBox(height: 8),
                  _amountBox(
                    context,
                    currencyByCode('JPY'),
                    const Color(0xFFE86A6A),
                    '43,705',
                  ),
                ],
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.colors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.border),
                ),
                child: Icon(
                  Icons.swap_vert,
                  size: 20,
                  color: context.colors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 4),
              Text(
                '1 EUR = 174.82 JPY',
                style: _mono(context).copyWith(fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.accent.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '+0.42%',
                  style: _mono(
                    context,
                  ).copyWith(fontSize: 12, color: context.colors.accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountBox(
    BuildContext context,
    Currency currency,
    Color color,
    String amount,
  ) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: context.colors.fill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                CurrencyBadge(currency, size: 26, color: color),
                const SizedBox(width: 8),
                Text(
                  currency.code,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: context.colors.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // La cifra se encoge si no cabe (letra grande de accesibilidad).
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                amount,
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: context.colors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
