/// Health milestone card — displays a single body-recovery milestone
/// with organ-specific icon, title, description, and a circular percentage
/// indicator showing recovery progress.
///
/// Extracted from `dashboard_screen.dart`'s milestone timeline section.
/// Designed for use in both the dashboard horizontal timeline and a
/// vertical detail list on the profile / analysis screen.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entity/user.dart';

/// A card widget showing one [HealthMilestone] with recovery progress.
///
/// Supports two visual states controlled by [isAchieved]:
/// - **Achieved** (`true`): green border accent, filled progress ring,
///   checkmark overlay badge.
/// - **Not achieved** (`false`): muted palette, outline ring, dimmed text.
///
/// Example:
/// ```dart
/// HealthMilestoneCard(
///   milestone: myMilestone,
///   isAchieved: myMilestone.achieved,
///   onTap: () => showMilestoneDetail(context, myMilestone),
/// )
/// ```
class HealthMilestoneCard extends StatelessWidget {
  /// The milestone data to display.
  final HealthMilestone milestone;

  /// Whether the milestone has been achieved by the user.
  /// When `true`, the card renders with a green accent and checkmark.
  final bool isAchieved;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  /// Force a compact layout for horizontal timeline strips.
  final bool compact;

  const HealthMilestoneCard({
    super.key,
    required this.milestone,
    this.isAchieved = false,
    this.onTap,
    this.compact = false,
  });

  // ── Organ → icon map ─────────────────────────────────────────────────────
  static const Map<String, IconData> _organIcons = {
    '心血管': Icons.favorite_rounded,
    '肺部': Icons.air,
    '血液': Icons.water_drop_rounded,
    '感官': Icons.visibility_rounded,
    '呼吸': Icons.air,
    '皮肤': Icons.face_rounded,
    '免疫': Icons.shield_rounded,
    '全身': Icons.eco_rounded,
  };

  /// Returns a theme-aware colour seed for the organ type.
  static String _organColorKey(String organ) => switch (organ) {
        '心血管' => 'error',
        '血液' => 'error',
        '感官' => 'secondary',
        '呼吸' => 'tertiary',
        '肺部' => 'tertiary',
        '皮肤' => 'primary',
        '免疫' => 'primary',
        '全身' => 'primary',
        _ => 'primary',
      };

  Color _organColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (_organColorKey(milestone.organ)) {
      'primary' => cs.primary,
      'secondary' => cs.secondary,
      'tertiary' => cs.tertiary,
      'error' => cs.error,
      _ => cs.primary,
    };
  }

  Color _achievedColor(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    final colorScheme = Theme.of(context).colorScheme;
    return appColors?.successColor ?? colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = Theme.of(context).extension<AppSpacing>();
    final achieved = isAchieved;
    final icon = _organIcons[milestone.organ] ?? Icons.healing_rounded;
    final organColor = _organColor(context);
    final successColor = _achievedColor(context);

    if (compact) {
      return _buildCompact(
          colorScheme, spacing, achieved, icon, organColor, successColor);
    }

    return _buildFull(
        colorScheme, spacing, achieved, icon, organColor, successColor);
  }

  // ── Compact variant (horizontal timeline dots) ─────────────────────────
  Widget _buildCompact(
    ColorScheme colorScheme,
    AppSpacing? spacing,
    bool achieved,
    IconData icon,
    Color organColor,
    Color successColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress ring
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circular indicator
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: (milestone.percentageRecovered / 100).clamp(0.0, 1.0),
                    strokeWidth: 3,
                    backgroundColor: achieved
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      achieved
                          ? successColor
                          : organColor.withOpacity(0.5),
                    ),
                  ),
                ),
                // Centre icon
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: achieved
                        ? successColor.withOpacity(0.15)
                        : colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: achieved
                        ? successColor
                        : organColor.withOpacity(0.6),
                  ),
                ),
                // Checkmark overlay when achieved
                if (achieved)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: successColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Title
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 72),
            child: Text(
              milestone.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: achieved ? FontWeight.w600 : FontWeight.normal,
                color: achieved
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          // Days-since-quit label
          Text(
            '${milestone.daysSinceQuit}天',
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Full card variant (vertical list) ─────────────────────────────────
  Widget _buildFull(
    ColorScheme colorScheme,
    AppSpacing? spacing,
    bool achieved,
    IconData icon,
    Color organColor,
    Color successColor,
  ) {
    final r = spacing?.cardRadius ?? 16;
    final p = spacing?.cardPadding ?? 20;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(p),
        decoration: BoxDecoration(
          color: achieved
              ? successColor.withOpacity(0.06)
              : colorScheme.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(r),
          // Green border when achieved
          border: achieved
              ? Border.all(color: successColor.withOpacity(0.25))
              : null,
        ),
        child: Row(
          children: [
            // Circular percentage indicator with organ icon
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: (milestone.percentageRecovered / 100)
                          .clamp(0.0, 1.0),
                      strokeWidth: 4,
                      backgroundColor: achieved
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        achieved
                            ? successColor
                            : organColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: achieved
                          ? successColor.withOpacity(0.15)
                          : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: achieved
                          ? successColor
                          : organColor.withOpacity(0.7),
                    ),
                  ),
                  // Checkmark overlay
                  if (achieved)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: successColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: spacing?.md ?? 16),
            // Text content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          milestone.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: achieved
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (achieved) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded,
                            size: 16, color: successColor),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    milestone.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Organ pill + percentage
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: organColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                              spacing?.chipRadius ?? 20),
                        ),
                        child: Text(
                          milestone.organ,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: organColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${milestone.percentageRecovered.toInt()}% 已恢复',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
