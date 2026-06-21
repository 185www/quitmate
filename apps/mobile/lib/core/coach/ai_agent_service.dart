import 'package:flutter/foundation.dart';
import 'llm_service.dart';

/// Central singleton that owns the [LlmService] instance and manages its
/// lifecycle based on user preferences.
///
/// Other services that need LLM access (WidgetServiceV2,
/// NotificationContentGenerator, DailyInsightGenerator, etc.) should obtain
/// the shared [LlmService] via [AiAgentService.instance.llmService].
class AiAgentService {
  AiAgentService._();
  static final AiAgentService instance = AiAgentService._();

  LlmService? _llmService;
  bool _enabled = false;

  /// Whether the user has opted in to LLM-enhanced features.
  bool get enabled => _enabled;

  /// The shared [LlmService], or `null` if not configured / disabled.
  LlmService? get llmService => _enabled ? _llmService : null;

  /// Initialize from a preferences map (typically loaded from
  /// [UserUseCase.getPreferences]).
  ///
  /// Keys consumed:
  /// - `use_llm`  (bool)
  /// - `ai_api_key`  (String)
  /// - `ai_api_base` (String)
  /// - `ai_model`   (String)
  Future<void> initialize({required Map<String, dynamic> preferences}) async {
    _enabled = preferences['use_llm'] as bool? ?? false;
    final apiKey = preferences['ai_api_key'] as String? ?? '';
    final baseUrl = preferences['ai_api_base'] as String? ?? '';
    final model = preferences['ai_model'] as String? ?? '';

    _llmService = LlmService(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
    );
    debugPrint('AiAgentService: initialized (enabled=$_enabled, '
        'configured=${_llmService?.isConfigured ?? false})');
  }

  /// Re-configure (or disable) the LLM service after the user saves
  /// new settings.
  Future<void> updateLlmService({
    required String apiKey,
    required String baseUrl,
    required String model,
    required bool enabled,
  }) async {
    _enabled = enabled;
    _llmService = LlmService(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
    );
    debugPrint('AiAgentService: updated (enabled=$_enabled, '
        'configured=${_llmService?.isConfigured ?? false})');
  }
}