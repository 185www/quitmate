import 'package:flutter/material.dart';

/// Row of three summary statistic cards: total cravings, average intensity,
/// and week-over-week trend.
class SummaryCardsRow extends StatelessWidget {
  final int count;
  final double avg;
  final int thisWeekCount;
  final int lastWeekCount;

  const SummaryCardsRow({
    super.key,
    required this.count,
    required this.avg,
    required this.thisWeekCount,
    required this.lastWeekCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trendPct = lastWeekCount > 0
        ? ((thisWeekCount - lastWeekCount) / lastWeekCount * 100)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('$count',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('总渴望次数',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(avg.toStringAsFixed(1),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('平均强度 / 10',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (trendPct != 0)
                        Icon(
                          trendPct < 0
                              ? Icons.trending_down
                              : Icons.trending_up,
                          size: 20,
                          color: trendPct < 0 ? Colors.green : Colors.red,
                        )
                      else
                        const Icon(Icons.remove, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${trendPct.abs().toStringAsFixed(0)}%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: trendPct < 0
                                  ? Colors.green
                                  : (trendPct > 0 ? Colors.red : null),
                            ),
                      ),
                    ],
                  ),
                  Text('本周趋势',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
