enum TargetType { smoking, alcohol, both }

enum UserStage {
  preContemplation,
  contemplation,
  preparation,
  action,
  maintenance,
}

class User {
  final int id;
  final TargetType targetType;
  final DateTime? quitDate;
  final UserStage stage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({required this.id, required this.targetType, this.quitDate, required this.stage, required this.createdAt, required this.updatedAt});

  int get daysSinceQuit {
    if (quitDate == null) return 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).difference(DateTime(quitDate!.year, quitDate!.month, quitDate!.day)).inDays;
  }

  bool get hasQuitDate => quitDate != null;
  bool get isReadyForAction => stage == UserStage.preparation || stage == UserStage.action;
  bool get isReadyForMaintenance => stage == UserStage.maintenance;

  User copyWith({int? id, TargetType? targetType, DateTime? quitDate, UserStage? stage, DateTime? createdAt, DateTime? updatedAt}) {
    return User(id: id ?? this.id, targetType: targetType ?? this.targetType, quitDate: quitDate ?? this.quitDate, stage: stage ?? this.stage, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt);
  }
}