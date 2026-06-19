import '../entity/badge.dart';
import '../../data/repository/badge_repository_impl.dart';

class BadgeUseCase {
  final BadgeRepository _badgeRepository;
  BadgeUseCase(this._badgeRepository);

  Future<List<AppBadge>> getAllBadges() => _badgeRepository.getAllBadges();
  Future<List<AppBadge>> getEarnedBadges() =>
      _badgeRepository.getEarnedBadges();
  Future<int> getEarnedCount() => _badgeRepository.getEarnedCount();
}
