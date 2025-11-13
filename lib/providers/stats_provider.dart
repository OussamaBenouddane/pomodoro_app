import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/db/db.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lockin_app/model/day_stat_model.dart';
import 'package:lockin_app/model/hour_stat_model.dart';
import 'package:lockin_app/model/week_stat_model.dart';
import 'package:lockin_app/providers/user_provider.dart';
import 'package:lockin_app/repositories/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(DBHelper());
});

final currentMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime.now(); // default to current month
});

final statsControllerProvider =
    AsyncNotifierProvider<StatsController, StatsState>(StatsController.new);

class StatsController extends AsyncNotifier<StatsState> {
  late final StatsRepository _repo;

  @override
  FutureOr<StatsState> build() async {
    _repo = ref.read(statsRepositoryProvider);
    
    // Get actual user ID
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) {
      return const StatsState();
    }
    final userId = userAsync.value!.userId!;
    
    return await _loadInitialStats(userId);
  }

  // Initial load (today, current week, etc.)
  Future<StatsState> _loadInitialStats(int userId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final todayStats = await _repo.getDayStats(userId, today);
    final hourlyStats = await _repo.getHourlyStats(userId, today);
    final mostProductiveHour = await _repo.getMostProductiveHour(userId) ?? -1;

    // Load current week
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = currentWeekStart.toIso8601String().split('T').first;

    final currentWeek = await _repo.getWeekStats(userId, weekStartStr);

    final categoryBreakdown =
        await _getCategoryBreakdownForWeek(userId, currentWeek);

    // Cache starts with the current week only
    final cache = {
      if (currentWeek != null) weekStartStr: currentWeek,
    };

    return StatsState(
      todayStats: todayStats,
      hourlyStats: hourlyStats,
      cachedWeeks: cache,
      currentWeek: currentWeek,
      categoryBreakdown: categoryBreakdown,
      mostProductiveHour: mostProductiveHour,
    );
  }

  // Load a specific week, using cache if possible
  Future<void> loadWeek(String weekStart) async {
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) return;
    final userId = userAsync.value!.userId!;

    final currentState = state.asData?.value;
    if (currentState == null) return;

    // If cached, just switch to it
    if (currentState.cachedWeeks.containsKey(weekStart)) {
      final week = currentState.cachedWeeks[weekStart];
      final breakdown = await _getCategoryBreakdownForWeek(userId, week);
      state = AsyncData(currentState.copyWith(
        currentWeek: week,
        categoryBreakdown: breakdown,
      ));
      return;
    }

    // Not cached → fetch from DB
    final week = await _repo.getWeekStats(userId, weekStart);
    if (week == null) return;

    final updatedCache = Map<String, WeekStatModel>.from(
      currentState.cachedWeeks,
    );
    updatedCache[weekStart] = week;

    // Prune old weeks if cache > 5
    if (updatedCache.length > 5) {
      final sortedKeys = updatedCache.keys.toList()..sort();
      updatedCache.remove(sortedKeys.first);
    }

    final breakdown = await _getCategoryBreakdownForWeek(userId, week);

    state = AsyncData(currentState.copyWith(
      cachedWeeks: updatedCache,
      currentWeek: week,
      categoryBreakdown: breakdown,
    ));
  }

  Future<Map<String, double>> _getCategoryBreakdownForWeek(
    int userId,
    WeekStatModel? week,
  ) async {
    if (week == null) return {};

    final result = await _repo.dbHelper.readDataWithArgs(
      '''
      SELECT category, SUM(focus_minutes) as total
      FROM sessions
      WHERE user_id = ? AND date >= ? AND date <= ?
      GROUP BY category
      ''',
      [userId, week.weekStart, week.weekEnd],
    );

    final total = result.fold<int>(
      0,
      (sum, r) => sum + (r['total'] as int? ?? 0),
    );
    return {
      for (final row in result)
        row['category'] as String:
            (row['total'] as int) / (total == 0 ? 1 : total),
    };
  }

  // Allow controlled month navigation (no past creation or future months)
  void changeMonth(WidgetRef ref, bool forward) {
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) return;

    final user = userAsync.value!;
    final creationDate = DateTime.tryParse(user.dateCreated) ?? DateTime.now();
    final creationMonth = DateTime(creationDate.year, creationDate.month);
    final now = DateTime.now();
    final currentMonth = ref.read(currentMonthProvider);

    DateTime nextMonth;

    if (forward) {
      nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    } else {
      nextMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    }

    if (nextMonth.isBefore(creationMonth) ||
        nextMonth.isAfter(DateTime(now.year, now.month))) {
      return;
    }

    ref.read(currentMonthProvider.notifier).state = nextMonth;
  }
}

class StatsState {
  final DayStatModel? todayStats;
  final List<HourStatModel> hourlyStats;
  final Map<String, WeekStatModel> cachedWeeks;
  final WeekStatModel? currentWeek;
  final Map<String, double> categoryBreakdown;
  final int mostProductiveHour;

  const StatsState({
    this.todayStats,
    this.hourlyStats = const [],
    this.cachedWeeks = const {},
    this.currentWeek,
    this.categoryBreakdown = const {},
    this.mostProductiveHour = -1,
  });

  StatsState copyWith({
    DayStatModel? todayStats,
    List<HourStatModel>? hourlyStats,
    Map<String, WeekStatModel>? cachedWeeks,
    WeekStatModel? currentWeek,
    Map<String, double>? categoryBreakdown,
    int? mostProductiveHour,
  }) {
    return StatsState(
      todayStats: todayStats ?? this.todayStats,
      hourlyStats: hourlyStats ?? this.hourlyStats,
      cachedWeeks: cachedWeeks ?? this.cachedWeeks,
      currentWeek: currentWeek ?? this.currentWeek,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      mostProductiveHour: mostProductiveHour ?? this.mostProductiveHour,
    );
  }
}