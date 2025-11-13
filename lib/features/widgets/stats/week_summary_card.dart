import 'package:flutter/material.dart';
import 'package:lockin_app/model/week_stat_model.dart';

class WeekSummaryCard extends StatelessWidget {
  final WeekStatModel? weekStats;

  const WeekSummaryCard({
    super.key,
    required this.weekStats,
  });

  @override
  Widget build(BuildContext context) {
    if (weekStats == null) {
      return const SizedBox.shrink();
    }

    final totalMinutes = weekStats!.totalFocusMinutes;
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final avgLength = weekStats!.averageSessionLength.round();
    final sessionCount = weekStats!.sessionsCount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Week Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.calendar_today,
                  value: hours > 0 ? "${hours}h ${mins}m" : "${mins}m",
                  label: "Total",
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.assessment,
                  value: "${avgLength}m",
                  label: "Avg Session",
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.repeat,
                  value: "$sessionCount",
                  label: "Sessions",
                  color: Colors.red,
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