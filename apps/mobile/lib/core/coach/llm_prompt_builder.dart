import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/analysis.dart';
import 'pattern_analyzer.dart';
import 'llm_service.dart';
import 'analysis_utils.dart';

/// Builds structured text prompts that are sent to the LLM service.
///
/// Every method takes plain data objects as parameters (no class state)
/// so it can be reused from both [DailyInsightGenerator] and
/// [WeeklyReportGenerator] without coupling.
class LlmPromptBuilder {
  final PatternAnalyzer _patternAnalyzer;

  LlmPromptBuilder(this._patternAnalyzer);

  /// Builds the user-context section of the prompt (user info + gamification).
  String buildUserContext(User user, GameProfile gameProfile) {
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

  /// Builds today's data section for the daily-insight prompt.
  String buildTodayData(
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
      final todayCravings =
          recentCravings.where((c) => c.timestamp.isAfter(todayStart)).toList();

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
        final dateStr = '${log.date.month}/${log.date.day}';
        buffer.writeln(
          '- $dateStr: 心情${log.mood}/5, '
          '渴望${log.urgeLevel ?? '-'}/10 '
          '${log.relapsed ? '⚠️复发' : ''}',
        );
      }
    }

    return buffer.toString();
  }

  /// Builds a summary of local pattern analysis for the LLM prompt.
  String buildLocalAnalysisText({
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
      buffer.writeln(
          _patternAnalyzer.describeMoodCravingRelationship(correlation));
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

  /// Builds the weekly data section of the prompt.
  String buildWeekDataText(
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
      buffer.writeln(
          '- 渴望高峰时段：${TimePattern.formatHour(stats['peakHour'] as int)}');
    }
    buffer.writeln();

    if (weekLogs.isNotEmpty) {
      buffer.writeln('## 每日详情');
      for (final log in weekLogs) {
        final dateStr = '${log.date.month}/${log.date.day}';
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

  /// Builds a compact user context for widget insight generation.
  /// Optimized for minimal token usage while maintaining personalization.
  String buildWidgetInsightContext({
    required int daysSinceQuit,
    required int streakDays,
    required int yesterdayMood,
    required int yesterdayCravingCount,
    required String riskLevel,
  }) {
    return '戒断天数：$daysSinceQuit天，连续打卡：$streakDays天，昨天心情：$yesterdayMood/5，昨天渴望次数：$yesterdayCravingCount次，今日风险等级：$riskLevel';
  }

  /// Compressed week data summary for cost-effective LLM calls.
  /// Replaces raw data with aggregated insights from PatternAnalyzer.
  String buildCompressedWeekSummary({
    required int totalCravings,
    required double avgIntensity,
    required double avgMood,
    required int resistedCount,
    required double resistRate,
    required int relapseDays,
    required int loggedDays,
    String? peakDay,
    int? peakHour,
    required String topTriggerSummary,
    required String timePatternSummary,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('## 本周摘要');
    buffer.writeln('- 渴望 $totalCravings 次（抵抗率 ${resistRate.toStringAsFixed(0)}%）');
    buffer.writeln('- 平均强度 ${avgIntensity.toStringAsFixed(1)}/10，平均心情 ${avgMood.toStringAsFixed(1)}/5');
    buffer.writeln('- 复发 $relapseDays 天 / 打卡 $loggedDays 天');
    if (peakDay != null) buffer.writeln('- 渴望最高日：$peakDay');
    if (peakHour != null) buffer.writeln('- 高峰时段：${peakHour}点');
    if (topTriggerSummary.isNotEmpty) buffer.writeln('- $topTriggerSummary');
    if (timePatternSummary.isNotEmpty) buffer.writeln('- $timePatternSummary');
    return buffer.toString();
  }

  /// Calls the LLM to enrich local craving-pattern insights and returns
  /// additional [AnalysisInsight] objects.
  ///
  /// Requires [localInsights] so the LLM can build on top of them.
  Future<List<AnalysisInsight>> enhanceWithLlm({
    required LlmService llmService,
    required String userContext,
    required String localAnalysisText,
    required List<AnalysisInsight> localInsights,
  }) async {
    // Append local insight summaries
    final localSummary = StringBuffer(localAnalysisText);
    localSummary.writeln('\n## 本地分析已发现的洞察');
    for (final insight in localInsights) {
      localSummary.writeln(
        '- [${insight.type}] ${insight.title}: ${insight.description}',
      );
    }

    final rawJson = await llmService.analyzePatterns(
      userContext: userContext,
      localAnalysis: localSummary.toString(),
    );

    // Parse LLM response
    final parsed = AnalysisUtils.parseJsonArraySafely(rawJson);
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
}