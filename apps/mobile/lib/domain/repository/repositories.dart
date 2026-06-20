/// Abstract repository interfaces for the domain layer.
///
/// These define the contract that data-layer implementations must fulfill.
/// Each abstract class mirrors the exact public method signatures of the
/// corresponding concrete repository in `data/repository/`.
///
/// Placement in `domain/repository/` keeps use cases decoupled from the
/// data layer: they depend on these abstractions while `implements` bindings
/// live in the data layer.

import '../entity/user.dart';
import '../entity/game_profile.dart';
import '../entity/daily_log.dart';
import '../entity/relapse_plan.dart';
import '../entity/badge.dart';

// ---------------------------------------------------------------------------
// User
// ---------------------------------------------------------------------------

abstract class UserRepository {
  Future<User?> getCurrentUser();

  Future<User> createUser({
    required TargetType targetType,
    DateTime? quitDate,
    int? fagerstromScore,
    int? auditScore,
    double? dailyConsumption,
    int? yearsOfUse,
    double? dailyCostAmount,
  });

  Future<User> updateUser({
    required int id,
    TargetType? targetType,
    DateTime? quitDate,
    UserStage? stage,
    int? fagerstromScore,
    int? auditScore,
    double? dailyConsumption,
    int? yearsOfUse,
    double? dailyCostAmount,
  });

  Future<void> savePreferences(Map<String, dynamic> preferences);

  Future<Map<String, dynamic>> getPreferences();
}

// ---------------------------------------------------------------------------
// Craving
// ---------------------------------------------------------------------------

abstract class CravingRepository {
  Future<int> logCraving(
    int userId,
    int intensity, {
    String? trigger,
    String? context,
    String? copingUsed,
    bool resolved = false,
    String? location,
    String? socialContext,
    String? activity,
  });

  Future<int> getCravingCount(int userId, {DateTime? since});

  Future<double> getAverageIntensity(int userId, {DateTime? since});

  Future<List<MapEntry<String, int>>> getTopTriggers(int userId,
      {int limit = 5});

  Future<Map<String, List<MapEntry<String, int>>>> getSceneAnalysis(
      int userId);

  Future<List<Map<String, dynamic>>> getAllRawLogs(int userId);
}

// ---------------------------------------------------------------------------
// Game Profile
// ---------------------------------------------------------------------------

abstract class GameRepository {
  Future<GameProfile?> getGameProfile(int userId);

  Future<void> createGameProfile(int userId);

  Future<void> updateGameProfile(GameProfile profile);
}

// ---------------------------------------------------------------------------
// Daily Log
// ---------------------------------------------------------------------------

abstract class LogRepository {
  Future<DailyLogEntry?> getTodayLog(int userId);

  Future<List<DailyLogEntry>> getLogsForUser(int userId, {int limit = 30});

  Future<int> insertLog(DailyLogEntry log);

  Future<int> getStreakDays(int userId);

  Future<List<String>> getCommonTriggers(int userId, {int limit = 5});
}

// ---------------------------------------------------------------------------
// Relapse Plan
// ---------------------------------------------------------------------------

abstract class PlanRepository {
  Future<List<RelapsePlanItem>> getPlansForUser(int userId);

  Future<List<RelapsePlanItem>> getTemplatePlans();

  Future<int> insertPlan(RelapsePlanItem plan);

  Future<bool> deletePlan(int id);
}

// ---------------------------------------------------------------------------
// Badge
// ---------------------------------------------------------------------------

abstract class BadgeRepository {
  Future<List<AppBadge>> getAllBadges();

  Future<List<AppBadge>> getEarnedBadges();

  Future<bool> earnBadge(String code);

  Future<int> getEarnedCount();
}
