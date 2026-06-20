import '../entity/game_profile.dart';
import '../../data/repository/game_repository_impl.dart';

class GameUseCase {
  final GameRepository _gameRepo;

  GameUseCase(this._gameRepo);

  Future<GameProfile?> getGameProfile(int userId) async {
    return _gameRepo.getGameProfile(userId);
  }

  Future<GameProfile> getOrCreateProfile(int userId) async {
    var profile = await _gameRepo.getGameProfile(userId);
    if (profile == null) {
      await _gameRepo.createGameProfile(userId);
      profile = await _gameRepo.getGameProfile(userId);
    }
    return profile!;
  }

  /// Process daily check-in: award XP, update streak
  /// Returns the updated profile, or null if already checked in today
  Future<GameProfile?> processCheckin(int userId) async {
    final profile = await getOrCreateProfile(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if already checked in today
    if (profile.lastCheckinDate != null) {
      final last = DateTime(
        profile.lastCheckinDate!.year,
        profile.lastCheckinDate!.month,
        profile.lastCheckinDate!.day,
      );
      if (last == today) return null; // Already checked in
    }

    // Calculate streak
    int newStreak = 1;
    if (profile.lastCheckinDate != null) {
      final last = DateTime(
        profile.lastCheckinDate!.year,
        profile.lastCheckinDate!.month,
        profile.lastCheckinDate!.day,
      );
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        newStreak = profile.streakDays + 1;
      } else if (diff > 1) {
        newStreak = 1; // Streak broken
      }
    }

    // Calculate XP: base + streak bonus
    int xpEarned = XpRewards.dailyCheckin + (newStreak * XpRewards.streakBonus);

    // Award XP and level up
    final result = profile.awardXp(xpEarned);
    final updated = profile.copyWith(
      level: result.$3,
      xp: result.$4,
      totalXp: result.$2,
      streakDays: newStreak,
      longestStreak:
          newStreak > profile.longestStreak ? newStreak : profile.longestStreak,
      checkinTotal: profile.checkinTotal + 1,
      lastCheckinDate: today,
      updatedAt: DateTime.now(),
    );

    await _gameRepo.updateGameProfile(updated);
    return updated;
  }

  /// Award XP for craving resisted
  Future<GameProfile> awardCravingResisted(int userId) async {
    final profile = await getOrCreateProfile(userId);
    final result = profile.awardXp(XpRewards.cravingResisted);
    final updated = profile.copyWith(
      level: result.$3,
      xp: result.$4,
      totalXp: result.$2,
      cravingsResisted: profile.cravingsResisted + 1,
      updatedAt: DateTime.now(),
    );
    await _gameRepo.updateGameProfile(updated);
    return updated;
  }

  /// Award XP for exercise completed
  Future<GameProfile> awardExerciseCompleted(int userId) async {
    final profile = await getOrCreateProfile(userId);
    final result = profile.awardXp(XpRewards.exerciseCompleted);
    final updated = profile.copyWith(
      level: result.$3,
      xp: result.$4,
      totalXp: result.$2,
      exercisesCompleted: profile.exercisesCompleted + 1,
      updatedAt: DateTime.now(),
    );
    await _gameRepo.updateGameProfile(updated);
    return updated;
  }

  /// Award XP for SOS used
  Future<GameProfile> awardSosUsed(int userId) async {
    final profile = await getOrCreateProfile(userId);
    final result = profile.awardXp(XpRewards.sosUsed);
    final updated = profile.copyWith(
      level: result.$3,
      xp: result.$4,
      totalXp: result.$2,
      sosUsedCount: profile.sosUsedCount + 1,
      updatedAt: DateTime.now(),
    );
    await _gameRepo.updateGameProfile(updated);
    return updated;
  }
}
