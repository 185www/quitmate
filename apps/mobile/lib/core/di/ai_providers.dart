/// AI-specific Riverpod providers.
///
/// Provides:
/// - [aiAgentProvider] — shared singleton [AiAgentService], auto-initialized
///   from user preferences.
/// - [dailyInsightProvider] — [AsyncNotifierProvider] that drives the AI
///   insight card on the home screen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_agent_service.dart';
import '../di/providers.dart';
import '../../domain/entity/analysis.dart';
import '../../domain/entity/user.dart';
import '../../domain/entity/game_profile.dart';


// ─────────────────────────────────────────────────────────────────────────────
// aiAgentProvider — singleton, lazily initialized
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the shared [AiAgentService] singleton.
///
/// On first read, initializes the agent with the user's current preferences
/// and the shared [LlmPolicy] instance.
final aiAgentProvider = Provider<AiAgentService>((ref) {
  final agent = AiAgentService.instance;
  // Initialize synchronously if not yet done; the notifier will await it.
  return agent;
});

// ─────────────────────────────────────────────────────────────────────────────
// dailyInsightProvider — async notifier for the home-screen AI card
// ─────────────────────────────────────────────────────────────────────────────

/// Exposes a [DailyInsight] to the UI.
///
/// - `null` means loading (or no user data yet).
/// - [InsightType] drives the card gradient color.
/// - Call `invalidate(dailyInsightProvider)` or [DailyInsightNotifier.refresh]
///   to force re-generation.
final dailyInsightProvider =
    AsyncNotifierProvider<DailyInsightNotifier, DailyInsight?>(
  DailyInsightNotifier.new,
);

class DailyInsightNotifier extends AsyncNotifier<DailyInsight?> {
  @override
  Future<DailyInsight?> build() async {
    // Watch user prefs so we re-trigger when they change
    final userUseCase = ref.watch(userUseCaseProvider);
    final logUseCase = ref.watch(logUseCaseProvider);
    final gameUseCase = ref.watch(gameUseCaseProvider);
    final cravingUseCase = ref.watch(cravingUseCaseProvider);
    final llmPolicy = ref.watch(llmPolicyProvider);

    final agent = ref.read(aiAgentProvider);

    // Initialize agent if not yet done
    if (!agent.isInitialized) {
      try {
        final prefs = await userUseCase.getPreferences();
        await agent.initialize(
          preferences: prefs,
          llmPolicy: llmPolicy,
        );
      } catch (e) {
        // Initialize without LLM as fallback
        await agent.initialize(
          preferences: const {},
          llmPolicy: llmPolicy,
        );
      }
    }

    // Gather data
    final user = await userUseCase.getCurrentUser();
    if (user == null) {
      // No user yet — return a welcoming insight instead of null
      return DailyInsight(
        headline: '开始记录你的旅程',
        body: '完成引导设置后，AI 洞察将根据你的数据提供个性化分析。'
            '每天打卡并记录渴望，分析会越来越精准。',
        actionText: '完成设置',
        actionRoute: '/onboarding',
        type: InsightType.neutral,
        relapseRiskScore: 50,
      );
    }

    // Use getOrCreateProfile — it auto-creates if missing (never returns null)
    final gameProfile = await gameUseCase.getOrCreateProfile(user.id);

    return _generateWithProfile(
      user: user,
      gameProfile: gameProfile,
      logUseCase: logUseCase,
      cravingUseCase: cravingUseCase,
      agent: agent,
    );
  }

  /// Forces a fresh insight generation (clears cache).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final agent = ref.read(aiAgentProvider);
      agent.clearCache();

      final userUseCase = ref.read(userUseCaseProvider);
      final logUseCase = ref.read(logUseCaseProvider);
      final gameUseCase = ref.read(gameUseCaseProvider);
      final cravingUseCase = ref.read(cravingUseCaseProvider);

      final user = await userUseCase.getCurrentUser();
      if (user == null) {
        return DailyInsight(
          headline: '开始记录你的旅程',
          body: '完成引导设置后，AI 洞察将根据你的数据提供个性化分析。',
          actionText: '完成设置',
          actionRoute: '/onboarding',
          type: InsightType.neutral,
          relapseRiskScore: 50,
        );
      }

      final gameProfile = await gameUseCase.getOrCreateProfile(user.id);

      return _generateWithProfile(
        user: user,
        gameProfile: gameProfile,
        logUseCase: logUseCase,
        cravingUseCase: cravingUseCase,
        agent: agent,
      );
    });
  }

  /// Shared helper: gather logs/cravings and generate insight via agent.
  Future<DailyInsight> _generateWithProfile({
    required User user,
    required GameProfile gameProfile,
    required dynamic logUseCase,
    required dynamic cravingUseCase,
    required AiAgentService agent,
  }) async {
    final todayLog = await logUseCase.getTodayLog();
    final recentLogs = await logUseCase.getRecentLogs(limit: 7);

    final rawCravings = await cravingUseCase.getAllRawLogs();
    final recentCravings = AiAgentService.parseCravingEntries(rawCravings);

    return agent.generateDailyInsight(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
      recentLogs: recentLogs,
      recentCravings: recentCravings,
    );
  }
}
