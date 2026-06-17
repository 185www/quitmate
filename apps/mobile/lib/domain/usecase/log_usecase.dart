import '../entity/daily_log.dart';
import '../entity/user.dart';
import '../../data/repository/log_repository_impl.dart';
import '../../data/repository/badge_repository_impl.dart';
import '../../data/repository/user_repository_impl.dart';

class LogUseCase {
  final LogRepository _logRepository;
  final BadgeRepository _badgeRepository;
  final UserRepository _userRepository;

  LogUseCase(this._logRepository, this._badgeRepository, this._userRepository);

  Future<DailyLogEntry?> getTodayLog() async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return null;
    return _logRepository.getTodayLog(user.id);
  }

  Future<List<DailyLogEntry>> getRecentLogs({int limit = 7}) async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return [];
    return _logRepository.getLogsForUser(user.id, limit: limit);
  }

  Future<DailyLogEntry> logToday({int? urgeLevel, List<String>? triggers, String? coping, bool relapsed = false, String? notes}) async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) throw StateError('No user found');
    final log = DailyLogEntry(userId: user.id, date: DateTime.now(), urgeLevel: urgeLevel, triggers: triggers, coping: coping, relapsed: relapsed, notes: notes);
    final id = await _logRepository.insertLog(log);
    await _checkAndAwardBadges(user);
    return log.copyWith(id: id);
  }

  Future<void> _checkAndAwardBadges(User user) async {
    final streak = await _logRepository.getStreakDays(user.id);
    if (streak >= 1) await _badgeRepository.earnBadge('day_1');
    if (streak >= 7) await _badgeRepository.earnBadge('day_7');
    if (streak >= 30) await _badgeRepository.earnBadge('day_30');
    if (streak >= 90) await _badgeRepository.earnBadge('day_90');
    if (streak >= 365) await _badgeRepository.earnBadge('day_365');
  }

  Future<int> getStreakDays() async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return 0;
    return _logRepository.getStreakDays(user.id);
  }
}