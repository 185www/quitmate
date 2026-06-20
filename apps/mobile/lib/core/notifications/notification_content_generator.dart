import '../coach/llm_service.dart';
import '../coach/llm_prompt_builder.dart';

/// Generates personalized notification content using LLM.
/// Falls back to static templates when LLM is unavailable.
class NotificationContentGenerator {
  static const _morningTemplates = [
    '新的一天开始了。你已坚持 {days} 天，继续保持！',
    '早上好！今天是你戒断的第 {days} 天。',
    '{days} 天了，你的身体正在变得更好。',
  ];

  static const _urgeWarningTemplates = [
    '注意：上午 10-11 点可能是你的高风险时段。',
    '准备好应对策略了吗？根据你的数据，现在可能是渴望高峰。',
  ];

  /// Generate morning reminder content
  static Future<String> generateMorningReminder({
    required int daysSinceQuit,
    LlmService? llmService,
    String? userContext,
  }) async {
    if (llmService != null && llmService.isConfigured && userContext != null) {
      try {
        final response = await llmService.chat([
          {
            'role': 'system',
            'content': '你是一位戒烟/戒酒助手。根据用户数据生成一条简短的每日提醒通知（30字以内），要具体引用数据，不要空话，不要emoji。',
          },
          {'role': 'user', 'content': userContext},
        ], userContext: userContext);
        return response.trim().substring(0, 50);
      } catch (_) {}
    }
    return _morningTemplates[daysSinceQuit % _morningTemplates.length]
        .replaceAll('{days}', '$daysSinceQuit');
  }

  /// Generate urge warning content
  static Future<String> generateUrgeWarning({
    required String highRiskWindow,
    LlmService? llmService,
    String? userContext,
  }) async {
    if (llmService != null && llmService.isConfigured && userContext != null) {
      try {
        final response = await llmService.chat([
          {
            'role': 'system',
            'content': '根据用户数据生成一条渴望预警通知（30字以内），告知高风险时段，给出具体建议。',
          },
          {'role': 'user', 'content': '$userContext\n高风险时段：$highRiskWindow'},
        ], userContext: userContext);
        return response.trim().substring(0, 50);
      } catch (_) {}
    }
    return _urgeWarningTemplates[0].replaceAll('{high_risk}', highRiskWindow);
  }
}