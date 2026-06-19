import 'dart:convert';
import 'dart:math';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/analysis.dart';
import 'pattern_analyzer.dart';
import 'llm_service.dart';

/// Deep AI analysis engine that transforms the AI coach from a "chatbot"
/// into a "behavioral analyst" that studies user data and generates
/// personalized insights.
///
/// Architecture:
/// 1. [PatternAnalyzer] runs LOCALLY for instant results (no API needed)
/// 2. [LlmService] optionally ENHANCES results with deeper AI analysis
/// 3. [AiAnalyst] orchestrates both, falling back gracefully when LLM is unavailable
class AiAnalyst {
  final PatternAnalyzer _patternAnalyzer;
  final LlmService? _llmService;

  AiAnalyst({
    PatternAnalyzer? patternAnalyzer,
    LlmService? llmService,
  })  : _patternAnalyzer = patternAnalyzer ?? PatternAnalyzer(),
        _llmService = llmService;

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
        recommendation: _buildTimeRecommendation(timePattern),
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
      final correlation = _patternAnalyzer.calculateMoodCravingCorrelation(logs);
      if (correlation.abs() >= 0.3) {
        insights.add(AnalysisInsight(
          type: 'pattern',
          title: '情绪-渴望关联',
          description: _patternAnalyzer.describeMoodCravingRelationship(correlation),
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
          recommendation: _buildTriggerRecommendation(topTrigger),
          severity: topTrigger.avgIntensity >= 7 ? 4 : 2,
          data: {
            'topTrigger': topTrigger.trigger,
            'topTriggerCount': topTrigger.count,
            'topTriggerPct': (topTrigger.percentage * 100).toStringAsFixed(0),
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
      title: _trendTitle(trend, cravingTrend),
      description: _trendDescription(trend, cravingTrend),
      recommendation: _trendRecommendation(trend),
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
        final llmInsights = await _enhanceWithLlm(
          cravings: cravings,
          logs: logs,
          user: user,
          gameProfile: gameProfile,
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

    // Try LLM first for the richest insight
    if (_llmService != null && _llmService.isConfigured && recentCravings.length >= 2) {
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

  /// Generate a weekly progress report with AI-powered analysis.
  Future<WeeklyReport> generateWeeklyReport({
    required User user,
    required GameProfile gameProfile,
    required List<DailyLogEntry> weekLogs,
    required List<CravingEntry> weekCravings,
  }) async {
    final weekNumber = _currentWeekNumber();

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

    if (_llmService != null && _llmService.isConfigured && weekLogs.length >= 3) {
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

    motivationalQuote ??= _randomMotivationalQuote();

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
      return _criticalRiskAction(relapseRisk, hour);
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
      return _highRiskAction(relapseRisk, hour, days);
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
    return _defaultAction(hour, days);
  }

  // =========================================================================
  // Private Methods — Local Insight Generation
  // =========================================================================

  String _buildTimeRecommendation(TimePattern timePattern) {
    if (timePattern.highRiskHours.isEmpty) return '';

    final peakTime = TimePattern.formatHour(timePattern.peakHour);
    if (timePattern.highRiskHours.length >= 3) {
      return '在${TimePattern.formatHour(timePattern.highRiskHours.first)}'
          '到${TimePattern.formatHour(timePattern.highRiskHours.last)}期间，'
          '设置提醒提前做准备，安排替代活动。';
    }
    return '每天$peakTime前后是你最脆弱的时段，提前准备好应对策略。';
  }

  String _buildTriggerRecommendation(TriggerRanking trigger) {
    switch (trigger.trigger) {
      case '压力' || '工作压力' || '焦虑':
        return '当感到压力时，尝试"4-7-8呼吸法"或短暂的散步。'
            '提前准备一个"压力应对清单"，列出3-5个替代行为。';
      case '社交' || '聚会' || '朋友':
        return '社交场合是最常见的复吸触发因素。提前准备拒绝话术，'
            '告诉至少一个朋友你的决定，让他们支持你。';
      case '饭后' || '吃饭后' || '餐后':
        return '饭后渴望通常与习惯有关。准备一个饭后替代仪式：'
            '嚼口香糖、刷牙、或者散步10分钟。';
      case '无聊' || '空闲':
        return '无聊是渴望的温床。准备一个"无聊急救包"：'
            '一个有趣的应用、一本书、一个拼图——任何能快速转移注意力的事。';
      case '情绪低落' || '难过' || '抑郁':
        return '情绪管理是关键。当感到低落时，不要独自承受——'
            '找人聊聊、写日记、或者做些让自己开心的小事。';
      case '熬夜' || '失眠' || '疲劳':
        return '疲劳会削弱意志力。保持良好的睡眠习惯，'
            '如果失眠，试试"技能训练"里的渐进式放松练习。';
      default:
        return '识别到"${trigger.trigger}"是你主要的触发因素。'
            '每次这个触发出现时，立刻执行你的应对计划。';
    }
  }

  String _trendTitle(TrendDirection logTrend, TrendDirection cravingTrend) {
    if (logTrend == TrendDirection.improving &&
        cravingTrend == TrendDirection.improving) {
      return '持续进步';
    }
    if (logTrend == TrendDirection.worsening &&
        cravingTrend == TrendDirection.worsening) {
      return '需要关注';
    }
    if (logTrend == TrendDirection.improving) {
      return '心情在好转';
    }
    if (cravingTrend == TrendDirection.improving) {
      return '渴望在减弱';
    }
    if (logTrend == TrendDirection.worsening) {
      return '心情波动';
    }
    if (cravingTrend == TrendDirection.worsening) {
      return '渴望有增强';
    }
    return '保持稳定';
  }

  String _trendDescription(
      TrendDirection logTrend, TrendDirection cravingTrend) {
    if (logTrend == TrendDirection.improving &&
        cravingTrend == TrendDirection.improving) {
      return '太棒了！你的心情和渴望强度都在向好的方向发展。'
          '这说明你正在建立新的健康习惯，继续保持！';
    }
    if (logTrend == TrendDirection.worsening &&
        cravingTrend == TrendDirection.worsening) {
      return '近期数据显示你的心情和渴望强度都有恶化的趋势。'
          '这不是失败，而是一个信号——可能需要调整你的应对策略。';
    }
    if (logTrend == TrendDirection.improving) {
      return '你的整体心情在改善，这是一个积极的信号。'
          '继续关注情绪管理，它会帮助你更好地应对渴望。';
    }
    if (cravingTrend == TrendDirection.improving) {
      return '你的渴望强度正在逐渐减弱，这说明你的大脑正在适应。'
          '每次抵抗成功，你的神经通路都在重塑。';
    }
    if (logTrend == TrendDirection.worsening) {
      return '近期的情绪有些波动。情绪低落时渴望更容易趁虚而入，'
          '注意及时调节心情。';
    }
    return '目前整体状态保持稳定。稳定的阶段同样需要坚持，'
        '不要因为"感觉还好"就放松警惕。';
  }

  String _trendRecommendation(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return '把最近的进步记下来，下次遇到困难时回顾一下，'
            '它会给你信心和力量。';
      case TrendDirection.worsening:
        return '考虑回顾一下最近的触发因素，是否有什么新的变化？'
            '如果需要，可以使用SOS功能获取即时支持。';
      case TrendDirection.stable:
        return '稳定的阶段是巩固习惯的好时机。'
            '尝试学习一个新的应对技巧，丰富你的工具箱。';
    }
  }

  // =========================================================================
  // Private Methods — Daily Insight Generation
  // =========================================================================

  Future<DailyInsight> _generateLlmDailyInsight({
    required User user,
    required GameProfile gameProfile,
    required DailyLogEntry? todayLog,
    required List<DailyLogEntry> recentLogs,
    required List<CravingEntry> recentCravings,
    required int riskScore,
  }) async {
    final userContext = _buildUserContext(user, gameProfile);
    final todayData = _buildTodayData(todayLog, recentLogs, recentCravings);

    // Run local analysis for context
    final localAnalysisText = _buildLocalAnalysisText(
      recentCravings: recentCravings,
      recentLogs: recentLogs,
    );

    final rawJson = await _llmService!.generatePersonalizedInsight(
      userContext: userContext,
      todayData: todayData,
      localAnalysis: localAnalysisText,
    );

    final parsed = _parseJsonSafely(rawJson);

    return DailyInsight(
      headline: parsed['headline'] as String? ?? '今日洞察',
      body: parsed['body'] as String? ?? '继续保持你的努力。',
      actionText: parsed['actionText'] as String? ?? '查看详情',
      type: _parseInsightType(parsed['type'] as String?),
      relapseRiskScore: riskScore,
    );
  }

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
      final reason = _identifyHighRiskReason(todayLog, recentCravings, recentLogs);
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

  // =========================================================================
  // Private Methods — Weekly Report Generation
  // =========================================================================

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

    final resistedCount =
        weekCravings.where((c) => c.resolved).length;
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
        dayCount[c.timestamp.weekday] = (dayCount[c.timestamp.weekday] ?? 0) + 1;
      }
      final weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final maxDay = dayCount.entries.reduce((a, b) => a.value > b.value ? a : b);
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
          description: _patternAnalyzer.describeMoodCravingRelationship(correlation),
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
          description: '"${triggers.first.trigger}"本周出现了${triggers.first.count}次，'
              '占${(triggers.first.percentage * 100).toStringAsFixed(0)}%。',
          recommendation: _buildTriggerRecommendation(triggers.first),
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
        severity: relapseDays >= 3 ? 5 : relapseDays >= 2 ? 4 : 3,
      ));
    }

    return insights;
  }

  Future<Map<String, dynamic>> _generateLlmWeeklyReport({
    required User user,
    required GameProfile gameProfile,
    required List<DailyLogEntry> weekLogs,
    required List<CravingEntry> weekCravings,
    required Map<String, dynamic> stats,
  }) async {
    final userContext = _buildUserContext(user, gameProfile);
    final weekData = _buildWeekDataText(weekLogs, weekCravings, stats);

    final rawJson = await _llmService!.generateWeeklyReport(
      userContext: userContext,
      weekData: weekData,
    );

    return _parseJsonSafely(rawJson);
  }

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

  // =========================================================================
  // Private Methods — Action Suggestion
  // =========================================================================

  PersonalizedAction _criticalRiskAction(int riskScore, int hour) {
    if (hour >= 22 || hour < 5) {
      return const PersonalizedAction(
        title: '现在就做呼吸练习',
        description: '深夜是意志力最弱的时候。3分钟的呼吸练习可以帮助你度过此刻。',
        route: '/sos',
        icon: 'air',
        priority: 10,
      );
    }
    return PersonalizedAction(
      title: '风险等级 $riskScore/100',
      description: '你的当前状态显示较高的复发风险。'
          '请立即使用SOS功能或联系支持你的人。',
      route: '/sos',
      icon: 'warning',
      priority: 10,
    );
  }

  PersonalizedAction _highRiskAction(int riskScore, int hour, int days) {
    if (days <= 14) {
      return const PersonalizedAction(
        title: '回顾你的应对策略',
        description: '前两周是关键期，确保你的应对工具箱准备齐全。',
        route: '/skills',
        icon: 'build',
        priority: 6,
      );
    }

    if (hour >= 12 && hour <= 14) {
      return const PersonalizedAction(
        title: '午休时间，试试冲浪法',
        description: '午后是渴望的高发时段，现在是一个好时机练习冲浪技巧。',
        route: '/surf',
        icon: 'waves',
        priority: 6,
      );
    }

    return const PersonalizedAction(
      title: '做一次正念练习',
      description: '花5分钟做正念练习，重新连接你的目标和动机。',
      route: '/skills',
      icon: 'self_improvement',
      priority: 5,
    );
  }

  PersonalizedAction _defaultAction(int hour, int days) {
    // Morning
    if (hour >= 6 && hour < 10) {
      return const PersonalizedAction(
        title: '设定今天的意图',
        description: '早上是设定积极心态的最佳时机。想一想今天你为什么要坚持。',
        route: '/coach',
        icon: 'wb_sunny',
        priority: 2,
      );
    }

    // Evening
    if (hour >= 20) {
      return const PersonalizedAction(
        title: '回顾今天的表现',
        description: '花一分钟回顾今天——什么做得好？什么可以改进？',
        route: '/checkin',
        icon: 'nights_stay',
        priority: 2,
      );
    }

    // Afternoon
    if (days > 7) {
      return const PersonalizedAction(
        title: '查看你的进步趋势',
        description: '你已经坚持了一段时间，看看数据告诉你什么。',
        route: '/analysis',
        icon: 'trending_up',
        priority: 2,
      );
    }

    return const PersonalizedAction(
      title: '和AI教练聊聊',
      description: '有什么想说的吗？AI教练随时在这里支持你。',
      route: '/coach',
      icon: 'chat',
      priority: 1,
    );
  }

  // =========================================================================
  // Private Methods — Context Building for LLM
  // =========================================================================

  String _buildUserContext(User user, GameProfile gameProfile) {
    final targetName = user.targetType == TargetType.smoking
        ? '戒烟'
        : user.targetType == TargetType.alcohol
            ? '戒酒'
            : '戒烟戒酒';

    return '''
## 用户基本信息
- 戒断目标：$targetName
- 戒断天数：${user.daysSinceQuit}天
- 当前阶段：${user.stage.name}
- Fagerstrom评分：${user.fagerstromScore ?? '未设置'}
- AUDIT评分：${user.auditScore ?? '未设置'}
- 每日使用量：${user.dailyConsumption ?? '未设置'}
- 使用年数：${user.yearsOfUse ?? '未设置'}
- 每日花费：${user.dailyCost.toStringAsFixed(1)}元

## 游戏化数据
- 等级：${gameProfile.level}（${gameProfile.levelTitle}）
- 当前经验：${gameProfile.xpDisplay}
- 连续打卡：${gameProfile.streakDays}天
- 最长连续：${gameProfile.longestStreak}天
- 总打卡次数：${gameProfile.checkinTotal}
- 成功抵抗渴望：${gameProfile.cravingsResisted}次
- 完成练习：${gameProfile.exercisesCompleted}次
- SOS使用次数：${gameProfile.sosUsedCount}次
- 连续打卡是否活跃：${gameProfile.isStreakActive ? '是' : '否'}''';
  }

  String _buildTodayData(
    DailyLogEntry? todayLog,
    List<DailyLogEntry> recentLogs,
    List<CravingEntry> recentCravings,
  ) {
    final buffer = StringBuffer();

    if (todayLog != null) {
      buffer.writeln('## 今日打卡数据');
      buffer.writeln('- 心情：${todayLog.mood}/5');
      buffer.writeln('- 渴望程度：${todayLog.urgeLevel ?? '未记录'}/10');
      buffer.writeln('- 是否复发：${todayLog.relapsed ? '是' : '否'}');
      if (todayLog.triggers != null && todayLog.triggers!.isNotEmpty) {
        buffer.writeln('- 今日触发因素：${todayLog.triggers!.join("、")}');
      }
      if (todayLog.coping != null) {
        buffer.writeln('- 应对方式：${todayLog.coping}');
      }
      if (todayLog.notes != null) {
        buffer.writeln('- 备注：${todayLog.notes}');
      }
      buffer.writeln();
    } else {
      buffer.writeln('## 今日尚未打卡');
      buffer.writeln();
    }

    if (recentCravings.isNotEmpty) {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayCravings = recentCravings
          .where((c) => c.timestamp.isAfter(todayStart))
          .toList();

      buffer.writeln('## 今日渴望记录（${todayCravings.length}次）');
      for (final c in todayCravings) {
        buffer.writeln(
          '- ${c.timestamp.hour}:${c.timestamp.minute.toString().padLeft(2, '0')} '
          '强度${c.intensity}/10 '
          '触发：${c.trigger ?? '未记录'} '
          '${c.resolved ? '✅已抵抗' : '❌未抵抗'}',
        );
      }
      buffer.writeln();
    }

    if (recentLogs.length >= 2) {
      buffer.writeln('## 近期心情趋势');
      for (final log in recentLogs.take(5)) {
        final dateStr =
            '${log.date.month}/${log.date.day}';
        buffer.writeln(
          '- $dateStr: 心情${log.mood}/5, '
          '渴望${log.urgeLevel ?? '-'}/10 '
          '${log.relapsed ? '⚠️复发' : ''}',
        );
      }
    }

    return buffer.toString();
  }

  String _buildLocalAnalysisText({
    required List<CravingEntry> recentCravings,
    required List<DailyLogEntry> recentLogs,
  }) {
    final buffer = StringBuffer();

    if (recentCravings.length >= 3) {
      final timePattern = _patternAnalyzer.analyzeTimePatterns(recentCravings);
      buffer.writeln('## 时间模式分析');
      buffer.writeln(timePattern.summary);
      buffer.writeln();

      final triggers = _patternAnalyzer.rankTriggers(recentCravings);
      if (triggers.isNotEmpty) {
        buffer.writeln('## 触发因素排名');
        for (var i = 0; i < triggers.length && i < 5; i++) {
          buffer.writeln(
            '${i + 1}. ${triggers[i].trigger}: '
            '${triggers[i].count}次, '
            '平均强度${triggers[i].avgIntensity.toStringAsFixed(1)}, '
            '占比${(triggers[i].percentage * 100).toStringAsFixed(0)}%',
          );
        }
        buffer.writeln();
      }
    }

    if (recentLogs.length >= 3) {
      final correlation =
          _patternAnalyzer.calculateMoodCravingCorrelation(recentLogs);
      buffer.writeln('## 情绪-渴望相关性: ${correlation.toStringAsFixed(2)}');
      buffer.writeln(_patternAnalyzer.describeMoodCravingRelationship(correlation));
      buffer.writeln();

      final trend = _patternAnalyzer.detectTrend(recentLogs);
      final trendName = trend == TrendDirection.improving
          ? '改善'
          : trend == TrendDirection.worsening
              ? '恶化'
              : '稳定';
      buffer.writeln('## 整体趋势: $trendName');
    }

    return buffer.toString();
  }

  String _buildWeekDataText(
    List<DailyLogEntry> weekLogs,
    List<CravingEntry> weekCravings,
    Map<String, dynamic> stats,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('## 本周统计');
    buffer.writeln('- 总渴望次数：${stats['totalCravings']}');
    buffer.writeln('- 平均渴望强度：${stats['avgIntensity']}/10');
    buffer.writeln('- 平均心情：${stats['avgMood']}/5');
    buffer.writeln('- 成功抵抗次数：${stats['resistedCount']}');
    buffer.writeln('- 抵抗率：${stats['resistRate']}%');
    buffer.writeln('- 复发天数：${stats['relapseDays']}');
    buffer.writeln('- 打卡天数：${stats['loggedDays']}');
    if (stats['peakDay'] != null) {
      buffer.writeln('- 渴望最高日：${stats['peakDay']}');
    }
    if (stats['peakHour'] != null) {
      buffer.writeln('- 渴望高峰时段：${TimePattern.formatHour(stats['peakHour'] as int)}');
    }
    buffer.writeln();

    if (weekLogs.isNotEmpty) {
      buffer.writeln('## 每日详情');
      for (final log in weekLogs) {
        final dateStr =
            '${log.date.month}/${log.date.day}';
        buffer.writeln(
          '- $dateStr: 心情${log.mood}/5, '
          '渴望${log.urgeLevel ?? '-'}/10 '
          '${log.relapsed ? '⚠️复发' : '✅'} '
          '触发：${log.triggers?.join(",") ?? "-"}',
        );
      }
      buffer.writeln();
    }

    if (weekCravings.isNotEmpty) {
      buffer.writeln('## 渴望明细（最近20条）');
      for (final c in weekCravings.take(20)) {
        buffer.writeln(
          '- ${c.timestamp.month}/${c.timestamp.day} ${c.timestamp.hour}:${c.timestamp.minute.toString().padLeft(2, '0')} '
          '强度${c.intensity}/10 '
          '触发：${c.trigger ?? '-'} '
          '地点：${c.location ?? '-'} '
          '${c.resolved ? '✅' : '❌'}',
        );
      }
    }

    return buffer.toString();
  }

  // =========================================================================
  // Private Methods — LLM Enhancement
  // =========================================================================

  Future<List<AnalysisInsight>> _enhanceWithLlm({
    required List<CravingEntry> cravings,
    required List<DailyLogEntry> logs,
    required User user,
    required GameProfile gameProfile,
    required List<AnalysisInsight> localInsights,
  }) async {
    final userContext = _buildUserContext(user, gameProfile);
    final localAnalysisText = _buildLocalAnalysisText(
      recentCravings: cravings,
      recentLogs: logs,
    );

    // Also append local insight summaries
    final localSummary = StringBuffer(localAnalysisText);
    localSummary.writeln('\n## 本地分析已发现的洞察');
    for (final insight in localInsights) {
      localSummary.writeln(
        '- [${insight.type}] ${insight.title}: ${insight.description}',
      );
    }

    final rawJson = await _llmService!.analyzePatterns(
      userContext: userContext,
      localAnalysis: localSummary.toString(),
    );

    // Parse LLM response
    final parsed = _parseJsonArraySafely(rawJson);
    final insights = <AnalysisInsight>[];

    for (final item in parsed) {
      if (item is! Map<String, dynamic>) continue;
      insights.add(AnalysisInsight(
        type: item['type'] as String? ?? 'pattern',
        title: item['title'] as String? ?? '洞察',
        description: item['description'] as String? ?? '',
        recommendation: item['recommendation'] as String?,
        severity: (item['severity'] as int?)?.clamp(1, 5) ?? 3,
        data: item['data'] as Map<String, dynamic>?,
      ));
    }

    return insights;
  }

  // =========================================================================
  // Private Methods — Utilities
  // =========================================================================

  int _currentWeekNumber() {
    final now = DateTime.now();
    final dayOfYear = _dayOfYear(now);
    return ((dayOfYear - now.weekday + 10) ~/ 7);
  }

  int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  dynamic _parseJsonSafely(String raw) {
    try {
      // Try to extract JSON from markdown code blocks
      var content = raw.trim();
      if (content.startsWith('```')) {
        content = content
            .replaceFirst(RegExp(r'^```\w*\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '');
      }
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  List<dynamic> _parseJsonArraySafely(String raw) {
    try {
      var content = raw.trim();
      if (content.startsWith('```')) {
        content = content
            .replaceFirst(RegExp(r'^```\w*\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '');
      }
      final parsed = jsonDecode(content);
      if (parsed is List) return parsed;
      return <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  InsightType _parseInsightType(String? type) {
    switch (type) {
      case 'motivational':
        return InsightType.motivational;
      case 'warning':
        return InsightType.warning;
      case 'achievement':
        return InsightType.achievement;
      case 'critical':
        return InsightType.critical;
      default:
        return InsightType.neutral;
    }
  }

  String _randomMotivationalQuote() {
    final quotes = [
      '每一次坚持，都是对未来自己的投资。',
      '戒断不是失去什么，而是找回什么。',
      '你比你想象的更强大。',
      '困难是暂时的，进步是永久的。',
      '每一次说"不"，你都在重新定义自己。',
      '不是因为没有渴望才成功，而是因为成功了才没有渴望。',
      '最暗的夜之后，一定是最亮的晨。',
      '你今天的选择，决定了明天的自由。',
      '每一步都算数，即使有时看不到进步。',
      '你不是在放弃一个习惯，你是在赢得一种自由。',
    ];
    return quotes[Random().nextInt(quotes.length)];
  }
}