import 'package:flutter/material.dart';

/// A triangular visualization showing the relationship between the top
/// trigger, most common context/scene, and top coping method.
class PatternTriangle extends StatelessWidget {
  final List<MapEntry<String, int>> triggers;
  final List<MapEntry<String, int>> topCoping;
  final List<MapEntry<String, int>> socials;
  final List<MapEntry<String, int>> activities;

  const PatternTriangle({
    super.key,
    required this.triggers,
    required this.topCoping,
    required this.socials,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final topTrigger = triggers.first;
    final topCopingMethod = topCoping.isNotEmpty ? topCoping.first : null;

    // Get second dimension for pattern
    String? patternContext;
    if (socials.isNotEmpty) {
      patternContext = socials.first.key;
    } else if (activities.isNotEmpty) {
      patternContext = activities.first.key;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree, size: 18),
                const SizedBox(width: 8),
                Text('模式三角',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '最常见模式',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Triangle visualization
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Connection lines
                  CustomPaint(
                    size: const Size(300, 180),
                    painter: _TriangleLinesPainter(
                        color: colorScheme.outlineVariant.withOpacity(0.3)),
                  ),
                  // Top node: Trigger
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _PatternNode(
                      label: topTrigger.key,
                      sublabel: '${topTrigger.value}次',
                      icon: Icons.bolt,
                      color: Colors.red,
                      bgColor: Colors.red.shade50,
                    ),
                  ),
                  // Bottom-left: Context
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: SizedBox(
                      width: 140,
                      child: _PatternNode(
                        label: patternContext ?? '未记录',
                        sublabel: '场景',
                        icon: Icons.place,
                        color: Colors.orange,
                        bgColor: Colors.orange.shade50,
                      ),
                    ),
                  ),
                  // Bottom-right: Coping
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: SizedBox(
                      width: 140,
                      child: _PatternNode(
                        label: topCopingMethod?.key ?? '未记录',
                        sublabel: topCopingMethod != null
                            ? '${topCopingMethod.value}次'
                            : '应对',
                        icon: Icons.self_improvement,
                        color: Colors.teal,
                        bgColor: Colors.teal.shade50,
                      ),
                    ),
                  ),
                  // Center arrow labels
                  Positioned(
                    top: 48,
                    left: 12,
                    child: Icon(Icons.arrow_downward,
                        size: 14,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  ),
                  Positioned(
                    top: 48,
                    right: 12,
                    child: Icon(Icons.arrow_downward,
                        size: 14,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  ),
                  Positioned(
                    bottom: 38,
                    child: Icon(Icons.arrow_back,
                        size: 14,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
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

// ──────────────────────────────────────────────────────────
// Pattern Node Widget
// ──────────────────────────────────────────────────────────
class _PatternNode extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _PatternNode({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sublabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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

// ──────────────────────────────────────────────────────────
// Triangle Lines Painter
// ──────────────────────────────────────────────────────────
class _TriangleLinesPainter extends CustomPainter {
  final Color color;
  _TriangleLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final topCenter = Offset(size.width / 2, 30);
    final bottomLeft = Offset(70, size.height - 30);
    final bottomRight = Offset(size.width - 70, size.height - 30);

    canvas.drawLine(topCenter, bottomLeft, paint);
    canvas.drawLine(topCenter, bottomRight, paint);
    canvas.drawLine(bottomLeft, bottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleLinesPainter old) => old.color != color;
}
