import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lockin_app/model/day_stat_model.dart';
import 'package:lockin_app/model/hour_stat_model.dart';
import 'package:lockin_app/providers/stats_provider.dart';
import 'package:lockin_app/providers/user_provider.dart';
import 'package:lockin_app/repositories/stats_repository.dart';
import 'package:lockin_app/features/widgets/stats/month_selector.dart';
import 'package:lockin_app/features/widgets/stats/calendar_heatmap.dart';
import 'package:lockin_app/features/widgets/stats/week_scroller.dart';
import 'package:lockin_app/features/widgets/stats/week_summary_card.dart';
import 'package:lockin_app/features/widgets/stats/weekly_hour_bar_chart.dart';
import 'package:lockin_app/features/widgets/stats/category_pie_chart.dart';

class StatsDashboardScreen extends ConsumerStatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  ConsumerState<StatsDashboardScreen> createState() =>
      _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends ConsumerState<StatsDashboardScreen> {
  DateTime? selectedWeekStart;
  bool isLoadingWeek = false;
  List<HourStatModel> weekHourlyStats = [];
  int _refreshKey = 0; // Add key to track refreshes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      selectedWeekStart = now.subtract(Duration(days: now.weekday - 1));
      _loadWeekStats();
    });
  }

  Future<void> _loadWeekStats() async {
    if (selectedWeekStart == null) return;

    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) return;
    final userId = userAsync.value!.userId!;

    setState(() {
      isLoadingWeek = true;
    });

    try {
      final weekStartStr =
          selectedWeekStart!.toIso8601String().split('T').first;
      await ref.read(statsControllerProvider.notifier).loadWeek(weekStartStr);
      
      // Load hourly stats for the week
      final weekEnd = selectedWeekStart!.add(const Duration(days: 6));
      final weekEndStr = weekEnd.toIso8601String().split('T').first;
      final repo = ref.read(statsRepositoryProvider);
      
      final hourlyData = await repo.getHourlyStatsForRange(
        userId,
        weekStartStr,
        weekEndStr,
      );
      
      if (mounted) {
        setState(() {
          weekHourlyStats = hourlyData;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingWeek = false;
        });
      }
    }
  }

  bool _canNavigateWeek(bool forward) {
    if (selectedWeekStart == null || isLoadingWeek) return false;

    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) return false;

    final user = userAsync.value!;
    final creationDate = DateTime.tryParse(user.dateCreated) ?? DateTime.now();
    final creationWeekStart = creationDate.subtract(Duration(days: creationDate.weekday - 1));

    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));

    final newWeekStart = selectedWeekStart!.add(
      Duration(days: forward ? 7 : -7),
    );

    // Can't go before user creation week
    if (newWeekStart.isBefore(creationWeekStart)) return false;

    // Can't go after current week
    if (newWeekStart.isAfter(currentWeekStart)) return false;

    return true;
  }

  void _changeWeek(bool forward) async {
    if (!_canNavigateWeek(forward)) return;

    final newWeekStart = selectedWeekStart!.add(
      Duration(days: forward ? 7 : -7),
    );

    setState(() {
      selectedWeekStart = newWeekStart;
    });

    await _loadWeekStats();
  }

  Future<List<DayStatModel>> _loadMonthDayStats(
    StatsRepository repo,
    DateTime month,
    int refreshKey, // Add refreshKey parameter
  ) async {
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.value == null) return [];
    final userId = userAsync.value!.userId!;

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    return await repo.getStatsInRange(
      userId,
      DateFormat('yyyy-MM-dd').format(startDate),
      DateFormat('yyyy-MM-dd').format(endDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsControllerProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final monthLabel = DateFormat('MMMM yyyy').format(currentMonth);
    final repo = ref.watch(statsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stats Dashboard"),
        centerTitle: true,
        elevation: 0,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async {
              // Invalidate and wait for rebuild
              ref.invalidate(statsControllerProvider);
              
              // Increment refresh key to force FutureBuilder rebuild
              setState(() {
                _refreshKey++;
              });
              
              // Wait for provider to rebuild
              await Future.delayed(const Duration(milliseconds: 100));
              
              // Reload week stats
              await _loadWeekStats();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MonthSelector(
                  monthLabel: monthLabel,
                  onMonthChange: (forward) {
                    ref
                        .read(statsControllerProvider.notifier)
                        .changeMonth(ref, forward);
                    // Trigger refresh of calendar
                    setState(() {
                      _refreshKey++;
                    });
                  },
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<DayStatModel>>(
                  key: ValueKey(_refreshKey), // Use refresh key to force rebuild
                  future: _loadMonthDayStats(repo, currentMonth, _refreshKey),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return CalendarHeatmap(
                      stats: snapshot.data!,
                      month: currentMonth,
                    );
                  },
                ),
                const SizedBox(height: 24),
                WeekScroller(
                  selectedWeekStart: selectedWeekStart,
                  isLoading: isLoadingWeek,
                  onWeekChange: _changeWeek,
                ),
                const SizedBox(height: 24),
                WeekSummaryCard(weekStats: stats.currentWeek),
                const SizedBox(height: 24),
                WeekHourlyBarChart(hourlyStats: weekHourlyStats),
                const SizedBox(height: 24),
                CategoryPieChart(categoryBreakdown: stats.categoryBreakdown),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}