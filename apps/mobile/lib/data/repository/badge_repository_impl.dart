import '../../domain/entity/badge.dart';
import '../database/app_database.dart';

class BadgeRepository {
  final AppDatabase _database;
  BadgeRepository(this._database);

  Future<List<AppBadge>> getAllBadges() async {
    final badges = await _database.getAllBadges();
    return badges.map((b) => _mapToBadge(b)).toList();
  }

  Future<List<AppBadge>> getEarnedBadges() async {
    final badges = await _database.getEarnedBadges();
    return badges.map((b) => _mapToBadge(b)).toList();
  }

  Future<bool> earnBadge(String code) async {
    final rows = await _database.earnBadge(code);
    return rows > 0;
  }

  Future<int> getEarnedCount() async {
    final badges = await getEarnedBadges();
    return badges.length;
  }

  AppBadge _mapToBadge(Map<String, dynamic> b) => AppBadge(
    id: b['id'] as int,
    code: b['code'] as String,
    name: b['name'] as String,
    description: b['description'] as String,
    iconAsset: b['icon_asset'] as String,
    earnedAt: b['earned_at'] != null ? DateTime.parse(b['earned_at'] as String) : null,
  );
}