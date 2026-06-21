/// Relapse risk assessment engine.
///
/// Evaluates a daily "relapse risk score" (0-100) from multiple weighted
/// factors: streak, recent cravings, mood, exercise, trigger exposure,
/// time since quit, and social context.
///
/// Pure Dart — zero external dependencies. Fully unit-testable.

import 'dart:math';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';

// Re-export CravingEntry for convenience.
export '../../domain/entity/user.dart' show CravingEntry;

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

/// Full relapse risk assessment result.
class RelapseRiskAssessment {
  /// Overall risk score 0-100.
  final int overallScore;

  /// Classified risk level.
  final RiskLevel level;

  /// Chinese human-readable summary.
  final String summary;

  /// Individual factor breakdown.
  final List<RiskFactor> factors;

  /// Actionable suggestions.
  final List<String> suggestions;

  /// When this assessment was generated.
  final DateTime assessedAt;

  const RelapseRiskAssessment({
    required this.overallScore,
    required this.level,
    required this.summary,
    required this.factors,
    required this.suggestions,
    required this.assessedAt,
  });
}

/// A single risk factor with its sub-score and weight.
class RiskFactor {
  /// Display name in Chinese (e.g. "连胜天数", "近期渴望频率").
  final String name;

  /// Sub-score 0-100 for this factor alone.
  final double score;

  /// Relative weight (0.0-1.0). All weights sum to 1.0.
  final double weight;

  /// Chinese description of why this factor has this score.
  final String description;

  /// Icon name from Material icons.
  final String icon;

  const RiskFactor({
    required this.name,
    required this.score,
    required this.weight,
    required this.description,
    this.icon = 'info_outline',
  });
}

/// Risk level classification.
enum RiskLevel {
  /// 0-25: low risk (green).
  low,

  /// 26-50: moderate risk (yellow).
  moderate,

  /// 51-75: high risk (orange).
  high,

  /// 76-100: critical risk (red).
  critical,
}

// ─────────────────────────────────────────────────────────────────────────────
// RelapseRiskEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Multi-factor relapse risk assessment engine.
///
/// Produces a [RelapseRiskAssessment] from user data. Each factor has a
/// configurable weight (tuned via static constants) and produces a
/// sub-score 0-100. The final score is a weighted sum.
///
/// Usage:
/// ```dart
/// final engine = RelapseRiskEngine();
/// final assessment = engine.assess(
///   user: user,
///   gameProfile: profile,
///   recentCravings: cravings,
///   recentLogs: logs,
/// );
/// ```
class RelapseRiskEngine {
  // ── Configurable factor weights ────────────────────────────────────────
  // Sum to 1.0. Adjust these to tune the model.

  /// Weight for streak-related risk.
  static const double weightStreak = 0.15;

  /// Weight for recent craving frequency & intensity.
  static const double weightCraving = 0.25;

  /// Weight for mood factor.
  static const double weightMood = 0.15;

  /// Weight for exercise / CBT engagement.
  static const double weightExercise = 0.10;

  /// Weight for trigger exposure.
  static const double weightTrigger = 0.15;

  /// Weight for time since quit (early days are highest risk).
  static const double weightTimeSinceQuit = 0.10;

  /// Weight for social context risk.
  static const double weightSocialContext = 0.10;

  // ── Thresholds ──────────────────────────────────────────────────────────
  static const int _lowThreshold = 25;
  static const int _moderateThreshold = 50;
  static const int _highThreshold = 75;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Assess relapse risk from the given data.
  ///
  /// [todayLog] is optional but improves mood assessment when present.
  /// [cravingPrediction] is optional — when provided, high-risk windows
  /// and trigger analysis enrich the assessment.
  RelapseRiskAssessment assess({
    required User user,
    required GameProfile gameProfile,
    required List<CravingEntry> recentCravings,
    required List<DailyLogEntry> recentLogs,
    DailyLogEntry? todayLog,
  }) {
    final factors = <RiskFactor>[];

    // 1. Streak factor
    factors.add(_streakFactor(gameProfile, recentLogs));

    // 2. Recent craving factor
    factors.add(_cravingFactor(recentCravings));

    // 3. Mood factor
    factors.add(_moodFactor(recentLogs, todayLog));

    // 4. Exercise factor
    factors.add(_exerciseFactor(gameProfile, recentLogs));

    // 5. Trigger factor
    factors.add(_triggerFactor(recentCravings));

    // 6. Time since quit factor
    factors.add(_timeSinceQuitFactor(user));

    // 7. Social context factor
    factors.add(_socialContextFactor(recentCravings));

    // ── Weighted sum ─────────────────────────────────────────────────────
    final weights = [
      weightStreak,
      weightCraving,
      weightMood,
      weightExercise,
      weightTrigger,
      weightTimeSinceQuit,
      weightSocialContext,
    ];

    double totalScore = 0;
    for (var i = 0; i < factors.length; i++) {
      totalScore += factors[i].score * weights[i];
    }

    final overallScore = totalScore.round().clamp(0, 100);
    final level = _classifyLevel(overallScore);
    final summary = _buildSummary(level, overallScore, factors);
    final suggestions = _buildSuggestions(level, factors);

    return RelapseRiskAssessment(
      overallScore: overallScore,
      level: level,
      summary: summary,
      factors: factors,
      suggestions: suggestions,
      assessedAt: DateTime.now(),
    );
  }

  // ── Factor: Streak ─────────────────────────────────────────────────────
  //
  // Longer streak → lower risk. But streak at risk of breaking adds risk.

  RiskFactor _streakFactor(
    GameProfile profile,
    List<DailyLogEntry> logs,
  ) {
    final streak = profile.streakDays;
    final longest = profile.longestStreak;

    double score;

    if (streak == 0) {
      // No active streak — moderate-to-high risk.
      score = 60;
    } else if (streak >= 30) {
      // Well-established habit — very low risk.
      score = 10;
    } else if (streak >= 14) {
      score = 20;
    } else if (streak >= 7) {
      score = 30;
    } else if (streak >= 3) {
      score = 45;
    } else {
      score = 55;
    }

    // Penalty if streak is about to break (no check-in yesterday or today).
    if (streak > 0) {
      final lastCheckin = profile.lastCheckinDate;
      if (lastCheckin != null) {
        final now = DateTime.now();
        final lastDay = DateTime(lastCheckin.year, lastCheckin.month, lastCheckin.day);
        final today = DateTime(now.year, now.month, now.day);
        final daysSince = today.difference(lastDay).inDays;

        if (daysSince >= 2) {
          score = (score + 30).clamp(0.0, 100.0);
        } else if (daysSince == 1) {
          score = (score + 15).clamp(0.0, 100.0);
        }
      }
    }

    // Bonus protection if current streak is the longest ever.
    if (streak > 0 && streak >= longest && longest > 0) {
      score = (score - 5).clamp(0.0, 100.0);
    }

    // Historical relapse rate — if user has relapsed frequently, higher risk.
    if (logs.length >= 7) {
      final recentWeek = logs.length >= 7 ? logs.sublist(logs.length - 7) : logs;
      final relapseCount = recentWeek.where((l) => l.relapsed).length;
      if (relapseCount >= 3) {
        score = (score + 20).clamp(0.0, 100.0);
      } else if (relapseCount >= 1) {
        score = (score + 8).clamp(0.0, 100.0);
      }
    }

    final description = score < 25
        ? '连续打卡 $streak 天，状态稳定'
        : score < 50
            ? streak > 0
                ? '连续 $streak 天打卡，继续保持'
                : '尚未建立连续打卡习惯'
            : streak > 0
                ? '连续 $streak 天，但可能面临打卡中断风险'
                : '缺少连续打卡记录';

    return RiskFactor(
      name: '连胜天数',
      score: score,
      weight: weightStreak,
      description: description,
      icon: 'local_fire_department',
    );
  }

  // ── Factor: Recent cravings ────────────────────────────────────────────

  RiskFactor _cravingFactor(List<CravingEntry> cravings) {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Count and intensity in last 3 days.
    final veryRecent =
        cravings.where((c) => c.timestamp.isAfter(threeDaysAgo)).toList();
    final weekRecent =
        cravings.where((c) => c.timestamp.isAfter(sevenDaysAgo)).toList();

    double score = 0;

    // Frequency component (0-50 points).
    if (veryRecent.isNotEmpty) {
      final dailyRate = veryRecent.length / 3.0;
      score += (dailyRate * 8).clamp(0, 50);
    }

    // Intensity component (0-30 points).
    if (veryRecent.isNotEmpty) {
      final avgIntensity =
          veryRecent.map((c) => c.intensity.toDouble()).reduce((a, b) => a + b) /
              veryRecent.length;
      score += (avgIntensity / 10.0) * 30;
    }

    // Recency spike — more cravings in the last day than the preceding 2.
    if (weekRecent.length >= 3) {
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final lastDayCount =
          weekRecent.where((c) => c.timestamp.isAfter(oneDayAgo)).length;
      final precedingCount =
          weekRecent.where((c) => !c.timestamp.isAfter(oneDayAgo)).length;

      if (precedingCount > 0 && lastDayCount > precedingCount * 1.5) {
        score = (score + 15).clamp(0.0, 100.0);
      }
    }

    // Unresolved cravings add risk (0-20 points).
    if (veryRecent.isNotEmpty) {
      final unresolvedRate =
          veryRecent.where((c) => !c.resolved).length / veryRecent.length;
      score += unresolvedRate * 20;
    }

    score = score.clamp(0.0, 100.0);

    final description = score < 25
        ? '近期渴望频率低，控制良好'
        : score < 50
            ? '近期有一定渴望，基本可控'
            : score < 75
                ? '近期渴望频繁，需要加强应对'
                : '近期渴望非常频繁且强烈，需格外警惕';

    return RiskFactor(
      name: '近期渴望频率',
      score: score,
      weight: weightCraving,
      description: description,
      icon: 'flash_on',
    );
  }

  // ── Factor: Mood ───────────────────────────────────────────────────────

  RiskFactor _moodFactor(
    List<DailyLogEntry> logs,
    DailyLogEntry? todayLog,
  ) {
    double score = 0;

    // Today's mood (1-5).
    if (todayLog != null) {
      // Lower mood → higher risk.
      score += (5 - todayLog.mood) * 10;

      // Today's urge level adds risk.
      if (todayLog.urgeLevel != null && todayLog.urgeLevel! > 0) {
        score += todayLog.urgeLevel! * 3;
      }
    } else {
      // No log today — slight uncertainty penalty.
      score += 10;
    }

    // Recent mood trend (last 5 days).
    if (logs.length >= 3) {
      final recentSlice =
          logs.length >= 5 ? logs.sublist(logs.length - 5) : logs;
      final avgMood =
          recentSlice.map((l) => l.mood.toDouble()).reduce((a, b) => a + b) /
              recentSlice.length;

      if (avgMood < 2.0) {
        score += 30;
      } else if (avgMood < 2.5) {
        score += 20;
      } else if (avgMood < 3.0) {
        score += 10;
      }
      // Mood >= 3 is neutral/positive — no extra risk.
    }

    // Mood volatility — highly variable mood is a risk indicator.
    if (logs.length >= 5) {
      final recentSlice = logs.sublist(logs.length - 5);
      final moods = recentSlice.map((l) => l.mood.toDouble()).toList();
      final mean = moods.reduce((a, b) => a + b) / moods.length;
      final variance =
          moods.map((m) => (m - mean) * (m - mean)).reduce((a, b) => a + b) /
              moods.length;
      final stdDev = sqrt(variance);

      if (stdDev > 1.3) {
        score += 15;
      } else if (stdDev > 0.8) {
        score += 8;
      }
    }

    score = score.clamp(0.0, 100.0);

    final description = score < 25
        ? '心情稳定，情绪管理良好'
        : score < 50
            ? '心情一般，注意调节情绪'
            : score < 75
                ? '近期情绪波动较大，建议多做放松练习'
                : '情绪状态堪忧，建议立即寻求支持';

    return RiskFactor(
      name: '心情状态',
      score: score,
      weight: weightMood,
      description: description,
      icon: 'sentiment_satisfied',
    );
  }

  // ── Factor: Exercise / CBT engagement ──────────────────────────────────
  //
  // More exercises completed → lower risk (protective factor).

  RiskFactor _exerciseFactor(
    GameProfile profile,
    List<DailyLogEntry> logs,
  ) {
    // Score is inverted — more exercise = lower risk score.
    // Uses total exercises completed as a general indicator.
    final exercisesTotal = profile.exercisesCompleted;
    double protection = 0;

    if (exercisesTotal >= 50) {
      protection = 40;
    } else if (exercisesTotal >= 30) {
      protection = 30;
    } else if (exercisesTotal >= 15) {
      protection = 20;
    } else if (exercisesTotal >= 5) {
      protection = 10;
    } else {
      protection = 0;
    }

    // Recent exercise — check if the user has done exercises in the last 3 days.
    // Since we don't have per-exercise timestamps, use cravings resisted as
    // a proxy for engagement.
    final engagementBonus = min(profile.cravingsResisted * 0.3, 15);
    protection += engagementBonus;

    final score = (100 - protection).clamp(0.0, 100.0);

    final description = score < 25
        ? '已完成 $exercisesTotal 个练习，防护充足'
        : score < 50
            ? '已完成 $exercisesTotal 个练习，建议多做几个'
            : score < 75
                ? '练习完成量偏少，建议每天完成至少一个练习'
                : '尚未开始练习，强烈建议尝试CBT练习';

    return RiskFactor(
      name: '练习完成度',
      score: score,
      weight: weightExercise,
      description: description,
      icon: 'self_improvement',
    );
  }

  // ── Factor: Trigger exposure ───────────────────────────────────────────
  //
  // Recent high-risk triggers increase risk.

  RiskFactor _triggerFactor(List<CravingEntry> cravings) {
    if (cravings.isEmpty) {
      return const RiskFactor(
        name: '触发因素',
        score: 10,
        weight: weightTrigger,
        description: '暂无触发因素数据',
        icon: 'warning_amber',
      );
    }

    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final recent = cravings.where((c) => c.timestamp.isAfter(threeDaysAgo)).toList();

    if (recent.isEmpty) {
      return const RiskFactor(
        name: '触发因素',
        score: 15,
        weight: weightTrigger,
        description: '近三天无触发因素记录',
        icon: 'warning_amber',
      );
    }

    // Analyze triggers in recent cravings.
    final triggerCounts = <String, int>{};
    final triggerIntensity = <String, double>{};

    for (final c in recent) {
      final t = c.trigger?.trim();
      if (t == null || t.isEmpty) continue;
      triggerCounts[t] = (triggerCounts[t] ?? 0) + 1;
      triggerIntensity[t] = (triggerIntensity[t] ?? 0) + c.intensity;
    }

    if (triggerCounts.isEmpty) {
      return const RiskFactor(
        name: '触发因素',
        score: 20,
        weight: weightTrigger,
        description: '近三天有渴望但未标注触发因素',
        icon: 'warning_amber',
      );
    }

    // Score based on: frequency × average intensity of recent triggers.
    double maxRisk = 0;
    for (final entry in triggerCounts.entries) {
      final avgIntensity = (triggerIntensity[entry.key] ?? 0) / entry.value;
      final risk = entry.value * avgIntensity;
      if (risk > maxRisk) maxRisk = risk;
    }

    // Normalize: 1 craving × intensity 5 ≈ baseline, scale to 0-100.
    final score = (maxRisk / 20.0 * 100).clamp(0.0, 100.0);

    final description = score < 25
        ? '近期触发因素影响较小'
        : score < 50
            ? '近期有一定触发因素暴露'
            : score < 75
                ? '近期频繁遇到高风险触发因素'
                : '触发因素风险极高，建议主动避开';

    return RiskFactor(
      name: '触发因素',
      score: score,
      weight: weightTrigger,
      description: description,
      icon: 'warning_amber',
    );
  }

  // ── Factor: Time since quit ────────────────────────────────────────────
  //
  // First 2 weeks highest risk, then gradually decreasing.

  RiskFactor _timeSinceQuitFactor(User user) {
    final days = user.daysSinceQuit;

    double score;
    if (days == 0) {
      score = 80; // Haven't started yet — highest risk.
    } else if (days <= 3) {
      score = 85; // Acute withdrawal.
    } else if (days <= 7) {
      score = 70;
    } else if (days <= 14) {
      score = 55;
    } else if (days <= 21) {
      score = 40;
    } else if (days <= 30) {
      score = 30;
    } else if (days <= 60) {
      score = 20;
    } else if (days <= 90) {
      score = 12;
    } else {
      score = 5; // Very low risk from time perspective alone.
    }

    // Addiction severity modifier (Fagerström / AUDIT).
    final severityScore = user.fagerstromScore ?? user.auditScore ?? 0;
    if (severityScore >= 8) {
      score = (score + 10).clamp(0.0, 100.0);
    } else if (severityScore >= 5) {
      score = (score + 5).clamp(0.0, 100.0);
    }

    final description = score >= 60
        ? '戒断初期（第 $days 天），身体和心理适应中'
        : score >= 30
            ? '戒断第 $days 天，逐渐适应但仍需警惕'
            : '戒断第 $days 天，已度过最艰难的阶段';

    return RiskFactor(
      name: '戒断阶段',
      score: score,
      weight: weightTimeSinceQuit,
      description: description,
      icon: 'schedule',
    );
  }

  // ── Factor: Social context ─────────────────────────────────────────────
  //
  // Social situations without coping plan = higher risk.

  RiskFactor _socialContextFactor(List<CravingEntry> cravings) {
    if (cravings.isEmpty) {
      return const RiskFactor(
        name: '社交情境',
        score: 15,
        weight: weightSocialContext,
        description: '暂无社交情境数据',
        icon: 'groups',
      );
    }

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent =
        cravings.where((c) => c.timestamp.isAfter(weekAgo)).toList();

    // Count cravings in social contexts.
    final socialCravings = recent.where((c) {
      final social = c.socialContext?.trim().toLowerCase() ?? '';
      return social.isNotEmpty &&
          (social.contains('朋友') ||
              social.contains('聚会') ||
              social.contains('社交') ||
              social.contains('party') ||
              social.contains('同事') ||
              social.contains('饮酒') ||
              social == 'alone');
    }).toList();

    if (socialCravings.isEmpty) {
      return const RiskFactor(
        name: '社交情境',
        score: 20,
        weight: weightSocialContext,
        description: '近一周无高风险社交情境',
        icon: 'groups',
      );
    }

    // Score based on how many social-context cravings and their intensity.
    final avgIntensity = socialCravings.map((c) => c.intensity.toDouble()).reduce(
            (a, b) => a + b) /
        socialCravings.length;

    final unresolvedSocial =
        socialCravings.where((c) => !c.resolved).length / socialCravings.length;

    var score = (avgIntensity / 10.0) * 50 + unresolvedSocial * 40 + socialCravings.length * 5;
    score = score.clamp(0.0, 100.0);

    final description = score < 25
        ? '社交情境中的渴望控制良好'
        : score < 50
            ? '社交场合有轻微渴望风险'
            : score < 75
                ? '社交情境中渴望较强，建议制定应对计划'
                : '社交情境风险很高，建议减少暴露';

    return RiskFactor(
      name: '社交情境',
      score: score,
      weight: weightSocialContext,
      description: description,
      icon: 'groups',
    );
  }

  // ── Level classification ────────────────────────────────────────────────

  RiskLevel _classifyLevel(int score) {
    if (score <= _lowThreshold) return RiskLevel.low;
    if (score <= _moderateThreshold) return RiskLevel.moderate;
    if (score <= _highThreshold) return RiskLevel.high;
    return RiskLevel.critical;
  }

  // ── Summary generation ─────────────────────────────────────────────────

  String _buildSummary(
    RiskLevel level,
    int score,
    List<RiskFactor> factors,
  ) {
    // Find the highest-scoring factor for personalization.
    final topFactor = factors.reduce(
      (a, b) => a.score * a.weight > b.score * b.weight ? a : b,
    );

    switch (level) {
      case RiskLevel.low:
        return '状态很好，继续保持！综合风险评分 $score 分。';
      case RiskLevel.moderate:
        return '注意观察，保持警惕。主要影响因素：${topFactor.name}。'
            '综合风险评分 $score 分。';
      case RiskLevel.high:
        return '建议多做几个练习，保持警惕。'
            '当前最突出的风险来自「${topFactor.name}」。'
            '综合风险评分 $score 分。';
      case RiskLevel.critical:
        return '建议立即使用呼吸放松或联系教练。'
            '「${topFactor.name}」风险极高，需要立即应对。'
            '综合风险评分 $score 分。';
    }
  }

  // ── Suggestion generation ────────────────────────────────────────────────

  List<String> _buildSuggestions(RiskLevel level, List<RiskFactor> factors) {
    final suggestions = <String>[];

    // Always add a level-based primary suggestion.
    switch (level) {
      case RiskLevel.low:
        suggestions.add('状态很好，继续保持！坚持每日打卡和练习。');
        break;
      case RiskLevel.moderate:
        suggestions.add('注意观察，保持警惕。可以做一个呼吸放松练习。');
        break;
      case RiskLevel.high:
        suggestions.add('建议多做几个练习，保持警惕。');
        break;
      case RiskLevel.critical:
        suggestions.add('建议立即使用呼吸放松或联系教练。');
        break;
    }

    // Add factor-specific suggestions for the top 2 risk factors.
    final sortedFactors = List<RiskFactor>.from(factors)
      ..sort((a, b) => (b.score * b.weight).compareTo(a.score * a.weight));

    for (var i = 0; i < min(2, sortedFactors.length); i++) {
      final factor = sortedFactors[i];
      if (factor.score < 30) continue; // Skip low-risk factors.

      suggestions.add(_factorSuggestion(factor));
    }

    // De-duplicate and cap at 4 suggestions.
    final unique = suggestions.toSet().toList();
    return unique.length > 4 ? unique.sublist(0, 4) : unique;
  }

  String _factorSuggestion(RiskFactor factor) {
    switch (factor.name) {
      case '连胜天数':
        return '今天记得打卡，保持连胜纪录！';
      case '近期渴望频率':
        return '遇到渴望时，尝试使用4-7-8呼吸法或延迟策略。';
      case '心情状态':
        return '心情低落时容易复发，建议做正念练习或散步放松。';
      case '练习完成度':
        return '完成CBT练习可以增强心理韧性，降低复发风险。';
      case '触发因素':
        return '识别并避开高风险触发因素，提前制定应对计划。';
      case '戒断阶段':
        return '戒断初期身体正在适应，保持耐心，症状会逐渐减轻。';
      case '社交情境':
        return '社交场合提前准备好拒绝话术，或选择不饮酒的聚会。';
      default:
        return '保持警惕，坚持记录。';
    }
  }
}

