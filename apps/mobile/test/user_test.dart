import 'package:flutter_test/flutter_test.dart';
import '../lib/domain/entity/user.dart';

void main() {
  // Helper: create a base User for testing
  User createUser({
    TargetType targetType = TargetType.smoking,
    UserStage stage = UserStage.preparation,
    DateTime? quitDate,
    int? fagerstromScore,
    int? auditScore,
    double? dailyConsumption,
    int? yearsOfUse,
    double? dailyCostAmount,
  }) {
    final now = DateTime.now();
    return User(
      id: 1,
      targetType: targetType,
      quitDate: quitDate,
      stage: stage,
      fagerstromScore: fagerstromScore,
      auditScore: auditScore,
      dailyConsumption: dailyConsumption,
      yearsOfUse: yearsOfUse,
      dailyCostAmount: dailyCostAmount,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('User - daysSinceQuit', () {
    test('今天戒烟 → 0天', () {
      final user = createUser(quitDate: DateTime.now());
      expect(user.daysSinceQuit, equals(0));
    });

    test('过去10天戒烟 → 10天', () {
      final user = createUser(
        quitDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(user.daysSinceQuit, equals(10));
    });

    test('过去100天戒烟 → 100天', () {
      final user = createUser(
        quitDate: DateTime.now().subtract(const Duration(days: 100)),
      );
      expect(user.daysSinceQuit, equals(100));
    });

    test('过去365天戒烟 → 365天', () {
      final user = createUser(
        quitDate: DateTime.now().subtract(const Duration(days: 365)),
      );
      expect(user.daysSinceQuit, equals(365));
    });

    test('null quitDate → 0天', () {
      final user = createUser(quitDate: null);
      expect(user.daysSinceQuit, equals(0));
    });

    test('明天戒烟(未来) → 负数', () {
      final user = createUser(
        quitDate: DateTime.now().add(const Duration(days: 5)),
      );
      // 未来日期返回负数
      expect(user.daysSinceQuit, lessThan(0));
    });
  });

  group('User - hasQuitDate', () {
    test('有quitDate → true', () {
      final user = createUser(quitDate: DateTime.now());
      expect(user.hasQuitDate, isTrue);
    });

    test('null quitDate → false', () {
      final user = createUser(quitDate: null);
      expect(user.hasQuitDate, isFalse);
    });
  });

  group('User - estimatedDailyCigarettes', () {
    test('smoking目标, fagerstromScore=5 → 10根', () {
      // (5 * 2).clamp(1, 60) = 10
      final user = createUser(
        targetType: TargetType.smoking,
        fagerstromScore: 5,
      );
      expect(user.estimatedDailyCigarettes, equals(10));
    });

    test('smoking目标, fagerstromScore=8 → 16根', () {
      // (8 * 2).clamp(1, 60) = 16
      final user = createUser(
        targetType: TargetType.smoking,
        fagerstromScore: 8,
      );
      expect(user.estimatedDailyCigarettes, equals(16));
    });

    test('smoking目标, fagerstromScore=0 → 0 (clamp到1)', () {
      // (0 * 2).clamp(1, 60) = 0.clamp(1, 60) = 1
      final user = createUser(
        targetType: TargetType.smoking,
        fagerstromScore: 0,
      );
      expect(user.estimatedDailyCigarettes, equals(1));
    });

    test('smoking目标, fagerstromScore=30 → 60 (clamp上限)', () {
      // (30 * 2).clamp(1, 60) = 60.clamp(1, 60) = 60
      final user = createUser(
        targetType: TargetType.smoking,
        fagerstromScore: 30,
      );
      expect(user.estimatedDailyCigarettes, equals(60));
    });

    test('alcohol目标 → 0', () {
      final user = createUser(
        targetType: TargetType.alcohol,
        fagerstromScore: 8,
      );
      expect(user.estimatedDailyCigarettes, equals(0));
    });

    test('smoking目标, null fagerstromScore → 默认10', () {
      final user = createUser(
        targetType: TargetType.smoking,
        fagerstromScore: null,
      );
      expect(user.estimatedDailyCigarettes, equals(10));
    });

    test('both目标, fagerstromScore=5 → 10根', () {
      final user = createUser(
        targetType: TargetType.both,
        fagerstromScore: 5,
      );
      expect(user.estimatedDailyCigarettes, equals(10));
    });
  });

  group('User - estimatedDailyDrinks', () {
    test('alcohol目标, auditScore=8 → 2杯', () {
      // (8 ~/ 4).clamp(0, 20) = 2
      final user = createUser(
        targetType: TargetType.alcohol,
        auditScore: 8,
      );
      expect(user.estimatedDailyDrinks, equals(2));
    });

    test('alcohol目标, auditScore=16 → 4杯', () {
      // (16 ~/ 4).clamp(0, 20) = 4
      final user = createUser(
        targetType: TargetType.alcohol,
        auditScore: 16,
      );
      expect(user.estimatedDailyDrinks, equals(4));
    });

    test('alcohol目标, auditScore=3 → 0杯', () {
      // (3 ~/ 4).clamp(0, 20) = 0
      final user = createUser(
        targetType: TargetType.alcohol,
        auditScore: 3,
      );
      expect(user.estimatedDailyDrinks, equals(0));
    });

    test('alcohol目标, auditScore=100 → 20杯 (clamp上限)', () {
      // (100 ~/ 4).clamp(0, 20) = 25.clamp(0, 20) = 20
      final user = createUser(
        targetType: TargetType.alcohol,
        auditScore: 100,
      );
      expect(user.estimatedDailyDrinks, equals(20));
    });

    test('smoking目标 → 0', () {
      final user = createUser(
        targetType: TargetType.smoking,
        auditScore: 8,
      );
      expect(user.estimatedDailyDrinks, equals(0));
    });

    test('alcohol目标, null auditScore → 默认2', () {
      final user = createUser(
        targetType: TargetType.alcohol,
        auditScore: null,
      );
      expect(user.estimatedDailyDrinks, equals(2));
    });

    test('both目标, auditScore=12 → 3杯', () {
      // (12 ~/ 4).clamp(0, 20) = 3
      final user = createUser(
        targetType: TargetType.both,
        auditScore: 12,
      );
      expect(user.estimatedDailyDrinks, equals(3));
    });
  });

  group('User - dailyCost', () {
    test('有dailyCostAmount → 直接使用', () {
      final user = createUser(
        targetType: TargetType.smoking,
        dailyCostAmount: 50.0,
      );
      expect(user.dailyCost, equals(50.0));
    });

    test('dailyCostAmount=0且有consumption → 使用consumption计算', () {
      final user = createUser(
        targetType: TargetType.smoking,
        dailyCostAmount: 0,
        dailyConsumption: 20,
      );
      // smoking: costPerUnit = 0.5
      // 20 * 0.5 = 10.0
      expect(user.dailyCost, equals(10.0));
    });

    test('alcohol目标有consumption → 使用alcohol单价计算', () {
      final user = createUser(
        targetType: TargetType.alcohol,
        dailyConsumption: 3,
      );
      // alcohol: costPerUnit = 15.0
      // 3 * 15.0 = 45.0
      expect(user.dailyCost, equals(45.0));
    });

    test('smoking目标无consumption和dailyCostAmount → 用estimatedDailyCigarettes计算', () {
      final user = createUser(
        targetType: TargetType.smoking,
        fagerstromScore: 10,
      );
      // estimatedDailyCigarettes = (10*2).clamp(1,60) = 20
      // dailyCost = 20 * 0.5 = 10.0
      expect(user.dailyCost, equals(10.0));
    });

    test('alcohol目标无consumption和dailyCostAmount → 用estimatedDailyDrinks计算', () {
      final user = createUser(
        targetType: TargetType.alcohol,
        auditScore: 8,
      );
      // estimatedDailyDrinks = (8~/4).clamp(0,20) = 2
      // dailyCost = 2 * 15.0 = 30.0
      expect(user.dailyCost, equals(30.0));
    });

    test('both目标无consumption → 烟+酒合计', () {
      final user = createUser(
        targetType: TargetType.both,
        fagerstromScore: 10,
        auditScore: 8,
      );
      // estimatedDailyCigarettes = 20, estimatedDailyDrinks = 2
      // dailyCost = 20 * 0.5 + 2 * 15.0 = 10 + 30 = 40
      expect(user.dailyCost, equals(40.0));
    });

    test('有dailyCostAmount且大于0 → 优先使用dailyCostAmount', () {
      final user = createUser(
        targetType: TargetType.smoking,
        dailyCostAmount: 100.0,
        dailyConsumption: 20,
      );
      expect(user.dailyCost, equals(100.0));
    });
  });

  group('User - dailyLifeRegainedMinutes', () {
    test('smoking目标 → 11分钟', () {
      final user = createUser(targetType: TargetType.smoking);
      expect(user.dailyLifeRegainedMinutes, equals(11));
    });

    test('alcohol目标 → 11分钟', () {
      final user = createUser(targetType: TargetType.alcohol);
      expect(user.dailyLifeRegainedMinutes, equals(11));
    });

    test('both目标 → 22分钟', () {
      final user = createUser(targetType: TargetType.both);
      expect(user.dailyLifeRegainedMinutes, equals(22));
    });
  });

  group('User - isReadyForAction', () {
    test('preparation阶段 → true', () {
      final user = createUser(stage: UserStage.preparation);
      expect(user.isReadyForAction, isTrue);
    });

    test('action阶段 → true', () {
      final user = createUser(stage: UserStage.action);
      expect(user.isReadyForAction, isTrue);
    });

    test('preContemplation阶段 → false', () {
      final user = createUser(stage: UserStage.preContemplation);
      expect(user.isReadyForAction, isFalse);
    });

    test('contemplation阶段 → false', () {
      final user = createUser(stage: UserStage.contemplation);
      expect(user.isReadyForAction, isFalse);
    });

    test('maintenance阶段 → false', () {
      final user = createUser(stage: UserStage.maintenance);
      expect(user.isReadyForAction, isFalse);
    });
  });

  group('User - isReadyForMaintenance', () {
    test('maintenance阶段 → true', () {
      final user = createUser(stage: UserStage.maintenance);
      expect(user.isReadyForMaintenance, isTrue);
    });

    test('action阶段 → false', () {
      final user = createUser(stage: UserStage.action);
      expect(user.isReadyForMaintenance, isFalse);
    });

    test('preparation阶段 → false', () {
      final user = createUser(stage: UserStage.preparation);
      expect(user.isReadyForMaintenance, isFalse);
    });

    test('preContemplation阶段 → false', () {
      final user = createUser(stage: UserStage.preContemplation);
      expect(user.isReadyForMaintenance, isFalse);
    });
  });

  group('User - HealthMilestone.milestones', () {
    test('包含14个健康里程碑', () {
      expect(HealthMilestone.milestones.length, equals(14));
    });

    test('第一个里程碑是day 0', () {
      expect(HealthMilestone.milestones[0]['days'], equals(0));
      expect(HealthMilestone.milestones[0]['title'], isNotEmpty);
      expect(HealthMilestone.milestones[0]['desc'], isNotEmpty);
      expect(HealthMilestone.milestones[0]['organ'], isNotEmpty);
      expect(HealthMilestone.milestones[0]['pct'], isNotNull);
    });

    test('最后一个里程碑是day 3650', () {
      expect(HealthMilestone.milestones[13]['days'], equals(3650));
    });

    test('里程碑按天数递增排列', () {
      for (var i = 1; i < HealthMilestone.milestones.length; i++) {
        expect(
          HealthMilestone.milestones[i]['days'] as int,
          greaterThanOrEqualTo(HealthMilestone.milestones[i - 1]['days'] as int),
        );
      }
    });

    test('所有里程碑有必需字段 (days, title, desc, organ, pct)', () {
      for (final m in HealthMilestone.milestones) {
        expect(m.containsKey('days'), isTrue);
        expect(m.containsKey('title'), isTrue);
        expect(m.containsKey('desc'), isTrue);
        expect(m.containsKey('organ'), isTrue);
        expect(m.containsKey('pct'), isTrue);
        expect(m['title'] as String, isNotEmpty);
        expect(m['desc'] as String, isNotEmpty);
        expect(m['organ'] as String, isNotEmpty);
      }
    });

    test('恢复百分比在0-100范围内', () {
      for (final m in HealthMilestone.milestones) {
        final pct = m['pct'] as int;
        expect(pct, greaterThanOrEqualTo(0));
        expect(pct, lessThanOrEqualTo(100));
      }
    });

    test('里程碑包含关键时间节点', () {
      final daysList =
          HealthMilestone.milestones.map((m) => m['days'] as int).toList();
      expect(daysList, contains(0));
      expect(daysList, contains(1));
      expect(daysList, contains(7));
      expect(daysList, contains(30));
      expect(daysList, contains(90));
      expect(daysList, contains(365));
    });
  });

  group('User - CravingEntry copyWith', () {

    test('CravingEntry可以修改intensity', () {
      // Note: CravingEntry.timestamp is required, so we need a real DateTime
      final now = DateTime.now();
      final entry = CravingEntry(
        id: 1,
        userId: 1,
        timestamp: now,
        intensity: 5,
        trigger: '压力',
        resolved: true,
      );
      final copy = entry.copyWith(intensity: 8);
      expect(copy.intensity, equals(8));
      expect(copy.trigger, equals('压力'));
      expect(copy.resolved, isTrue);
    });

    test('CravingEntry可以修改trigger', () {
      final entry = CravingEntry(
        userId: 1,
        timestamp: DateTime.now(),
        intensity: 3,
        trigger: '社交',
      );
      final copy = entry.copyWith(trigger: '饭后');
      expect(copy.trigger, equals('饭后'));
      expect(copy.intensity, equals(3));
    });

    test('CravingEntry可以修改resolved', () {
      final entry = CravingEntry(
        userId: 1,
        timestamp: DateTime.now(),
        intensity: 7,
        resolved: false,
      );
      final copy = entry.copyWith(resolved: true);
      expect(copy.resolved, isTrue);
    });

    test('CravingEntry不传参数时所有字段保持不变', () {
      final entry = CravingEntry(
        id: 42,
        userId: 99,
        timestamp: DateTime(2024, 6, 15, 14, 30),
        intensity: 8,
        trigger: '焦虑',
        context: '家里',
        copingUsed: '冥想',
        resolved: true,
        location: '卧室',
        socialContext: '独自',
        activity: '休息',
      );
      final copy = entry.copyWith();
      expect(copy.id, equals(42));
      expect(copy.userId, equals(99));
      expect(copy.intensity, equals(8));
      expect(copy.trigger, equals('焦虑'));
      expect(copy.context, equals('家里'));
      expect(copy.copingUsed, equals('冥想'));
      expect(copy.resolved, isTrue);
      expect(copy.location, equals('卧室'));
      expect(copy.socialContext, equals('独自'));
      expect(copy.activity, equals('休息'));
    });
  });

  group('User - TargetType 枚举', () {
    test('TargetType包含三种类型', () {
      expect(TargetType.values.length, equals(3));
      expect(TargetType.values, contains(TargetType.smoking));
      expect(TargetType.values, contains(TargetType.alcohol));
      expect(TargetType.values, contains(TargetType.both));
    });
  });

  group('User - UserStage 枚举', () {
    test('UserStage包含五种阶段', () {
      expect(UserStage.values.length, equals(5));
      expect(UserStage.values, contains(UserStage.preContemplation));
      expect(UserStage.values, contains(UserStage.contemplation));
      expect(UserStage.values, contains(UserStage.preparation));
      expect(UserStage.values, contains(UserStage.action));
      expect(UserStage.values, contains(UserStage.maintenance));
    });
  });

  group('User - copyWith', () {
    test('修改targetType后其他字段保持不变', () {
      final now = DateTime.now();
      final user = User(
        id: 1,
        targetType: TargetType.smoking,
        stage: UserStage.action,
        quitDate: now,
        fagerstromScore: 5,
        auditScore: 8,
        dailyConsumption: 20,
        yearsOfUse: 10,
        createdAt: now,
        updatedAt: now,
      );
      final copy = user.copyWith(targetType: TargetType.alcohol);
      expect(copy.targetType, equals(TargetType.alcohol));
      expect(copy.stage, equals(UserStage.action));
      expect(copy.fagerstromScore, equals(5));
      expect(copy.dailyConsumption, equals(20));
    });

    test('修改stage后其他字段保持不变', () {
      final user = createUser(stage: UserStage.preContemplation);
      final copy = user.copyWith(stage: UserStage.maintenance);
      expect(copy.stage, equals(UserStage.maintenance));
      expect(copy.targetType, equals(user.targetType));
    });

    test('不传参数时所有字段保持不变', () {
      final now = DateTime.now();
      final user = User(
        id: 5,
        targetType: TargetType.both,
        quitDate: now,
        stage: UserStage.maintenance,
        fagerstromScore: 6,
        auditScore: 10,
        dailyConsumption: 15.5,
        yearsOfUse: 5,
        dailyCostAmount: 25.0,
        createdAt: now,
        updatedAt: now,
      );
      final copy = user.copyWith();
      expect(copy.id, equals(user.id));
      expect(copy.targetType, equals(user.targetType));
      expect(copy.stage, equals(user.stage));
      expect(copy.fagerstromScore, equals(user.fagerstromScore));
      expect(copy.auditScore, equals(user.auditScore));
      expect(copy.dailyConsumption, equals(user.dailyConsumption));
      expect(copy.yearsOfUse, equals(user.yearsOfUse));
      expect(copy.dailyCostAmount, equals(user.dailyCostAmount));
    });
  });
}
