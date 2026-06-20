/// 华为健康平台适配器 — 连接 Huawei Health Kit
///
/// 利用已有的 [HealthDataService] 抽象接口，实现华为设备的
/// 步数、心率（华为手环/手表）、睡眠时长数据读取。
///
/// 集成前提：
/// - 注册华为开发者账号
/// - 在 AppGallery Connect 配置应用
/// - 添加 Huawei Health Kit 依赖（com.huawei.hms:health）
/// - 用户授权健康数据读取权限
///
/// 当前为接口定义 + 方法存根，待集成 HMS SDK 后补充实现。
library;

import '../health/health_data_service.dart';

/// 华为健康 Kit 数据类型映射
class HuaweiHealthDataType {
  static const String steps = 'com.huawei.health.step';
  static const String heartRate = 'com.huawei.health.heart_rate';
  static const String sleep = 'com.huawei.health.sleep';
  static const String calories = 'com.huawei.health.calories';
  static const String distance = 'com.huawei.health.distance';
}

/// 华为健康服务适配器
///
/// 实现策略模式，对接 Huawei Health Kit API。
/// 当 HMS SDK 可用时，替换 [SelfReportHealthService]。
///
/// 使用示例：
/// ```dart
/// // 在 providers.dart 中根据平台选择实现
/// final healthServiceProvider = Provider<HealthDataService>((ref) {
///   if (HuaweiHealthService.isAvailable()) {
///     return HuaweiHealthService();
///   }
///   return SelfReportHealthService();
/// });
/// ```
class HuaweiHealthService implements HealthDataService {
  /// 检查 HMS Core 和 Health Kit 是否可用
  ///
  /// 需要通过 Platform Channel 调用原生代码检测
  static Future<bool> isAvailable() async {
    // TODO: 实现 Platform Channel 检测 HMS Core 版本
    // return await _channel.invokeMethod<bool>('isHmsAvailable') ?? false;
    return false;
  }

  /// 请求用户授权健康数据读取权限
  ///
  /// 需要用户在华为健康授权弹窗中同意
  static Future<bool> requestPermissions() async {
    // TODO: 调用 HMS Health Kit 权限请求 API
    // return await _channel.invokeMethod<bool>('requestHealthPermissions') ?? false;
    return false;
  }

  @override
  Future<HealthSnapshot?> getLatestSnapshot(String userId) async {
    // TODO: 通过 HMS Health Kit API 获取最新健康数据
    // 1. 查询今日步数
    // 2. 查询最近心率
    // 3. 查询昨晚睡眠时长
    return null;
  }

  @override
  Stream<HealthSnapshot> watchSnapshots(String userId) {
    // TODO: 注册 HMS Health Kit 数据变化监听
    return Stream.empty();
  }

  /// 获取指定日期范围的步数汇总
  Future<int> getStepsRange({
    required DateTime start,
    required DateTime end,
  }) async {
    // TODO: 调用 HMS Health Kit 步数聚合 API
    return 0;
  }

  /// 获取最近 24 小时的心率数据点
  Future<List<HeartRateDataPoint>> getHeartRateHistory({
    required DateTime since,
  }) async {
    // TODO: 调用 HMS Health Kit 心率数据 API
    return [];
  }

  /// 获取最近一次睡眠分析
  Future<SleepAnalysis?> getLatestSleepAnalysis() async {
    // TODO: 调用 HMS Health Kit 睡眠数据 API
    // 包含：入睡时间、醒来时间、深睡时长、浅睡时长、REM 时长
    return null;
  }

  @override
  void dispose() {}
}

/// 心率数据点
class HeartRateDataPoint {
  final DateTime timestamp;
  final int bpm;

  const HeartRateDataPoint({required this.timestamp, required this.bpm});
}

/// 睡眠分析结果
class SleepAnalysis {
  final DateTime sleepStart;
  final DateTime sleepEnd;
  final Duration deepSleep;
  final Duration lightSleep;
  final Duration remSleep;
  final int sleepScore; // 0-100

  const SleepAnalysis({
    required this.sleepStart,
    required this.sleepEnd,
    required this.deepSleep,
    required this.lightSleep,
    required this.remSleep,
    required this.sleepScore,
  });

  Duration get totalSleep => sleepEnd.difference(sleepStart);

  bool get isPoorSleep => sleepScore < 60 || totalSleep.inHours < 6;
  bool get isGoodSleep => sleepScore >= 80 && totalSleep.inHours >= 7;

  /// 质量描述（中文）
  String get qualityLabel {
    if (sleepScore >= 80) return '优质';
    if (sleepScore >= 60) return '一般';
    return '较差';
  }
}
