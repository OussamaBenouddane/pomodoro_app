enum SessionPhase { idle, focusing, onBreak, waitingForBreak, finished }

class SessionTimerState {
  final SessionPhase phase;
  final String? title;
  final String? category;
  final Duration focusDuration;
  final Duration breakDuration;
  final Duration remaining;
  final bool isPaused;
  
  // New fields for accurate time tracking
  final DateTime? sessionStartedAt;
  final DateTime? lastPausedAt;
  final Duration totalPausedDuration;

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