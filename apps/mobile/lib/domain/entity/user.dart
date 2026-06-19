enum TargetType { smoking, alcohol, both }
enum UserStage { preContemplation, contemplation, preparation, action, maintenance }

class User {
  final int id;
  final TargetType targetType;
  final DateTime? quitDate;
  final UserStage stage;
  final int? fagerstromScore;
  final int? auditScore;
  final double? dailyConsumption;
  final int? yearsOfUse;
  final double? dailyCostAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.targetType,
    this.quitDate,
    required this.stage,
    this.fagerstromScore,
    this.auditScore,
    this.dailyConsumption,
    this.yearsOfUse,
    this.dailyCostAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  int get daysSinceQuit {
    if (quitDate == null) return 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).difference(DateTime(quitDate!.year, quitDate!.month, quitDate!.day)).inDays;
  }

  bool get hasQuitDate => quitDate != null;
  bool get isReadyForAction => stage == UserStage.preparation || stage == UserStage.action;
  bool get isReadyForMaintenance => stage == UserStage.maintenance;

  /// Estimated cigarettes per day from FTND score
  int get estimatedDailyCigarettes {
    if (targetType == TargetType.alcohol) return 0;
    if (fagerstromScore == null) return 10;
    return (fagerstromScore! * 2).clamp(1, 60);
  }

  /// Estimated standard drinks per day from AUDIT score
  int get estimatedDailyDrinks {
    if (targetType == TargetType.smoking) return 0;
    if (auditScore == null) return 2;
    return (auditScore! ~/ 4).clamp(0, 20);
  }

  /// Money saved per day (based on avg price)
  double get dailyCost {
    if (dailyCostAmount != null && dailyCostAmount! > 0) return dailyCostAmount!;
    if (dailyConsumption != null && dailyConsumption! > 0) {
      final costPerUnit = targetType == TargetType.alcohol ? 15.0 : 0.5;
      return dailyConsumption! * costPerUnit;
    }
    double cost = 0;
    if (targetType != TargetType.alcohol) cost += estimatedDailyCigarettes * 0.5;
    if (targetType != TargetType.smoking) cost += estimatedDailyDrinks * 15.0;
    return cost;
  }

  /// Years of life regained per day (statistical)
  double get dailyLifeRegainedMinutes => (targetType == TargetType.alcohol ? 11 : 0) + (targetType == TargetType.smoking ? 11 : 0);

  User copyWith({int? id, TargetType? targetType, DateTime? quitDate, UserStage? stage, int? fagerstromScore, int? auditScore, double? dailyConsumption, int? yearsOfUse, double? dailyCostAmount, DateTime? createdAt, DateTime? updatedAt}) {
    return User(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      quitDate: quitDate ?? this.quitDate,
      stage: stage ?? this.stage,
      fagerstromScore: fagerstromScore ?? this.fagerstromScore,
      auditScore: auditScore ?? this.auditScore,
      dailyConsumption: dailyConsumption ?? this.dailyConsumption,
      yearsOfUse: yearsOfUse ?? this.yearsOfUse,
      dailyCostAmount: dailyCostAmount ?? this.dailyCostAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Health milestone data from WHO/CDC/ACS
class HealthMilestone {
  final int id;
  final int daysSinceQuit;
  final String title;
  final String description;
  final String organ;
  final double percentageRecovered;
  final bool achieved;
  final DateTime? achievedDate;

  const HealthMilestone({
    required this.id,
    required this.daysSinceQuit,
    required this.title,
    required this.description,
    required this.organ,
    required this.percentageRecovered,
    this.achieved = false,
    this.achievedDate,
  });

  static const List<Map<String, dynamic>> milestones = [
    {'days': 0, 'title': '最后一次使用', 'desc': '身体开始自我修复', 'organ': '全身', 'pct': 0},
    {'days': 0, 'title': '心率和血压开始恢复正常', 'desc': '停止使用后20分钟，心率和血压开始下降', 'organ': '心血管', 'pct': 5},
    {'days': 1, 'title': '一氧化碳水平下降', 'desc': '血液中一氧化碳水平降至正常，氧气水平上升', 'organ': '血液', 'pct': 15},
    {'days': 2, 'title': '味觉和嗅觉改善', 'desc': '神经末梢开始再生，味觉和嗅觉逐渐恢复', 'organ': '感官', 'pct': 20},
    {'days': 3, 'title': '支气管开始放松', 'desc': '呼吸道开始放松，呼吸变得更加顺畅', 'organ': '呼吸', 'pct': 25},
    {'days': 7, 'title': '肺部清洁开始', 'desc': '肺部纤毛开始再生，清理黏液和焦油', 'organ': '肺部', 'pct': 35},
    {'days': 14, 'title': '循环系统改善', 'desc': '血液循环显著改善，行走变得更加轻松', 'organ': '心血管', 'pct': 45},
    {'days': 30, 'title': '皮肤状态改善', 'desc': '皮肤弹性恢复，肤色改善', 'organ': '皮肤', 'pct': 55},
    {'days': 60, 'title': '免疫系统恢复', 'desc': '免疫系统功能显著增强，抗感染能力提高', 'organ': '免疫', 'pct': 65},
    {'days': 90, 'title': '肺部功能显著改善', 'desc': '肺功能改善5-10%，呼吸更加顺畅', 'organ': '肺部', 'pct': 70},
    {'days': 180, 'title': '心脏病风险降低50%', 'desc': '与继续使用相比，心脏病风险降低一半', 'organ': '心血管', 'pct': 80},
    {'days': 365, 'title': '癌症风险减半', 'desc': '口腔、咽喉、食道癌风险降低50%', 'organ': '全身', 'pct': 90},
    {'days': 1825, 'title': '肺癌风险降低50%', 'desc': '5年后，肺癌风险降低至非使用者的一半', 'organ': '肺部', 'pct': 95},
    {'days': 3650, 'title': '心脏病风险与非使用者相同', 'desc': '10年后，心脏病风险与从未使用过的人相同', 'organ': '心血管', 'pct': 100},
  ];
}

class CravingEntry {
  final int? id;
  final int userId;
  final DateTime timestamp;
  final int intensity; // 1-10
  final String? trigger;
  final String? context;
  final String? copingUsed;
  final bool resolved;
  final String? location;
  final String? socialContext;
  final String? activity;

  const CravingEntry({
    this.id,
    required this.userId,
    required this.timestamp,
    required this.intensity,
    this.trigger,
    this.context,
    this.copingUsed,
    this.resolved = false,
    this.location,
    this.socialContext,
    this.activity,
  });

  CravingEntry copyWith({int? id, int? userId, DateTime? timestamp, int? intensity, String? trigger, String? context, String? copingUsed, bool? resolved, String? location, String? socialContext, String? activity}) {
    return CravingEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      intensity: intensity ?? this.intensity,
      trigger: trigger ?? this.trigger,
      context: context ?? this.context,
      copingUsed: copingUsed ?? this.copingUsed,
      resolved: resolved ?? this.resolved,
      location: location ?? this.location,
      socialContext: socialContext ?? this.socialContext,
      activity: activity ?? this.activity,
    );
  }
}
