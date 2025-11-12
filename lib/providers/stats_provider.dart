import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lockin_app/db/db.dart';
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
    // you could optionally store current userId in a userProvider
    const userId = 1;
    return await _loadStats(userId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    const userId = 1;
    state = AsyncData(await _loadStats(userId));
  }

  Future<StatsState> _loadStats(int userId) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final todayStats = await _repo.getDayStats(userId, today);
    final hourlyStats = await _repo.getHourlyStats(userId, today);
    final recentWeeks = await _repo.getRecentWeeks(userId, 4);
    final mostProductiveHour = await _repo.getMostProductiveHour(userId) ?? -1;

    // Category breakdown for the current month
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      1,
    ).toIso8601String().split('T').first;
    final end = DateTime(
      now.year,
      now.month + 1,
      0,
    ).toIso8601String().split('T').first;

    final result = await _repo.dbHelper.readDataWithArgs(
      '''
      SELECT category, SUM(focus_minutes) as total
      FROM sessions
      WHERE user_id = ? AND date >= ? AND date <= ?
      GROUP BY category
    ''',
      [userId, start, end],
    );

    final total = result.fold<int>(
      0,
      (sum, r) => sum + (r['total'] as int? ?? 0),
    );
    final categoryBreakdown = {
      for (final row in result)
        row['category'] as String:
            (row['total'] as int) / (total == 0 ? 1 : total),
    };

    return StatsState(
      todayStats: todayStats,
      hourlyStats: hourlyStats,
      recentWeeks: recentWeeks,
      categoryBreakdown: categoryBreakdown,
      mostProductiveHour: mostProductiveHour,
    );
  }

  void changeMonth(WidgetRef ref, bool forward) {
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) return;

    final user = userAsync.value!;
    // Parse the string date
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

    // Prevent going before creation month or after current month
    if (nextMonth.isBefore(creationMonth)) {
      return;
    }
    if (nextMonth.isAfter(DateTime(now.year, now.month))) {
      return;
    }

    // Safe to change
    ref.read(currentMonthProvider.notifier).state = nextMonth;
  }
}

class StatsState {
  final DayStatModel? todayStats;
  final List<HourStatModel> hourlyStats;
  final List<WeekStatModel> recentWeeks;
  final Map<String, double> categoryBreakdown;
  final int mostProductiveHour;

  const StatsState({
    this.todayStats,
    this.hourlyStats = const [],
    this.recentWeeks = const [],
    this.categoryBreakdown = const {},
    this.mostProductiveHour = -1,
  });
}
