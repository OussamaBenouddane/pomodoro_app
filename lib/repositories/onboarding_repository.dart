import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  final SharedPreferences prefs;

  OnboardingRepository(this.prefs);

  static const _key = 'has_seen_onboarding';

  bool get hasSeenOnboarding => prefs.getBool(_key) ?? false;

  Future<void> setSeen() async {
    await prefs.setBool(_key, true);
  }
}
