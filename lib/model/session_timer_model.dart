enum SessionPhase { idle, focusing, onBreak, waitingForBreak, finished }

class SessionTimerState {
  final SessionPhase phase;
  final String? title;
  final String? category;
  final Duration focusDuration;
  final Duration breakDuration;
  final Duration remaining;
  final bool isPaused;
  
  // Time tracking fields
  final DateTime? sessionStartedAt;
  final DateTime? lastPausedAt;
  final Duration totalPausedDuration;
  
  // Focus completion tracking
  final DateTime? focusEndedAt;
  final int? actualFocusMinutes;

  const SessionTimerState({
    this.phase = SessionPhase.idle,
    this.title,
    this.category,
    this.focusDuration = const Duration(minutes: 25),
    this.breakDuration = const Duration(minutes: 5),
    this.remaining = Duration.zero,
    this.isPaused = false,
    this.sessionStartedAt,
    this.lastPausedAt,
    this.totalPausedDuration = Duration.zero,
    this.focusEndedAt,
    this.actualFocusMinutes,
  });

  SessionTimerState copyWith({
    SessionPhase? phase,
    String? title,
    String? category,
    Duration? focusDuration,
    Duration? breakDuration,
    Duration? remaining,
    bool? isPaused,
    DateTime? sessionStartedAt,
    DateTime? lastPausedAt,
    Duration? totalPausedDuration,
    DateTime? focusEndedAt,
    int? actualFocusMinutes,
  }) {
    return SessionTimerState(
      phase: phase ?? this.phase,
      title: title ?? this.title,
      category: category ?? this.category,
      focusDuration: focusDuration ?? this.focusDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      remaining: remaining ?? this.remaining,
      isPaused: isPaused ?? this.isPaused,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      lastPausedAt: lastPausedAt ?? this.lastPausedAt,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
      focusEndedAt: focusEndedAt ?? this.focusEndedAt,
      actualFocusMinutes: actualFocusMinutes ?? this.actualFocusMinutes,
    );
  }

  /// Get actual elapsed time (excluding pauses)
  Duration get actualElapsedTime {
    if (sessionStartedAt == null) return Duration.zero;
    
    final elapsed = DateTime.now().difference(sessionStartedAt!);
    var paused = totalPausedDuration;
    
    // Add current pause if paused
    if (isPaused && lastPausedAt != null) {
      paused += DateTime.now().difference(lastPausedAt!);
    }
    
    return elapsed - paused;
  }

  /// Get the focus time to display/save (ONLY focus phase, no break time)
  /// This should be used when navigating to finished page or saving sessions
  int get displayFocusMinutes {
    // Priority 1: Use actualFocusMinutes if set by background service
    if (actualFocusMinutes != null) {
      return actualFocusMinutes!;
    }
    
    // Priority 2: Calculate from actual elapsed time (for running sessions)
    // Only count time if we're in focusing phase or have completed focus
    if (phase == SessionPhase.focusing || focusEndedAt != null) {
      return actualElapsedTime.inMinutes;
    }
    
    // Priority 3: Fallback to 0 if no focus has occurred
    return 0;
  }

  /// Check if timer is active (focusing or on break, not paused)
  bool get isActive => 
      (phase == SessionPhase.focusing || phase == SessionPhase.onBreak) && 
      !isPaused;

  /// Format remaining time as MM:SS
  String get formattedRemaining {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}