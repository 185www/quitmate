import '../../domain/entity/analysis.dart';

/// Builds human-readable recommendations from pattern-analysis results.
///
/// All methods are pure functions that accept the analysis data as parameters
/// and return formatted strings.
class RecommendationBuilder {
  const RecommendationBuilder();

  /// Builds a time-based recommendation from a [TimePattern].
  String buildTimeRecommendation(TimePattern timePattern) {
    if (timePattern.highRiskHours.isEmpty) return '';

    final peakTime = TimePattern.formatHour(timePattern.peakHour);
    if (timePattern.highRiskHours.length >= 3) {
      return '在${TimePattern.formatHour(timePattern.highRiskHours.first)}'
          '到${TimePattern.formatHour(timePattern.highRiskHours.last)}期间，'
          '设置提醒提前做准备，安排替代活动。';
    }
    return '每天$peakTime前后是你最脆弱的时段，提前准备好应对策略。';
  }

  /// Builds a trigger-based recommendation from a [TriggerRanking].
  String buildTriggerRecommendation(TriggerRanking trigger) {
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

  /// Returns a headline string for the trend insight.
  String trendTitle(TrendDirection logTrend, TrendDirection cravingTrend) {
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

  /// Returns a description string for the trend insight.
  String trendDescription(
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

  /// Returns an actionable recommendation based on the log trend direction.
  String trendRecommendation(TrendDirection trend) {
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
}
