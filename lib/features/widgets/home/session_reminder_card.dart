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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final cardColor = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey[200]!;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.alarm,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Session Reminders",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: primaryColor,
                  ),
                  onPressed: () => _showReminderDialog(context, ref, null),
                ),
              ],
            ),
          ),
          if (reminders.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: subtextColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No reminders set. Tap + to add one.',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ...reminders.map((reminder) => _buildReminderTile(
                      context,
                      ref,
                      reminder,
                    )),
                const SizedBox(height: 8),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey[200]!;
    final tileBackground = isDark ? const Color(0xFF1F2937) : Colors.grey[50];
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Switch(
            value: reminder.isEnabled,
            activeColor: primaryColor,
            onChanged: (value) {
              ref.read(remindersProvider.notifier).toggleReminder(
                    reminder.id,
                    value,
                  );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: reminder.isEnabled
                        ? textColor
                        : subtextColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reminder.timeString} • ${reminder.dayString}',
                  style: TextStyle(
                    fontSize: 13,
                    color: reminder.isEnabled ? subtextColor : subtextColor.withValues(alpha: 0.6),
                  ),
                ),
                if (reminder.isRepeating) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 14,
                        color: subtextColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Repeating',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: subtextColor,
              size: 20,
            ),
            onPressed: () => _showReminderDialog(context, ref, reminder),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red[isDark ? 300 : 400],
              size: 20,
            ),
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
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardColor = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
          final textColor = Theme.of(context).colorScheme.onSurface;
          final subtextColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
          final borderColor = isDark ? const Color(0xFF374151) : Colors.grey[300]!;
          final primaryColor = Theme.of(context).colorScheme.primary;
          final chipBackground = isDark ? const Color(0xFF1F2937) : Colors.grey[100]!;
          final inputBackground = isDark ? const Color(0xFF1F2937) : Colors.grey[50]!;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: cardColor,
            title: Text(
              existingReminder == null ? 'New Reminder' : 'Edit Reminder',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message at the top
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[isDark ? 900 : 50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red[isDark ? 700 : 200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, 
                          size: 20, 
                          color: Colors.red[isDark ? 300 : 700]
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red[isDark ? 300 : 700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: 'e.g., Study Session',
                            labelStyle: TextStyle(color: subtextColor),
                            hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.6)),
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
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red[isDark ? 300 : 300]!,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red[isDark ? 300 : 400]!,
                                width: 2,
                              ),
                            ),
                            counterText: '',
                          ),
                          maxLength: 50,
                        ),
                        const SizedBox(height: 16),

                        // Time Picker
                        InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setState(() => selectedTime = time);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: inputBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subtextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selectedTime.format(context),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          'Days',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Day Selection
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 1; i <= 7; i++)
                              FilterChip(
                                label: Text(_getDayName(i)),
                                selected: selectedDays.contains(i),
                                selectedColor: primaryColor.withValues(alpha: 0.2),
                                checkmarkColor: primaryColor,
                                backgroundColor: chipBackground,
                                side: BorderSide(
                                  color: selectedDays.contains(i)
                                      ? primaryColor
                                      : borderColor,
                                ),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: inputBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Repeat weekly',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              Switch(
                                value: isRepeating,
                                activeColor: primaryColor,
                                onChanged: (value) {
                                  setState(() => isRepeating = value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: subtextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (titleController.text.isEmpty || selectedDays.isEmpty) {
                    setState(() {
                      errorMessage = 'Please fill all fields and select at least one day';
                    });
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
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: cardColor,
        title: Text(
          'Delete Reminder',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${reminder.title}"?',
          style: TextStyle(
            fontSize: 15,
            color: subtextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: subtextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[isDark ? 300 : 400],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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