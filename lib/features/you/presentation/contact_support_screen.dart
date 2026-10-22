import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_info.dart';
import '../../../core/widgets/back_header.dart';
import '../../../core/widgets/keyboard_done_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_label.dart';
import '../../paywall/data/subscription_repository.dart';
import '../data/mail_composer.dart';

const supportEmail = 'flsd.support@gmail.com';

/// Help & Support > Contact support (design/SETTINGS - CONTACT SUPPORT.png y (SENT).png).
/// Se envía con la hoja de Mail de iOS; «Message sent» solo sale si iOS confirma el envío.
class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  static const _topics = [
    'Billing',
    'Exchange rates',
    'Trips & expenses',
    'Other',
  ];

  String _topic = _topics.first;
  final _message = TextEditingController();
  final _messageFocus = FocusNode();
  bool _sending = false;

  /// Hora de envío; con valor se muestra «Message sent».
  DateTime? _sentAt;

  @override
  void initState() {
    super.initState();
    // La barra Done solo se ve mientras se escribe el mensaje.
    _messageFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  Future<void> _send(String appVersion, String plan) async {
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(mailComposerProvider)
        .compose(
          to: supportEmail,
          subject: 'TRAVIO support · $_topic',
          body:
              '${_message.text.trim()}\n\n—\nTopic: $_topic\nPlan: $plan\nApp version: $appVersion\niOS version: ${iosVersion()}',
        )
        .catchError((Object _) => MailResult.failed);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (result == MailResult.sent) _sentAt = DateTime.now();
    });
    switch (result) {
      case MailResult.unavailable:
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Mail isn’t set up on this iPhone. Write to $supportEmail',
            ),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () =>
                  Clipboard.setData(const ClipboardData(text: supportEmail)),
            ),
          ),
        );
      case MailResult.saved:
        messenger.showSnackBar(
          const SnackBar(content: Text('Saved as a draft in Mail.')),
        );
      case MailResult.failed:
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Couldn't send the message. Please try again."),
          ),
        );
      case MailResult.sent || MailResult.cancelled:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Contact'),
            Expanded(
              child: _sentAt == null
                  ? _form(context)
                  : _sent(context, _sentAt!),
            ),
            // En un campo de varias líneas, la tecla de intro añade un salto de línea en vez de cerrar.
            if (_messageFocus.hasFocus)
              KeyboardDoneBar(onDone: _messageFocus.unfocus),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final appVersion = ref.watch(appVersionProvider).value ?? '—';
    final plan = ref.watch(subscriptionProvider).value?.label ?? '—';
    final canSend = _message.text.trim().isNotEmpty && !_sending;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text('Contact support', style: text.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Tell us what happened. We’ll reply by email.',
          style: text.bodyMedium?.copyWith(fontSize: 16),
        ),
        const SectionLabel('TOPIC'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final topic in _topics)
              ChoiceChip(
                label: Text(topic),
                selected: topic == _topic,
                onSelected: (_) => setState(() => _topic = topic),
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: topic == _topic ? colors.onAccent : colors.text,
                ),
                selectedColor: colors.accent,
                backgroundColor: colors.card,
                side: BorderSide(
                  color: topic == _topic ? colors.accent : colors.border,
                ),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
          ],
        ),
        const SectionLabel('MESSAGE'),
        TextField(
          controller: _message,
          focusNode: _messageFocus,
          onChanged: (_) => setState(() {}),
          minLines: 5,
          maxLines: 10,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: 17, color: colors.text),
          decoration: InputDecoration(
            hintText: 'Describe the problem or your question',
            hintStyle: TextStyle(color: colors.textSecondary),
            filled: true,
            fillColor: colors.card,
            enabledBorder: _border(colors.border),
            focusedBorder: _border(colors.accent),
          ),
        ),
        const SectionLabel('INCLUDED WITH YOUR MESSAGE'),
        _InfoCard(
          rows: [
            ('Plan', plan),
            ('App version', appVersion),
            ('iOS version', iosVersion()),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Helps us find the problem. Your trips and expenses are not sent.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Send message',
          onPressed: canSend ? () => _send(appVersion, plan) : null,
        ),
        const SizedBox(height: 12),
        Text(
          'Opens the Mail app. Not set up? Write to',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        SelectableText(
          supportEmail,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
      ],
    );
  }

  Widget _sent(BuildContext context, DateTime sentAt) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: colors.accent.withValues(alpha: 0.09),
                      child: Icon(Icons.check, size: 32, color: colors.accent),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Message sent',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We’ll reply by email. You can keep using TRAVIO in the meantime.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InfoCard(
                      rows: [
                        ('Topic', _topic),
                        (
                          'Sent',
                          DateFormat("MMM d '·' HH:mm", 'en_US').format(sentAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Done vuelve a You, como en la maqueta.
          PrimaryButton(label: 'Done', onPressed: () => context.go('/you')),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color),
  );
}

/// Filas etiqueta / valor (en mono) en una tarjeta blanca.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].$2,
                    style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
