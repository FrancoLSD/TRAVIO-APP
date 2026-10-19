import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/convert/presentation/convert_screen.dart';
import '../../features/trips/presentation/trips_screen.dart';
import '../../features/you/presentation/you_screen.dart';
import 'main_navigation.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/convert',
    routes: [
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
              GoRoute(path: '/trips', builder: (_, _) => const TripsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/alerts', builder: (_, _) => const AlertsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/you', builder: (_, _) => const YouScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
