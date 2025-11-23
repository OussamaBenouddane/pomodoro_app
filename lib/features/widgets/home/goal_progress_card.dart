import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:lockin_app/features/controllers/home_controller.dart';

class GoalProgressCard extends ConsumerWidget {
  const GoalProgressCard({super.key});

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.75) return Colors.lightGreen;
    if (progress >= 0.5) return Colors.amber;
    if (progress >= 0.25) return Colors.orange;
    return Colors.deepOrange;
  }

  IconData _getProgressIcon(double progress) {
    if (progress >= 1.0) return Icons.emoji_events;
    if (progress >= 0.75) return Icons.trending_up;
    if (progress >= 0.5) return Icons.flag_rounded;
    return Icons.flag_outlined;
  }

  String _getMotivationalMessage(double progress, int remaining) {
    if (progress >= 1.0) return "🎉 Goal crushed!";
    if (progress >= 0.75) return "Almost there! $remaining min to go";
    if (progress >= 0.5) return "Halfway there! Keep going!";
    if (progress >= 0.25) return "$remaining min left—you got this!";
    if (progress > 0) return "Great start! $remaining min remaining";
    return "Ready to begin? $remaining min today";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref
        .watch(homeControllerProvider)
        .maybeWhen(data: (data) => data, orElse: () => null);

    if (state == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    final cardColor =
        Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;

    final progress = (state.todayFocusMinutes / state.dailyGoalMinutes).clamp(
      0.0,
      1.0,
    );
    final progressColor = _getProgressColor(progress);
    final progressIcon = _getProgressIcon(progress);
    final remaining = math.max(
      0,
      state.dailyGoalMinutes - state.todayFocusMinutes,
    );
    final motivationalMsg = _getMotivationalMessage(progress, remaining);
    final progressPercent = (progress * 100).toInt();

    return Card(
      elevation: isDark ? 0 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              progressColor.withValues(alpha: isDark ? 0.2 : 0.1),
              cardColor,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(progressIcon, color: progressColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Goal",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "$progressPercent% complete",
                        style: TextStyle(
                          fontSize: 13,
                          color: subtextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: subtextColor),
                    onPressed: () async {
                      final newGoal = await _showEditDialog(
                        context,
                        state.dailyGoalMinutes,
                      );
                      if (newGoal != null) {
                        ref
                            .read(homeControllerProvider.notifier)
                            .updateGoal(newGoal);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF374151)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    height: 12,
                    width: MediaQuery.of(context).size.width * progress * 0.85,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor,
                          progressColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "${state.todayFocusMinutes}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        " / ${state.dailyGoalMinutes} min",
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (progress >= 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Done",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                motivationalMsg,
                style: TextStyle(
                  fontSize: 14,
                  color: subtextColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int?> _showEditDialog(BuildContext context, int currentGoal) async {
    final controller = TextEditingController(text: currentGoal.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey[300]!;

    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cardColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flag_rounded, color: Colors.deepOrange),
            ),
            const SizedBox(width: 12),
            Text("Set Daily Goal", style: TextStyle(color: textColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "How many minutes do you want to focus today?",
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Goal (minutes)",
                labelStyle: TextStyle(color: subtextColor),
                prefixIcon: const Icon(Icons.timer_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.deepOrange,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: subtextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(ctx, value);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
