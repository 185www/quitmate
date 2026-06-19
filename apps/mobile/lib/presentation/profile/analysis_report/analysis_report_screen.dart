import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';

class AnalysisReportScreen extends ConsumerStatefulWidget {
  const AnalysisReportScreen({super.key});

  @override
  ConsumerState<AnalysisReportScreen> createState() =>
      _AnalysisReportScreenState();
}

class _AnalysisReportScreenState extends ConsumerState<AnalysisReportScreen> {
  Future<Map<String, dynamic>> _loadData() async {
    final uc = ref.read(cravingUseCaseProvider);
    final count = await uc.getCravingCount();
    final avg = await uc.getAverageIntensity();
    final triggers = await uc.getTopTriggers();
    final scene = await uc.getSceneAnalysis();
    final logs = await uc.getAllRawLogs();

    // Compute week-over-week comparison
    final now = DateTime.now();
    final thisWeekStart = now
        .subtract(Duration(days: now.weekday - 1))
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart;

    await uc.getCravingCount(since: thisWeekStart);
    await uc.getCravingCount(since: lastWeekStart);
    // Recompute lastWeekCount as count between lastWeekStart and lastWeekEnd
    final allLogs = await uc.getAllRawLogs();
    final lastWeekLogs = allLogs.where((l) {
      final t = DateTime.parse(l['timestamp'] as String);
      return !t.isBefore(lastWeekStart) && t.isBefore(lastWeekEnd);
    }).toList();

    // Weekly trend: last 7 days craving intensity
    final weeklyTrend = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart =
          day.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayLogs = allLogs.where((l) {
        final t = DateTime.parse(l['timestamp'] as String);
        return !t.isBefore(dayStart) && t.isBefore(dayEnd);
      }).toList();
      final dayAvg = dayLogs.isEmpty
          ? 0.0
          : dayLogs.fold<double>(0, (s, l) => s + (l['intensity'] as int)) /
              dayLogs.length;
      weeklyTrend.add({
        'day': day,
        'label': ['一', '二', '三', '四', '五', '六', '日'][day.weekday - 1],
        'avgIntensity': dayAvg,
        'count': dayLogs.length,
      });
    }

    // Hourly heatmap
    final hourlyCounts = List.filled(24, 0);
    for (final l in allLogs) {
      final t = DateTime.parse(l['timestamp'] as String);
      hourlyCounts[t.hour]++;
    }

    // Top coping methods
    final copingCounts = <String, int>{};
    for (final l in allLogs) {
      final c = l['coping_used'] as String?;
      if (c != null && c.isNotEmpty)
        copingCounts[c] = (copingCounts[c] ?? 0) + 1;
    }
    final topCoping = copingCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Week-over-week intensity change
    final thisWeekLogs = allLogs.where((l) {
      final t = DateTime.parse(l['timestamp'] as String);
      return !t.isBefore(thisWeekStart);
    }).toList();
    final thisWeekAvg = thisWeekLogs.isEmpty
        ? 0.0
        : thisWeekLogs.fold<double>(0, (s, l) => s + (l['intensity'] as int)) /
            thisWeekLogs.length;
    final lastWeekAvg = lastWeekLogs.isEmpty
        ? 0.0
        : lastWeekLogs.fold<double>(0, (s, l) => s + (l['intensity'] as int)) /
            lastWeekLogs.length;

    return {
      'count': count,
      'avg': avg,
      'triggers': triggers,
      'scene': scene,
      'logs': logs,
      'weeklyTrend': weeklyTrend,
      'hourlyCounts': hourlyCounts,
      'topCoping': topCoping,
      'thisWeekCount': thisWeekLogs.length,
      'lastWeekCount': lastWeekLogs.length,
      'thisWeekAvg': thisWeekAvg,
      'lastWeekAvg': lastWeekAvg,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('行为分析报告')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          if (data == null) return const Center(child: Text('加载失败'));
          final count = data['count'] as int;
          final avg = data['avg'] as double;
          final triggers = data['triggers'] as List<MapEntry<String, int>>;
          final scene =
              data['scene'] as Map<String, List<MapEntry<String, int>>>;
          final logs = data['logs'] as List<Map<String, dynamic>>;
          final weeklyTrend = data['weeklyTrend'] as List<Map<String, dynamic>>;
          final hourlyCounts = data['hourlyCounts'] as List<int>;
          final topCoping = data['topCoping'] as List<MapEntry<String, int>>;
          final thisWeekCount = data['thisWeekCount'] as int;
          final lastWeekCount = data['lastWeekCount'] as int;
          final thisWeekAvg = data['thisWeekAvg'] as double;
          final lastWeekAvg = data['lastWeekAvg'] as double;

          final locations = scene['locations']!;
          final socials = scene['socials']!;
          final activities = scene['activities']!;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary cards
                _buildSummaryCards(count, avg, thisWeekCount, lastWeekCount),
                const SizedBox(height: 16),

                // Personalized insights
                if (logs.isNotEmpty) ...[
                  _buildInsightsCard(triggers, socials, topCoping, hourlyCounts,
                      thisWeekAvg, lastWeekAvg),
                  const SizedBox(height: 16),
                ],

                // Weekly trend bar chart
                _buildWeeklyTrend(weeklyTrend),
                const SizedBox(height: 16),

                // Time-of-day heatmap
                if (logs.isNotEmpty) _buildHourlyHeatmap(hourlyCounts),
                if (logs.isNotEmpty) const SizedBox(height: 16),

                // Trigger → Craving → Coping triangle
                if (triggers.isNotEmpty && topCoping.isNotEmpty)
                  _buildPatternTriangle(
                      triggers, topCoping, socials, activities),
                if (triggers.isNotEmpty && topCoping.isNotEmpty)
                  const SizedBox(height: 16),

                // Existing sections
                if (triggers.isNotEmpty)
                  _buildSection('常见诱因', triggers, Icons.bolt),
                if (locations.isNotEmpty)
                  _buildSection('高危地点', locations, Icons.place),
                if (socials.isNotEmpty)
                  _buildSection('高危社交场景', socials, Icons.people),
                if (activities.isNotEmpty)
                  _buildSection('高危活动', activities, Icons.sports_esports),
                if (logs.any((l) =>
                    l['location'] != null ||
                    l['social_context'] != null ||
                    l['activity'] != null))
                  _buildRecentLogs(logs),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Summary Cards
  // ──────────────────────────────────────────────────────────
  Widget _buildSummaryCards(
      int count, double avg, int thisWeekCount, int lastWeekCount) {
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

  // ──────────────────────────────────────────────────────────
  // Personalized Insights Card
  // ──────────────────────────────────────────────────────────
  Widget _buildInsightsCard(
    List<MapEntry<String, int>> triggers,
    List<MapEntry<String, int>> socials,
    List<MapEntry<String, int>> topCoping,
    List<int> hourlyCounts,
    double thisWeekAvg,
    double lastWeekAvg,
  ) {
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

  String _getHourRange(int peakHour) {
    // Find the surrounding hours that also have significant counts
    final start = peakHour;
    final end = (peakHour + 1) % 24;
    return '$start:00-$end:00';
  }

  // ──────────────────────────────────────────────────────────
  // Weekly Trend Bar Chart
  // ──────────────────────────────────────────────────────────
  Widget _buildWeeklyTrend(List<Map<String, dynamic>> weeklyTrend) {
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

  // ──────────────────────────────────────────────────────────
  // Time-of-day Heatmap
  // ──────────────────────────────────────────────────────────
  Widget _buildHourlyHeatmap(List<int> hourlyCounts) {
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

  // ──────────────────────────────────────────────────────────
  // Pattern Triangle: Trigger → Craving → Coping
  // ──────────────────────────────────────────────────────────
  Widget _buildPatternTriangle(
    List<MapEntry<String, int>> triggers,
    List<MapEntry<String, int>> topCoping,
    List<MapEntry<String, int>> socials,
    List<MapEntry<String, int>> activities,
  ) {
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

  // ──────────────────────────────────────────────────────────
  // Existing sections (kept from original)
  // ──────────────────────────────────────────────────────────
  Widget _buildSection(
      String title, List<MapEntry<String, int>> items, IconData icon) {
    final maxVal = items.first.value;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final pct = item.value / max(maxVal, 1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.key,
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('${item.value} 次',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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

  Widget _buildRecentLogs(List<Map<String, dynamic>> logs) {
    final sceneLogs = logs
        .where((l) =>
            l['location'] != null ||
            l['social_context'] != null ||
            l['activity'] != null)
        .take(10)
        .toList();
    if (sceneLogs.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 18),
                const SizedBox(width: 8),
                Text('最近场景记录',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...sceneLogs.map((l) {
              final ts = DateTime.parse(l['timestamp'] as String);
              final dateStr =
                  '${ts.month}/${ts.day} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}';
              final parts = [
                if (l['location'] != null) '📍 ${l['location']}',
                if (l['social_context'] != null) '👥 ${l['social_context']}',
                if (l['activity'] != null) '🎯 ${l['activity']}',
              ];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: (l['intensity'] as int) > 7
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  child: Text('${l['intensity']}',
                      style: TextStyle(
                          fontSize: 12,
                          color: (l['intensity'] as int) > 7
                              ? Colors.red
                              : Colors.blue)),
                ),
                title: Text('$dateStr · 强度 ${l['intensity']}/10',
                    style: const TextStyle(fontSize: 13)),
                subtitle: parts.isNotEmpty
                    ? Text(parts.join('  '),
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant))
                    : null,
              );
            }),
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
