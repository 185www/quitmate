class DailyLogEntry {
  final int? id;
  final int userId;
  final DateTime date;
  final int? urgeLevel;
  final List<String>? triggers;
  final String? coping;
  final bool relapsed;
  final String? notes;

  const DailyLogEntry({
    this.id,
    required this.userId,
    required this.date,
    this.urgeLevel,
    this.triggers,
    this.coping,
    this.relapsed = false,
    this.notes,
  });

  DailyLogEntry copyWith({
    int? id,
    int? userId,
    DateTime? date,
    int? urgeLevel,
    List<String>? triggers,
    String? coping,
    bool? relapsed,
    String? notes,
  }) {
    return DailyLogEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      urgeLevel: urgeLevel ?? this.urgeLevel,
      triggers: triggers ?? this.triggers,
      coping: coping ?? this.coping,
      relapsed: relapsed ?? this.relapsed,
      notes: notes ?? this.notes,
    );
  }
}