import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/features/controllers/home_controller.dart';
import 'package:lockin_app/features/widgets/home/goal_progress_card.dart';
import 'package:lockin_app/features/widgets/home/session_reminder_card.dart';
import 'package:lockin_app/features/widgets/home/start_session_button.dart';
import 'package:lockin_app/features/widgets/home/streak_display.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(homeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Welcome Back!")),
      body: asyncState.when(
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SizedBox(height: 8),
              StreakDisplay(),
              SizedBox(height: 32),
              StartSessionButton(),
              SizedBox(height: 32),
              GoalProgressCard(),
              SizedBox(height: 16),
              SessionReminderCard(),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
