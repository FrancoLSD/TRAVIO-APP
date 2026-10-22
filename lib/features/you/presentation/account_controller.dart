import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_profile_repository.dart';
import '../../convert/data/favorites_repository.dart';
import '../../trips/data/trips_repository.dart';

/// Cerrar sesión y eliminar cuenta. Al quedarse sin sesión, el router lleva a Sign in.
class AccountController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(authRepositoryProvider).signOut);
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    final trips = ref.read(tripsRepositoryProvider);
    final favorites = ref.read(favoritesRepositoryProvider);
    final profiles = ref.read(userProfileRepositoryProvider);
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).deleteAccount((uid) async {
        // Viajes y gastos primero: con el perfil borrado ya no habría forma de encontrarlos.
        await trips.deleteAllTrips(uid);
        await favorites.deleteAll(uid);
        await profiles.deleteProfile(uid);
      }),
    );
  }
}

final accountControllerProvider =
    AsyncNotifierProvider<AccountController, void>(AccountController.new);
