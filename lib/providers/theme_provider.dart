import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider that manages theme mode with persistence
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _key = 'theme_mode';
  
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  /// Load saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_key);
      
      if (themeModeString != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.light,
        );
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Set specific theme mode and persist it
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.toString());
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Light theme configuration
final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF388BC6), // Your specified blue
    secondary: const Color(0xFF2C6B95), // Darker blue for secondary
    surface: Colors.white,
    error: Colors.red[400]!,
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1F2937),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey[200]!),
    ),
  ),
);

/// Dark theme configuration
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF5BA3D0), // Lighter blue for dark mode
    secondary: const Color(0xFF7BB8DD), // Even lighter blue for secondary
    surface: const Color(0xFF1F2937),
    error: Colors.red[300]!,
  ),
  scaffoldBackgroundColor: const Color(0xFF111827),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1F2937),
    foregroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1F2937),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF374151)),
    ),
  ),
);