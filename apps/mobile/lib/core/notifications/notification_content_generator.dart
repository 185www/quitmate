import '../coach/llm_service.dart';
import '../coach/llm_prompt_builder.dart';

/// Generates personalized notification content using LLM.
/// Falls back to static templates when LLM is unavailable.
class NotificationContentGenerator {
  static const _morningTemplates = [
    '新的一天开始了。你已坚持 {days} 天，继续保持！',
    '早上好！今天是你戒断的第 {days} 天。',
    '{days} 天了，你的身体正在变得更好。',
    '第 {days} 天。如果今天有渴望，记住：3-5 分钟就会过去。',
    '{days} 天没有放弃。你的前额叶皮层正在恢复自控力。',
    '早上好。{days} 天前你做了一个改变人生的决定。',
    '今天是你戒断的第 {days} 天。每抵抗一次渴望，你的意志力都在增强。',
    '坚持了 {days} 天。想想你当初为什么决定戒掉，那个理由还在。',
  ];

  static const _urgeWarningTemplates = [
    '注意：上午 10-11 点可能是你的高风险时段。',
    '准备好应对策略了吗？根据你的数据，现在可能是渴望高峰。',
    '高风险时段快到了。提前准备：喝水、深呼吸、离开触发环境。',
    '渴望高峰时段将近。你之前成功抵抗了 {streak} 次，这次也可以。',
  ];

  static const _milestoneTemplates = [
    '恭喜你达成了一个新里程碑！{milestone_title}',
    '了不起！{milestone_title}，你已经超越了大多数人。',
    '{milestone_title}！身体正在恢复，继续坚持。',
  ];

  static const _proactiveCareTemplates = [
    '已经连续 {streak} 天了。注意休息，疲劳会降低自控力。',
    '今天心情怎么样？如果觉得难熬，试试 4-7-8 呼吸法。',
    '连续 {streak} 天。试试今天做一件让自己开心的小事。',
    '最近一周表现不错。给自己一个小奖励吧，你值得。',
    '如果今天遇到渴望，不要慌。想想你成功抵抗时的感觉。',
  ];

  /// Generate morning reminder content.
  /// Uses LLM when available for personalized messages, falls back to templates.
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
            'content': '你是一位戒烟/戒酒助手。根据用户数据生成一条简短的每日提醒通知（30字以内），'
                '要具体引用数据，不要空话，不要emoji。语气像关心你的朋友，不是教练。',
          },
          {'role': 'user', 'content': userContext},
        ], userContext: userContext);
        return response.trim().substring(0, 50);
      } catch (_) {}
    }
    return _morningTemplates[daysSinceQuit % _morningTemplates.length]
        .replaceAll('{days}', '$daysSinceQuit');
  }

  /// Generate urge warning content.
  /// Uses LLM when available for personalized warnings, falls back to templates.
  static Future<String> generateUrgeWarning({
    required String highRiskWindow,
    int streakDays = 0,
    LlmService? llmService,
    String? userContext,
  }) async {
    if (llmService != null && llmService.isConfigured && userContext != null) {
      try {
        final response = await llmService.chat([
          {
            'role': 'system',
            'content': '根据用户数据生成一条渴望预警通知（30字以内），告知高风险时段，给出具体建议。'
                '语气紧张但不焦虑，像朋友提醒。',
          },
          {'role': 'user', 'content': '$userContext\n高风险时段：$highRiskWindow'},
        ], userContext: userContext);
        return response.trim().substring(0, 50);
      } catch (_) {}
    }
    return _urgeWarningTemplates[streakDays % _urgeWarningTemplates.length]
        .replaceAll('{high_risk}', highRiskWindow)
        .replaceAll('{streak}', '$streakDays');
  }

  /// Generate milestone celebration notification.
  static Future<String> generateMilestoneNotification({
    required String milestoneTitle,
    int daysSinceQuit = 0,
  }) async {
    return _milestoneTemplates[daysSinceQuit % _milestoneTemplates.length]
        .replaceAll('{milestone_title}', milestoneTitle);
  }

  /// Generate proactive care notification.
  /// Triggered when user has been idle for a while or needs encouragement.
  static Future<String> generateProactiveCare({
    required int streakDays,
    int daysSinceQuit = 0,
    LlmService? llmService,
    String? userContext,
  }) async {
    if (llmService != null && llmService.isConfigured && userContext != null) {
      try {
        final response = await llmService.chat([
          {
            'role': 'system',
            'content': '你是一位关心用户的戒断助手。用户已经坚持了一段时间，'
                '生成一条主动关怀通知（30字以内）。引用具体数据，不要空话，不要emoji。'
                '语气温暖但不油腻，像真正关心你的朋友。',
          },
          {'role': 'user', 'content': userContext},
        ], userContext: userContext);
        return response.trim().substring(0, 50);
      } catch (_) {}
    }
    return _proactiveCareTemplates[streakDays % _proactiveCareTemplates.length]
        .replaceAll('{streak}', '$streakDays');
  }

  /// Generate education-based insight notification.
  /// Uses a health fact related to the user's quit stage.
  static String generateEducationInsight({
    required int daysSinceQuit,
  }) {
    if (daysSinceQuit < 1) {
      return '戒烟 20 分钟后，你的心率就开始恢复正常。';
    } else if (daysSinceQuit < 2) {
      return '戒烟 24 小时后，心脏病发作风险开始降低。';
    } else if (daysSinceQuit < 14) {
      return '戒断 2 周内，你的循环会改善，肺功能开始提升。';
    } else if (daysSinceQuit < 30) {
      return '戒断 1 个月后，你的肺功能改善 30%，咳嗽减少。';
    } else if (daysSinceQuit < 90) {
      return '戒断 3 个月后，你的多巴胺受体开始恢复正常。';
    } else if (daysSinceQuit < 365) {
      return '戒断 1 年后，冠心病风险降低一半。';
    } else {
      return '戒断 5 年后，中风风险降至非吸烟者水平。你的坚持意义非凡。';
    }
  }
}