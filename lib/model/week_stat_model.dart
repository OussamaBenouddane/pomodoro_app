class WeekStatModel {
  final int? id;
  final int userId;
  final String weekStart;
  final String weekEnd;
  final int totalFocusMinutes;
  final double averageSessionLength;
  final int sessionsCount;
  final int lastUpdated;
  final int synced;

  WeekStatModel({
    this.id,
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.totalFocusMinutes,
    required this.averageSessionLength,
    required this.sessionsCount,
    required this.lastUpdated,
    this.synced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'week_start': weekStart,
      'week_end': weekEnd,
      'total_focus_minutes': totalFocusMinutes,
      'average_session_length': averageSessionLength,
      'sessions_count': sessionsCount,
      'last_updated': lastUpdated,
      'synced': synced,
    };
  }

  factory WeekStatModel.fromMap(Map<String, dynamic> map) {
    return WeekStatModel(
      id: map['id'],
      userId: map['user_id'],
      weekStart: map['week_start'],
      weekEnd: map['week_end'],
      totalFocusMinutes: map['total_focus_minutes'],
      averageSessionLength: map['average_session_length'],
      sessionsCount: map['sessions_count'],
      lastUpdated: map['last_updated'],
      synced: map['synced'],
    );
  }
}
