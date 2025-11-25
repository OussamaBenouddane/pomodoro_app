import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  /// Singleton getter
  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  /// Initialize database
  Future<Database> initDB() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'lockin.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        username TEXT,
        password TEXT,
        goal_minutes INTEGER DEFAULT 120,
        date_created TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        session_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT,
        category TEXT,
        focus_minutes INTEGER,
        date TEXT,
        start_time TEXT,
        end_time TEXT,
        last_updated INTEGER,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE hour_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        date TEXT,
        hour INTEGER,
        focus_minutes INTEGER,
        last_updated INTEGER,
        synced INTEGER DEFAULT 0,
        UNIQUE(user_id, date, hour),
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE day_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        date TEXT,
        total_focus_minutes INTEGER,
        last_updated INTEGER,
        synced INTEGER DEFAULT 0,
        UNIQUE(user_id, date),
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE week_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        week_start TEXT,
        week_end TEXT,
        total_focus_minutes INTEGER,
        average_session_length REAL,
        sessions_count INTEGER,
        last_updated INTEGER,
        synced INTEGER DEFAULT 0,
        UNIQUE(user_id, week_start),
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    print('✅ Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add unique constraints to stats tables
      // Note: SQLite doesn't support ADD CONSTRAINT, so we need to recreate tables

      // Backup data
      await db.execute(
        'CREATE TABLE hour_stats_backup AS SELECT * FROM hour_stats',
      );
      await db.execute(
        'CREATE TABLE day_stats_backup AS SELECT * FROM day_stats',
      );
      await db.execute(
        'CREATE TABLE week_stats_backup AS SELECT * FROM week_stats',
      );

      // Drop old tables
      await db.execute('DROP TABLE hour_stats');
      await db.execute('DROP TABLE day_stats');
      await db.execute('DROP TABLE week_stats');

      // Recreate with unique constraints
      await db.execute('''
        CREATE TABLE hour_stats (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          date TEXT,
          hour INTEGER,
          focus_minutes INTEGER,
          last_updated INTEGER,
          synced INTEGER DEFAULT 0,
          UNIQUE(user_id, date, hour),
          FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE day_stats (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          date TEXT,
          total_focus_minutes INTEGER,
          last_updated INTEGER,
          synced INTEGER DEFAULT 0,
          UNIQUE(user_id, date),
          FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE week_stats (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          week_start TEXT,
          week_end TEXT,
          total_focus_minutes INTEGER,
          average_session_length REAL,
          sessions_count INTEGER,
          last_updated INTEGER,
          synced INTEGER DEFAULT 0,
          UNIQUE(user_id, week_start),
          FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
        )
      ''');

      // Restore data (removing duplicates)
      await db.execute('''
        INSERT OR IGNORE INTO hour_stats 
        SELECT * FROM hour_stats_backup
      ''');

      await db.execute('''
        INSERT OR IGNORE INTO day_stats 
        SELECT * FROM day_stats_backup
      ''');

      await db.execute('''
        INSERT OR IGNORE INTO week_stats 
        SELECT * FROM week_stats_backup
      ''');

      // Drop backup tables
      await db.execute('DROP TABLE hour_stats_backup');
      await db.execute('DROP TABLE day_stats_backup');
      await db.execute('DROP TABLE week_stats_backup');
    }
  }

  /// Generic read query
  Future<List<Map<String, dynamic>>> readData(String sql) async {
    final myDb = await db;
    return await myDb.rawQuery(sql);
  }

  /// Insert helper
  Future<int> insertData(String table, Map<String, dynamic> data) async {
    final myDb = await db;
    return await myDb.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update helper
  Future<int> updateData(
    String table,
    Map<String, dynamic> data,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    final myDb = await db;
    return await myDb.update(
      table,
      data,
      where: whereClause,
      whereArgs: whereArgs,
    );
  }

  /// Delete helper
  Future<int> deleteData(
    String table,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    final myDb = await db;
    return await myDb.delete(table, where: whereClause, whereArgs: whereArgs);
  }

  /// Clear all session and stats data for a specific user
  Future<void> clearUserHistory(int userId) async {
    final myDb = await db;
    await myDb.transaction((txn) async {
      await txn.delete('sessions', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('hour_stats', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('day_stats', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('week_stats', where: 'user_id = ?', whereArgs: [userId]);
    });
    print('✅ Cleared all history for user $userId');
  }

  /// Delete entire DB (useful for testing or reset)
  Future<void> deleteDatabaseFile() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'lockin.db');
    await deleteDatabase(path);
    _db = null;
  }

  Future<List<Map<String, dynamic>>> readDataWithArgs(
    String sql,
    List<dynamic> args,
  ) async {
    final myDb = await db;
    return await myDb.rawQuery(sql, args);
  }
}
