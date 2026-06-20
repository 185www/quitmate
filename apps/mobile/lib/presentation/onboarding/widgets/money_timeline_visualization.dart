import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Money Timeline — "这些年你花在烟/酒上的钱可以买..."
///
/// An animated vertical timeline showing cumulative spending over the user's
/// years of use, with milestone callouts showing what that money could have
/// purchased. Ends with a future savings projection.
class MoneyTimelineVisualization extends StatefulWidget {
  /// Daily cost in yuan.
  final int dailyCost;

  /// Number of years the user has been using.
  final int yearsOfUse;

  /// Label for the substance (e.g. "烟", "酒", "烟酒").
  final String unitLabel;

  const MoneyTimelineVisualization({
    super.key,
    required this.dailyCost,
    required this.yearsOfUse,
    this.unitLabel = '烟',
  });

  @override
  State<MoneyTimelineVisualization> createState() =>
      _MoneyTimelineVisualizationState();
}

class _MoneyTimelineVisualizationState extends State<MoneyTimelineVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int get _yearlyCost => widget.dailyCost * 365;

  /// Future 10-year savings if they quit today.
  int get _futureSavings => _yearlyCost * 10;

  @override
  void initState() {
    super.initState();
    // Animate longer when there are more years to show.
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 1200 + widget.yearsOfUse * 200,
      ),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Milestone purchase items — thresholds and Chinese-relevant descriptions.
  static const _milestones = [
    _Milestone(threshold: 5000, emoji: '📱', label: '一部新手机'),
    _Milestone(threshold: 10000, emoji: '✈️', label: '一次国内旅行'),
    _Milestone(threshold: 30000, emoji: '💍', label: '一枚金戒指'),
    _Milestone(threshold: 50000, emoji: '🚗', label: '一辆小汽车的定金'),
    _Milestone(threshold: 100000, emoji: '🏠', label: '一年的房租'),
    _Milestone(threshold: 200000, emoji: '💰', label: '一套小户型首付'),
    _Milestone(threshold: 500000, emoji: '🌟', label: '改变人生的一笔钱'),
  ];

  /// Build a list of year entries, each with the cumulative cost and
  /// optionally a milestone that was crossed that year.
  List<_YearEntry> get _yearEntries {
    final entries = <_YearEntry>[];
    int cumulative = 0;
    final crossedMilestones = <_Milestone>[];

    // Decide step: if years > 10, show every 2 years; if > 20, every 5.
    int step = 1;
    if (widget.yearsOfUse > 20) {
      step = 5;
    } else if (widget.yearsOfUse > 10) {
      step = 2;
    }

    int prevShownCumulative = 0;

    for (int y = 1; y <= widget.yearsOfUse; y++) {
      cumulative += _yearlyCost;

      // Check milestones crossed so far
      for (final m in _milestones) {
        if (!crossedMilestones.contains(m) &&
            cumulative >= m.threshold) {
          crossedMilestones.add(m);
        }
      }

      // Only show stepped years, or the last year.
      if (y % step == 0 || y == widget.yearsOfUse) {
        final newlyCrossed = <_Milestone>[];
        // Find milestones crossed since the last displayed entry.
        for (final m in _milestones) {
          if (cumulative >= m.threshold &&
              prevShownCumulative < m.threshold) {
            newlyCrossed.add(m);
          }
        }

        entries.add(_YearEntry(
          year: y,
          cumulative: cumulative,
          milestones: newlyCrossed,
        ));
        prevShownCumulative = cumulative;
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spacing = theme.extension<AppSpacing>();
    final cardRadius = spacing?.cardRadius ?? 16;
    final cardPadding = spacing?.cardPadding ?? 20;

    final entries = _yearEntries;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.timeline_rounded,
                    size: 20, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  '花费时间线',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '这些年你花在${widget.unitLabel}上的钱，其实可以买这些…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Timeline
            _TimelineBody(
              entries: entries,
              animation: _controller,
              colorScheme: colorScheme,
              theme: theme,
            ),

            const SizedBox(height: 20),

            // Divider
            Divider(color: colorScheme.outlineVariant.withOpacity(0.3)),
            const SizedBox(height: 16),

            // Future savings section
            _FutureSavingsSection(
              futureSavings: _futureSavings,
              unitLabel: widget.unitLabel,
              theme: theme,
              colorScheme: colorScheme,
              animation: _controller,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Data classes
// ──────────────────────────────────────────────────────────────────────

class _Milestone {
  final int threshold;
  final String emoji;
  final String label;
  const _Milestone({
    required this.threshold,
    required this.emoji,
    required this.label,
  });
}

class _YearEntry {
  final int year;
  final int cumulative;
  final List<_Milestone> milestones;
  const _YearEntry({
    required this.year,
    required this.cumulative,
    required this.milestones,
  });
}

// ──────────────────────────────────────────────────────────────────────
// Timeline body with staggered reveal
// ──────────────────────────────────────────────────────────────────────

class _TimelineBody extends StatelessWidget {
  final List<_YearEntry> entries;
  final Animation<double> animation;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _TimelineBody({
    required this.entries,
    required this.animation,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      children: List.generate(entries.length, (i) {
        final entry = entries[i];
        final total = entries.length;

        // Stagger each entry's appearance.
        final startFraction = (i / total) * 0.7;
        final endFraction = ((i + 1) / total) * 0.7 + 0.3;
        final itemAnim = CurvedAnimation(
          parent: animation,
          curve: Interval(
            startFraction.clamp(0.0, 1.0),
            endFraction.clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        );

        return _TimelineEntryWidget(
          entry: entry,
          animation: itemAnim,
          colorScheme: colorScheme,
          theme: theme,
          isLast: i == entries.length - 1,
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Single timeline entry
// ──────────────────────────────────────────────────────────────────────

class _TimelineEntryWidget extends StatelessWidget {
  final _YearEntry entry;
  final Animation<double> animation;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isLast;

  const _TimelineEntryWidget({
    required this.entry,
    required this.animation,
    required this.colorScheme,
    required this.theme,
    required this.isLast,
  });

  String _formatMoney(int amount) {
    if (amount >= 10000) {
      return '¥${(amount / 10000).toStringAsFixed(1)}万';
    }
    return '¥${amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final opacity = animation.value;
        final slideOffset = (1 - animation.value) * 20;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, slideOffset),
            child: child,
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline track
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  // Dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.milestones.isNotEmpty
                          ? Colors.amber.shade600
                          : colorScheme.primary,
                      border: Border.all(
                        color: entry.milestones.isNotEmpty
                            ? Colors.amber.shade200
                            : colorScheme.primaryContainer,
                        width: 2,
                      ),
                    ),
                  ),
                  // Line (unless last)
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Year label + amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '第 ${entry.year} 年',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatMoney(entry.cumulative),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    // Stacked bar showing cumulative amount
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.milestones.isNotEmpty ? 1.0 : 0.6,
                        minHeight: 4,
                        backgroundColor:
                            colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        valueColor: AlwaysStoppedAnimation(
                          entry.milestones.isNotEmpty
                              ? Colors.amber.shade500
                              : colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                    ),
                    // Milestone callouts
                    if (entry.milestones.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...entry.milestones.map((m) => Builder(
                            builder: (context) {
                              final isDark = Theme.of(context).brightness ==
                                  Brightness.dark;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.amber.shade900.withOpacity(0.3)
                                      : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber.shade200
                                        .withOpacity(isDark ? 0.3 : 0.5),
                                  ),
                                ),
                            child: Row(
                                  children: [
                                    Text(m.emoji, style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_formatMoney(m.threshold)} = ${m.label}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: isDark
                                              ? Colors.amber.shade200
                                              : Colors.amber.shade900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          )),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Future savings section
// ──────────────────────────────────────────────────────────────────────

class _FutureSavingsSection extends StatelessWidget {
  final int futureSavings;
  final String unitLabel;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final Animation<double> animation;

  const _FutureSavingsSection({
    required this.futureSavings,
    required this.unitLabel,
    required this.theme,
    required this.colorScheme,
    required this.animation,
  });

  String _formatMoney(int amount) {
    if (amount >= 10000) {
      return '¥${(amount / 10000).toStringAsFixed(1)}万';
    }
    return '¥$amount';
  }

  @override
  Widget build(BuildContext context) {
    // Animate the number counting up (interval 0.8–1.0, easeOutCubic).
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // Manual interval + easeOutCubic to avoid CurvedAnimation per frame.
        final rawInterval = ((animation.value - 0.8) / 0.2).clamp(0.0, 1.0);
        final t = 1 - rawInterval;
        final eased = 1 - (t * t * t); // easeOutCubic
        final animatedSavings = (futureSavings * eased).round();

        return Column(
          children: [
            Row(
              children: [
                Icon(Icons.savings_rounded,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '如果今天开始戒${unitLabel}…',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Big number
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatMoney(animatedSavings),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '十年后你将多出这些钱',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Stacked coin animation area
            SizedBox(
              height: 48,
              child: CustomPaint(
                size: Size(double.infinity, 48),
                painter: _RisingCoinsPainter(
                  progress: animation.value,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Rising coins CustomPainter — decorative stacked money animation
// ──────────────────────────────────────────────────────────────────────

class _RisingCoinsPainter extends CustomPainter {
  final double progress;
  final ColorScheme colorScheme;

  _RisingCoinsPainter({
    required this.progress,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    const coinCount = 7;
    for (int i = 0; i < coinCount; i++) {
      final delay = i / coinCount;
      final coinProgress = ((progress - delay * 0.5).clamp(0.0, 1.0));
      if (coinProgress <= 0) continue;

      // Each coin rises from bottom with slight horizontal offset.
      final baseX = size.width * (0.15 + 0.7 * (i / (coinCount - 1)));
      final xOffset = math.sin(i * 1.5 + progress * 4) * 6;
      final yProgress = (1 - coinProgress);
      final yOffset = size.height * (0.8 - 0.7 * coinProgress);

      final coinRadius = 10.0 + (i % 3) * 2;
      final opacity = (coinProgress * 0.6).clamp(0.0, 0.6);

      final paint = Paint()
        ..color = Colors.amber.shade400.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(baseX + xOffset, yOffset),
        coinRadius,
        paint,
      );

      // Inner circle (coin detail)
      final innerPaint = Paint()
        ..color = Colors.amber.shade300.withOpacity(opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(
        Offset(baseX + xOffset, yOffset),
        coinRadius * 0.6,
        innerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RisingCoinsPainter old) =>
      old.progress != progress;
}