import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import 'widgets/analysis_section_card.dart';
import 'widgets/summary_cards_row.dart';
import 'widgets/personalized_insights_card.dart';
import 'widgets/weekly_trend_chart.dart';
import 'widgets/hourly_heatmap.dart';
import 'widgets/pattern_triangle.dart';
import 'widgets/recent_scene_logs.dart';

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
                SummaryCardsRow(
                  count: count,
                  avg: avg,
                  thisWeekCount: thisWeekCount,
                  lastWeekCount: lastWeekCount,
                ),
                const SizedBox(height: 16),

                // Personalized insights
                if (logs.isNotEmpty) ...[
                  PersonalizedInsightsCard(
                    triggers: triggers,
                    socials: socials,
                    topCoping: topCoping,
                    hourlyCounts: hourlyCounts,
                    thisWeekAvg: thisWeekAvg,
                    lastWeekAvg: lastWeekAvg,
                  ),
                  const SizedBox(height: 16),
                ],

                // Weekly trend bar chart
                WeeklyTrendChart(weeklyTrend: weeklyTrend),
                const SizedBox(height: 16),

                // Time-of-day heatmap
                if (logs.isNotEmpty)
                  HourlyHeatmap(hourlyCounts: hourlyCounts),
                if (logs.isNotEmpty) const SizedBox(height: 16),

                // Trigger → Craving → Coping triangle
                if (triggers.isNotEmpty && topCoping.isNotEmpty)
                  PatternTriangle(
                    triggers: triggers,
                    topCoping: topCoping,
                    socials: socials,
                    activities: activities,
                  ),
                if (triggers.isNotEmpty && topCoping.isNotEmpty)
                  const SizedBox(height: 16),

                // Existing sections
                if (triggers.isNotEmpty)
                  AnalysisSectionCard(
                      title: '常见诱因', items: triggers, icon: Icons.bolt),
                if (locations.isNotEmpty)
                  AnalysisSectionCard(
                      title: '高危地点',
                      items: locations,
                      icon: Icons.place),
                if (socials.isNotEmpty)
                  AnalysisSectionCard(
                      title: '高危社交场景',
                      items: socials,
                      icon: Icons.people),
                if (activities.isNotEmpty)
                  AnalysisSectionCard(
                      title: '高危活动',
                      items: activities,
                      icon: Icons.sports_esports),
                if (logs.any((l) =>
                    l['location'] != null ||
                    l['social_context'] != null ||
                    l['activity'] != null))
                  RecentSceneLogs(logs: logs),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
