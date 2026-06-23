/// AI Agent Service — the brain of proactive AI analysis.
///
/// Singleton service that orchestrates all AI tasks:
/// - Daily insight generation (LLM-enhanced or local fallback)
/// - Risk assessment (local engine + optional LLM enrichment)
/// - Motivational content generation (widgets & notifications)
/// - Proactive care checks (intervention triggers)
///
/// Every LLM call goes through [LlmPolicy.sanitizeInput] / [sanitizeOutput].
/// Results are cached in memory with date-based invalidation.
library;

import 'package:QuitMate/domain/entity/user.dart';
import 'package:QuitMate/domain/entity/game_profile.dart';
import 'package:QuitMate/domain/entity/daily_log.dart';
import 'package:QuitMate/domain/entity/analysis.dart';
import 'package:QuitMate/core/coach/llm_service.dart';
import 'package:QuitMate/core/coach/daily_insight_generator.dart';
import 'package:QuitMate/core/coach/pattern_analyzer.dart';
import 'package:QuitMate/core/coach/llm_prompt_builder.dart';
import 'package:QuitMate/core/coach/analysis_utils.dart';
import 'package:QuitMate/core/llm/llm_policy.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AiAgentService
// ─────────────────────────────────────────────────────────────────────────────

class AiAgentService {
  static final AiAgentService _instance = AiAgentService._();
  static AiAgentService get instance => _instance;
  AiAgentService._();

  // Dependencies (injected via [initialize])
  LlmService? _llmService;
  LlmPolicy? _llmPolicy;
  PatternAnalyzer _patternAnalyzer = PatternAnalyzer();
  LlmPromptBuilder? _promptBuilder;
  DailyInsightGenerator? _dailyInsightGenerator;

  bool _initialized = false;

  // ── Daily cache ──────────────────────────────────────────────────────────

  DailyInsight? _cachedInsight;
  DateTime? _cachedInsightDate;

  int? _cachedRiskScore;
  DateTime? _cachedRiskDate;

  String? _cachedMotivation;
  DateTime? _cachedMotivationDate;

  ProactiveCareResult? _cachedCareResult;
  DateTime? _cachedCareDate;

  // ── Initialization ──────────────────────────────────────────────────────

  /// Initializes the agent with the user's LLM preferences.
  ///
  /// Call this on app startup after loading user preferences.
  /// [preferences] should contain keys: `use_llm`, `ai_api_key`,
  /// `ai_api_base`, `ai_model`.
  /// [llmPolicy] is the shared policy instance from DI.
  Future<void> initialize({
    required Map<String, dynamic> preferences,
    LlmPolicy? llmPolicy,
  }) async {
    _llmPolicy = llmPolicy;

    final enabled = preferences['use_llm'] as bool? ?? false;
    if (enabled) {
      final apiKey = (preferences['ai_api_key'] as String? ?? '').trim();
      final baseUrl =
          (preferences['ai_api_base'] as String? ?? 'https://api.openai.com/v1')
              .trim();
      final model =
          (preferences['ai_model'] as String? ?? 'gpt-4o-mini').trim();

      if (apiKey.isNotEmpty) {
        _llmService =
            LlmService(apiKey: apiKey, baseUrl: baseUrl, model: model);
      }
    }

    // Build internal pipeline
    _promptBuilder = LlmPromptBuilder(_patternAnalyzer);
    _dailyInsightGenerator = DailyInsightGenerator(
      patternAnalyzer: _patternAnalyzer,
      llmService: _llmService,
      promptBuilder: _promptBuilder!,
    );

    _initialized = true;
  }

  /// Whether the agent is ready for LLM-enhanced operations.
  bool get isReady =>
      _initialized && _llmService != null && _llmService!.isConfigured;

  /// Whether the agent has been initialized (even without LLM).
  bool get isInitialized => _initialized;

  /// Access to the underlying LlmService (for ChatScreen etc.).
  LlmService? get llmService => _llmService;

  /// Access to the shared PatternAnalyzer.
  PatternAnalyzer get patternAnalyzer => _patternAnalyzer;

  // ──────────────────────────────────────────────────────────────────────────
  // Daily Insight
  // ──────────────────────────────────────────────────────────────────────────

  /// Generates a [DailyInsight] for the current day.
  ///
  /// Results are cached per-calendar-day; calling this multiple times on the
  /// same day returns the cached result.
  ///
  /// Falls back to local heuristic generation when LLM is unavailable.
  Future<DailyInsight> generateDailyInsight({
    required User user,
    required GameProfile gameProfile,
    DailyLogEntry? todayLog,
    List<DailyLogEntry> recentLogs = const [],
    List<CravingEntry> recentCravings = const [],
  }) async {
    // Check cache (same calendar day)
    final now = DateTime.now();
    if (_cachedInsight != null &&
        _cachedInsightDate != null &&
        _isSameDay(now, _cachedInsightDate!)) {
      return _cachedInsight!;
    }

    // Calculate local risk score first
    final riskScore = _patternAnalyzer.calculateLocalRiskScore(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
      recentLogs: recentLogs,
      recentCravings: recentCravings,
    );

    // Generate insight via DailyInsightGenerator (LLM or local fallback)
    DailyInsight insight;
    try {
      // Validate LLM policy before making any LLM network request
      if (isReady && _llmPolicy != null) {
        await _llmPolicy!.validateRequestAsync();
      }

      insight = await _dailyInsightGenerator!.generateDailyInsight(
        user: user,
        gameProfile: gameProfile,
        todayLog: todayLog,
        recentLogs: recentLogs,
        recentCravings: recentCravings,
        riskScore: riskScore,
      );

      // Sanitize output if it came from LLM
      if (isReady && _llmPolicy != null) {
        insight = DailyInsight(
          headline: _llmPolicy!.sanitizeOutput(insight.headline),
          body: _llmPolicy!.sanitizeOutput(insight.body),
          actionText: insight.actionText,
          actionRoute: insight.actionRoute,
          type: insight.type,
          relapseRiskScore: insight.relapseRiskScore,
          generatedAt: insight.generatedAt,
        );
      }
    } catch (e) {
      // If generator itself fails, create a safe fallback
      insight = DailyInsight(
        headline: '继续你的每日节奏',
        body:
            '每天坚持打卡和记录是成功的关键。连续${gameProfile.streakDays}天了，保持这个习惯。',
        actionText: '完成今日打卡',
        actionRoute: '/checkin',
        type: InsightType.neutral,
        relapseRiskScore: riskScore,
      );
    }

    _cachedInsight = insight;
    _cachedInsightDate = DateTime.now();
    return insight;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Risk Assessment
  // ──────────────────────────────────────────────────────────────────────────

  /// Calculates the current relapse risk score (0-100).
  ///
  /// Uses the local [PatternAnalyzer] heuristic. Cached per-day.
  Future<int> assessRisk({
    required User user,
    required GameProfile gameProfile,
    DailyLogEntry? todayLog,
    List<DailyLogEntry> recentLogs = const [],
    List<CravingEntry> recentCravings = const [],
  }) async {
    final now = DateTime.now();
    if (_cachedRiskScore != null &&
        _cachedRiskDate != null &&
        _isSameDay(now, _cachedRiskDate!)) {
      return _cachedRiskScore!;
    }

    final riskScore = _patternAnalyzer.calculateLocalRiskScore(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
      recentLogs: recentLogs,
      recentCravings: recentCravings,
    );

    _cachedRiskScore = riskScore;
    _cachedRiskDate = DateTime.now();
    return riskScore;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Motivational Content
  // ──────────────────────────────────────────────────────────────────────────

  /// Generates motivational content for widgets and notifications.
  ///
  /// If LLM is ready, produces a personalized message; otherwise returns
  /// a random built-in quote. Cached per-day.
  Future<String> generateMotivationalContent({
    required User user,
    required GameProfile gameProfile,
  }) async {
    final now = DateTime.now();
    if (_cachedMotivation != null &&
        _cachedMotivationDate != null &&
        _isSameDay(now, _cachedMotivationDate!)) {
      return _cachedMotivation!;
    }

    if (isReady && _promptBuilder != null && _llmPolicy != null) {
      try {
        // Validate LLM policy before making network request
        await _llmPolicy!.validateRequestAsync();

        final context = _promptBuilder!.buildUserContext(user, gameProfile);
        final sanitized = _llmPolicy!.sanitizeInput(context);

        final response = await _llmService!.chat(
          [
            {
              'role': 'user',
              'content': '基于我的数据，给我一句简短的鼓励（20字以内）。'
            },
          ],
          userContext: sanitized,
        );

        final sanitizedOut = _llmPolicy!.sanitizeOutput(response);
        _cachedMotivation = sanitizedOut;
        _cachedMotivationDate = DateTime.now();
        return sanitizedOut;
      } on LlmPolicyViolation {
        // LLM not authorized — fall through to local fallback
        debugPrint('AiAgentService: LLM policy not met, using local fallback');
      } catch (_) {
        // Fall through to local fallback
      }
    }

    final quote = AnalysisUtils.randomMotivationalQuote();
    _cachedMotivation = quote;
    _cachedMotivationDate = DateTime.now();
    return quote;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Proactive Care Check
  // ──────────────────────────────────────────────────────────────────────────

  /// Checks if the user needs proactive intervention.
  ///
  /// Returns a [ProactiveCareResult] with reasons and recommended actions.
  /// Triggers: high risk score, broken streak, low mood trend,
  /// craving spike, recent relapse.
  Future<ProactiveCareResult> proactiveCareCheck({
    required User user,
    required GameProfile gameProfile,
    DailyLogEntry? todayLog,
    List<DailyLogEntry> recentLogs = const [],
    List<CravingEntry> recentCravings = const [],
  }) async {
    // Cache valid for 4 hours
    final now = DateTime.now();
    if (_cachedCareResult != null &&
        _cachedCareDate != null &&
        now.difference(_cachedCareDate!).inHours < 4) {
      return _cachedCareResult!;
    }

    final reasons = <String>[];
    int severity = 0;
    String? recommendedAction;
    String? recommendedRoute;

    // 1. High risk score
    final riskScore = await assessRisk(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
      recentLogs: recentLogs,
      recentCravings: recentCravings,
    );
    if (riskScore >= 70) {
      severity = 3;
      reasons.add('风险评估为高风险 ($riskScore/100)');
      recommendedAction = '使用SOS呼吸练习';
      recommendedRoute = '/sos';
    } else if (riskScore >= 50) {
      severity = severity < 2 ? 2 : severity;
      reasons.add('风险评估处于警戒线 ($riskScore/100)');
    }

    // 2. Streak about to break
    if (gameProfile.streakDays > 0 && !gameProfile.isStreakActive) {
      severity = severity < 2 ? 2 : severity;
      reasons.add('连续打卡可能已中断');
      if (recommendedAction == null) {
        recommendedAction = '立即打卡保持连续记录';
        recommendedRoute = '/checkin';
      }
    }

    // 3. Low mood trend
    if (recentLogs.length >= 3) {
      final recentMood = recentLogs
              .sublist(recentLogs.length - 3)
              .map((l) => l.mood)
              .reduce((a, b) => a + b) /
          3;
      if (recentMood < 2.0) {
        severity = severity < 2 ? 2 : severity;
        reasons.add('近期心情持续偏低');
        if (recommendedAction == null) {
          recommendedAction = '试试情绪调节练习';
          recommendedRoute = '/skills';
        }
      }
    }

    // 4. Sudden craving spike
    if (recentCravings.length >= 5) {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayCravings =
          recentCravings.where((c) => c.timestamp.isAfter(todayStart)).length;
      if (todayCravings >= 5) {
        severity = severity < 2 ? 2 : severity;
        reasons.add('今日渴望频率异常偏高 ($todayCravings 次)');
        if (recommendedAction == null) {
          recommendedAction = '做一次冲浪练习';
          recommendedRoute = '/surf';
        }
      }
    }

    // 5. Recent relapse
    final recentRelapses = recentLogs.where((l) => l.relapsed).length;
    if (recentRelapses >= 1) {
      severity = severity < 2 ? 2 : severity;
      reasons.add('近期有复发记录');
      if (recommendedAction == null) {
        recommendedAction = '制定预防复发计划';
        recommendedRoute = '/relapse-plan';
      }
    }

    final result = ProactiveCareResult(
      needsIntervention: severity >= 2,
      severity: severity,
      reasons: reasons,
      recommendedAction: recommendedAction,
      recommendedRoute: recommendedRoute,
    );

    _cachedCareResult = result;
    _cachedCareDate = DateTime.now();
    return result;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Cache Management
  // ──────────────────────────────────────────────────────────────────────────

  /// Clears all cached results, forcing fresh generation on next call.
  void clearCache() {
    _cachedInsight = null;
    _cachedInsightDate = null;
    _cachedRiskScore = null;
    _cachedRiskDate = null;
    _cachedMotivation = null;
    _cachedMotivationDate = null;
    _cachedCareResult = null;
    _cachedCareDate = null;
  }

  /// Updates the LLM service (e.g., after settings change).
  void updateLlmService({
    required Map<String, dynamic> preferences,
  }) {
    final enabled = preferences['use_llm'] as bool? ?? false;
    if (enabled) {
      final apiKey = (preferences['ai_api_key'] as String? ?? '').trim();
      final baseUrl =
          (preferences['ai_api_base'] as String? ?? 'https://api.openai.com/v1')
              .trim();
      final model =
          (preferences['ai_model'] as String? ?? 'gpt-4o-mini').trim();

      if (apiKey.isNotEmpty) {
        _llmService =
            LlmService(apiKey: apiKey, baseUrl: baseUrl, model: model);
      } else {
        _llmService = null;
      }
    } else {
      _llmService = null;
    }

    // Rebuild pipeline
    _promptBuilder = LlmPromptBuilder(_patternAnalyzer);
    _dailyInsightGenerator = DailyInsightGenerator(
      patternAnalyzer: _patternAnalyzer,
      llmService: _llmService,
      promptBuilder: _promptBuilder!,
    );

    clearCache();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Converts raw craving maps from repository to [CravingEntry] objects.
  static List<CravingEntry> parseCravingEntries(
      List<Map<String, dynamic>> raw) {
    return raw.map((m) {
      return CravingEntry(
        id: m['id'] as int?,
        userId: m['user_id'] as int? ?? 0,
        timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ??
            DateTime.now(),
        intensity: (m['intensity'] as int?) ?? 5,
        trigger: m['trigger'] as String?,
        context: m['context'] as String?,
        copingUsed: m['coping_used'] as String?,
        resolved: (m['resolved'] as int?) == 1,
        location: m['location'] as String?,
        socialContext: m['social_context'] as String?,
        activity: m['activity'] as String?,
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProactiveCareResult
// ─────────────────────────────────────────────────────────────────────────────

/// Result of a proactive care check.
class ProactiveCareResult {
  /// Whether the user needs proactive intervention.
  final bool needsIntervention;

  /// Severity level: 0 = none, 1 = low, 2 = medium, 3 = high.
  final int severity;

  /// Human-readable reasons for the recommendation.
  final List<String> reasons;

  /// What the user should do (actionable).
  final String? recommendedAction;

  /// Route to navigate to for the recommended action.
  final String? recommendedRoute;

  const ProactiveCareResult({
    required this.needsIntervention,
    required this.severity,
    required this.reasons,
    this.recommendedAction,
    this.recommendedRoute,
  });

  /// Severity label in Chinese.
  String get severityLabel {
    switch (severity) {
      case 3:
        return '高';
      case 2:
        return '中';
      case 1:
        return '低';
      default:
        return '无';
    }
  }
}
