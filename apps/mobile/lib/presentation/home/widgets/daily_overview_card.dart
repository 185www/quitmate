/// Daily overview card — shows today's daily log with mood emoji indicators,
/// urge level bar, and relapse warning badge. When no log exists for today,
/// prompts the user to create one.
///
/// Extracted from `dashboard_screen.dart`'s check-in section.
/// Pure widget — data is passed in via parameters.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entity/daily_log.dart';

/// A card showing today's daily log overview at a glance.
///
/// Displays:
/// - Five mood emoji indicators (mood 1 → 😢, 2 → 😕, 3 → 😐, 4 → 🙂, 5 → 😊)
///   with the active mood highlighted.
/// - An urge level bar on a 0–10 scale.
/// - A warning badge if the user relapsed.
/// - A prompt to create a log when [todayLog] is `null`.
///
/// Example:
/// ```dart
/// DailyOverviewCard(
///   todayLog: myDailyLog,
///   onCreateLog: () => context.push('/action/daily-log'),
/// )
/// ```
class DailyOverviewCard extends StatelessWidget {
  /// Today's daily log entry, or `null` if the user hasn't logged yet.
  final DailyLogEntry? todayLog;

  /// Optional callback to create or edit today's log.
  final VoidCallback? onCreateLog;

  const DailyOverviewCard({
    super.key,
    this.todayLog,
    this.onCreateLog,
  });

  // ── Mood → emoji mapping ─────────────────────────────────────────────
  /// Returns the emoji corresponding to a mood value (1–5).
  ///
  /// Mapping: 1→😢, 2→😕, 3→😐, 4→🙂, 5→😊
  static String moodEmoji(int mood) {
    return switch (mood.clamp(1, 5)) {
      1 => '😢',
      2 => '😕',
      3 => '😐',
      4 => '🙂',
      5 => '😊',
      _ => '😐',
    };
  }

  /// Returns a theme-aware colour for the urge level.
  Color _urgeColor(BuildContext context, int urgeLevel) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    if (urgeLevel <= 2) return appColors?.successColor ?? colorScheme.primary;
    if (urgeLevel <= 5) return appColors?.warningColor ?? colorScheme.tertiary;
    return appColors?.dangerColor ?? colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final spacing = Theme.of(context).extension<AppSpacing>();
    final r = spacing?.cardRadius ?? 16;
    final p = spacing?.cardPadding ?? 20;

    final log = todayLog;
    final hasLog = log != null;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r),
      ),
      child: Padding(
        padding: EdgeInsets.all(p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasLog
                        ? colorScheme.primaryContainer.withOpacity(0.6)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                        spacing?.iconRadius ?? 10),
                  ),
                  child: Icon(
                    hasLog
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                    color: hasLog
                        ? (appColors?.successColor ?? colorScheme.primary)
                        : colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                SizedBox(width: spacing?.sm ?? 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLog ? '今日记录' : '今日未记录',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasLog
                            ? '情绪和渴望水平一览'
                            : '记录今天的状态，追踪你的恢复进度',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                // Relapse warning badge
                if (hasLog && log.relapsed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (appColors?.dangerColor ??
                              colorScheme.error)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                          spacing?.chipRadius ?? 20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 12,
                            color: appColors?.dangerColor ??
                                colorScheme.error),
                        const SizedBox(width: 4),
                        Text(
                          '复发',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: appColors?.dangerColor ??
                                colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // ── Prompt to create log ─────────────────────────────────────
            if (!hasLog) ...[
              SizedBox(height: spacing?.md ?? 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton.tonal(
                  onPressed: onCreateLog,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        colorScheme.primary.withOpacity(0.1),
                    foregroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          spacing?.buttonRadius ?? 12),
                    ),
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('开始今日记录'),
                ),
              ),
            ],

            // ── Mood emoji indicators ────────────────────────────────────
            if (hasLog) ...[
              SizedBox(height: spacing?.md ?? 16),
              Text(
                '心情',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final moodValue = index + 1;
                  final isActive = log.mood == moodValue;
                  return Expanded(
                    child: GestureDetector(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primaryContainer
                                  .withOpacity(0.8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                              spacing?.chipRadius ?? 12),
                          border: isActive
                              ? Border.all(
                                  color: colorScheme.primary
                                      .withOpacity(0.3),
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            moodEmoji(moodValue),
                            style: TextStyle(
                              fontSize: isActive ? 22 : 18,
                              color: isActive
                                  ? null
                                  : colorScheme.onSurfaceVariant
                                      .withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              // Mood label
              Center(
                child: Text(
                  moodEmoji(log.mood),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // ── Urge level bar ─────────────────────────────────────────
              SizedBox(height: spacing?.sm ?? 12),
              Row(
                children: [
                  Text(
                    '渴望程度',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ((log.urgeLevel ?? 0) / 10)
                            .clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor:
                            colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          _urgeColor(
                              context, log.urgeLevel ?? 0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${log.urgeLevel ?? 0}/10',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
