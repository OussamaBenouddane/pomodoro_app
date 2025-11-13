import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/home_controller.dart';

class GoalProgressCard extends ConsumerWidget {
  const GoalProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref
        .watch(homeControllerProvider)
        .maybeWhen(data: (data) => data, orElse: () => null);
    if (state == null) return const SizedBox.shrink();

    final progress = (state.todayFocusMinutes / state.dailyGoalMinutes).clamp(
      0.0,
      1.0,
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: Colors.deepOrange),
                const SizedBox(width: 8),
                const Text(
                  "Today's Goal",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
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
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(6),
              color: Colors.deepOrangeAccent,
              backgroundColor: Colors.orangeAccent.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              "${state.todayFocusMinutes} / ${state.dailyGoalMinutes} min",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _showEditDialog(BuildContext context, int currentGoal) async {
    final controller = TextEditingController(text: currentGoal.toString());
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set Daily Goal"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Goal (minutes)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) Navigator.pop(ctx, value);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
