// providers/reminders_provider.dart
import 'package:flutter_riverpod/legacy.dart';
import 'package:lockin_app/model/reminder_model.dart';
import 'package:lockin_app/services/notification_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RemindersNotifier extends StateNotifier<List<Reminder>> {
  RemindersNotifier() : super([]) {
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('reminders') ?? [];
    state = remindersJson
        .map((json) => Reminder.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson =
        state.map((reminder) => jsonEncode(reminder.toJson())).toList();
    await prefs.setStringList('reminders', remindersJson);
  }

  void addReminder(Reminder reminder) {
    state = [...state, reminder];
    _saveReminders();
    NotificationService.scheduleReminder(reminder);
  }

  void updateReminder(Reminder reminder) {
    state = [
      for (final r in state)
        if (r.id == reminder.id) reminder else r
    ];
    _saveReminders();
    NotificationService.cancelReminder(reminder.id, reminder.days);
    NotificationService.scheduleReminder(reminder);
  }

  void deleteReminder(String id) {
    final reminder = state.firstWhere((r) => r.id == id);
    state = state.where((r) => r.id != id).toList();
    _saveReminders();
    NotificationService.cancelReminder(id, reminder.days);
  }

  void toggleReminder(String id, bool enabled) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(isEnabled: enabled) else r
    ];
    _saveReminders();

    final reminder = state.firstWhere((r) => r.id == id);
    if (enabled) {
      NotificationService.scheduleReminder(reminder);
    } else {
      NotificationService.cancelReminder(id, reminder.days);
    }
  }
}

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<Reminder>>(
  (ref) => RemindersNotifier(),
);