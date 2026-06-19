class DailyLogEntry {
  final int? id;
  final int userId;
  final DateTime date;
  final int mood; // 1-5
  final int? urgeLevel; // 0-10
  final List<String>? triggers;
  final String? coping;
  final bool relapsed;
  final int? consumption;
  final String? notes;

  const DailyLogEntry({
    this.id,
    required this.userId,
    required this.date,
    this.mood = 3,
    this.urgeLevel,
    this.triggers,
    this.coping,
    this.relapsed = false,
    this.consumption,
    this.notes,
  });

  DailyLogEntry copyWith({
    int? id,
    int? userId,
    DateTime? date,
    int? mood,
    int? urgeLevel,
    List<String>? triggers,
    String? coping,
    bool? relapsed,
    int? consumption,
    String? notes,
  }) {
    return DailyLogEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      urgeLevel: urgeLevel ?? this.urgeLevel,
      triggers: triggers ?? this.triggers,
      coping: coping ?? this.coping,
      relapsed: relapsed ?? this.relapsed,
      consumption: consumption ?? this.consumption,
      notes: notes ?? this.notes,
    );
  }
}
