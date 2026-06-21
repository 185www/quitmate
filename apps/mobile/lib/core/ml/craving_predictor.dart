/// On-device ML craving prediction using time-series analysis.
///
/// Pure Dart implementation — zero external dependencies.
/// Uses statistical methods: exponential smoothing, moving averages,
/// hourly/day-of-week distribution analysis, and trigger correlation.
///
/// This is "smart rules" rather than deep learning — appropriate for the
/// data volume available in a personal quit-journey app.

import 'dart:math';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';

// Re-export CravingEntry from user.dart so consumers only need this import.
export '../../domain/entity/user.dart' show CravingEntry;

// ─────────────────────────────────────────────────────────────────────────────
// Data classes returned by the predictor
// ─────────────────────────────────────────────────────────────────────────────

/// Overall craving prediction result.
class CravingPrediction {
  /// Per-hour risk probability map (hour 0-23 → risk 0.0-1.0).
  final Map<int, double> hourlyRisk;

  /// Consolidated high-risk time windows.
  final List<TimeRiskWindow> highRiskWindows;

  /// Trigger analysis — which triggers lead to the highest intensity.
  final TriggerAnalysis triggerAnalysis;

  /// Whether craving intensity is improving, stable, or worsening.
  final TrendDirection trendDirection;

  /// Confidence in this prediction (0.0-1.0). Based on data volume.
  final double confidence;

  /// Chinese human-readable summary.
  final String summary;

  const CravingPrediction({
    required this.hourlyRisk,
    required this.highRiskWindows,
    required this.triggerAnalysis,
    required this.trendDirection,
    required this.confidence,
    required this.summary,
  });
}

/// A contiguous time window with elevated craving risk.
class TimeRiskWindow {
  /// Starting hour of the window (0-23).
  final int startHour;

  /// Ending hour of the window (0-23).
  final int endHour;

  /// Risk level for this window (0.0-1.0).
  final double riskLevel;

  /// Human-readable suggestion in Chinese.
  final String suggestion;

  const TimeRiskWindow({
    required this.startHour,
    required this.endHour,
    required this.riskLevel,
    required this.suggestion,
  });
}

/// Trigger analysis result.
class TriggerAnalysis {
  /// Top triggers sorted by risk (descending).
  final List<TriggerInsight> topTriggers;

  const TriggerAnalysis({required this.topTriggers});
}

/// Per-trigger insight.
class TriggerInsight {
  /// The trigger label (e.g. "压力", "社交").
  final String trigger;

  /// Average craving intensity when this trigger is present (1-10).
  final double avgIntensity;

  /// Percentage of cravings with this trigger that were resolved (0.0-1.0).
  final double resolutionRate;

  /// How many times this trigger appeared.
  final int count;

  /// Composite risk score (intensity × frequency factor).
  double get riskScore {
    if (count < 2) return avgIntensity * 0.5;
    return avgIntensity * (1 + count * 0.1);
  }

  const TriggerInsight({
    required this.trigger,
    required this.avgIntensity,
    required this.resolutionRate,
    required this.count,
  });
}

/// Direction of the craving intensity trend.
enum TrendDirection {
  /// Craving intensity is decreasing over time.
  improving,

  /// No significant change.
  stable,

  /// Craving intensity is increasing over time.
  worsening,
}

// ─────────────────────────────────────────────────────────────────────────────
// CravingPredictor — main class
// ─────────────────────────────────────────────────────────────────────────────

/// On-device craving predictor using time-series analysis.
///
/// Accepts a list of [CravingEntry] and produces a [CravingPrediction]
/// containing hourly risk scores, high-risk windows, trigger insights,
/// trend direction, and a confidence level.
///
/// Usage:
/// ```dart
/// final predictor = CravingPredictor();
/// final prediction = predictor.predict(
///   cravings: myCravings,
///   dailyLogs: myLogs,
/// );
/// ```
class CravingPredictor {
  // ── Tuning constants ─────────────────────────────────────────────────────
  /// Smoothing factor for exponential smoothing (0-1). Higher = more responsive.
  static const double _alpha = 0.3;

  /// Minimum cravings before predictions are considered meaningful.
  static const int _minimumDataPoints = 5;

  /// Risk threshold to classify a window as "high-risk".
  static const double _highRiskThreshold = 0.35;

  /// Minimum hours of consecutive risk to form a window.
  static const int _minimumWindowHours = 1;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Run the full prediction pipeline on the given craving history.
  ///
  /// [dailyLogs] is optional but improves trend detection when provided.
  CravingPrediction predict({
    required List<CravingEntry> cravings,
    List<DailyLogEntry>? dailyLogs,
  }) {
    if (cravings.length < _minimumDataPoints) {
      return _emptyPrediction(cravings.length);
    }

    // 1. Hourly risk map
    final hourlyRisk = _computeHourlyRisk(cravings);

    // 2. Consolidate into time windows
    final highRiskWindows = _extractHighRiskWindows(hourlyRisk);

    // 3. Trigger analysis
    final triggerAnalysis = _analyzeTriggers(cravings);

    // 4. Trend detection
    final trendDirection = _detectTrend(cravings, dailyLogs);

    // 5. Confidence based on data volume
    final confidence = _computeConfidence(cravings);

    // 6. Summary
    final summary = _buildSummary(
      highRiskWindows: highRiskWindows,
      trendDirection: trendDirection,
      confidence: confidence,
      cravingCount: cravings.length,
      triggerAnalysis: triggerAnalysis,
    );

    return CravingPrediction(
      hourlyRisk: hourlyRisk,
      highRiskWindows: highRiskWindows,
      triggerAnalysis: triggerAnalysis,
      trendDirection: trendDirection,
      confidence: confidence,
      summary: summary,
    );
  }

  // ── 1. Hourly risk computation ─────────────────────────────────────────

  /// Compute a risk probability for each hour (0-23).
  ///
  /// Combines:
  /// - Historical frequency (how many cravings in a ±1 hour window per day)
  /// - Average intensity at that hour
  /// - Exponential-smoothed trend modifier
  Map<int, double> _computeHourlyRisk(List<CravingEntry> cravings) {
    // Gather per-hour aggregates and count unique days.
    final hourlyAccum = <int, _HourAccum>{};
    final uniqueDays = <int>{};

    for (final c in cravings) {
      final dayKey = DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day)
          .millisecondsSinceEpoch ~/
          86400000;
      uniqueDays.add(dayKey);

      // Add to this hour and ±1 hour windows (wrap-around aware).
      for (final offset in [-1, 0, 1]) {
        final h = (c.timestamp.hour + offset + 24) % 24;
        final weight = offset == 0 ? 1.0 : 0.5;
        final existing = hourlyAccum[h] ?? const _HourAccum();
        hourlyAccum[h] = existing.copyWith(
          weightedCount: existing.weightedCount + weight,
          totalIntensity: existing.totalIntensity + c.intensity * weight,
          rawCount: existing.rawCount + (offset == 0 ? 1 : 0),
        );
      }
    }

    final totalDays = uniqueDays.length;
    if (totalDays == 0) return _flatRisk(0.0);

    // Convert to risk probabilities.
    final result = <int, double>{};
    const maxExpectedPerDay = 2.5; // baseline for normalization.

    for (var h = 0; h < 24; h++) {
      final data = hourlyAccum[h];
      if (data == null || data.rawCount == 0) {
        result[h] = 0.0;
        continue;
      }

      // Frequency component (0-0.7 range).
      final avgFrequency = data.weightedCount / totalDays;
      var freqRisk = (avgFrequency / maxExpectedPerDay).clamp(0.0, 0.7);

      // Intensity component (0-0.3 range).
      final avgIntensity = data.totalIntensity / data.weightedCount;
      final intensityRisk = (avgIntensity / 10.0) * 0.3;

      result[h] = (freqRisk + intensityRisk).clamp(0.0, 1.0);
    }

    return result;
  }

  // ── 2. High-risk window extraction ─────────────────────────────────────

  /// Group consecutive high-risk hours into windows.
  List<TimeRiskWindow> _extractHighRiskWindows(Map<int, double> hourlyRisk) {
    final highHours = <int>[];
    for (var h = 0; h < 24; h++) {
      if ((hourlyRisk[h] ?? 0.0) >= _highRiskThreshold) {
        highHours.add(h);
      }
    }

    if (highHours.isEmpty) return [];

    // Group consecutive hours (handling midnight wrap-around).
    final groups = <List<int>>[];
    var current = <int>[highHours.first];

    for (var i = 1; i < highHours.length; i++) {
      final gap = highHours[i] - highHours[i - 1];
      if (gap == 1 || (gap == 23 && highHours.length > 4)) {
        // Allow wrap-around only when enough data justifies it.
        current.add(highHours[i]);
      } else {
        if (current.length >= _minimumWindowHours) {
          groups.add(current);
        }
        current = [highHours[i]];
      }
    }
    if (current.length >= _minimumWindowHours) {
      groups.add(current);
    }

    return groups.map((group) {
      final start = group.first;
      final end = group.last;
      // Average risk across the window.
      final avgRisk =
          group.map((h) => hourlyRisk[h] ?? 0.0).reduce((a, b) => a + b) /
              group.length;

      return TimeRiskWindow(
        startHour: start,
        endHour: end,
        riskLevel: avgRisk,
        suggestion: _windowSuggestion(start, end, avgRisk),
      );
    }).toList()
      ..sort((a, b) => b.riskLevel.compareTo(a.riskLevel));
  }

  // ── 3. Trigger analysis ─────────────────────────────────────────────────

  TriggerAnalysis _analyzeTriggers(List<CravingEntry> cravings) {
    final accum = <String, _TriggerAccum>{};

    for (final c in cravings) {
      final trigger = c.trigger?.trim();
      if (trigger == null || trigger.isEmpty) continue;

      final existing = accum[trigger] ?? _TriggerAccum(trigger: trigger);
      accum[trigger] = existing.copyWith(
        count: existing.count + 1,
        totalIntensity: existing.totalIntensity + c.intensity,
        resolvedCount: existing.resolvedCount + (c.resolved ? 1 : 0),
      );
    }

    final insights = accum.values
        .where((a) => a.count >= 2)
        .map((a) => TriggerInsight(
              trigger: a.trigger,
              avgIntensity: a.totalIntensity / a.count,
              resolutionRate: a.count > 0 ? a.resolvedCount / a.count : 0.0,
              count: a.count,
            ))
        .toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return TriggerAnalysis(topTriggers: insights);
  }

  // ── 4. Trend detection via exponential smoothing ─────────────────────────

  TrendDirection _detectTrend(
    List<CravingEntry> cravings,
    List<DailyLogEntry>? dailyLogs,
  ) {
    // Sort cravings by time.
    final sorted = List<CravingEntry>.from(cravings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Bucket cravings by day.
    final dailyBuckets = <DateTime, List<CravingEntry>>{};
    for (final c in sorted) {
      final day = DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day);
      dailyBuckets.putIfAbsent(day, () => []).add(c);
    }

    final days = dailyBuckets.keys.toList()..sort();
    if (days.length < 4) return TrendDirection.stable;

    // Build a time series of average daily intensity.
    final series = days.map((d) {
      final bucket = dailyBuckets[d]!;
      return bucket.map((c) => c.intensity.toDouble()).reduce((a, b) => a + b) /
          bucket.length;
    }).toList();

    // Apply exponential smoothing to get the smoothed trend.
    final smoothed = _exponentialSmoothing(series, _alpha);

    // Compare the smoothed values of the first half vs the second half.
    final mid = smoothed.length ~/ 2;
    final firstHalf = smoothed.sublist(0, mid);
    final secondHalf = smoothed.sublist(mid);

    final avgFirst = _mean(firstHalf);
    final avgSecond = _mean(secondHalf);

    // If daily logs available, also factor in mood-urge trend.
    double moodBonus = 0.0;
    if (dailyLogs != null && dailyLogs.length >= 4) {
      final logSorted = List<DailyLogEntry>.from(dailyLogs)
        ..sort((a, b) => a.date.compareTo(b.date));
      final logMid = logSorted.length ~/ 2;
      final recentLogs = logSorted.sublist(logMid);
      final olderLogs = logSorted.sublist(0, logMid);

      final recentAvgMood = _mean(recentLogs.map((l) => l.mood.toDouble()));
      final olderAvgMood = _mean(olderLogs.map((l) => l.mood.toDouble()));
      moodBonus = (recentAvgMood - olderAvgMood) * 0.3;
    }

    final diff = avgFirst - avgSecond + moodBonus;
    if (diff > 0.6) return TrendDirection.improving;
    if (diff < -0.6) return TrendDirection.worsening;
    return TrendDirection.stable;
  }

  // ── 5. Confidence scoring ───────────────────────────────────────────────

  double _computeConfidence(List<CravingEntry> cravings) {
    final count = cravings.length;

    // Sigmoid-based confidence that saturates around 80-90 data points.
    final raw = (count - _minimumDataPoints).toDouble();
    return (1.0 - exp(-raw / 30.0)).clamp(0.1, 0.95);
  }

  // ── 6. Summary generation ──────────────────────────────────────────────

  String _buildSummary({
    required List<TimeRiskWindow> highRiskWindows,
    required TrendDirection trendDirection,
    required double confidence,
    required int cravingCount,
    required TriggerAnalysis triggerAnalysis,
  }) {
    final parts = <String>[];

    if (highRiskWindows.isNotEmpty) {
      final top = highRiskWindows.first;
      parts.add(top.suggestion);
    }

    if (triggerAnalysis.topTriggers.isNotEmpty) {
      final topTrigger = triggerAnalysis.topTriggers.first;
      parts.add('你最常见的触发因素是「${topTrigger.trigger}」'
          '，平均强度 ${topTrigger.avgIntensity.toStringAsFixed(1)}。');
    }

    switch (trendDirection) {
      case TrendDirection.improving:
        parts.add('整体趋势向好，渴望强度在逐渐降低。');
        break;
      case TrendDirection.worsening:
        parts.add('近期渴望强度有上升趋势，需要额外关注。');
        break;
      case TrendDirection.stable:
        break;
    }

    if (confidence < 0.4) {
      parts.add('（数据量较少，建议持续记录以提高预测准确性）');
    }

    if (parts.isEmpty) return '持续记录渴望数据，可获得更精准的预测。';
    return parts.join('');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  CravingPrediction _emptyPrediction(int dataPoints) {
    return CravingPrediction(
      hourlyRisk: _flatRisk(0.0),
      highRiskWindows: [],
      triggerAnalysis: const TriggerAnalysis(topTriggers: []),
      trendDirection: TrendDirection.stable,
      confidence: dataPoints == 0
          ? 0.0
          : (1.0 - exp(-(dataPoints - 0).toDouble() / 30.0)).clamp(0.05, 0.3),
      summary: dataPoints == 0
          ? '暂无渴望数据，开始记录后可获得个性化预测。'
          : '数据不足（需要至少 $_minimumDataPoints 条记录），请继续坚持记录。',
    );
  }

  Map<int, double> _flatRisk(double value) {
    return Map<int, double>.fromEntries(
      List.generate(24, (h) => MapEntry(h, value)),
    );
  }

  String _windowSuggestion(int start, int end, double risk) {
    final startStr = formatHour(start);
    final endStr = formatHour(end);

    if (risk >= 0.7) {
      return '$startStr到$endStr是极高危时段，强烈建议提前做好应对准备，'
          '避开诱惑环境。';
    }
    if (risk >= 0.5) {
      return '$startStr到$endStr是较高危时段，建议保持警觉，'
          '准备好应对策略。';
    }
    return '$startStr到$endStr存在一定风险，提前做好准备可以降低渴望强度。';
  }

  /// Format hour as readable Chinese time.
  static String formatHour(int hour) {
    if (hour == 0 || hour == 24) return '午夜';
    if (hour < 6) return '凌晨$hour点';
    if (hour < 12) return '上午$hour点';
    if (hour == 12) return '中午';
    if (hour < 18) return '下午${hour - 12}点';
    return '晚上${hour - 12}点';
  }

  /// Simple exponential smoothing.
  ///
  /// Returns a list of smoothed values of the same length as [data].
  /// Uses the mean of the first N/3 data points as the initial level.
  List<double> _exponentialSmoothing(List<double> data, double alpha) {
    if (data.isEmpty) return [];

    // Initialise level with the mean of the first few points.
    final initLen = max(1, data.length ~/ 3);
    var level = _mean(data.sublist(0, initLen));

    final result = <double>[];
    for (final value in data) {
      level = alpha * value + (1 - alpha) * level;
      result.add(level);
    }
    return result;
  }

  double _mean(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0.0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal accumulator classes
// ─────────────────────────────────────────────────────────────────────────────

class _HourAccum {
  final double weightedCount;
  final double totalIntensity;
  final int rawCount;

  const _HourAccum({
    this.weightedCount = 0,
    this.totalIntensity = 0,
    this.rawCount = 0,
  });

  _HourAccum copyWith({
    double? weightedCount,
    double? totalIntensity,
    int? rawCount,
  }) {
    return _HourAccum(
      weightedCount: weightedCount ?? this.weightedCount,
      totalIntensity: totalIntensity ?? this.totalIntensity,
      rawCount: rawCount ?? this.rawCount,
    );
  }
}

class _TriggerAccum {
  final String trigger;
  final int count;
  final double totalIntensity;
  final int resolvedCount;

  const _TriggerAccum({
    required this.trigger,
    this.count = 0,
    this.totalIntensity = 0,
    this.resolvedCount = 0,
  });

  _TriggerAccum copyWith({
    int? count,
    double? totalIntensity,
    int? resolvedCount,
  }) {
    return _TriggerAccum(
      trigger: trigger,
      count: count ?? this.count,
      totalIntensity: totalIntensity ?? this.totalIntensity,
      resolvedCount: resolvedCount ?? this.resolvedCount,
    );
  }
}
