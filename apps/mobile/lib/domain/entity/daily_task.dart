class DailyTask {
  final String id;
  final String title;
  final String description;
  final String type; // 'exercise', 'challenge', 'reflection', 'action'
  final int xpReward;
  final bool completed;
  final DateTime date;
  final String? relatedExerciseId;

  const DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.xpReward = 10,
    this.completed = false,
    required this.date,
    this.relatedExerciseId,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    int? xpReward,
    bool? completed,
    DateTime? date,
    String? relatedExerciseId,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      xpReward: xpReward ?? this.xpReward,
      completed: completed ?? this.completed,
      date: date ?? this.date,
      relatedExerciseId: relatedExerciseId ?? this.relatedExerciseId,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'exercise':
        return '练习';
      case 'challenge':
        return '挑战';
      case 'reflection':
        return '反思';
      case 'action':
        return '行动';
      default:
        return type;
    }
  }
}