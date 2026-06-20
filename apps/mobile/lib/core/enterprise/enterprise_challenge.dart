/// 企业定制化挑战系统
///
/// 允许企业HR/管理员创建、管理面向员工群体的戒断挑战。
/// 企业可以定制挑战名称、目标天数、企业品牌徽章等。
library;

/// 企业定制化群体挑战
class EnterpriseChallenge {
  /// 挑战唯一标识
  final String id;

  /// 挑战标题
  final String title;

  /// 挑战描述
  final String description;

  /// 所属企业ID
  final String companyId;

  /// 目标天数
  final int targetDays;

  /// 已报名人数
  final int enrolledCount;

  /// 已完成人数
  final int completedCount;

  /// 挑战开始日期
  final DateTime startDate;

  /// 挑战结束日期（null 表示无截止日期）
  final DateTime? endDate;

  /// 是否进行中
  final bool isActive;

  /// 完成奖励经验值
  final int xpReward;

  /// 企业品牌自定义徽章标识（null 表示使用默认徽章）
  final String? customBadge;

  const EnterpriseChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.companyId,
    required this.targetDays,
    required this.enrolledCount,
    required this.completedCount,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.xpReward,
    this.customBadge,
  });

  factory EnterpriseChallenge.fromJson(Map<String, dynamic> json) {
    return EnterpriseChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      companyId: json['company_id'] as String,
      targetDays: json['target_days'] as int,
      enrolledCount: json['enrolled_count'] as int,
      completedCount: json['completed_count'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? false,
      xpReward: json['xp_reward'] as int,
      customBadge: json['custom_badge'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'company_id': companyId,
        'target_days': targetDays,
        'enrolled_count': enrolledCount,
        'completed_count': completedCount,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_active': isActive,
        'xp_reward': xpReward,
        'custom_badge': customBadge,
      };

  /// 计算完成率
  double get completionRate =>
      enrolledCount > 0 ? completedCount / enrolledCount : 0.0;

  /// 判断挑战是否已结束
  bool get isFinished =>
      endDate != null && DateTime.now().isAfter(endDate!);
}

/// 企业挑战管理器
///
/// 负责企业挑战的获取、报名、进度更新等操作。
/// 当前为本地占位实现，未来可对接企业后端API。
class EnterpriseChallengeManager {
  /// 获取可用的企业挑战列表
  ///
  /// 本地实现返回空列表。
  Future<List<EnterpriseChallenge>> getChallenges() async {
    // 占位实现：未来对接企业后端API获取挑战列表
    return [];
  }

  /// 报名参加指定挑战
  ///
  /// [challengeId] 挑战ID
  Future<void> enrollInChallenge(String challengeId) async {
    // 占位实现：未来对接企业后端API完成报名
  }

  /// 更新挑战进度
  ///
  /// [challengeId] 挑战ID
  /// [progressDays] 当前进度天数
  Future<void> updateChallengeProgress(
      String challengeId, int progressDays) async {
    // 占位实现：未来对接企业后端API更新进度
  }
}