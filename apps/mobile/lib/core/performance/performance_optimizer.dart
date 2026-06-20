/// Android 性能优化模块
///
/// 集中管理启动速度、内存和电池优化策略。
import 'dart:io';

/// 性能配置常量
class PerformanceConfig {
  static const bool enabled = true;
  static const int firstFrameTimeoutMs = 3000;
  static const int slowStartupThresholdMs = 2000;
  static const int lazyLoadThreshold = 50;
  static const int imageCacheMaxMB = 50;
  static const int backgroundTaskMinIntervalMin = 30;

  static bool get isLowMemoryDevice {
    return false; // TODO: Platform Channel
  }
}

/// 启动优化器 — 管理分阶段初始化
class StartupOptimizer {
  static const _criticalModules = ['theme', 'router', 'user_session', 'pipl_consent'];
  static const _enhancedModules = ['game_profile', 'notifications', 'health_snapshot', 'daily_log', 'widget_update'];
  static const _deferredModules = ['pattern_analyzer', 'craving_predictor', 'ml_models', 'community_content', 'ota_check'];

  static List<String> get criticalModules => List.unmodifiable(_criticalModules);
  static List<String> get enhancedModules => List.unmodifiable(_enhancedModules);
  static List<String> get deferredModules => List.unmodifiable(_deferredModules);

  static final DateTime _startTime = DateTime.now();

  static int getElapsedMs() {
    return DateTime.now().difference(_startTime).inMilliseconds;
  }

  static bool isSlowStartup() {
    return getElapsedMs() > PerformanceConfig.slowStartupThresholdMs;
  }

  static final Map<String, int> moduleLoadTimes = {};

  static void markModuleLoaded(String module) {
    moduleLoadTimes[module] = getElapsedMs();
  }

  static String getPerformanceReport() {
    final buffer = StringBuffer('Performance Report:\n');
    buffer.writeln('Total startup: ${getElapsedMs()}ms');

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
  static bool shouldLazyLoad(int itemCount) =>
      itemCount > PerformanceConfig.lazyLoadThreshold;

  static int maxConcurrentAnimations({required bool isLowMemory}) =>
      isLowMemory ? 1 : 3;

  static int maxCacheSizeMB({required bool isLowMemory}) =>
      isLowMemory ? 20 : PerformanceConfig.imageCacheMaxMB;
}

/// 电池优化建议
class BatteryOptimization {
  static bool shouldRunBackgroundTask({
    required DateTime lastExecution,
    required int minIntervalMinutes,
  }) {
    final interval = DateTime.now().difference(lastExecution).inMinutes;
    return interval >= minIntervalMinutes;
  }

  static int getRecommendedInterval({
    required double userActivityScore,
    required int? batteryLevel,
  }) {
    var interval = PerformanceConfig.backgroundTaskMinIntervalMin;
    if (batteryLevel != null && batteryLevel < 20) {
      interval *= 2;
    }
    if (userActivityScore > 0.7) {
      interval = (interval * 0.7).round();
    }
    return interval;
  }
}
