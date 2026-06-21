import 'package:flutter/material.dart';

/// Displays the most recent craving logs that have associated
/// location, social context, or activity data (up to 10 entries).
class RecentSceneLogs extends StatelessWidget {
  final List<Map<String, dynamic>> logs;

  const RecentSceneLogs({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
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
