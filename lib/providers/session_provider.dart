import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/model/session_model.dart';
import 'package:lockin_app/model/session_timer_model.dart';
import 'package:lockin_app/repositories/session_repository.dart';
import 'package:lockin_app/repositories/stats_repository.dart';
import 'package:lockin_app/providers/user_provider.dart';
import 'package:lockin_app/providers/session_timer_provider.dart';

/// Provides the SessionRepository instance
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final dbHelper = ref.watch(dbHelperProvider);
  return SessionRepository(dbHelper);
});

/// Provides the StatsRepository instance (needed for recalculation)
final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final dbHelper = ref.watch(dbHelperProvider);
  return StatsRepository(dbHelper);
});

/// Handles user sessions list, streaks, and summaries
class SessionNotifier extends AsyncNotifier<List<SessionModel>> {
  late final SessionRepository _sessionRepo;
  late final StatsRepository _statsRepo;
  int? _userId;

  @override
  Future<List<SessionModel>> build() async {
    _sessionRepo = ref.read(sessionRepositoryProvider);
    _statsRepo = ref.read(statsRepositoryProvider);
    return [];
  }

  Future<void> loadUserSessions(int userId) async {
    _userId = userId;
    state = const AsyncLoading();
    try {
      final sessions = await _sessionRepo.getSessionsByUser(userId);
      state = AsyncData(sessions);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> startSession(SessionModel session) async {
    try {
      await _sessionRepo.insertSession(session);

      // Recalculate stats for the session date
      await _recalculateStatsForDate(session.userId, session.date);

      if (_userId != null) await loadUserSessions(_userId!);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> deleteSession(int sessionId) async {
    try {
      // Get the session from database before deleting to know which date to recalculate
      if (_userId != null) {
        final allSessions = await _sessionRepo.getSessionsByUser(_userId!);
        final session = allSessions.firstWhere((s) => s.sessionId == sessionId);

        await _sessionRepo.deleteSession(sessionId);

        // Recalculate stats for that date
        await _recalculateStatsForDate(session.userId, session.date);

        await loadUserSessions(_userId!);
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> refresh() async {
    if (_userId != null) await loadUserSessions(_userId!);
  }

  /// When session timer finishes → insert new record and update stats
  Future<void> saveFinishedSession(SessionTimerState completedTimer) async {
    final user = ref.read(currentUserProvider).value; // ✅ get inner UserModel

    if (user == null || user.userId == null) return; // ✅ guard against null

    try {
      final now = DateTime.now();
      final date = now.toIso8601String().split('T').first;

      final session = SessionModel(
        userId: user.userId!,
        title: completedTimer.title ?? 'Focus Session',
        category: completedTimer.category ?? 'General',
        focusMinutes: completedTimer.focusDuration.inMinutes,
        date: date,
        startTime: now.subtract(completedTimer.focusDuration).toIso8601String(),
        endTime: now.toIso8601String(),
        lastUpdated: now.millisecondsSinceEpoch,
      );

      await _sessionRepo.insertSession(session);

      // Recalculate all stats for today
      await _recalculateStatsForDate(user.userId!, date);

      if (_userId != null) await loadUserSessions(_userId!);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// Helper to recalculate all stats for a given date
  Future<void> _recalculateStatsForDate(int userId, String date) async {
    // Recalculate day stats
    await _statsRepo.recalculateDayStats(userId, date);

    // Recalculate hour stats
    await _statsRepo.recalculateHourStats(userId, date);

    // Recalculate week stats (get the week start for this date)
    final dateTime = DateTime.parse(date);
    final weekStart = dateTime.subtract(Duration(days: dateTime.weekday - 1));
    final weekStartStr = weekStart.toIso8601String().split('T').first;
    await _statsRepo.recalculateWeekStats(userId, weekStartStr);
  }
}

/// Provider for session list
final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, List<SessionModel>>(
      SessionNotifier.new,
    );

/// User streak provider
final streakProvider = FutureProvider.family<int, int>((ref, userId) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return await repo.getCurrentStreak(userId);
});

/// Total focus for a given date
final totalFocusByDateProvider =
    FutureProvider.family<int, Map<String, dynamic>>((ref, data) async {
      final repo = ref.watch(sessionRepositoryProvider);
      final userId = data['userId'] as int;
      final date = data['date'] as String;
      return await repo.getTotalFocusByDate(userId, date);
    });

/// Listener that saves session when timer finishes
final sessionSaveListenerProvider = Provider<void>((ref) {
  ref.listen(sessionTimerProvider, (previous, next) {
    // Only trigger when transitioning TO finished state
    if (previous?.phase != SessionPhase.finished &&
        next.phase == SessionPhase.finished) {
      // Use a microtask to avoid modifying state during build
      Future.microtask(() {
        ref.read(sessionProvider.notifier).saveFinishedSession(next);
      });
    }
  });
});
