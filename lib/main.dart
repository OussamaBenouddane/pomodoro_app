import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/providers/shared_prefs_provider.dart';
import 'package:lockin_app/providers/theme_provider.dart';
import 'package:lockin_app/routes/app_routes.dart';
import 'package:lockin_app/services/notification_services.dart';
import 'package:lockin_app/services/timer_background_service.dart';
import 'package:lockin_app/services/timer_service_manager.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'providers/session_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services BEFORE running the app
  print('🔧 Initializing services...');
  await TimerBackgroundService.initialize();
  await NotificationService.initialize();
  tz.initializeTimeZones();
  
  print('✅ Services initialized');
  
  runApp(const ProviderScope(child: LockInApp()));
}

class LockInApp extends ConsumerStatefulWidget {
  const LockInApp({super.key});

  @override
  ConsumerState<LockInApp> createState() => _LockInAppState();
}

class _LockInAppState extends ConsumerState<LockInApp> {
  @override
  void initState() {
    super.initState();
    // Initialize timer service manager after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🎧 Initializing TimerServiceManager...');
      TimerServiceManager.initialize(ref);
      print('✅ TimerServiceManager initialized');
    });
  }

  @override
  void dispose() {
    TimerServiceManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(sharedPrefsProvider);
    final themeMode = ref.watch(themeModeProvider);
    ref.read(sessionSaveListenerProvider);

    return prefsAsync.when(
      data: (_) {
        // Once SharedPreferences is ready, we can safely build the router
        final router = ref.watch(goRouterProvider);

        return MaterialApp.router(
          title: 'Lock In',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        );
      },
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: darkTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: darkTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: Scaffold(
          body: Center(child: Text('Error loading preferences: $e')),
        ),
      ),
    );
  }
}