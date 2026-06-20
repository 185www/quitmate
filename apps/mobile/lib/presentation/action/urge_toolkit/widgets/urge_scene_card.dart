import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// 冲浪场景数据模型
class UrgeSurfScene {
  final String id;
  final String name;
  final String description;
  final String techniqueName;
  final int requiredStreakDays;
  final List<Color> gradientColors;
  final List<Color> darkGradientColors;
  final _SceneType sceneType;

  const UrgeSurfScene({
    required this.id,
    required this.name,
    required this.description,
    required this.techniqueName,
    required this.requiredStreakDays,
    required this.gradientColors,
    required this.darkGradientColors,
    required this.sceneType,
  });

  /// 是否已解锁
  bool isUnlocked(int currentStreak) => currentStreak >= requiredStreakDays;
}

/// 场景绘制类型
enum _SceneType { beach, forest, starry, snow }

/// 预设的4个冲浪场景
final kUrgeSurfScenes = <UrgeSurfScene>[
  UrgeSurfScene(
    id: 'beach',
    name: '海滩',
    description: '海浪拍打岸边，感受潮起潮落',
    techniqueName: '海浪冲浪',
    requiredStreakDays: 0,
    gradientColors: const [
      Color(0xFF80DEEA),
      Color(0xFF4DD0E1),
      Color(0xFF26C6DA),
    ],
    darkGradientColors: const [
      Color(0xFF0D2F2A),
      Color(0xFF1A5C52),
      Color(0xFF0D3B4F),
    ],
    sceneType: _SceneType.beach,
  ),
  UrgeSurfScene(
    id: 'forest',
    name: '森林',
    description: '树叶沙沙作响，呼吸自然清新',
    techniqueName: '森林呼吸',
    requiredStreakDays: 7,
    gradientColors: const [
      Color(0xFFA5D6A7),
      Color(0xFF66BB6A),
      Color(0xFF388E3C),
    ],
    darkGradientColors: const [
      Color(0xFF0D2818),
      Color(0xFF1B4332),
      Color(0xFF0D2F2A),
    ],
    sceneType: _SceneType.forest,
  ),
  UrgeSurfScene(
    id: 'starry',
    name: '星空',
    description: '仰望星空，感受宇宙的宁静',
    techniqueName: '星空冥想',
    requiredStreakDays: 30,
    gradientColors: const [
      Color(0xFF7986CB),
      Color(0xFF5C6BC0),
      Color(0xFF283593),
    ],
    darkGradientColors: const [
      Color(0xFF0D0D2B),
      Color(0xFF1A1A4E),
      Color(0xFF0D1B2A),
    ],
    sceneType: _SceneType.starry,
  ),
  UrgeSurfScene(
    id: 'snow',
    name: '雪山',
    description: '纯净雪原，洗涤心灵的净土',
    techniqueName: '雪山净土',
    requiredStreakDays: 90,
    gradientColors: const [
      Color(0xFFB3E5FC),
      Color(0xFF81D4FA),
      Color(0xFFE0F7FA),
    ],
    darkGradientColors: const [
      Color(0xFF0D1B2A),
      Color(0xFF1B3A5C),
      Color(0xFF152238),
    ],
    sceneType: _SceneType.snow,
  ),
];

/// 渐进解锁不同冲浪场景 — 海滩/森林/星空/雪山
///
/// 单张场景卡片，展示场景插画、名称、描述、解锁状态。
/// 选中场景有高亮边框。
class UrgeSceneCard extends StatelessWidget {
  final UrgeSurfScene scene;
  final int currentStreakDays;
  final bool isSelected;
  final VoidCallback? onTap;

  const UrgeSceneCard({
    super.key,
    required this.scene,
    required this.currentStreakDays,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnlocked = scene.isUnlocked(currentStreakDays);
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.cardRadius),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.5,
                )
              : isUnlocked
                  ? Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    )
                  : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(spacing.cardRadius),
          child: Stack(
            children: [
              // ── 场景背景插画 ──
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SceneBackgroundPainter(
                    sceneType: scene.sceneType,
                    gradientColors: isDark
                        ? scene.darkGradientColors
                        : scene.gradientColors,
                    isUnlocked: isUnlocked,
                    isDark: isDark,
                  ),
                ),
              ),

              // ── 锁定遮罩 ──
              if (!isUnlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.55)
                          : Colors.white.withOpacity(0.5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 32,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black.withOpacity(0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '连续 ${scene.requiredStreakDays} 天解锁',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── 选中指示器 ──
              if (isSelected && isUnlocked)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(spacing.chipRadius),
                    ),
                    child: const Text(
                      '使用中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // ── 底部信息 ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    spacing.cardPadding,
                    24,
                    spacing.cardPadding,
                    spacing.cardPadding,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        isDark
                            ? Colors.black.withOpacity(0.7)
                            : Colors.white.withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            scene.name,
                            style: TextStyle(
                              color: isUnlocked
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? colors.coachColor
                                      : colors.coachColor)
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(spacing.chipRadius),
                            ),
                            child: Text(
                              scene.techniqueName,
                              style: TextStyle(
                                color: colors.coachColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scene.description,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(isUnlocked ? 0.65 : 0.35),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 场景背景 CustomPainter — 简化场景插画
// ═══════════════════════════════════════════════════════════════════════════════

class _SceneBackgroundPainter extends CustomPainter {
  final _SceneType sceneType;
  final List<Color> gradientColors;
  final bool isUnlocked;
  final bool isDark;

  _SceneBackgroundPainter({
    required this.sceneType,
    required this.gradientColors,
    required this.isUnlocked,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── 基础渐变背景 ──
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (!isUnlocked) {
      // 未解锁时简化绘制
      return;
    }

    switch (sceneType) {
      case _SceneType.beach:
        _drawBeach(canvas, size);
        break;
      case _SceneType.forest:
        _drawForest(canvas, size);
        break;
      case _SceneType.starry:
        _drawStarry(canvas, size);
        break;
      case _SceneType.snow:
        _drawSnow(canvas, size);
        break;
    }
  }

  // ── 海滩场景 ──
  void _drawBeach(Canvas canvas, Size size) {
    final opacity = isDark ? 0.2 : 0.15;

    // 海浪线
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.5 + i * 0.12);
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 4) {
        final wave = sin(x / 30 + i * 1.5) * 8;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, wavePaint);
    }

    // 太阳/月亮
    final sunPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.25 : 0.3);
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.22),
      20,
      sunPaint,
    );
  }

  // ── 森林场景 ──
  void _drawForest(Canvas canvas, Size size) {
    final treeOpacity = isDark ? 0.2 : 0.18;
    final treePaint = Paint()
      ..color = const Color(0xFF1B4332).withOpacity(treeOpacity);

    // 树木（简化三角形）
    for (int i = 0; i < 7; i++) {
      final x = size.width * (0.1 + i * 0.13);
      final baseY = size.height * 0.85;
      final treeHeight = 40 + (i % 3) * 15;
      final treeWidth = 20 + (i % 2) * 8;

      final path = Path();
      path.moveTo(x, baseY - treeHeight);
      path.lineTo(x - treeWidth, baseY);
      path.lineTo(x + treeWidth, baseY);
      path.close();
      canvas.drawPath(path, treePaint);
    }

    // 飘落的叶子
    final leafPaint = Paint()
      ..color = const Color(0xFF81C784).withOpacity(isDark ? 0.3 : 0.25);
    final rng = Random(123);
    for (int i = 0; i < 8; i++) {
      final lx = rng.nextDouble() * size.width;
      final ly = rng.nextDouble() * size.height * 0.7;
      canvas.drawCircle(Offset(lx, ly), 3, leafPaint);
    }
  }

  // ── 星空场景 ──
  void _drawStarry(Canvas canvas, Size size) {
    final rng = Random(456);

    // 星星
    for (int i = 0; i < 30; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height * 0.75;
      final starSize = 0.5 + rng.nextDouble() * 2;
      final starOpacity = 0.3 + rng.nextDouble() * 0.5;

      final starPaint = Paint()
        ..color = Colors.white.withOpacity(starOpacity);
      canvas.drawCircle(Offset(sx, sy), starSize, starPaint);
    }

    // 月亮
    final moonPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.3 : 0.35);
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.2),
      18,
      moonPaint,
    );
    // 月亮遮罩（做成弯月）
    final moonMaskPaint = Paint()
      ..color = const Color(0xFF1A1A4E).withOpacity(isDark ? 0.8 : 0.6);
    canvas.drawCircle(
      Offset(size.width * 0.78 + 8, size.height * 0.2 - 4),
      15,
      moonMaskPaint,
    );
  }

  // ── 雪山场景 ──
  void _drawSnow(Canvas canvas, Size size) {
    final mtOpacity = isDark ? 0.15 : 0.12;

    // 山峰
    final mountainPaint = Paint()
      ..color = const Color(0xFF37474F).withOpacity(mtOpacity + 0.1);

    // 大山
    final mt1 = Path();
    mt1.moveTo(size.width * 0.15, size.height * 0.85);
    mt1.lineTo(size.width * 0.35, size.height * 0.3);
    mt1.lineTo(size.width * 0.55, size.height * 0.85);
    mt1.close();
    canvas.drawPath(mt1, mountainPaint);

    // 小山
    final mt2 = Path();
    mt2.moveTo(size.width * 0.45, size.height * 0.85);
    mt2.lineTo(size.width * 0.7, size.height * 0.4);
    mt2.lineTo(size.width * 0.95, size.height * 0.85);
    mt2.close();
    canvas.drawPath(mt2, mountainPaint);

    // 雪花
    final snowPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.4 : 0.35);
    final rng = Random(789);
    for (int i = 0; i < 20; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height;
      final sSize = 1 + rng.nextDouble() * 2.5;
      canvas.drawCircle(Offset(sx, sy), sSize, snowPaint);
    }

    // 山顶积雪
    final snowCapPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.25 : 0.2);
    final cap1 = Path();
    cap1.moveTo(size.width * 0.28, size.height * 0.4);
    cap1.lineTo(size.width * 0.35, size.height * 0.3);
    cap1.lineTo(size.width * 0.42, size.height * 0.4);
    cap1.close();
    canvas.drawPath(cap1, snowCapPaint);
  }

  @override
  bool shouldRepaint(covariant _SceneBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.isUnlocked != isUnlocked ||
        oldDelegate.sceneType != sceneType;
  }
}