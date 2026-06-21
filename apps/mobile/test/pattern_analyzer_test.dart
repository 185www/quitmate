import 'package:flutter_test/flutter_test.dart';
import '../lib/domain/entity/user.dart';
import '../lib/domain/entity/daily_log.dart';
import '../lib/domain/entity/game_profile.dart';
import '../lib/domain/entity/analysis.dart';
import '../lib/core/coach/pattern_analyzer.dart';

void main() {
  late PatternAnalyzer analyzer;

  setUp(() {
    analyzer = PatternAnalyzer();
  });

  // ══════════════════════════════════════════════
  // analyzeTimePatterns
  // ══════════════════════════════════════════════
  group('PatternAnalyzer - analyzeTimePatterns', () {
    test('空列表返回默认中性模式', () {
      final result = analyzer.analyzeTimePatterns([]);
      expect(result.peakHour, equals(-1));
      expect(result.peakIntensity, equals(0));
      expect(result.highRiskHours, isEmpty);
      expect(result.summary, contains('暂无'));
    });

    test('单个渴望 → 该小时为峰值', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 15, 14, 30),
          intensity: 7,
        ),
      ];
      final result = analyzer.analyzeTimePatterns(cravings);
      expect(result.peakHour, equals(14));
      expect(result.peakIntensity, equals(7.0));
      expect(result.hourlyDistribution, isNotNull);
      expect(result.hourlyDistribution[14], equals(1));
    });

    test('多个渴望在同一小时 → 集中模式', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 15, 15, 0),
          intensity: 8,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 15, 15, 30),
          intensity: 6,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 15, 15, 45),
          intensity: 7,
        ),
      ];
      final result = analyzer.analyzeTimePatterns(cravings);
      expect(result.peakHour, equals(15));
      expect(result.peakIntensity, closeTo(7.0, 0.1));
      expect(result.hourlyDistribution[15], equals(3));
    });

    test('分散的渴望 → 分散模式摘要', () {
      // 24 个渴望分布在每个小时
      final cravings = List.generate(24, (i) {
        return CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 15, i, 0),
          intensity: 5,
        );
      });
      final result = analyzer.analyzeTimePatterns(cravings);
      // 每小时 1 个，avgPerHour = 24/24 = 1
      // highRisk: count >= 1 * 1.3 = 1.3 → count >= 2 → none
      expect(result.highRiskHours, isEmpty);
      expect(result.summary, contains('峰值'));
    });

    test('多个高峰小时 → 高风险时段', () {
      // 10 个渴望在 10 点, 8 个在 11 点, 2 个在 14 点
      // avgPerHour = 20/24 ≈ 0.833, highRisk threshold = 0.833 * 1.3 ≈ 1.08
      final cravings = [
        ...List.generate(
            10,
            (_) => CravingEntry(
                  userId: 1,
                  timestamp: DateTime(2024, 6, 15, 10, 0),
                  intensity: 6,
                )),
        ...List.generate(
            8,
            (_) => CravingEntry(
                  userId: 1,
                  timestamp: DateTime(2024, 6, 15, 11, 0),
                  intensity: 5,
                )),
        ...List.generate(
            2,
            (_) => CravingEntry(
                  userId: 1,
                  timestamp: DateTime(2024, 6, 15, 14, 0),
                  intensity: 4,
                )),
      ];
      final result = analyzer.analyzeTimePatterns(cravings);
      expect(result.peakHour, equals(10)); // highest weighted score
      expect(result.highRiskHours, contains(10));
      expect(result.highRiskHours, contains(11));
      expect(result.summary, contains('高风险'));
    });

    test('hourlyDistribution正确记录每小时计数', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 15, 8, 0),
          intensity: 5,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 15, 8, 30),
          intensity: 6,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 15, 20, 0),
          intensity: 7,
        ),
      ];
      final result = analyzer.analyzeTimePatterns(cravings);
      expect(result.hourlyDistribution[8], equals(2));
      expect(result.hourlyDistribution[20], equals(1));
      expect(result.hourlyDistribution.length, equals(2));
    });
  });

  // ══════════════════════════════════════════════
  // analyzeDayPatterns
  // ══════════════════════════════════════════════
  group('PatternAnalyzer - analyzeDayPatterns', () {
    test('空列表返回空列表', () {
      final result = analyzer.analyzeDayPatterns([]);
      expect(result, isEmpty);
    });

    test('正确按星期分组', () {
      // 2024-06-10 is Monday, 2024-06-11 is Tuesday, 2024-06-12 is Wednesday
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 10, 0), // Monday
          intensity: 5,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 15, 0), // Monday
          intensity: 7,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 10, 0), // Tuesday
          intensity: 3,
        ),
      ];
      final result = analyzer.analyzeDayPatterns(cravings);
      expect(result.length, equals(2));
      // Should have Monday (2 cravings) and Tuesday (1 craving)
      final weekdays = result.map((p) => p.weekday).toList();
      expect(weekdays, contains('周一'));
      expect(weekdays, contains('周二'));
    });

    test('按渴望数量降序排列', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 12, 10, 0), // Wednesday
          intensity: 5,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 10, 0), // Monday
          intensity: 5,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 15, 0), // Monday
          intensity: 6,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 20, 0), // Monday
          intensity: 7,
        ),
      ];
      final result = analyzer.analyzeDayPatterns(cravings);
      expect(result.first.weekday, equals('周一'));
      expect(result.first.cravingCount, equals(3));
    });

    test('正确计算平均强度', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 10, 0), // Monday
          intensity: 4,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 15, 0), // Monday
          intensity: 8,
        ),
      ];
      final result = analyzer.analyzeDayPatterns(cravings);
      expect(result.first.avgIntensity, equals(6.0));
    });

    test('高风险天数正确标记', () {
      // 5 cravings on Monday, 1 on Tuesday
      // avgCount = 6/2 = 3, highRisk threshold = 3 * 1.3 = 3.9
      final cravings = [
        ...List.generate(
            5,
            (i) => CravingEntry(
                  userId: 1,
                  timestamp: DateTime(2024, 6, 10, i + 8, 0), // Monday
                  intensity: 5,
                )),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 10, 0), // Tuesday
          intensity: 5,
        ),
      ];
      final result = analyzer.analyzeDayPatterns(cravings);
      final monday = result.firstWhere((p) => p.weekday == '周一');
      expect(monday.isHighRisk, isTrue);
    });
  });

  // ══════════════════════════════════════════════
  // calculateMoodCravingCorrelation
  // ══════════════════════════════════════════════
  group('PatternAnalyzer - calculateMoodCravingCorrelation', () {
    test('空列表 → 0.0', () {
      final result = analyzer.calculateMoodCravingCorrelation([]);
      expect(result, equals(0.0));
    });

    test('少于3条记录 → 0.0', () {
      final logs = [
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 10),
          mood: 3,
          urgeLevel: 5,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 11),
          mood: 4,
          urgeLevel: 3,
        ),
      ];
      final result = analyzer.calculateMoodCravingCorrelation(logs);
      expect(result, equals(0.0));
    });

    test('没有urgeLevel的记录 → 0.0', () {
      final logs = [
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 10), mood: 3),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 11), mood: 4),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 12), mood: 5),
      ];
      final result = analyzer.calculateMoodCravingCorrelation(logs);
      expect(result, equals(0.0));
    });

    test('完全负相关 (mood↑ → urge↓)', () {
      // mood = [1, 2, 3], urge = [3, 2, 1]
      // meanMood=2, meanUrge=2
      // covariance = (-1)(1) + (0)(0) + (1)(-1) = -2
      // varMood = 2, varUrge = 2
      // r = -2/sqrt(4) = -1.0
      final logs = [
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 10),
          mood: 1,
          urgeLevel: 3,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 11),
          mood: 2,
          urgeLevel: 2,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 12),
          mood: 3,
          urgeLevel: 1,
        ),
      ];
      final result = analyzer.calculateMoodCravingCorrelation(logs);
      expect(result, closeTo(-1.0, 0.001));
    });

    test('完全正相关 (mood↑ → urge↑)', () {
      // mood = [1, 2, 3], urge = [1, 2, 3]
      // r = 1.0
      final logs = [
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 10),
          mood: 1,
          urgeLevel: 1,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 11),
          mood: 2,
          urgeLevel: 2,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 12),
          mood: 3,
          urgeLevel: 3,
        ),
      ];
      final result = analyzer.calculateMoodCravingCorrelation(logs);
      expect(result, closeTo(1.0, 0.001));
    });

    test('无相关性', () {
      // mood = [1, 2, 3, 4], urge = [3, 1, 4, 2]
      // meanMood=2.5, meanUrge=2.5
      // covariance = (-1.5)(0.5)+(-0.5)(-1.5)+(0.5)(1.5)+(1.5)(-0.5) = -0.75+0.75+0.75-0.75 = 0
      // r = 0
      final logs = [
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 10),
          mood: 1,
          urgeLevel: 3,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 11),
          mood: 2,
          urgeLevel: 1,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 12),
          mood: 3,
          urgeLevel: 4,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 13),
          mood: 4,
          urgeLevel: 2,
        ),
      ];
      final result = analyzer.calculateMoodCravingCorrelation(logs);
      expect(result, closeTo(0.0, 0.001));
    });

    test('结果在 [-1, 1] 范围内', () {
      final logs = List.generate(10, (i) {
        return DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 1 + i),
          mood: (i % 5) + 1,
          urgeLevel: ((i + 2) % 8) + 1,
        );
      });
      final result = analyzer.calculateMoodCravingCorrelation(logs);
      expect(result, greaterThanOrEqualTo(-1.0));
      expect(result, lessThanOrEqualTo(1.0));
    });

    test('mood相同(方差为0) → 0.0', () {
      final logs = [
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 10),
          mood: 3,
          urgeLevel: 1,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 11),
          mood: 3,
          urgeLevel: 5,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime(2024, 6, 12),
          mood: 3,
          urgeLevel: 9,
        ),
      ];
      final result = analyzer.calculateMoodCravingCorrelation(logs);
      expect(result, equals(0.0));
    });
  });

  // ══════════════════════════════════════════════
  // describeMoodCravingRelationship
  // ══════════════════════════════════════════════
  group('PatternAnalyzer - describeMoodCravingRelationship', () {
    test('无关联 (|r| < 0.2)', () {
      final result = analyzer.describeMoodCravingRelationship(0.1);
      expect(result, contains('没有明显'));
    });

    test('轻微关联 (0.2 <= |r| < 0.4)', () {
      final result = analyzer.describeMoodCravingRelationship(0.3);
      expect(result, contains('轻微'));
    });

    test('轻微负关联 (-0.4 <= r < -0.2)', () {
      final result = analyzer.describeMoodCravingRelationship(-0.3);
      expect(result, contains('轻微'));
    });

    test('负相关 (r = -0.5, -0.4 <= r <= -0.7)', () {
      final result = analyzer.describeMoodCravingRelationship(-0.5);
      expect(result, contains('负相关'));
    });

    test('强负相关 (r < -0.7)', () {
      final result = analyzer.describeMoodCravingRelationship(-0.8);
      expect(result, contains('情绪管理'));
    });

    test('正相关 (r = 0.5, 0.4 <= r <= 0.7)', () {
      final result = analyzer.describeMoodCravingRelationship(0.5);
      expect(result, contains('社交场景'));
    });

    test('强正相关 (r > 0.7)', () {
      final result = analyzer.describeMoodCravingRelationship(0.8);
      expect(result, contains('庆祝心态'));
    });

    test('零相关', () {
      final result = analyzer.describeMoodCravingRelationship(0.0);
      expect(result, contains('没有明显'));
    });

    test('中等关联 (|r| ≈ 0.4)', () {
      // abs(0.4) >= 0.4 but not < 0.2 and not < 0.4
      // Actually: absCorr=0.4 is not <0.2 and not <0.4
      // So it falls through to the < -0.4 or > 0.4 checks
      final result = analyzer.describeMoodCravingRelationship(0.4);
      // correlation > 0.4 and not > 0.7
      expect(result, contains('社交场景'));
    });
  });

  // ══════════════════════════════════════════════
  // detectTrend
  // ══════════════════════════════════════════════
  group('PatternAnalyzer - detectTrend', () {
    test('空列表 → stable', () {
      final result = analyzer.detectTrend([]);
      expect(result, equals(TrendDirection.stable));
    });

    test('少于4条记录 → stable', () {
      final logs = [
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 10), mood: 3),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 11), mood: 4),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 12), mood: 2),
      ];
      final result = analyzer.detectTrend(logs);
      expect(result, equals(TrendDirection.stable));
    });

    test('心情改善趋势 → improving', () {
      // First half: mood 1, 2 (avg 1.5)
      // Second half: mood 4, 5 (avg 4.5)
      // score = (4.5 - 1.5) * 0.4 = 1.2 > 0.3 → improving
      final logs = [
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 10), mood: 1),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 11), mood: 2),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 12), mood: 4),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 13), mood: 5),
      ];
      final result = analyzer.detectTrend(logs);
      expect(result, equals(TrendDirection.improving));
    });

    test('心情恶化趋势 → worsening', () {
      // First half: mood 4, 5 (avg 4.5)
      // Second half: mood 1, 2 (avg 1.5)
      // score = (1.5 - 4.5) * 0.4 = -1.2 < -0.3 → worsening
      final logs = [
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 10), mood: 4),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 11), mood: 5),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 12), mood: 1),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 13), mood: 2),
      ];
      final result = analyzer.detectTrend(logs);
      expect(result, equals(TrendDirection.worsening));
    });

    test('稳定趋势 → stable', () {
      // mood consistent: all 3s
      // score ≈ 0 → stable
      final logs = [
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 10), mood: 3),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 11), mood: 3),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 12), mood: 3),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 13), mood: 3),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 14), mood: 3),
        DailyLogEntry(userId: 1, date: DateTime(2024, 6, 15), mood: 3),
      ];
      final result = analyzer.detectTrend(logs);
      expect(result, equals(TrendDirection.stable));
    });

    test('复发减少 → improving', () {
      // First half: all relapsed, second half: none relapsed
      final logs = [
        DailyLogEntry(
            userId: 1,
            date: DateTime(2024, 6, 10),
            mood: 3,
            relapsed: true),
        DailyLogEntry(
            userId: 1,
            date: DateTime(2024, 6, 11),
            mood: 3,
            relapsed: true),
        DailyLogEntry(
            userId: 1,
            date: DateTime(2024, 6, 12),
            mood: 3,
            relapsed: false),
        DailyLogEntry(
            userId: 1,
            date: DateTime(2024, 6, 13),
            mood: 3,
            relapsed: false),
      ];
      // score = (0 - 1)*3.0 = -3... wait, olderRelapseRate - recentRelapseRate = 1 - 0 = 1, * 3 = 3
      // score = 0 + 0 + 3 = 3 > 0.3 → improving ✓
      final result = analyzer.detectTrend(logs);
      expect(result, equals(TrendDirection.improving));
    });

    test('渴望降低也促进改善', () {
      final logs = [
        DailyLogEntry(
            userId: 1,
            date: DateTime(2024, 6, 10),
            mood: 3,
            urgeLevel: 8),
        DailyLogEntry(
            userId: 1,
            date: DateTime(2024, 6, 11),
            mood: 3,
            urgeLevel: 7),
        DailyLogEntry(
            userId: 1,
            date: DateTime(2024, 6, 12),
            mood: 3,
            urgeLevel: 2),
        DailyLogEntry(
            userId: 1,
            date: DateTime(2024, 6, 13),
            mood: 3,
            urgeLevel: 1),
      ];
      // urge: older avg = 7.5, recent avg = 1.5
      // score = 0 + (7.5 - 1.5)*0.3 + 0 = 1.8 > 0.3 → improving
      final result = analyzer.detectTrend(logs);
      expect(result, equals(TrendDirection.improving));
    });
  });

  // ══════════════════════════════════════════════
  // detectCravingTrend
  // ══════════════════════════════════════════════
  group('PatternAnalyzer - detectCravingTrend', () {
    test('空列表 → stable', () {
      final result = analyzer.detectCravingTrend([]);
      expect(result, equals(TrendDirection.stable));
    });

    test('少于4条渴望 → stable', () {
      final now = DateTime.now();
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 1)),
          intensity: 5,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(hours: 12)),
          intensity: 6,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now,
          intensity: 4,
        ),
      ];
      final result = analyzer.detectCravingTrend(cravings);
      expect(result, equals(TrendDirection.stable));
    });

    test('渴望强度降低 → improving', () {
      final now = DateTime.now();
      // Older window (8-14 days ago): high intensity
      // Recent window (0-7 days ago): low intensity
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 13)),
          intensity: 9,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 12)),
          intensity: 8,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 11)),
          intensity: 9,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 3)),
          intensity: 2,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 2)),
          intensity: 1,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 1)),
          intensity: 2,
        ),
      ];
      final result = analyzer.detectCravingTrend(cravings);
      // older avg ≈ 8.67, recent avg ≈ 1.67, diff ≈ 7.0 > 0.8 → improving
      expect(result, equals(TrendDirection.improving));
    });

    test('渴望强度升高 → worsening', () {
      final now = DateTime.now();
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 13)),
          intensity: 1,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 12)),
          intensity: 2,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 11)),
          intensity: 1,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 3)),
          intensity: 9,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 2)),
          intensity: 8,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 1)),
          intensity: 9,
        ),
      ];
      final result = analyzer.detectCravingTrend(cravings);
      // older avg ≈ 1.33, recent avg ≈ 8.67, diff ≈ -7.33 < -0.8 → worsening
      expect(result, equals(TrendDirection.worsening));
    });

    test('所有渴望在同一窗口内 → stable', () {
      final now = DateTime.now();
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 3)),
          intensity: 5,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 2)),
          intensity: 6,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(days: 1)),
          intensity: 4,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(hours: 12)),
          intensity: 5,
        ),
      ];
      final result = analyzer.detectCravingTrend(cravings);
      // All in recent window, older is empty → stable
      expect(result, equals(TrendDirection.stable));
    });
  });

  // ══════════════════════════════════════════════
  // predictCravingLikelihood
  // ══════════════════════════════════════════════
  group('PatternAnalyzer - predictCravingLikelihood', () {
    test('空渴望列表 → 0.0', () {
      final result = analyzer.predictCravingLikelihood(14, []);
      expect(result, equals(0.0));
    });

    test('高峰时段返回更高值', () {
      // 所有渴望在下午3点
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 15, 0),
          intensity: 8,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 15, 0),
          intensity: 7,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 12, 15, 0),
          intensity: 9,
        ),
      ];
      // At hour 15: all 3 match in window, avgWindowCount = 3/3 = 1
      // probability = (1/3).clamp(0, 0.9) + (8/10)*0.1 ≈ 0.333 + 0.08 ≈ 0.413
      final peakResult = analyzer.predictCravingLikelihood(15, cravings);
      // At hour 3: no cravings nearby
      final offPeakResult = analyzer.predictCravingLikelihood(3, cravings);
      expect(peakResult, greaterThan(offPeakResult));
    });

    test('结果在 0.0-1.0 范围内', () {
      final cravings = List.generate(10, (i) {
        return CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 1 + (i ~/ 3), 14 + (i % 3), 0),
          intensity: 5 + (i % 5),
        );
      });
      for (var hour = 0; hour < 24; hour++) {
        final result = analyzer.predictCravingLikelihood(hour, cravings);
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThanOrEqualTo(1.0));
      }
    });

    test('高峰时段概率大于非高峰时段', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 15, 0),
          intensity: 8,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 15, 0),
          intensity: 8,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 12, 15, 0),
          intensity: 8,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 13, 15, 0),
          intensity: 8,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 14, 15, 0),
          intensity: 8,
        ),
      ];
      final atPeak = analyzer.predictCravingLikelihood(15, cravings);
      // Hour 15 is peak, hour 3 should have much lower
      // At 3, the wrapped diff from 15 is 12 (> windowSize 1), so 0 matches
      final offPeak = analyzer.predictCravingLikelihood(3, cravings);
      expect(atPeak, greaterThan(offPeak));
    });

    test('包裹处理 (23点和0点相邻)', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 23, 0),
          intensity: 7,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 23, 0),
          intensity: 7,
        ),
      ];
      // Hour 0 should be within window of hour 23 (wrapped diff = 1)
      final result0 = analyzer.predictCravingLikelihood(0, cravings);
      final result23 = analyzer.predictCravingLikelihood(23, cravings);
      // Both should be similar since 0 and 23 are adjacent
      expect(result0, greaterThan(0.0));
      expect(result23, greaterThan(0.0));
    });
  });

  // ══════════════════════════════════════════════
  // rankTriggers
  // ══════════════════════════════════════════════
  group('PatternAnalyzer - rankTriggers', () {
    test('空列表 → 空列表', () {
      final result = analyzer.rankTriggers([]);
      expect(result, isEmpty);
    });

    test('没有trigger的渴望 → 空列表', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 10, 0),
          intensity: 5,
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 10, 0),
          intensity: 6,
        ),
      ];
      final result = analyzer.rankTriggers(cravings);
      expect(result, isEmpty);
    });

    test('按次数降序排列', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 10, 0),
          intensity: 5,
          trigger: '压力',
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 10, 0),
          intensity: 6,
          trigger: '压力',
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 12, 10, 0),
          intensity: 7,
          trigger: '压力',
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 13, 10, 0),
          intensity: 4,
          trigger: '社交',
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 14, 10, 0),
          intensity: 5,
          trigger: '社交',
        ),
      ];
      final result = analyzer.rankTriggers(cravings);
      expect(result.length, equals(2));
      expect(result.first.trigger, equals('压力'));
      expect(result.first.count, equals(3));
      expect(result.last.trigger, equals('社交'));
      expect(result.last.count, equals(2));
    });

    test('百分比之和为1.0', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 10, 0),
          intensity: 5,
          trigger: '压力',
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 10, 0),
          intensity: 6,
          trigger: '社交',
        ),
      ];
      final result = analyzer.rankTriggers(cravings);
      final totalPercentage =
          result.fold(0.0, (sum, r) => sum + r.percentage);
      expect(totalPercentage, closeTo(1.0, 0.001));
    });

    test('avgIntensity正确计算', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 10, 0),
          intensity: 4,
          trigger: '焦虑',
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 10, 0),
          intensity: 8,
          trigger: '焦虑',
        ),
      ];
      final result = analyzer.rankTriggers(cravings);
      expect(result.first.avgIntensity, equals(6.0));
    });

    test('忽略空白trigger', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 10, 0),
          intensity: 5,
          trigger: '  ',
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 10, 0),
          intensity: 6,
          trigger: '压力',
        ),
      ];
      final result = analyzer.rankTriggers(cravings);
      expect(result.length, equals(1));
      expect(result.first.trigger, equals('压力'));
    });

    test('次数相同时按强度降序排列', () {
      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 10, 10, 0),
          intensity: 9,
          trigger: '社交',
        ),
        CravingEntry(
          userId: 1,
          timestamp: DateTime(2024, 6, 11, 10, 0),
          intensity: 3,
          trigger: '压力',
        ),
      ];
      final result = analyzer.rankTriggers(cravings);
      // Both count = 1, social has higher intensity
      expect(result.first.trigger, equals('社交'));
      expect(result.first.avgIntensity, equals(9.0));
    });
  });

  // ══════════════════════════════════════════════
  // analyzeStreak
  // ══════════════════════════════════════════════
  group('PatternAnalyzer - analyzeStreak', () {
    GameProfile createGameProfile({
      int streakDays = 0,
      int longestStreak = 0,
      DateTime? lastCheckinDate,
    }) {
      final now = DateTime.now();
      return GameProfile(
        id: 1,
        userId: 1,
        streakDays: streakDays,
        longestStreak: longestStreak,
        lastCheckinDate: lastCheckinDate ?? now,
        createdAt: now,
        updatedAt: now,
      );
    }

    User createUser({
      DateTime? quitDate,
      UserStage stage = UserStage.action,
    }) {
      final now = DateTime.now();
      return User(
        id: 1,
        targetType: TargetType.smoking,
        quitDate: quitDate,
        stage: stage,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('0天连续 → 鼓励开始', () {
      final profile = createGameProfile(streakDays: 0, longestStreak: 0);
      final user = createUser();
      final result = analyzer.analyzeStreak(
        gameProfile: profile,
        logs: [],
        user: user,
      );
      expect(result.currentStreak, equals(0));
      expect(result.continuationProbability, equals(0.5));
      expect(result.atRisk, isFalse);
      expect(result.summary, contains('还没有开始'));
    });

    test('长期连续 → 高概率', () {
      final profile = createGameProfile(
        streakDays: 60,
        longestStreak: 60,
        lastCheckinDate: DateTime.now(),
      );
      final user = createUser(
        quitDate: DateTime.now().subtract(const Duration(days: 60)),
      );
      final result = analyzer.analyzeStreak(
        gameProfile: profile,
        logs: List.generate(
            60,
            (i) => DailyLogEntry(
                  userId: 1,
                  date: DateTime.now().subtract(Duration(days: 60 - i)),
                  mood: 4,
                )),
        user: user,
      );
      expect(result.currentStreak, equals(60));
      expect(result.continuationProbability, greaterThan(0.5));
      expect(result.summary, contains('60'));
    });

    test('长期连续且创新纪录 → 特殊消息', () {
      final profile = createGameProfile(
        streakDays: 50,
        longestStreak: 50,
        lastCheckinDate: DateTime.now(),
      );
      final user = createUser(
        quitDate: DateTime.now().subtract(const Duration(days: 50)),
      );
      final result = analyzer.analyzeStreak(
        gameProfile: profile,
        logs: List.generate(
            50,
            (i) => DailyLogEntry(
                  userId: 1,
                  date: DateTime.now().subtract(Duration(days: 50 - i)),
                  mood: 4,
                )),
        user: user,
      );
      expect(result.summary, contains('创造新的记录'));
    });

    test('早期阶段低心情 → atRisk', () {
      final profile = createGameProfile(
        streakDays: 5,
        longestStreak: 10,
        lastCheckinDate: DateTime.now(),
      );
      final user = createUser(
        quitDate: DateTime.now().subtract(const Duration(days: 5)),
      );
      final logs = [
        DailyLogEntry(
          userId: 1,
          date: DateTime.now().subtract(const Duration(days: 2)),
          mood: 1,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime.now().subtract(const Duration(days: 1)),
          mood: 2,
        ),
        DailyLogEntry(
          userId: 1,
          date: DateTime.now(),
          mood: 1,
        ),
      ];
      final result = analyzer.analyzeStreak(
        gameProfile: profile,
        logs: logs,
        user: user,
      );
      expect(result.atRisk, isTrue);
      expect(result.summary, contains('挑战'));
    });

    test('continuationProbability在合理范围内', () {
      final profile = createGameProfile(streakDays: 10);
      final user = createUser(
        quitDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      final result = analyzer.analyzeStreak(
        gameProfile: profile,
        logs: [
          DailyLogEntry(
            userId: 1,
            date: DateTime.now().subtract(const Duration(days: 1)),
            mood: 3,
          ),
        ],
        user: user,
      );
      expect(result.continuationProbability, greaterThanOrEqualTo(0.1));
      expect(result.continuationProbability, lessThanOrEqualTo(0.99));
    });
  });

  // ══════════════════════════════════════════════
  // calculateLocalRiskScore
  // ══════════════════════════════════════════════
  group('PatternAnalyzer - calculateLocalRiskScore', () {
    GameProfile createGameProfile({
      int streakDays = 0,
      DateTime? lastCheckinDate,
    }) {
      final now = DateTime.now();
      return GameProfile(
        id: 1,
        userId: 1,
        streakDays: streakDays,
        lastCheckinDate: lastCheckinDate ?? now,
        createdAt: now,
        updatedAt: now,
      );
    }

    User createUser({int? daysSinceQuit}) {
      final now = DateTime.now();
      return User(
        id: 1,
        targetType: TargetType.smoking,
        quitDate: daysSinceQuit != null
            ? now.subtract(Duration(days: daysSinceQuit))
            : null,
        stage: UserStage.action,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('刚戒烟(第0天) → 基础风险较高', () {
      final user = createUser(daysSinceQuit: 0);
      final profile = createGameProfile();
      final result = analyzer.calculateLocalRiskScore(
        user: user,
        gameProfile: profile,
        todayLog: null,
        recentLogs: [],
        recentCravings: [],
      );
      // days == 0 → +20 points (base)
      expect(result, greaterThanOrEqualTo(20));
      expect(result, lessThanOrEqualTo(100));
    });

    test('第3天 → 急性戒断期风险', () {
      final user = createUser(daysSinceQuit: 3);
      final profile = createGameProfile();
      final result = analyzer.calculateLocalRiskScore(
        user: user,
        gameProfile: profile,
        todayLog: null,
        recentLogs: [],
        recentCravings: [],
      );
      // days <= 3 → +18 points (base)
      expect(result, greaterThanOrEqualTo(18));
      expect(result, lessThanOrEqualTo(100));
    });

    test('第30天 → 中等风险', () {
      final user = createUser(daysSinceQuit: 30);
      final profile = createGameProfile();
      final result = analyzer.calculateLocalRiskScore(
        user: user,
        gameProfile: profile,
        todayLog: null,
        recentLogs: [],
        recentCravings: [],
      );
      // days <= 30 → +6 points (base)
      expect(result, greaterThanOrEqualTo(6));
      expect(result, lessThanOrEqualTo(100));
    });

    test('第30天风险低于第3天', () {
      final userDay3 = createUser(daysSinceQuit: 3);
      final userDay30 = createUser(daysSinceQuit: 30);
      final profile = createGameProfile();

      final resultDay3 = analyzer.calculateLocalRiskScore(
        user: userDay3,
        gameProfile: profile,
        todayLog: null,
        recentLogs: [],
        recentCravings: [],
      );
      final resultDay30 = analyzer.calculateLocalRiskScore(
        user: userDay30,
        gameProfile: profile,
        todayLog: null,
        recentLogs: [],
        recentCravings: [],
      );
      expect(resultDay30, lessThan(resultDay3));
    });

    test('有复发记录 → 风险增加', () {
      final user = createUser(daysSinceQuit: 10);
      final profile = createGameProfile();
      final now = DateTime.now();
      final logs = [
        DailyLogEntry(
          userId: 1,
          date: now,
          mood: 3,
          relapsed: true,
        ),
      ];
      final result = analyzer.calculateLocalRiskScore(
        user: user,
        gameProfile: profile,
        todayLog: null,
        recentLogs: logs,
        recentCravings: [],
      );
      // days <= 14 → +10, relapse within 1 day → +15
      expect(result, greaterThanOrEqualTo(25));
    });

    test('坏心情增加风险', () {
      final user = createUser(daysSinceQuit: 10);
      final profile = createGameProfile();
      final now = DateTime.now();

      // 好心情
      final goodMoodLog = DailyLogEntry(
        userId: 1,
        date: now,
        mood: 5,
      );
      // 坏心情
      final badMoodLog = DailyLogEntry(
        userId: 1,
        date: now,
        mood: 1,
      );

      final resultGood = analyzer.calculateLocalRiskScore(
        user: user,
        gameProfile: profile,
        todayLog: goodMoodLog,
        recentLogs: [],
        recentCravings: [],
      );
      final resultBad = analyzer.calculateLocalRiskScore(
        user: user,
        gameProfile: profile,
        todayLog: badMoodLog,
        recentLogs: [],
        recentCravings: [],
      );
      // mood 5: (5-5)*3 = 0 extra
      // mood 1: (5-1)*3 = 12 extra
      expect(resultBad, greaterThan(resultGood));
    });

    test('近期强烈渴望增加风险', () {
      final user = createUser(daysSinceQuit: 10);
      final profile = createGameProfile();
      final now = DateTime.now();

      final cravings = [
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(hours: 6)),
          intensity: 9,
        ),
        CravingEntry(
          userId: 1,
          timestamp: now.subtract(const Duration(hours: 12)),
          intensity: 8,
        ),
      ];
      final result = analyzer.calculateLocalRiskScore(
        user: user,
        gameProfile: profile,
        todayLog: null,
        recentLogs: [],
        recentCravings: cravings,
      );
      // days 10 → +10, cravings avg 8.5 → (8.5/10)*20 = 17
      expect(result, greaterThan(10));
    });

    test('结果在 0-100 范围内', () {
      final user = createUser(daysSinceQuit: 0);
      final profile = createGameProfile();
      final now = DateTime.now();

      final worstCaseLogs = List.generate(
          10,
          (i) => DailyLogEntry(
                userId: 1,
                date: now.subtract(Duration(days: i)),
                mood: 1,
                relapsed: true,
                urgeLevel: 10,
              ));
      final worstCaseCravings = List.generate(
          20,
          (i) => CravingEntry(
                userId: 1,
                timestamp: now.subtract(Duration(hours: i)),
                intensity: 10,
              ));

      final result = analyzer.calculateLocalRiskScore(
        user: user,
        gameProfile: profile,
        todayLog: DailyLogEntry(
          userId: 1,
          date: now,
          mood: 1,
          urgeLevel: 10,
        ),
        recentLogs: worstCaseLogs,
        recentCravings: worstCaseCravings,
      );
      expect(result, greaterThanOrEqualTo(0));
      expect(result, lessThanOrEqualTo(100));
    });

    test('多次复发大幅增加风险', () {
      final user = createUser(daysSinceQuit: 10);
      final profile = createGameProfile();
      final now = DateTime.now();

      final logs = [
        DailyLogEntry(
          userId: 1,
          date: now,
          mood: 3,
          relapsed: true,
        ),
        DailyLogEntry(
          userId: 1,
          date: now.subtract(const Duration(days: 1)),
          mood: 3,
          relapsed: true,
        ),
        DailyLogEntry(
          userId: 1,
          date: now.subtract(const Duration(days: 2)),
          mood: 3,
          relapsed: true,
        ),
      ];
      final result = analyzer.calculateLocalRiskScore(
        user: user,
        gameProfile: profile,
        todayLog: null,
        recentLogs: logs,
        recentCravings: [],
      );
      // 3 relapses → +25 points
      expect(result, greaterThanOrEqualTo(35));
    });
  });

  // ══════════════════════════════════════════════
  // TimePattern.formatHour
  // ══════════════════════════════════════════════
  group('TimePattern - formatHour', () {
    test('0点 → 午夜12点', () {
      expect(TimePattern.formatHour(0), equals('午夜12点'));
    });

    test('24点 → 午夜12点', () {
      expect(TimePattern.formatHour(24), equals('午夜12点'));
    });

    test('凌晨时段 (1-5)', () {
      for (var h = 1; h <= 5; h++) {
        expect(TimePattern.formatHour(h), contains('凌晨'));
      }
    });

    test('上午时段 (6-11)', () {
      for (var h = 6; h <= 11; h++) {
        expect(TimePattern.formatHour(h), contains('上午'));
      }
    });

    test('中午12点', () {
      expect(TimePattern.formatHour(12), equals('中午12点'));
    });

    test('下午时段 (13-17)', () {
      for (var h = 13; h <= 17; h++) {
        expect(TimePattern.formatHour(h), contains('下午'));
      }
    });

    test('晚上时段 (18-23)', () {
      for (var h = 18; h <= 23; h++) {
        expect(TimePattern.formatHour(h), contains('晚上'));
      }
    });
  });
}
