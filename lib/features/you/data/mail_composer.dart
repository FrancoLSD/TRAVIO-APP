import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MailResult { sent, saved, cancelled, failed, unavailable }

/// Hoja de Mail de iOS (MFMailComposeViewController), vía el canal nativo de AppDelegate.swift.
/// A diferencia de mailto:, iOS dice si el correo se envió o se canceló.
class MailComposer {
  static const _channel = MethodChannel('travio/mail');

  /// unavailable si el iPhone no tiene ninguna cuenta en Mail.
  Future<MailResult> compose({
    required String to,
    required String subject,
    required String body,
  }) async {
    final result = await _channel.invokeMethod<String>('compose', {
      'to': to,
      'subject': subject,
      'body': body,
    });
    return MailResult.values.asNameMap()[result] ?? MailResult.failed;
  }
}

final mailComposerProvider = Provider<MailComposer>((ref) => MailComposer());
