// ═══════════════════════════════════════════════════════════════════════════════
// P1.2.4 — Stress Intervention Engine
//
// Pure Dart, zero dependencies, fully testable.
// Evaluates health snapshots + craving patterns to produce intervention
// suggestions that can be surfaced as local notifications or in-UI cards.
// ═══════════════════════════════════════════════════════════════════════════════

import 'health_data_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// InterventionSuggestion — output model
// ─────────────────────────────────────────────────────────────────────────────

/// A suggested intervention to help the user stay on track.
class InterventionSuggestion {
  final String title;
  final String body;
  final String type; // 'breathing' | 'relaxation' | 'sos' | 'positive'
  final int priority; // 1 (lowest) – 5 (highest)

  const InterventionSuggestion({
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterventionSuggestion &&
          title == other.title &&
          body == other.body &&
          type == other.type &&
          priority == other.priority;

  @override
  int get hashCode => Object.hash(title, body, type, priority);

  @override
  String toString() =>
      'InterventionSuggestion(type=$type, p=$priority, "$title")';
}

// ─────────────────────────────────────────────────────────────────────────────
// CravingPattern — lightweight input model
// ─────────────────────────────────────────────────────────────────────────────

/// Summarised craving data for the last N hours, fed into the engine.
class CravingPattern {
  /// Number of cravings logged in the look-back window.
  final int recentCount;

  /// Average intensity (1-10) of those cravings.
  final double avgIntensity;

  /// Whether any craving in the window was logged within the last hour.
  final bool hasVeryRecent;

  const CravingPattern({
    this.recentCount = 0,
    this.avgIntensity = 0,
    this.hasVeryRecent = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// StressInterventionEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Evaluates health data and craving patterns to produce actionable
/// intervention suggestions.
///
/// Usage:
/// ```dart
/// final engine = StressInterventionEngine();
/// final suggestions = engine.evaluate(
///   health: snapshot,
///   cravings: cravingPattern,
///   streakDays: 14,
/// );
/// ```
class StressInterventionEngine {
  // ── Thresholds (tweakable without touching widget code) ───────────────

  /// Stress level at or above which we suggest breathing exercises.
  static const int highStressThreshold = 7;

  /// Sleep hours below which we flag poor sleep.
  static const double poorSleepThreshold = 5.0;

  /// Sleep hours below which we consider it "very poor".
  static const double veryPoorSleepThreshold = 3.5;

  /// Streak days required for a "positive reinforcement" suggestion.
  static const int positiveReinforcementStreak = 7;

  /// Craving count in the look-back window that elevates risk.
  static const int elevatedCravingCount = 3;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Evaluate the current state and return a prioritised list of
  /// intervention suggestions (may be empty).
  ///
  /// [health] may be `null` if no data has been recorded yet.
  List<InterventionSuggestion> evaluate({
    required HealthSnapshot? health,
    CravingPattern? cravings,
    int streakDays = 0,
  }) {
    final suggestions = <InterventionSuggestion>[];

    if (health == null) return suggestions;

    // ── SOS: High stress + recent craving ──────────────────────────────
    if (health.isHighStress &&
        cravings != null &&
        cravings.hasVeryRecent) {
      suggestions.add(const InterventionSuggestion(
        title: '⚠️ 高压力 + 渴望来袭',
        body: '检测到高压和近期渴望，建议立即进行深呼吸练习，或使用SOS紧急求助。',
        type: 'sos',
        priority: 5,
      ));
    }

    // ── High stress → breathing exercise ───────────────────────────────
    if (health.isHighStress) {
      suggestions.add(InterventionSuggestion(
        title: '今天压力较大，试试呼吸放松',
        body: _breathingBody(health.stressLevel ?? 7),
        type: 'breathing',
        priority: 4,
      ));
    }

    // ── Very poor sleep → relaxation ───────────────────────────────────
    final sleep = health.sleepHours;
    if (sleep != null && sleep < veryPoorSleepThreshold) {
      suggestions.add(InterventionSuggestion(
        title: '昨晚严重睡眠不足',
        body: '仅睡了 ${sleep.toStringAsFixed(1)} 小时，今天请格外注意休息，避免高强度工作。低睡眠会增加复吸风险。',
        type: 'relaxation',
        priority: 4,
      ));
    } else if (health.isPoorSleep) {
      // ── Poor sleep → relaxation (less urgent) ───────────────────────
      suggestions.add(InterventionSuggestion(
        title: '昨晚睡眠不足，注意休息',
        body: '昨晚睡了 ${sleep!.toStringAsFixed(1)} 小时，低于推荐的 5 小时。建议今天减少刺激性活动，早点休息。',
        type: 'relaxation',
        priority: 3,
      ));
    }

    // ── Elevated cravings alone (no health flags) ──────────────────────
    if (cravings != null &&
        cravings.recentCount >= elevatedCravingCount &&
        !health.isHighStress &&
        !health.isPoorSleep) {
      suggestions.add(InterventionSuggestion(
        title: '近期渴望频率偏高',
        body: '过去几小时记录了 ${cravings.recentCount} 次渴望，试试分散注意力或进行一项放松活动。',
        type: 'breathing',
        priority: 2,
      ));
    }

    // ── Positive reinforcement: good streak + good health ──────────────
    if (streakDays >= positiveReinforcementStreak && health.isGoodState) {
      suggestions.add(InterventionSuggestion(
        title: '今天状态不错，继续保持！',
        body: '你已经坚持了 $streakDays 天，身心状态良好。每一天的坚持都在重塑你的大脑！',
        type: 'positive',
        priority: 1,
      ));
    }

    // Sort by descending priority
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    return suggestions;
  }

  // ── Private helpers ────────────────────────────────────────────────────

  String _breathingBody(int stressLevel) {
    if (stressLevel >= 9) {
      return '压力水平 $stressLevel/10，非常高。请立即停止手头工作，做3-5分钟4-7-8呼吸法。';
    }
    if (stressLevel >= 7) {
      return '压力水平 $stressLevel/10，建议做一组深呼吸练习来缓解紧张情绪。';
    }
    return '有些压力是正常的，试试简单的腹式呼吸让自己放松一下。';
  }
}