/// Weekly Achievement Card — 每周生成个人成就海报
///
/// A shareable card summarizing the user's weekly accomplishments: streak,
/// cravings resisted, money saved, exercises completed, and level progress.
///
/// Features:
/// - Staggered reveal animation on appearance
/// - Gradient background for visual appeal
/// - Share button (placeholder using [Icons.share])
/// - Motivational encouragement text

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Encouragement quotes pool
// ─────────────────────────────────────────────────────────────────────────────

const _kEncouragements = [
  '每一天的坚持，都是对自己最好的投资',
  '你已经比昨天的自己更强大了',
  '戒烟路上，你从不孤单',
  '坚持的力量，正在改变你的身体',
  '健康是最宝贵的财富，你正在守护它',
  '每一个不碰烟酒的日子，都是胜利',
  '你的身体正在悄悄感谢你',
  '自律即自由，你正在走向自由',
  '本周的你，值得所有的掌声',
  '一步一个脚印，你已经走了很远',
];

/// Picks a deterministic quote based on the week start date.
String _pickEncouragement(String weekStartDate) {
  final hash = weekStartDate.hashCode;
  return _kEncouragements[hash.abs() % _kEncouragements.length];
}

// ─────────────────────────────────────────────────────────────────────────────
// WeeklyAchievementCard — Main widget
// ─────────────────────────────────────────────────────────────────────────────

/// A card that summarizes a single week's achievements, designed to be
/// visually shareable.
///
/// Content includes streak status, cravings resisted, money saved, exercises
/// completed, level/XP progress, and a motivational quote.
///
/// Example:
/// ```dart
/// WeeklyAchievementCard(
///   streakDays: 14,
///   level: 4,
///   xp: 320,
///   xpToNext: 450,
///   cravingsResisted: 8,
///   exercisesCompleted: 5,
///   weeklyMoneySaved: 175.0,
///   weeklyCheckins: 7,
///   weekStartDate: '6月14日',
///   weekEndDate: '6月20日',
///   onShare: () => shareCard(),
/// )
/// ```
class WeeklyAchievementCard extends StatefulWidget {
  /// Current consecutive check-in streak in days.
  final int streakDays;

  /// Current game level.
  final int level;

  /// Current XP.
  final int xp;

  /// XP required for the next level.
  final int xpToNext;

  /// Number of cravings resisted this week.
  final int cravingsResisted;

  /// Number of exercises completed this week.
  final int exercisesCompleted;

  /// Money saved this week (yuan).
  final double weeklyMoneySaved;

  /// Number of daily check-ins completed this week.
  final int weeklyCheckins;

  /// Human-readable start date of the week (e.g. "6月14日").
  final String weekStartDate;

  /// Human-readable end date of the week (e.g. "6月20日").
  final String weekEndDate;

  /// Called when the share button is pressed.
  final VoidCallback? onShare;

  const WeeklyAchievementCard({
    super.key,
    required this.streakDays,
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.cravingsResisted,
    required this.exercisesCompleted,
    required this.weeklyMoneySaved,
    required this.weeklyCheckins,
    required this.weekStartDate,
    required this.weekEndDate,
    this.onShare,
  });

  @override
  State<WeeklyAchievementCard> createState() => _WeeklyAchievementCardState();
}

class _WeeklyAchievementCardState extends State<WeeklyAchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Start reveal on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealController.forward();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  /// Staggered opacity + slide animation for each child.
  Widget _animatedItem(int index, Widget child, double controllerValue) {
    final startDelay = index * 0.1;
    final start = (startDelay / 1.0).clamp(0.0, 0.8);
    final end = (start + 0.3).clamp(0.0, 1.0);

    final intervalValue = Interval(start, end, curve: Curves.easeOut)
        .transform(controllerValue);

    final opacity = intervalValue;
    final slideOffset = (1.0 - intervalValue) * 16.0;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slideOffset),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = Theme.of(context).extension<AppSpacing>();
    final appColors = Theme.of(context).extension<AppColors>();

    final r = spacing?.cardRadius ?? 16;

    final xpProgress =
        (widget.xp / widget.xpToNext).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (appColors?.achievementColor ?? colorScheme.primary)
                  .withOpacity(0.08),
              colorScheme.surfaceContainerHighest.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(r),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing?.cardPadding ?? 20),
          child: AnimatedBuilder(
            animation: _revealController,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 0: Week title + date range ──────────────────────────
                  _animatedItem(0, _buildHeader(colorScheme, spacing, appColors), _revealController.value),

                  SizedBox(height: spacing?.sm ?? 12),

                  // ── Row 1: Streak (fire icon, large) ──────────────────────────
                  _animatedItem(1, _buildStreakRow(colorScheme), _revealController.value),

                  SizedBox(height: spacing?.md ?? 16),

                  // ── Row 2: Stats grid (2×2) ──────────────────────────────────
                  _animatedItem(2, _buildStatsGrid(colorScheme, spacing), _revealController.value),

                  SizedBox(height: spacing?.md ?? 16),

                  // ── Row 3: Level + XP progress ────────────────────────────────
                  _animatedItem(3, _buildLevelSection(colorScheme, spacing, xpProgress), _revealController.value),

                  SizedBox(height: spacing?.md ?? 16),

                  // ── Row 4: Motivational quote ─────────────────────────────────
                  _animatedItem(4, _buildQuoteSection(colorScheme), _revealController.value),

                  SizedBox(height: spacing?.sm ?? 12),

                  // ── Row 5: Share button ───────────────────────────────────────
                  _animatedItem(5, _buildShareButton(colorScheme, spacing), _revealController.value),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Section builders ─────────────────────────────────────────────────────

  Widget _buildHeader(
    ColorScheme colorScheme,
    AppSpacing? spacing,
    AppColors? appColors,
  ) {
    return Row(
      children: [
        Icon(
          Icons.emoji_events_rounded,
          size: 20,
          color: appColors?.achievementColor ?? colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '本周成就',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
        ),
        const Spacer(),
        Text(
          '${widget.weekStartDate} — ${widget.weekEndDate}',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakRow(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Text(
            '${widget.streakDays}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1.1,
                ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '天连续',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
          // Checkin count
          Text(
            '本周签到 ${widget.weeklyCheckins} 天',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ColorScheme colorScheme, AppSpacing? spacing) {
    final items = [
      _StatItem(
        icon: Icons.shield_rounded,
        label: '抵御渴望',
        value: '${widget.cravingsResisted} 次',
        color: const Color(0xFF42A5F5),
      ),
      _StatItem(
        icon: Icons.savings_rounded,
        label: '省下',
        value: '¥${widget.weeklyMoneySaved.toStringAsFixed(0)}',
        color: const Color(0xFFFFB300),
      ),
      _StatItem(
        icon: Icons.fitness_center_rounded,
        label: '完成练习',
        value: '${widget.exercisesCompleted} 个',
        color: const Color(0xFF66BB6A),
      ),
      _StatItem(
        icon: Icons.stars_rounded,
        label: '签到天数',
        value: '${widget.weeklyCheckins} 天',
        color: const Color(0xFFAB47BC),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing?.xs ?? 8,
      crossAxisSpacing: spacing?.xs ?? 8,
      childAspectRatio: 2.8,
      children: items.map((item) => _buildStatCell(item, colorScheme)).toList(),
    );
  }

  Widget _buildStatCell(_StatItem item, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              size: 16,
              color: item.color,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection(
    ColorScheme colorScheme,
    AppSpacing? spacing,
    double xpProgress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                'Lv.${widget.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.xp} / ${widget.xpToNext} XP',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing?.xxs ?? 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: xpProgress,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteSection(ColorScheme colorScheme) {
    final encouragement = _pickEncouragement(widget.weekStartDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: (Theme.of(context).extension<AppColors>()
                        ?.achievementColor ??
                    colorScheme.primary)
                .withOpacity(0.5),
            width: 3,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '「$encouragement」',
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildShareButton(ColorScheme colorScheme, AppSpacing? spacing) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: widget.onShare,
        icon: Icon(
          Icons.share_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        label: Text(
          '分享本周成就',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: BorderSide(
            color: colorScheme.outlineVariant,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing?.buttonRadius ?? 12),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal data class for stats grid items
// ─────────────────────────────────────────────────────────────────────────────

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}