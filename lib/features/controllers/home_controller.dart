import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/db/db.dart';
import 'package:lockin_app/providers/session_provider.dart';
import 'package:lockin_app/providers/user_provider.dart';

final homeRefreshListenerProvider = Provider((ref) {
  ref.listen(sessionProvider, (_, __) {
    ref.invalidate(homeControllerProvider);
  });
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(DBHelper());
});

final homeControllerProvider = AsyncNotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

class HomeController extends AsyncNotifier<HomeState> {
  HomeRepository get _repo => ref.read(homeRepositoryProvider);

  @override
  FutureOr<HomeState> build() async {
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) {
      return const HomeState(
        streakDays: 0,
        todayFocusMinutes: 0,
        dailyGoalMinutes: 120,
        nextReminder: 'Not set',
      );
    }

    final userId = userAsync.value!.userId!;

    return await _loadHomeData(userId);
  }

  Future<HomeState> _loadHomeData(int userId) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    // Get today's stats
    final todayStats = await _repo.getDayStats(userId, today);
    final todayMinutes = todayStats?.totalFocusMinutes ?? 0;

    // Get user's daily goal
    final goal = await _repo.getUserGoal(userId);

    // Calculate streak
    final streak = await _repo.calculateStreak(userId);

    // Get next reminder (if you have reminders table)
    final nextReminder = await _repo.getNextReminder(userId);

    return HomeState(
      streakDays: streak,
      todayFocusMinutes: todayMinutes,
      dailyGoalMinutes: goal,
      nextReminder: nextReminder ?? 'Not set',
    );
  }

  Future<void> updateGoal(int newGoal) async {
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) return;
    final userId = userAsync.value!.userId!;

    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current == null) return;

    // Update in database first
    await _repo.updateUserGoal(userId, newGoal);

    // Also update the user provider
    await ref.read(currentUserProvider.notifier).updateGoal(newGoal);

    // Update state immediately
    state = AsyncData(current.copyWith(dailyGoalMinutes: newGoal));
  }

  Future<void> updateReminder(String newReminder) async {
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) return;
    final userId = userAsync.value!.userId!;

    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current == null) return;

    // Update in database
    await _repo.updateReminder(userId, newReminder);

    // Update state
    state = AsyncData(current.copyWith(nextReminder: newReminder));
  }

  Future<void> refresh() async {
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) return;
    final userId = userAsync.value!.userId!;

    state = await AsyncValue.guard(() => _loadHomeData(userId));
  }

  // Method to update today's focus minutes without full reload
  void updateTodayMinutes(int minutes) {
    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current == null) return;

    state = AsyncData(current.copyWith(todayFocusMinutes: minutes));
  }
}

class HomeState {
  final int streakDays;
  final int todayFocusMinutes;
  final int dailyGoalMinutes;
  final String nextReminder;

  const HomeState({
    required this.streakDays,
    required this.todayFocusMinutes,
    required this.dailyGoalMinutes,
    required this.nextReminder,
  });

  HomeState copyWith({
    int? streakDays,
    int? todayFocusMinutes,
    int? dailyGoalMinutes,
    String? nextReminder,
  }) {
    return HomeState(
      streakDays: streakDays ?? this.streakDays,
      todayFocusMinutes: todayFocusMinutes ?? this.todayFocusMinutes,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      nextReminder: nextReminder ?? this.nextReminder,
    );
  }
}

class HomeRepository {
  final DBHelper dbHelper;

  HomeRepository(this.dbHelper);

  Future<DayStatModel?> getDayStats(int userId, String date) async {
    final result = await dbHelper.readDataWithArgs(
      '''
      SELECT 
        date,
        SUM(focus_minutes) as total_focus_minutes,
        COUNT(*) as session_count
      FROM sessions
      WHERE user_id = ? AND date = ?
      GROUP BY date
      ''',
      [userId, date],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return DayStatModel(
      date: row['date'] as String,
      totalFocusMinutes: row['total_focus_minutes'] as int? ?? 0,
      sessionCount: row['session_count'] as int? ?? 0,
    );
  }

  Future<int> getUserGoal(int userId) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT goal_minutes FROM users WHERE user_id = ?',
      [userId],
    );

    if (result.isEmpty) return 120; // Default goal
    return result.first['goal_minutes'] as int? ?? 120;
  }

  Future<int> calculateStreak(int userId) async {
    final today = DateTime.now();
    int streak = 0;
    DateTime checkDate = today;

    while (true) {
      final dateStr = checkDate.toIso8601String().split('T').first;
      final result = await dbHelper.readDataWithArgs(
        '''
        SELECT SUM(focus_minutes) as total
        FROM sessions
        WHERE user_id = ? AND date = ?
        ''',
        [userId, dateStr],
      );

      final totalMinutes = result.isNotEmpty
          ? (result.first['total'] as int? ?? 0)
          : 0;

      // Consider a day "completed" if they have any focus time
      if (totalMinutes > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // If today has no sessions yet, don't break the streak
        if (checkDate.day == today.day &&
            checkDate.month == today.month &&
            checkDate.year == today.year) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }

      // Safety limit to prevent infinite loop
      if (streak > 1000) break;
    }

    return streak;
  }

  Future<String?> getNextReminder(int userId) async {
    try {
      // Check if reminders table exists first
      final tableCheck = await dbHelper.readData(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='reminders'",
      );

      if (tableCheck.isEmpty) {
        return null; // Table doesn't exist yet
      }

      final result = await dbHelper.readDataWithArgs(
        '''
        SELECT reminder_time 
        FROM reminders 
        WHERE user_id = ? AND reminder_time > datetime('now')
        ORDER BY reminder_time ASC
        LIMIT 1
        ''',
        [userId],
      );

      if (result.isEmpty) return null;

      // Format the reminder time nicely
      final reminderTime = result.first['reminder_time'] as String?;
      if (reminderTime == null) return null;

      try {
        final dateTime = DateTime.parse(reminderTime);
        final now = DateTime.now();

        if (dateTime.day == now.day &&
            dateTime.month == now.month &&
            dateTime.year == now.year) {
          return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        } else {
          return '${dateTime.month}/${dateTime.day} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        }
      } catch (e) {
        return reminderTime;
      }
    } catch (e) {
      // If any error occurs (table doesn't exist, etc.), just return null
      return null;
    }
  }

  Future<void> updateUserGoal(int userId, int newGoal) async {
    await dbHelper.updateData(
      'users',
      {'goal_minutes': newGoal},
      'user_id = ?',
      [userId],
    );
  }

  Future<void> updateReminder(int userId, String reminderTime) async {
    try {
      // Check if reminders table exists first
      final tableCheck = await dbHelper.readData(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='reminders'",
      );

      if (tableCheck.isEmpty) {
        // Create reminders table if it doesn't exist
        await dbHelper.readData('''
          CREATE TABLE IF NOT EXISTS reminders (
            reminder_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            reminder_time TEXT,
            created_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
          )
        ''');
      }

      // Delete old reminders and insert new one
      await dbHelper.deleteData('reminders', 'user_id = ?', [userId]);

      await dbHelper.insertData('reminders', {
        'user_id': userId,
        'reminder_time': reminderTime,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // If any error occurs (table doesn't exist, etc.), just return null
    }
  }
}

// Simple model for day stats
class DayStatModel {
  final String date;
  final int totalFocusMinutes;
  final int sessionCount;

  DayStatModel({
    required this.date,
    required this.totalFocusMinutes,
    required this.sessionCount,
  });
}
