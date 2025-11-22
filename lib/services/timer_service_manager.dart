// services/timer_service_manager.dart
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/model/session_timer_model.dart';
import 'package:lockin_app/providers/session_timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

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
      
      _timerUpdateSub?.cancel();
      _phaseChangedSub?.cancel();
      _serviceReadySub?.cancel();
      
      _serviceReadySub = _service.on('service_ready').listen((event) {
        if (_serviceReadyCompleter != null && !_serviceReadyCompleter!.isCompleted) {
          _serviceReadyCompleter!.complete();
        }
      });
      
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
    }

    _restoreStateIfNeeded();
  }

  static Future<void> _restoreStateIfNeeded() async {
    if (_ref == null) return;

    final isRunning = await _service.isRunning();
    if (!isRunning) return;

    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString('timer_state');
    
    if (stateJson != null) {
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
        
        final notifier = _ref!.read(sessionTimerProvider.notifier);
        notifier.updateStateFromService(timerState);
      }
    }
  }

  static void _syncFromService(Map<String, dynamic> data) {
    if (_ref == null) return;

    final remainingSeconds = data['remainingSeconds'] as int;
    final phase = data['phase'] as String;
    final isPaused = data['isPaused'] as bool;
    final title = data['title'] as String? ?? 'Focus Session';
    final category = data['category'] as String? ?? 'General';

    final currentState = _ref!.read(sessionTimerProvider);
    
    final sessionPhase = phase == 'focusing' 
        ? SessionPhase.focusing 
        : phase == 'onBreak' 
            ? SessionPhase.onBreak
            : SessionPhase.idle;

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
    final isRunning = await _service.isRunning();
    
    if (!isRunning) {
      _serviceReadyCompleter = Completer<void>();
      await _service.startService();
      
      try {
        await _serviceReadyCompleter!.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      } catch (e) {
        // Continue anyway
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    _service.invoke('start_timer', {
      'title': title,
      'category': category,
      'focusDurationSeconds': focusDuration.inSeconds,
      'breakDurationSeconds': breakDuration.inSeconds,
    });
  }

  static void pauseTimer() {
    _service.invoke('pause');
  }

  static void resumeTimer() {
    _service.invoke('resume');
  }

  static Future<void> stopTimer() async {
    _service.invoke('stop');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('timer_state');
  }

  static Future<bool> isServiceRunning() async {
    return await _service.isRunning();
  }

  static void dispose() {
    _timerUpdateSub?.cancel();
    _phaseChangedSub?.cancel();
    _serviceReadySub?.cancel();
    _isListening = false;
  }
}