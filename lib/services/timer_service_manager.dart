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
  static StreamSubscription? _sessionCompletedSub;

  static void initialize(WidgetRef ref) {
    _ref = ref;

    if (!_isListening) {
      _isListening = true;

      _timerUpdateSub?.cancel();
      _phaseChangedSub?.cancel();
      _serviceReadySub?.cancel();
      _sessionCompletedSub?.cancel();

      _serviceReadySub = _service.on('service_ready').listen((event) {
        if (_serviceReadyCompleter != null &&
            !_serviceReadyCompleter!.isCompleted) {
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

      _sessionCompletedSub = _service.on('session_completed').listen((event) {
        if (event != null) {
          _handleSessionCompleted(event);
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

      if (phase == 'focusing' || phase == 'onBreak' || phase == 'finished') {
        final remainingSeconds = state['remainingSeconds'] as int;
        final title = state['title'] as String;
        final category = state['category'] as String? ?? 'General';
        final isPaused = state['isPaused'] as bool;
        final focusDurationSeconds = state['focusDurationSeconds'] as int;
        final breakDurationSeconds = state['breakDurationSeconds'] as int;
        final sessionStartTimestamp = state['sessionStartTimestamp'] as int?;
        final totalPausedSeconds = state['totalPausedSeconds'] as int? ?? 0;
        final lastPausedTimestamp = state['lastPausedTimestamp'] as int?;
        final focusEndTimestamp = state['focusEndTimestamp'] as int?;
        final actualFocusMinutes = state['actualFocusMinutes'] as int?;

        SessionPhase sessionPhase;
        if (phase == 'focusing') {
          sessionPhase = SessionPhase.focusing;
        } else if (phase == 'onBreak') {
          sessionPhase = SessionPhase.onBreak;
        } else {
          sessionPhase = SessionPhase.finished;
        }

        final timerState = SessionTimerState(
          phase: sessionPhase,
          title: title,
          category: category,
          focusDuration: Duration(seconds: focusDurationSeconds),
          breakDuration: Duration(seconds: breakDurationSeconds),
          remaining: Duration(seconds: remainingSeconds),
          isPaused: isPaused,
          sessionStartedAt: sessionStartTimestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(sessionStartTimestamp)
              : null,
          totalPausedDuration: Duration(seconds: totalPausedSeconds),
          lastPausedAt: lastPausedTimestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(lastPausedTimestamp)
              : null,
          focusEndedAt: focusEndTimestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(focusEndTimestamp)
              : null,
          actualFocusMinutes: actualFocusMinutes,
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
    final sessionStartTimestamp = data['sessionStartTimestamp'] as int?;
    final totalPausedSeconds = data['totalPausedSeconds'] as int? ?? 0;
    final lastPausedTimestamp = data['lastPausedTimestamp'] as int?;

    final currentState = _ref!.read(sessionTimerProvider);

    SessionPhase sessionPhase;
    if (phase == 'focusing') {
      sessionPhase = SessionPhase.focusing;
    } else if (phase == 'onBreak') {
      sessionPhase = SessionPhase.onBreak;
    } else if (phase == 'finished') {
      sessionPhase = SessionPhase.finished;
    } else {
      sessionPhase = SessionPhase.idle;
    }

    final notifier = _ref!.read(sessionTimerProvider.notifier);
    notifier.updateStateFromService(
      currentState.copyWith(
        phase: sessionPhase,
        remaining: Duration(seconds: remainingSeconds),
        isPaused: isPaused,
        title: title,
        category: category,
        sessionStartedAt: sessionStartTimestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(sessionStartTimestamp)
            : currentState.sessionStartedAt,
        totalPausedDuration: Duration(seconds: totalPausedSeconds),
        lastPausedAt: lastPausedTimestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(lastPausedTimestamp)
            : null,
      ),
    );
  }

  static void _handlePhaseChange(Map<String, dynamic> data) {
    if (_ref == null) return;

    final phase = data['phase'] as String;
    final remainingSeconds = data['remainingSeconds'] as int? ?? 0;
    final focusEndTimestamp = data['focusEndTimestamp'] as int?;
    final actualFocusMinutes = data['actualFocusMinutes'] as int?;

    final currentState = _ref!.read(sessionTimerProvider);
    final notifier = _ref!.read(sessionTimerProvider.notifier);

    if (phase == 'onBreak') {
      // Focus phase completed, preserve focus data
      notifier.updateStateFromService(
        currentState.copyWith(
          phase: SessionPhase.onBreak,
          remaining: Duration(seconds: remainingSeconds),
          isPaused: false,
          focusEndedAt: focusEndTimestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(focusEndTimestamp)
              : null,
          actualFocusMinutes: actualFocusMinutes,
        ),
      );
    } else if (phase == 'finished') {
      // Session finished (either break completed or skipped)
      notifier.updateStateFromService(
        currentState.copyWith(
          phase: SessionPhase.finished,
          remaining: Duration.zero,
          isPaused: false,
          focusEndedAt: focusEndTimestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(focusEndTimestamp)
              : currentState.focusEndedAt,
          actualFocusMinutes:
              actualFocusMinutes ?? currentState.actualFocusMinutes,
        ),
      );
    } else if (phase == 'focusing') {
      notifier.updateStateFromService(
        currentState.copyWith(
          phase: SessionPhase.focusing,
          remaining: Duration(seconds: remainingSeconds),
          isPaused: false,
        ),
      );
    }
  }

  static void _handleSessionCompleted(Map<String, dynamic> data) {
    if (_ref == null) return;

    final focusEndTimestamp = data['focusEndTimestamp'] as int?;
    final actualFocusMinutes = data['actualFocusMinutes'] as int?;

    final currentState = _ref!.read(sessionTimerProvider);
    final notifier = _ref!.read(sessionTimerProvider.notifier);

    notifier.updateStateFromService(
      currentState.copyWith(
        phase: SessionPhase.finished,
        focusEndedAt: focusEndTimestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(focusEndTimestamp)
            : null,
        actualFocusMinutes: actualFocusMinutes,
      ),
    );
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
        );
      } catch (e) {
        // Ignore
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

  static void skipBreak() {
    _service.invoke('skip_break');
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
    _sessionCompletedSub?.cancel();
    _isListening = false;
  }
}
