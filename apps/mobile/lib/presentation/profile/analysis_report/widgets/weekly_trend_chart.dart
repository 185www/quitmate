import 'dart:math';
import 'package:flutter/material.dart';

/// A bar chart showing craving intensity trends for the last 7 days.
/// Each bar is color-coded by intensity level.
class WeeklyTrendChart extends StatelessWidget {
  /// List of daily entries. Each map must contain:
  /// - `label` (String): day-of-week label
  /// - `avgIntensity` (double): average craving intensity for that day
  /// - `count` (int): number of craving logs for that day
  final List<Map<String, dynamic>> weeklyTrend;

  const WeeklyTrendChart({
    super.key,
    required this.weeklyTrend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxIntensity = weeklyTrend.fold<double>(
        0, (m, d) => max(m, (d['avgIntensity'] as double)));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 18),
                const SizedBox(width: 8),
                Text('本周渴望强度趋势',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weeklyTrend.map((day) {
                  final intensity = day['avgIntensity'] as double;
                  final label = day['label'] as String;
                  final count = day['count'] as int;
                  final height =
                      maxIntensity > 0 ? (intensity / maxIntensity * 120) : 0.0;

                  // Color based on intensity
                  Color barColor;
                  if (intensity == 0) {
                    barColor = colorScheme.surfaceContainerHighest;
                  } else if (intensity <= 3) {
                    barColor = Colors.green;
                  } else if (intensity <= 6) {
                    barColor = Colors.orange;
                  } else {
                    barColor = Colors.red;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Intensity value
                          if (intensity > 0)
                            Text(
                              intensity.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 4),
                          // Bar
                          Container(
                            height: max(height, count > 0 ? 8.0 : 2.0),
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Day label
                          Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          // Count
                          if (count > 0)
                            Text(
                              '$count次',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
