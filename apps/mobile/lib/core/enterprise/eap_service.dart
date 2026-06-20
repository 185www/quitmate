/// 企业员工援助计划（EAP）服务
///
/// 为企业客户提供匿名聚合健康统计，严格遵守隐私原则：
/// - 仅提供群体级别的聚合数据
/// - 绝不暴露任何个人用户信息
/// - 遵守《个人信息保护法》（PIPL）要求
library;

/// 企业信息
class EnterpriseInfo {
  final String companyId;
  final String companyName;
  final String programName;
  final DateTime enrollmentDate;
  final List<String> features;

  const EnterpriseInfo({
    required this.companyId,
    required this.companyName,
    required this.programName,
    required this.enrollmentDate,
    required this.features,
  });

  factory EnterpriseInfo.fromJson(Map<String, dynamic> json) {
    return EnterpriseInfo(
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String,
      programName: json['program_name'] as String,
      enrollmentDate: DateTime.parse(json['enrollment_date'] as String),
      features: List<String>.from(json['features'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'company_name': companyName,
        'program_name': programName,
        'enrollment_date': enrollmentDate.toIso8601String(),
        'features': features,
      };
}

/// 企业健康指数（完全匿名化，仅聚合数据）
///
/// 所有数据均为群体级别的统计平均，不包含任何个人可识别信息。
class EnterpriseHealthIndex {
  /// 综合健康评分（0-100），群体平均值
  final double overallScore;

  /// 参与总人数
  final int totalParticipants;

  /// 活跃用户数（近7天有签到）
  final int activeUsers;

  /// 平均连续打卡天数
  final double averageStreakDays;

  /// 戒断成功率（坚持超过30天的用户占比）
  final double quitSuccessRate;

  /// 各维度得分（'streak' 连续打卡, 'exercise' 运动完成, 'craving' 渴望管理, 'mood' 情绪稳定）
  /// 所有分数均为群体聚合值
  final Map<String, double> dimensionScores;

  const EnterpriseHealthIndex({
    required this.overallScore,
    required this.totalParticipants,
    required this.activeUsers,
    required this.averageStreakDays,
    required this.quitSuccessRate,
    required this.dimensionScores,
  });

  factory EnterpriseHealthIndex.fromJson(Map<String, dynamic> json) {
    return EnterpriseHealthIndex(
      overallScore: (json['overall_score'] as num).toDouble(),
      totalParticipants: json['total_participants'] as int,
      activeUsers: json['active_users'] as int,
      averageStreakDays: (json['average_streak_days'] as num).toDouble(),
      quitSuccessRate: (json['quit_success_rate'] as num).toDouble(),
      dimensionScores: Map<String, double>.from(
        (json['dimension_scores'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'overall_score': overallScore,
        'total_participants': totalParticipants,
        'active_users': activeUsers,
        'average_streak_days': averageStreakDays,
        'quit_success_rate': quitSuccessRate,
        'dimension_scores': dimensionScores,
      };
}

/// 企业级统计数据（完全匿名化）
class EnterpriseStats {
  /// 总签到次数（群体汇总）
  final int totalCheckins;

  /// 总运动完成次数（群体汇总）
  final int totalExercises;

  /// SOS紧急求助使用总次数（群体汇总）
  final int totalSosUsed;

  /// 里程碑分布：{天数里程碑: 达到该里程碑的人数}
  /// 例如 {7: 45, 30: 28, 90: 12}
  final Map<int, int> milestoneDistribution;

  const EnterpriseStats({
    required this.totalCheckins,
    required this.totalExercises,
    required this.totalSosUsed,
    required this.milestoneDistribution,
  });

  factory EnterpriseStats.fromJson(Map<String, dynamic> json) {
    return EnterpriseStats(
      totalCheckins: json['total_checkins'] as int,
      totalExercises: json['total_exercises'] as int,
      totalSosUsed: json['total_sos_used'] as int,
      milestoneDistribution: Map<int, int>.from(
        (json['milestone_distribution'] as Map).map(
          (k, v) => MapEntry(k as int, v as int),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_checkins': totalCheckins,
        'total_exercises': totalExercises,
        'total_sos_used': totalSosUsed,
        'milestone_distribution': milestoneDistribution,
      };
}

/// 企业EAP服务接口
///
/// 定义企业版许可模式下的所有功能接口。
/// 所有数据输出严格为匿名聚合级别。
abstract class EapService {
  /// 检查当前用户是否在企业许可证下
  Future<bool> isEnterpriseUser();

  /// 获取企业信息（公司名称、项目详情）
  ///
  /// 非企业用户返回 null。
  Future<EnterpriseInfo?> getEnterpriseInfo();

  /// 生成企业级健康指数（完全匿名化）
  ///
  /// 返回的数据仅包含群体聚合统计，不包含任何个人数据。
  /// 非企业用户返回空的默认值。
  Future<EnterpriseHealthIndex> generateHealthIndex();

  /// 获取企业统计数据（完全匿名化）
  ///
  /// 非企业用户返回空的默认值。
  Future<EnterpriseStats> getEnterpriseStats();
}

/// 本地实现（无实际服务器连接）
///
/// 当前为纯本地占位实现，所有企业功能均返回默认值。
/// 未来可替换为真实的企业API客户端实现。
class LocalEapService implements EapService {
  /// 本地实现始终返回 false（非企业用户）
  @override
  Future<bool> isEnterpriseUser() async {
    return false;
  }

  /// 本地实现始终返回 null（无企业信息）
  @override
  Future<EnterpriseInfo?> getEnterpriseInfo() async {
    return null;
  }

  /// 本地实现返回空的健康指数
  @override
  Future<EnterpriseHealthIndex> generateHealthIndex() async {
    return const EnterpriseHealthIndex(
      overallScore: 0.0,
      totalParticipants: 0,
      activeUsers: 0,
      averageStreakDays: 0.0,
      quitSuccessRate: 0.0,
      dimensionScores: {
        'streak': 0.0,
        'exercise': 0.0,
        'craving': 0.0,
        'mood': 0.0,
      },
    );
  }

  /// 本地实现返回空的统计数据
  @override
  Future<EnterpriseStats> getEnterpriseStats() async {
    return const EnterpriseStats(
      totalCheckins: 0,
      totalExercises: 0,
      totalSosUsed: 0,
      milestoneDistribution: {},
    );
  }
}