import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/expense.dart';
import '../domain/trip.dart';

/// Viajes y gastos en Firestore: users/{uid}/trips/{tripId}/expenses/{expenseId}.
///
/// Cada viaje guarda los totales de sus gastos (spentHome, spentLocal) para que la lista de Trips
/// no tenga que leer todos los gastos; se actualizan en el mismo lote que el gasto.
class TripsRepository {
  TripsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _trips(String uid) =>
      _db.collection('users').doc(uid).collection('trips');

  CollectionReference<Map<String, dynamic>> _expenses(
    String uid,
    String tripId,
  ) => _trips(uid).doc(tripId).collection('expenses');

  Stream<List<Trip>> watchTrips(String uid) => _trips(uid).snapshots().map(
    (s) => [for (final doc in s.docs) _tripFromDoc(doc.id, doc.data())],
  );

  Future<void> createTrip(String uid, Trip trip) => _trips(uid).add({
    ..._tripFields(trip),
    'spentHome': 0,
    'spentLocal': 0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteTrip(String uid, String tripId) async {
    final expenses = await _expenses(uid, tripId).get();
    await _deleteInBatches([
      for (final doc in expenses.docs) doc.reference,
      _trips(uid).doc(tripId),
    ]);
  }

  /// Para eliminar la cuenta: Firestore no borra las subcolecciones con el documento.
  Future<void> deleteAllTrips(String uid) async {
    final trips = await _trips(uid).get();
    for (final trip in trips.docs) {
      await deleteTrip(uid, trip.id);
    }
  }

  /// Del más reciente al más antiguo.
  Stream<List<Expense>> watchExpenses(String uid, String tripId) =>
      _expenses(uid, tripId)
          .orderBy('dateTime', descending: true)
          .snapshots()
          .map(
            (s) => [
              for (final doc in s.docs) _expenseFromDoc(doc.id, doc.data()),
            ],
          );

  Future<void> addExpense(String uid, String tripId, Expense expense) {
    final batch = _db.batch()
      ..set(_expenses(uid, tripId).doc(), _expenseFields(expense))
      ..update(
        _trips(uid).doc(tripId),
        _totalsDelta(expense.amountHome, expense.amountLocal),
      );
    return batch.commit();
  }

  Future<void> updateExpense(
    String uid,
    String tripId,
    Expense before,
    Expense after,
  ) {
    final batch = _db.batch()
      ..set(_expenses(uid, tripId).doc(after.id), _expenseFields(after))
      ..update(
        _trips(uid).doc(tripId),
        _totalsDelta(
          after.amountHome - before.amountHome,
          after.amountLocal - before.amountLocal,
        ),
      );
    return batch.commit();
  }

  Future<void> deleteExpense(String uid, String tripId, Expense expense) {
    final batch = _db.batch()
      ..delete(_expenses(uid, tripId).doc(expense.id))
      ..update(
        _trips(uid).doc(tripId),
        _totalsDelta(-expense.amountHome, -expense.amountLocal),
      );
    return batch.commit();
  }

  Future<void> _deleteInBatches(List<DocumentReference> refs) async {
    // Lotes de 500 operaciones como máximo (límite de Firestore).
    for (var i = 0; i < refs.length; i += 500) {
      final batch = _db.batch();
      for (final ref in refs.skip(i).take(500)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  static Map<String, Object> _totalsDelta(double home, double local) => {
    'spentHome': FieldValue.increment(home),
    'spentLocal': FieldValue.increment(local),
  };

  static Map<String, Object?> _tripFields(Trip trip) => {
    'destination': trip.destination,
    'countryCode': trip.countryCode,
    'homeCurrency': trip.homeCurrency,
    'localCurrency': trip.localCurrency,
    'startDate': _day(trip.startDate),
    'endDate': _day(trip.endDate),
    'budget': trip.budget,
  };

  static Map<String, Object> _expenseFields(Expense e) => {
    'name': e.name,
    'category': e.category.name,
    'amountLocal': e.amountLocal,
    'amountHome': e.amountHome,
    'rate': e.rate,
    'rateDate': e.rateDate,
    'rateOffline': e.rateOffline,
    'dateTime': Timestamp.fromDate(e.dateTime),
  };

  // Fechas como 'yyyy-MM-dd' para que no cambien de día con la zona horaria.
  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Trip _tripFromDoc(String id, Map<String, dynamic> data) => Trip(
    id: id,
    destination: data['destination'] as String,
    countryCode: data['countryCode'] as String,
    homeCurrency: data['homeCurrency'] as String,
    localCurrency: data['localCurrency'] as String,
    startDate: DateTime.parse(data['startDate'] as String),
    endDate: DateTime.parse(data['endDate'] as String),
    budget: (data['budget'] as num?)?.toDouble(),
    spentHome: (data['spentHome'] as num?)?.toDouble() ?? 0,
    spentLocal: (data['spentLocal'] as num?)?.toDouble() ?? 0,
  );

  static Expense _expenseFromDoc(String id, Map<String, dynamic> data) =>
      Expense(
        id: id,
        name: data['name'] as String,
        category:
            ExpenseCategory.values.asNameMap()[data['category']] ??
            ExpenseCategory.other,
        amountLocal: (data['amountLocal'] as num).toDouble(),
        rate: (data['rate'] as num).toDouble(),
        rateDate: data['rateDate'] as String,
        rateOffline: data['rateOffline'] as bool? ?? false,
        dateTime: (data['dateTime'] as Timestamp).toDate(),
      );
}

final tripsRepositoryProvider = Provider<TripsRepository>(
  (ref) => TripsRepository(FirebaseFirestore.instance),
);

final tripsProvider = StreamProvider<List<Trip>>((ref) {
  final uid = ref.watch(authUidProvider).value;
  if (uid == null) return Stream.value(const []);
  return ref.watch(tripsRepositoryProvider).watchTrips(uid);
});

final expensesProvider = StreamProvider.family<List<Expense>, String>((
  ref,
  tripId,
) {
  final uid = ref.watch(authUidProvider).value;
  if (uid == null) return Stream.value(const []);
  return ref.watch(tripsRepositoryProvider).watchExpenses(uid, tripId);
});
