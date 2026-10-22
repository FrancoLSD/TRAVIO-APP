import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/preferences/app_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/launch_splash.dart';
import 'features/paywall/data/subscription_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  // Espera a que Firebase restaure la sesión para no mostrar Sign in a quien ya entró.
  await FirebaseAuth.instance.authStateChanges().first;
  await SubscriptionRepository.configure(
    uid: FirebaseAuth.instance.currentUser?.uid,
  );
  // El icono ya decodificado evita un fotograma vacío entre la splash nativa y la animada.
  await _precache(LaunchSplash.icon);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TRAVIO',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      // Sin AppBar, iOS no cambia solo el color de la hora y la batería.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: LaunchSplash(child: child!),
      ),
    );
  }
}

Future<void> _precache(ImageProvider image) {
  final done = Completer<void>();
  final stream = image.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void finish() {
    stream.removeListener(listener);
    if (!done.isCompleted) done.complete();
  }

  listener = ImageStreamListener(
    (_, _) => finish(),
    onError: (_, _) => finish(),
  );
  stream.addListener(listener);
  return done.future;
}
