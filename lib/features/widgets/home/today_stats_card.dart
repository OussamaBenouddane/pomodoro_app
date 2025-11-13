import 'package:flutter/material.dart';
import 'package:lockin_app/model/day_stat_model.dart';

class TodayStatsCard extends StatelessWidget {
  final DayStatModel? todayStats;
  final int mostProductiveHour;

  const TodayStatsCard({
    super.key,
    required this.todayStats,
    required this.mostProductiveHour,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = todayStats?.totalFocusMinutes ?? 0;
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Today's Focus",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.timer,
                  value: hours > 0
                      ? "${hours}h ${remainingMins}m"
                      : "${remainingMins}m",
                  label: "Total Time",
                  color: Colors.orange,
                ),
                _buildStatItem(
                  icon: Icons.schedule,
                  value: mostProductiveHour >= 0
                      ? "${mostProductiveHour}:00"
                      : "N/A",
                  label: "Peak Hour",
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}