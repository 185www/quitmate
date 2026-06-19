/// Insight types for analysis results.
enum InsightType {
  motivational,
  warning,
  achievement,
  neutral,
  critical,
}

/// A single analysis insight about the user's behavior.
class AnalysisInsight {
  /// The category of this insight.
  ///
  /// - 'pattern': A behavioral pattern detected in user data
  /// - 'risk': A risk factor or warning sign
  /// - 'achievement': A positive milestone or improvement
  /// - 'suggestion': An actionable recommendation
  /// - 'trend': A directional trend in user's data
  final String type;

  /// Short, attention-grabbing title (≤20 chars).
  final String title;

  /// Detailed explanation of the insight.
  final String description;

  /// Optional actionable recommendation.
  final String? recommendation;

  /// Severity level (1-5).
  ///
  /// For 'risk' type: 1 = low risk, 5 = critical danger.
  /// For 'achievement' type: 1 = minor win, 5 = major milestone.
  /// For other types: represents importance/significance.
  final int severity;

  /// Supporting data points that back this insight.
  ///
  /// Examples:
  /// ```dart
  /// {'peakHour': 15, 'avgIntensity': 7.2, 'sampleSize': 23}
  /// ```
  final Map<String, dynamic>? data;

  const AnalysisInsight({
    required this.type,
    required this.title,
    required this.description,
    this.recommendation,
    required this.severity,
    this.data,
  });

  /// Whether this insight represents a risk or warning.
  bool get isRisk => type == 'risk' && severity >= 3;

  /// Whether this insight is positive (achievement or improving trend).
  bool get isPositive => type == 'achievement' || (type == 'trend' && severity <= 2);

  AnalysisInsight copyWith({
    String? type,
    String? title,
    String? description,
    String? recommendation,
    int? severity,
    Map<String, dynamic>? data,
  }) {
    return AnalysisInsight(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      recommendation: recommendation ?? this.recommendation,
      severity: severity ?? this.severity,
      data: data ?? this.data,
    );
  }

  @override
  String toString() => 'AnalysisInsight(type: $type, title: $title, severity: $severity)';
}

/// A daily personalized insight shown on the dashboard.
class DailyInsight {
  /// Short, punchy headline (e.g., "你的渴望在下午3点最高").
  final String headline;

  /// Detailed explanation of why this insight matters.
  final String body;

  /// What the user should do about it (actionable).
  final String actionText;

  /// Optional deep-link route to a relevant screen.
  final String? actionRoute;

  /// The type of insight, used for visual styling.
  final InsightType type;

  /// Calculated relapse risk score (0-100).
  ///
  /// 0 = no risk, 100 = extremely high risk of relapse.
  final int relapseRiskScore;

  /// When this insight was generated.
  final DateTime generatedAt;

  DailyInsight({
    required this.headline,
    required this.body,
    required this.actionText,
    this.actionRoute,
    required this.type,
    required this.relapseRiskScore,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  DailyInsight copyWith({
    String? headline,
    String? body,
    String? actionText,
    String? actionRoute,
    InsightType? type,
    int? relapseRiskScore,
    DateTime? generatedAt,
  }) {
    return DailyInsight(
      headline: headline ?? this.headline,
      body: body ?? this.body,
      actionText: actionText ?? this.actionText,
      actionRoute: actionRoute ?? this.actionRoute,
      type: type ?? this.type,
      relapseRiskScore: relapseRiskScore ?? this.relapseRiskScore,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

/// A comprehensive weekly progress report with AI-powered analysis.
class WeeklyReport {
  /// ISO week number.
  final int weekNumber;

  /// Executive summary paragraph.
  final String summary;

  /// List of achievements earned this week.
  final List<String> achievements;

  /// Detailed insights discovered this week.
  final List<AnalysisInsight> insights;

  /// Aggregated statistics for the week.
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'totalCravings': 23,
  ///   'avgIntensity': 5.4,
  ///   'avgMood': 3.8,
  ///   'resistedCount': 20,
  ///   'resistRate': 0.87,
  ///   'peakDay': '周三',
  ///   'peakHour': 15,
  ///   'relapseDays': 0,
  ///   'xpEarned': 320,
  /// }
  /// ```
  final Map<String, dynamic> statistics;

  /// An optional motivational quote to end the report.
  final String? motivationalQuote;

  /// Overall score for the week (0-100).
  final int overallScore;

  /// When this report was generated.
  final DateTime generatedAt;

  WeeklyReport({
    required this.weekNumber,
    required this.summary,
    required this.achievements,
    required this.insights,
    required this.statistics,
    this.motivationalQuote,
    this.overallScore = 50,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}

/// A personalized action suggestion based on the user's current state.
class PersonalizedAction {
  /// Short action title (e.g., "做一次呼吸练习").
  final String title;

  /// Brief description of why this action is recommended.
  final String description;

  /// GoRouter path to navigate to the relevant screen.
  final String route;

  /// Material icon name for visual display.
  final String icon;

  /// Priority (higher = more urgent).
  ///
  /// 1-3: Nice to have
  /// 4-6: Recommended
  /// 7-10: Urgent
  final int priority;

  const PersonalizedAction({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.priority,
  });

  /// Whether this action is urgent.
  bool get isUrgent => priority >= 7;

  PersonalizedAction copyWith({
    String? title,
    String? description,
    String? route,
    String? icon,
    int? priority,
  }) {
    return PersonalizedAction(
      title: title ?? this.title,
      description: description ?? this.description,
      route: route ?? this.route,
      icon: icon ?? this.icon,
      priority: priority ?? this.priority,
    );
  }
}

/// Pattern analysis result structures.

/// Time-of-day craving pattern.
class TimePattern {
  /// Hour (0-23) with the most cravings.
  final int peakHour;

  /// Average intensity at peak hour (1.0-10.0).
  final double peakIntensity;

  /// Hours (0-23) with above-average craving frequency/intensity.
  final List<int> highRiskHours;

  /// Human-readable summary in Chinese.
  final String summary;

  /// Raw hourly distribution data (hour -> count).
  final Map<int, int> hourlyDistribution;

  const TimePattern({
    required this.peakHour,
    required this.peakIntensity,
    required this.highRiskHours,
    required this.summary,
    this.hourlyDistribution = const {},
  });

  /// Format hour as a readable time string (e.g., "下午3点").
  static String formatHour(int hour) {
    if (hour == 0 || hour == 24) return '午夜12点';
    if (hour < 6) return '凌晨$hour点';
    if (hour < 12) return '上午$hour点';
    if (hour == 12) return '中午12点';
    if (hour < 18) return '下午$hour点';
    return '晚上$hour点';
  }
}

/// Day-of-week craving pattern.
class DayPattern {
  /// Chinese weekday name (e.g., "周一").
  final String weekday;

  /// Number of cravings on this day.
  final int cravingCount;

  /// Average craving intensity on this day.
  final double avgIntensity;

  /// Whether this day is statistically high-risk.
  final bool isHighRisk;

  const DayPattern({
    required this.weekday,
    required this.cravingCount,
    required this.avgIntensity,
    required this.isHighRisk,
  });
}

/// Direction of a trend.
enum TrendDirection {
  improving,
  stable,
  worsening,
}

/// Trigger frequency ranking result.
class TriggerRanking {
  /// The trigger text (e.g., "压力", "社交", "饭后").
  final String trigger;

  /// How many times this trigger appeared.
  final int count;

  /// Average craving intensity when this trigger fired.
  final double avgIntensity;

  /// Percentage of total cravings this trigger accounts for.
  final double percentage;

  const TriggerRanking({
    required this.trigger,
    required this.count,
    required this.avgIntensity,
    required this.percentage,
  });
}

/// Streak analysis result.
class StreakAnalysis {
  /// Current streak length in days.
  final int currentStreak;

  /// Longest streak ever achieved.
  final int longestStreak;

  /// Average streak length (excluding the current one).
  final double avgStreakLength;

  /// Predicted probability of maintaining streak for 7 more days (0.0-1.0).
  final double continuationProbability;

  /// Whether the current streak is at risk of breaking.
  final bool atRisk;

  /// Human-readable summary.
  final String summary;

  const StreakAnalysis({
    required this.currentStreak,
    required this.longestStreak,
    required this.avgStreakLength,
    required this.continuationProbability,
    required this.atRisk,
    required this.summary,
  });
}