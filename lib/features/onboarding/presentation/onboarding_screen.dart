import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import 'home_currency_page.dart';
import 'intro_page.dart';

/// Onboarding de 3 pasos (design/1-3 - ON BOARDING.png), sin Skip. Al terminar → sign in.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 3;
  final _pages = PageController();
  int _step = 0;
  final _suggested = suggestedCurrency(
    PlatformDispatcher.instance.locale.toString(),
  );
  late Currency _homeCurrency = _suggested;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_step < _steps - 1) {
      await _pages.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    await ref
        .read(appPreferencesProvider)
        .completeOnboarding(homeCurrency: _homeCurrency.code);
    if (mounted) context.go('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              _ProgressBar(step: _step, steps: _steps),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    const IntroPage.convert(),
                    const IntroPage.trips(),
                    HomeCurrencyPage(
                      selected: _homeCurrency,
                      suggested: _suggested,
                      onSelected: (c) => setState(() => _homeCurrency = c),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Continue', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.steps});

  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${step + 1} of $steps',
      child: Row(
        children: [
          for (var i = 0; i < steps; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step
                      ? context.colors.accent
                      : context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
