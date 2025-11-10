class DayStatModel {
  final int? id;
  final int userId;
  final String date;
  final int totalFocusMinutes;
  final int lastUpdated;
  final int synced;

  DayStatModel({
    this.id,
    required this.userId,
    required this.date,
    required this.totalFocusMinutes,
    required this.lastUpdated,
    this.synced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'total_focus_minutes': totalFocusMinutes,
      'last_updated': lastUpdated,
      'synced': synced,
    };
  }

  factory DayStatModel.fromMap(Map<String, dynamic> map) {
    return DayStatModel(
      id: map['id'],
      userId: map['user_id'],
      date: map['date'],
      totalFocusMinutes: map['total_focus_minutes'],
      lastUpdated: map['last_updated'],
      synced: map['synced'],
    );
  }
}
