import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/analysis.dart';
import 'pattern_analyzer.dart';
import 'llm_service.dart';
import 'analysis_utils.dart';
import 'llm_prompt_builder.dart';

/// Generates the daily "smart card" insight shown on the home screen.
///
/// Tries LLM-enhanced generation first and falls back to local heuristic
/// generation when the LLM is unavailable or fails.
class DailyInsightGenerator {
  final PatternAnalyzer _patternAnalyzer;
  final LlmService? _llmService;
  final LlmPromptBuilder _promptBuilder;

  DailyInsightGenerator({
    required PatternAnalyzer patternAnalyzer,
    LlmService? llmService,
    required LlmPromptBuilder promptBuilder,
  })  : _patternAnalyzer = patternAnalyzer,
        _llmService = llmService,
        _promptBuilder = promptBuilder;

  /// Main entry point — generates a [DailyInsight].
  ///
  /// Tries LLM first when configured and enough craving data exists,
  /// otherwise falls back to local heuristic generation.
  Future<DailyInsight> generateDailyInsight({
    required User user,
    required GameProfile gameProfile,
    required DailyLogEntry? todayLog,
    required List<DailyLogEntry> recentLogs,
    required List<CravingEntry> recentCravings,
    required int riskScore,
  }) async {
    // Try LLM first for the richest insight
    if (_llmService != null &&
        _llmService.isConfigured &&
        recentCravings.length >= 2) {
      try {
        return await _generateLlmDailyInsight(
          user: user,
          gameProfile: gameProfile,
          todayLog: todayLog,
          recentLogs: recentLogs,
          recentCravings: recentCravings,
          riskScore: riskScore,
        );
      } catch (_) {
        // Fall through to local generation
      }
    }

    // Local generation fallback
    return _generateLocalDailyInsight(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
      recentLogs: recentLogs,
      recentCravings: recentCravings,
      riskScore: riskScore,
    );
  }

  // ---------------------------------------------------------------------------
  // Private — LLM-based generation
  // ---------------------------------------------------------------------------

  Future<DailyInsight> _generateLlmDailyInsight({
    required User user,
    required GameProfile gameProfile,
    required DailyLogEntry? todayLog,
    required List<DailyLogEntry> recentLogs,
    required List<CravingEntry> recentCravings,
    required int riskScore,
  }) async {
    final userContext = _promptBuilder.buildUserContext(user, gameProfile);
    final todayData =
        _promptBuilder.buildTodayData(todayLog, recentLogs, recentCravings);

    // Run local analysis for context
    final localAnalysisText = _promptBuilder.buildLocalAnalysisText(
      recentCravings: recentCravings,
      recentLogs: recentLogs,
    );

    final rawJson = await _llmService!.generatePersonalizedInsight(
      userContext: userContext,
      todayData: todayData,
      localAnalysis: localAnalysisText,
    );

    final parsed = AnalysisUtils.parseJsonSafely(rawJson);

    return DailyInsight(
      headline: parsed['headline'] as String? ?? '今日洞察',
      body: parsed['body'] as String? ?? '继续保持你的努力。',
      actionText: parsed['actionText'] as String? ?? '查看详情',
      type: AnalysisUtils.parseInsightType(parsed['type'] as String?),
      relapseRiskScore: riskScore,
    );
  }

  // ---------------------------------------------------------------------------
  // Private — Local heuristic generation
  // ---------------------------------------------------------------------------

  DailyInsight _generateLocalDailyInsight({
    required User user,
    required GameProfile gameProfile,
    required DailyLogEntry? todayLog,
    required List<DailyLogEntry> recentLogs,
    required List<CravingEntry> recentCravings,
    required int riskScore,
  }) {
    final days = user.daysSinceQuit;
    final hour = DateTime.now().hour;

    // Critical risk
    if (riskScore >= 70) {
      final reason =
          _identifyHighRiskReason(todayLog, recentCravings, recentLogs);
      return DailyInsight(
        headline: '今天需要特别注意',
        body: '你的风险评估得分为$riskScore/100。$reason'
            '建议今天格外警惕，准备好应对策略。',
        actionText: '使用SOS呼吸练习',
        actionRoute: '/sos',
        type: InsightType.critical,
        relapseRiskScore: riskScore,
      );
    }

    // Check if entering a known high-risk hour
    if (recentCravings.length >= 5) {
      final timePattern = _patternAnalyzer.analyzeTimePatterns(recentCravings);
      final likelihood = _patternAnalyzer.predictCravingLikelihood(
        hour,
        recentCravings,
      );
      if (likelihood >= 0.5 && timePattern.highRiskHours.contains(hour)) {
        return DailyInsight(
          headline: '现在是你脆弱的时段',
          body: '数据显示${TimePattern.formatHour(hour)}前后是你的渴望高峰期。'
              '你正在高风险时段中，提前做好心理准备。',
          actionText: '做一次冲浪练习',
          actionRoute: '/surf',
          type: InsightType.warning,
          relapseRiskScore: riskScore,
        );
      }
    }

    // First day
    if (days == 0 && user.hasQuitDate) {
      return DailyInsight(
        headline: '第一天，最重要的一天',
        body: '今天是你戒断旅程的起点。前72小时身体会有戒断反应，'
            '这是完全正常的——说明你的身体正在开始修复。',
        actionText: '了解身体恢复时间线',
        actionRoute: '/health',
        type: InsightType.motivational,
        relapseRiskScore: 50,
      );
    }

    // Streak milestone
    if (gameProfile.streakDays > 0 &&
        gameProfile.streakDays == gameProfile.longestStreak &&
        gameProfile.streakDays >= 7) {
      return DailyInsight(
        headline: '你正在创造新纪录！',
        body: '连续${gameProfile.streakDays}天！这是你迄今为止最长的连续记录。'
            '每一次坚持都在重塑你的大脑。',
        actionText: '查看你的成就',
        actionRoute: '/profile',
        type: InsightType.achievement,
        relapseRiskScore: riskScore,
      );
    }

    // Mood-based insight
    if (todayLog != null && todayLog.mood <= 2) {
      return DailyInsight(
        headline: '今天心情不太好',
        body: '你今天的心情评分较低。低情绪是渴望的常见触发因素，'
            '今天要格外注意情绪管理。',
        actionText: '试试情绪调节练习',
        actionRoute: '/skills',
        type: InsightType.warning,
        relapseRiskScore: riskScore,
      );
    }

    // Achievement: long streak
    if (days >= 30 && gameProfile.streakDays >= 14) {
      return DailyInsight(
        headline: '$days天，习惯正在形成',
        body: '研究表明，持续的重复行为在大约66天后会变成自动习惯。'
            '你已经走了${(days / 66 * 100).toStringAsFixed(0)}%的路程。',
        actionText: '继续坚持',
        type: InsightType.motivational,
        relapseRiskScore: riskScore,
      );
    }

    // No data yet
    if (recentLogs.isEmpty && recentCravings.isEmpty) {
      return DailyInsight(
        headline: '开始记录你的旅程',
        body: '每天打卡并记录渴望，AI教练就能为你提供个性化的分析和建议。'
            '数据越多，分析越精准。',
        actionText: '完成今日打卡',
        actionRoute: '/checkin',
        type: InsightType.neutral,
        relapseRiskScore: 50,
      );
    }

    // Positive trend
    final trend = _patternAnalyzer.detectTrend(recentLogs);
    if (trend == TrendDirection.improving) {
      return DailyInsight(
        headline: '你在越变越好',
        body: '近期的数据显示你的状态正在改善。心情更稳定，渴望在减弱。'
            '继续你正在做的事情，它正在起作用。',
        actionText: '查看详细分析',
        actionRoute: '/analysis',
        type: InsightType.achievement,
        relapseRiskScore: 20,
      );
    }

    // Default neutral
    return DailyInsight(
      headline: '继续你的每日节奏',
      body: '每天坚持打卡和记录是成功的关键。'
          '连续${gameProfile.streakDays}天了，保持这个习惯。',
      actionText: '完成今日打卡',
      actionRoute: '/checkin',
      type: InsightType.neutral,
      relapseRiskScore: riskScore,
    );
  }

  /// Identifies why the user is at high risk, for the daily insight body.
  String _identifyHighRiskReason(
    DailyLogEntry? todayLog,
    List<CravingEntry> recentCravings,
    List<DailyLogEntry> recentLogs,
  ) {
    final reasons = <String>[];

    if (todayLog != null) {
      if (todayLog.mood <= 2) reasons.add('今天心情较低');
      if (todayLog.urgeLevel != null && todayLog.urgeLevel! >= 7) {
        reasons.add('当前渴望强度较高');
      }
    }

    if (recentCravings.isNotEmpty) {
      final recentWindow = DateTime.now().subtract(const Duration(days: 2));
      final veryRecent = recentCravings
          .where((c) => c.timestamp.isAfter(recentWindow))
          .toList();
      if (veryRecent.length >= 4) {
        reasons.add('最近两天渴望频繁（${veryRecent.length}次）');
      }
    }

    final recentRelapses = recentLogs.where((l) => l.relapsed).length;
    if (recentRelapses >= 1) {
      reasons.add('近期有复发记录');
    }

    if (reasons.isEmpty) return '';
    return '${reasons.join("，")}。';
  }
}
