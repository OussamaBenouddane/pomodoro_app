import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lockin_app/model/hour_stat_model.dart';

class WeekHourlyBarChart extends StatelessWidget {
  final List<HourStatModel> hourlyStats;

  const WeekHourlyBarChart({
    super.key,
    required this.hourlyStats,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyStats.isEmpty) {
      return _buildEmptyChart("No hourly data for this week");
    }

    final spots = hourlyStats
        .map((e) => BarChartGroupData(
              x: e.hour,
              barRods: [
                BarChartRodData(
                  toY: e.focusMinutes.toDouble(),
                  color: Colors.blueAccent,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                )
              ],
            ))
        .toList();

    final maxY = hourlyStats
        .map((e) => e.focusMinutes)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Focus by Hour (This Week)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 100 ? 60 : 30,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "${value.toInt()}m",
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
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
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "$hour",
                              style: const TextStyle(fontSize: 10),
                            ),
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

  Widget _buildEmptyChart(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}