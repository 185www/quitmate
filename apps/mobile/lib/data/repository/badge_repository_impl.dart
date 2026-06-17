import '../../domain/entity/badge.dart';
import '../../domain/repository/badge_repository.dart';
import '../database/app_database.dart';

class BadgeRepositoryImpl implements BadgeRepository {
  final AppDatabase _database;

  BadgeRepositoryImpl(this._database);

  @override
  Future<List<AppBadge>> getAllBadges() async {
    final badges = await _database.getAllBadges();
    return badges
        .map((b) => AppBadge(
              id: b.id,
              code: b.code,
              name: b.name,
              description: b.description,
              iconAsset: b.iconAsset,
              earnedAt: b.earnedAt,
            ))
        .toList();
  }

  @override
  Future<List<AppBadge>> getEarnedBadges() async {
    final badges = await _database.getEarnedBadges();
    return badges
        .map((b) => AppBadge(
              id: b.id,
              code: b.code,
              name: b.name,
              description: b.description,
              iconAsset: b.iconAsset,
              earnedAt: b.earnedAt,
            ))
        .toList();
  }

  @override
  Future<bool> earnBadge(String code) async {
    return await _database.earnBadge(code);
  }

  @override
  Future<int> getEarnedCount() async {
    final earned = await getEarnedBadges();
    return earned.length;
  }
}