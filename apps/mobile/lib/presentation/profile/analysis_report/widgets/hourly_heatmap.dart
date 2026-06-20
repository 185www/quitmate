import 'dart:math';
import 'package:flutter/material.dart';

/// A heatmap-style visualization showing craving distribution across
/// six 4-hour time blocks of the day.
class HourlyHeatmap extends StatelessWidget {
  /// 24-element list where index = hour (0-23) and value = craving count.
  final List<int> hourlyCounts;

  const HourlyHeatmap({
    super.key,
    required this.hourlyCounts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxCount = hourlyCounts.fold(0, max);

    // Group into 6 time blocks of 4 hours each
    final timeBlocks = <Map<String, dynamic>>[];
    final blockLabels = ['0-4时', '4-8时', '8-12时', '12-16时', '16-20时', '20-24时'];
    final blockIcons = [
      Icons.nightlight,
      Icons.bedtime,
      Icons.wb_sunny,
      Icons.wb_cloudy,
      Icons.wb_twilight,
      Icons.nights_stay
    ];

    for (int i = 0; i < 6; i++) {
      final start = i * 4;
      final end = start + 4;
      final blockCount =
          hourlyCounts.sublist(start, end).fold(0, (a, b) => a + b);
      timeBlocks.add({
        'label': blockLabels[i],
        'icon': blockIcons[i],
        'count': blockCount,
      });
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
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                Text('时段分布',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...timeBlocks.map((block) {
              final blockCount = block['count'] as int;
              final pct = maxCount > 0 ? blockCount / maxCount : 0.0;
              final isActive = blockCount > 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Row(
                        children: [
                          Icon(block['icon'] as IconData,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            block['label'] as String,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 20,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              if (isActive)
                                FractionallySizedBox(
                                  widthFactor: pct.clamp(0.05, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: pct > 0.7
                                          ? Colors.red.shade300
                                          : pct > 0.4
                                              ? Colors.orange.shade300
                                              : Colors.green.shade300,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$blockCount次',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
