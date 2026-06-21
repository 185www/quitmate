/// 高级订阅服务
///
/// 设计原则："基础版永远免费且全功能"
/// - 免费版包含所有核心戒断功能
/// - 高级版提供增值增强功能（AI深度对话、专业音频等）
/// - 当前所有高级功能均为占位，等待支付集成（Apple IAP / Google Play / 微信支付）
library;

import '../../data/database/app_database.dart';

/// 订阅层级
enum SubscriptionTier {
  /// 免费版 — 永久免费，包含所有核心功能
  free,

  /// 高级版 — 增值功能，未来开放
  premium,
}

/// 高级功能定义
class PremiumFeature {
  /// 功能唯一标识
  final String id;

  /// 功能名称
  final String name;

  /// 功能描述
  final String description;

  /// 该功能是否已实现可用
  final bool isAvailable;

  const PremiumFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.isAvailable,
  });
}

/// 订阅服务
///
/// 管理用户订阅状态和高级功能访问控制。
/// 默认始终为免费版，高级版为未来支付集成的占位。
class SubscriptionService {
  final AppDatabase _db;

  /// app_config 中存储订阅层级的键名
  static const _tierConfigKey = 'subscription_tier';

  SubscriptionService(this._db);

  /// 获取当前订阅层级
  ///
  /// 默认返回 [SubscriptionTier.free]。
  /// 未来支付集成后，将从 app_config 读取持久化的订阅状态。
  Future<SubscriptionTier> getCurrentTier() async {
    try {
      final tierStr = await _db.getConfig(_tierConfigKey);
      if (tierStr == 'premium') {
        return SubscriptionTier.premium;
      }
    } catch (_) {
      // 读取失败，默认免费版
    }
    return SubscriptionTier.free;
  }

  /// 检查指定功能是否可用
  ///
  /// [featureId] 功能标识，对应 [premiumFeatures] 中的 id
  /// 当前所有高级功能均返回 false（免费版无权访问）。
  /// 未来支付集成后，将根据实际订阅层级判断。
  Future<bool> isFeatureAvailable(String featureId) async {
    final tier = await getCurrentTier();
    if (tier == SubscriptionTier.premium) {
      // 高级版用户：检查功能是否已实现
      final feature = premiumFeatures
          .where((f) => f.id == featureId)
          .firstOrNull;
      return feature?.isAvailable ?? false;
    }
    return false;
  }

  /// 高级功能列表
  ///
  /// 定义所有计划中的高级增值功能。
  /// [isAvailable] 标识该功能是否已开发完成并可用。
  static final List<PremiumFeature> premiumFeatures = [
    PremiumFeature(
      id: 'llm_deep_chat',
      name: 'AI深度对话',
      description: '端侧LLM个性化深度对话支持',
      isAvailable: true,
    ),
    PremiumFeature(
      id: 'meditation_audio',
      name: '专业冥想音频库',
      description: '由心理专家录制的正念冥想引导',
      isAvailable: false,
    ),
    PremiumFeature(
      id: 'advanced_analytics',
      name: '高级数据分析报告',
      description: '更详细的戒断数据分析',
      isAvailable: true,
    ),
    PremiumFeature(
      id: 'cloud_sync',
      name: '多设备云同步',
      description: '端到端加密的跨设备数据同步',
      isAvailable: false,
    ),
    PremiumFeature(
      id: 'custom_theme',
      name: '自定义主题',
      description: '更多界面主题和个性化设置',
      isAvailable: false,
    ),
  ];

  /// 获取功能列表及其可用状态
  ///
  /// 根据当前订阅层级，标注每个高级功能是否可使用。
  Future<List<Map<String, dynamic>>> getFeaturesWithAvailability() async {
    final tier = await getCurrentTier();
    return premiumFeatures.map((feature) {
      final canUse = tier == SubscriptionTier.premium && feature.isAvailable;
      return {
        'id': feature.id,
        'name': feature.name,
        'description': feature.description,
        'is_available': feature.isAvailable,
        'can_use': canUse,
      };
    }).toList();
  }
}