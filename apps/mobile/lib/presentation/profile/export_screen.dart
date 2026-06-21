import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../../core/di/providers.dart';
import '../../domain/entity/user.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
                    Text('导出选项',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('JSON导出'),
                      subtitle: const Text('完整数据，可用于备份'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportJSON(context, ref),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.table_chart),
                      title: const Text('CSV导出'),
                      subtitle: const Text('表格格式，可用Excel打开'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportCSV(context, ref),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('报告摘要'),
                      subtitle: const Text('文本格式的统计摘要'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportReport(context, ref),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('说明',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '• 导出的数据仅存储在本地设备\n'
                      '• 你可以通过分享功能发送给自己或备份到云端\n'
                      '• 所有数据均为匿名，不包含可识别个人信息',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportJSON(BuildContext context, WidgetRef ref) async {
    try {
      final user = await ref.read(userUseCaseProvider).getCurrentUser();
      final logs = await ref.read(logUseCaseProvider).getAllLogs(limit: 365);

      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.7.0',
        'appName': 'QuitMate',
        'user': user != null
            ? {
                'id': user.id,
                'targetType': user.targetType.name,
                'stage': user.stage.name,
                'quitDate': user.quitDate?.toIso8601String(),
                'daysSinceQuit': user.daysSinceQuit,
                'fagerstromScore': user.fagerstromScore,
                'auditScore': user.auditScore,
                'dailyCost': user.dailyCost,
                'estimatedDailyCigarettes': user.estimatedDailyCigarettes,
                'estimatedDailyDrinks': user.estimatedDailyDrinks,
                'dailyLifeRegainedMinutes': user.dailyLifeRegainedMinutes,
              }
            : null,
        'logs': logs
            .map((log) => {
                  'date': log.date.toIso8601String(),
                  'mood': log.mood,
                  'urgeLevel': log.urgeLevel,
                  'triggers': log.triggers,
                  'coping': log.coping,
                  'relapsed': log.relapsed,
                  'consumption': log.consumption,
                  'notes': log.notes,
                })
            .toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      await Share.share(jsonStr, subject: 'QuitMate数据导出(JSON)');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _exportCSV(BuildContext context, WidgetRef ref) async {
    try {
      final logs = await ref.read(logUseCaseProvider).getAllLogs(limit: 365);

      final buffer = StringBuffer();
      buffer.writeln('日期,情绪(1-5),渴望程度(0-10),触发因素,应对方式,是否复发,摄入量,备注');
      for (final log in logs) {
        final date =
            '${log.date.year}-${_pad(log.date.month)}-${_pad(log.date.day)}';
        final triggers = log.triggers?.join(';') ?? '';
        final coping = _escapeCsv(log.coping ?? '');
        final notes = _escapeCsv(log.notes ?? '');
        buffer.writeln(
            '$date,${log.mood},${log.urgeLevel ?? ''},"$triggers","$coping",${log.relapsed ? 1 : 0},${log.consumption ?? ''},"$notes"');
      }

      await Share.share(buffer.toString(), subject: 'QuitMate数据导出(CSV)');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
  String _escapeCsv(String s) => s.replaceAll('"', '""');

  Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
    try {
      final user = await ref.read(userUseCaseProvider).getCurrentUser();
      final logs = await ref.read(logUseCaseProvider).getAllLogs(limit: 365);
      final streak = await ref.read(logUseCaseProvider).getStreakDays();
      final abstinenceRate =
          await ref.read(logUseCaseProvider).getAbstinenceRate();
      final commonTriggers =
          await ref.read(logUseCaseProvider).getCommonTriggers();

      final relapseDays = logs.where((l) => l.relapsed).length;
      final totalDays = logs.length;
      final avgMood = logs.isEmpty
          ? 0
          : logs.map((l) => l.mood).reduce((a, b) => a + b) / logs.length;
      final avgUrge = logs.where((l) => l.urgeLevel != null).isEmpty
          ? 0
          : logs
                  .where((l) => l.urgeLevel != null)
                  .map((l) => l.urgeLevel!)
                  .reduce((a, b) => a + b) /
              logs.where((l) => l.urgeLevel != null).length;

      final buffer = StringBuffer();
      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln('        QuitMate 数据报告摘要');
      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln();
      buffer.writeln(
          '报告生成时间: ${DateTime.now().toLocal().toString().substring(0, 19)}');
      buffer.writeln();
      if (user != null) {
        buffer.writeln('--- 用户信息 ---');
        buffer.writeln('目标类型: ${_targetLabel(user.targetType)}');
        buffer.writeln('当前阶段: ${_stageLabel(user.stage)}');
        buffer.writeln('戒断天数: ${user.daysSinceQuit}天');
        if (user.quitDate != null)
          buffer.writeln(
              '开始日期: ${user.quitDate!.toLocal().toString().substring(0, 10)}');
        buffer.writeln('日均节省: ¥${user.dailyCost.toStringAsFixed(1)}');
        buffer.writeln(
            '累计节省: ¥${(user.dailyCost * user.daysSinceQuit).toStringAsFixed(1)}');
        buffer.writeln();
      }
      buffer.writeln('--- 记录统计 ---');
      buffer.writeln('总记录天数: $totalDays天');
      buffer.writeln('当前连续: $streak天');
      buffer.writeln('戒断率: ${(abstinenceRate * 100).toStringAsFixed(1)}%');
      buffer.writeln('复发次数: $relapseDays次');
      buffer.writeln('平均情绪: ${avgMood.toStringAsFixed(1)}/5');
      buffer.writeln('平均渴望: ${avgUrge.toStringAsFixed(1)}/10');
      buffer.writeln();
      if (commonTriggers.isNotEmpty) {
        buffer.writeln('--- 常见触发因素 ---');
        for (final t in commonTriggers) {
          buffer.writeln('  • $t');
        }
        buffer.writeln();
      }
      buffer.writeln('--- 健康里程碑 ---');
      for (final m in HealthMilestone.milestones) {
        final days = m['days'] as int;
        if (user != null && user.daysSinceQuit >= days) {
          buffer.writeln('  ✓ [${_milestoneIcon(days)}] ${m['title']}');
        }
      }
      buffer.writeln();
      buffer.writeln('--- 研究参考 ---');
      buffer.writeln('• Chaiton et al. (BMJ Open, 2016) - 平均需要6-30次尝试');
      buffer.writeln('• Prochaska & DiClemente - 行为改变阶段理论');
      buffer.writeln('• CDC - 戒烟后身体恢复时间线');
      buffer.writeln('• Cochrane Database - CBT有效性');
      buffer.writeln('• Ussher et al. - 运动减少渴求强度');
      buffer.writeln();
      buffer.writeln('数据来源: QuitMate v1.7.0');
      buffer.writeln('═══════════════════════════════════════');

      await Share.share(buffer.toString(), subject: 'QuitMate数据报告');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  String _targetLabel(TargetType t) {
    switch (t) {
      case TargetType.smoking:
        return '戒烟';
      case TargetType.alcohol:
        return '戒酒';
      case TargetType.both:
        return '戒烟戒酒';
    }
  }

  String _stageLabel(UserStage s) {
    switch (s) {
      case UserStage.preContemplation:
        return '前 contemplation';
      case UserStage.contemplation:
        return '思考期';
      case UserStage.preparation:
        return '准备期';
      case UserStage.action:
        return '行动期';
      case UserStage.maintenance:
        return '维持期';
    }
  }

  String _milestoneIcon(int days) {
    if (days < 1) return '20分钟';
    if (days < 7) return '$days天';
    if (days < 30) return '${days ~/ 7}周';
    if (days < 365) return '${days ~/ 30}月';
    return '${days ~/ 365}年';
  }
}
