import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockin_app/providers/user_provider.dart';
import 'package:lockin_app/providers/onboarding_provider.dart';
import 'package:lockin_app/screens/home.dart';
import 'package:lockin_app/screens/login/signin_screen.dart';
import 'package:lockin_app/screens/onboarding/onboarding.dart';
import 'package:lockin_app/screens/session/finished_session_page.dart';
import 'package:lockin_app/screens/session/focus_page.dart';
import 'package:lockin_app/screens/session/session_page.dart';
import 'package:lockin_app/screens/session/test.dart';
import 'package:lockin_app/screens/shared/root_layout.dart';
import 'package:lockin_app/screens/stats.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch the user state
  final currentUserAsync = ref.watch(currentUserProvider);
  
  // Watch the onboarding state provider directly (this will trigger rebuilds)
  final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);

  // Compute user status
  final isLoggedIn = currentUserAsync.asData?.value != null;

  return GoRouter(
    initialLocation: hasSeenOnboarding ? (isLoggedIn ? '/home' : '/register') : '/onboarding',
    debugLogDiagnostics: true,

    // Add refreshListenable to make router reactive to provider changes
    refreshListenable: _GoRouterRefreshStream(ref),

    redirect: (context, state) {
      final path = state.uri.path;

      // Wait until user is loaded
      if (currentUserAsync.isLoading) {
        return null;
      }

      // Priority 1: If user hasn't seen onboarding, always show it first
      if (!hasSeenOnboarding) {
        return path == '/onboarding' ? null : '/onboarding';
      }

      // Priority 2: If user is logged in
      if (isLoggedIn) {
        // Don't allow going back to onboarding or auth screens
        if (path == '/onboarding' || path == '/register' || path == '/login') {
          return '/home';
        }
        return null; // Allow access to other routes
      }

      // Priority 3: If onboarding is complete but user is not logged in
      if (!isLoggedIn) {
        // Allow access to register/login pages
        if (path == '/register' || path == '/login' || path == '/onboarding') {
          return null;
        }
        // Redirect everything else to register
        return '/register';
      }

      return null; // No redirect
    },

    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/finished/:durationSeconds',
        builder: (context, state) {
          final durationSeconds =
              state.pathParameters['durationSeconds'] ?? '0';
          return SessionSummaryPage(durationSeconds: durationSeconds);
        },
      ),
      GoRoute(path: '/session', builder: (_, __) => const SessionPage()),
      GoRoute(
        path: '/focus',
        pageBuilder: (context, state) =>
            const MaterialPage(fullscreenDialog: true, child: FocusPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => RootLayout(),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/stats', builder: (_, __) => StatsDashboardScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const Placeholder()),
          GoRoute(path: '/settings', builder: (_, __) => const Placeholder()),
        ],
      ),
    ],
  );
});

// Helper class to make GoRouter reactive to Riverpod state changes
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(this._ref) {
    // Listen to both providers and notify when they change
    _ref.listen(
      currentUserProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen(
      hasSeenOnboardingProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;

  @override
  void dispose() {
    // Cleanup if needed
    super.dispose();
  }
}