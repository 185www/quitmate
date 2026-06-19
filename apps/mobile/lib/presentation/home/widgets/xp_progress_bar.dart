/// XP progress bar — shows the user's game level, XP progress towards
/// the next level, and the current XP / next-level threshold.
///
/// Extracted from `dashboard_screen.dart`'s `_buildLevelBar` section.
/// Pure widget — all data comes from the [GameProfile] parameter.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entity/game_profile.dart';

/// A card displaying XP progress for the user's current level.
///
/// Shows:
/// - A header with the level badge ("Lv.{level}") and level title.
/// - A linear progress bar reflecting [GameProfile.levelProgress].
/// - An XP label showing "{xp}/{xpToNextLevel} XP".
///
/// Example:
/// ```dart
/// XpProgressBar(
///   profile: myGameProfile,
///   onTap: () => context.push('/profile/game-profile'),
/// )
/// ```
class XpProgressBar extends StatelessWidget {
  /// The game profile containing level, XP, and progress data.
  final GameProfile profile;

  /// Optional callback when the bar is tapped (e.g. to navigate to
  /// the full game-profile screen).
  final VoidCallback? onTap;

  const XpProgressBar({
    super.key,
    required this.profile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = Theme.of(context).extension<AppSpacing>();
    final r = spacing?.cardRadius ?? 16;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing?.cardPadding ?? 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: level badge + title
              Row(
                children: [
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.tertiary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Lv.${profile.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Level title + emoji
                  Text(
                    '${profile.levelEmoji} ${profile.levelTitle}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  // XP label
                  Text(
                    '${profile.xp}/${profile.xpToNextLevel} XP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),

              SizedBox(height: spacing?.sm ?? 12),

              // Linear progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: profile.levelProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              ),

              SizedBox(height: spacing?.xxs ?? 4),

              // Progress percentage
              Text(
                '距离下一级还差 ${profile.xpToNextLevel - profile.xp} XP',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
