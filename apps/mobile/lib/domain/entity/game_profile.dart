/// RPG-style gamification profile for the quit journey
class GameProfile {
  final int id;
  final int userId;
  int level; // Current level (1-100)
  int xp; // Current XP in this level
  int totalXp; // Total lifetime XP
  int streakDays; // Current consecutive check-in streak
  int longestStreak; // Longest streak ever achieved
  int checkinTotal; // Total check-ins ever
  DateTime? lastCheckinDate;
  DateTime createdAt;
  DateTime updatedAt;

  // Achievement counts
  int cravingsResisted; // Total cravings resisted
  int exercisesCompleted; // Total exercises completed
  int sosUsedCount; // Total SOS uses

  GameProfile({
    required this.id,
    required this.userId,
    this.level = 1,
    this.xp = 0,
    this.totalXp = 0,
    this.streakDays = 0,
    this.longestStreak = 0,
    this.checkinTotal = 0,
    this.lastCheckinDate,
    required this.createdAt,
    required this.updatedAt,
    this.cravingsResisted = 0,
    this.exercisesCompleted = 0,
    this.sosUsedCount = 0,
  });

  /// XP needed to reach next level (exponential growth)
  int get xpToNextLevel => _xpForLevel(level + 1);

  /// Progress percentage to next level (0.0-1.0)
  double get levelProgress {
    final currentLevelXp = _xpForLevel(level);
    final nextLevelXp = _xpForLevel(level + 1);
    if (nextLevelXp == currentLevelXp) return 0.0;
    return (xp - currentLevelXp) / (nextLevelXp - currentLevelXp);
  }

  /// Level title based on progress
  String get levelTitle {
    if (level <= 3) return '初学者';
    if (level <= 7) return '觉醒者';
    if (level <= 12) return '探索者';
    if (level <= 18) return '战斗者';
    if (level <= 25) return '勇士';
    if (level <= 35) return '守护者';
    if (level <= 50) return '征服者';
    if (level <= 70) return '传奇';
    if (level <= 90) return '英雄';
    return '大师';
  }

  /// Level icon emoji based on level
  String get levelEmoji {
    if (level <= 3) return '🌱';
    if (level <= 7) return '⭐';
    if (level <= 12) return '🔍';
    if (level <= 18) return '⚔️';
    if (level <= 25) return '🛡️';
    if (level <= 35) return '🏰';
    if (level <= 50) return '🏆';
    if (level <= 70) return '👑';
    if (level <= 90) return '🦸';
    return '🌟';
  }

  /// XP required for a given level
  static int _xpForLevel(int lvl) {
    // Level 1 = 0 XP, Level 2 = 100 XP, Level 3 = 250 XP, etc.
    return ((lvl - 1) * (lvl - 1) * 50);
  }

  /// Check if streak is still active today
  bool get isStreakActive {
    if (lastCheckinDate == null) return false;
    final now = DateTime.now();
    final last = DateTime(
        lastCheckinDate!.year, lastCheckinDate!.month, lastCheckinDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    return last == today || last == today.subtract(const Duration(days: 1));
  }

  /// Award XP and auto-level-up
  (int levelsGained, int newXp, int newLevel, int newXpInLevel) awardXp(
      int amount) {
    int newTotal = totalXp + amount;
    var newLevel = level;
    // Calculate what level the new total XP corresponds to
    while (_xpForLevel(newLevel + 1) <= newTotal) {
      newLevel++;
    }
    final newXpInLevel = newTotal - _xpForLevel(newLevel);
    final levelsGained = newLevel - level;
    return (levelsGained, newTotal, newLevel, newXpInLevel);
  }

  /// Get the XP range for current level display
  String get xpDisplay {
    final nextLevelXp = _xpForLevel(level + 1);
    return '$xp/$nextLevelXp';
  }

  GameProfile copyWith({
    int? id,
    int? userId,
    int? level,
    int? xp,
    int? totalXp,
    int? streakDays,
    int? longestStreak,
    int? checkinTotal,
    DateTime? lastCheckinDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? cravingsResisted,
    int? exercisesCompleted,
    int? sosUsedCount,
  }) {
    return GameProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      totalXp: totalXp ?? this.totalXp,
      streakDays: streakDays ?? this.streakDays,
      longestStreak: longestStreak ?? this.longestStreak,
      checkinTotal: checkinTotal ?? this.checkinTotal,
      lastCheckinDate: lastCheckinDate ?? this.lastCheckinDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cravingsResisted: cravingsResisted ?? this.cravingsResisted,
      exercisesCompleted: exercisesCompleted ?? this.exercisesCompleted,
      sosUsedCount: sosUsedCount ?? this.sosUsedCount,
    );
  }
}

/// XP reward definitions for various actions
class XpRewards {
  static const int dailyCheckin = 20;
  static const int streakBonus = 10; // Per streak day, multiplied
  static const int cravingResisted = 15;
  static const int cravingLogged = 5;
  static const int exerciseCompleted = 25;
  static const int sosUsed = 30;
  static const int relapsePlanCreated = 10;
  static const int weeklyReport = 50;
  static const int milestoneReached = 100;
}

/// Level milestone descriptions for the game profile screen
class LevelMilestone {
  final int level;
  final String title;
  final String description;
  final String reward;

  const LevelMilestone({
    required this.level,
    required this.title,
    required this.description,
    required this.reward,
  });

  static const List<LevelMilestone> milestones = [
    LevelMilestone(
        level: 1, title: '初学者', description: '开始你的戒断之旅', reward: '解锁每日签到'),
    LevelMilestone(
        level: 3, title: '觉醒者', description: '连续签到3天', reward: '解锁渴望冲浪'),
    LevelMilestone(
        level: 5, title: '探索者', description: '开始探索自己的渴望模式', reward: '解锁场景分析'),
    LevelMilestone(
        level: 10, title: '战斗者', description: '成功抵抗10次渴望', reward: '解锁高级CBT练习'),
    LevelMilestone(
        level: 15, title: '勇士', description: '连续签到15天', reward: '解锁生活方式重塑'),
    LevelMilestone(
        level: 20, title: '守护者', description: '完成20个CBT练习', reward: '解锁复发预防计划'),
    LevelMilestone(
        level: 30, title: '征服者', description: '坚持30天不复发', reward: '解锁周报功能'),
    LevelMilestone(
        level: 50, title: '传奇', description: '累计获得5000 XP', reward: '解锁大师徽章'),
    LevelMilestone(
        level: 75, title: '英雄', description: '连续签到75天', reward: '解锁专属称号'),
    LevelMilestone(
        level: 100, title: '大师', description: '达到最高等级', reward: '获得大师勋章'),
  ];
}
