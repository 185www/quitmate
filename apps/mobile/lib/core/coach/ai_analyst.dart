import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/analysis.dart';
import 'pattern_analyzer.dart';
import 'llm_service.dart';
import 'analysis_utils.dart';
import 'recommendation_builder.dart';
import 'action_suggestion_engine.dart';
import 'llm_prompt_builder.dart';
import 'daily_insight_generator.dart';
import 'weekly_report_generator.dart';

/// Deep AI analysis engine that transforms the AI coach from a "chatbot"
/// into a "behavioral analyst" that studies user data and generates
/// personalized insights.
///
/// Architecture:
/// 1. [PatternAnalyzer] runs LOCALLY for instant results (no API needed)
/// 2. [LlmService] optionally ENHANCES results with deeper AI analysis
/// 3. [AiAnalyst] orchestrates both, falling back gracefully when LLM is unavailable
///
/// The heavy lifting is delegated to focused helper classes:
/// - [DailyInsightGenerator] — daily smart-card insight
/// - [WeeklyReportGenerator] — weekly progress report
/// - [LlmPromptBuilder] — structured prompt construction for LLM calls
/// - [RecommendationBuilder] — human-readable recommendation strings
/// - [ActionSuggestionEngine] — personalized action suggestions
/// - [AnalysisUtils] — shared utility functions
class AiAnalyst {
  final PatternAnalyzer _patternAnalyzer;
  final LlmService? _llmService;

  // Helper instances (created once, reused)
  late final RecommendationBuilder _recommendationBuilder;
  late final ActionSuggestionEngine _actionEngine;
  late final LlmPromptBuilder _promptBuilder;
  late final DailyInsightGenerator _dailyInsightGenerator;
  late final WeeklyReportGenerator _weeklyReportGenerator;

  AiAnalyst({
    PatternAnalyzer? patternAnalyzer,
    LlmService? llmService,
  })  : _patternAnalyzer = patternAnalyzer ?? PatternAnalyzer(),
        _llmService = llmService {
    _recommendationBuilder = const RecommendationBuilder();
    _actionEngine = const ActionSuggestionEngine();
    _promptBuilder = LlmPromptBuilder(_patternAnalyzer);
    _dailyInsightGenerator = DailyInsightGenerator(
      patternAnalyzer: _patternAnalyzer,
      llmService: _llmService,
      promptBuilder: _promptBuilder,
    );
    _weeklyReportGenerator = WeeklyReportGenerator(
      patternAnalyzer: _patternAnalyzer,
      llmService: _llmService,
      promptBuilder: _promptBuilder,
      recommendationBuilder: _recommendationBuilder,
    );
  }

  /// Analyze user's craving patterns and generate insights.
  ///
  /// Always runs local analysis first. If LLM is configured, also sends data
  /// for deeper AI-enhanced analysis and merges the results.
  Future<List<AnalysisInsight>> analyzeCravingPatterns({
    required List<CravingEntry> cravings,
    required List<DailyLogEntry> logs,
    required User user,
    required GameProfile gameProfile,
  }) async {
    if (cravings.isEmpty && logs.isEmpty) {
      return [];
    }

    final insights = <AnalysisInsight>[];

    // ---- Phase 1: Local Pattern Analysis (always runs) ----

    // 1. Time-of-day patterns
    if (cravings.length >= 3) {
      final timePattern = _patternAnalyzer.analyzeTimePatterns(cravings);
      insights.add(AnalysisInsight(
        type: 'pattern',
        title: '时间规律',
        description: timePattern.summary,
        recommendation: _recommendationBuilder.buildTimeRecommendation(
            timePattern),
        severity: timePattern.highRiskHours.length >= 4 ? 4 : 3,
        data: {
          'peakHour': timePattern.peakHour,
          'peakIntensity': timePattern.peakIntensity,
          'highRiskHours': timePattern.highRiskHours,
        },
      ));
    }

    // 2. Day-of-week patterns
    if (cravings.length >= 5) {
      final dayPatterns = _patternAnalyzer.analyzeDayPatterns(cravings);
      if (dayPatterns.length >= 2) {
        final highRiskDays = dayPatterns
            .where((d) => d.isHighRisk)
            .map((d) => d.weekday)
            .toList();
        if (highRiskDays.isNotEmpty) {
          insights.add(AnalysisInsight(
            type: 'pattern',
            title: '星期规律',
            description: '你的高风险日是：${highRiskDays.join('、')}。'
                '${highRiskDays.length > 1 ? "这些天的渴望频率明显高于平均水平。" : "这一天的渴望特别集中。"}',
            recommendation: highRiskDays.length == 1
                ? '每周${highRiskDays.first}提前做好心理准备，安排替代活动。'
                : '在${highRiskDays.join('、')}这些日子里，提前安排好替代活动，减少空闲时间。',
            severity: 3,
            data: {
              'highRiskDays': highRiskDays,
              'dayPatterns': dayPatterns
                  .map((d) => {
                        'day': d.weekday,
                        'count': d.cravingCount,
                        'avg': d.avgIntensity.toStringAsFixed(1),
                      })
                  .toList(),
            },
          ));
        }
      }
    }

    // 3. Mood-craving correlation
    if (logs.length >= 5) {
      final correlation =
          _patternAnalyzer.calculateMoodCravingCorrelation(logs);
      if (correlation.abs() >= 0.3) {
        insights.add(AnalysisInsight(
          type: 'pattern',
          title: '情绪-渴望关联',
          description:
              _patternAnalyzer.describeMoodCravingRelationship(correlation),
          recommendation: correlation < -0.3
              ? '当感到情绪低落时，立即启动应对计划——深呼吸、散步、或者找人聊聊。'
              : '注意在心情好的时候也不要放松警惕，尤其在社交场合。',
          severity: correlation.abs() >= 0.6 ? 4 : 2,
          data: {'correlation': correlation},
        ));
      }
    }

    // 4. Trigger analysis
    if (cravings.length >= 3) {
      final triggers = _patternAnalyzer.rankTriggers(cravings);
      if (triggers.isNotEmpty) {
        final topTrigger = triggers.first;
        insights.add(AnalysisInsight(
          type: 'pattern',
          title: '主要触发因素',
          description: '"${topTrigger.trigger}"是你最频繁的触发因素，'
              '占所有触发记录的${(topTrigger.percentage * 100).toStringAsFixed(0)}%，'
              '平均渴望强度${topTrigger.avgIntensity.toStringAsFixed(1)}。',
          recommendation: _recommendationBuilder
              .buildTriggerRecommendation(topTrigger),
          severity: topTrigger.avgIntensity >= 7 ? 4 : 2,
          data: {
            'topTrigger': topTrigger.trigger,
            'topTriggerCount': topTrigger.count,
            'topTriggerPct':
                (topTrigger.percentage * 100).toStringAsFixed(0),
            'allTriggers': triggers
                .take(5)
                .map((t) => {
                      'name': t.trigger,
                      'count': t.count,
                      'pct': (t.percentage * 100).toStringAsFixed(0),
                    })
                .toList(),
          },
        ));
      }
    }

    // 5. Trend analysis
    final trend = _patternAnalyzer.detectTrend(logs);
    final cravingTrend = _patternAnalyzer.detectCravingTrend(cravings);
    insights.add(AnalysisInsight(
      type: 'trend',
      title: _recommendationBuilder.trendTitle(trend, cravingTrend),
      description: _recommendationBuilder.trendDescription(trend, cravingTrend),
      recommendation: _recommendationBuilder.trendRecommendation(trend),
      severity: trend == TrendDirection.worsening
          ? 4
          : trend == TrendDirection.improving
              ? 1
              : 2,
      data: {
        'logTrend': trend.name,
        'cravingTrend': cravingTrend.name,
      },
    ));

    // ---- Phase 2: LLM Enhancement (optional) ----
    if (_llmService != null && _llmService.isConfigured) {
      try {
        final userContext = _promptBuilder.buildUserContext(user, gameProfile);
        final localAnalysisText = _promptBuilder.buildLocalAnalysisText(
          recentCravings: cravings,
          recentLogs: logs,
        );
        final llmInsights = await _promptBuilder.enhanceWithLlm(
          llmService: _llmService,
          userContext: userContext,
          localAnalysisText: localAnalysisText,
          localInsights: insights,
        );
        insights.addAll(llmInsights);
      } catch (_) {
        // LLM failed — local insights are still valuable
      }
    }

    // Sort by severity descending
    insights.sort((a, b) => b.severity.compareTo(a.severity));
    return insights;
  }

  /// Generate a daily personalized insight for the dashboard.
  ///
  /// This is the "smart card" shown on the home screen. It should feel
  /// like the app truly understands what's happening with the user.
  Future<DailyInsight> generateDailyInsight({
    required User user,
    required GameProfile gameProfile,
    required DailyLogEntry? todayLog,
    required List<DailyLogEntry> recentLogs,
    required List<CravingEntry> recentCravings,
  }) async {
    final riskScore = calculateRelapseRiskScore(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
      recentLogs: recentLogs,
      recentCravings: recentCravings,
    );

    return _dailyInsightGenerator.generateDailyInsight(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
      recentLogs: recentLogs,
      recentCravings: recentCravings,
      riskScore: riskScore,
    );
  }

  /// Generate a weekly progress report with AI-powered analysis.
  Future<WeeklyReport> generateWeeklyReport({
    required User user,
    required GameProfile gameProfile,
    required List<DailyLogEntry> weekLogs,
    required List<CravingEntry> weekCravings,
  }) {
    return _weeklyReportGenerator.generateWeeklyReport(
      user: user,
      gameProfile: gameProfile,
      weekLogs: weekLogs,
      weekCravings: weekCravings,
    );
  }

  /// Calculate relapse risk score (0-100).
  ///
  /// Combines local heuristic analysis with optional LLM assessment.
  int calculateRelapseRiskScore({
    required User user,
    required GameProfile gameProfile,
    DailyLogEntry? todayLog,
    required List<DailyLogEntry> recentLogs,
    required List<CravingEntry> recentCravings,
  }) {
    return _patternAnalyzer.calculateLocalRiskScore(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
      recentLogs: recentLogs,
      recentCravings: recentCravings,
    );
  }

  /// Suggest a personalized action based on the user's current state.
  ///
  /// Returns the single most relevant action the user should take right now.
  PersonalizedAction suggestAction({
    required int relapseRisk,
    required User user,
    required GameProfile gameProfile,
    DailyLogEntry? todayLog,
  }) {
    final days = user.daysSinceQuit;
    final hour = DateTime.now().hour;

    // Priority 1: Critical risk — immediate intervention
    if (relapseRisk >= 70) {
      return _actionEngine.criticalRiskAction(relapseRisk, hour);
    }

    // Priority 2: Today hasn't been checked in
    if (todayLog == null && gameProfile.streakDays > 0) {
      return const PersonalizedAction(
        title: '完成今日打卡',
        description: '你的连续打卡记录可能会中断！今天还没有签到。',
        route: '/checkin',
        icon: 'check_circle',
        priority: 8,
      );
    }

    // Priority 3: High risk — preventive action
    if (relapseRisk >= 45) {
      return _actionEngine.highRiskAction(relapseRisk, hour, days);
    }

    // Priority 4: Early stage — educational/supportive
    if (days <= 7 && days > 0) {
      return const PersonalizedAction(
        title: '了解身体恢复进度',
        description: '你正处于身体修复的关键期，查看你的健康里程碑。',
        route: '/health',
        icon: 'favorite',
        priority: 5,
      );
    }

    // Priority 5: Suggest skill training
    if (gameProfile.exercisesCompleted < 5) {
      return const PersonalizedAction(
        title: '尝试CBT技能训练',
        description: '认知行为训练可以帮助你识别和改变不健康的思维模式。',
        route: '/skills',
        icon: 'psychology',
        priority: 4,
      );
    }

    // Priority 6: Streak milestone celebration
    if (gameProfile.streakDays == gameProfile.longestStreak &&
        gameProfile.streakDays >= 7) {
      return PersonalizedAction(
        title: '你创造了新纪录！',
        description: '连续${gameProfile.streakDays}天打卡，这是你的最佳成绩！',
        route: '/profile',
        icon: 'emoji_events',
        priority: 3,
      );
    }

    // Default: gentle encouragement to engage
    return _actionEngine.defaultAction(hour, days);
  }
}
