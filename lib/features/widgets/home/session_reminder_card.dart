import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/home_controller.dart';

class SessionReminderCard extends ConsumerWidget {
  const SessionReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref
        .watch(homeControllerProvider)
        .maybeWhen(data: (data) => data, orElse: () => null);
    if (state == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: const Icon(Icons.alarm, color: Colors.blueAccent, size: 30),
        title: const Text(
          "Session Reminder",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          state.nextReminder,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final newReminder = await _showReminderDialog(
              context,
              state.nextReminder,
            );
            if (newReminder != null) {
              ref
                  .read(homeControllerProvider.notifier)
                  .updateReminder(newReminder);
            }
          },
        ),
      ),
    );
  }

  Future<String?> _showReminderDialog(
    BuildContext context,
    String currentReminder,
  ) async {
    final controller = TextEditingController(text: currentReminder);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set Reminder"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Reminder (e.g. Mon 8:00 PM)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
