// providers/session_timer_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockin_app/model/session_timer_model.dart';
import 'package:lockin_app/services/timer_service_manager.dart';

/// This provider now acts as a state holder that syncs with the background service
class SessionTimerNotifier extends Notifier<SessionTimerState> {
  @override
  SessionTimerState build() {
    return const SessionTimerState();
  }

  void initializeTimer({
    required String title,
    required String category,
    required int focusMinutes,
    required int breakMinutes,
  }) {
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

    // Start the background service
    TimerServiceManager.startTimer(
      title: title,
      category: category,
      focusDuration: focusDuration,
      breakDuration: breakDuration,
    );
  }

  void pause() {
    if (state.phase != SessionPhase.focusing &&
        state.phase != SessionPhase.onBreak) {
      return;
    }

    if (state.isPaused) {
      return;
    }

    final now = DateTime.now();
    state = state.copyWith(isPaused: true, lastPausedAt: now);

    // Notify background service
    TimerServiceManager.pauseTimer();
  }

  void resume() {
    if (!state.isPaused || state.lastPausedAt == null) return;

    final pauseDuration = DateTime.now().difference(state.lastPausedAt!);
    state = state.copyWith(
      isPaused: false,
      totalPausedDuration: state.totalPausedDuration + pauseDuration,
      lastPausedAt: null,
    );

    // Notify background service
    TimerServiceManager.resumeTimer();
  }

  void skipBreak() {
    if (state.phase != SessionPhase.onBreak) return;

    // Notify background service to skip break
    TimerServiceManager.skipBreak();
  }

  /// ✅ FIXED: Don't reset to idle immediately - wait for background service
  Future<void> stopSession() async {
    // ✅ First, request the background service to stop and get focus data
    await TimerServiceManager.stopTimer();

    // ✅ The service will send 'session_completed' event which will:
    // 1. Calculate actualFocusMinutes
    // 2. Update state to finished with the data
    // 3. Then we can safely reset to idle

    // Give the service a moment to send the completion event
    await Future.delayed(const Duration(milliseconds: 100));

    // ✅ Only reset to idle if we didn't receive a finished state
    // (This handles edge cases where service was already stopped)
    if (state.phase != SessionPhase.finished) {
      state = const SessionTimerState(phase: SessionPhase.idle);
    }
  }

  /// Get the actual time spent focusing (excluding pauses)
  Duration getActualFocusTime() {
    if (state.sessionStartedAt == null) return Duration.zero;

    final elapsed = DateTime.now().difference(state.sessionStartedAt!);
    var totalPaused = state.totalPausedDuration;

    if (state.isPaused && state.lastPausedAt != null) {
      totalPaused += DateTime.now().difference(state.lastPausedAt!);
    }

    return elapsed - totalPaused;
  }

  /// Allow direct state updates from background service
  void updateStateFromService(SessionTimerState newState) {
    state = newState;
  }

  /// ✅ NEW: Allow resetting to idle (called after navigation completes)
  void resetToIdle() {
    state = const SessionTimerState(phase: SessionPhase.idle);
  }
}

final sessionTimerProvider =
    NotifierProvider<SessionTimerNotifier, SessionTimerState>(
      SessionTimerNotifier.new,
    );
