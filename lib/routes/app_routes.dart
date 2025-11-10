import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockin_app/screens/home.dart';
import 'package:lockin_app/screens/onboarding/onboarding.dart';
import 'package:lockin_app/screens/session/finished_session_page.dart';
import 'package:lockin_app/screens/session/focus_page.dart';
import 'package:lockin_app/screens/session/session_page.dart';
import 'package:lockin_app/screens/shared/root_layout.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
        pageBuilder: (context, state) {
          return const MaterialPage(fullscreenDialog: true, child: FocusPage());
        },
      ),
      ShellRoute(
        builder: (context, state, child) => RootLayout(),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/profile', builder: (_, __) => const Placeholder()),
          GoRoute(path: '/settings', builder: (_, __) => const Placeholder()),
        ],
      ),
    ],
  );
});
