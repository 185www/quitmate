/// Craving summary card — shows today's craving statistics with an
/// intensity bar, top trigger chip, and a positive message when no
/// cravings are recorded.
///
/// Extracted from `dashboard_screen.dart`. Pure widget — all data is
/// passed in via parameters, making it easily testable and reusable.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A card summarising today's craving activity.
///
/// Displays:
/// - When [cravingCount] is 0: a positive "今日暂无渴望" message.
/// - When [cravingCount] > 0: the count, an average intensity bar,
///   and the most common trigger chip (if [topTrigger] is provided).
///
/// Example:
/// ```dart
/// CravingSummaryCard(
///   cravingCount: 3,
///   avgIntensity: 5.7,
///   topTrigger: '社交压力',
///   onLogCraving: () => context.push('/action/urge-toolkit'),
/// )
/// ```
class CravingSummaryCard extends StatelessWidget {
  /// Number of cravings logged today.
  final int cravingCount;

  /// Average intensity across today's cravings (0.0–10.0 scale).
  final double avgIntensity;

  /// The most common trigger string, or `null` if no data.
  final String? topTrigger;

  /// Optional callback when the card is tapped or action button is pressed.
  final VoidCallback? onLogCraving;

  const CravingSummaryCard({
    super.key,
    required this.cravingCount,
    required this.avgIntensity,
    this.topTrigger,
    this.onLogCraving,
  });

  // ── Intensity label helper ────────────────────────────────────────────
  String _intensityLabel(double intensity) {
    if (intensity <= 0) return '无渴望';
    if (intensity <= 3) return '轻微';
    if (intensity <= 6) return '中等';
    return '强烈';
  }

  /// Returns a theme-aware colour based on intensity level.
  Color _intensityColor(BuildContext context, double intensity) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    if (intensity <= 3) return colorScheme.primary;
    if (intensity <= 6) return appColors?.warningColor ?? colorScheme.tertiary;
    return appColors?.dangerColor ?? colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final spacing = Theme.of(context).extension<AppSpacing>();
    final r = spacing?.cardRadius ?? 16;
    final p = spacing?.cardPadding ?? 20;
    final hasCravings = cravingCount > 0;

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
            // Header row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (hasCravings
                            ? _intensityColor(context, avgIntensity)
                            : (appColors?.successColor ??
                                colorScheme.primary))
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(
                        spacing?.iconRadius ?? 10),
                  ),
                  child: Icon(
                    hasCravings
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: hasCravings
                        ? _intensityColor(context, avgIntensity)
                        : (appColors?.successColor ??
                            colorScheme.primary),
                    size: 18,
                  ),
                ),
                SizedBox(width: spacing?.sm ?? 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日渴望',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasCravings
                            ? '共 $cravingCount 次 · 平均${_intensityLabel(avgIntensity)}'
                            : '今日暂无渴望',
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
              ],
            ),

            // ── Positive message when no cravings ─────────────────────────
            if (!hasCravings) ...[
              SizedBox(height: spacing?.sm ?? 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (appColors?.successColor ??
                          colorScheme.primary)
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(
                      spacing?.chipRadius ?? 12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      size: 16,
                      color: appColors?.successColor ??
                          colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '继续保持，你做得很棒！',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Intensity bar when cravings exist ────────────────────────
            if (hasCravings) ...[
              SizedBox(height: spacing?.sm ?? 12),
              // Average intensity bar
              Row(
                children: [
                  Text(
                    '平均强度',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (avgIntensity / 10).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor:
                            colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          _intensityColor(context, avgIntensity),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${avgIntensity.toStringAsFixed(1)}/10',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            // ── Top trigger chip ─────────────────────────────────────────
            if (topTrigger != null && topTrigger!.isNotEmpty) ...[
              SizedBox(height: spacing?.sm ?? 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(
                      spacing?.chipRadius ?? 20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '常见触发: $topTrigger',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Quick log button ─────────────────────────────────────────
            if (onLogCraving != null) ...[
              SizedBox(height: spacing?.sm ?? 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton.tonal(
                  onPressed: onLogCraving,
                  style: FilledButton.styleFrom(
                    backgroundColor: (appColors?.warningColor ??
                            colorScheme.tertiary)
                        .withOpacity(0.15),
                    foregroundColor: appColors?.warningColor ??
                        colorScheme.tertiary,
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
                  child: const Text('记录一次渴望'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
