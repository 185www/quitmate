/// Android 性能优化模块 — 启动速度、内存、电池优化
///
/// 集中管理所有性能优化策略：
/// - Flutter 引擎预热
/// - 非关键模块延迟初始化
/// - 大列表懒加载配置
/// - 图片缓存策略
/// - 电池消耗优化（后台任务最小化）
library;

import 'dart:io';

/// 性能配置
class PerformanceConfig {
  /// 是否启用性能优化（可在调试时关闭）
  static const bool enabled = true;

  /// 首屏加载超时阈值（毫秒）
  static const int firstFrameTimeoutMs = 3000;

  /// 首屏加载"慢启动"阈值（毫秒），超过则记录警告
  static const int slowStartupThresholdMs = 2000;

  /// 大列表懒加载阈值（item 数量超过此值启用懒加载）
  static const int lazyLoadThreshold = 50;

  /// 图片缓存最大内存（MB）
  static const int imageCacheMaxMB = 50;

  /// 后台任务最小间隔（分钟）— 控制通知频率以节省电池
  static const int backgroundTaskMinIntervalMin = 30;

  /// 是否为低内存设备（< 2GB RAM）
  static bool get isLowMemoryDevice {
    // 通过 Platform Channel 获取设备内存信息
    // 低端设备上自动禁用动画、减少缓存
    return false; // TODO: 实现 Platform Channel 检测
  }
}

/// 启动优化器 — 管理分阶段初始化
///
/// 将应用启动分为三个阶段：
/// 1. **首屏必须**（< 500ms）：路由、主题、用户基本状态
/// 2. **首屏增强**（< 1500ms）：游戏化数据、通知、健康数据
/// 3. **后台延迟**（> 3000ms）：数据分析、ML 模型预热、内容更新
class StartupOptimizer {
  /// 首屏必须加载的模块列表
  static const _criticalModules = [
    'theme',
    'router',
    'user_session',
    'pipl_consent',
  ];

  /// 首屏增强模块（异步并行加载）
  static const _enhancedModules = [
    'game_profile',
    'notifications',
    'health_snapshot',
    'daily_log',
    'widget_update',
  ];

  /// 后台延迟加载模块
  static const _deferredModules = [
    'pattern_analyzer',
    'craving_predictor',
    'ml_models',
    'community_content',
    'ota_check',
  ];

  /// 获取首屏必须加载的模块列表
  static List<String> get criticalModules =>
      List.unmodifiable(_criticalModules);

  /// 获取增强模块列表
  static List<String> get enhancedModules =>
      List.unmodifiable(_enhancedModules);

  /// 获取延迟加载模块列表
  static List<String> get deferredModules =>
      List.unmodifiable(_deferredModules);

  /// 记录启动时间（用于性能监控）
  static final _startTime = DateTime.now();

  /// 获取自应用启动以来的毫秒数
  static int elapsedMs => DateTime.now().difference(_startTime).inMilliseconds;

  /// 检查是否超过慢启动阈值
  static bool get isSlowStartup => elapsedMs > PerformanceConfig.slowStartupThresholdMs;

  /// 记录各阶段加载时间（调试用）
  static final Map<String, int> moduleLoadTimes = {};

  /// 标记模块加载完成
  static void markModuleLoaded(String module) {
    moduleLoadTimes[module] = elapsedMs;
  }

  /// 获取性能报告
  static String getPerformanceReport() {
    final buffer = StringBuffer('Performance Report:\n');
    buffer.writeln('Total startup: ${elapsedMs}ms');

    for (final module in _criticalModules) {
      final time = moduleLoadTimes[module];
      buffer.writeln('  [$module] ${time != null ? "${time}ms" : "not loaded"}');
    }

    if (moduleLoadTimes.length >= _criticalModules.length) {
      final criticalEnd = moduleLoadTimes.values.reduce((a, b) => a > b ? a : b);
      buffer.writeln('Critical path: ${criticalEnd}ms');
    }

    return buffer.toString();
  }
}

/// 内存优化建议
class MemoryOptimization {
  /// 大列表应使用的 ListView.builder 模式提示
  ///
  /// 当 item 数量超过 [PerformanceConfig.lazyLoadThreshold] 时，
  /// 必须使用 ListView.builder 而非 ListView(children: [...])
  static bool shouldLazyLoad(int itemCount) =>
      itemCount > PerformanceConfig.lazyLoadThreshold;

  /// 低内存设备上减少动画复杂度的建议
  static int maxConcurrentAnimations({
    required bool isLowMemory,
  }) =>
      isLowMemory ? 1 : 3;

  /// 图片缓存配置建议
  static int maxCacheSizeMB({required bool isLowMemory}) =>
      isLowMemory ? 20 : PerformanceConfig.imageCacheMaxMB;
}

/// 电池优化建议
class BatteryOptimization {
  /// 后台通知任务是否应该执行（基于最小间隔）
  static bool shouldRunBackgroundTask({
    required DateTime lastExecution,
    required int minIntervalMinutes,
  }) {
    final interval = DateTime.now().difference(lastExecution).inMinutes;
    return interval >= minIntervalMinutes;
  }

  /// 获取推荐的后台任务间隔（分钟）
  ///
  /// 基于用户活跃度和设备电量智能调整
  static int getRecommendedInterval({
    required double userActivityScore, // 0-1, 越高越活跃
    required int? batteryLevel, // 0-100, null = 未知
  }) {
    var interval = PerformanceConfig.backgroundTaskMinIntervalMin;

    // 低电量时减少后台任务
    if (batteryLevel != null && batteryLevel < 20) {
      interval *= 2;
    }

    // 高活跃度用户可以接受更频繁的通知
    if (userActivityScore > 0.7) {
      interval = (interval * 0.7).round();
    }

    return interval;
  }
}
