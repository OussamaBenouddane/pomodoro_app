// widgets/session_reminder_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/model/reminder_model.dart';
import 'package:lockin_app/providers/remiders_provider.dart';

class SessionReminderCard extends ConsumerWidget {
  const SessionReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.alarm,
              color: Colors.blueAccent,
              size: 30,
            ),
            title: const Text(
              "Session Reminders",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                  onPressed: () => _showReminderDialog(context, ref, null),
                ),
              ],
            ),
          ),
          if (reminders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No reminders set. Tap + to add one.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...reminders.map((reminder) => _buildReminderTile(
                  context,
                  ref,
                  reminder,
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildReminderTile(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) {
    return ListTile(
      leading: Switch(
        value: reminder.isEnabled,
        onChanged: (value) {
          ref.read(remindersProvider.notifier).toggleReminder(
                reminder.id,
                value,
              );
        },
      ),
      title: Text(
        reminder.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: reminder.isEnabled ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${reminder.timeString} • ${reminder.dayString}',
            style: TextStyle(
              color: reminder.isEnabled ? Colors.black54 : Colors.grey,
            ),
          ),
          if (reminder.isRepeating)
            Row(
              children: [
                Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Repeating',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showReminderDialog(context, ref, reminder),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context, ref, reminder),
          ),
        ],
      ),
    );
  }

  Future<void> _showReminderDialog(
    BuildContext context,
    WidgetRef ref,
    Reminder? existingReminder,
  ) async {
    final titleController = TextEditingController(
      text: existingReminder?.title ?? '',
    );
    TimeOfDay selectedTime = existingReminder?.time ?? TimeOfDay.now();
    List<int> selectedDays =
        existingReminder?.days ?? [DateTime.now().weekday];
    bool isRepeating = existingReminder?.isRepeating ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
              existingReminder == null ? 'New Reminder' : 'Edit Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Study Session',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),

                // Time Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),

                const Divider(),
                const Text(
                  'Days',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Day Selection
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 1; i <= 7; i++)
                      FilterChip(
                        label: Text(_getDayName(i)),
                        selected: selectedDays.contains(i),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedDays.add(i);
                            } else {
                              selectedDays.remove(i);
                            }
                            selectedDays.sort();
                          });
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeat weekly'),
                  value: isRepeating,
                  onChanged: (value) {
                    setState(() => isRepeating = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty || selectedDays.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please fill all fields and select at least one day'),
                    ),
                  );
                  return;
                }

                final reminder = Reminder(
                  id: existingReminder?.id ?? DateTime.now().toString(),
                  title: titleController.text,
                  time: selectedTime,
                  days: selectedDays,
                  isRepeating: isRepeating,
                );

                if (existingReminder == null) {
                  ref.read(remindersProvider.notifier).addReminder(reminder);
                } else {
                  ref
                      .read(remindersProvider.notifier)
                      .updateReminder(reminder);
                }

                Navigator.pop(ctx);
              },
              child: Text(existingReminder == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
    }
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }
}