import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';

/// Par favorito (informe §5.5): se guarda por par, no por moneda.
typedef CurrencyPair = ({String from, String to});

/// Favoritos en Firestore: users/{uid}/favorites/{EUR-USD}.
class FavoritesRepository {
  FavoritesRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  // El id es el propio par, así el mismo par no se guarda dos veces.
  static String _id(CurrencyPair pair) => '${pair.from}-${pair.to}';

  /// En el orden en que se añadieron.
  Stream<List<CurrencyPair>> watchFavorites(String uid) => _favorites(uid)
      .orderBy('createdAt')
      .snapshots()
      .map(
        (s) => [
          for (final doc in s.docs)
            (from: doc['from'] as String, to: doc['to'] as String),
        ],
      );

  Future<void> add(String uid, CurrencyPair pair) =>
      _favorites(uid).doc(_id(pair)).set({
        'from': pair.from,
        'to': pair.to,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> remove(String uid, CurrencyPair pair) =>
      _favorites(uid).doc(_id(pair)).delete();

  /// Para eliminar la cuenta.
  Future<void> deleteAll(String uid) async {
    final batch = _db.batch();
    for (final doc in (await _favorites(uid).get()).docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(FirebaseFirestore.instance),
);

final favoritesProvider = StreamProvider<List<CurrencyPair>>((ref) {
  final uid = ref.watch(authUidProvider).value;
  if (uid == null) return Stream.value(const []);
  return ref.watch(favoritesRepositoryProvider).watchFavorites(uid);
});
