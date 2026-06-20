import 'dart:convert';
import 'dart:math';
import '../../domain/entity/analysis.dart';

/// Static utility methods used across the analysis modules.
///
/// Pure functions with no side effects — safe to use from any class.
class AnalysisUtils {
  AnalysisUtils._();

  /// Returns the 1-based day-of-year for [date].
  static int dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  /// Returns the ISO week number of the current date.
  static int currentWeekNumber() {
    final now = DateTime.now();
    final doy = dayOfYear(now);
    return ((doy - now.weekday + 10) ~/ 7);
  }

  /// Parses a raw string that may be wrapped in markdown code blocks
  /// into a `Map<String, dynamic>`. Returns an empty map on failure.
  static Map<String, dynamic> parseJsonSafely(String raw) {
    try {
      var content = raw.trim();
      if (content.startsWith('```')) {
        content = content
            .replaceFirst(RegExp(r'^```\w*\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '');
      }
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Parses a raw string that may be wrapped in markdown code blocks
  /// into a `List<dynamic>`. Returns an empty list on failure.
  static List<dynamic> parseJsonArraySafely(String raw) {
    try {
      var content = raw.trim();
      if (content.startsWith('```')) {
        content = content
            .replaceFirst(RegExp(r'^```\w*\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '');
      }
      final parsed = jsonDecode(content);
      if (parsed is List) return parsed;
      return <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  /// Maps a string label from LLM output to an [InsightType] enum value.
  static InsightType parseInsightType(String? type) {
    switch (type) {
      case 'motivational':
        return InsightType.motivational;
      case 'warning':
        return InsightType.warning;
      case 'achievement':
        return InsightType.achievement;
      case 'critical':
        return InsightType.critical;
      default:
        return InsightType.neutral;
    }
  }

  /// Returns a random motivational quote from the built-in collection.
  static String randomMotivationalQuote() {
    const quotes = [
      '每一次坚持，都是对未来自己的投资。',
      '戒断不是失去什么，而是找回什么。',
      '你比你想象的更强大。',
      '困难是暂时的，进步是永久的。',
      '每一次说"不"，你都在重新定义自己。',
      '不是因为没有渴望才成功，而是因为成功了才没有渴望。',
      '最暗的夜之后，一定是最亮的晨。',
      '你今天的选择，决定了明天的自由。',
      '每一步都算数，即使有时看不到进步。',
      '你不是在放弃一个习惯，你是在赢得一种自由。',
    ];
    return quotes[Random().nextInt(quotes.length)];
  }
}
