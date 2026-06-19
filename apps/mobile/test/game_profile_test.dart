import 'package:flutter_test/flutter_test.dart';
import '../lib/domain/entity/game_profile.dart';

void main() {
  // Helper: create a base GameProfile for testing
  GameProfile createProfile({
    int level = 1,
    int xp = 0,
    int totalXp = 0,
    int streakDays = 0,
    int longestStreak = 0,
    DateTime? lastCheckinDate,
  }) {
    final now = DateTime.now();
    return GameProfile(
      id: 1,
      userId: 1,
      level: level,
      xp: xp,
      totalXp: totalXp,
      streakDays: streakDays,
      longestStreak: longestStreak,
      lastCheckinDate: lastCheckinDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('GameProfile - 等级称号 (levelTitle)', () {
    test('等级1-3 返回 初学者', () {
      for (var lvl = 1; lvl <= 3; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelTitle, equals('初学者'));
      }
    });

    test('等级4-7 返回 觉醒者', () {
      for (var lvl = 4; lvl <= 7; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelTitle, equals('觉醒者'));
      }
    });

    test('等级8-12 返回 探索者', () {
      for (var lvl = 8; lvl <= 12; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelTitle, equals('探索者'));
      }
    });

    test('等级13-18 返回 战斗者', () {
      for (var lvl = 13; lvl <= 18; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelTitle, equals('战斗者'));
      }
    });

    test('等级19-25 返回 勇士', () {
      for (var lvl = 19; lvl <= 25; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelTitle, equals('勇士'));
      }
    });

    test('等级26-35 返回 守护者', () {
      for (var lvl = 26; lvl <= 35; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelTitle, equals('守护者'));
      }
    });

    test('等级36-50 返回 征服者', () {
      for (var lvl = 36; lvl <= 50; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelTitle, equals('征服者'));
      }
    });

    test('等级51-70 返回 传奇', () {
      for (var lvl = 51; lvl <= 70; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelTitle, equals('传奇'));
      }
    });

    test('等级71-90 返回 英雄', () {
      for (var lvl = 71; lvl <= 90; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelTitle, equals('英雄'));
      }
    });

    test('等级91-100 返回 大师', () {
      for (var lvl = 91; lvl <= 100; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelTitle, equals('大师'));
      }
    });
  });

  group('GameProfile - 等级图标 (levelEmoji)', () {
    test('等级1-3 返回 🌱', () {
      for (var lvl = 1; lvl <= 3; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelEmoji, equals('🌱'));
      }
    });

    test('等级4-7 返回 ⭐', () {
      for (var lvl = 4; lvl <= 7; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelEmoji, equals('⭐'));
      }
    });

    test('等级8-12 返回 🔍', () {
      for (var lvl = 8; lvl <= 12; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelEmoji, equals('🔍'));
      }
    });

    test('等级13-18 返回 ⚔️', () {
      for (var lvl = 13; lvl <= 18; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelEmoji, equals('⚔️'));
      }
    });

    test('等级19-25 返回 🛡️', () {
      for (var lvl = 19; lvl <= 25; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelEmoji, equals('🛡️'));
      }
    });

    test('等级26-35 返回 🏰', () {
      for (var lvl = 26; lvl <= 35; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelEmoji, equals('🏰'));
      }
    });

    test('等级36-50 返回 🏆', () {
      for (var lvl = 36; lvl <= 50; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelEmoji, equals('🏆'));
      }
    });

    test('等级51-70 返回 👑', () {
      for (var lvl = 51; lvl <= 70; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelEmoji, equals('👑'));
      }
    });

    test('等级71-90 返回 🦸', () {
      for (var lvl = 71; lvl <= 90; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelEmoji, equals('🦸'));
      }
    });

    test('等级91-100 返回 🌟', () {
      for (var lvl = 91; lvl <= 100; lvl++) {
        final profile = createProfile(level: lvl);
        expect(profile.levelEmoji, equals('🌟'));
      }
    });
  });

  group('GameProfile - XP计算 (_xpForLevel)', () {
    // _xpForLevel is private, so we test via xpToNextLevel and levelProgress.
    // _xpForLevel(lvl) = ((lvl-1) * (lvl-1) * 50)
    // Level 1 = 0, Level 2 = 50, Level 3 = 200, Level 4 = 450, Level 10 = 4050

    test('等级1的 xpToNextLevel = 50', () {
      final profile = createProfile(level: 1);
      // xpToNextLevel = _xpForLevel(2) = (1*1*50) = 50
      expect(profile.xpToNextLevel, equals(50));
    });

    test('等级2的 xpToNextLevel = 200', () {
      final profile = createProfile(level: 2);
      // xpToNextLevel = _xpForLevel(3) = (2*2*50) = 200
      expect(profile.xpToNextLevel, equals(200));
    });

    test('等级3的 xpToNextLevel = 450', () {
      final profile = createProfile(level: 3);
      // xpToNextLevel = _xpForLevel(4) = (3*3*50) = 450
      expect(profile.xpToNextLevel, equals(450));
    });

    test('等级9的 xpToNextLevel = 4050', () {
      final profile = createProfile(level: 9);
      // xpToNextLevel = _xpForLevel(10) = (9*9*50) = 4050
      expect(profile.xpToNextLevel, equals(4050));
    });

    test('等级100的 xpToNextLevel = 99*99*50 = 490050', () {
      final profile = createProfile(level: 100);
      // xpToNextLevel = _xpForLevel(101) = (100*100*50) = 500000
      expect(profile.xpToNextLevel, equals(500000));
    });
  });

  group('GameProfile - 等级进度 (levelProgress)', () {
    test('等级1, xp=0 → progress=0.0', () {
      // (0 - 0) / (50 - 0) = 0
      final profile = createProfile(level: 1, xp: 0);
      expect(profile.levelProgress, equals(0.0));
    });

    test('等级1, xp=25 → progress=0.5', () {
      // (25 - 0) / (50 - 0) = 0.5
      final profile = createProfile(level: 1, xp: 25);
      expect(profile.levelProgress, closeTo(0.5, 0.001));
    });

    test('等级1, xp=50 → progress=1.0 (即将升级)', () {
      // (50 - 0) / (50 - 0) = 1.0
      final profile = createProfile(level: 1, xp: 50);
      expect(profile.levelProgress, equals(1.0));
    });

    test('等级2, xp=50 → progress=0.0 (刚到等级2)', () {
      // (50 - 50) / (200 - 50) = 0
      final profile = createProfile(level: 2, xp: 50);
      expect(profile.levelProgress, equals(0.0));
    });

    test('等级2, xp=125 → progress=0.5', () {
      // (125 - 50) / (200 - 50) = 75/150 = 0.5
      final profile = createProfile(level: 2, xp: 125);
      expect(profile.levelProgress, closeTo(0.5, 0.001));
    });

    test('等级5, xp=800 → progress=0.0 (刚到等级5)', () {
      // _xpForLevel(5) = 4*4*50 = 800
      // (800 - 800) / (5*5*50 - 800) = 0 / 450 = 0
      final profile = createProfile(level: 5, xp: 800);
      expect(profile.levelProgress, equals(0.0));
    });

    test('等级5, xp=1025 → progress=0.5', () {
      // _xpForLevel(5) = 800, _xpForLevel(6) = 1250
      // (1025 - 800) / (1250 - 800) = 225/450 = 0.5
      final profile = createProfile(level: 5, xp: 1025);
      expect(profile.levelProgress, closeTo(0.5, 0.001));
    });
  });

  group('GameProfile - xpToNextLevel', () {
    test('等级1 → 需要50 XP升到等级2', () {
      final profile = createProfile(level: 1);
      expect(profile.xpToNextLevel, equals(50));
    });

    test('等级5 → 需要1250 XP升到等级6', () {
      // _xpForLevel(6) = 5*5*50 = 1250
      final profile = createProfile(level: 5);
      expect(profile.xpToNextLevel, equals(1250));
    });

    test('等级10 → 需要5000 XP升到等级11', () {
      // _xpForLevel(11) = 10*10*50 = 5000
      final profile = createProfile(level: 10);
      expect(profile.xpToNextLevel, equals(5000));
    });
  });

  group('GameProfile - awardXp', () {
    test('少量XP不升级', () {
      final profile = createProfile(level: 1, totalXp: 0);
      final result = profile.awardXp(25);
      expect(result.$1, equals(0)); // levelsGained
      expect(result.$2, equals(25)); // newXp (totalXp)
      expect(result.$3, equals(1)); // newLevel
      expect(result.$4, equals(25)); // newXpInLevel
    });

    test('刚好升一级 (50 XP at level 1)', () {
      final profile = createProfile(level: 1, totalXp: 0);
      final result = profile.awardXp(50);
      expect(result.$1, equals(1)); // levelsGained
      expect(result.$2, equals(50)); // newXp
      expect(result.$3, equals(2)); // newLevel
      expect(result.$4, equals(0)); // newXpInLevel (50 - 50 = 0)
    });

    test('跨越一级边界', () {
      final profile = createProfile(level: 1, totalXp: 40);
      final result = profile.awardXp(20);
      // newTotal = 60, level 2 starts at 50
      // _xpForLevel(2) = 50 <= 60 → level 2
      // _xpForLevel(3) = 200 > 60 → stop
      // newXpInLevel = 60 - 50 = 10
      expect(result.$1, equals(1)); // levelsGained
      expect(result.$2, equals(60)); // newXp
      expect(result.$3, equals(2)); // newLevel
      expect(result.$4, equals(10)); // newXpInLevel
    });

    test('跨越多级边界 (200 XP at level 1)', () {
      final profile = createProfile(level: 1, totalXp: 0);
      final result = profile.awardXp(200);
      // newTotal = 200
      // _xpForLevel(2) = 50 <= 200 → level 2
      // _xpForLevel(3) = 200 <= 200 → level 3
      // _xpForLevel(4) = 450 > 200 → stop
      // newXpInLevel = 200 - 200 = 0
      expect(result.$1, equals(2)); // levelsGained
      expect(result.$2, equals(200)); // newXp
      expect(result.$3, equals(3)); // newLevel
      expect(result.$4, equals(0)); // newXpInLevel
    });

    test('跨越多级边界 (500 XP at level 1)', () {
      final profile = createProfile(level: 1, totalXp: 0);
      final result = profile.awardXp(500);
      // newTotal = 500
      // _xpForLevel(2)=50, _xpForLevel(3)=200, _xpForLevel(4)=450, _xpForLevel(5)=800
      // 50 <= 500, 200 <= 500, 450 <= 500, 800 > 500 → level 4
      // newXpInLevel = 500 - 450 = 50
      expect(result.$1, equals(3)); // levelsGained
      expect(result.$2, equals(500)); // newXp
      expect(result.$3, equals(4)); // newLevel
      expect(result.$4, equals(50)); // newXpInLevel
    });

    test('高等级少量XP不升级', () {
      final profile = createProfile(level: 10, totalXp: 4050);
      // _xpForLevel(11) = 5000
      final result = profile.awardXp(100);
      expect(result.$1, equals(0));
      expect(result.$2, equals(4150));
      expect(result.$3, equals(10));
    });
  });

  group('GameProfile - 连续打卡 (isStreakActive)', () {
    test('今天打卡 → 连续有效', () {
      final profile = createProfile(lastCheckinDate: DateTime.now());
      expect(profile.isStreakActive, isTrue);
    });

    test('昨天打卡 → 连续有效', () {
      final profile = createProfile(
        lastCheckinDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(profile.isStreakActive, isTrue);
    });

    test('2天前打卡 → 连续已断', () {
      final profile = createProfile(
        lastCheckinDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(profile.isStreakActive, isFalse);
    });

    test('7天前打卡 → 连续已断', () {
      final profile = createProfile(
        lastCheckinDate: DateTime.now().subtract(const Duration(days: 7)),
      );
      expect(profile.isStreakActive, isFalse);
    });

    test('null lastCheckinDate → 连续无效', () {
      final profile = createProfile(lastCheckinDate: null);
      expect(profile.isStreakActive, isFalse);
    });

    test('未来时间打卡(异常情况) → 连续无效', () {
      final profile = createProfile(
        lastCheckinDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(profile.isStreakActive, isFalse);
    });
  });

  group('GameProfile - LevelMilestone.milestones', () {
    test('包含10个里程碑', () {
      expect(LevelMilestone.milestones.length, equals(10));
    });

    test('第一个里程碑是等级1', () {
      expect(LevelMilestone.milestones[0].level, equals(1));
      expect(LevelMilestone.milestones[0].title, equals('初学者'));
    });

    test('最后一个里程碑是等级100', () {
      expect(LevelMilestone.milestones[9].level, equals(100));
      expect(LevelMilestone.milestones[9].title, equals('大师'));
    });

    test('所有里程碑按等级递增排列', () {
      for (var i = 1; i < LevelMilestone.milestones.length; i++) {
        expect(
          LevelMilestone.milestones[i].level,
          greaterThan(LevelMilestone.milestones[i - 1].level),
        );
      }
    });

    test('每个里程碑都有非空的title、description、reward', () {
      for (final m in LevelMilestone.milestones) {
        expect(m.title, isNotEmpty);
        expect(m.description, isNotEmpty);
        expect(m.reward, isNotEmpty);
      }
    });
  });

  group('GameProfile - XpRewards 常量', () {
    test('dailyCheckin = 20', () {
      expect(XpRewards.dailyCheckin, equals(20));
    });

    test('streakBonus = 10', () {
      expect(XpRewards.streakBonus, equals(10));
    });

    test('cravingResisted = 15', () {
      expect(XpRewards.cravingResisted, equals(15));
    });

    test('cravingLogged = 5', () {
      expect(XpRewards.cravingLogged, equals(5));
    });

    test('exerciseCompleted = 25', () {
      expect(XpRewards.exerciseCompleted, equals(25));
    });

    test('sosUsed = 30', () {
      expect(XpRewards.sosUsed, equals(30));
    });

    test('relapsePlanCreated = 10', () {
      expect(XpRewards.relapsePlanCreated, equals(10));
    });

    test('weeklyReport = 50', () {
      expect(XpRewards.weeklyReport, equals(50));
    });

    test('milestoneReached = 100', () {
      expect(XpRewards.milestoneReached, equals(100));
    });

    test('所有奖励值为正数', () {
      expect(XpRewards.dailyCheckin, greaterThan(0));
      expect(XpRewards.streakBonus, greaterThan(0));
      expect(XpRewards.cravingResisted, greaterThan(0));
      expect(XpRewards.exerciseCompleted, greaterThan(0));
      expect(XpRewards.sosUsed, greaterThan(0));
      expect(XpRewards.weeklyReport, greaterThan(0));
      expect(XpRewards.milestoneReached, greaterThan(0));
    });
  });

  group('GameProfile - copyWith', () {
    late GameProfile base;

    setUp(() {
      base = createProfile(
        level: 5,
        xp: 800,
        totalXp: 800,
        streakDays: 10,
        longestStreak: 15,
        checkinTotal: 20,
        cravingsResisted: 30,
        exercisesCompleted: 10,
        sosUsedCount: 2,
        lastCheckinDate: DateTime.now(),
      );
    });

    test('修改level后其他字段保持不变', () {
      final copy = base.copyWith(level: 10);
      expect(copy.level, equals(10));
      expect(copy.xp, equals(base.xp));
      expect(copy.totalXp, equals(base.totalXp));
      expect(copy.streakDays, equals(base.streakDays));
      expect(copy.longestStreak, equals(base.longestStreak));
      expect(copy.userId, equals(base.userId));
    });

    test('修改streakDays后其他字段保持不变', () {
      final copy = base.copyWith(streakDays: 99);
      expect(copy.streakDays, equals(99));
      expect(copy.level, equals(base.level));
      expect(copy.longestStreak, equals(base.longestStreak));
    });

    test('不传参数时所有字段保持不变', () {
      final copy = base.copyWith();
      expect(copy.level, equals(base.level));
      expect(copy.xp, equals(base.xp));
      expect(copy.totalXp, equals(base.totalXp));
      expect(copy.streakDays, equals(base.streakDays));
      expect(copy.longestStreak, equals(base.longestStreak));
      expect(copy.checkinTotal, equals(base.checkinTotal));
      expect(copy.cravingsResisted, equals(base.cravingsResisted));
      expect(copy.exercisesCompleted, equals(base.exercisesCompleted));
      expect(copy.sosUsedCount, equals(base.sosUsedCount));
    });

    test('可以同时修改多个字段', () {
      final copy = base.copyWith(level: 20, totalXp: 5000, streakDays: 0);
      expect(copy.level, equals(20));
      expect(copy.totalXp, equals(5000));
      expect(copy.streakDays, equals(0));
      expect(copy.xp, equals(base.xp)); // 未修改
    });
  });

  group('GameProfile - xpDisplay', () {
    test('等级1显示正确格式', () {
      final profile = createProfile(level: 1, xp: 25);
      expect(profile.xpDisplay, equals('25/50'));
    });

    test('等级5显示正确格式', () {
      final profile = createProfile(level: 5, xp: 1000);
      // xpToNextLevel = _xpForLevel(6) = 1250
      expect(profile.xpDisplay, equals('1000/1250'));
    });
  });

  group('GameProfile - 构造函数默认值', () {
    test('默认等级为1', () {
      final now = DateTime.now();
      final profile = GameProfile(id: 1, userId: 1, createdAt: now, updatedAt: now);
      expect(profile.level, equals(1));
    });

    test('默认XP相关值为0', () {
      final now = DateTime.now();
      final profile = GameProfile(id: 1, userId: 1, createdAt: now, updatedAt: now);
      expect(profile.xp, equals(0));
      expect(profile.totalXp, equals(0));
    });

    test('默认连续天数为0', () {
      final now = DateTime.now();
      final profile = GameProfile(id: 1, userId: 1, createdAt: now, updatedAt: now);
      expect(profile.streakDays, equals(0));
      expect(profile.longestStreak, equals(0));
      expect(profile.checkinTotal, equals(0));
    });

    test('默认成就计数为0', () {
      final now = DateTime.now();
      final profile = GameProfile(id: 1, userId: 1, createdAt: now, updatedAt: now);
      expect(profile.cravingsResisted, equals(0));
      expect(profile.exercisesCompleted, equals(0));
      expect(profile.sosUsedCount, equals(0));
    });
  });
}
