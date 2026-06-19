import 'dart:convert';
import '../../domain/entity/daily_log.dart';
import '../database/app_database.dart';

class LogRepository {
  final AppDatabase _database;
  LogRepository(this._database);

  Future<DailyLogEntry?> getTodayLog(int userId) async {
    final log = await _database.getTodayLog(userId);
    if (log == null) return null;
    return _mapToEntry(log);
  }

  Future<List<DailyLogEntry>> getLogsForUser(int userId, {int limit = 30}) async {
    final logs = await _database.getDailyLogsForUser(userId, limit: limit);
    return logs.map((l) => _mapToEntry(l)).toList();
  }

  Future<int> insertLog(DailyLogEntry log) async {
    return _database.insertDailyLog({
      'user_id': log.userId,
      'date': log.date.toIso8601String(),
      'mood': log.mood,
      'urge_level': log.urgeLevel,
      'triggers': log.triggers != null ? jsonEncode(log.triggers) : null,
      'coping': log.coping,
      'relapsed': log.relapsed ? 1 : 0,
      'consumption': log.consumption,
      'notes': log.notes,
    });
  }

  Future<int> getStreakDays(int userId) async {
    final logs = await getLogsForUser(userId, limit: 365);
    if (logs.isEmpty) return 0;
    int streak = 0;
    DateTime checkDate = DateTime.now();
    for (final log in logs) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      final expected = DateTime(checkDate.year, checkDate.month, checkDate.day);
      if (logDate.isAtSameMomentAs(expected)) { streak++; checkDate = checkDate.subtract(const Duration(days: 1)); }
      else if (logDate.isBefore(expected)) break;
    }
    return streak;
  }

  /// Get the most common triggers for a user
  Future<List<String>> getCommonTriggers(int userId, {int limit = 5}) async {
    final logs = await getLogsForUser(userId, limit: 90);
    final triggerCount = <String, int>{};
    for (final log in logs) {
      if (log.triggers != null) {
        for (final t in log.triggers!) {
          triggerCount[t] = (triggerCount[t] ?? 0) + 1;
        }
      }
    }
    final sorted = triggerCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  DailyLogEntry _mapToEntry(Map<String, dynamic> log) => DailyLogEntry(
    id: log['id'] as int,
    userId: log['user_id'] as int,
    date: DateTime.parse(log['date'] as String),
    mood: log['mood'] as int? ?? 3,
    urgeLevel: log['urge_level'] as int?,
    triggers: log['triggers'] != null ? List<String>.from(jsonDecode(log['triggers'] as String)) : null,
    coping: log['coping'] as String?,
    relapsed: (log['relapsed'] as int?) == 1,
    consumption: log['consumption'] as int?,
    notes: log['notes'] as String?,
  );
}
