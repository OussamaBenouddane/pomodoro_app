import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/providers/shared_prefs_provider.dart';
import 'package:lockin_app/routes/app_routes.dart';
import 'providers/session_provider.dart';

void main() {
  runApp(const ProviderScope(child: LockInApp()));
}

class LockInApp extends ConsumerWidget {
  const LockInApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(sharedPrefsProvider);
    ref.read(sessionSaveListenerProvider);

    return prefsAsync.when(
      data: (_) {
        // Once SharedPreferences is ready, we can safely build the router
        final router = ref.watch(goRouterProvider);

        return MaterialApp.router(
          title: 'Lock In',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error loading preferences: $e')),
        ),
      ),
    );
  }
}
