import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/db/db.dart';
import 'package:lockin_app/model/user_model.dart';
import 'package:lockin_app/repositories/user_repository.dart';

/// Provides the DBHelper singleton
final dbHelperProvider = Provider<DBHelper>((ref) => DBHelper());

/// Provides the UserRepository instance
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dbHelper = ref.watch(dbHelperProvider);
  return UserRepository(dbHelper);
});

/// Manages the current logged-in user (Riverpod 3.x Notifier)
class CurrentUserNotifier extends Notifier<UserModel?> {
  late final UserRepository _userRepository;

  @override
  UserModel? build() {
    // Access repository from ref when Notifier is built
    _userRepository = ref.read(userRepositoryProvider);
    return null; // initial state
  }

  Future<void> login(String email, String password) async {
    final user = await _userRepository.getUserByEmail(email);
    if (user != null && user.password == password) {
      state = user;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<void> register(UserModel user) async {
    await _userRepository.insertUser(user);
    state = user;
  }

  void logout() {
    state = null;
  }

  Future<void> updateGoal(int newGoalMinutes) async {
    if (state == null) return;
    final updatedUser = UserModel(
      userId: state!.userId,
      email: state!.email,
      username: state!.username,
      password: state!.password,
      goalMinutes: newGoalMinutes,
      dateCreated: state!.dateCreated,
    );
    await _userRepository.updateUser(updatedUser);
    state = updatedUser;
  }
}

/// Exposes the current logged-in user
final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, UserModel?>(CurrentUserNotifier.new);

/// Derived provider for goal_minutes
final userGoalProvider = Provider<int?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.goalMinutes;
});
