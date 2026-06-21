import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

// NotificationContentGenerator can provide LLM-powered dynamic content for
// scheduleDailyReminder() and scheduleUrgeReminder() title/body params.
// Import and call NotificationContentGenerator.generateMorningReminder() or
// generateUrgeWarning() to produce personalized notification text, then pass
// the result to the scheduling methods below without changing their signatures.
// See: notification_content_generator.dart

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionGranted = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped);

    // Create notification channels (does not require permission)
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _initialized = true;
  }

  /// Request POST_NOTIFICATIONS runtime permission (Android 13+).
  /// Should be called after the user has been shown a value explanation.
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    try {
      _permissionGranted = await android.requestNotificationsPermission() ?? true;
      if (!_permissionGranted) {
        debugPrint('NotificationService: 用户拒绝了通知权限');
      }
    } catch (e) {
      debugPrint('NotificationService: 请求通知权限异常: $e');
      _permissionGranted = false;
    }
    return _permissionGranted;
  }

  /// 显式创建通知通道，避免国产ROM忽略importance设置
  /// OPPO/ColorOS、MIUI可能重置或忽略隐式创建的通道设置
  Future<void> _createNotificationChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        'daily_reminder',
        '每日提醒',
        description: '每日戒烟戒酒提醒',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'urge_reminder',
        '渴望提醒',
        description: '渴望高峰期提醒',
        importance: Importance.max,
      ),
      AndroidNotificationChannel(
        'milestone',
        '里程碑',
        description: '成就里程碑通知',
        importance: Importance.high,
      ),
    ];

    for (final channel in channels) {
      try {
        await android.createNotificationChannel(channel);
      } catch (e) {
        debugPrint('NotificationService: 创建通道 ${channel.id} 失败: $e');
      }
    }
  }

  /// 当前是否拥有通知权限
  bool get hasPermission => _permissionGranted;

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null)
      debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleDailyReminder(
      {required int hour,
      required int minute,
      required String title,
      required String body}) async {
    final androidDetails = const AndroidNotificationDetails(
        'daily_reminder', '每日提醒',
        channelDescription: '每日戒烟戒酒提醒',
        importance: Importance.high,
        priority: Priority.high);
    await _plugin.zonedSchedule(
      0,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
          android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now))
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    return scheduledDate;
  }

  Future<void> scheduleUrgeReminder(
      {required String title,
      required String body,
      required Duration delay}) async {
    final androidDetails = const AndroidNotificationDetails(
        'urge_reminder', '渴望提醒',
        channelDescription: '渴望高峰期提醒',
        importance: Importance.max,
        priority: Priority.high);
    await _plugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(delay),
      NotificationDetails(
          android: androidDetails, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showMilestoneNotification(
      {required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails('milestone', '里程碑',
        channelDescription: '成就里程碑通知',
        importance: Importance.high,
        priority: Priority.high);
    await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
            android: androidDetails, iOS: DarwinNotificationDetails()));
  }

  Future<void> cancelAll() async => await _plugin.cancelAll();

  /// 打开系统通知设置页面（国产ROM引导）
  Future<void> openNotificationSettings() async {
    if (!Platform.isAndroid) return;
    try {
      // flutter_local_notifications 不直接提供此API
      // 可在SettingsScreen中通过app_settings或url_launcher实现
      debugPrint('NotificationService: 请在设置中配置通知通道');
    } catch (e) {
      debugPrint('NotificationService: 打开通知设置失败: $e');
    }
  }
}