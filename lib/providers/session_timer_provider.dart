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
    print('🔧 Initializing timer: $title');
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
    print('🎯 [Provider] Starting focus session: $title');
    print('   Focus: ${focusDuration.inMinutes}min, Break: ${breakDuration.inMinutes}min');
    
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

    print('✅ [Provider] State updated to focusing');
    print('   Remaining: ${state.remaining.inSeconds}s');

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

    print('⏸️ [Provider] Pausing timer');
    final now = DateTime.now();
    state = state.copyWith(
      isPaused: true,
      lastPausedAt: now,
    );

    // Notify background service
    TimerServiceManager.pauseTimer();
  }

  void resume() {
    if (!state.isPaused || state.lastPausedAt == null) return;

    print('▶️ [Provider] Resuming timer');
    final pauseDuration = DateTime.now().difference(state.lastPausedAt!);
    state = state.copyWith(
      isPaused: false,
      totalPausedDuration: state.totalPausedDuration + pauseDuration,
      lastPausedAt: null,
    );

    // Notify background service
    TimerServiceManager.resumeTimer();
  }

  void stopSession() {
    print('⏹️ [Provider] Stopping session');
    state = const SessionTimerState(phase: SessionPhase.idle);
    
    // Stop background service
    TimerServiceManager.stopTimer();
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
    // Only log significant changes to avoid spam
    if (state.remaining.inSeconds != newState.remaining.inSeconds) {
      if (newState.remaining.inSeconds % 10 == 0) {
        print('🔄 [Provider] Syncing from service: ${newState.remaining.inSeconds}s remaining');
      }
    }
    state = newState;
  }
}

final sessionTimerProvider =
    NotifierProvider<SessionTimerNotifier, SessionTimerState>(
      SessionTimerNotifier.new,
    );