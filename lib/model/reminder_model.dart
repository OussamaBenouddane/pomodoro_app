// models/reminder_model.dart
import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String title;
  final TimeOfDay time;
  final List<int> days; // 1=Monday, 7=Sunday
  final bool isRepeating;
  final bool isEnabled;

  Reminder({
    required this.id,
    required this.title,
    required this.time,
    required this.days,
    required this.isRepeating,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hour': time.hour,
        'minute': time.minute,
        'days': days,
        'isRepeating': isRepeating,
        'isEnabled': isEnabled,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'],
        title: json['title'],
        time: TimeOfDay(hour: json['hour'], minute: json['minute']),
        days: List<int>.from(json['days']),
        isRepeating: json['isRepeating'],
        isEnabled: json['isEnabled'] ?? true,
      );

  Reminder copyWith({
    String? title,
    TimeOfDay? time,
    List<int>? days,
    bool? isRepeating,
    bool? isEnabled,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      time: time ?? this.time,
      days: days ?? this.days,
      isRepeating: isRepeating ?? this.isRepeating,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  String get dayString {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Weekends';
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }

  String get timeString {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}