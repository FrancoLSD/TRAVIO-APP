import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_header.dart';
import '../../../core/widgets/section_label.dart';

/// You > Help & Support (design/SETTINGS - HELP & SUPPORT.png).
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // La primera respuesta es la de la maqueta; las otras, redactadas con lo decidido en el informe (§5.10, §14.4, §10.3).
  static const _faq = [
    (
      'Where do exchange rates come from?',
      'Daily reference rates from central banks, published on working days. TRAVIO shows the most recent rate '
          'available and its date. It does not offer real-time rates.',
    ),
    (
      'Why does an expense use a past rate?',
      'Each expense keeps the rate of the day you picked for it, so your trip totals don’t change when rates move '
          'later. If you log yesterday’s dinner today, it uses yesterday’s rate.',
    ),
    (
      'Can I use TRAVIO offline?',
      'Yes. TRAVIO saves the latest rates on your iPhone, so you can convert and log expenses without a connection. '
          'Your trips and expenses sync when you’re back online.',
    ),
    (
      'How do I cancel my subscription?',
      'Your subscription is managed by Apple. Open Settings on your iPhone, tap your name, then Subscriptions, choose '
          'TRAVIO and tap Cancel Subscription. You keep access until the end of the period you’ve paid for.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Help & Support'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Text('Help & Support', style: text.headlineLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Quick answers, or write to us.',
                    style: text.bodyMedium?.copyWith(fontSize: 16),
                  ),
                  const SectionLabel('COMMON QUESTIONS'),
                  _Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < _faq.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: colors.border,
                            ),
                          // La primera abierta, como en la maqueta.
                          _Question(
                            question: _faq[i].$1,
                            answer: _faq[i].$2,
                            initiallyOpen: i == 0,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SectionLabel('CONTACT'),
                  _Card(
                    child: InkWell(
                      onTap: () => context.push('/you/help/contact'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: colors.fill,
                              child: Icon(
                                Icons.mail_outline,
                                size: 19,
                                color: colors.text,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Contact support',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: colors.text,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: colors.chevron,
                            ),
                          ],
                        ),
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

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: context.colors.border),
      ),
      child: child,
    );
  }
}

/// Pregunta desplegable; se pueden abrir varias a la vez.
class _Question extends StatefulWidget {
  const _Question({
    required this.question,
    required this.answer,
    required this.initiallyOpen,
  });

  final String question;
  final String answer;
  final bool initiallyOpen;

  @override
  State<_Question> createState() => _QuestionState();
}

class _QuestionState extends State<_Question> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      expanded: _open,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: colors.textSecondary,
                  ),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 10),
                Text(
                  widget.answer,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
