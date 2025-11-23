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

    const androidNotificationChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'This channel is used for focus timer foreground service',
      importance: Importance.low,
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

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
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
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    
    Timer? timer;
    
    int remainingSeconds = 0;
    String phase = 'idle';
    String title = 'Focus Session';
    String category = 'General';
    bool isPaused = false;
    int focusDurationSeconds = 1500;
    int breakDurationSeconds = 300;
    
    // ✅ NEW: Track actual focus time
    int? sessionStartTimestamp;
    int totalPausedSeconds = 0;
    int? lastPausedTimestamp;
    int? focusEndTimestamp;
    int? actualFocusMinutes;

    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString('timer_state');
    if (stateJson != null) {
      final state = jsonDecode(stateJson);
      remainingSeconds = state['remainingSeconds'] ?? 0;
      phase = state['phase'] ?? 'idle';
      title = state['title'] ?? 'Focus Session';
      category = state['category'] ?? 'General';
      isPaused = state['isPaused'] ?? false;
      focusDurationSeconds = state['focusDurationSeconds'] ?? 1500;
      breakDurationSeconds = state['breakDurationSeconds'] ?? 300;
      sessionStartTimestamp = state['sessionStartTimestamp'];
      totalPausedSeconds = state['totalPausedSeconds'] ?? 0;
      lastPausedTimestamp = state['lastPausedTimestamp'];
      focusEndTimestamp = state['focusEndTimestamp'];
      actualFocusMinutes = state['actualFocusMinutes'];

      service.invoke('timer_update', {
        'remainingSeconds': remainingSeconds,
        'phase': phase,
        'isPaused': isPaused,
        'title': title,
        'category': category,
        'sessionStartTimestamp': sessionStartTimestamp,
        'totalPausedSeconds': totalPausedSeconds,
        'focusEndTimestamp': focusEndTimestamp,
        'actualFocusMinutes': actualFocusMinutes,
      });
    }
    
    service.on('start_timer').listen((event) async {
      if (event == null) return;
      
      phase = 'focusing';
      remainingSeconds = event['focusDurationSeconds'] as int;
      title = event['title'] as String;
      category = event['category'] as String? ?? 'General';
      focusDurationSeconds = event['focusDurationSeconds'] as int;
      breakDurationSeconds = event['breakDurationSeconds'] as int;
      isPaused = false;
      
      // ✅ Reset tracking variables for new session
      sessionStartTimestamp = DateTime.now().millisecondsSinceEpoch;
      totalPausedSeconds = 0;
      lastPausedTimestamp = null;
      focusEndTimestamp = null;
      actualFocusMinutes = null;
      
      await _saveState(prefs, remainingSeconds, phase, title, category, isPaused, 
                       focusDurationSeconds, breakDurationSeconds,
                       sessionStartTimestamp, totalPausedSeconds, lastPausedTimestamp,
                       focusEndTimestamp, actualFocusMinutes);
      
      service.invoke('timer_update', {
        'remainingSeconds': remainingSeconds,
        'phase': phase,
        'isPaused': isPaused,
        'title': title,
        'category': category,
        'sessionStartTimestamp': sessionStartTimestamp,
        'totalPausedSeconds': totalPausedSeconds,
      });
    });

    service.on('pause').listen((event) async {
      isPaused = true;
      lastPausedTimestamp = DateTime.now().millisecondsSinceEpoch;
      
      await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                       focusDurationSeconds, breakDurationSeconds,
                       sessionStartTimestamp, totalPausedSeconds, lastPausedTimestamp,
                       focusEndTimestamp, actualFocusMinutes);
      
      service.invoke('timer_update', {
        'remainingSeconds': remainingSeconds,
        'phase': phase,
        'isPaused': isPaused,
        'title': title,
        'category': category,
        'lastPausedTimestamp': lastPausedTimestamp,
      });
    });

    service.on('resume').listen((event) async {
      if (lastPausedTimestamp != null) {
        final pauseDuration = DateTime.now().millisecondsSinceEpoch - lastPausedTimestamp!;
        totalPausedSeconds += (pauseDuration / 1000).round();
      }
      
      isPaused = false;
      lastPausedTimestamp = null;
      
      await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                       focusDurationSeconds, breakDurationSeconds,
                       sessionStartTimestamp, totalPausedSeconds, lastPausedTimestamp,
                       focusEndTimestamp, actualFocusMinutes);
      
      service.invoke('timer_update', {
        'remainingSeconds': remainingSeconds,
        'phase': phase,
        'isPaused': isPaused,
        'title': title,
        'category': category,
        'totalPausedSeconds': totalPausedSeconds,
      });
    });

    service.on('stop').listen((event) async {
      // ✅ If stopped during focus phase, calculate actual focus time
      if (phase == 'focusing' && sessionStartTimestamp != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedSeconds = ((now - sessionStartTimestamp!) / 1000).round();
        var totalPaused = totalPausedSeconds;
        
        // Include current pause if paused
        if (isPaused && lastPausedTimestamp != null) {
          totalPaused += ((now - lastPausedTimestamp!) / 1000).round();
        }
        
        final actualFocusSeconds = elapsedSeconds - totalPaused;
        actualFocusMinutes = (actualFocusSeconds / 60).round();
        focusEndTimestamp = now;
        
        print('⏹️ Stopped during focus: ${actualFocusMinutes}min actual focus time');
        
        // Send one final update with focus data before stopping
        service.invoke('session_completed', {
          'focusEndTimestamp': focusEndTimestamp,
          'actualFocusMinutes': actualFocusMinutes,
        });
      }
      
      phase = 'idle';
      remainingSeconds = 0;
      isPaused = false;
      await prefs.remove('timer_state');
      timer?.cancel();
      await flutterLocalNotificationsPlugin.cancel(999);
      service.stopSelf();
    });

    service.on('stopService').listen((event) {
      timer?.cancel();
      service.stopSelf();
    });
    
    service.invoke('service_ready', {});
    
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (!await service.isForegroundService()) {
          await service.setAsForegroundService();
        }
      }

      if (isPaused || phase == 'idle') return;

      if (remainingSeconds > 0) {
        remainingSeconds--;
        
        if (remainingSeconds % 5 == 0) {
          await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                           focusDurationSeconds, breakDurationSeconds,
                           sessionStartTimestamp, totalPausedSeconds, lastPausedTimestamp,
                           focusEndTimestamp, actualFocusMinutes);
        }

        service.invoke('timer_update', {
          'remainingSeconds': remainingSeconds,
          'phase': phase,
          'isPaused': isPaused,
          'title': title,
          'category': category,
        });

        if (service is AndroidServiceInstance) {
          final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
          final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
          final timeStr = '$minutes:$seconds';
          final phaseIcon = phase == 'focusing' ? '🎯' : '☕';
          final phaseTitle = phase == 'focusing' ? 'Focus Mode' : 'Break Time';
          final pauseText = isPaused ? ' (Paused)' : '';
          
          await service.setForegroundNotificationInfo(
            title: '$phaseIcon $phaseTitle - $timeStr$pauseText',
            content: title,
          );
        }
      } else {
        // Timer reached 0
        if (phase == 'focusing') {
          // ✅ FOCUS PHASE COMPLETED - Calculate actual focus time
          if (sessionStartTimestamp != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final elapsedSeconds = ((now - sessionStartTimestamp!) / 1000).round();
            final actualFocusSeconds = elapsedSeconds - totalPausedSeconds;
            actualFocusMinutes = (actualFocusSeconds / 60).round();
            focusEndTimestamp = now;
            
            print('✅ Focus completed: ${actualFocusMinutes}min actual focus time');
            print('   Planned: ${focusDurationSeconds ~/ 60}min');
            print('   Paused: ${totalPausedSeconds ~/ 60}min');
          }
          
          phase = 'onBreak';
          remainingSeconds = breakDurationSeconds;
          isPaused = false;
          
          await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                           focusDurationSeconds, breakDurationSeconds,
                           sessionStartTimestamp, totalPausedSeconds, null,
                           focusEndTimestamp, actualFocusMinutes);
          
          service.invoke('phase_changed', {
            'phase': 'onBreak',
            'remainingSeconds': remainingSeconds,
            'focusEndTimestamp': focusEndTimestamp,
            'actualFocusMinutes': actualFocusMinutes,
          });
        } else if (phase == 'onBreak') {
          // ✅ BREAK COMPLETED - Session finished
          phase = 'finished';
          
          await _saveState(prefs, remainingSeconds, phase, title, category, isPaused,
                           focusDurationSeconds, breakDurationSeconds,
                           sessionStartTimestamp, totalPausedSeconds, null,
                           focusEndTimestamp, actualFocusMinutes);
          
          service.invoke('phase_changed', {
            'phase': 'finished',
            'remainingSeconds': 0,
            'focusEndTimestamp': focusEndTimestamp,
            'actualFocusMinutes': actualFocusMinutes,
          });
          
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
    int? sessionStartTimestamp,
    int totalPausedSeconds,
    int? lastPausedTimestamp,
    int? focusEndTimestamp,
    int? actualFocusMinutes,
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
      'sessionStartTimestamp': sessionStartTimestamp,
      'totalPausedSeconds': totalPausedSeconds,
      'lastPausedTimestamp': lastPausedTimestamp,
      'focusEndTimestamp': focusEndTimestamp,
      'actualFocusMinutes': actualFocusMinutes,
    }));
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
    );

    await notifications.show(
      999,
      '✅ Break Complete!',
      'Your break for "$title" is finished',
      const NotificationDetails(android: androidDetails),
    );
  }
}