import '../entity/daily_log.dart';

abstract class LogRepository {
  Future<DailyLogEntry?> getTodayLog(int userId);
  Future<List<DailyLogEntry>> getLogsForUser(int userId, {int limit});
  Future<List<DailyLogEntry>> getLogsByDateRange(int userId, DateTime start, DateTime end);
  Future<int> insertLog(DailyLogEntry log);
  Future<bool> updateLog(DailyLogEntry log);
  Future<int> getStreakDays(int userId);
  Future<int> getTotalLogsCount(int userId);
}