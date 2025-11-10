class SessionModel {
  final int? sessionId;
  final int userId;
  final String title;
  final String category;
  final int focusMinutes;
  final String date;
  final String startTime;
  final String endTime;
  final int lastUpdated;
  final int synced;

  SessionModel({
    this.sessionId,
    required this.userId,
    required this.title,
    required this.category,
    required this.focusMinutes,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.lastUpdated,
    this.synced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'title': title,
      'category': category,
      'focus_minutes': focusMinutes,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'last_updated': lastUpdated,
      'synced': synced,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['session_id'],
      userId: map['user_id'],
      title: map['title'],
      category: map['category'],
      focusMinutes: map['focus_minutes'],
      date: map['date'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      lastUpdated: map['last_updated'],
      synced: map['synced'],
    );
  }
}
