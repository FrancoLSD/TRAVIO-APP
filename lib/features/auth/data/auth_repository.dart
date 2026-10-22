import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in_native/google_sign_in_native.dart';

/// Inicio de sesión con Apple y Google sobre Firebase Auth.
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  String? get email => _auth.currentUser?.email;

  /// 'Apple' o 'Google', según con qué entró.
  String? get providerName =>
      switch (_auth.currentUser?.providerData.firstOrNull?.providerId) {
        'apple.com' => 'Apple',
        'google.com' => 'Google',
        _ => null,
      };

  Stream<String?> uidChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  /// Devuelve el uid, o null si el usuario cancela.
  Future<String?> signInWithApple() async {
    try {
      final credential = await _auth.signInWithProvider(
        AppleAuthProvider()..addScope('email'),
      );
      return credential.user?.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code.contains('cancel')) return null;
      rethrow;
    }
  }

  /// Devuelve el uid, o null si el usuario cancela.
  /// Con el SDK nativo de Google: el login web de Firebase falla al repetirlo en iOS.
  Future<String?> signInWithGoogle() async {
    final credential = await _googleCredential();
    if (credential == null) return null;
    return (await _auth.signInWithCredential(credential)).user?.uid;
  }

  static Future<AuthCredential?> _googleCredential() async {
    final tokens = await GoogleSignInNative.signIn();
    if (tokens == null) return null;
    return GoogleAuthProvider.credential(
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
  }

  Future<void> signOut() async {
    // Olvida la cuenta de Google para que el próximo login permita elegir otra.
    if (providerName == 'Google') await GoogleSignInNative.signOut();
    await _auth.signOut();
  }

  /// Borra la cuenta tras volver a autenticar (Firebase exige un login reciente).
  /// [deleteData] borra los datos del usuario mientras aún tiene permiso. Devuelve false si cancela.
  Future<bool> deleteAccount(
    Future<void> Function(String uid) deleteData,
  ) async {
    final user = _auth.currentUser!;
    final isApple = providerName == 'Apple';
    final UserCredential credential;
    if (isApple) {
      try {
        credential = await user.reauthenticateWithProvider(AppleAuthProvider());
      } on FirebaseAuthException catch (e) {
        if (e.code.contains('cancel')) return false;
        rethrow;
      }
    } else {
      final google = await _googleCredential();
      if (google == null) return false;
      credential = await user.reauthenticateWithCredential(google);
    }
    await deleteData(user.uid);
    // Apple exige revocar el token de Sign in with Apple al eliminar la cuenta.
    final appleCode = credential.additionalUserInfo?.authorizationCode;
    if (isApple && appleCode != null) {
      await _auth.revokeTokenWithAuthorizationCode(appleCode);
    }
    await user.delete();
    return true;
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(FirebaseAuth.instance),
);

/// uid de la sesión actual, que cambia al entrar o salir.
final authUidProvider = StreamProvider<String?>((ref) async* {
  final auth = ref.watch(authRepositoryProvider);
  yield auth.uid;
  yield* auth.uidChanges();
});
