import 'package:flutter/services.dart';

/// Login de Google con el SDK nativo de iOS.
///
/// Existe porque el plugin oficial `google_sign_in` aún depende de GoogleSignIn-iOS 9, que no es
/// compatible con Firebase 13, y el login web de Firebase falla al repetirlo en iOS
/// («missing initial state»).
// shortcut: cuando google_sign_in_ios use GoogleSignIn-iOS 10, volver al plugin oficial y borrar este paquete.
class GoogleSignInNative {
  static const _channel = MethodChannel('travio/google_sign_in');

  /// Tokens de Google para Firebase; null si el usuario cancela.
  static Future<({String idToken, String accessToken})?> signIn() async {
    final tokens = await _channel.invokeMapMethod<String, String>('signIn');
    if (tokens == null) return null;
    return (idToken: tokens['idToken']!, accessToken: tokens['accessToken']!);
  }

  /// Olvida la cuenta elegida para que el próximo login vuelva a preguntar.
  static Future<void> signOut() => _channel.invokeMethod('signOut');
}
