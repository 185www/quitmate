/// 复发宽容机制 — "跌倒了没关系，重要的是站起来"
///
/// 核心设计原则：禁止"全或无"的复发处理。
/// 用户破戒一次不应清零所有数据，避免"惩罚式设计"导致用户自暴自弃。
///
/// 宽容规则（7天窗口期）：
/// - 第1次复发：保留连续天数，仅标记"颠簸"
/// - 第2次复发：连续天数减半（但 longestStreak 不受影响）
/// - 第3次+复发：重置连续天数（但其他所有数据保留）
library;

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

/// 单次复发事件记录
class RelapseEvent {
  final DateTime timestamp;
  final String trigger;
  final String? situation;
  final String copingAttempted;
  final bool bouncedBack;

  const RelapseEvent({
    required this.timestamp,
    required this.trigger,
    this.situation,
    required this.copingAttempted,
    this.bouncedBack = false,
  });

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'trigger': trigger,
        'situation': situation,
        'coping_attempted': copingAttempted,
        'bounced_back': bouncedBack ? 1 : 0,
      };

  factory RelapseEvent.fromMap(Map<String, dynamic> map) => RelapseEvent(
        timestamp: DateTime.parse(map['timestamp'] as String),
        trigger: map['trigger'] as String,
        situation: map['situation'] as String?,
        copingAttempted: map['coping_attempted'] as String? ?? '',
        bouncedBack: (map['bounced_back'] as int? ?? 0) == 1,
      );

  RelapseEvent copyWith({
    DateTime? timestamp,
    String? trigger,
    String? situation,
    String? copingAttempted,
    bool? bouncedBack,
  }) =>
      RelapseEvent(
        timestamp: timestamp ?? this.timestamp,
        trigger: trigger ?? this.trigger,
        situation: situation ?? this.situation,
        copingAttempted: copingAttempted ?? this.copingAttempted,
        bouncedBack: bouncedBack ?? this.bouncedBack,
      );
}

/// 复发情况综合摘要
class RelapseSummary {
  final int totalRelapses;
  final int relapsesThisWeek;
  final int relapsesThisMonth;
  final double bounceBackRate;
  final int daysSinceLastRelapse;
  final int currentForgivenessCount;
  final String encouragement;

  const RelapseSummary({
    required this.totalRelapses,
    required this.relapsesThisWeek,
    required this.relapsesThisMonth,
    required this.bounceBackRate,
    required this.daysSinceLastRelapse,
    required this.currentForgivenessCount,
    required this.encouragement,
  });
}

/// 宽容处理后的连续天数结果
class ForgivenessResult {
  /// 修改后的连续天数
  final int adjustedStreakDays;

  /// 是否使用了宽容（即没有完全重置）
  final bool forgivenessApplied;

  /// 本周内已使用的宽容次数
  final int forgivenessCountThisWeek;

  /// 本次处理的行为类型
  final ForgivenessAction action;

  /// 供用户看的中文提示信息
  final String message;

  const ForgivenessResult({
    required this.adjustedStreakDays,
    required this.forgivenessApplied,
    required this.forgivenessCountThisWeek,
    required this.action,
    required this.message,
  });
}

/// 宽容动作类型
enum ForgivenessAction {
  /// 第1次：颠簸标记，连续天数保留
  bump,
  /// 第2次：连续天数减半
  halve,
  /// 第3次+：重置连续天数
  reset,
}

/// 恢复轨迹评估
class RecoveryTrajectory {
  /// 恢复速度评分 (0-100)，越高越好
  final int recoveryScore;

  /// 恢复趋势描述
  final String trendDescription;

  /// 个性化建议
  final String advice;

  const RecoveryTrajectory({
    required this.recoveryScore,
    required this.trendDescription,
    required this.advice,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Relapse Tolerance Service
// ─────────────────────────────────────────────────────────────────────────────

/// 复发宽容计算引擎 — 纯 Dart，可测试，无 UI 依赖
class RelapseToleranceService {
  /// 7天宽容窗口
  static const int forgivenessWindowDays = 7;

  /// 恢复判定阈值：复发后多少天无再次复发算"恢复"
  static const int recoveryThresholdDays = 2;

  // ──────────────────────────────────────────────────────────
  // Core: 计算宽容后的连续天数
  // ──────────────────────────────────────────────────────────

  /// 计算一次复发后的宽容处理结果
  ///
  /// [currentStreak] — 用户当前的连续天数
  /// [longestStreak] — 用户的历史最长连续天数（不可被修改）
  /// [recentRelapses] — 本窗口期内的历史复发事件
  /// [newEvent] — 本次新记录的复发事件
  ForgivenessResult calculateForgiveness({
    required int currentStreak,
    required int longestStreak,
    required List<RelapseEvent> recentRelapses,
    required RelapseEvent newEvent,
  }) {
    final windowRelapses = _relapsesInWindow(recentRelapses);
    final count = windowRelapses + 1; // +1 for the new event

    if (count == 1) {
      // 第一次复发：颠簸标记，保留连续天数
      return ForgivenessResult(
        adjustedStreakDays: currentStreak,
        forgivenessApplied: true,
        forgivenessCountThisWeek: 1,
        action: ForgivenessAction.bump,
        message: '颠簸一下，你的连续天数不受影响。',
      );
    } else if (count == 2) {
      // 第二次：减半
      final halved = (currentStreak / 2).floor();
      return ForgivenessResult(
        adjustedStreakDays: halved,
        forgivenessApplied: true,
        forgivenessCountThisWeek: 2,
        action: ForgivenessAction.halve,
        message: '连续天数减半，但最长记录仍在，继续加油。',
      );
    } else {
      // 第三次+：重置连续天数，但保留 longestStreak 和其他数据
      return ForgivenessResult(
        adjustedStreakDays: 0,
        forgivenessApplied: false,
        forgivenessCountThisWeek: count,
        action: ForgivenessAction.reset,
        message: '连续天数重置，但你所有的经验和成就都还在。',
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // Summary: 综合复发摘要
  // ──────────────────────────────────────────────────────────

  /// 根据全部复发事件列表生成摘要
  RelapseSummary buildSummary({
    required List<RelapseEvent> allRelapses,
    int streakDays = 0,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 本周复发次数
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final relapsesThisWeek =
        allRelapses.where((e) => e.timestamp.isAfter(weekStart)).length;

    // 本月复发次数
    final monthStart = DateTime(now.year, now.month, 1);
    final relapsesThisMonth =
        allRelapses.where((e) => e.timestamp.isAfter(monthStart)).length;

    // 反弹率：有多少比例的复发后成功恢复
    final bouncedCount =
        allRelapses.where((e) => e.bouncedBack).length;
    final bounceBackRate = allRelapses.isEmpty
        ? 1.0
        : bouncedCount / allRelapses.length;

    // 距上次复发天数
    int daysSince = streakDays; // 如果当前连续中，用连续天数近似
    if (allRelapses.isNotEmpty) {
      final last = allRelapses
          .reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b)
          .timestamp;
      final lastDay = DateTime(last.year, last.month, last.day);
      daysSince = today.difference(lastDay).inDays;
    }

    // 本周已用宽容次数
    final currentForgivenessCount = _relapsesInWindow(allRelapses);

    // 生成鼓励语
    final encouragement = _generateEncouragement(
      allRelapses: allRelapses,
      daysSinceLastRelapse: daysSince,
      relapsesThisWeek: relapsesThisWeek,
      bounceBackRate: bounceBackRate,
    );

    return RelapseSummary(
      totalRelapses: allRelapses.length,
      relapsesThisWeek: relapsesThisWeek,
      relapsesThisMonth: relapsesThisMonth,
      bounceBackRate: bounceBackRate,
      daysSinceLastRelapse: daysSince,
      currentForgivenessCount: currentForgivenessCount,
      encouragement: encouragement,
    );
  }

  // ──────────────────────────────────────────────────────────
  // Recovery Trajectory: 恢复轨迹
  // ──────────────────────────────────────────────────────────

  /// 评估用户复发后的恢复速度和趋势
  RecoveryTrajectory assessRecoveryTrajectory({
    required List<RelapseEvent> allRelapses,
    required int currentStreakDays,
  }) {
    if (allRelapses.isEmpty || currentStreakDays == 0) {
      return const RecoveryTrajectory(
        recoveryScore: 50,
        trendDescription: '刚开始旅程',
        advice: '每一步都是进步，坚持下去。',
      );
    }

    // 取最近3次复发，计算间隔天数
    final sorted = List<RelapseEvent>.from(allRelapses)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final recent = sorted.length >= 3
        ? sorted.sublist(sorted.length - 3)
        : sorted;

    // 复发间隔天数趋势
    List<int> gaps = [];
    for (int i = 1; i < recent.length; i++) {
      gaps.add(recent[i].timestamp.difference(recent[i - 1].timestamp).inDays);
    }

    // 如果最后一次复发后已经恢复，加上当前连续天数
    final lastRelapse = recent.last;
    final daysSinceLast =
        DateTime.now().difference(lastRelapse.timestamp).inDays;
    if (daysSinceLast >= recoveryThresholdDays) {
      gaps.add(daysSinceLast);
    }

    int score;
    String trend;
    String advice;

    if (gaps.isEmpty) {
      score = 30;
      trend = '刚经历复发';
      advice = '现在最重要的是给自己一点宽容。';
    } else {
      final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
      final isLengthening =
          gaps.length >= 2 && gaps.last > gaps.first;

      if (avgGap >= 14 && isLengthening) {
        score = 95;
        trend = '恢复趋势优秀';
        advice = '你恢复的速度越来越快了，保持下去！';
      } else if (avgGap >= 7) {
        score = 80;
        trend = '恢复趋势良好';
        advice = '每次恢复都在积累经验，你做得很好。';
      } else if (avgGap >= 3) {
        score = 60;
        trend = '恢复中';
        advice = '可以试着识别触发因素，提前准备应对策略。';
      } else {
        score = 35;
        trend = '需要更多支持';
        advice = '别气馁，考虑联系支持伙伴或使用 SOS 功能。';
      }

      // 反弹率加分
      final bouncedCount =
          recent.where((e) => e.bouncedBack).length;
      if (bouncedCount / recent.length > 0.7) {
        score = (score * 1.1).clamp(0, 100).round();
        advice = '你的反弹能力很强，继续发挥这个优势。';
      }
    }

    return RecoveryTrajectory(
      recoveryScore: score,
      trendDescription: trend,
      advice: advice,
    );
  }

  // ──────────────────────────────────────────────────────────
  // Bounce-back detection
  // ──────────────────────────────────────────────────────────

  /// 判断一次复发后是否已经"反弹"（恢复）
  ///
  /// 规则：复发后 [RecoveryThresholdDays] 天内没有再次复发
  bool hasBouncedBack({
    required RelapseEvent relapse,
    required List<RelapseEvent> allSubsequentRelapses,
  }) {
    return allSubsequentRelapses.isEmpty ||
        allSubsequentRelapses.every((e) =>
            e.timestamp.difference(relapse.timestamp).inDays >=
            recoveryThresholdDays);
  }

  // ──────────────────────────────────────────────────────────
  // Recovery tips
  // ──────────────────────────────────────────────────────────

  /// 根据复发触发因素推荐恢复建议
  List<String> getRecoveryTips(String trigger) {
    final tips = <String>[];

    // 根据触发因素匹配
    if (_containsAny(trigger, ['社交', '朋友', '聚会', '应酬'])) {
      tips.addAll([
        '下次聚会前，提前告诉朋友你在戒烟/酒',
        '准备一个"拒绝话术"并练习几遍',
        '手里拿一杯饮料可以减少社交压力',
      ]);
    }
    if (_containsAny(trigger, ['压力', '工作', '焦虑', '紧张'])) {
      tips.addAll([
        '工作间隙做3-5分钟深呼吸练习',
        '设置定时提醒站起来活动',
        '试着把压力写下来，理清思路',
      ]);
    }
    if (_containsAny(trigger, ['情绪', '低落', '沮丧', '生气', '愤怒'])) {
      tips.addAll([
        '先让自己冷静10分钟再行动',
        '尝试正念冥想或数数法',
        '联系一个可以倾诉的朋友',
      ]);
    }
    if (_containsAny(trigger, ['习惯', '饭后', '早起', '睡前', '咖啡'])) {
      tips.addAll([
        '在这个特定时间点安排一个替代活动',
        '用口香糖、薄荷糖替代手到嘴的习惯',
        '改变日常路线，打破条件反射',
      ]);
    }
    if (_containsAny(trigger, ['无聊', '孤独', '空闲'])) {
      tips.addAll([
        '准备一个"无聊急救包"：书籍、游戏、运动器材',
        '学习一个新技能来填充空闲时间',
        '加入一个支持小组',
      ]);
    }

    // 通用建议
    tips.add('记住：一次复发不代表失败，是学习的机会');

    return tips;
  }

  // ──────────────────────────────────────────────────────────
  // Encouragement messages
  // ──────────────────────────────────────────────────────────

  /// 生成个性化鼓励语（中文）
  String _generateEncouragement({
    required List<RelapseEvent> allRelapses,
    required int daysSinceLastRelapse,
    required int relapsesThisWeek,
    required double bounceBackRate,
  }) {
    if (allRelapses.isEmpty) {
      return '你还没有经历过复发，继续坚持！';
    }

    if (daysSinceLastRelapse >= 30) {
      return '已经一个月没有复发了，你的毅力令人敬佩！';
    }
    if (daysSinceLastRelapse >= 14) {
      return '两周没有复发了，你正在建立更强的自我控制力！';
    }
    if (daysSinceLastRelapse >= 7) {
      return '一周保持下来了，每一步都算数！';
    }
    if (daysSinceLastRelapse >= 3) {
      return '已经开始恢复节奏了，给自己一点掌声。';
    }

    // 刚复发不久
    if (relapsesThisWeek == 1) {
      return '偶尔的跌倒没关系，重要的是你已经意识到了。';
    }
    if (relapsesThisWeek >= 3) {
      return '这周确实不容易，但请记住：你已经坚持比以前更久了。';
    }

    if (bounceBackRate >= 0.7) {
      return '你的恢复能力很强，70%的复发后都成功走出来了。';
    }

    return '跌倒了没关系，重要的是站起来。你正在做一件很了不起的事。';
  }

  // ──────────────────────────────────────────────────────────
  // Internal helpers
  // ──────────────────────────────────────────────────────────

  /// 获取当前7天窗口内的复发次数
  int _relapsesInWindow(List<RelapseEvent> relapses) {
    final now = DateTime.now();
    final windowStart = now.subtract(
        const Duration(days: forgivenessWindowDays));
    return relapses
        .where((e) => e.timestamp.isAfter(windowStart))
        .length;
  }

  /// 简单的中文关键词匹配
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
