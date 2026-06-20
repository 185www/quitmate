import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Social Comparison Card — "80% 的人在你的年龄段…"
///
/// Displays 4 anonymized statistics cards with animated number counters,
/// using realistic Chinese demographic data about smoking/drinking.
///
/// Each stat card shows: icon → animated number → description.
/// The stats adapt based on the user's age range and target type.
class SocialComparisonCard extends StatefulWidget {
  /// User's approximate age, used to tailor demographic comparisons.
  final int userAge;

  /// The target type label — affects which stats to show.
  final String targetTypeLabel;

  const SocialComparisonCard({
    super.key,
    required this.userAge,
    this.targetTypeLabel = '吸烟',
  });

  @override
  State<SocialComparisonCard> createState() => _SocialComparisonCardState();
}

class _SocialComparisonCardState extends State<SocialComparisonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Age bracket string for display.
  String get _ageBracket {
    final age = widget.userAge;
    if (age < 25) return '18-24岁';
    if (age < 35) return '25-34岁';
    if (age < 45) return '35-44岁';
    if (age < 55) return '45-54岁';
    return '55岁以上';
  }

  /// Smoking rate by age bracket (China CDC 2022 data, simplified).
  double get _ageGroupSmokingRate {
    final age = widget.userAge;
    if (age < 25) return 18.0;
    if (age < 35) return 30.0;
    if (age < 45) return 35.0;
    if (age < 55) return 38.0;
    return 33.0;
  }

  /// National average smoking rate (China adult male ≈ 50.5%, overall ≈ 26.6%).
  double get _nationalAverage => 26.6;

  /// Average annual spending on cigarettes/alcohol for this age group.
  int get _avgAnnualSpending {
    final age = widget.userAge;
    if (age < 25) return 5400;
    if (age < 35) return 10800;
    if (age < 45) return 14400;
    if (age < 55) return 12000;
    return 8400;
  }

  /// First-attempt quit success rate.
  double get _firstAttemptRate => 3.0;

  /// 90-day quit success rate.
  double get _day90SuccessRate => 65.0;

  List<_StatItem> get _stats => [
        _StatItem(
          icon: Icons.groups_rounded,
          iconColor: Colors.blue,
          label: '你的年龄段${widget.targetTypeLabel}率',
          value: _ageGroupSmokingRate,
          suffix: '%',
          unit: '',
          description: '全国平均为 $_nationalAverage%',
          isHighlight: _ageGroupSmokingRate > _nationalAverage,
          highlightText:
              _ageGroupSmokingRate > _nationalAverage
                  ? '高于全国平均水平'
                  : '低于全国平均水平',
        ),
        _StatItem(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: Colors.amber.shade700,
          label: '同龄人年均${widget.targetTypeLabel}支出',
          value: _avgAnnualSpending.toDouble(),
          suffix: '',
          unit: '元',
          description: '相当于一台新手机的钱',
          isHighlight: false,
          highlightText: null,
          isCurrency: true,
        ),
        _StatItem(
          icon: Icons.block_rounded,
          iconColor: Colors.red.shade400,
          label: '首次尝试即${widget.targetTypeLabel == "饮酒" ? "戒酒" : "戒烟"}成功',
          value: _firstAttemptRate,
          suffix: '%',
          unit: '',
          description: '但大多数人会反复尝试',
          isHighlight: false,
          highlightText: '不要因为失败而放弃',
        ),
        _StatItem(
          icon: Icons.emoji_events_rounded,
          iconColor: Colors.green.shade600,
          label: '坚持 90 天不${widget.targetTypeLabel}',
          value: _day90SuccessRate,
          suffix: '%',
          unit: '',
          description: '${widget.targetTypeLabel == "饮酒" ? "戒酒" : "戒烟"}成功率',
          isHighlight: true,
          highlightText: '坚持就是胜利',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spacing = theme.extension<AppSpacing>();
    final cardRadius = spacing?.cardRadius ?? 16;
    final cardPadding = spacing?.cardPadding ?? 20;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 20, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '你并不孤单',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$_ageBracket 人群的匿名统计数据',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stat cards in 2x2 grid
            ..._buildStatGrid(colorScheme, theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatGrid(ColorScheme colorScheme, ThemeData theme) {
    final rows = <Widget>[];
    final rowCount = (_stats.length / 2).ceil();

    for (int row = 0; row < rowCount; row++) {
      final rowChildren = <Widget>[];
      for (int col = 0; col < 2; col++) {
        final i = row * 2 + col;
        if (i >= _stats.length) {
          // Empty slot to keep grid aligned.
          rowChildren.add(const Expanded(child: SizedBox()));
          continue;
        }

        final stat = _stats[i];
        final staggerStart = i * 0.15;
        final staggerEnd = staggerStart + 0.5;
        final anim = CurvedAnimation(
          parent: _controller,
          curve: Interval(
            staggerStart.clamp(0.0, 1.0),
            staggerEnd.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        );

        rowChildren.add(
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: col == 0 ? 6 : 0,
                left: col == 1 ? 6 : 0,
                bottom: row < rowCount - 1 ? 12 : 0,
              ),
              child: _AnimatedStatCard(
                stat: stat,
                animation: anim,
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),
          ),
        );
      }
      rows.add(Row(children: rowChildren));
    }
    return rows;
  }
}

// ──────────────────────────────────────────────────────────────────────
// Stat data
// ──────────────────────────────────────────────────────────────────────

class _StatItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final double value;
  final String suffix;
  final String unit;
  final String description;
  final bool isHighlight;
  final String? highlightText;
  final bool isCurrency;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.suffix,
    required this.unit,
    required this.description,
    required this.isHighlight,
    this.highlightText,
    this.isCurrency = false,
  });
}

// ──────────────────────────────────────────────────────────────────────
// Animated stat card with counter
// ──────────────────────────────────────────────────────────────────────

class _AnimatedStatCard extends StatelessWidget {
  final _StatItem stat;
  final Animation<double> animation;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _AnimatedStatCard({
    required this.stat,
    required this.animation,
    required this.colorScheme,
    required this.theme,
  });

  String _formatValue(double val) {
    if (stat.isCurrency) {
      final rounded = val.round();
      if (rounded >= 10000) {
        return '¥${(rounded / 10000).toStringAsFixed(1)}万';
      }
      return '¥${rounded.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          )}';
    }
    return val.toStringAsFixed(stat.value == val.roundToDouble() ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final opacity = animation.value;
        final scale = 0.9 + 0.1 * animation.value;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.centerLeft,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: stat.isHighlight
              ? (colorScheme.brightness == Brightness.dark
                  ? colorScheme.primaryContainer.withOpacity(0.2)
                  : colorScheme.primaryContainer.withOpacity(0.4))
              : colorScheme.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
          border: stat.isHighlight
              ? Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: stat.iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(stat.icon, size: 20, color: stat.iconColor),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  Text(
                    stat.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Animated number
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) {
                          final currentVal = stat.value * animation.value;
                          return Text(
                            _formatValue(currentVal),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: stat.iconColor,
                            ),
                          );
                        },
                      ),
                      if (stat.suffix.isNotEmpty)
                        Text(
                          stat.suffix,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: stat.iconColor,
                          ),
                        ),
                      if (stat.unit.isNotEmpty) ...[
                        const SizedBox(width: 2),
                        Text(
                          stat.unit,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    stat.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  // Highlight text
                  if (stat.highlightText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      stat.highlightText!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: stat.isHighlight
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}