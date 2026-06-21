/// 对话上下文模型 — AI Coach 的有状态记忆系统
///
/// 存储最近 N 轮对话的主题、情绪趋势、已讨论策略，
/// 使 AI Coach 能够生成连贯的跟进问题和个性化回应。
library;

import '../../domain/entity/daily_log.dart';

/// 单条对话记录
class ConversationTurn {
  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final String? detectedTopic;
  final String? detectedEmotion;

  const ConversationTurn({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.detectedTopic,
    this.detectedEmotion,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'is_user': isUser ? 1 : 0,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'detected_topic': detectedTopic,
        'detected_emotion': detectedEmotion,
      };

  factory ConversationTurn.fromMap(Map<String, dynamic> map) =>
      ConversationTurn(
        id: map['id'] as String,
        isUser: (map['is_user'] as int) == 1,
        text: map['text'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        detectedTopic: map['detected_topic'] as String?,
        detectedEmotion: map['detected_emotion'] as String?,
      );
}

/// 对话上下文 — 聚合最近对话的主题/情绪/策略摘要
class ConversationContext {
  /// 最近 N 轮对话（最新在末尾）
  final List<ConversationTurn> recentTurns;

  /// 本次会话已讨论的主题
  final Set<String> discussedTopics;

  /// 检测到的用户当前情绪趋势（最近 5 轮）
  final MoodTrend moodTrend;

  /// 本次会话中用户提及的触发因素
  final Set<String> mentionedTriggers;

  /// 本次会话中教练已建议的策略
  final Set<String> suggestedStrategies;

  /// 上一次讨论的主题（用于生成跟进问题）
  String? get lastTopic {
    for (final turn in recentTurns.reversed) {
      if (!turn.isUser && turn.detectedTopic != null) {
        return turn.detectedTopic;
      }
    }
    return null;
  }

  /// 上一次的用户输入（用于上下文衔接）
  String? get lastUserInput {
    for (final turn in recentTurns.reversed) {
      if (turn.isUser) return turn.text;
    }
    return null;
  }

  /// 会话轮数
  int get turnCount => recentTurns.length;

  /// 对话轮数是否足够生成有上下文的回应
  bool get hasContext => recentTurns.length >= 2;

  const ConversationContext({
    this.recentTurns = const [],
    this.discussedTopics = const {},
    this.moodTrend = MoodTrend.neutral,
    this.mentionedTriggers = const {},
    this.suggestedStrategies = const {},
  });

  /// 从对话历史列表构建上下文（保留最近 [maxTurns] 轮）
  factory ConversationContext.fromHistory(
    List<ConversationTurn> history, {
    int maxTurns = 20,
  }) {
    final recent = history.length > maxTurns
        ? history.sublist(history.length - maxTurns)
        : history;

    final topics = <String>{};
    final triggers = <String>{};
    final strategies = <String>{};
    final emotions = <MoodIndicator>[];

    for (final turn in recent) {
      if (turn.detectedTopic != null) topics.add(turn.detectedTopic!);
      if (turn.detectedEmotion != null) {
        emotions.add(_emotionToIndicator(turn.detectedEmotion!));
      }
    }

    // 分析情绪趋势（最近 5 轮有效情绪数据）
    final recentEmotions =
        emotions.length >= 3 ? emotions.sublist(emotions.length - 5) : emotions;
    final trend = _analyzeMoodTrend(recentEmotions);

    return ConversationContext(
      recentTurns: recent,
      discussedTopics: topics,
      moodTrend: trend,
      mentionedTriggers: triggers,
      suggestedStrategies: strategies,
    );
  }

  /// 添加一轮对话并返回新的上下文
  ConversationContext addTurn(ConversationTurn turn) {
    final newTurns = [...recentTurns, turn];
    // 保留最近 20 轮
    final trimmed =
        newTurns.length > 20 ? newTurns.sublist(newTurns.length - 20) : newTurns;

    return ConversationContext.fromHistory(trimmed);
  }

  /// 检查某个主题是否在最近 N 轮内被讨论过
  bool recentlyDiscussed(String topic, {int withinTurns = 5}) {
    if (recentTurns.length < withinTurns) {
      return discussedTopics.contains(topic);
    }
    final recent = recentTurns.sublist(recentTurns.length - withinTurns);
    return recent.any((t) => t.detectedTopic == topic);
  }

  /// 获取对话摘要（用于展示或分析）
  String get summary {
    if (recentTurns.isEmpty) return '暂无对话记录';
    final topicStr =
        discussedTopics.isEmpty ? '尚未深入讨论' : discussedTopics.join('、');
    final moodStr = _moodTrendToLabel(moodTrend);
    return '已讨论：$topicStr | 情绪趋势：$moodStr | 共 $turnCount 轮对话';
  }

  static MoodTrend _analyzeMoodTrend(List<MoodIndicator> emotions) {
    if (emotions.length < 2) return MoodTrend.neutral;

    // 简单趋势：比较前半段和后半段的平均值
    final mid = emotions.length ~/ 2;
    final firstHalf = emotions.sublist(0, mid);
    final secondHalf = emotions.sublist(mid);

    final firstAvg = firstHalf.map((e) => e.value).reduce((a, b) => a + b) /
        firstHalf.length;
    final secondAvg = secondHalf.map((e) => e.value).reduce((a, b) => a + b) /
        secondHalf.length;

    final diff = secondAvg - firstAvg;
    if (diff > 0.3) return MoodTrend.improving;
    if (diff < -0.3) return MoodTrend.declining;
    return MoodTrend.neutral;
  }

  static MoodIndicator _emotionToIndicator(String emotion) {
    final lower = emotion.toLowerCase();
    if (const ['开心', '高兴', '不错', '很好', '成功', '坚持']
        .any((k) => lower.contains(k))) {
      return MoodIndicator.positive;
    }
    if (const ['焦虑', '压力', '烦躁', '生气', '难过', '难受', '痛苦']
        .any((k) => lower.contains(k))) {
      return MoodIndicator.negative;
    }
    return MoodIndicator.neutral;
  }

  static String _moodTrendToLabel(MoodTrend trend) {
    switch (trend) {
      case MoodTrend.improving:
        return '好转中';
      case MoodTrend.declining:
        return '需要关注';
      case MoodTrend.neutral:
        return '平稳';
    }
  }
}

/// 情绪趋势
enum MoodTrend { improving, neutral, declining }

/// 情绪指标（内部使用）
enum MoodIndicator {
  positive(1.0),
  neutral(0.0),
  negative(-1.0);

  const MoodIndicator(this.value);
  final double value;
}

/// 对话主题常量
class ConversationTopics {
  static const craving = '渴望';
  static const emotion = '情绪';
  static const weight = '体重';
  static const relapse = '复吸';
  static const social = '社交';
  static const sleep = '睡眠';
  static const help = '求助';
  static const success = '成功';
  static const progress = '进展';
  static const sos = '紧急救援';

  static const all = [
    craving,
    emotion,
    weight,
    relapse,
    social,
    sleep,
    help,
    success,
    progress,
    sos,
  ];
}
