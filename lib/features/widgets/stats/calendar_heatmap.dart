import 'package:flutter/material.dart';
import 'package:lockin_app/model/day_stat_model.dart';

class CalendarHeatmap extends StatelessWidget {
  final List<DayStatModel> stats;
  final DateTime month;

  const CalendarHeatmap({
    super.key,
    required this.stats,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final data = <int, int>{};
    for (final stat in stats) {
      final date = DateTime.tryParse(stat.date);
      if (date != null && date.month == month.month) {
        data[date.day] = stat.totalFocusMinutes;
      }
    }

    final maxMinutes = data.values.isEmpty
        ? 120
        : data.values.reduce((a, b) => a > b ? a : b);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Focus Heatmap",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(daysInMonth, (i) {
                final day = i + 1;
                final minutes = data[day] ?? 0;
                final intensity = maxMinutes > 0 ? (minutes / maxMinutes) : 0.0;
                final color = minutes == 0
                    ? Colors.grey[200]
                    : Color.lerp(
                        Colors.blue.shade100, Colors.blue.shade700, intensity);

                return Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: intensity > 0.5
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      if (minutes > 0)
                        Text(
                          "${minutes}m",
                          style: TextStyle(
                            fontSize: 8,
                            color: intensity > 0.5
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.grey[200]!, "No focus"),
                const SizedBox(width: 12),
                _buildLegendItem(Colors.blue.shade100, "Low"),
                const SizedBox(width: 12),
                _buildLegendItem(Colors.blue.shade400, "Medium"),
                const SizedBox(width: 12),
                _buildLegendItem(Colors.blue.shade700, "High"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}