import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lockin_app/model/day_stat_model.dart';
import 'package:lockin_app/model/hour_stat_model.dart';
import 'package:lockin_app/providers/user_provider.dart';
import 'package:lockin_app/repositories/stats_repository.dart';

// ==================== PROVIDERS ====================

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final db = ref.read(dbHelperProvider);
  return StatsRepository(db);
});

final currentMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

class StatsState {
  final List<DayStatModel> dayStats;
  final List<HourStatModel> hourStats;
  final int totalFocusMinutes;
  final bool loading;

  StatsState({
    this.dayStats = const [],
    this.hourStats = const [],
    this.totalFocusMinutes = 0,
    this.loading = false,
  });

  StatsState copyWith({
    List<DayStatModel>? dayStats,
    List<HourStatModel>? hourStats,
    int? totalFocusMinutes,
    bool? loading,
  }) {
    return StatsState(
      dayStats: dayStats ?? this.dayStats,
      hourStats: hourStats ?? this.hourStats,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      loading: loading ?? this.loading,
    );
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  final Ref ref;
  StatsNotifier(this.ref) : super(StatsState());

  Future<void> loadMonthStats() async {
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) return;

    final user = userAsync.value!;
    final repo = ref.read(statsRepositoryProvider);
    final currentMonth = ref.read(currentMonthProvider);

    final startDate = DateTime(currentMonth.year, currentMonth.month, 1);
    final endDate = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    state = state.copyWith(loading: true);

    final dayStats = await repo.getStatsInRange(
      user.userId!,
      DateFormat('yyyy-MM-dd').format(startDate),
      DateFormat('yyyy-MM-dd').format(endDate),
    );

    final total = await repo.getTotalLifetimeFocus(user.userId!);

    // For simplicity, get hourly stats for today only (expand later)
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hourStats = await repo.getHourlyStats(user.userId!, todayString);

    state = state.copyWith(
      dayStats: dayStats,
      hourStats: hourStats,
      totalFocusMinutes: total,
      loading: false,
    );
  }

  void changeMonth(bool forward) {
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

    if (nextMonth.isBefore(creationMonth)) return;
    if (nextMonth.isAfter(DateTime(now.year, now.month))) return;

    ref.read(currentMonthProvider.notifier).state = nextMonth;
    loadMonthStats();
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>(
  (ref) => StatsNotifier(ref),
);

// ==================== UI ====================

class StatsDashboardScreen extends ConsumerWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final monthLabel = DateFormat('MMMM yyyy').format(currentMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stats Dashboard"),
        centerTitle: true,
      ),
      body: stats.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => ref.read(statsProvider.notifier).loadMonthStats(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Month selector ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () =>
                            ref.read(statsProvider.notifier).changeMonth(false),
                      ),
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () =>
                            ref.read(statsProvider.notifier).changeMonth(true),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- Calendar Heatmap ---
                  _buildCalendarHeatmap(stats.dayStats, currentMonth),

                  const SizedBox(height: 24),

                  // --- Focus summary ---
                  _buildSummaryCard(stats.totalFocusMinutes),

                  const SizedBox(height: 24),

                  // --- Focus trend line ---
                  _buildFocusTrend(stats.dayStats),

                  const SizedBox(height: 24),

                  // --- Hourly distribution ---
                  _buildHourlyBarChart(stats.hourStats),

                  const SizedBox(height: 24),

                  // --- Placeholder for category pie chart ---
                  _buildPlaceholderCard("Category Breakdown (Coming Soon)"),
                ],
              ),
            ),
    );
  }

  // ==================== Widgets ====================

  Widget _buildCalendarHeatmap(List<DayStatModel> stats, DateTime month) {
    // Build a map of {dayNumber: focusMinutes}
    final data = <int, int>{};
    for (final stat in stats) {
      final date = DateTime.tryParse(stat.date);
      if (date != null && date.month == month.month) {
        data[date.day] = stat.totalFocusMinutes;
      }
    }

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(daysInMonth, (i) {
        final day = i + 1;
        final minutes = data[day] ?? 0;
        final intensity = (minutes / 60).clamp(0.0, 1.0);
        final color = Color.lerp(Colors.grey[300], Colors.green, intensity);
        return Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            day.toString(),
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(int total) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Total Focus Time",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("$total min",
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusTrend(List<DayStatModel> stats) {
    final spots = <FlSpot>[];
    for (int i = 0; i < stats.length; i++) {
      spots.add(FlSpot(
          i.toDouble(), stats[i].totalFocusMinutes.toDouble()));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Focus Trend",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: false),
                  gridData: const FlGridData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.orange,
                      dotData: const FlDotData(show: false),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyBarChart(List<HourStatModel> stats) {
    final spots = stats
        .map((e) => BarChartGroupData(
              x: e.hour,
              barRods: [
                BarChartRodData(
                  toY: e.focusMinutes.toDouble(),
                  color: Colors.blueAccent,
                  width: 12,
                )
              ],
            ))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Focus by Hour",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          return Text(
                            "$hour",
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: spots,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(String text) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 120,
        child: Center(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
