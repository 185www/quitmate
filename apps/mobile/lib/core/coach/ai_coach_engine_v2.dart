import 'dart:math';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/coach_message.dart';
import 'coach_response_templates.dart';

/// Config-driven AI Coach engine (v2).
///
/// All response text lives in [CoachResponseTemplates]. This engine is
/// responsible only for routing, condition evaluation, variable
/// interpolation, and category detection.
///
/// Public API is identical to the original [AiCoachEngine] so it can be
/// used as a drop-in replacement.
class AiCoachEngineV2 {
  // ── Public API ────────────────────────────────────────────────────────────

  /// Generate a contextual opening message based on user state.
  CoachMessage generateGreeting({
    User? user,
    GameProfile? gameProfile,
    DailyLogEntry? todayLog,
  }) {
    final text = _buildGreetingText(user, gameProfile, todayLog);
    return CoachMessage(
      id: CoachMessage.generateId(),
      isUser: false,
      text: text,
      timestamp: DateTime.now(),
      category: 'greeting',
      quickReplies: CoachResponseTemplates.initialQuickReplies,
    );
  }

  /// Generate a response to user input.
  CoachMessage generateResponse({
    required String userInput,
    User? user,
    GameProfile? gameProfile,
    DailyLogEntry? todayLog,
  }) {
    final text = _buildResponseText(userInput, user, gameProfile);
    final category = _categorizeResponse(text);
    final replies = _contextualQuickReplies(userInput);
    return CoachMessage(
      id: CoachMessage.generateId(),
      isUser: false,
      text: text,
      timestamp: DateTime.now(),
      category: category,
      quickReplies: replies,
    );
  }

  // ── Greeting Generation ──────────────────────────────────────────────────

  String _buildGreetingText(
      User? user, GameProfile? gameProfile, DailyLogEntry? todayLog) {
    final context = _buildInterpolationContext(user, gameProfile);

    // Evaluate greeting conditions in order; first match wins.
    for (final group in CoachResponseTemplates.greetings) {
      if (_matchesGreetingCondition(group.condition, user)) {
        return _interpolate(
          CoachResponseTemplates.randomFrom(group.responses),
          context,
        );
      }
    }

    // Fallback (should never reach here if templates cover all cases).
    return '你好！有什么我能帮你的吗？';
  }

  /// Map a greeting condition string to an actual runtime check.
  bool _matchesGreetingCondition(String? condition, User? user) {
    if (condition == null) return false;
    final days = user?.daysSinceQuit ?? 0;

    switch (condition) {
      case 'user_is_null':
        return user == null || !user.hasQuitDate;
      case 'days_since_quit == 0':
        return days == 0;
      case '1 <= days_since_quit <= 3':
        return days >= 1 && days <= 3;
      case '4 <= days_since_quit <= 7':
        return days >= 4 && days <= 7;
      case '8 <= days_since_quit <= 30':
        return days >= 8 && days <= 30;
      case '31 <= days_since_quit <= 90':
        return days >= 31 && days <= 90;
      case 'days_since_quit > 90':
        return days > 90;
      default:
        return false;
    }
  }

  // ── Response Generation ───────────────────────────────────────────────────

  String _buildResponseText(
      String userInput, User? user, GameProfile? gameProfile) {
    final input = userInput.toLowerCase();
    final days = user?.daysSinceQuit ?? 0;
    final context = _buildInterpolationContext(user, gameProfile);

    // Iterate topic handlers in definition order; first keyword match wins.
    for (final handler in CoachResponseTemplates.topicHandlers) {
      // Empty keywords → fallback handler (general), skip keyword check.
      if (handler.keywords.isNotEmpty &&
          !_containsAny(input, handler.keywords)) {
        continue;
      }

      // Determine which sub-group to use.
      final subGroupKey = _resolveSubGroupKey(handler, input, days, gameProfile);
      final subGroup = handler.responses[subGroupKey];
      if (subGroup == null) continue;

      final rawText = CoachResponseTemplates.randomFrom(subGroup.responses);
      return _interpolate(rawText, context);
    }

    // Ultimate fallback.
    return '你能多说说吗？';
  }

  /// Decide which sub-group key to use for a matched handler.
  ///
  /// Priority:
  ///  1. Sub-keyword matching (for handlers that define [subKeywords])
  ///  2. Contextual conditions (days-based, profile-based)
  ///  3. 'default'
  String _resolveSubGroupKey(
    CoachTopicHandler handler,
    String input,
    int days,
    GameProfile? profile,
  ) {
    // 1) Keyword-based sub-routing
    for (final entry in handler.subKeywords.entries) {
      if (_containsAny(input, entry.value)) return entry.key;
    }

    // 2) Contextual condition routing
    if (handler.responses.containsKey('early') && days <= 3) return 'early';
    if (handler.responses.containsKey('day_0') && days == 0) return 'day_0';
    if (handler.responses.containsKey('no_profile') && profile == null) {
      return 'no_profile';
    }

    // 3) Default
    return 'default';
  }

  // ── Quick Reply Generation ────────────────────────────────────────────────

  List<String> _contextualQuickReplies(String userInput) {
    final input = userInput.toLowerCase();

    // Try topic-based quick replies first (match via handler keywords).
    for (final handler in CoachResponseTemplates.topicHandlers) {
      if (handler.keywords.isNotEmpty && _containsAny(input, handler.keywords)) {
        final topicReplies =
            CoachResponseTemplates.quickRepliesByTopic[handler.id];
        if (topicReplies != null && topicReplies.isNotEmpty) {
          return topicReplies;
        }
      }
    }

    // Fallback: pick a random default set.
    final defaults = CoachResponseTemplates.defaultQuickReplies;
    return defaults[Random().nextInt(defaults.length)];
  }

  // ── Category Detection (unchanged from original) ─────────────────────────

  String _categorizeResponse(String response) {
    if (response.contains('渴望') && response.contains('消退')) return 'tip';
    if (response.contains('HALT')) return 'tip';
    if (response.contains('呼吸')) return 'tip';
    if (response.contains('方法') || response.contains('建议')) return 'tip';
    if (response.contains('?') || response.contains('？')) return 'question';
    if (response.contains('骄傲') || response.contains('棒'))
      return 'encouragement';
    if (response.contains('？')) return 'question';
    if (response.contains('进步') || response.contains('成功'))
      return 'encouragement';
    return 'reflection';
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  /// Build the interpolation context map from current user / profile state.
  Map<String, String> _buildInterpolationContext(
    User? user,
    GameProfile? gameProfile,
  ) {
    final days = user?.daysSinceQuit ?? 0;
    final streak = gameProfile?.streakDays ?? 0;
    final level = gameProfile?.levelTitle ?? '';
    final cravingsResisted = gameProfile?.cravingsResisted ?? 0;
    final longestStreak = gameProfile?.longestStreak ?? 0;
    final levelNum = gameProfile?.level ?? 1;

    return {
      'days': '$days',
      'streak': '$streak',
      'level': level,
      'level_num': '$levelNum',
      'cravings_resisted': '$cravingsResisted',
      'longest_streak': '$longestStreak',
      'time_greeting': _timeGreeting(),
    };
  }

  /// Replace `{placeholder}` tokens in [text] with values from [context].
  String _interpolate(String text, Map<String, String> context) {
    for (final entry in context.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }

  /// Time-of-day greeting (unchanged from original).
  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  /// Check whether [input] contains any of [keywords].
  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k));
  }
}
