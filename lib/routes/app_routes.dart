import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockin_app/model/session_timer_model.dart';
import 'package:lockin_app/providers/session_timer_provider.dart';
import 'package:lockin_app/providers/user_provider.dart';
import 'package:lockin_app/providers/onboarding_provider.dart';
import 'package:lockin_app/screens/home.dart';
import 'package:lockin_app/screens/login/signin_screen.dart';
import 'package:lockin_app/screens/onboarding/onboarding.dart';
import 'package:lockin_app/screens/session/finished_session_page.dart';
import 'package:lockin_app/screens/session/focus_page.dart';
import 'package:lockin_app/screens/session/session_page.dart';
import 'package:lockin_app/screens/settings.dart';
import 'package:lockin_app/screens/shared/root_layout.dart';
import 'package:lockin_app/screens/stats.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch the user state
  final currentUserAsync = ref.watch(currentUserProvider);

  // Watch the onboarding state provider directly (this will trigger rebuilds)
  final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);

  // Compute user status
  final isLoggedIn = currentUserAsync.asData?.value != null;

  // Check session state for initial location
  final timerState = ref.read(sessionTimerProvider);
  final hasActiveSession =
      timerState.phase == SessionPhase.focusing ||
      timerState.phase == SessionPhase.onBreak;

  print('🚀 [Router Init] Building GoRouter');
  print('   Onboarding seen: $hasSeenOnboarding');
  print('   Logged in: $isLoggedIn');
  print('   Active session: $hasActiveSession (Phase: ${timerState.phase})');

  // Determine initial location based on state
  String initialLocation;
  if (!hasSeenOnboarding) {
    initialLocation = '/onboarding';
  } else if (!isLoggedIn) {
    initialLocation = '/register';
  } else if (hasActiveSession) {
    initialLocation = '/focus';
    print('   ✅ Setting initial location to /focus due to active session');
  } else {
    initialLocation = '/home';
  }

  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: true,

    // Add refreshListenable to make router reactive to provider changes
    refreshListenable: _GoRouterRefreshStream(ref),

    redirect: (context, state) {
      final path = state.uri.path;

      print('🔀 [Router] Redirect check: $path');

      // Wait until user is loaded
      if (currentUserAsync.isLoading) {
        print('⏳ [Router] User loading, waiting...');
        return null;
      }

      // Priority 1: If user hasn't seen onboarding, always show it first
      if (!hasSeenOnboarding) {
        print('👋 [Router] Onboarding not seen, redirecting to /onboarding');
        return path == '/onboarding' ? null : '/onboarding';
      }

      // Priority 2: If user is logged in
      if (isLoggedIn) {
        // Don't allow going back to onboarding or auth screens
        if (path == '/onboarding' || path == '/register' || path == '/login') {
          print('🔒 [Router] User logged in, blocking auth screens');
          return '/home';
        }
        
        // Check if there's an active session using read (not watch)
        // This prevents circular dependency during navigation
        final timerState = ref.read(sessionTimerProvider);
        final hasActiveSession =
            timerState.phase == SessionPhase.focusing ||
            timerState.phase == SessionPhase.onBreak;
        
        print('📊 [Router] Timer state - Phase: ${timerState.phase}, Active: $hasActiveSession');
        
        // Allow /session and /finished routes even during active session
        if (path == '/session' || path.startsWith('/finished')) {
          print('✅ [Router] Allowing /session or /finished route');
          return null;
        }
        
        // If there's an active session and user is not on /focus, redirect to /focus
        if (hasActiveSession && path != '/focus') {
          print('🎯 [Router] Active session detected, redirecting to /focus from $path');
          return '/focus';
        }
        
        print('✅ [Router] No redirect needed');
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
          GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
        ],
      ),
    ],
  );
});

// Helper class to make GoRouter reactive to Riverpod state changes
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(this._ref) {
    // Listen to providers and notify when they change
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
    _ref.listen(hasSeenOnboardingProvider, (_, __) => notifyListeners());
    // Listen to session timer ONLY for phase changes (not every second)
    _ref.listen(
      sessionTimerProvider.select((state) => state.phase),
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