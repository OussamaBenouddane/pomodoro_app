// services/timer_service_manager.dart
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/model/session_timer_model.dart';
import 'package:lockin_app/providers/session_timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Manages communication between the app and background service
class TimerServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static WidgetRef? _ref;
  static bool _isListening = false;
  static Completer<void>? _serviceReadyCompleter;
  static StreamSubscription? _timerUpdateSub;
  static StreamSubscription? _phaseChangedSub;
  static StreamSubscription? _serviceReadySub;

  static void initialize(WidgetRef ref) {
    _ref = ref;
    
    if (!_isListening) {
      _isListening = true;
      print('🎧 Setting up service listeners...');
      
      // Cancel any existing subscriptions
      _timerUpdateSub?.cancel();
      _phaseChangedSub?.cancel();
      _serviceReadySub?.cancel();
      
      // Listen for service ready signal
      _serviceReadySub = _service.on('service_ready').listen((event) {
        print('✅ Service confirmed ready!');
        if (_serviceReadyCompleter != null && !_serviceReadyCompleter!.isCompleted) {
          _serviceReadyCompleter!.complete();
        }
      });
      
      // Listen for updates from background service
      _timerUpdateSub = _service.on('timer_update').listen((event) {
        if (event != null) {
          _syncFromService(event);
        }
      });

      _phaseChangedSub = _service.on('phase_changed').listen((event) {
        if (event != null) {
          _handlePhaseChange(event);
        }
      });
      
      print('✅ Service listeners set up');
    }

    // Restore state if service was running
    _restoreStateIfNeeded();
  }

  static Future<void> _restoreStateIfNeeded() async {
    if (_ref == null) return;

    final isRunning = await _service.isRunning();
    print('🔍 Service running: $isRunning');

    if (!isRunning) return;

    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString('timer_state');
    
    if (stateJson != null) {
      print('🔄 Restoring timer state from SharedPreferences');
      final state = jsonDecode(stateJson);
      final phase = state['phase'] as String;
      
      if (phase == 'focusing' || phase == 'onBreak') {
        final remainingSeconds = state['remainingSeconds'] as int;
        final title = state['title'] as String;
        final category = state['category'] as String? ?? 'General';
        final isPaused = state['isPaused'] as bool;
        final focusDurationSeconds = state['focusDurationSeconds'] as int;
        final breakDurationSeconds = state['breakDurationSeconds'] as int;
        
        final sessionPhase = phase == 'focusing' 
            ? SessionPhase.focusing 
            : SessionPhase.onBreak;
        
        final timerState = SessionTimerState(
          phase: sessionPhase,
          title: title,
          category: category,
          focusDuration: Duration(seconds: focusDurationSeconds),
          breakDuration: Duration(seconds: breakDurationSeconds),
          remaining: Duration(seconds: remainingSeconds),
          isPaused: isPaused,
          sessionStartedAt: DateTime.now(),
          totalPausedDuration: Duration.zero,
        );
        
        // Update the provider state
        final notifier = _ref!.read(sessionTimerProvider.notifier);
        notifier.updateStateFromService(timerState);
        
        print('✅ State restored: $phase, $remainingSeconds seconds remaining');
      }
    }
  }

  static void _syncFromService(Map<String, dynamic> data) {
    if (_ref == null) {
      print('⚠️ Warning: _ref is null, cannot sync state');
      return;
    }

    final remainingSeconds = data['remainingSeconds'] as int;
    final phase = data['phase'] as String;
    final isPaused = data['isPaused'] as bool;
    final title = data['title'] as String? ?? 'Focus Session';
    final category = data['category'] as String? ?? 'General';

    // Only log every 10 seconds to avoid spam
    if (remainingSeconds % 10 == 0) {
      print('🔄 Syncing from service: $remainingSeconds seconds, phase: $phase, paused: $isPaused');
    }

    final currentState = _ref!.read(sessionTimerProvider);
    
    final sessionPhase = phase == 'focusing' 
        ? SessionPhase.focusing 
        : phase == 'onBreak' 
            ? SessionPhase.onBreak
            : SessionPhase.idle;

    // Update state - this will trigger UI rebuild
    final notifier = _ref!.read(sessionTimerProvider.notifier);
    notifier.updateStateFromService(currentState.copyWith(
      phase: sessionPhase,
      remaining: Duration(seconds: remainingSeconds),
      isPaused: isPaused,
      title: title,
      category: category,
    ));
  }

  static void _handlePhaseChange(Map<String, dynamic> data) {
    if (_ref == null) return;

    final phase = data['phase'] as String;
    final remainingSeconds = data['remainingSeconds'] as int? ?? 0;
    
    print('🔄 Phase changed to: $phase');

    final currentState = _ref!.read(sessionTimerProvider);
    final notifier = _ref!.read(sessionTimerProvider.notifier);
    
    if (phase == 'onBreak') {
      notifier.updateStateFromService(currentState.copyWith(
        phase: SessionPhase.onBreak,
        remaining: Duration(seconds: remainingSeconds),
        isPaused: false,
      ));
    } else if (phase == 'finished') {
      notifier.updateStateFromService(currentState.copyWith(
        phase: SessionPhase.finished,
      ));
    } else if (phase == 'focusing') {
      notifier.updateStateFromService(currentState.copyWith(
        phase: SessionPhase.focusing,
        remaining: Duration(seconds: remainingSeconds),
        isPaused: false,
      ));
    }
  }

  static Future<void> startTimer({
    required String title,
    required String category,
    required Duration focusDuration,
    required Duration breakDuration,
  }) async {
    print('🚀 Starting timer service...');
    final isRunning = await _service.isRunning();
    
    if (!isRunning) {
      print('⏳ Service not running, starting it...');
      
      // Create a completer to wait for service ready signal
      _serviceReadyCompleter = Completer<void>();
      
      await _service.startService();
      
      // Wait for service to signal it's ready (with timeout)
      try {
        print('⏳ Waiting for service to be ready...');
        await _serviceReadyCompleter!.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ Service ready timeout, proceeding anyway');
          },
        );
      } catch (e) {
        print('⚠️ Error waiting for service: $e');
      }
      
      // Add extra delay to ensure service is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      print('✓ Service already running');
      // Service already running, small delay to ensure it's responsive
      await Future.delayed(const Duration(milliseconds: 300));
    }

    print('📤 Sending start_timer command with data:');
    print('   title: $title');
    print('   category: $category');
    print('   focusDuration: ${focusDuration.inSeconds}s');
    print('   breakDuration: ${breakDuration.inSeconds}s');
    
    _service.invoke('start_timer', {
      'title': title,
      'category': category,
      'focusDurationSeconds': focusDuration.inSeconds,
      'breakDurationSeconds': breakDuration.inSeconds,
    });
    
    print('✅ Command sent!');
  }

  static void pauseTimer() {
    print('📤 Sending pause command');
    _service.invoke('pause');
  }

  static void resumeTimer() {
    print('📤 Sending resume command');
    _service.invoke('resume');
  }

  static Future<void> stopTimer() async {
    print('📤 Sending stop command');
    _service.invoke('stop');
    
    // Clear saved state
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('timer_state');
  }

  static void handleBreakAction(String action) {
    print('📤 Sending break_action: $action');
    _service.invoke('break_action', {'action': action});
  }

  static Future<bool> isServiceRunning() async {
    return await _service.isRunning();
  }

  static void dispose() {
    print('🧹 Disposing service manager listeners');
    _timerUpdateSub?.cancel();
    _phaseChangedSub?.cancel();
    _serviceReadySub?.cancel();
    _isListening = false;
  }
}