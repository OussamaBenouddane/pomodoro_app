// services/timer_background_service.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

@pragma('vm:entry-point')
class TimerBackgroundService {
  static const String channelId = 'timer_foreground_service';
  static const String channelName = 'Focus Timer Service';
  static const int notificationId = 888;
  static const String breakChannelId = 'break_complete';
  static const String breakChannelName = 'Break Complete';

  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create notification channels
    const androidNotificationChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'This channel is used for focus timer foreground service',
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
    );

    const breakNotificationChannel = AndroidNotificationChannel(
      breakChannelId,
      breakChannelName,
      description: 'Notification when break is complete',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(androidNotificationChannel);
    await androidPlugin?.createNotificationChannel(breakNotificationChannel);

    // Initialize notification plugin with action handler
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationAction(details.actionId);
      },
    );

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: false,
        notificationChannelId: channelId,
        initialNotificationTitle: 'Focus Timer',
        initialNotificationContent: 'Starting timer...',
        foregroundServiceNotificationId: notificationId,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void _handleNotificationAction(String? actionId) {
    if (actionId == null) return;
    
    final service = FlutterBackgroundService();
    print('🔔 Notification action received: $actionId');
    
    if (actionId == 'pause_timer') {
      service.invoke('pause');
    } else if (actionId == 'resume_timer') {
      service.invoke('resume');
    } else if (actionId == 'stop_timer') {
      service.invoke('stop');
    } else if (actionId == 'end_session') {
      service.invoke('break_action', {'action': 'end'});
    } else if (actionId == 'continue_session') {
      service.invoke('break_action', {'action': 'continue'});
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    print('🟢🟢🟢 SERVICE ENTRY POINT HIT 🟢🟢🟢');
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    print('🔧 Setting up service...');
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Initialize the notification plugin in this isolate as well
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationAction(details.actionId);
      },
    );
    
    Timer? timer;
    
    // Timer state variables
    int remainingSeconds = 0;
    String phase = 'idle';
    String title = 'Focus Session';
    String category = 'General';
    bool isPaused = false;
    int focusDurationSeconds = 1500;
    int breakDurationSeconds = 300;

    print('📂 Loading initial state...');
    // Load initial state
    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString('timer_state');
    if (stateJson != null) {
      print('✓ Found existing state');
      final state = jsonDecode(stateJson);
      remainingSeconds = state['remainingSeconds'] ?? 0;
      phase = state['phase'] ?? 'idle';
      title = state['title'] ?? 'Focus Session';
      category = state['category'] ?? 'General';
      isPaused = state['isPaused'] ?? false;
      focusDurationSeconds = state['focusDurationSeconds'] ?? 1500;
      breakDurationSeconds = state['breakDurationSeconds'] ?? 300;

      // Send initial state to app
      service.invoke('timer_update', {
        'remainingSeconds': remainingSeconds,
        'phase': phase,
        'isPaused': isPaused,
        'title': title,
        'category': category,
      });
    } else {
      print('✓ No existing state found');
    }

    print('🎧 Setting up event listeners...');
    
    // Set up event listeners ONCE
    service.on('start_timer').listen((event) async {
      print('🚀 Background service: Received start_timer event');
      
      if (event == null) {
        print('❌ ERROR: Event is null!');
        return;
      }
      
      phase = 'focusing';
      remainingSeconds = event['focusDurationSeconds'] as int;
      title = event['title'] as String;
      category = event['category'] as String? ?? 'General';
      focusDurationSeconds = event['focusDurationSeconds'] as int;
      breakDurationSeconds = event['breakDurationSeconds'] as int;
      isPaused = false;
      
      print('✓ Set state: phase=$phase, remaining=${remainingSeconds}s');
      
      await _saveState(prefs, remainingSeconds, phase, title, category, isPaused, 
                       focusDurationSeconds, breakDurationSeconds);
      
      // Send immediate update to app
      service.invoke('timer_update', {
        'remainingSeconds': remainingSeconds,
        'phase': phase,
        'isPaused': isPaused,
        'title': title,
        'category': category,
      });
      
      // Update notification immediately with actions
      await _updateNotification(
        service,
        flutterLocalNotificationsPlugin,
        remainingSeconds,
        phase,
        title,
        isPaused,
      );
      
      print('✅ Background service: Timer started successfully');
    });

    service.on('pause').listen((event) async {
      print('⏸️ Background service: Pausing');
      isPaused = true;
      await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                       focusDurationSeconds, breakDurationSeconds);
      
      service.invoke('timer_update', {
        'remainingSeconds': remainingSeconds,
        'phase': phase,
        'isPaused': isPaused,
        'title': title,
        'category': category,
      });
      
      await _updateNotification(
        service,
        flutterLocalNotificationsPlugin,
        remainingSeconds,
        phase,
        title,
        isPaused,
      );
    });

    service.on('resume').listen((event) async {
      print('▶️ Background service: Resuming');
      isPaused = false;
      await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                       focusDurationSeconds, breakDurationSeconds);
      
      service.invoke('timer_update', {
        'remainingSeconds': remainingSeconds,
        'phase': phase,
        'isPaused': isPaused,
        'title': title,
        'category': category,
      });
      
      await _updateNotification(
        service,
        flutterLocalNotificationsPlugin,
        remainingSeconds,
        phase,
        title,
        isPaused,
      );
    });

    service.on('stop').listen((event) async {
      print('⏹️ Background service: Stopping');
      phase = 'idle';
      remainingSeconds = 0;
      isPaused = false;
      await prefs.remove('timer_state');
      timer?.cancel();
      
      // Cancel any break notifications
      await flutterLocalNotificationsPlugin.cancel(999);
      
      service.stopSelf();
    });

    service.on('break_action').listen((event) async {
      final action = event!['action'] as String;
      print('🔔 Background service: Break action - $action');
      
      // Cancel the break notification
      await flutterLocalNotificationsPlugin.cancel(999);
      
      if (action == 'end') {
        phase = 'idle';
        remainingSeconds = 0;
        await prefs.remove('timer_state');
        timer?.cancel();
        service.stopSelf();
      } else if (action == 'continue') {
        phase = 'focusing';
        remainingSeconds = focusDurationSeconds;
        isPaused = false;
        await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                         focusDurationSeconds, breakDurationSeconds);
        
        service.invoke('phase_changed', {
          'phase': 'focusing',
          'remainingSeconds': remainingSeconds,
        });
        
        await _updateNotification(
          service,
          flutterLocalNotificationsPlugin,
          remainingSeconds,
          phase,
          title,
          isPaused,
        );
      }
    });

    service.on('stopService').listen((event) {
      print('🛑 Background service: Received stopService');
      timer?.cancel();
      service.stopSelf();
    });
    
    print('✅ Event listeners set up complete');
    print('🚀 Service is ready to receive commands');
    
    // Signal that service is ready
    service.invoke('service_ready', {});
    print('📢 Sent service_ready signal to app');
    
    // Start the timer loop
    print('⏰ Starting timer loop...');
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // Ensure we're a foreground service
      if (service is AndroidServiceInstance) {
        if (!await service.isForegroundService()) {
          await service.setAsForegroundService();
        }
      }

      // Don't tick if paused or idle
      if (isPaused || phase == 'idle') {
        return;
      }

      if (remainingSeconds > 0) {
        remainingSeconds--;
        
        // Save state every 5 seconds
        if (remainingSeconds % 5 == 0) {
          await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                           focusDurationSeconds, breakDurationSeconds);
        }

        // Send update to app EVERY second
        service.invoke('timer_update', {
          'remainingSeconds': remainingSeconds,
          'phase': phase,
          'isPaused': isPaused,
          'title': title,
          'category': category,
        });

        // Update notification using the service's method (not creating a new one)
        if (service is AndroidServiceInstance) {
          final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
          final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
          final timeStr = '$minutes:$seconds';
          final phaseIcon = phase == 'focusing' ? '🎯' : '☕';
          final phaseTitle = phase == 'focusing' ? 'Focus Mode' : 'Break Time';
          final pauseText = isPaused ? ' (Paused)' : '';
          
          // Use setForegroundNotificationInfo to UPDATE existing notification
          await service.setForegroundNotificationInfo(
            title: '$phaseIcon $phaseTitle - $timeStr$pauseText',
            content: title,
          );
        }
      } else {
        // Timer reached zero
        if (phase == 'focusing') {
          print('✅ Focus complete, starting break');
          phase = 'onBreak';
          remainingSeconds = breakDurationSeconds;
          isPaused = false;
          await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                           focusDurationSeconds, breakDurationSeconds);
          
          service.invoke('phase_changed', {
            'phase': 'onBreak',
            'remainingSeconds': remainingSeconds,
          });
          
          await _updateNotification(
            service,
            flutterLocalNotificationsPlugin,
            remainingSeconds,
            phase,
            title,
            isPaused,
          );
        } else if (phase == 'onBreak') {
          print('✅ Break complete');
          phase = 'finished';
          await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                           focusDurationSeconds, breakDurationSeconds);
          
          service.invoke('phase_changed', {
            'phase': 'finished',
            'remainingSeconds': 0,
          });
          
          // Show break complete notification with actions
          await _showBreakCompleteNotification(flutterLocalNotificationsPlugin, title);
        }
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _saveState(
    SharedPreferences prefs,
    int remainingSeconds,
    String phase,
    String title,
    String category,
    bool isPaused,
    int focusDurationSeconds,
    int breakDurationSeconds,
  ) async {
    await prefs.setString('timer_state', jsonEncode({
      'remainingSeconds': remainingSeconds,
      'phase': phase,
      'title': title,
      'category': category,
      'isPaused': isPaused,
      'focusDurationSeconds': focusDurationSeconds,
      'breakDurationSeconds': breakDurationSeconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  @pragma('vm:entry-point')
  static Future<void> _updateNotification(
    ServiceInstance service,
    FlutterLocalNotificationsPlugin notifications,
    int remainingSeconds,
    String phase,
    String title,
    bool isPaused,
  ) async {
    if (service is! AndroidServiceInstance) return;

    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    final timeStr = '$minutes:$seconds';

    final phaseIcon = phase == 'focusing' ? '🎯' : '☕';
    final phaseTitle = phase == 'focusing' ? 'Focus Mode' : 'Break Time';
    final pauseText = isPaused ? ' (Paused)' : '';

    // For initial notification and when adding action buttons, use notifications.show()
    // This is called when starting, pausing, resuming
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Focus timer foreground service',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      actions: [
        if (!isPaused)
          AndroidNotificationAction(
            'pause_timer',
            'Pause',
            showsUserInterface: false,
            cancelNotification: false,
          )
        else
          AndroidNotificationAction(
            'resume_timer',
            'Resume',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        AndroidNotificationAction(
          'stop_timer',
          'Stop',
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
    );

    try {
      // Only show notification with actions when we need to update the buttons
      await notifications.show(
        notificationId,
        '$phaseIcon $phaseTitle - $timeStr$pauseText',
        title,
        NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      print('❌ Error updating notification: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _showBreakCompleteNotification(
    FlutterLocalNotificationsPlugin notifications,
    String title,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      breakChannelId,
      breakChannelName,
      channelDescription: 'Notification when break is complete',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: false,
      autoCancel: true,
      playSound: true,
      enableVibration: true,
      actions: [
        AndroidNotificationAction(
          'end_session',
          'End Session',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'continue_session',
          'Continue Focus',
          showsUserInterface: true,
        ),
      ],
    );

    await notifications.show(
      999, // Different ID from foreground notification
      '✅ Break Complete!',
      'Ready to continue $title?',
      const NotificationDetails(android: androidDetails),
    );
  }
}