/// Money Savings Animator — 从文字变为动画积攒效果
///
/// Displays total money saved since the quit date with:
/// - An animated coin/bill stacking [CustomPainter]
/// - A number counter that animates from 0 to the current savings
/// - A "today you saved" subtitle
/// - Sparkle effects at milestone thresholds (¥1K, ¥5K, ¥10K, ¥50K)
///
/// All text is in Chinese. Uses warm gold/amber tones.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CoinStackPainter — CustomPainter for animated coins/bills
// ─────────────────────────────────────────────────────────────────────────────

/// Paints a savings jar with stacked coins inside it.
/// The number of visible coin stacks grows with [animatedValue].
class _CoinStackPainter extends CustomPainter {
  _CoinStackPainter({
    required this.animatedValue,
    this.isDark = false,
  });

  /// The currently displayed (animated) savings value.
  final double animatedValue;

  final bool isDark;

  /// Milestone thresholds for sparkle detection.
  static const _milestones = [1000.0, 5000.0, 10000.0, 50000.0, 100000.0];

  bool get _isAtMilestone =>
      _milestones.any((m) => (animatedValue - m).abs() < 50);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final isDark = this.isDark;

    // ── Jar body ───────────────────────────────────────────────────────────
    _drawJar(canvas, cx, size, isDark);

    // ── Coins inside ───────────────────────────────────────────────────────
    _drawCoins(canvas, cx, size);

    // ── Sparkle at milestones ──────────────────────────────────────────────
    if (_isAtMilestone) {
      _drawSparkles(canvas, cx, size);
    }
  }

  void _drawJar(Canvas canvas, double cx, Size size, bool isDark) {
    final jarTop = size.height * 0.18;
    final jarBottom = size.height * 0.85;
    final jarWidth = size.width * 0.55;
    final jarHeight = jarBottom - jarTop;

    // Jar body (rounded rectangle with slightly narrower top)
    final jarPath = Path()
      ..moveTo(cx - jarWidth * 0.4, jarTop + 12)
      ..quadraticBezierTo(cx - jarWidth * 0.48, jarTop + jarHeight * 0.5,
          cx - jarWidth * 0.44, jarBottom - 8)
      ..quadraticBezierTo(cx - jarWidth * 0.44, jarBottom, cx - jarWidth * 0.3, jarBottom)
      ..lineTo(cx + jarWidth * 0.3, jarBottom)
      ..quadraticBezierTo(cx + jarWidth * 0.44, jarBottom, cx + jarWidth * 0.44, jarBottom - 8)
      ..quadraticBezierTo(cx + jarWidth * 0.48, jarTop + jarHeight * 0.5,
          cx + jarWidth * 0.4, jarTop + 12)
      ..close();

    final jarColor = isDark
        ? const Color(0xFF4A6741).withOpacity(0.3)
        : const Color(0xFFC8E6C9).withOpacity(0.5);
    final jarStroke = isDark
        ? const Color(0xFF66BB6A).withOpacity(0.3)
        : const Color(0xFF81C784).withOpacity(0.5);

    canvas.drawPath(jarPath, Paint()..color = jarColor);
    canvas.drawPath(
      jarPath,
      Paint()
        ..color = jarStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Jar neck / rim
    final rimPath = Path()
      ..moveTo(cx - jarWidth * 0.42, jarTop)
      ..lineTo(cx - jarWidth * 0.4, jarTop + 12)
      ..lineTo(cx + jarWidth * 0.4, jarTop + 12)
      ..lineTo(cx + jarWidth * 0.42, jarTop)
      ..close();

    canvas.drawPath(
      rimPath,
      Paint()
        ..color = isDark
            ? const Color(0xFF66BB6A).withOpacity(0.3)
            : const Color(0xFF81C784).withOpacity(0.5),
    );

    // Jar label: "¥"
    final labelY = jarBottom - 20;
    final labelColor = isDark
        ? const Color(0xFFA5D6A7).withOpacity(0.4)
        : const Color(0xFF388E3C).withOpacity(0.25);
    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: 28,
      fontWeight: FontWeight.w800,
    );
    final tp = TextPainter(
      text: TextSpan(text: '¥', style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, labelY - tp.height / 2));
  }

  void _drawCoins(Canvas canvas, double cx, Size size) {
    if (animatedValue <= 0) return;

    // Number of coin stacks scales with savings
    final maxStacks = 5;
    final numStacks = (math.min(animatedValue / 1000, 1.0) * maxStacks).ceil().clamp(1, maxStacks);

    // Coins per stack scale with savings
    final coinsPerStack = (math.min(animatedValue / 500, 1.0) * 4).ceil().clamp(1, 4);

    final jarTop = size.height * 0.28;
    final jarBottom = size.height * 0.75;
    final coinHeight = 6.0;
    final coinWidth = 14.0;

    final stackSpacing = (size.width * 0.35) / (numStacks + 1);

    for (var s = 0; s < numStacks; s++) {
      final stackX = cx - (numStacks - 1) * stackSpacing / 2 + s * stackSpacing;
      final baseY = jarBottom - 12;

      for (var c = 0; c < coinsPerStack; c++) {
        final coinY = baseY - c * coinHeight;

        // Only draw if within jar bounds
        if (coinY < jarTop + 5) continue;

        // Coin body
        final coinRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(stackX, coinY), width: coinWidth, height: coinHeight),
          const Radius.circular(3),
        );

        // Gold gradient per coin
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFD54F),
            const Color(0xFFFFB300),
          ],
        );

        canvas.drawRRect(
          coinRect,
          Paint()..shader = gradient.createShader(coinRect.outerRect),
        );

        // Subtle border
        canvas.drawRRect(
          coinRect,
          Paint()
            ..color = const Color(0xFFFF8F00).withOpacity(0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }

    // Add a bill peeking out for larger amounts (>2000)
    if (animatedValue > 2000) {
      _drawBill(canvas, cx + size.width * 0.08, jarTop + 10, size);
    }
    if (animatedValue > 5000) {
      _drawBill(canvas, cx - size.width * 0.06, jarTop + 16, size);
    }
  }

  void _drawBill(Canvas canvas, double x, double y, Size size) {
    final billPath = Path()
      ..moveTo(x, y)
      ..lineTo(x + 18, y - 6)
      ..lineTo(x + 18, y + 18)
      ..lineTo(x, y + 24)
      ..close();

    canvas.drawPath(
      billPath,
      Paint()..color = const Color(0xFF43A047).withOpacity(0.7),
    );

    // ¥ symbol on bill
    final billStyle = TextStyle(
      color: Colors.white.withOpacity(0.6),
      fontSize: 9,
      fontWeight: FontWeight.bold,
    );
    final tp = TextPainter(
      text: const TextSpan(text: '¥', style: billStyle),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x + 4, y + 5));
  }

  void _drawSparkles(Canvas canvas, double cx, Size size) {
    final rng = math.Random(42); // Deterministic for consistent sparkle positions
    final sparkleColor = const Color(0xFFFFD54F);

    for (var i = 0; i < 8; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist = 25.0 + rng.nextDouble() * 35;
      final sx = cx + math.cos(angle) * dist;
      final sy = size.height * 0.45 + math.sin(angle) * dist * 0.6;
      _drawSparkle(canvas, Offset(sx, sy), 3 + rng.nextDouble() * 3, sparkleColor);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Four-pointed star
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoinStackPainter oldDelegate) {
    return oldDelegate.animatedValue != animatedValue ||
        oldDelegate.isDark != isDark;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MoneySavingsAnimator — Main widget
// ─────────────────────────────────────────────────────────────────────────────

/// An animated card that shows total money saved since the user quit.
///
/// Features:
/// - Animated number counter from 0 to [totalSavedYuan].
/// - Coin/bill stacking visual that grows with savings.
/// - "Today you saved" subtitle.
/// - Sparkle effect at milestone thresholds.
///
/// Example:
/// ```dart
/// MoneySavingsAnimator(
///   totalSavedYuan: 3680.0,
///   dailySavedYuan: 25.0,
///   daysQuit: 147,
/// )
/// ```
class MoneySavingsAnimator extends StatefulWidget {
  /// Total money saved in yuan since the quit date.
  final double totalSavedYuan;

  /// Money saved today (daily cost avoided).
  final double dailySavedYuan;

  /// Number of days since the quit date.
  final int daysQuit;

  const MoneySavingsAnimator({
    super.key,
    required this.totalSavedYuan,
    required this.dailySavedYuan,
    required this.daysQuit,
  });

  @override
  State<MoneySavingsAnimator> createState() => _MoneySavingsAnimatorState();
}

class _MoneySavingsAnimatorState extends State<MoneySavingsAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _counterController;
  late Animation<double> _counterAnimation;

  @override
  void initState() {
    super.initState();
    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _counterAnimation = CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutExpo,
    );
    // Start the counter animation on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _counterController.forward();
    });
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  /// Formats a yuan value to a compact display string.
  String _formatYuan(double value) {
    if (value >= 10000) {
      return '¥${(value / 10000).toStringAsFixed(value % 10000 == 0 ? 0 : 1)}万';
    }
    return '¥${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}';
  }

  /// Full display for the animated counter.
  String _formatCounter(double value) {
    // Show integer for clean animation
    return '¥${value.round().toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = Theme.of(context).extension<AppSpacing>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final r = spacing?.cardRadius ?? 16;
    final p = spacing?.cardPadding ?? 16;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r),
      ),
      child: Padding(
        padding: EdgeInsets.all(p),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(
                      spacing?.iconRadius ?? 10,
                    ),
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    size: 18,
                    color: Color(0xFFFFB300),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '已省下',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
                const Spacer(),
                // Days badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius:
                        BorderRadius.circular(spacing?.chipRadius ?? 20),
                  ),
                  child: Text(
                    '${widget.daysQuit} 天',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: spacing?.md ?? 16),

            // Coin stack visual + counter
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Coin jar painter
                SizedBox(
                  width: 120,
                  height: 140,
                  child: AnimatedBuilder(
                    animation: _counterAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _CoinStackPainter(
                          animatedValue:
                              widget.totalSavedYuan * _counterAnimation.value,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Counter column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big animated number
                      AnimatedBuilder(
                        animation: _counterAnimation,
                        builder: (context, _) {
                          final current =
                              widget.totalSavedYuan * _counterAnimation.value;
                          return Text(
                            _formatCounter(current),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFFB300),
                                  height: 1.1,
                                ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      // Subtitle: today saved
                      Text(
                        '今天省了 ¥${widget.dailySavedYuan.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFFB300).withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '坚持每一天，积少成多',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Milestone progress bar
            SizedBox(height: spacing?.sm ?? 12),
            _buildMilestoneBar(colorScheme, spacing),
          ],
        ),
      ),
    );
  }

  /// A thin bar showing progress towards the next savings milestone.
  Widget _buildMilestoneBar(ColorScheme colorScheme, AppSpacing? spacing) {
    const milestones = [1000.0, 5000.0, 10000.0, 50000.0, 100000.0];

    // Find current milestone range
    double lower = 0;
    double upper = 1000.0;
    for (var i = 0; i < milestones.length; i++) {
      if (widget.totalSavedYuan >= milestones[i]) {
        lower = milestones[i];
        upper = i + 1 < milestones.length ? milestones[i + 1] : milestones[i] * 2;
      } else {
        lower = i > 0 ? milestones[i - 1] : 0;
        upper = milestones[i];
        break;
      }
    }

    final progress = ((widget.totalSavedYuan - lower) / (upper - lower))
        .clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '下一个目标',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              _formatYuan(upper),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)),
          ),
        ),
      ],
    );
  }
}