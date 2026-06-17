import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationTapped);
    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleDailyReminder({required int hour, required int minute, required String title, required String body}) async {
    final androidDetails = const AndroidNotificationDetails('daily_reminder', '每日提醒', channelDescription: '每日戒烟戒酒提醒', importance: Importance.high, priority: Priority.high);
    await _plugin.zonedSchedule(0, title, body, _nextInstanceOfTime(hour, minute),
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
    return scheduledDate;
  }

  Future<void> scheduleUrgeReminder({required String title, required String body, required Duration delay}) async {
    final androidDetails = const AndroidNotificationDetails('urge_reminder', '渴望提醒', channelDescription: '渴望高峰期提醒', importance: Importance.max, priority: Priority.high);
    await _plugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body,
      tz.TZDateTime.now(tz.local).add(delay),
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showMilestoneNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails('milestone', '里程碑', channelDescription: '成就里程碑通知', importance: Importance.high, priority: Priority.high);
    await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body,
      const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails()));
  }

  Future<void> cancelAll() async => await _plugin.cancelAll();
}