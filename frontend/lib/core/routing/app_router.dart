import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_scaffold.dart';

// ── Auth State Provider (stub – replace with real auth provider) ───────
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

// ── Router Provider ───────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !loggingIn) return '/login';
      if (isAuthenticated && loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      // ── Login (no shell) ────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const _PlaceholderScreen(title: 'Login'),
      ),

      // ── Main Shell with sidebar + app bar ───────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(
            title: _titleForLocation(state.matchedLocation),
            child: child,
          );
        },
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Dashboard'),
          ),

          // ── Vehicles ─────────────────────────────────────────────────
          GoRoute(
            path: '/vehicles',
            name: 'vehicles',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Vehicles'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'vehicle-create',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Create Vehicle'),
              ),
              GoRoute(
                path: ':id',
                name: 'vehicle-detail',
                builder: (context, state) => _PlaceholderScreen(
                  title: 'Vehicle ${state.pathParameters['id']}',
                ),
              ),
            ],
          ),

          // ── Machines ─────────────────────────────────────────────────
          GoRoute(
            path: '/machines',
            name: 'machines',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Machines'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'machine-create',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Create Machine'),
              ),
              GoRoute(
                path: ':id',
                name: 'machine-detail',
                builder: (context, state) => _PlaceholderScreen(
                  title: 'Machine ${state.pathParameters['id']}',
                ),
              ),
            ],
          ),

          // ── Services ─────────────────────────────────────────────────
          GoRoute(
            path: '/services',
            name: 'services',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Services'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'service-create',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Create Service'),
              ),
              GoRoute(
                path: ':id',
                name: 'service-detail',
                builder: (context, state) => _PlaceholderScreen(
                  title: 'Service ${state.pathParameters['id']}',
                ),
              ),
            ],
          ),

          // ── Inventory ────────────────────────────────────────────────
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Inventory'),
            routes: [
              GoRoute(
                path: ':id',
                name: 'inventory-detail',
                builder: (context, state) => _PlaceholderScreen(
                  title: 'Product ${state.pathParameters['id']}',
                ),
              ),
            ],
          ),

          // ── Assets ───────────────────────────────────────────────────
          GoRoute(
            path: '/assets',
            name: 'assets',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Assets'),
            routes: [
              GoRoute(
                path: ':id',
                name: 'asset-detail',
                builder: (context, state) => _PlaceholderScreen(
                  title: 'Asset ${state.pathParameters['id']}',
                ),
              ),
            ],
          ),

          // ── Reports ──────────────────────────────────────────────────
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Reports'),
          ),
        ],
      ),
    ],
  );
});

// ── Helper: derive page title from location ───────────────────────────
String _titleForLocation(String location) {
  if (location.startsWith('/vehicles')) return 'Vehicles';
  if (location.startsWith('/machines')) return 'Machines';
  if (location.startsWith('/services')) return 'Services';
  if (location.startsWith('/inventory')) return 'Inventory';
  if (location.startsWith('/assets')) return 'Assets';
  if (location.startsWith('/reports')) return 'Reports';
  return 'Dashboard';
}

// ── Placeholder screen (will be replaced with real screens) ───────────
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
