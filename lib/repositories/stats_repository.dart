import 'package:lockin_app/db/db.dart';
import 'package:lockin_app/model/day_stat_model.dart';
import 'package:lockin_app/model/week_stat_model.dart';
import 'package:lockin_app/model/hour_stat_model.dart';

class StatsRepository {
  final DBHelper dbHelper;
  StatsRepository(this.dbHelper);

  // ==================== DAY STATS ====================

  Future<DayStatModel?> getDayStats(int userId, String date) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT * FROM day_stats WHERE user_id = ? AND date = ? LIMIT 1',
      [userId, date],
    );

    if (result.isEmpty) return null;
    return DayStatModel.fromMap(result.first);
  }

  Future<int> upsertDayStats(DayStatModel stats) async {
    return await dbHelper.insertData('day_stats', stats.toMap());
  }

  Future<List<DayStatModel>> getStatsInRange(
    int userId,
    String startDate,
    String endDate,
  ) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT * FROM day_stats WHERE user_id = ? AND date >= ? AND date <= ? ORDER BY date ASC',
      [userId, startDate, endDate],
    );

    return result.map((map) => DayStatModel.fromMap(map)).toList();
  }

  Future<int> getTotalLifetimeFocus(int userId) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT SUM(total_focus_minutes) as total FROM day_stats WHERE user_id = ?',
      [userId],
    );

    return result.first['total'] as int? ?? 0;
  }

  // ==================== WEEK STATS ====================

  Future<WeekStatModel?> getWeekStats(int userId, String weekStart) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT * FROM week_stats WHERE user_id = ? AND week_start = ? LIMIT 1',
      [userId, weekStart],
    );

    if (result.isEmpty) return null;
    return WeekStatModel.fromMap(result.first);
  }

  Future<int> upsertWeekStats(WeekStatModel stats) async {
    return await dbHelper.insertData('week_stats', stats.toMap());
  }

  Future<List<WeekStatModel>> getRecentWeeks(int userId, int count) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT * FROM week_stats WHERE user_id = ? ORDER BY week_start DESC LIMIT ?',
      [userId, count],
    );

    return result.map((map) => WeekStatModel.fromMap(map)).toList();
  }


  Future<List<HourStatModel>> getHourlyStatsForRange(
    int userId,
    String startDate,
    String endDate,
  ) async {
    // Get aggregated hourly stats from the hour_stats table for the week range
    final result = await dbHelper.readDataWithArgs(
      '''
    SELECT hour, SUM(focus_minutes) as total_minutes
    FROM hour_stats
    WHERE user_id = ? AND date >= ? AND date <= ?
    GROUP BY hour
    ORDER BY hour
    ''',
      [userId, startDate, endDate],
    );

    return result.map((row) {
      return HourStatModel(
        userId: userId,
        date: startDate, // Use start date as reference
        hour: row['hour'] as int,
        focusMinutes: row['total_minutes'] as int,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );
    }).toList();
  }
  // ==================== HOUR STATS ====================

  Future<List<HourStatModel>> getHourlyStats(int userId, String date) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT * FROM hour_stats WHERE user_id = ? AND date = ? ORDER BY hour ASC',
      [userId, date],
    );

    return result.map((map) => HourStatModel.fromMap(map)).toList();
  }

  Future<int> upsertHourStats(HourStatModel stats) async {
    return await dbHelper.insertData('hour_stats', stats.toMap());
  }

  /// Get the most productive hour of the day (across all time)
  Future<int?> getMostProductiveHour(int userId) async {
    final result = await dbHelper.readDataWithArgs(
      '''
      SELECT hour, SUM(focus_minutes) as total
      FROM hour_stats
      WHERE user_id = ?
      GROUP BY hour
      ORDER BY total DESC
      LIMIT 1
    ''',
      [userId],
    );

    if (result.isEmpty) return null;
    return result.first['hour'] as int;
  }

  // ==================== AGGREGATION HELPERS ====================

  /// Calculate and update day stats from sessions
  Future<void> recalculateDayStats(int userId, String date) async {
    // Sum all focus minutes for this day
    final result = await dbHelper.readDataWithArgs(
      '''
      SELECT SUM(focus_minutes) as total
      FROM sessions
      WHERE user_id = ? AND date = ?
    ''',
      [userId, date],
    );

    final total = result.first['total'] as int? ?? 0;

    final dayStats = DayStatModel(
      userId: userId,
      date: date,
      totalFocusMinutes: total,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );

    await upsertDayStats(dayStats);
  }

  /// Calculate and update week stats from sessions
  Future<void> recalculateWeekStats(int userId, String weekStart) async {
    // Calculate week end (6 days after start)
    final startDate = DateTime.parse(weekStart);
    final endDate = startDate.add(const Duration(days: 6));
    final weekEnd = endDate.toIso8601String().split('T').first;

    // Get all sessions in this week
    final result = await dbHelper.readDataWithArgs(
      '''
      SELECT 
        SUM(focus_minutes) as total,
        AVG(focus_minutes) as average,
        COUNT(*) as count
      FROM sessions
      WHERE user_id = ? AND date >= ? AND date <= ?
    ''',
      [userId, weekStart, weekEnd],
    );

    final data = result.first;
    final total = data['total'] as int? ?? 0;
    final average = data['average'] as double? ?? 0.0;
    final count = data['count'] as int? ?? 0;

    final weekStats = WeekStatModel(
      userId: userId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalFocusMinutes: total,
      averageSessionLength: average,
      sessionsCount: count,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );

    await upsertWeekStats(weekStats);
  }

  /// Calculate hour stats from sessions
  Future<void> recalculateHourStats(int userId, String date) async {
    // Get all sessions for this date
    final sessions = await dbHelper.readDataWithArgs(
      'SELECT * FROM sessions WHERE user_id = ? AND date = ?',
      [userId, date],
    );

    // Group by hour and sum focus minutes
    final hourMap = <int, int>{};

    for (final session in sessions) {
      final startTime = DateTime.parse(session['start_time'] as String);
      final hour = startTime.hour;
      final minutes = session['focus_minutes'] as int;

      hourMap[hour] = (hourMap[hour] ?? 0) + minutes;
    }

    // Insert/update hour stats
    for (final entry in hourMap.entries) {
      final hourStats = HourStatModel(
        userId: userId,
        date: date,
        hour: entry.key,
        focusMinutes: entry.value,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );

      await upsertHourStats(hourStats);
    }
  }
}
