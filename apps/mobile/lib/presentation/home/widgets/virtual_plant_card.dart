/// Virtual Plant Card — 利用损失厌恶心理
///
/// Shows a virtual plant that grows based on the user's streak and level
/// progress. The plant progresses through 8 growth stages, uses
/// [CustomPainter] for the visual, and features a tap-to-sway animation
/// and a water-drop button linked to daily check-in.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Plant growth stage enum
// ─────────────────────────────────────────────────────────────────────────────

/// Describes the visual maturity of the virtual plant.
enum _PlantStage {
  /// 0 days — just a seed in soil
  seed,

  /// 1–3 days — a tiny sprout
  sprout,

  /// 4–7 days — small seedling
  smallPlant,

  /// 8–14 days — growing taller
  growing,

  /// 15–30 days — a young tree
  youngTree,

  /// 31–60 days — a proper tree
  tree,

  /// 61–90 days — tree with blossoms
  flowering,

  /// 91+ days — full bloom with many flowers
  fullBloom,
}

/// Maps streak days to the corresponding growth stage.
_PlantStage _stageFromStreak(int streakDays) {
  if (streakDays >= 91) return _PlantStage.fullBloom;
  if (streakDays >= 61) return _PlantStage.flowering;
  if (streakDays >= 31) return _PlantStage.tree;
  if (streakDays >= 15) return _PlantStage.youngTree;
  if (streakDays >= 8) return _PlantStage.growing;
  if (streakDays >= 4) return _PlantStage.smallPlant;
  if (streakDays >= 1) return _PlantStage.sprout;
  return _PlantStage.seed;
}

/// Human-readable Chinese label for each growth stage.
String _stageLabel(_PlantStage stage) => switch (stage) {
      _PlantStage.seed => '种子',
      _PlantStage.sprout => '嫩芽',
      _PlantStage.smallPlant => '小苗',
      _PlantStage.growing => '成长中',
      _PlantStage.youngTree => '小树',
      _PlantStage.tree => '大树',
      _PlantStage.flowering => '开花',
      _PlantStage.fullBloom => '繁花似锦',
    };

// ─────────────────────────────────────────────────────────────────────────────
// PlantPainter — CustomPainter for the virtual plant
// ─────────────────────────────────────────────────────────────────────────────

/// Paints the plant, pot, and soil. Adjusts visuals based on the growth
/// stage, level progress, and a sway offset for the tap animation.
class _PlantPainter extends CustomPainter {
  _PlantPainter({
    required this.stage,
    required this.levelProgress,
    this.swayOffset = 0.0,
    this.isDark = false,
    this.isWithering = false,
  });

  final _PlantStage stage;
  final double levelProgress;
  final double swayOffset;
  final bool isDark;
  final bool isWithering;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final potTop = size.height * 0.72;
    final soilY = potTop + 4;
    final baseY = potTop - 2;

    // Withering factor: 1.0 = healthy, 0.4 = wilted
    final healthFactor = isWithering ? 0.4 : 1.0;

    // ── Pot ────────────────────────────────────────────────────────────────
    _drawPot(canvas, cx, potTop, size);

    // ── Soil ───────────────────────────────────────────────────────────────
    _drawSoil(canvas, cx, soilY, size);

    // ── Plant ──────────────────────────────────────────────────────────────
    _drawPlant(canvas, cx, baseY, size, healthFactor);
  }

  void _drawPot(Canvas canvas, double cx, double potTop, Size size) {
    final potWidth = size.width * 0.5;
    final potHeight = size.height * 0.2;
    final rimHeight = 8.0;

    // Pot body (trapezoid)
    final potPath = Path()
      ..moveTo(cx - potWidth * 0.45, potTop + rimHeight)
      ..lineTo(cx - potWidth * 0.55, potTop + potHeight)
      ..lineTo(cx + potWidth * 0.55, potTop + potHeight)
      ..lineTo(cx + potWidth * 0.45, potTop + rimHeight)
      ..close();

    final potColor = isDark
        ? const Color(0xFF8D6E63).withOpacity(0.85)
        : const Color(0xFFA1887F);
    final potPaint = Paint()..color = potColor;
    canvas.drawPath(potPath, potPaint);

    // Pot rim
    final rimPath = Path()
      ..moveTo(cx - potWidth * 0.48, potTop)
      ..lineTo(cx + potWidth * 0.48, potTop)
      ..lineTo(cx + potWidth * 0.45, potTop + rimHeight)
      ..lineTo(cx - potWidth * 0.45, potTop + rimHeight)
      ..close();

    final rimColor = isDark
        ? const Color(0xFF795548).withOpacity(0.9)
        : const Color(0xFF8D6E63);
    canvas.drawPath(rimPath, Paint()..color = rimColor);
  }

  void _drawSoil(Canvas canvas, double cx, double soilY, Size size) {
    final potWidth = size.width * 0.5;
    canvas.drawEllipse(
      Rect.fromCenter(
        center: Offset(cx, soilY + 2),
        width: potWidth * 0.86,
        height: 10,
      ),
      Paint()..color = isDark ? const Color(0xFF4E342E) : const Color(0xFF6D4C41),
    );
  }

  void _drawPlant(
    Canvas canvas,
    double cx,
    double baseY,
    Size size,
    double healthFactor,
  ) {
    // Color palette based on health
    final stemColor = Color.lerp(
      const Color(0xFFA5D6A7),
      const Color(0xFF66BB6A),
      levelProgress,
    )!.withOpacity(healthFactor);

    final leafColor = Color.lerp(
      const Color(0xFF81C784),
      const Color(0xFF43A047),
      levelProgress,
    )!.withOpacity(healthFactor);

    final darkLeafColor = Color.lerp(
      const Color(0xFF66BB6A),
      const Color(0xFF2E7D32),
      levelProgress,
    )!.withOpacity(healthFactor);

    // Withering tint
    final witherColor = isDark
        ? const Color(0xFF795548)
        : const Color(0xFFA1887F);

    final actualStemColor = isWithering
        ? Color.lerp(stemColor, witherColor, 0.5)!
        : stemColor;
    final actualLeafColor = isWithering
        ? Color.lerp(leafColor, witherColor, 0.5)!
        : leafColor;

    // Sway rotation point at base
    canvas.save();
    canvas.translate(cx, baseY);
    canvas.rotate(swayOffset * 0.05);

    switch (stage) {
      case _PlantStage.seed:
        _drawSeed(canvas, size, actualLeafColor);
      case _PlantStage.sprout:
        _drawSprout(canvas, size, actualStemColor, actualLeafColor);
      case _PlantStage.smallPlant:
        _drawSmallPlant(canvas, size, actualStemColor, actualLeafColor, darkLeafColor);
      case _PlantStage.growing:
        _drawGrowing(canvas, size, actualStemColor, actualLeafColor, darkLeafColor);
      case _PlantStage.youngTree:
        _drawYoungTree(canvas, size, actualStemColor, actualLeafColor, darkLeafColor);
      case _PlantStage.tree:
        _drawTree(canvas, size, actualStemColor, actualLeafColor, darkLeafColor);
      case _PlantStage.flowering:
        _drawFlowering(canvas, size, actualStemColor, actualLeafColor, darkLeafColor);
      case _PlantStage.fullBloom:
        _drawFullBloom(canvas, size, actualStemColor, actualLeafColor, darkLeafColor);
    }

    canvas.restore();
  }

  // ── Individual stage painters ───────────────────────────────────────────

  void _drawSeed(Canvas canvas, Size size, Color color) {
    // Small seed shape in the soil
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -6), width: 12, height: 8),
      Paint()..color = color,
    );
  }

  void _drawSprout(Canvas canvas, Size size, Color stem, Color leaf) {
    final stemPaint = Paint()
      ..color = stem
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Stem
    canvas.drawLine(Offset.zero, const Offset(0, -35), stemPaint);

    // Two small leaves
    _drawLeaf(canvas, const Offset(0, -32), -0.5, 18, 8, leaf);
    _drawLeaf(canvas, const Offset(0, -28), 0.5, 16, 7, leaf);
  }

  void _drawSmallPlant(Canvas canvas, Size size, Color stem, Color leaf, Color dark) {
    final stemPaint = Paint()
      ..color = stem
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, const Offset(0, -55), stemPaint);

    _drawLeaf(canvas, const Offset(0, -50), -0.6, 22, 10, leaf);
    _drawLeaf(canvas, const Offset(0, -44), 0.6, 20, 9, leaf);
    _drawLeaf(canvas, const Offset(0, -36), -0.4, 16, 7, dark);
    _drawLeaf(canvas, const Offset(0, -30), 0.4, 14, 6, dark);
  }

  void _drawGrowing(Canvas canvas, Size size, Color stem, Color leaf, Color dark) {
    final stemPaint = Paint()
      ..color = stem
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, const Offset(0, -75), stemPaint);

    _drawLeaf(canvas, const Offset(0, -70), -0.5, 24, 11, leaf);
    _drawLeaf(canvas, const Offset(0, -62), 0.5, 22, 10, leaf);
    _drawLeaf(canvas, const Offset(0, -54), -0.6, 20, 9, dark);
    _drawLeaf(canvas, const Offset(0, -46), 0.6, 18, 8, dark);
    _drawLeaf(canvas, const Offset(0, -38), -0.3, 15, 7, leaf);
    _drawLeaf(canvas, const Offset(0, -32), 0.3, 13, 6, leaf);
  }

  void _drawYoungTree(Canvas canvas, Size size, Color stem, Color leaf, Color dark) {
    // Thicker trunk
    final trunkPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, const Offset(0, -90), trunkPaint);

    // Branch
    final branchPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(0, -65),
      const Offset(-18, -80),
      branchPaint,
    );
    canvas.drawLine(
      const Offset(0, -60),
      const Offset(16, -75),
      branchPaint,
    );

    // Canopy (multiple overlapping circles)
    _drawCanopy(canvas, const Offset(0, -100), 28, leaf);
    _drawCanopy(canvas, const Offset(-18, -90), 20, dark);
    _drawCanopy(canvas, const Offset(18, -88), 20, leaf);
    _drawCanopy(canvas, const Offset(-8, -108), 18, dark);
    _drawCanopy(canvas, const Offset(10, -105), 16, leaf);
  }

  void _drawTree(Canvas canvas, Size size, Color stem, Color leaf, Color dark) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, const Offset(0, -105), trunkPaint);

    // Branches
    final branchPaint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, -70), const Offset(-25, -90), branchPaint);
    canvas.drawLine(const Offset(0, -65), const Offset(22, -85), branchPaint);
    canvas.drawLine(const Offset(0, -85), const Offset(-15, -100), branchPaint);

    // Larger canopy
    _drawCanopy(canvas, const Offset(0, -118), 34, leaf);
    _drawCanopy(canvas, const Offset(-24, -105), 24, dark);
    _drawCanopy(canvas, const Offset(24, -103), 24, leaf);
    _drawCanopy(canvas, const Offset(-12, -130), 22, dark);
    _drawCanopy(canvas, const Offset(14, -126), 20, leaf);
    _drawCanopy(canvas, const Offset(0, -110), 26, leaf);
  }

  void _drawFlowering(Canvas canvas, Size size, Color stem, Color leaf, Color dark) {
    // Reuse tree base
    _drawTree(canvas, size, stem, leaf, dark);

    // Add flowers
    final flowerPositions = [
      const Offset(-20, -120),
      const Offset(18, -115),
      const Offset(-5, -135),
      const Offset(25, -105),
      const Offset(-25, -100),
    ];

    for (final pos in flowerPositions) {
      _drawFlower(canvas, pos, 5 + levelProgress * 3);
    }
  }

  void _drawFullBloom(Canvas canvas, Size size, Color stem, Color leaf, Color dark) {
    // Reuse tree base
    _drawTree(canvas, size, stem, leaf, dark);

    // Many flowers
    final flowerPositions = [
      const Offset(-20, -125),
      const Offset(18, -120),
      const Offset(-5, -140),
      const Offset(25, -108),
      const Offset(-28, -105),
      const Offset(10, -135),
      const Offset(-15, -110),
      const Offset(30, -118),
      const Offset(0, -115),
      const Offset(-10, -130),
    ];

    for (final pos in flowerPositions) {
      _drawFlower(canvas, pos, 5 + levelProgress * 2);
    }
  }

  // ── Helper drawing methods ──────────────────────────────────────────────

  void _drawLeaf(
    Canvas canvas,
    Offset origin,
    double angle,
    double length,
    double width,
    Color color,
  ) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -width, length, 0)
      ..quadraticBezierTo(length * 0.5, width, 0, 0);

    canvas.drawPath(path, Paint()..color = color);

    // Leaf vein
    canvas.drawLine(
      Offset.zero,
      Offset(length * 0.85, 0),
      Paint()
        ..color = color.withOpacity(0.5)
        ..strokeWidth = 0.8,
    );

    canvas.restore();
  }

  void _drawCanopy(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color);
    // Highlight
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.25),
      radius * 0.5,
      Paint()..color = color.withOpacity(0.3),
    );
  }

  void _drawFlower(Canvas canvas, Offset center, double size) {
    // Petals
    final petalColor = isDark
        ? const Color(0xFFF48FB1)
        : const Color(0xFFEC407A);
    final centerColor = isDark
        ? const Color(0xFFFFF176)
        : const Color(0xFFFFEB3B);

    for (var i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi) / 5;
      final px = center.dx + math.cos(angle) * size * 0.5;
      final py = center.dy + math.sin(angle) * size * 0.5;
      canvas.drawCircle(Offset(px, py), size * 0.4, Paint()..color = petalColor);
    }
    // Center
    canvas.drawCircle(center, size * 0.3, Paint()..color = centerColor);
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) {
    return oldDelegate.stage != stage ||
        oldDelegate.levelProgress != levelProgress ||
        oldDelegate.swayOffset != swayOffset ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isWithering != isWithering;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WaterDropAnimation — overlay for water feedback
// ─────────────────────────────────────────────────────────────────────────────

class _WaterDropPainter extends CustomPainter {
  _WaterDropPainter(this.progress);

  final double progress; // 0.0 → 1.0

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final cx = size.width / 2;
    final startY = size.height * 0.2;
    final endY = size.height * 0.7;

    // Animate drop falling
    final dropY = startY + (endY - startY) * progress;
    final alpha = progress < 0.8 ? 1.0 : (1.0 - progress) / 0.2;

    // Draw water drop
    final dropPath = Path()
      ..moveTo(cx, dropY - 8)
      ..quadraticBezierTo(cx + 7, dropY, cx, dropY + 6)
      ..quadraticBezierTo(cx - 7, dropY, cx, dropY - 8);

    canvas.drawPath(
      dropPath,
      Paint()..color = const Color(0xFF42A5F5).withOpacity(alpha * 0.7),
    );

    // Splash circles at impact point
    if (progress > 0.7) {
      final splashProgress = (progress - 0.7) / 0.3;
      for (var i = 0; i < 3; i++) {
        final r = (6.0 + i * 5) * splashProgress;
        final a = (1.0 - splashProgress) * 0.4;
        canvas.drawCircle(
          Offset(cx, endY),
          r,
          Paint()
            ..color = const Color(0xFF42A5F5).withOpacity(a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaterDropPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// VirtualPlantCard — Main widget
// ─────────────────────────────────────────────────────────────────────────────

/// A card showing a virtual plant that grows based on the user's streak.
///
/// Tapping the card triggers a gentle sway animation. The water-drop button
/// provides visual "watering" feedback linked to daily check-in.
///
/// Example:
/// ```dart
/// VirtualPlantCard(
///   streakDays: 15,
///   level: 5,
///   levelProgress: 0.6,
///   onWater: () => doCheckIn(),
/// )
/// ```
class VirtualPlantCard extends StatefulWidget {
  /// Current consecutive check-in streak in days.
  final int streakDays;

  /// Current game level of the user.
  final int level;

  /// Progress towards the next level (0.0 – 1.0).
  final double levelProgress;

  /// Whether the streak was broken within the last 2 days.
  /// When `true` the plant appears wilted to trigger loss aversion.
  final bool isWithering;

  /// Called when the water-drop button is tapped (intended for check-in).
  final VoidCallback? onWater;

  const VirtualPlantCard({
    super.key,
    required this.streakDays,
    required this.level,
    required this.levelProgress,
    this.isWithering = false,
    this.onWater,
  });

  @override
  State<VirtualPlantCard> createState() => _VirtualPlantCardState();
}

class _VirtualPlantCardState extends State<VirtualPlantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _swayController;
  late Animation<double> _swayAnimation;

  double _waterProgress = 0.0;
  bool _isWatering = false;

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _swayAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: -1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _swayController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _swayController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_swayController.isAnimating) return;
    _swayController.forward(from: 0.0);
  }

  void _onWater() {
    if (_isWatering) return;
    setState(() => _isWatering = true);
    _waterProgress = 0.0;

    // Simple frame-by-frame animation via periodic timer
    const totalDuration = Duration(milliseconds: 900);
    const frames = 45;
    var frame = 0;
    Future.doWhile(() async {
      await Future.delayed(totalDuration ~/ frames);
      frame++;
      if (!mounted) return false;
      setState(() {
        _waterProgress = frame / frames;
      });
      if (frame >= frames) {
        setState(() {
          _isWatering = false;
          _waterProgress = 0.0;
        });
        return false;
      }
      return true;
    });

    widget.onWater?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = Theme.of(context).extension<AppSpacing>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stage = _stageFromStreak(widget.streakDays);
    final r = spacing?.cardRadius ?? 16;
    final p = spacing?.cardPadding ?? 16;

    final careText = widget.streakDays > 0
        ? '连续 ${widget.streakDays} 天，你的植物正在成长'
        : '开始签到，种下你的第一颗种子吧';

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
            // Header row
            Row(
              children: [
                Icon(
                  Icons.eco_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '我的植物',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
                const Spacer(),
                // Stage pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius:
                        BorderRadius.circular(spacing?.chipRadius ?? 20),
                  ),
                  child: Text(
                    _stageLabel(stage),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: spacing?.sm ?? 12),

            // Plant canvas — tap to sway
            GestureDetector(
              onTap: _onTap,
              child: AnimatedBuilder(
                animation: _swayAnimation,
                builder: (context, child) {
                  return SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        // Main plant
                        CustomPaint(
                          size: const Size(double.infinity, 200),
                          painter: _PlantPainter(
                            stage: stage,
                            levelProgress: widget.levelProgress.clamp(0.0, 1.0),
                            swayOffset: _swayAnimation.value,
                            isDark: isDark,
                            isWithering: widget.isWithering,
                          ),
                        ),
                        // Water drop overlay
                        if (_isWatering)
                          CustomPaint(
                            size: const Size(double.infinity, 200),
                            painter: _WaterDropPainter(_waterProgress),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: spacing?.sm ?? 12),

            // Care reminder text
            Row(
              children: [
                Icon(
                  widget.isWithering
                      ? Icons.warning_amber_rounded
                      : Icons.water_drop_rounded,
                  size: 14,
                  color: widget.isWithering
                      ? (Theme.of(context).extension<AppColors>()
                              ?.warningColor ??
                          colorScheme.error)
                      : colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    careText,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: spacing?.xs ?? 8),

            // Water button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _onWater,
                icon: Icon(
                  Icons.water_drop_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                label: Text(
                  '浇水',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(spacing?.buttonRadius ?? 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}