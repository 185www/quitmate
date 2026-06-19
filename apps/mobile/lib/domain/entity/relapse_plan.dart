class RelapsePlanItem {
  final int? id;
  final int userId;
  final String situation;
  final String? trigger;
  final String copingPlan;
  final int priority;
  final bool isTemplate;
  final String? category; // social, stress, habitual, emotional

  const RelapsePlanItem({
    this.id,
    required this.userId,
    required this.situation,
    this.trigger,
    required this.copingPlan,
    this.priority = 0,
    this.isTemplate = false,
    this.category,
  });

  RelapsePlanItem copyWith({
    int? id,
    int? userId,
    String? situation,
    String? trigger,
    String? copingPlan,
    int? priority,
    bool? isTemplate,
    String? category,
  }) {
    return RelapsePlanItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      situation: situation ?? this.situation,
      trigger: trigger ?? this.trigger,
      copingPlan: copingPlan ?? this.copingPlan,
      priority: priority ?? this.priority,
      isTemplate: isTemplate ?? this.isTemplate,
      category: category ?? this.category,
    );
  }
}
