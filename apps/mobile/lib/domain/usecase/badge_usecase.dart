import '../entity/badge.dart';
import '../../data/repository/badge_repository_impl.dart';
import '../../data/repository/log_repository_impl.dart';

class BadgeUseCase {
  final BadgeRepository _badgeRepository;
  final LogRepository _logRepository;
  BadgeUseCase(this._badgeRepository, this._logRepository);

  Future<List<AppBadge>> getAllBadges() => _badgeRepository.getAllBadges();
  Future<List<AppBadge>> getEarnedBadges() => _badgeRepository.getEarnedBadges();
  Future<int> getEarnedCount() => _badgeRepository.getEarnedCount();

  Future<void> evaluateBadges(int userId) async {
    final streak = await _logRepository.getStreakDays(userId);
    if (streak >= 1) await _badgeRepository.earnBadge('day_1');
    if (streak >= 7) await _badgeRepository.earnBadge('day_7');
    if (streak >= 30) await _badgeRepository.earnBadge('day_30');
    if (streak >= 90) await _badgeRepository.earnBadge('day_90');
    if (streak >= 365) await _badgeRepository.earnBadge('day_365');
  }
}