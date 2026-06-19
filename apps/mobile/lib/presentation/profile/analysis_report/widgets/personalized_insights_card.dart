import 'package:flutter/material.dart';

/// A card that displays personalized insights based on craving data,
/// including most common trigger, peak hour, top coping method,
/// week-over-week intensity change, and social trigger.
class PersonalizedInsightsCard extends StatelessWidget {
  final List<MapEntry<String, int>> triggers;
  final List<MapEntry<String, int>> socials;
  final List<MapEntry<String, int>> topCoping;
  final List<int> hourlyCounts;
  final double thisWeekAvg;
  final double lastWeekAvg;

  const PersonalizedInsightsCard({
    super.key,
    required this.triggers,
    required this.socials,
    required this.topCoping,
    required this.hourlyCounts,
    required this.thisWeekAvg,
    required this.lastWeekAvg,
  });

  String _getHourRange(int peakHour) {
    final start = peakHour;
    final end = (peakHour + 1) % 24;
    return '$start:00-$end:00';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final insights = <(String, Icon)>[];

    // Most common trigger
    if (triggers.isNotEmpty) {
      insights.add(
        (
          '你最常因【${triggers.first.key}】感到渴望',
          Icon(Icons.bolt, size: 16, color: colorScheme.primary)
        ),
      );
    }

    // Peak hour
    int peakHour = 0;
    int peakCount = 0;
    for (int i = 0; i < hourlyCounts.length; i++) {
      if (hourlyCounts[i] > peakCount) {
        peakCount = hourlyCounts[i];
        peakHour = i;
      }
    }
    if (peakCount > 0) {
      final hourRange = _getHourRange(peakHour);
      insights.add(
        (
          '你的渴望高峰时间是【$hourRange】',
          Icon(Icons.access_time, size: 16, color: Colors.orange)
        ),
      );
    }

    // Most effective coping
    if (topCoping.isNotEmpty) {
      insights.add(
        (
          '你最常用的应对方式是【${topCoping.first.key}】',
          Icon(Icons.self_improvement, size: 16, color: Colors.teal)
        ),
      );
    }

    // Week-over-week intensity change
    if (lastWeekAvg > 0 && thisWeekAvg > 0) {
      final change = ((thisWeekAvg - lastWeekAvg) / lastWeekAvg * 100).round();
      final direction = change < 0 ? '下降' : '上升';
      insights.add(
        (
          '本周渴求强度比上周【$direction】了${change.abs()}%',
          Icon(change < 0 ? Icons.trending_down : Icons.trending_up,
              size: 16, color: change < 0 ? Colors.green : Colors.red)
        ),
      );
    }

    // Social trigger
    if (socials.isNotEmpty) {
      insights.add(
        (
          '社交场景中【${socials.first.key}】最容易触发渴望',
          Icon(Icons.people, size: 16, color: Colors.purple)
        ),
      );
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
                const Icon(Icons.lightbulb, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Text('个性化洞察',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...insights.map((item) {
              final text = item.$1;
              final icon = item.$2;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: icon,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
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
