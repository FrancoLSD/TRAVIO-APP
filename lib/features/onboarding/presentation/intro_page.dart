import 'package:flutter/material.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/currency_badge.dart';

TextStyle _mono(BuildContext context) =>
    TextStyle(fontFamily: AppFonts.mono, color: context.colors.textSecondary);
const _japan = Color(0xFFE86A6A);

/// Pasos 1 y 2: ilustración con componentes de la app arriba, titular abajo.
class IntroPage extends StatelessWidget {
  const IntroPage.convert({super.key})
    : title = 'Convert in seconds, anywhere.',
      subtitle =
          'Daily exchange rates for your trip, saved on your phone so they work offline too.',
      illustration = const _ConvertCard();

  const IntroPage.trips({super.key})
    : title = 'Know what every trip costs.',
      subtitle =
          'Set a budget, log expenses as you go, and see each one in your own currency.',
      illustration = const _TripCards();

  final String title;
  final String subtitle;
  final Widget illustration;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              ExcludeSemantics(child: illustration),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.headlineLarge),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: text.bodyMedium?.copyWith(fontSize: 17, height: 1.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context, [double radius = 24]) =>
    BoxDecoration(
      color: context.colors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: context.colors.border),
    );

class _ConvertCard extends StatelessWidget {
  const _ConvertCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _amountRow(
            context,
            'You have',
            currencyByCode('EUR'),
            '1,000',
            context.colors.text,
          ),
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Divider(color: context.colors.border, height: 1),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.colors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_vert,
                    size: 20,
                    color: context.colors.onAccent,
                  ),
                ),
              ],
            ),
          ),
          _amountRow(
            context,
            'You get',
            currencyByCode('JPY'),
            '174,820',
            context.colors.accent,
          ),
          const SizedBox(height: 16),
          Text(
            '1 EUR = 174.82 JPY · Saved for offline use',
            style: _mono(context).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    Currency currency,
    String amount,
    Color amountColor,
  ) {
    return Row(
      children: [
        CurrencyBadge(currency, size: 36),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            ),
            Text(
              currency.code,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.colors.text,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          amount,
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 34,
            fontWeight: FontWeight.w600,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

class _TripCards extends StatelessWidget {
  const _TripCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: _cardDecoration(context),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: _japan),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE · DAY 5 OF 15',
                          style: _mono(context).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: _japan,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tokyo, Japan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: context.colors.text,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              '¥92,400',
                              style: _mono(context).copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.colors.text,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'of ¥200,000',
                              style: _mono(context).copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.46,
                            minHeight: 8,
                            color: _japan,
                            backgroundColor: context.colors.track,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '¥107,600 left',
                          style: _mono(context).copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: _cardDecoration(context, 18),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ramen',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: context.colors.text,
                    ),
                  ),
                  Text(
                    'Oct 16 · 19:30',
                    style: _mono(context).copyWith(fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥1,200',
                    style: _mono(context).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.colors.text,
                    ),
                  ),
                  Text('≈ €6.86', style: _mono(context).copyWith(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
