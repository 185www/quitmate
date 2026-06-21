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
    if (user == null) return null;

    final gameProfile = await gameUseCase.getGameProfile(user.id);
    if (gameProfile == null) return null;

    final todayLog = await logUseCase.getTodayLog();
    final recentLogs = await logUseCase.getRecentLogs(limit: 7);

    // Get craving entries via raw logs → CravingEntry conversion
    final rawCravings = await cravingUseCase.getAllRawLogs();
    final recentCravings = AiAgentService.parseCravingEntries(rawCravings);

    // Generate insight (cached per day inside the agent)
    return agent.generateDailyInsight(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
      recentLogs: recentLogs,
      recentCravings: recentCravings,
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
      if (user == null) return null;

      final gameProfile = await gameUseCase.getGameProfile(user.id);
      if (gameProfile == null) return null;

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
    });
  }
}
