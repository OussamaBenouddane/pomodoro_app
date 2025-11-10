import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/model/session_timer_model.dart';

class SessionTimerNotifier extends Notifier<SessionTimerState> {
  Timer? _timer;

  @override
  SessionTimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const SessionTimerState();
  }

  void initializeTimer({
    required String title,
    required String category,
    required int focusMinutes,
    required int breakMinutes,
  }) {
    _timer?.cancel();
    state = SessionTimerState(
      phase: SessionPhase.idle,
      title: title,
      category: category,
      focusDuration: Duration(minutes: focusMinutes),
      breakDuration: Duration(minutes: breakMinutes),
      remaining: Duration(minutes: focusMinutes),
    );
  }

  void startFocus({
    required String title,
    required String category,
    required Duration focusDuration,
    required Duration breakDuration,
  }) {
    _timer?.cancel();
    final now = DateTime.now();
    state = SessionTimerState(
      phase: SessionPhase.focusing,
      title: title,
      category: category,
      focusDuration: focusDuration,
      breakDuration: breakDuration,
      remaining: focusDuration,
      sessionStartedAt: now,
      totalPausedDuration: Duration.zero,
    );
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isPaused) {
        return; // Don't tick while paused
      }

      if (state.remaining > Duration.zero) {
        state = state.copyWith(
          remaining: state.remaining - const Duration(seconds: 1),
        );
      } else {
        // Timer reached zero
        _timer?.cancel();
        
        if (state.phase == SessionPhase.focusing) {
          // Focus done → automatically start break
          _transitionToBreak();
        } else if (state.phase == SessionPhase.onBreak) {
          // Break done → session finished
          state = state.copyWith(phase: SessionPhase.finished);
        }
      }
    });
  }

  void _transitionToBreak() {
    _timer?.cancel();
    state = state.copyWith(
      phase: SessionPhase.onBreak,
      remaining: state.breakDuration,
      isPaused: false, // Ensure break starts unpaused
    );
    _startTicker();
  }

  void startBreak() {
    // This method can be kept for manual break start if needed
    _transitionToBreak();
  }

  void pause() {
    if (state.phase != SessionPhase.focusing &&
        state.phase != SessionPhase.onBreak) {
      return;
    }

    if (state.isPaused) {
      return; // Already paused
    }

    final now = DateTime.now();
    state = state.copyWith(
      isPaused: true,
      lastPausedAt: now,
    );
    // Note: We keep the timer running but it checks isPaused in _startTicker
  }

  void resume() {
    if (!state.isPaused || state.lastPausedAt == null) return;

    final pauseDuration = DateTime.now().difference(state.lastPausedAt!);
    state = state.copyWith(
      isPaused: false,
      totalPausedDuration: state.totalPausedDuration + pauseDuration,
      lastPausedAt: null,
    );
    // Timer is still running, it will resume ticking automatically
  }

  void stopSession() {
    _timer?.cancel();
    state = const SessionTimerState(phase: SessionPhase.idle);
  }

  /// Get the actual time spent focusing (excluding pauses)
  Duration getActualFocusTime() {
    if (state.sessionStartedAt == null) return Duration.zero;

    final elapsed = DateTime.now().difference(state.sessionStartedAt!);
    var totalPaused = state.totalPausedDuration;

    // If currently paused, add current pause duration
    if (state.isPaused && state.lastPausedAt != null) {
      totalPaused += DateTime.now().difference(state.lastPausedAt!);
    }

    return elapsed - totalPaused;
  }
}

final sessionTimerProvider =
    NotifierProvider<SessionTimerNotifier, SessionTimerState>(
      SessionTimerNotifier.new,
    );