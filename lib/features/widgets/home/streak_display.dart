import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/home_controller.dart';

class StreakDisplay extends ConsumerWidget {
  const StreakDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref
        .watch(homeControllerProvider)
        .maybeWhen(data: (data) => data, orElse: () => null);

    final streak = state?.streakDays ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.deepOrange,
              size: 30,
            ),
            const SizedBox(width: 8),
            Text(
              "$streak-day streak",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
