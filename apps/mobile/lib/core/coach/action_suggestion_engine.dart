import '../../domain/entity/analysis.dart';

/// Generates the single best [PersonalizedAction] for the user's current state.
///
/// All methods are pure functions. The caller is responsible for determining
/// the risk score and passing in the relevant context.
class ActionSuggestionEngine {
  const ActionSuggestionEngine();

  /// Returns the most relevant action based on current risk, time, and
  /// user state. The caller should apply its own priority ordering around
  /// this — see [AiAnalyst.suggestAction] for the full priority chain.
  PersonalizedAction criticalRiskAction(int riskScore, int hour) {
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

  PersonalizedAction highRiskAction(int riskScore, int hour, int days) {
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

  PersonalizedAction defaultAction(int hour, int days) {
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
}
