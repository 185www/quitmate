import 'dart:math';

/// A message in the AI coaching conversation
class CoachMessage {
  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final String? category; // 'greeting', 'encouragement', 'tip', 'question', 'reflection'
  final List<String>? quickReplies;

  const CoachMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.category,
    this.quickReplies,
  });

  CoachMessage copyWith({
    String? id,
    bool? isUser,
    String? text,
    DateTime? timestamp,
    String? category,
    List<String>? quickReplies,
  }) {
    return CoachMessage(
      id: id ?? this.id,
      isUser: isUser ?? this.isUser,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      quickReplies: quickReplies ?? this.quickReplies,
    );
  }

  static String generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  }
}
