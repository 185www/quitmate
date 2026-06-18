import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../domain/entity/user.dart';

class WidgetService {
  static const _widgetName = 'QuitMateWidgetProvider';

  static Future<void> updateWidget(User? user) async {
    if (user == null || !user.hasQuitDate) return;

    try {
      final days = user.daysSinceQuit;
      final moneySaved = user.dailyCost * days;
      final lifeMinutes = user.dailyLifeRegainedMinutes * days;
      final lifeDays = (lifeMinutes / 1440).floor();

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
          'widget_money', '💰 已省 ¥${moneySaved.toStringAsFixed(0)}');
      await HomeWidget.saveWidgetData<String>(
          'widget_life', '❤️ +$lifeDays 天生命');
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
