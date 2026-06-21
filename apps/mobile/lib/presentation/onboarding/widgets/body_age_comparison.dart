import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Body Age Comparison — "你的肺年龄是 X 岁"
///
/// Shows an animated gauge comparing the user's actual age with an
/// estimated "lung age" based on years of smoking/alcohol use.
///
/// Lung age formula (simplified): `actualAge + yearsOfUse * 1.5`
///
/// The gauge animates from green (healthy) through yellow to red (damaged).
/// A recovery timeline is shown below the gauge.
class BodyAgeComparison extends StatefulWidget {
  /// The user's actual age in years.
  final int actualAge;

  /// Number of years the user has been smoking / drinking.
  final int yearsOfUse;

  /// The target type — affects the organ label and recovery text.
  final String targetTypeLabel;

  const BodyAgeComparison({
    super.key,
    required this.actualAge,
    required this.yearsOfUse,
    this.targetTypeLabel = '吸烟',
  });

  @override
  State<BodyAgeComparison> createState() => _BodyAgeComparisonState();
}

class _BodyAgeComparisonState extends State<BodyAgeComparison>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gaugeAnimation;
  late Animation<double> _numberAnimation;

  /// Lung age estimate (simplified heuristic).
  int get _lungAge => widget.actualAge + (widget.yearsOfUse * 1.5).round();

  /// How much older the lungs are compared to actual age.
  int get _ageDiff => _lungAge - widget.actualAge;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Gauge sweeps from 0 to 1.
    _gaugeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Number counter animates to lung age.
    _numberAnimation = Tween<double>(begin: 0, end: _lungAge.toDouble())
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Recovery milestones based on the age difference.
  List<_RecoveryMilestone> get _recoveryMilestones {
    final milestones = <_RecoveryMilestone>[];
    if (_ageDiff <= 2) {
      milestones
        ..add(const _RecoveryMilestone('2 周', '肺部纤毛开始修复', 0.1))
        ..add(const _RecoveryMilestone('3 个月', '肺功能明显改善', 0.5))
        ..add(const _RecoveryMilestone('1 年', '肺年龄基本恢复正常', 0.95));
    } else if (_ageDiff <= 8) {
      milestones
        ..add(const _RecoveryMilestone('2 周', '呼吸会变得更轻松', 0.1))
        ..add(const _RecoveryMilestone('3 个月', '肺活量提升约 30%', 0.35))
        ..add(const _RecoveryMilestone('1 年', '冠心病风险降低一半', 0.55))
        ..add(const _RecoveryMilestone('5 年', '中风风险恢复到非吸烟者水平', 0.8))
        ..add(const _RecoveryMilestone('10 年', '肺癌风险降低约 50%', 0.95));
    } else {
      milestones
        ..add(const _RecoveryMilestone('1 周', '一氧化碳水平恢复正常', 0.08))
        ..add(const _RecoveryMilestone('3 个月', '咳嗽和气短明显减少', 0.25))
        ..add(const _RecoveryMilestone('1 年', '心血管疾病风险降低一半', 0.45))
        ..add(const _RecoveryMilestone('5 年', '中风风险接近非吸烟者', 0.7))
        ..add(const _RecoveryMilestone('10 年', '肺癌死亡率降至非吸烟者水平', 0.9))
        ..add(const _RecoveryMilestone('15 年', '各项指标恢复到正常水平', 1.0));
    }
    return milestones;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spacing = theme.extension<AppSpacing>();
    final cardRadius = spacing?.cardRadius ?? 16;
    final cardPadding = spacing?.cardPadding ?? 20;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(Icons.air_rounded,
                    size: 20,
                    color: colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  '肺年龄评估',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '基于${widget.targetTypeLabel}史估算，仅供参考',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Gauge + numbers
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Column(
                children: [
                  // Gauge
                  SizedBox(
                    height: 28,
                    child: CustomPaint(
                      size: Size(double.infinity, 28),
                      painter: _LungGaugePainter(
                        progress: _gaugeAnimation.value,
                        lungAge: _lungAge,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Age comparison numbers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Actual age
                      _AgeColumn(
                        label: '实际年龄',
                        value: widget.actualAge,
                        unit: '岁',
                        color: colorScheme.primary,
                        theme: theme,
                      ),
                      // Arrow
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                color: colorScheme.onSurfaceVariant, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              '+$_ageDiff',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Lung age (animated)
                      _AgeColumn(
                        label: '肺年龄',
                        value: _numberAnimation.value.round(),
                        unit: '岁',
                        color: colorScheme.error,
                        theme: theme,
                        highlight: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Divider
            Divider(color: colorScheme.outlineVariant.withOpacity(0.3)),
            const SizedBox(height: 16),

            // Recovery timeline
            Text(
              '戒烟后，肺年龄可以逐步恢复',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            ..._recoveryMilestones.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecoveryRow(
                    milestone: m,
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Age column display
// ──────────────────────────────────────────────────────────────────────

class _AgeColumn extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color color;
  final ThemeData theme;
  final bool highlight;

  const _AgeColumn({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.theme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$value',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: highlight ? 40 : 32,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Recovery milestone row
// ──────────────────────────────────────────────────────────────────────

class _RecoveryMilestone {
  final String timeLabel;
  final String description;
  final double progressHint;
  const _RecoveryMilestone(this.timeLabel, this.description, this.progressHint);
}

class _RecoveryRow extends StatelessWidget {
  final _RecoveryMilestone milestone;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _RecoveryRow({
    required this.milestone,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot + line
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
                border: Border.all(
                  color: colorScheme.primaryContainer,
                  width: 2,
                ),
              ),
            ),
            Container(
              width: 2,
              height: 28,
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                milestone.timeLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                milestone.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Lung Gauge CustomPainter
// ──────────────────────────────────────────────────────────────────────

class _LungGaugePainter extends CustomPainter {
  final double progress;
  final int lungAge;
  final bool isDark;
  final ColorScheme colorScheme;

  _LungGaugePainter({
    required this.progress,
    required this.lungAge,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    // Background track
    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark
          ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
          : colorScheme.surfaceContainerHighest;
    canvas.drawRRect(rrect, bgPaint);

    // Foreground gradient — green → yellow → red
    if (progress > 0) {
      final fillWidth = size.width * progress.clamp(0.0, 1.0);
      final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
      final fillRrect = RRect.fromRectAndRadius(
          fillRect, const Radius.circular(14));

      // We use a right-aligned radius correction to avoid overflow
      final shaderRect = Rect.fromLTWH(0, 0, size.width, size.height);
      final gradient = LinearGradient(
        colors: [
          Colors.green.shade400,
          Colors.green.shade300,
          Colors.yellow.shade400,
          Colors.orange.shade400,
          Colors.red.shade400,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = gradient.createShader(shaderRect);
      canvas.drawRRect(fillRrect, fillPaint);
    }

    // Needle marker at current position
    final needleX = size.width * progress.clamp(0.0, 1.0);
    final needlePaint = Paint()
      ..color = colorScheme.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(needleX, 0),
      Offset(needleX, size.height),
      needlePaint,
    );

    // Top and bottom caps on the needle
    final capPaint = Paint()
      ..color = colorScheme.onSurface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(needleX, 0), 3.5, capPaint);
    canvas.drawCircle(Offset(needleX, size.height), 3.5, capPaint);

    // Labels at start and end
    final labelStyle = TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontSize: 9,
    );
    final labelPainter = TextPainter(
      text: TextSpan(text: '健康', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(6, (size.height - labelPainter.height) / 2),
    );

    final endLabelPainter = TextPainter(
      text: TextSpan(text: '受损', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    endLabelPainter.paint(
      canvas,
      Offset(
        size.width - endLabelPainter.width - 6,
        (size.height - endLabelPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _LungGaugePainter old) =>
      old.progress != progress ||
      old.isDark != isDark ||
      old.colorScheme != colorScheme;
}