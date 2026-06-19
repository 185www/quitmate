import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../domain/entity/user.dart';

class WidgetService {
  static const _widgetName = 'QuitMateWidgetProvider';

  /// Format life regained as human-readable string (hours/minutes, not days)
  static String _formatLifeRegained(int totalMinutes) {
    if (totalMinutes < 60) {
      return '+$totalMinutes 分钟生命';
    } else if (totalMinutes < 1440) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return mins > 0 ? '+$hours 小时 $mins 分钟生命' : '+$hours 小时生命';
    } else {
      final days = totalMinutes ~/ 1440;
      return '+$days 天生命';
    }
  }

  static Future<void> updateWidget(User? user) async {
    if (user == null || !user.hasQuitDate) return;

    try {
      final days = user.daysSinceQuit;
      final moneySaved = user.dailyCost * days;
      final lifeMinutes = (user.dailyLifeRegainedMinutes * days).round();

      // Calculate recovery progress from milestones
      final milestones = HealthMilestone.milestones;
      int progressPct = 0;
      for (int i = milestones.length - 1; i >= 0; i--) {
        if (milestones[i]['days'] <= days) {
          progressPct = milestones[i]['pct'] as int;
          break;
        }
      }

      await HomeWidget.saveWidgetData<String>('widget_days', '第 $days 天');
      await HomeWidget.saveWidgetData<String>(
          'widget_money', '已省 ${moneySaved.toStringAsFixed(0)} 元');
      await HomeWidget.saveWidgetData<String>(
          'widget_life', _formatLifeRegained(lifeMinutes));
      await HomeWidget.saveWidgetData<String>(
          'widget_recovery', '身体恢复 $progressPct%');
      await HomeWidget.saveWidgetData<int>('widget_progress', progressPct);

      await HomeWidget.updateWidget(
        androidName: _widgetName,
        iOSName: _widgetName,
      );
    } catch (e) {
      debugPrint('WidgetService.updateWidget error: $e');
    }
  }
}
