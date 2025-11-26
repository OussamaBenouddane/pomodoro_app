// services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lockin_app/model/reminder_model.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<bool> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(settings);

    // Request notification permissions for Android 13+
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }

    return initialized ?? false;
  }

  static Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isEnabled) {
      return;
    }

    for (var day in reminder.days) {
      final id = '${reminder.id}_$day'.hashCode & 0x7FFFFFFF;

      final scheduledDate = _getNextInstanceOfDayAndTime(day, reminder.time);

      try {
        await _notifications.zonedSchedule(
          id,
          'REMINDER',
          reminder.title,
          scheduledDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'reminders',
              'Session Reminders',
              channelDescription: 'Notifications for session reminders',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: reminder.isRepeating
              ? DateTimeComponents.dayOfWeekAndTime
              : DateTimeComponents.time,
        );
      } catch (e) {
        // Handle scheduling error
      }
    }
  }

  static tz.TZDateTime _getNextInstanceOfDayAndTime(
    int targetDay,
    TimeOfDay time,
  ) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Create a DateTime for today at the specified time
    DateTime baseDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Find the next occurrence of the target weekday
    int daysToAdd = (targetDay - baseDate.weekday) % 7;

    // If it's today but the time has already passed, add 7 days
    if (daysToAdd == 0 && baseDate.isBefore(DateTime.now())) {
      daysToAdd = 7;
    }

    baseDate = baseDate.add(Duration(days: daysToAdd));

    // Convert to TZDateTime in local timezone
    final scheduledDate = tz.TZDateTime.from(baseDate, tz.local);

    return scheduledDate;
  }

  static Future<void> cancelReminder(String reminderId, List<int> days) async {
    for (var day in days) {
      final id = '${reminderId}_$day'.hashCode & 0x7FFFFFFF;
      await _notifications.cancel(id);
    }
  }

  // Test notification to verify setup
  static Future<void> showTestNotification() async {
    await _notifications.show(
      0,
      'REMINDER',
      'Test notification - if you see this, notifications work!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Session Reminders',
          channelDescription: 'Notifications for session reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // Schedule a test notification 10 seconds from now
  static Future<void> scheduleTestNotification() async {
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 10));

    await _notifications.zonedSchedule(
      999999,
      'REMINDER',
      'Scheduled test notification (10 seconds)',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Session Reminders',
          channelDescription: 'Notifications for session reminders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
