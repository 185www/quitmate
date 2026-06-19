class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final int targetDays; // e.g., 7 for a weekly challenge
  final int progressDays; // How many days completed
  final DateTime startDate;
  final DateTime? completedDate;
  final bool isActive;
  final int xpReward;
  final String emoji;

  const WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDays,
    this.progressDays = 0,
    required this.startDate,
    this.completedDate,
    this.isActive = true,
    this.xpReward = 100,
    this.emoji = '🏆',
  });

  double get progress => targetDays > 0 ? progressDays / targetDays : 0;
  bool get isCompleted => progressDays >= targetDays;
}
