import 'package:flutter/material.dart';
import 'package:lockin_app/model/week_stat_model.dart';

class WeekProgressCard extends StatelessWidget {
  final WeekStatModel weekStats;

  const WeekProgressCard({
    super.key,
    required this.weekStats,
  });

  @override
  Widget build(BuildContext context) {
    final goalMinutes = 120 * 7; // 120 min/day * 7 days
    final progress =
        (weekStats.totalFocusMinutes / goalMinutes).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Weekly Goal Progress",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 20,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Colors.blue,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${weekStats.totalFocusMinutes} / $goalMinutes min",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "${(progress * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}