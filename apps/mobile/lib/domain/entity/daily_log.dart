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

  /// v6.1: 觉察日记标记。当为 true 时，此记录来自觉察日记而非传统打卡。
  /// 觉察日记不要求用户"没有使用"，允许诚实记录。
  final bool isAwarenessLog;

  /// v6.1: 觉察日记类型——consumption(记录使用)|emotion(记录情绪)|trigger(记录触发)|free(自由记录)
  final String? awarenessType;

  /// v6.1: 觉察日记的原始用户输入文本（核心内容）
  final String? rawInput;

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
    this.isAwarenessLog = false,
    this.awarenessType,
    this.rawInput,
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
    bool? isAwarenessLog,
    String? awarenessType,
    String? rawInput,
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
      isAwarenessLog: isAwarenessLog ?? this.isAwarenessLog,
      awarenessType: awarenessType ?? this.awarenessType,
      rawInput: rawInput ?? this.rawInput,
    );
  }
}
