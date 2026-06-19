/// Streak display — shows the current check-in streak with a large number,
/// level title / emoji, longest-record pill, and fire icon visual.
///
/// Extracted from `dashboard_screen.dart`'s level bar and quick-stats row.
/// Can be used standalone on the dashboard or within the game-profile screen.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entity/game_profile.dart';
import '../../../domain/entity/user.dart';

/// A prominent widget displaying the user's check-in streak with visual flair.
///
/// Combines the streak counter, longest-record indicator, and the current
/// [GameProfile.levelTitle] / [GameProfile.levelEmoji] into a single
/// cohesive card.
///
/// Example:
/// ```dart
/// StreakDisplay(
///   profile: myGameProfile,
///   user: myUser,
///   onTap: () => context.push('/profile/game-profile'),
/// )
/// ```
class StreakDisplay extends StatelessWidget {
  /// The game profile containing streak data and level info.
  final GameProfile profile;

  /// The user entity (used for days-since-quit context).
  final User user;

  /// Optional callback when the widget is tapped.
  final VoidCallback? onTap;

  /// Visual layout variant.
  final StreakDisplayStyle style;

  const StreakDisplay({
    super.key,
    required this.profile,
    required this.user,
    this.onTap,
    this.style = StreakDisplayStyle.card,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final spacing = Theme.of(context).extension<AppSpacing>();

    return switch (style) {
      StreakDisplayStyle.card => _buildCard(context, colorScheme, spacing,
          appColors),
      StreakDisplayStyle.inline =>
        _buildInline(context, colorScheme, spacing),
    };
  }

  // ── Card variant (dashboard featured block) ───────────────────────────
  Widget _buildCard(
    BuildContext context,
    ColorScheme colorScheme,
    AppSpacing? spacing,
    AppColors? appColors,
  ) {
    final streakDays = profile.streakDays;
    final longestStreak = profile.longestStreak;
    final isActive = profile.isStreakActive;
    final r = spacing?.cardRadius ?? 16;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r),
          side: isActive
              ? BorderSide(
                  color: (appColors?.successColor ?? colorScheme.primary)
                      .withOpacity(0.15),
                  width: 1,
                )
              : BorderSide.none,
        ),
        color: isActive
            ? colorScheme.tertiary.withOpacity(0.06)
            : colorScheme.surfaceContainerHighest.withOpacity(0.45),
        child: Padding(
          padding: EdgeInsets.all(spacing?.cardPadding ?? 20),
          child: Column(
            children: [
              // Header row: level emoji + title
              Row(
                children: [
                  Text(
                    '${profile.levelEmoji} ${profile.levelTitle}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  // Streak-active indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (appColors?.successColor ?? colorScheme.primary)
                              .withOpacity(0.12)
                          : colorScheme.surfaceContainerHighest
                              .withOpacity(0.6),
                      borderRadius: BorderRadius.circular(
                          spacing?.chipRadius ?? 20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? (appColors?.successColor ??
                                    colorScheme.primary)
                                : colorScheme.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? '连续中' : '已中断',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? (appColors?.successColor ??
                                    colorScheme.primary)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing?.md ?? 16),
              // Large streak number with fire icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Fire icon (static for now)
                  Text(
                    streakDays > 0
                        ? (streakDays >= 30
                            ? '🔥'
                            : streakDays >= 7
                                ? '🔥'
                                : streakDays >= 3
                                    ? '🔥'
                                    : '✨')
                        : '💤',
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 8),
                  // Big number
                  Text(
                    '$streakDays',
                    style:
                        Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 40,
                              height: 1.1,
                              color: colorScheme.onSurface,
                            ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '天连续签到',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing?.sm ?? 12),
              // Stats row: 连续 | 最长: {longestStreak}天
              Row(
                children: [
                  _miniStat(
                    Icons.emoji_events_rounded,
                    '最长记录',
                    '$longestStreak 天',
                    colorScheme,
                  ),
                  const SizedBox(width: 16),
                  _miniStat(
                    Icons.calendar_today_rounded,
                    '累计签到',
                    '${profile.checkinTotal} 次',
                    colorScheme,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Inline variant (compact pill for headers) ─────────────────────────
  Widget _buildInline(
    BuildContext context,
    ColorScheme colorScheme,
    AppSpacing? spacing,
  ) {
    if (profile.streakDays <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.7),
          borderRadius:
              BorderRadius.circular(spacing?.chipRadius ?? 20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 2),
            Text(
              '${profile.streakDays}天',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mini stat row item ────────────────────────────────────────────────
  Widget _miniStat(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Visual layout options for [StreakDisplay].
enum StreakDisplayStyle {
  /// Full card with large streak number and supporting stats.
  card,

  /// Compact inline pill showing streak days with fire emoji.
  inline,
}
