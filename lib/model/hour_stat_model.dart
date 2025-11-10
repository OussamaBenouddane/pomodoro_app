class HourStatModel {
  final int? id;
  final int userId;
  final String date;
  final int hour; // 0–23
  final int focusMinutes;
  final int lastUpdated;
  final int synced;

  HourStatModel({
    this.id,
    required this.userId,
    required this.date,
    required this.hour,
    required this.focusMinutes,
    required this.lastUpdated,
    this.synced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'hour': hour,
      'focus_minutes': focusMinutes,
      'last_updated': lastUpdated,
      'synced': synced,
    };
  }

  factory HourStatModel.fromMap(Map<String, dynamic> map) {
    return HourStatModel(
      id: map['id'],
      userId: map['user_id'],
      date: map['date'],
      hour: map['hour'],
      focusMinutes: map['focus_minutes'],
      lastUpdated: map['last_updated'],
      synced: map['synced'],
    );
  }
}
