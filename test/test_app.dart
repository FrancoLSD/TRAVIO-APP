import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travio_app/core/preferences/app_preferences.dart';
import 'package:travio_app/features/auth/data/auth_repository.dart';
import 'package:travio_app/features/auth/data/user_profile_repository.dart';
import 'package:travio_app/features/convert/data/favorites_repository.dart';
import 'package:travio_app/features/paywall/data/subscription_repository.dart';
import 'package:travio_app/features/paywall/domain/subscription.dart';
import 'package:travio_app/features/rates/data/rates_repository.dart';
import 'package:travio_app/features/trips/data/destination_repository.dart';
import 'package:travio_app/features/trips/data/trips_repository.dart';
import 'package:travio_app/features/trips/domain/expense.dart';
import 'package:travio_app/features/trips/domain/trip.dart';
import 'package:travio_app/features/you/data/mail_composer.dart';
import 'package:travio_app/main.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.uid});

  @override
  String? uid;
  final _changes = StreamController<String?>.broadcast();

  @override
  Stream<String?> uidChanges() => _changes.stream;

  Future<String?> _signIn() async {
    uid = 'test-user';
    _changes.add(uid);
    return uid;
  }

  @override
  Future<String?> signInWithApple() => _signIn();

  @override
  Future<String?> signInWithGoogle() => _signIn();

  @override
  String? get email => uid == null ? null : 'traveler@example.com';

  @override
  String? get providerName => uid == null ? null : 'Apple';

  @override
  Future<void> signOut() async {
    uid = null;
    _changes.add(null);
  }

  @override
  Future<bool> deleteAccount(
    Future<void> Function(String uid) deleteData,
  ) async {
    await deleteData(uid!);
    await signOut();
    return true;
  }
}

class FakeUserProfileRepository implements UserProfileRepository {
  final homeCurrencies = <String, String>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> saveHomeCurrencyIfMissing(String uid, String code) async =>
      homeCurrencies.putIfAbsent(uid, () => code);

  @override
  Future<void> setHomeCurrency(String uid, String code) async {
    homeCurrencies[uid] = code;
    _changes.add(null);
  }

  @override
  Stream<String?> watchHomeCurrency(String uid) async* {
    yield homeCurrencies[uid];
    await for (final _ in _changes.stream) {
      yield homeCurrencies[uid];
    }
  }

  @override
  Future<void> deleteProfile(String uid) async => homeCurrencies.remove(uid);
}

class FakeTripsRepository implements TripsRepository {
  FakeTripsRepository([List<Trip> trips = const []]) : trips = [...trips];

  final List<Trip> trips;
  final expenses = <String, List<Expense>>{};
  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  void _changed() => _changes.add(null);

  @override
  Stream<List<Trip>> watchTrips(String uid) async* {
    yield [...trips];
    await for (final _ in _changes.stream) {
      yield [...trips];
    }
  }

  @override
  Stream<List<Expense>> watchExpenses(String uid, String tripId) async* {
    List<Expense> sorted() =>
        [...?expenses[tripId]]
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    yield sorted();
    await for (final _ in _changes.stream) {
      yield sorted();
    }
  }

  @override
  Future<void> createTrip(String uid, Trip trip) async {
    trips.add(_copy(trip, id: trip.id.isEmpty ? 'trip-${_nextId++}' : trip.id));
    _changed();
  }

  @override
  Future<void> deleteTrip(String uid, String tripId) async {
    trips.removeWhere((t) => t.id == tripId);
    expenses.remove(tripId);
    _changed();
  }

  @override
  Future<void> deleteAllTrips(String uid) async {
    trips.clear();
    expenses.clear();
    _changed();
  }

  @override
  Future<void> addExpense(String uid, String tripId, Expense expense) async {
    final saved = _copyExpense(expense, id: 'expense-${_nextId++}');
    (expenses[tripId] ??= []).add(saved);
    _addTotals(tripId, saved.amountHome, saved.amountLocal);
  }

  @override
  Future<void> updateExpense(
    String uid,
    String tripId,
    Expense before,
    Expense after,
  ) async {
    final list = expenses[tripId]!;
    list[list.indexWhere((e) => e.id == before.id)] = after;
    _addTotals(
      tripId,
      after.amountHome - before.amountHome,
      after.amountLocal - before.amountLocal,
    );
  }

  @override
  Future<void> deleteExpense(String uid, String tripId, Expense expense) async {
    expenses[tripId]!.removeWhere((e) => e.id == expense.id);
    _addTotals(tripId, -expense.amountHome, -expense.amountLocal);
  }

  void _addTotals(String tripId, double home, double local) {
    final i = trips.indexWhere((t) => t.id == tripId);
    trips[i] = _copy(
      trips[i],
      spentHome: trips[i].spentHome + home,
      spentLocal: trips[i].spentLocal + local,
    );
    _changed();
  }

  static Trip _copy(
    Trip t, {
    String? id,
    double? spentHome,
    double? spentLocal,
  }) => Trip(
    id: id ?? t.id,
    destination: t.destination,
    countryCode: t.countryCode,
    homeCurrency: t.homeCurrency,
    localCurrency: t.localCurrency,
    startDate: t.startDate,
    endDate: t.endDate,
    budget: t.budget,
    spentHome: spentHome ?? t.spentHome,
    spentLocal: spentLocal ?? t.spentLocal,
  );

  static Expense _copyExpense(Expense e, {required String id}) => Expense(
    id: id,
    name: e.name,
    category: e.category,
    amountLocal: e.amountLocal,
    rate: e.rate,
    rateDate: e.rateDate,
    rateOffline: e.rateOffline,
    dateTime: e.dateTime,
  );
}

class FakeDestinationRepository implements DestinationRepository {
  @override
  Future<List<Destination>> search(String query) async => const [
    Destination(name: 'Tokyo, Japan', countryCode: 'JP', currencyCode: 'JPY'),
    Destination(
      name: 'Caracas, Venezuela',
      countryCode: 'VE',
      currencyCode: 'VEF',
    ),
  ];
}

/// Respuesta de Frankfurter /v2/rates con dos monedas: 1 EUR = 177.63 JPY = 1.16 USD.
const sampleRates =
    '[{"date":"2026-10-20","base":"EUR","quote":"JPY","rate":177.63},'
    '{"date":"2026-10-19","base":"EUR","quote":"USD","rate":1.16}]';

class FakeMailComposer implements MailComposer {
  FakeMailComposer([this.result = MailResult.sent]);

  MailResult result;
  final sent = <({String to, String subject, String body})>[];

  @override
  Future<MailResult> compose({
    required String to,
    required String subject,
    required String body,
  }) async {
    sent.add((to: to, subject: subject, body: body));
    return result;
  }
}

class FakeFavoritesRepository implements FavoritesRepository {
  final favorites = <CurrencyPair>[];
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<List<CurrencyPair>> watchFavorites(String uid) async* {
    yield [...favorites];
    await for (final _ in _changes.stream) {
      yield [...favorites];
    }
  }

  @override
  Future<void> add(String uid, CurrencyPair pair) async {
    if (!favorites.contains(pair)) favorites.add(pair);
    _changes.add(null);
  }

  @override
  Future<void> remove(String uid, CurrencyPair pair) async {
    favorites.remove(pair);
    _changes.add(null);
  }

  @override
  Future<void> deleteAll(String uid) async {
    favorites.clear();
    _changes.add(null);
  }
}

/// Por defecto con suscripción activa, para entrar directamente a la app.
class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({bool active = true})
    : current = active
          ? Subscription(
              active: true,
              period: PlanPeriod.annual,
              willRenew: true,
              expiresAt: DateTime(2027, 3, 4),
            )
          : Subscription.none;

  Subscription current;
  Object? purchaseError;
  final purchased = <String>[];
  var customerCenterShown = false;
  final _changes = StreamController<Subscription>.broadcast();

  @override
  Future<void> logIn(String uid) async {}

  @override
  Stream<Subscription> watch() async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  Future<List<PlanOption>> plans() async => const [
    PlanOption(
      id: r'$rc_annual',
      period: PlanPeriod.annual,
      price: 'US\$29.99',
      priceValue: 29.99,
      pricePerMonth: 'US\$2.50',
      trialDays: 7,
    ),
    PlanOption(
      id: r'$rc_monthly',
      period: PlanPeriod.monthly,
      price: 'US\$2.99',
      priceValue: 2.99,
      trialDays: 7,
    ),
    PlanOption(
      id: r'$rc_weekly',
      period: PlanPeriod.weekly,
      price: 'US\$0.99',
      priceValue: 0.99,
    ),
  ];

  @override
  Future<bool> purchase(PlanOption plan) async {
    if (purchaseError != null) throw purchaseError!;
    purchased.add(plan.id);
    current = Subscription(active: true, period: plan.period, willRenew: true);
    _changes.add(current);
    return true;
  }

  @override
  Future<bool> restore() async => current.active;

  @override
  Future<void> showCustomerCenter() async => customerCenterShown = true;
}

/// La app con preferencias en memoria y Firebase falso, como si se abriera con ese estado.
Future<Widget> testApp(
  Map<String, Object> saved, {
  AuthRepository? auth,
  UserProfileRepository? profiles,
  TripsRepository? trips,
  MailComposer? mail,
  FavoritesRepository? favorites,
  SubscriptionRepository? subscription,
}) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    key: UniqueKey(), // cada llamada es un arranque nuevo
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ratesRepositoryProvider.overrideWithValue(
        RatesRepository(prefs, fetch: (_) async => sampleRates),
      ),
      tripsRepositoryProvider.overrideWithValue(trips ?? FakeTripsRepository()),
      destinationRepositoryProvider.overrideWithValue(
        FakeDestinationRepository(),
      ),
      mailComposerProvider.overrideWithValue(mail ?? FakeMailComposer()),
      favoritesRepositoryProvider.overrideWithValue(
        favorites ?? FakeFavoritesRepository(),
      ),
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
      subscriptionRepositoryProvider.overrideWithValue(
        subscription ?? FakeSubscriptionRepository(),
      ),
      userProfileRepositoryProvider.overrideWithValue(
        profiles ?? FakeUserProfileRepository(),
      ),
    ],
    child: const MainApp(),
  );
}
