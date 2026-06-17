import '../entity/badge.dart';
import '../repository/badge_repository.dart';
import '../repository/log_repository.dart';

class BadgeUseCase {
  final BadgeRepository _badgeRepository;
  final LogRepository _logRepository;

  BadgeUseCase(this._badgeRepository, this._logRepository);

  Future<List<AppBadge>> getAllBadges() async {
    return _badgeRepository.getAllBadges();
  }

  Future<List<AppBadge>> getEarnedBadges() async {
    return _badgeRepository.getEarnedBadges();
  }

  Future<int> getEarnedCount() async {
    return _badgeRepository.getEarnedCount();
  }

  Future<void> evaluateBadges(int userId) async {
    final streak = await _logRepository.getStreakDays(userId);
    final totalLogs = await _logRepository.getTotalLogsCount(userId);

    final badgeRules = <String, bool Function()>{
      'day_1': () => streak >= 1,
      'day_7': () => streak >= 7,
      'day_30': () => streak >= 30,
      'day_90': () => streak >= 90,
      'day_365': () => streak >= 365,
      'log_7': () => totalLogs >= 7,
      'log_30': () => totalLogs >= 30,
    };

    for (final entry in badgeRules.entries) {
      if (entry.value()) {
        await _badgeRepository.earnBadge(entry.key);
      }
    }
  }
}