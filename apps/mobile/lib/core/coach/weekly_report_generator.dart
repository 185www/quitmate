import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/analysis.dart';
import 'pattern_analyzer.dart';
import 'llm_service.dart';
import 'analysis_utils.dart';
import 'llm_prompt_builder.dart';
import 'recommendation_builder.dart';

/// Generates the weekly progress report with AI-powered analysis.
///
/// Computes statistics, achievements, and insights locally first, then
/// optionally enhances the summary with LLM output.
class WeeklyReportGenerator {
  final PatternAnalyzer _patternAnalyzer;
  final LlmService? _llmService;
  final LlmPromptBuilder _promptBuilder;
  final RecommendationBuilder _recommendationBuilder;

  WeeklyReportGenerator({
    required PatternAnalyzer patternAnalyzer,
    LlmService? llmService,
    required LlmPromptBuilder promptBuilder,
    required RecommendationBuilder recommendationBuilder,
  })  : _patternAnalyzer = patternAnalyzer,
        _llmService = llmService,
        _promptBuilder = promptBuilder,
        _recommendationBuilder = recommendationBuilder;

  /// Main entry point — generates a full [WeeklyReport].
  Future<WeeklyReport> generateWeeklyReport({
    required User user,
    required GameProfile gameProfile,
    required List<DailyLogEntry> weekLogs,
    required List<CravingEntry> weekCravings,
  }) async {
    final weekNumber = AnalysisUtils.currentWeekNumber();

    // ---- Phase 1: Compute statistics locally ----
    final stats = _computeWeeklyStatistics(
      weekLogs: weekLogs,
      weekCravings: weekCravings,
      gameProfile: gameProfile,
      user: user,
    );

    // ---- Phase 2: Build achievements locally ----
    final achievements = _computeWeeklyAchievements(
      weekLogs: weekLogs,
      weekCravings: weekCravings,
      gameProfile: gameProfile,
      user: user,
      stats: stats,
    );

    // ---- Phase 3: Generate insights locally ----
    final localInsights = _computeWeeklyInsights(
      weekLogs: weekLogs,
      weekCravings: weekCravings,
      user: user,
      gameProfile: gameProfile,
      stats: stats,
    );

    // ---- Phase 4: Try LLM for enhanced summary and insights ----
    String summary = '';
    String? motivationalQuote;
    List<AnalysisInsight> llmHighlights = [];

    if (_llmService != null &&
        _llmService.isConfigured &&
        weekLogs.length >= 3) {
      try {
        final llmResult = await _generateLlmWeeklyReport(
          user: user,
          gameProfile: gameProfile,
          weekLogs: weekLogs,
          weekCravings: weekCravings,
          stats: stats,
        );
        summary = llmResult['summary'] as String? ?? '';
        motivationalQuote = llmResult['motivationalQuote'] as String?;
        llmHighlights = (llmResult['highlights'] as List?)
                ?.map((h) => AnalysisInsight(
                      type: (h['type'] as String?) ?? 'pattern',
                      title: (h['title'] as String?) ?? '',
                      description: (h['description'] as String?) ?? '',
                      recommendation: (h['recommendation'] as String?),
                      severity: (h['severity'] as int?) ?? 3,
                    ))
                .toList() ??
            [];
      } catch (_) {
        // Fall through to local generation
      }
    }

    // Local fallback for summary
    if (summary.isEmpty) {
      summary = _generateLocalWeeklySummary(
        user: user,
        gameProfile: gameProfile,
        stats: stats,
        trend: _patternAnalyzer.detectTrend(weekLogs),
      );
    }

    motivationalQuote ??= AnalysisUtils.randomMotivationalQuote();

    // Calculate overall score
    final overallScore = _calculateWeeklyOverallScore(stats);

    // Merge local and LLM insights, deduplicate by title
    final allInsights = <String, AnalysisInsight>{};
    for (final insight in localInsights) {
      allInsights[insight.title] = insight;
    }
    for (final insight in llmHighlights) {
      if (insight.title.isNotEmpty && !allInsights.containsKey(insight.title)) {
        allInsights[insight.title] = insight;
      }
    }

    return WeeklyReport(
      weekNumber: weekNumber,
      summary: summary,
      achievements: achievements,
      insights: allInsights.values.toList()
        ..sort((a, b) => b.severity.compareTo(a.severity)),
      statistics: stats,
      motivationalQuote: motivationalQuote,
      overallScore: overallScore,
    );
  }

  // ---------------------------------------------------------------------------
  // Statistics
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _computeWeeklyStatistics({
    required List<DailyLogEntry> weekLogs,
    required List<CravingEntry> weekCravings,
    required GameProfile gameProfile,
    required User user,
  }) {
    final totalCravings = weekCravings.length;
    final avgIntensity = totalCravings > 0
        ? weekCravings.map((c) => c.intensity).reduce((a, b) => a + b) /
            totalCravings
        : 0.0;

    final resistedCount = weekCravings.where((c) => c.resolved).length;
    final resistRate = totalCravings > 0 ? resistedCount / totalCravings : 0.0;

    final avgMood = weekLogs.isNotEmpty
        ? weekLogs.map((l) => l.mood).reduce((a, b) => a + b) / weekLogs.length
        : 0.0;

    final relapseDays = weekLogs.where((l) => l.relapsed).length;

    // Peak day
    String? peakDay;
    if (weekCravings.length >= 3) {
      final dayCount = <int, int>{};
      for (final c in weekCravings) {
        dayCount[c.timestamp.weekday] =
            (dayCount[c.timestamp.weekday] ?? 0) + 1;
      }
      final weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final maxDay =
          dayCount.entries.reduce((a, b) => a.value > b.value ? a : b);
      peakDay = weekdayNames[maxDay.key - 1];
    }

    // Peak hour
    int? peakHour;
    if (weekCravings.length >= 3) {
      final timePattern = _patternAnalyzer.analyzeTimePatterns(weekCravings);
      peakHour = timePattern.peakHour;
    }

    // XP estimate (rough)
    final xpEarned = weekLogs.length * 20 + // checkin
        weekCravings.where((c) => c.resolved).length * 15 + // resisted
        gameProfile.exercisesCompleted * 25; // exercises

    return {
      'totalCravings': totalCravings,
      'avgIntensity': avgIntensity.toStringAsFixed(1),
      'avgMood': avgMood.toStringAsFixed(1),
      'resistedCount': resistedCount,
      'resistRate': (resistRate * 100).toStringAsFixed(0),
      'relapseDays': relapseDays,
      'peakDay': peakDay,
      'peakHour': peakHour,
      'loggedDays': weekLogs.length,
      'xpEarned': xpEarned,
      'streakDays': gameProfile.streakDays,
      'daysSinceQuit': user.daysSinceQuit,
    };
  }

  // ---------------------------------------------------------------------------
  // Achievements
  // ---------------------------------------------------------------------------

  List<String> _computeWeeklyAchievements({
    required List<DailyLogEntry> weekLogs,
    required List<CravingEntry> weekCravings,
    required GameProfile gameProfile,
    required User user,
    required Map<String, dynamic> stats,
  }) {
    final achievements = <String>[];

    final totalCravings = stats['totalCravings'] as int;
    final resistedCount = stats['resistedCount'] as int;
    final relapseDays = stats['relapseDays'] as int;

    // Perfect week (no relapses)
    if (weekLogs.length >= 7 && relapseDays == 0) {
      achievements.add('完美一周！零复发');
    }

    // High resist rate
    final resistRate = totalCravings > 0 ? resistedCount / totalCravings : 0.0;
    if (totalCravings >= 5 && resistRate >= 0.9) {
      achievements.add('渴望抵抗率超过90%');
    }

    // Streak milestone
    if (gameProfile.streakDays >= 7 && gameProfile.streakDays < 14) {
      achievements.add('连续打卡突破7天');
    } else if (gameProfile.streakDays >= 14 && gameProfile.streakDays < 30) {
      achievements.add('连续打卡突破14天');
    } else if (gameProfile.streakDays >= 30) {
      achievements.add('连续打卡超过30天');
    }

    // Good mood week
    if (weekLogs.length >= 5) {
      final avgMood = double.parse(stats['avgMood'] as String);
      if (avgMood >= 4.0) {
        achievements.add('本周平均心情评分优秀（${stats['avgMood']}分）');
      }
    }

    // No cravings at all
    if (totalCravings == 0 && weekLogs.length >= 3) {
      achievements.add('本周零渴望记录！');
    }

    // Declining cravings
    if (weekCravings.length >= 5) {
      final trend = _patternAnalyzer.detectCravingTrend(weekCravings);
      if (trend == TrendDirection.improving) {
        achievements.add('渴望强度呈下降趋势');
      }
    }

    if (achievements.isEmpty) {
      achievements.add('坚持了又一周，每一步都算数');
    }

    return achievements;
  }

  // ---------------------------------------------------------------------------
  // Insights
  // ---------------------------------------------------------------------------

  List<AnalysisInsight> _computeWeeklyInsights({
    required List<DailyLogEntry> weekLogs,
    required List<CravingEntry> weekCravings,
    required User user,
    required GameProfile gameProfile,
    required Map<String, dynamic> stats,
  }) {
    final insights = <AnalysisInsight>[];

    // Time pattern insight
    if (weekCravings.length >= 5) {
      final timePattern = _patternAnalyzer.analyzeTimePatterns(weekCravings);
      if (timePattern.peakHour >= 0) {
        insights.add(AnalysisInsight(
          type: 'pattern',
          title: '本周时间规律',
          description: '本周渴望高峰在${TimePattern.formatHour(timePattern.peakHour)}，'
              '平均强度${timePattern.peakIntensity.toStringAsFixed(1)}。',
          recommendation: '下周在高风险时段提前安排替代活动。',
          severity: timePattern.peakIntensity >= 7 ? 4 : 2,
        ));
      }
    }

    // Mood-craving insight
    if (weekLogs.length >= 5) {
      final correlation =
          _patternAnalyzer.calculateMoodCravingCorrelation(weekLogs);
      if (correlation.abs() >= 0.3) {
        insights.add(AnalysisInsight(
          type: 'pattern',
          title: '情绪关联',
          description:
              _patternAnalyzer.describeMoodCravingRelationship(correlation),
          severity: correlation.abs() >= 0.6 ? 4 : 2,
        ));
      }
    }

    // Trigger insight
    if (weekCravings.length >= 3) {
      final triggers = _patternAnalyzer.rankTriggers(weekCravings);
      if (triggers.isNotEmpty) {
        insights.add(AnalysisInsight(
          type: 'suggestion',
          title: '应对"${triggers.first.trigger}"',
          description:
              '"${triggers.first.trigger}"本周出现了${triggers.first.count}次，'
              '占${(triggers.first.percentage * 100).toStringAsFixed(0)}%。',
          recommendation:
              _recommendationBuilder.buildTriggerRecommendation(triggers.first),
          severity: 3,
        ));
      }
    }

    // Relapse analysis
    final relapseDays = stats['relapseDays'] as int;
    if (relapseDays > 0) {
      insights.add(AnalysisInsight(
        type: 'risk',
        title: '本周有$relapseDays天复发',
        description: '复发是旅程的一部分，重要的是从中学习。'
            '分析每次复发的触发因素，更新你的预防计划。',
        recommendation: '回顾复发预防计划，更新高风险场景列表。',
        severity: relapseDays >= 3
            ? 5
            : relapseDays >= 2
                ? 4
                : 3,
      ));
    }

    return insights;
  }

  // ---------------------------------------------------------------------------
  // LLM weekly report
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _generateLlmWeeklyReport({
    required User user,
    required GameProfile gameProfile,
    required List<DailyLogEntry> weekLogs,
    required List<CravingEntry> weekCravings,
    required Map<String, dynamic> stats,
  }) async {
    final userContext = _promptBuilder.buildUserContext(user, gameProfile);
    final weekData =
        _promptBuilder.buildWeekDataText(weekLogs, weekCravings, stats);

    final rawJson = await _llmService!.generateWeeklyReport(
      userContext: userContext,
      weekData: weekData,
    );

    return AnalysisUtils.parseJsonSafely(rawJson);
  }

  // ---------------------------------------------------------------------------
  // Local fallback summary
  // ---------------------------------------------------------------------------

  String _generateLocalWeeklySummary({
    required User user,
    required GameProfile gameProfile,
    required Map<String, dynamic> stats,
    required TrendDirection trend,
  }) {
    final totalCravings = stats['totalCravings'] as int;
    final relapseDays = stats['relapseDays'] as int;
    final resistRate = stats['resistRate'] as String;

    final trendText = trend == TrendDirection.improving
        ? '整体趋势向好'
        : trend == TrendDirection.worsening
            ? '需要注意近期状态'
            : '保持稳定';

    final base = '第${stats['streakDays']}天，$trendText。';

    if (relapseDays == 0 && totalCravings > 0) {
      return '$base本周记录了$totalCravings次渴望，成功抵抗了$resistRate%。';
    } else if (relapseDays == 0) {
      return '$base本周状态很好，继续保持！';
    } else {
      return '$base本周有$relapseDays天复发，但每次都是学习的机会。'
          '分析原因，继续前进。';
    }
  }

  // ---------------------------------------------------------------------------
  // Overall score
  // ---------------------------------------------------------------------------

  int _calculateWeeklyOverallScore(Map<String, dynamic> stats) {
    int score = 50; // Base score

    // Relapse penalty
    final relapseDays = stats['relapseDays'] as int;
    score -= relapseDays * 15;

    // Resist rate bonus
    final resistRate = double.parse(stats['resistRate'] as String) / 100;
    score += (resistRate * 30).round();

    // Mood bonus
    final avgMood = double.parse(stats['avgMood'] as String);
    score += ((avgMood - 3) * 10).round();

    // Log consistency bonus
    final loggedDays = stats['loggedDays'] as int;
    if (loggedDays >= 7) {
      score += 10;
    } else if (loggedDays >= 5) {
      score += 5;
    }

    return score.clamp(0, 100);
  }
}
