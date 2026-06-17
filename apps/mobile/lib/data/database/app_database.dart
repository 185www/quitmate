import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'quitmate.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            target_type TEXT NOT NULL,
            quit_date TEXT,
            stage INTEGER DEFAULT 0,
            preferences_encrypted TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE daily_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES user_profile(id),
            date TEXT NOT NULL,
            urge_level INTEGER,
            triggers TEXT,
            coping TEXT,
            relapsed INTEGER DEFAULT 0,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE badge (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            icon_asset TEXT NOT NULL,
            earned_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE relapse_plan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES user_profile(id),
            situation TEXT NOT NULL,
            trigger TEXT,
            coping_plan TEXT NOT NULL,
            priority INTEGER DEFAULT 0,
            is_template INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE notification_schedule (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            notification_id TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            type INTEGER NOT NULL,
            payload TEXT,
            scheduled_at TEXT,
            cron_expr TEXT,
            enabled INTEGER DEFAULT 1
          )
        ''');

        await _seedBadges(db);
      },
    );
  }

  Future<void> _seedBadges(Database db) async {
    final badges = [
      {'code': 'day_1', 'name': '第一天', 'description': '成功坚持1天', 'icon_asset': 'assets/brand/badges/day1.svg'},
      {'code': 'day_7', 'name': '一周达人', 'description': '成功坚持7天', 'icon_asset': 'assets/brand/badges/day7.svg'},
      {'code': 'day_30', 'name': '月度冠军', 'description': '成功坚持30天', 'icon_asset': 'assets/brand/badges/day30.svg'},
      {'code': 'day_90', 'name': '季度英雄', 'description': '成功坚持90天', 'icon_asset': 'assets/brand/badges/day90.svg'},
      {'code': 'day_365', 'name': '年度传奇', 'description': '成功坚持一年', 'icon_asset': 'assets/brand/badges/day365.svg'},
    ];
    for (final b in badges) {
      await db.insert('badge', b);
    }
  }

  Future<Map<String, dynamic>?> getFirstUserProfile() async {
    final db = await database;
    final results = await db.query('user_profile', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> createUserProfile(Map<String, dynamic> profile) async {
    final db = await database;
    return db.insert('user_profile', profile);
  }

  Future<int> updateUserProfile(int id, Map<String, dynamic> values) async {
    final db = await database;
    return db.update('user_profile', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertDailyLog(Map<String, dynamic> log) async {
    final db = await database;
    return db.insert('daily_log', log);
  }

  Future<List<Map<String, dynamic>>> getDailyLogsForUser(int userId, {int limit = 30}) async {
    final db = await database;
    return db.query('daily_log', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getDailyLogsByDateRange(int userId, String start, String end) async {
    final db = await database;
    return db.query('daily_log', where: 'user_id = ? AND date >= ? AND date <= ?', whereArgs: [userId, start, end], orderBy: 'date DESC');
  }

  Future<Map<String, dynamic>?> getTodayLog(int userId) async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();
    final results = await db.query('daily_log', where: 'user_id = ? AND date >= ? AND date <= ?', whereArgs: [userId, startOfDay, endOfDay], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllBadges() async {
    final db = await database;
    return db.query('badge');
  }

  Future<List<Map<String, dynamic>>> getEarnedBadges() async {
    final db = await database;
    return db.query('badge', where: 'earned_at IS NOT NULL');
  }

  Future<int> earnBadge(String code) async {
    final db = await database;
    return db.update('badge', {'earned_at': DateTime.now().toIso8601String()}, where: 'code = ?', whereArgs: [code]);
  }

  Future<int> insertRelapsePlan(Map<String, dynamic> plan) async {
    final db = await database;
    return db.insert('relapse_plan', plan);
  }

  Future<List<Map<String, dynamic>>> getRelapsePlansForUser(int userId) async {
    final db = await database;
    return db.query('relapse_plan', where: 'user_id = ?', whereArgs: [userId], orderBy: 'priority DESC');
  }

  Future<List<Map<String, dynamic>>> getTemplatePlans() async {
    final db = await database;
    return db.query('relapse_plan', where: 'is_template = 1');
  }

  Future<int> deleteRelapsePlan(int id) async {
    final db = await database;
    return db.delete('relapse_plan', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertNotificationSchedule(Map<String, dynamic> schedule) async {
    final db = await database;
    return db.insert('notification_schedule', schedule);
  }

  Future<List<Map<String, dynamic>>> getEnabledNotifications() async {
    final db = await database;
    return db.query('notification_schedule', where: 'enabled = 1');
  }

  Future<int> toggleNotification(String notificationId, bool enabled) async {
    final db = await database;
    return db.update('notification_schedule', {'enabled': enabled ? 1 : 0}, where: 'notification_id = ?', whereArgs: [notificationId]);
  }
}