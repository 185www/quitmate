import 'dart:async';

/// 同步状态 — 反映当前云同步操作的状态
class SyncStatus {
  final bool syncing;
  final double? progress;
  final String? error;
  final DateTime? lastSync;

  const SyncStatus({
    this.syncing = false,
    this.progress,
    this.error,
    this.lastSync,
  });

  SyncStatus copyWith({
    bool? syncing,
    double? progress,
    String? error,
    DateTime? lastSync,
  }) {
    return SyncStatus(
      syncing: syncing ?? this.syncing,
      progress: progress ?? this.progress,
      error: error,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

/// 同步结果 — 一次同步操作的返回值
class SyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final String? error;

  const SyncResult({
    required this.success,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.error,
  });
}

/// 云同步抽象接口 — 所有实现必须使用端到端加密（E2EE）
///
/// 设计原则：
/// - 零知识架构：服务器永远无法解密用户数据
/// - 用户明确同意：启用/禁用需要用户主动操作
/// - 离线优先：即使云同步不可用，本地功能不受影响
abstract class SyncService {
  /// 同步状态流 — UI 可据此显示同步进度
  Stream<SyncStatus> get statusStream;

  /// 检查用户是否启用了云同步
  Future<bool> isEnabled();

  /// 启用或禁用云同步（需要用户明确同意）
  Future<void> setEnabled(bool enabled);

  /// 触发一次同步操作
  Future<SyncResult> syncNow();

  /// 获取上次同步时间
  Future<DateTime?> getLastSyncTime();
}

/// 本地同步服务 — 默认实现，不包含实际云同步功能
///
/// 此实现始终返回 isEnabled=false，syncNow 返回空结果。
/// 适用于完全离线使用的场景。
/// 未来可替换为基于自托管服务器或零知识云的实现。
class LocalOnlySyncService implements SyncService {
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  @override
  Future<bool> isEnabled() async {
    // 本地模式：云同步始终未启用
    return false;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      // 本地模式不支持云同步，抛出友好的中文提示
      throw UnsupportedError('当前为本地模式，不支持云同步功能。请等待后续版本更新。');
    }
    // 禁用操作在本地模式下为空操作
  }

  @override
  Future<SyncResult> syncNow() async {
    // 本地模式：无需同步，直接返回空结果
    return const SyncResult(
      success: true,
      uploadedCount: 0,
      downloadedCount: 0,
    );
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    // 本地模式：从未同步过
    return null;
  }

  /// 释放资源
  void dispose() {
    _statusController.close();
  }
}
