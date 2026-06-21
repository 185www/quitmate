import '../../domain/entity/game_profile.dart';
import '../database/app_database.dart';

class GameRepository {
  final AppDatabase _db;
  GameRepository(this._db);

  Future<GameProfile?> getGameProfile(int userId) async {
    final db = await _db.database;
    final results = await db.query('game_profile',
        where: 'user_id = ?', whereArgs: [userId], limit: 1);
    if (results.isEmpty) return null;
    return _fromRow(results.first);
  }

  Future<void> createGameProfile(int userId) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('game_profile', {
      'user_id': userId,
      'level': 1,
      'xp': 0,
      'total_xp': 0,
      'streak_days': 0,
      'longest_streak': 0,
      'checkin_total': 0,
      'created_at': now,
      'updated_at': now,
      'cravings_resisted': 0,
      'exercises_completed': 0,
      'sos_used_count': 0,
    });
  }

  Future<void> updateGameProfile(GameProfile profile) async {
    final db = await _db.database;
    await db.update(
        'game_profile',
        {
          'level': profile.level,
          'xp': profile.xp,
          'total_xp': profile.totalXp,
          'streak_days': profile.streakDays,
          'longest_streak': profile.longestStreak,
          'checkin_total': profile.checkinTotal,
          'last_checkin_date': profile.lastCheckinDate?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'cravings_resisted': profile.cravingsResisted,
          'exercises_completed': profile.exercisesCompleted,
          'sos_used_count': profile.sosUsedCount,
        },
        where: 'id = ?',
        whereArgs: [profile.id]);
  }

  GameProfile _fromRow(Map<String, dynamic> row) {
    return GameProfile(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      level: row['level'] as int,
      xp: row['xp'] as int,
      totalXp: row['total_xp'] as int,
      streakDays: row['streak_days'] as int,
      longestStreak: row['longest_streak'] as int,
      checkinTotal: row['checkin_total'] as int,
      lastCheckinDate: row['last_checkin_date'] != null
          ? DateTime.parse(row['last_checkin_date'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      cravingsResisted: row['cravings_resisted'] as int? ?? 0,
      exercisesCompleted: row['exercises_completed'] as int? ?? 0,
      sosUsedCount: row['sos_used_count'] as int? ?? 0,
    );
  }
}
