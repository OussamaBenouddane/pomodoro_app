import 'package:shared_preferences/shared_preferences.dart';

class UserSessionRepository {
  final SharedPreferences? _prefs;
  static const _keyUserId = 'logged_in_user_id';

  UserSessionRepository([this._prefs]);

  Future<SharedPreferences> get prefs async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<void> saveLoggedInUserId(int userId) async {
    final p = await prefs;
    await p.setInt(_keyUserId, userId);
  }

  Future<int?> getLoggedInUserId() async {
    final p = await prefs;
    return p.getInt(_keyUserId);
  }

  Future<void> clearSession() async {
    final p = await prefs;
    await p.remove(_keyUserId);
  }
}