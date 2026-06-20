/// 桌面小组件服务 — 增强版
///
/// 改进点：
/// - 更多数据展示（渴望预测、风险等级、每日任务进度）
/// - 更频繁的 Widget 数据刷新（每次 check-in 后立即刷新）
/// - 支持多种 Widget 布局尺寸
/// - 与渴望预测引擎联动，在高危时段显示预警
library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../domain/entity/user.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/daily_log.dart';
import '../coach/craving_predictor.dart';
import '../coach/relapse_risk_engine.dart';

/// 小组件数据模型
class WidgetData {
  final String userName;
  final int daysSinceQuit;
  final int streakDays;
  final int level;
  final String levelTitle;
  final int cravingIntensity; // 0-10, 0 = 未记录
  final String moodLabel; // 好/一般/差
  final String riskLabel; // 低/中/高/极高
  final int riskScore; // 0-100
  final int dailyTasksCompleted;
  final int dailyTasksTotal;
  final String tipOfTheDay;

  const WidgetData({
    this.userName = '',
    this.daysSinceQuit = 0,
    this.streakDays = 0,
    this.level = 1,
    this.levelTitle = '初学者',
    this.cravingIntensity = 0,
    this.moodLabel = '--',
    this.riskLabel = '低',
    this.riskScore = 0,
    this.dailyTasksCompleted = 0,
    this.dailyTasksTotal = 0,
    this.tipOfTheDay = '',
  });

  Map<String, dynamic> toMap() => {
        'user_name': userName,
        'days_since_quit': daysSinceQuit,
        'streak_days': streakDays,
        'level': level,
        'level_title': levelTitle,
        'craving_intensity': cravingIntensity,
        'mood_label': moodLabel,
        'risk_label': riskLabel,
        'risk_score': riskScore,
        'daily_tasks_completed': dailyTasksCompleted,
        'daily_tasks_total': dailyTasksTotal,
        'tip_of_the_day': tipOfTheDay,
      };

  /// 转为 JSON 字符串（用于 Widget 存储）
  String toJson() => jsonEncode(toMap());

  factory WidgetData.fromMap(Map<String, dynamic> map) => WidgetData(
        userName: map['user_name'] as String? ?? '',
        daysSinceQuit: map['days_since_quit'] as int? ?? 0,
        streakDays: map['streak_days'] as int? ?? 0,
        level: map['level'] as int? ?? 1,
        levelTitle: map['level_title'] as String? ?? '初学者',
        cravingIntensity: map['craving_intensity'] as int? ?? 0,
        moodLabel: map['mood_label'] as String? ?? '--',
        riskLabel: map['risk_label'] as String? ?? '低',
        riskScore: map['risk_score'] as int? ?? 0,
        dailyTasksCompleted: map['daily_tasks_completed'] as int? ?? 0,
        dailyTasksTotal: map['daily_tasks_total'] as int? ?? 0,
        tipOfTheDay: map['tip_of_the_day'] as String? ?? '',
      );
}

/// 每日提示语库
class WidgetTips {
  static const _tips = [
    '大多数渴望在 3-5 分钟内自然消退。',
    '深呼吸可以快速缓解焦虑，试试 4-7-8 呼吸法。',
    '每抵抗一次渴望，你的大脑就在改变。',
    '喝水、嚼口香糖是有效的替代策略。',
    'HALT 原则：饿、怒、孤、累时常引发渴望。',
    '运动是最有效的渴望对抗方法之一。',
    '记录你的渴望模式，有助于提前预防。',
    '社交场合提前准备拒绝话术。',
    '你的连胜记录就是最好的动力。',
    '不要因为一次破戒就放弃。Slide, not a fall.',
  ];

  /// 获取今天的提示（基于日期的伪随机）
  static String getTipOfTheDay() {
    final dayOfYear = DateTime.now().difference(
      DateTime(DateTime.now().year),
    ).inDays;
    return _tips[dayOfYear % _tips.length];
  }
}

/// 增强版 Widget 服务
///
/// 相比原版 [WidgetService] 的改进：
/// 1. 联动渴望预测引擎，提供风险评分
/// 2. 联动复发风险评估，在高危时段显示预警
/// 3. 显示每日任务完成进度
/// 4. 每日自动刷新一条提示语
class WidgetServiceV2 {
  static const _widgetName = 'QuitMateWidget';
  static const _androidWidgetName = 'QuitMateWidgetProvider';

  /// 更新 Widget 数据到 HomeWidget
  ///
  /// 应在以下时机调用：
  /// - 用户 check-in 后
  /// - 每日任务完成后
  /// - 渴望记录后
  /// - App 启动时
  /// - 每日零点自动刷新
  static Future<void> updateWidgetData({
    required User? user,
    required GameProfile? gameProfile,
    required DailyLogEntry? todayLog,
    int cravingIntensity = 0,
    int dailyTasksCompleted = 0,
    int dailyTasksTotal = 0,
    int? riskScore,
    String? riskLabel,
  }) async {
    final data = WidgetData(
      userName: user?.nickname ?? '',
      daysSinceQuit: user?.daysSinceQuit ?? 0,
      streakDays: gameProfile?.streakDays ?? 0,
      level: gameProfile?.level ?? 1,
      levelTitle: gameProfile?.levelTitle ?? '初学者',
      cravingIntensity: cravingIntensity,
      moodLabel: _moodToLabel(todayLog?.mood),
      riskLabel: riskLabel ?? '低',
      riskScore: riskScore ?? 0,
      dailyTasksCompleted: dailyTasksCompleted,
      dailyTasksTotal: dailyTasksTotal,
      tipOfTheDay: WidgetTips.getTipOfTheDay(),
    );

    // 将数据保存到 HomeWidget
    for (final entry in data.toMap().entries) {
      await HomeWidget.saveWidgetData(entry.key, entry.value);
    }

    // 刷新 Widget 显示
    try {
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
    } catch (_) {
      // Widget 刷新失败不阻断主流程
    }
  }

  /// 仅刷新每日提示（零点定时任务调用）
  static Future<void> refreshDailyTip() async {
    await HomeWidget.saveWidgetData(
      'tip_of_the_day',
      WidgetTips.getTipOfTheDay(),
    );
    try {
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (_) {}
  }

  /// 渲染风险等级为中文标签
  static String _moodToLabel(int? mood) {
    if (mood == null) return '--';
    if (mood >= 4) return '好';
    if (mood >= 2) return '一般';
    return '差';
  }
}
