import 'dart:math';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/analysis.dart';

/// Local pattern analyzer that works 100% offline without any API calls.
///
/// Uses statistical methods to detect patterns in user behavior data:
/// - Time-of-day craving patterns
/// - Day-of-week patterns
/// - Mood-craving correlation
/// - Trigger frequency ranking
/// - Trend detection (improving/stable/worsening)
/// - Streak analysis with continuation prediction
class PatternAnalyzer {
  // ---- Time-of-Day Analysis ----

  /// Detect time-of-day patterns in cravings.
  ///
  /// Returns a [TimePattern] with peak hour, high-risk hours, and summary.
  /// If [cravings] is empty, returns a neutral default pattern.
  TimePattern analyzeTimePatterns(List<CravingEntry> cravings) {
    if (cravings.isEmpty) {
      return const TimePattern(
        peakHour: -1,
        peakIntensity: 0,
        highRiskHours: [],
        summary: '暂无足够数据来分析时间模式',
      );
    }

    // Build hourly distribution: hour -> {count, totalIntensity}
    final hourlyData = <int, _HourData>{};
    for (final c in cravings) {
      final hour = c.timestamp.hour;
      final existing = hourlyData[hour] ?? const _HourData();
      hourlyData[hour] = existing.copyWith(
        count: existing.count + 1,
        totalIntensity: existing.totalIntensity + c.intensity,
      );
    }

    // Calculate average count to determine "high risk"
    final totalCravings = cravings.length;
    final avgPerHour = totalCravings / 24;

    // Find peak hour by weighted score (count * intensity)
    int peakHour = 0;
    double peakScore = -1;
    double peakIntensity = 0;
    final hourlyCountMap = <int, int>{};

    for (final entry in hourlyData.entries) {
      final hour = entry.key;
      final data = entry.value;
      final score = data.count * data.avgIntensity;
      hourlyCountMap[hour] = data.count;

      if (score > peakScore) {
        peakScore = score;
        peakHour = hour;
        peakIntensity = data.avgIntensity;
      }
    }

    // Find high-risk hours (above average craving count)
    final highRiskHours = <int>[];
    for (final entry in hourlyData.entries) {
      if (entry.value.count >= avgPerHour * 1.3) {
        highRiskHours.add(entry.key);
      }
    }
    highRiskHours.sort();

    // Generate summary
    final summary = _buildTimePatternSummary(
      peakHour: peakHour,
      peakIntensity: peakIntensity,
      highRiskHours: highRiskHours,
      totalCravings: totalCravings,
      hourlyData: hourlyData,
    );

    return TimePattern(
      peakHour: peakHour,
      peakIntensity: peakIntensity,
      highRiskHours: highRiskHours,
      summary: summary,
      hourlyDistribution: hourlyCountMap,
    );
  }

  String _buildTimePatternSummary({
    required int peakHour,
    required double peakIntensity,
    required List<int> highRiskHours,
    required int totalCravings,
    required Map<int, _HourData> hourlyData,
  }) {
    final peakTimeStr = TimePattern.formatHour(peakHour);

    // Check if there's a concentration pattern (cravings in a short window)
    if (highRiskHours.length >= 3) {
      final span = highRiskHours.last - highRiskHours.first;
      if (span <= 4) {
        return '你的渴望高度集中在${TimePattern.formatHour(highRiskHours.first)}'
            '到${TimePattern.formatHour(highRiskHours.last)}之间，'
            '峰值出现在$peakTimeStr（平均强度 ${peakIntensity.toStringAsFixed(1)}）。'
            '建议在这个时段提前做好应对准备。';
      }
    }

    if (highRiskHours.length >= 2) {
      final times =
          highRiskHours.take(3).map((h) => TimePattern.formatHour(h)).join('、');
      return '你的高风险时段主要集中在$times，其中$peakTimeStr最为突出'
          '（平均强度 ${peakIntensity.toStringAsFixed(1)}）。'
          '在这些时段特别要警惕。';
    }

    return '你的渴望峰值出现在$peakTimeStr，'
        '平均强度 ${peakIntensity.toStringAsFixed(1)}。'
        '共记录了$totalCravings次渴望。';
  }

  // ---- Day-of-Week Analysis ----

  /// Detect day-of-week patterns in cravings.
  ///
  /// Returns a list of [DayPattern] for each day that has data.
  List<DayPattern> analyzeDayPatterns(List<CravingEntry> cravings) {
    if (cravings.isEmpty) return [];

    // Group cravings by weekday
    final weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekdayData = <int, _DayCravingData>{};

    for (final c in cravings) {
      // DateTime.weekday: Monday=1, Sunday=7
      final weekday = c.timestamp.weekday;
      final existing =
          weekdayData[weekday] ?? _DayCravingData(weekday: weekday);
      weekdayData[weekday] = existing.copyWith(
        cravingCount: existing.cravingCount + 1,
        totalIntensity: existing.totalIntensity + c.intensity,
      );
    }

    // Calculate average to determine high-risk days
    final activeDays = weekdayData.length;
    final avgCount = cravings.length / activeDays;

    final patterns = <DayPattern>[];
    for (final entry in weekdayData.entries) {
      final data = entry.value;
      final avgIntensity = data.totalIntensity / data.cravingCount;
      final isHighRisk = data.cravingCount >= avgCount * 1.3;

      patterns.add(DayPattern(
        weekday: weekdayNames[data.weekday - 1],
        cravingCount: data.cravingCount,
        avgIntensity: avgIntensity,
        isHighRisk: isHighRisk,
      ));
    }

    // Sort by craving count descending
    patterns.sort((a, b) => b.cravingCount.compareTo(a.cravingCount));
    return patterns;
  }

  // ---- Mood-Craving Correlation ----

  /// Calculate the correlation between mood scores and craving intensity.
  ///
  /// Uses Pearson correlation coefficient.
  /// Returns a value between -1.0 and 1.0:
  /// - Negative = low mood correlates with higher craving (common pattern)
  /// - Positive = high mood correlates with higher craving (unusual)
  /// - Near 0 = no linear correlation
  double calculateMoodCravingCorrelation(List<DailyLogEntry> logs) {
    if (logs.length < 3) return 0.0;

    // Filter to logs that have both mood and urgeLevel
    final paired = logs.where((l) => l.urgeLevel != null).toList();

    if (paired.length < 3) return 0.0;

    final n = paired.length.toDouble();
    final moods = paired.map((l) => l.mood.toDouble()).toList();
    final urges = paired.map((l) => l.urgeLevel!.toDouble()).toList();

    // Pearson correlation
    final meanMood = moods.reduce((a, b) => a + b) / n;
    final meanUrge = urges.reduce((a, b) => a + b) / n;

    double covariance = 0;
    double varMood = 0;
    double varUrge = 0;

    for (var i = 0; i < n; i++) {
      final dm = moods[i] - meanMood;
      final du = urges[i] - meanUrge;
      covariance += dm * du;
      varMood += dm * dm;
      varUrge += du * du;
    }

    if (varMood == 0 || varUrge == 0) return 0.0;
    return (covariance / sqrt(varMood * varUrge)).clamp(-1.0, 1.0);
  }

  /// Get a human-readable description of the mood-craving relationship.
  String describeMoodCravingRelationship(double correlation) {
    final absCorr = correlation.abs();
    if (absCorr < 0.2) return '心情与渴望之间没有明显的线性关联。';
    if (absCorr < 0.4) return '心情与渴望之间存在轻微的关联。';

    if (correlation < -0.4) {
      if (correlation < -0.7) {
        return '数据显示，当你的心情低落时，渴望会明显增强。'
            '情绪管理可能是你戒断成功的关键因素之一。';
      }
      return '你的心情和渴望有一定的负相关——心情不好的时候，'
          '渴望往往更强。注意调节情绪可以帮助减少渴望。';
    }

    if (correlation > 0.4) {
      if (correlation > 0.7) {
        return '有趣的是，你的数据呈现出心情好的时候渴望也更强的模式。'
            '这可能和"庆祝心态"有关——开心时容易放松警惕。';
      }
      return '数据显示心情好的时候渴望也稍强，'
          '这可能和社交场景有关。';
    }

    return '心情与渴望之间存在一定的关联。';
  }

  // ---- Trend Detection ----

  /// Detect whether the user's situation is improving, stable, or worsening.
  ///
  /// Compares the most recent [windowDays] days against the [windowDays] before that.
  /// Considers: craving intensity, mood, relapse frequency, urge levels.
  TrendDirection detectTrend(
    List<DailyLogEntry> logs, {
    int windowDays = 7,
  }) {
    if (logs.length < 4) return TrendDirection.stable;

    // Sort by date
    final sorted = List<DailyLogEntry>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    final half = sorted.length ~/ 2;
    final recent = sorted.sublist(half);
    final older = sorted.sublist(0, half);

    if (recent.isEmpty || older.isEmpty) return TrendDirection.stable;

    // Compare average metrics
    final recentAvgMood = _avg(recent.map((l) => l.mood.toDouble()));
    final olderAvgMood = _avg(older.map((l) => l.mood.toDouble()));

    final recentAvgUrge = _avgOpt(recent
        .where((l) => l.urgeLevel != null)
        .map((l) => l.urgeLevel!.toDouble()));
    final olderAvgUrge = _avgOpt(older
        .where((l) => l.urgeLevel != null)
        .map((l) => l.urgeLevel!.toDouble()));

    final recentRelapseRate = _avg(recent.map((l) => l.relapsed ? 1.0 : 0.0));
    final olderRelapseRate = _avg(older.map((l) => l.relapsed ? 1.0 : 0.0));

    // Score: positive = improving
    double score = 0;

    // Mood improvement (higher is better)
    score += (recentAvgMood - olderAvgMood) * 0.4;

    // Urge decrease (lower is better)
    if (recentAvgUrge != null && olderAvgUrge != null) {
      score += (olderAvgUrge - recentAvgUrge) * 0.3;
    }

    // Relapse decrease (lower is better)
    score += (olderRelapseRate - recentRelapseRate) * 3.0;

    if (score > 0.3) return TrendDirection.improving;
    if (score < -0.3) return TrendDirection.worsening;
    return TrendDirection.stable;
  }

  /// Detect trend based on craving entries alone.
  TrendDirection detectCravingTrend(
    List<CravingEntry> cravings, {
    int windowDays = 7,
  }) {
    if (cravings.length < 4) return TrendDirection.stable;

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: windowDays * 2));
    final midCutoff = now.subtract(Duration(days: windowDays));

    final older = cravings
        .where((c) =>
            c.timestamp.isAfter(cutoff) && c.timestamp.isBefore(midCutoff))
        .toList();
    final recent =
        cravings.where((c) => c.timestamp.isAfter(midCutoff)).toList();

    if (older.isEmpty || recent.isEmpty) return TrendDirection.stable;

    final olderAvg = _avg(older.map((c) => c.intensity.toDouble()));
    final recentAvg = _avg(recent.map((c) => c.intensity.toDouble()));

    final diff = olderAvg - recentAvg;
    if (diff > 0.8) return TrendDirection.improving;
    if (diff < -0.8) return TrendDirection.worsening;
    return TrendDirection.stable;
  }

  // ---- Craving Prediction ----

  /// Predict craving likelihood for a given hour (0.0-1.0).
  ///
  /// Uses historical frequency and intensity data.
  /// Returns 0.0 if no data is available.
  double predictCravingLikelihood(int hour, List<CravingEntry> cravings) {
    if (cravings.isEmpty) return 0.0;

    // Count cravings in a 2-hour window around the target hour
    const windowSize = 1; // +/- 1 hour
    var windowCount = 0;
    var windowTotalIntensity = 0;
    final totalDays = <int>{};

    for (final c in cravings) {
      totalDays.add(DateTime(
            c.timestamp.year,
            c.timestamp.month,
            c.timestamp.day,
          ).millisecondsSinceEpoch ~/
          86400000);

      final h = c.timestamp.hour;
      final diff = (h - hour).abs();
      // Handle wrap-around (e.g., 23 and 0)
      final wrappedDiff = diff > 12 ? 24 - diff : diff;
      if (wrappedDiff <= windowSize) {
        windowCount++;
        windowTotalIntensity += c.intensity;
      }
    }

    if (totalDays.isEmpty) return 0.0;

    // Base probability: frequency in this window
    final days = totalDays.length;
    final avgWindowCount = windowCount / days;

    // Normalize: typical max cravings in a 3-hour window per day
    const maxExpected = 3.0;
    var probability = (avgWindowCount / maxExpected).clamp(0.0, 0.9);

    // Boost by average intensity (higher intensity cravings = higher likelihood)
    if (windowCount > 0) {
      final avgIntensity = windowTotalIntensity / windowCount;
      probability += (avgIntensity / 10.0) * 0.1;
    }

    return probability.clamp(0.0, 1.0);
  }

  // ---- Trigger Analysis ----

  /// Rank triggers by frequency and average craving intensity.
  ///
  /// Returns triggers sorted by frequency (descending).
  List<TriggerRanking> rankTriggers(List<CravingEntry> cravings) {
    if (cravings.isEmpty) return [];

    final triggerMap = <String, _TriggerAccum>{};

    for (final c in cravings) {
      final trigger = c.trigger;
      if (trigger == null || trigger.trim().isEmpty) continue;

      final t = trigger.trim();
      final existing = triggerMap[t] ?? _TriggerAccum(trigger: t);
      triggerMap[t] = existing.copyWith(
        count: existing.count + 1,
        totalIntensity: existing.totalIntensity + c.intensity,
      );
    }

    final totalWithTriggers = cravings
        .where((c) => c.trigger != null && c.trigger!.trim().isNotEmpty)
        .length;

    if (totalWithTriggers == 0) return [];

    final rankings = triggerMap.values.map((acc) {
      return TriggerRanking(
        trigger: acc.trigger,
        count: acc.count,
        avgIntensity: acc.totalIntensity / acc.count,
        percentage: acc.count / totalWithTriggers,
      );
    }).toList();

    // Sort by count descending, then by intensity descending
    rankings.sort((a, b) {
      final countDiff = b.count.compareTo(a.count);
      if (countDiff != 0) return countDiff;
      return b.avgIntensity.compareTo(a.avgIntensity);
    });

    return rankings;
  }

  // ---- Streak Analysis ----

  /// Analyze the user's streak and predict continuation probability.
  StreakAnalysis analyzeStreak({
    required GameProfile gameProfile,
    required List<DailyLogEntry> logs,
    required User user,
  }) {
    final currentStreak = gameProfile.streakDays;
    final longestStreak = gameProfile.longestStreak;

    if (currentStreak == 0) {
      return StreakAnalysis(
        currentStreak: 0,
        longestStreak: longestStreak,
        avgStreakLength: 0,
        continuationProbability: 0.5,
        atRisk: false,
        summary: '还没有开始连续打卡。今天开始吧！',
      );
    }

    // Calculate historical average streak from log data
    final relapseDays = logs.where((l) => l.relapsed).length;
    final totalLoggedDays = logs.length;
    final daysSinceQuit = user.daysSinceQuit;

    // Estimate average streak length between relapses
    double avgStreak = 0;
    if (relapseDays > 0 && totalLoggedDays > 0) {
      avgStreak = totalLoggedDays / (relapseDays + 1);
    } else if (daysSinceQuit > 0 && relapseDays == 0) {
      avgStreak = daysSinceQuit.toDouble();
    }

    // Predict continuation probability using a sigmoid model
    // Factors: current streak relative to average, days since quit, recent mood
    final streakRatio = avgStreak > 0 ? currentStreak / avgStreak : 1.0;
    final daysFactor = min(daysSinceQuit / 90.0, 1.0); // Plateaus at 90 days

    // Recent mood trend (last 3 logs)
    final recentLogs = logs.length >= 3 ? logs.sublist(logs.length - 3) : logs;
    final recentAvgMood = recentLogs.isNotEmpty
        ? _avg(recentLogs.map((l) => l.mood.toDouble()))
        : 3.0;

    // Sigmoid-based probability
    final rawScore = (streakRatio * 0.3) +
        (daysFactor * 0.3) +
        ((recentAvgMood - 3) / 4 * 0.4);
    final probability = (1.0 / (1.0 + exp(-rawScore * 3))).clamp(0.1, 0.99);

    // Determine if at risk
    final isEarlyStage = daysSinceQuit <= 14;
    final lowMood = recentAvgMood < 2.5;
    final streakBelowAverage = avgStreak > 0 && currentStreak < avgStreak * 0.5;
    final atRisk = (isEarlyStage && lowMood) || streakBelowAverage;

    // Build summary
    final summary = _buildStreakSummary(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      avgStreak: avgStreak,
      probability: probability,
      atRisk: atRisk,
      daysSinceQuit: daysSinceQuit,
    );

    return StreakAnalysis(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      avgStreakLength: avgStreak,
      continuationProbability: probability,
      atRisk: atRisk,
      summary: summary,
    );
  }

  String _buildStreakSummary({
    required int currentStreak,
    required int longestStreak,
    required double avgStreak,
    required double probability,
    required bool atRisk,
    required int daysSinceQuit,
  }) {
    final pctText = (probability * 100).toStringAsFixed(0);

    if (atRisk) {
      return '当前连续打卡$currentStreak天，但数据显示你可能面临一些挑战。'
          '保持警惕，今天也坚持打卡！';
    }

    if (currentStreak >= longestStreak && currentStreak > 0) {
      return '你正在创造新的记录！连续$currentStreak天打卡，'
          '继续坚持的概率约为$pctText%。你做得很棒！';
    }

    if (currentStreak >= 30) {
      return '连续$currentStreak天，你已经度过了最艰难的阶段。'
          '继续保持的概率约$pctText%，习惯正在稳固。';
    }

    if (currentStreak >= 7) {
      return '连续$currentStreak天了！第一周是最难的，你已经挺过来了。'
          '保持当前节奏，继续坚持的概率约$pctText%。';
    }

    return '连续打卡$currentStreak天。早期阶段需要格外注意，'
        '每一天的坚持都在帮你建立新的习惯。';
  }

  // ---- Composite Risk Score (Local) ----

  /// Calculate a local relapse risk score (0-100) without LLM.
  ///
  /// This is a heuristic-based score that considers:
  /// - Recent craving frequency and intensity
  /// - Mood trend
  /// - Recent relapses
  /// - Streak status
  /// - Time since quit
  int calculateLocalRiskScore({
    required User user,
    required GameProfile gameProfile,
    DailyLogEntry? todayLog,
    required List<DailyLogEntry> recentLogs,
    required List<CravingEntry> recentCravings,
  }) {
    double riskScore = 0;

    // 1. Days since quit factor (0-20 points)
    final days = user.daysSinceQuit;
    if (days == 0) {
      riskScore += 20; // Haven't started yet
    } else if (days <= 3) {
      riskScore += 18; // Acute withdrawal phase
    } else if (days <= 7) {
      riskScore += 14;
    } else if (days <= 14) {
      riskScore += 10;
    } else if (days <= 30) {
      riskScore += 6;
    } else if (days <= 90) {
      riskScore += 3;
    } else {
      riskScore += 1;
    }

    // 2. Recent craving intensity (0-25 points)
    if (recentCravings.isNotEmpty) {
      final recentWindow = DateTime.now().subtract(const Duration(days: 3));
      final veryRecent = recentCravings
          .where((c) => c.timestamp.isAfter(recentWindow))
          .toList();
      if (veryRecent.isNotEmpty) {
        final avgIntensity =
            _avg(veryRecent.map((c) => c.intensity.toDouble()));
        riskScore += (avgIntensity / 10.0) * 20;

        // Bonus risk for high frequency
        final dailyRate = veryRecent.length / 3.0;
        if (dailyRate > 5) {
          riskScore += 5;
        } else if (dailyRate > 3) {
          riskScore += 3;
        }
      }
    }

    // 3. Mood factor (0-20 points)
    if (todayLog != null) {
      // Today's mood (lower = more risk)
      riskScore += (5 - todayLog.mood) * 3;

      // Today's urge level
      if (todayLog.urgeLevel != null && todayLog.urgeLevel! > 0) {
        riskScore += todayLog.urgeLevel! * 1.5;
      }
    }

    // Recent mood trend
    if (recentLogs.length >= 3) {
      final recentMood = _avg(
        recentLogs.sublist(recentLogs.length - 3).map((l) => l.mood.toDouble()),
      );
      if (recentMood < 2.5) {
        riskScore += 8;
      } else if (recentMood < 3.0) {
        riskScore += 4;
      }
    }

    // 4. Recent relapse factor (0-25 points)
    final recentRelapses = recentLogs.where((l) => l.relapsed).length;
    if (recentRelapses >= 3) {
      riskScore += 25;
    } else if (recentRelapses == 2) {
      riskScore += 18;
    } else if (recentRelapses == 1) {
      // Check how recent
      final lastRelapse = recentLogs.lastWhere(
        (l) => l.relapsed,
        orElse: () => recentLogs.first,
      );
      final daysSinceRelapse =
          DateTime.now().difference(lastRelapse.date).inDays;
      if (daysSinceRelapse <= 1) {
        riskScore += 15;
      } else if (daysSinceRelapse <= 3) {
        riskScore += 10;
      } else {
        riskScore += 5;
      }
    }

    // 5. Streak break risk (0-10 points)
    if (gameProfile.streakDays > 0) {
      // If streak is active but today hasn't been checked in
      final lastCheckin = gameProfile.lastCheckinDate;
      if (lastCheckin != null) {
        final today = DateTime.now();
        final lastDay =
            DateTime(lastCheckin.year, lastCheckin.month, lastCheckin.day);
        final todayDay = DateTime(today.year, today.month, today.day);
        final daysSinceCheckin = todayDay.difference(lastDay).inDays;

        if (daysSinceCheckin >= 2) {
          riskScore += 10; // Streak about to break
        } else if (daysSinceCheckin == 1 && todayLog == null) {
          riskScore += 5; // Haven't checked in today yet
        }
      }
    }

    return riskScore.round().clamp(0, 100);
  }

  // ---- Utility Methods ----

  double _avg(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? _avgOpt(Iterable<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

// ---- Internal helper classes ----

class _HourData {
  final int count;
  final double totalIntensity;

  const _HourData({this.count = 0, this.totalIntensity = 0});

  double get avgIntensity => count > 0 ? totalIntensity / count : 0;

  _HourData copyWith({int? count, double? totalIntensity}) {
    return _HourData(
      count: count ?? this.count,
      totalIntensity: totalIntensity ?? this.totalIntensity,
    );
  }
}

class _DayCravingData {
  final int weekday;
  final int cravingCount;
  final double totalIntensity;

  const _DayCravingData({
    required this.weekday,
    this.cravingCount = 0,
    this.totalIntensity = 0,
  });

  _DayCravingData copyWith({int? cravingCount, double? totalIntensity}) {
    return _DayCravingData(
      weekday: weekday,
      cravingCount: cravingCount ?? this.cravingCount,
      totalIntensity: totalIntensity ?? this.totalIntensity,
    );
  }
}

class _TriggerAccum {
  final String trigger;
  final int count;
  final double totalIntensity;

  const _TriggerAccum({
    required this.trigger,
    this.count = 0,
    this.totalIntensity = 0,
  });

  _TriggerAccum copyWith({int? count, double? totalIntensity}) {
    return _TriggerAccum(
      trigger: trigger,
      count: count ?? this.count,
      totalIntensity: totalIntensity ?? this.totalIntensity,
    );
  }
}
