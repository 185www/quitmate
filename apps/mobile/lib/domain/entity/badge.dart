class AppBadge {
  final int? id;
  final String code;
  final String name;
  final String description;
  final String iconAsset;
  final DateTime? earnedAt;

  const AppBadge({
    this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.iconAsset,
    this.earnedAt,
  });

  bool get isEarned => earnedAt != null;

  AppBadge copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    String? iconAsset,
    DateTime? earnedAt,
  }) {
    return AppBadge(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }
}
