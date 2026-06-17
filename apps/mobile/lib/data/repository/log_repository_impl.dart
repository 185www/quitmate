import 'dart:convert';
import '../../domain/entity/daily_log.dart';
import '../../domain/repository/log_repository.dart';
import '../database/app_database.dart';

class LogRepositoryImpl implements LogRepository {
  final AppDatabase _database;

  LogRepositoryImpl(this._database);

  @override
  Future<DailyLogEntry?> getTodayLog(int userId) async {
    final log = await _database.getTodayLog(userId);
    if (log == null) return null;

    return DailyLogEntry(
      id: log.id,
      userId: log.userId,
      date: log.date,
      urgeLevel: log.urgeLevel,
      triggers: log.triggers != null
          ? List<String>.from(jsonDecode(log.triggers!))
          : null,
      coping: log.coping,
      relapsed: log.relapsed,
      notes: log.notes,
    );
  }

  @override
  Future<List<DailyLogEntry>> getLogsForUser(int userId, {int limit = 30}) async {
    final logs = await _database.getDailyLogsForUser(userId, limit: limit);
    return logs
        .map((log) => DailyLogEntry(
              id: log.id,
              userId: log.userId,
              date: log.date,
              urgeLevel: log.urgeLevel,
              triggers: log.triggers != null
                  ? List<String>.from(jsonDecode(log.triggers!))
                  : null,
              coping: log.coping,
              relapsed: log.relapsed,
              notes: log.notes,
            ))
        .toList();
  }

  @override
  Future<List<DailyLogEntry>> getLogsByDateRange(
      int userId, DateTime start, DateTime end) async {
    final logs = await _database.getDailyLogsByDateRange(userId, start, end);
    return logs
        .map((log) => DailyLogEntry(
              id: log.id,
              userId: log.userId,
              date: log.date,
              urgeLevel: log.urgeLevel,
              triggers: log.triggers != null
                  ? List<String>.from(jsonDecode(log.triggers!))
                  : null,
              coping: log.coping,
              relapsed: log.relapsed,
              notes: log.notes,
            ))
        .toList();
  }

  @override
  Future<int> insertLog(DailyLogEntry log) async {
    return await _database.insertDailyLog(
      DailyLogCompanion.insert(
        userId: log.userId,
        date: log.date,
        urgeLevel: log.urgeLevel != null ? Value(log.urgeLevel!) : const Value.absent(),
        triggers: log.triggers != null
            ? Value(jsonEncode(log.triggers))
            : const Value.absent(),
        coping: log.coping != null ? Value(log.coping!) : const Value.absent(),
        relapsed: Value(log.relapsed),
        notes: log.notes != null ? Value(log.notes!) : const Value.absent(),
      ),
    );
  }

  @override
  Future<bool> updateLog(DailyLogEntry log) async {
    if (log.id == null) return false;
    await _database.updateUserProfile(
      UserProfileCompanion(
        id: Value(log.id!),
      ),
    );
    return true;
  }

  @override
  Future<int> getStreakDays(int userId) async {
    final logs = await getLogsForUser(userId, limit: 365);
    if (logs.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final log in logs) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      final expected = DateTime(checkDate.year, checkDate.month, checkDate.day);

      if (logDate.isAtSameMomentAs(expected)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (logDate.isBefore(expected)) {
        break;
      }
    }

    return streak;
  }

  @override
  Future<int> getTotalLogsCount(int userId) async {
    final logs = await getLogsForUser(userId, limit: 999999);
    return logs.length;
  }
}