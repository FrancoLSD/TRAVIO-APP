import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/app_preferences.dart';
import '../data/auth_repository.dart';
import '../data/user_profile_repository.dart';

/// Al iniciar sesión, el router lleva solo al paywall (escucha el estado de Auth).
class SignInController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> signInWithApple() =>
      _signIn(ref.read(authRepositoryProvider).signInWithApple);

  Future<void> signInWithGoogle() =>
      _signIn(ref.read(authRepositoryProvider).signInWithGoogle);

  Future<void> _signIn(Future<String?> Function() method) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = await method();
      if (uid == null) return; // cancelado por el usuario
      final homeCurrency = ref.read(appPreferencesProvider).homeCurrency;
      if (homeCurrency != null) {
        await ref
            .read(userProfileRepositoryProvider)
            .saveHomeCurrencyIfMissing(uid, homeCurrency);
      }
    });
  }
}

final signInControllerProvider = AsyncNotifierProvider<SignInController, void>(
  SignInController.new,
);
