/// 可穿戴设备集成服务
///
/// 为智能手表、手环等可穿戴设备提供抽象集成层。
/// 支持呼吸引导推送、渴望提醒震动、实时心率监测等功能。
/// 当前为本地占位实现，未来可对接 Apple Watch / Wear OS / 华为手环 / 小米手环。
library;

import 'dart:async';

/// 可穿戴设备类型
enum WearableDeviceType {
  /// 无连接设备
  none,

  /// Apple Watch
  appleWatch,

  /// Android Wear OS
  androidWear,

  /// 华为手环/手表
  huaweiBand,

  /// 小米手环
  miBand,
}

/// 可穿戴设备服务接口
///
/// 定义与可穿戴设备交互的所有功能。
abstract class WearableService {
  /// 检查是否有可穿戴设备已连接
  Future<bool> isConnected();

  /// 获取当前连接的设备类型
  ///
  /// 未连接时返回 [WearableDeviceType.none]。
  Future<WearableDeviceType> getDeviceType();

  /// 向可穿戴设备发送呼吸引导
  ///
  /// [inhaleSeconds] 吸气秒数
  /// [holdSeconds] 屏息秒数
  /// [exhaleSeconds] 呼气秒数
  ///
  /// 设备上将显示呼吸节奏动画和触觉引导。
  Future<void> sendBreathingGuidance({
    required int inhaleSeconds,
    required int holdSeconds,
    required int exhaleSeconds,
  });

  /// 触发渴望提醒
  ///
  /// 向可穿戴设备发送震动反馈，提醒用户当前有渴望记录。
  Future<void> sendCravingAlert();

  /// 实时心率数据流
  ///
  /// 订阅此流可获取来自可穿戴设备的实时心率数据（单位：bpm）。
  /// 未连接设备时为空流。
  Stream<double?> get heartRateStream;
}

/// 本地实现（无实际可穿戴设备连接）
///
/// 纯本地占位实现，所有可穿戴功能均返回默认值。
/// 未来可替换为真实的设备SDK客户端。
class LocalWearableService implements WearableService {
  /// 心率数据流控制器（空流）
  final StreamController<double?> _heartRateController =
      StreamController<double?>.broadcast();

  /// 本地实现始终返回 false（无设备连接）
  @override
  Future<bool> isConnected() async {
    return false;
  }

  /// 本地实现始终返回 [WearableDeviceType.none]
  @override
  Future<WearableDeviceType> getDeviceType() async {
    return WearableDeviceType.none;
  }

  /// 本地实现为空操作（无法向设备发送呼吸引导）
  @override
  Future<void> sendBreathingGuidance({
    required int inhaleSeconds,
    required int holdSeconds,
    required int exhaleSeconds,
  }) async {
    // 占位实现：未来对接 Apple Watch / Wear OS SDK
  }

  /// 本地实现为空操作（无法向设备发送震动提醒）
  @override
  Future<void> sendCravingAlert() async {
    // 占位实现：未来对接设备震动反馈API
  }

  /// 本地实现返回空流（无心率数据）
  @override
  Stream<double?> get heartRateStream => _heartRateController.stream;

  /// 释放资源
  void dispose() {
    _heartRateController.close();
  }
}