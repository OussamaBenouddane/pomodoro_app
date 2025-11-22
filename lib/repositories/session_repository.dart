import 'package:lockin_app/db/db.dart';
import 'package:lockin_app/model/session_model.dart';

class SessionRepository {
  final DBHelper dbHelper;
  SessionRepository(this.dbHelper);

  /// Insert a new session
  Future<int> insertSession(SessionModel session) async {
    return await dbHelper.insertData('sessions', session.toMap());
  }

  /// Get all sessions for a user
  Future<List<SessionModel>> getSessionsByUser(int userId) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT * FROM sessions WHERE user_id = ? ORDER BY date DESC',
      [userId],
    );
    return result.map((e) => SessionModel.fromMap(e)).toList();
  }

  /// Get sessions for a specific day
  Future<List<SessionModel>> getSessionsByDate(int userId, String date) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT * FROM sessions WHERE user_id = ? AND date = ? ORDER BY start_time ASC',
      [userId, date],
    );
    return result.map((e) => SessionModel.fromMap(e)).toList();
  }

  /// Get sessions for a specific week
  Future<List<SessionModel>> getSessionsBetweenDates(
    int userId,
    String start,
    String end,
  ) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT * FROM sessions WHERE user_id = ? AND date BETWEEN ? AND ? ORDER BY date ASC',
      [userId, start, end],
    );
    return result.map((e) => SessionModel.fromMap(e)).toList();
  }

  /// Delete a session
  Future<int> deleteSession(int sessionId) async {
    return await dbHelper.deleteData(
      'sessions',
      'session_id = ?',
      [sessionId],
    );
  }

  /// Update a session (useful if you edit duration or mark synced)
  Future<int> updateSession(SessionModel session) async {
    return await dbHelper.updateData(
      'sessions',
      session.toMap(),
      'session_id = ?',
      [session.sessionId],
    );
  }

  /// Get total focused minutes for a given date
  Future<int> getTotalFocusByDate(int userId, String date) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT SUM(focus_minutes) AS total FROM sessions WHERE user_id = ? AND date = ?',
      [userId, date],
    );
    return (result.first['total'] ?? 0) as int;
  }

  /// Get current streak (consecutive days with at least one session)
  Future<int> getCurrentStreak(int userId) async {
    final result = await dbHelper.readDataWithArgs(
      'SELECT DISTINCT date FROM sessions WHERE user_id = ? ORDER BY date DESC',
      [userId],
    );

    if (result.isEmpty) return 0;

    int streak = 1;
    DateTime lastDate = DateTime.parse(result.first['date']);

    for (int i = 1; i < result.length; i++) {
      final currentDate = DateTime.parse(result[i]['date']);
      final difference = lastDate.difference(currentDate).inDays;
      if (difference == 1) {
        streak++;
        lastDate = currentDate;
      } else {
        break;
      }
    }
    return streak;
  }
}
