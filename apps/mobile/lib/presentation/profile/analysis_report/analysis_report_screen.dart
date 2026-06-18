import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';

class AnalysisReportScreen extends ConsumerStatefulWidget {
  const AnalysisReportScreen({super.key});

  @override
  ConsumerState<AnalysisReportScreen> createState() => _AnalysisReportScreenState();
}

class _AnalysisReportScreenState extends ConsumerState<AnalysisReportScreen> {
  Future<Map<String, dynamic>> _loadData() async {
    final uc = ref.read(cravingUseCaseProvider);
    final count = await uc.getCravingCount();
    final avg = await uc.getAverageIntensity();
    final triggers = await uc.getTopTriggers();
    final scene = await uc.getSceneAnalysis();
    final logs = await uc.getAllRawLogs();
    return {
      'count': count,
      'avg': avg,
      'triggers': triggers,
      'scene': scene,
      'logs': logs,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('高危场景分析')),
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
          final scene = data['scene'] as Map<String, List<MapEntry<String, int>>>;
          final logs = data['logs'] as List<Map<String, dynamic>>;

          final locations = scene['locations']!;
          final socials = scene['socials']!;
          final activities = scene['activities']!;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCards(count, avg),
                const SizedBox(height: 16),
                if (triggers.isNotEmpty) _buildSection('常见诱因', triggers, Icons.bolt),
                if (locations.isNotEmpty) _buildSection('高危地点', locations, Icons.place),
                if (socials.isNotEmpty) _buildSection('高危社交场景', socials, Icons.people),
                if (activities.isNotEmpty) _buildSection('高危活动', activities, Icons.sports_esports),
                if (logs.any((l) => l['location'] != null || l['social_context'] != null || l['activity'] != null))
                  _buildRecentLogs(logs),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int count, double avg) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('$count', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('渴望次数', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                  Text(avg.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('平均强度 / 10', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<MapEntry<String, int>> items, IconData icon) {
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
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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
                        Text(item.key, style: Theme.of(context).textTheme.bodyMedium),
                        Text('${item.value} 次', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    final sceneLogs = logs.where((l) => l['location'] != null || l['social_context'] != null || l['activity'] != null).take(10).toList();
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
                Text('最近场景记录', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...sceneLogs.map((l) {
              final ts = DateTime.parse(l['timestamp'] as String);
              final dateStr = '${ts.month}/${ts.day} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}';
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
                  child: Text('${l['intensity']}', style: TextStyle(fontSize: 12, color: (l['intensity'] as int) > 7 ? Colors.red : Colors.blue)),
                ),
                title: Text('$dateStr · 强度 ${l['intensity']}/10', style: const TextStyle(fontSize: 13)),
                subtitle: parts.isNotEmpty
                    ? Text(parts.join('  '), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}
