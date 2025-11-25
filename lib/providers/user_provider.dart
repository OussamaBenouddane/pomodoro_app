import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/db/db.dart';
import 'package:lockin_app/model/user_model.dart';
import 'package:lockin_app/providers/shared_prefs_provider.dart';
import 'package:lockin_app/repositories/user_repository.dart';
import 'package:lockin_app/repositories/user_session_repository.dart';

/// Provides DBHelper
final dbHelperProvider = Provider<DBHelper>((ref) => DBHelper());

/// Provides UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final db = ref.watch(dbHelperProvider);
  return UserRepository(db);
});

/// Provides session repository
final sessionRepositoryProvider = Provider<UserSessionRepository>(
  (ref) {
    final prefsAsync = ref.watch(sharedPrefsProvider);
    return prefsAsync.when(
      data: (prefs) => UserSessionRepository(prefs),
      loading: () => UserSessionRepository(),
      error: (_, __) => UserSessionRepository(),
    );
  },
);

/// Notifier to manage current user & persistence
class CurrentUserNotifier extends AsyncNotifier<UserModel?> {
  late final UserRepository _userRepository;
  late final UserSessionRepository _sessionRepository;

  @override
  Future<UserModel?> build() async {
    _userRepository = ref.read(userRepositoryProvider);
    _sessionRepository = ref.read(sessionRepositoryProvider);

    // On app start, try to restore the user session
    final userId = await _sessionRepository.getLoggedInUserId();
    if (userId != null) {
      return await _userRepository.getUserById(userId);
    }
    return null;
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    
    try {
      final user = await _userRepository.getUserByEmail(email);

      if (user == null) {
        state = const AsyncData(null);
        return false;
      }

      if (user.password != password) {
        state = const AsyncData(null);
        return false;
      }

      await _sessionRepository.saveLoggedInUserId(user.userId!);
      state = AsyncData(user);
      return true;
    } catch (e) {
      state = const AsyncData(null);
      return false;
    }
  }

  Future<bool> register(UserModel user) async {
    state = const AsyncLoading();
    
    try {
      // Check if user already exists
      final existingUser = await _userRepository.getUserByEmail(user.email);
      if (existingUser != null) {
        state = const AsyncData(null);
        return false;
      }

      final id = await _userRepository.insertUser(user);
      final newUser = user.copyWith(userId: id);
      await _sessionRepository.saveLoggedInUserId(id);
      state = AsyncData(newUser);
      return true;
    } catch (e) {
      state = const AsyncData(null);
      return false;
    }
  }

  Future<void> logout() async {
    await _sessionRepository.clearSession();
    state = const AsyncData(null);
  }

  Future<void> updateGoal(int newGoalMinutes) async {
    final current = state.asData?.value;
    if (current == null) return;

    final updated = current.copyWith(goalMinutes: newGoalMinutes);
    await _userRepository.updateUser(updated);
    state = AsyncData(updated);
  }

  /// Clear all session and stats history for the current user
  Future<void> clearHistory() async {
    final current = state.asData?.value;
    if (current == null || current.userId == null) return;

    await _userRepository.clearUserHistory(current.userId!);
  }
}

/// Global provider
final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserModel?>(
      CurrentUserNotifier.new,
    );