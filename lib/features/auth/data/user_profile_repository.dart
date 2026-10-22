import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

/// Perfil del usuario en Firestore: users/{uid}.
class UserProfileRepository {
  UserProfileRepository(this._db);

  final FirebaseFirestore _db;

  /// Guarda la moneda elegida en el onboarding salvo que la cuenta ya tenga una (usuario que vuelve).
  Future<void> saveHomeCurrencyIfMissing(String uid, String code) async {
    final doc = _db.collection('users').doc(uid);
    final snapshot = await doc.get();
    if (snapshot.data()?['homeCurrency'] == null) {
      await doc.set({'homeCurrency': code}, SetOptions(merge: true));
    }
  }

  /// La de You > Home currency; los viajes ya creados conservan la suya.
  Future<void> setHomeCurrency(String uid, String code) => _db
      .collection('users')
      .doc(uid)
      .set({'homeCurrency': code}, SetOptions(merge: true));

  Stream<String?> watchHomeCurrency(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => s.data()?['homeCurrency'] as String?);

  /// Borra users/{uid}; antes hay que borrar sus viajes (TripsRepository.deleteAllTrips).
  Future<void> deleteProfile(String uid) =>
      _db.collection('users').doc(uid).delete();
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(FirebaseFirestore.instance),
);

/// Moneda de casa del usuario con sesión (null mientras carga o si no tiene).
final homeCurrencyProvider = StreamProvider<String?>((ref) {
  final uid = ref.watch(authUidProvider).value;
  if (uid == null) return Stream.value(null);
  return ref.watch(userProfileRepositoryProvider).watchHomeCurrency(uid);
});
