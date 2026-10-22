import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/convert/presentation/convert_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/paywall/data/subscription_repository.dart';
import '../../features/paywall/presentation/paywall_screen.dart';
import '../../features/trips/presentation/new_trip_screen.dart';
import '../../features/trips/presentation/trip_detail_screen.dart';
import '../../features/trips/presentation/trips_screen.dart';
import '../../features/you/presentation/appearance_screen.dart';
import '../../features/you/presentation/contact_support_screen.dart';
import '../../features/you/presentation/help_support_screen.dart';
import '../../features/you/presentation/home_currency_screen.dart';
import '../../features/you/presentation/you_screen.dart';
import '../preferences/app_preferences.dart';
import 'main_navigation.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  final auth = ref.watch(authRepositoryProvider);
  final router = GoRouter(
    initialLocation: '/convert',
    // Flujo de entrada: onboarding (una sola vez) → sign in → paywall → app.
    // Sin suscripción activa solo se ve el paywall.
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (auth.uid != null) {
        // null mientras RevenueCat responde (al arrancar sale de su caché casi al instante).
        final active = ref.read(subscriptionProvider).value?.active;
        if (location == '/sign-in' || location == '/onboarding') {
          return active == true ? '/convert' : '/paywall';
        }
        if (active == false && location != '/paywall') return '/paywall';
        if (active == true && location == '/paywall') return '/convert';
        return null;
      }
      if (!prefs.onboardingCompleted) {
        return location == '/onboarding' ? null : '/onboarding';
      }
      return location == '/sign-in' ? null : '/sign-in';
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      // Fuera del menú inferior: New Trip ocupa toda la pantalla.
      GoRoute(path: '/new-trip', builder: (_, _) => const NewTripScreen()),
      GoRoute(path: '/paywall', builder: (_, _) => const PaywallScreen()),
      // Cada pestaña conserva su pila y su estado al cambiar de pestaña.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainNavigation(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/convert',
                builder: (_, _) => const ConvertScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trips',
                builder: (_, _) => const TripsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) =>
                        TripDetailScreen(tripId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/alerts', builder: (_, _) => const AlertsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/you',
                builder: (_, _) => const YouScreen(),
                routes: [
                  GoRoute(
                    path: 'appearance',
                    builder: (_, _) => const AppearanceScreen(),
                  ),
                  GoRoute(
                    path: 'home-currency',
                    builder: (_, _) => const HomeCurrencyScreen(),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (_, _) => const HelpSupportScreen(),
                    routes: [
                      GoRoute(
                        path: 'contact',
                        builder: (_, _) => const ContactSupportScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  // Al iniciar o cerrar sesión, o al cambiar la suscripción, se vuelve a evaluar el redirect.
  final subscription = auth.uidChanges().listen((_) => router.refresh());
  ref.listen(subscriptionProvider, (_, _) => router.refresh());
  ref.onDispose(() {
    subscription.cancel();
    router.dispose();
  });
  return router;
});
