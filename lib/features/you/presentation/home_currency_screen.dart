import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/widgets/back_header.dart';
import '../../../core/widgets/currency_selector.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_profile_repository.dart';

/// You > Home currency (design/SETTINGS - HOME CURRENCY.png). Se guarda en la cuenta.
class HomeCurrencyScreen extends ConsumerWidget {
  const HomeCurrencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final code =
        ref.watch(homeCurrencyProvider).value ??
        ref.read(appPreferencesProvider).homeCurrency ??
        suggestedCurrency(PlatformDispatcher.instance.locale.toString()).code;
    final selected = currencyByCode(code);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Home currency'),
            Expanded(
              child: CurrencySelector(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                header: [
                  Text('Home currency', style: text.headlineLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Used by default in new trips. You can change it for each trip.',
                    style: text.bodyMedium?.copyWith(fontSize: 16, height: 1.4),
                  ),
                ],
                pinned: selected,
                pinnedLabel: 'SELECTED',
                othersLabel: 'ALL CURRENCIES',
                selected: selected,
                onSelected: (currency) {
                  final messenger = ScaffoldMessenger.of(context);
                  // Sin await: Firestore guarda en local al momento y sincroniza al volver la conexión.
                  ref
                      .read(userProfileRepositoryProvider)
                      .setHomeCurrency(
                        ref.read(authRepositoryProvider).uid!,
                        currency.code,
                      )
                      .catchError((Object _) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Couldn't save your home currency. Please try again.",
                            ),
                          ),
                        );
                      });
                  context.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
