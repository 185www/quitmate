import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出数据'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '导出选项',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('PDF报告'),
                      subtitle: const Text('生成包含图表的PDF报告'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportPDF(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.table_chart),
                      title: const Text('CSV数据'),
                      subtitle: const Text('导出原始数据为CSV格式'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportCSV(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('JSON数据'),
                      subtitle: const Text('导出完整数据为JSON格式'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportJSON(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '说明',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '• 导出的数据仅存储在本地设备\n'
              '• 你可以通过分享功能发送给自己或备份\n'
              '• 所有数据都是匿名的，不包含个人信息',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _exportPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF报告生成中...')),
    );
  }

  void _exportCSV(BuildContext context) {
    final data = '日期,渴望程度,诱因,应对方式,是否复发\n';
    Share.share(data, subject: 'QuitMate数据导出');
  }

  void _exportJSON(BuildContext context) {
    final data = jsonEncode({
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'records': [],
    });
    Share.share(data, subject: 'QuitMate数据导出');
  }
}