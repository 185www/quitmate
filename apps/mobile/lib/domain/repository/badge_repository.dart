import '../entity/badge.dart';

abstract class BadgeRepository {
  Future<List<AppBadge>> getAllBadges();
  Future<List<AppBadge>> getEarnedBadges();
  Future<bool> earnBadge(String code);
  Future<int> getEarnedCount();
}