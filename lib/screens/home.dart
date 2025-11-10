import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo data (replace with DB later)
    final int streakDays = 18;
    final int goalsAchieved = 5;
    final int totalFocusMinutes = 540;
    final double avgSessionLength = 27.3;
    final int sessionsCount = 20;
    final List<int> weeklyFocus = [60, 45, 90, 70, 30, 120, 125];
    final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<DateTime, int> heatmapData = {
      for (int i = 0; i < 14; i++)
        DateTime.now().subtract(Duration(days: i)): (i % 5) * 10,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome Back!"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔥 Streak Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      "$streakDays Day Streak",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Stats
            Row(
              children: [
                Expanded(child: _buildStatCard("Goals", "$goalsAchieved", Icons.check_circle_outline, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard("Total Focus", "${totalFocusMinutes}m", Icons.timer, Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard("Avg Session", "${avgSessionLength.toStringAsFixed(1)}m", Icons.access_time, Colors.orangeAccent)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard("Sessions", "$sessionsCount", Icons.bar_chart, Colors.purpleAccent)),
              ],
            ),

            const SizedBox(height: 28),

            // 📊 Chart
            const Text("This Week’s Focus", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(weekDays[i % 7], style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  barGroups: List.generate(
                    weeklyFocus.length,
                    (i) => BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: weeklyFocus[i].toDouble(),
                        color: Colors.deepOrangeAccent,
                        borderRadius: BorderRadius.circular(6),
                        width: 18,
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 🗓️ Heatmap
            const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: HeatMapCalendar(
                datasets: heatmapData,
                colorMode: ColorMode.opacity,
                colorsets: const {1: Colors.orangeAccent},
                showColorTip: false,
                size: 30,
              ),
            ),

            const SizedBox(height: 40),

            // 🚀 Start Session — HERO BUTTON
            Center(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/session'),
                icon: const Icon(Icons.play_arrow_rounded, size: 34),
                label: const Text("Start a Session"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shadowColor: Colors.deepOrangeAccent.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
