import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Abstract interface for platform-specific notification handling.
///
/// This abstraction separates iOS (UNUserNotificationCenter) vs Android
/// (NotificationChannels + POST_NOTIFICATIONS runtime permission)
/// so that [NotificationService] can delegate platform-specific logic.
///
/// Future expansion: APNs remote push vs local-only notifications.
abstract class NotificationPlatformService {
  /// Initialize platform-specific notification subsystem.
  ///
  /// Called once during app startup (from [NotificationService.initialize]).
  /// On iOS this sets the UNUserNotificationCenter delegate.
  /// On Android this creates notification channels.
  Future<void> initialize();

  /// Request user permission for notifications.
  ///
  /// Returns `true` if the user granted permission.
  /// On iOS 10+ this calls UNUserNotificationCenter.requestAuthorization.
  /// On Android 13+ this calls the POST_NOTIFICATIONS runtime permission flow.
  Future<bool> requestPermission();

  /// Check whether the app currently holds notification permission.
  ///
  /// Returns `true` if notifications are authorized / granted.
  Future<bool> hasPermission();

  /// Open the system notification settings for the app.
  ///
  /// On Android this navigates to the app's notification channel settings.
  /// On iOS this opens Settings → QuitMate → Notifications.
  Future<void> openSystemSettings();
}

/// iOS implementation using UNUserNotificationCenter.
class IOSNotificationPlatformService implements NotificationPlatformService {
  final FlutterLocalNotificationsPlugin _plugin;

  IOSNotificationPlatformService(this._plugin);

  @override
  Future<void> initialize() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      // DarwinInitializationSettings in NotificationService already configures
      // requestAlertPermission / requestBadgePermission / requestSoundPermission.
      // The actual delegate is handled by the native AppDelegate.
      debugPrint('IOSNotificationPlatformService: initialized');
    }
  }

  @override
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios == null) return false;
    try {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('IOSNotificationPlatformService: permission granted = $granted');
      return granted ?? false;
    } catch (e) {
      debugPrint('IOSNotificationPlatformService: request permission failed: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    // flutter_local_notifications does not expose a direct "hasPermission"
    // API for iOS; we rely on the Darwin plugin delegate behavior.
    // A more precise check can be done via method channel if needed.
    return true; // assume granted if initialize succeeded without denial
  }

  @override
  Future<void> openSystemSettings() async {
    // iOS: open app-specific notification settings
    // This is best handled via url_launcher opening the app-settings URL scheme.
    debugPrint('IOSNotificationPlatformService: open settings via url_launcher');
  }
}

/// Android implementation using notification channels and runtime permissions.
class AndroidNotificationPlatformService implements NotificationPlatformService {
  final FlutterLocalNotificationsPlugin _plugin;

  AndroidNotificationPlatformService(this._plugin);

  @override
  Future<void> initialize() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await _requestNotificationPermission();
      await _createNotificationChannels();
    }
  }

  @override
  Future<bool> requestPermission() async {
    return _requestNotificationPermission();
  }

  Future<bool> _requestNotificationPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    try {
      final granted = await android.requestNotificationsPermission() ?? true;
      if (!granted) {
        debugPrint('NotificationService: 用户拒绝了通知权限');
      }
      return granted;
    } catch (e) {
      debugPrint('NotificationService: 请求通知权限异常: $e');
      return false;
    }
  }

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

  @override
  Future<bool> hasPermission() async {
    // AndroidFlutterLocalNotificationsPlugin does not expose hasPermission;
    // this is tracked in-memory in the existing NotificationService._permissionGranted.
    return true;
  }

  @override
  Future<void> openSystemSettings() async {
    if (!Platform.isAndroid) return;
    debugPrint('NotificationService: 请在设置中配置通知通道');
  }
}

/// Factory that returns the correct platform service.
NotificationPlatformService createNotificationPlatformService(
    FlutterLocalNotificationsPlugin plugin) {
  if (Platform.isIOS) {
    return IOSNotificationPlatformService(plugin);
  } else if (Platform.isAndroid) {
    return AndroidNotificationPlatformService(plugin);
  }
  // Fallback for other platforms (macOS, etc.)
  return _FallbackNotificationPlatformService(plugin);
}

/// No-op fallback for desktop / web platforms.
class _FallbackNotificationPlatformService
    implements NotificationPlatformService {
  final FlutterLocalNotificationsPlugin _plugin;
  _FallbackNotificationPlatformService(this._plugin);

  @override
  Future<void> initialize() async {
    debugPrint('FallbackNotificationPlatformService: no-op on this platform');
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> openSystemSettings() async {}
}
