import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/widgets/widget_service.dart';
import '../../../domain/entity/daily_log.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  int _mood = 3;
  int? _urgeLevel;
  bool _relapsed = false;
  int? _consumption;
  final _consumptionController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;
  bool _loading = true;
  bool _alreadyLogged = false;
  DailyLogEntry? _existingLog;

  static const _moodOptions = [
    {'emoji': '😢', 'value': 1},
    {'emoji': '😐', 'value': 3},
    {'emoji': '😊', 'value': 5},
  ];

  static const _urgeOptions = [
    {'label': '几乎没有', 'value': 1},
    {'label': '有一点', 'value': 3},
    {'label': '非常想', 'value': 5},
  ];

  @override
  void initState() {
    super.initState();
    _checkTodayLog();
  }

  @override
  void dispose() {
    _consumptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkTodayLog() async {
    try {
      final log = await ref.read(logUseCaseProvider).getTodayLog();
      if (mounted) {
        setState(() {
          _existingLog = log;
          _alreadyLogged = log != null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveLog() async {
    if (_urgeLevel == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(logUseCaseProvider).logToday(
        mood: _mood,
        urgeLevel: _urgeLevel,
        relapsed: _relapsed,
        consumption: _consumption,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      final user = await ref.read(userUseCaseProvider).getCurrentUser();
      await WidgetService.updateWidget(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已保存'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日记录'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alreadyLogged
              ? _buildAlreadyLogged(theme)
              : _buildForm(theme),
    );
  }

  Widget _buildAlreadyLogged(ThemeData theme) {
    final log = _existingLog!;
    final moodEmoji = _moodOptions.firstWhere(
      (o) => o['value'] == log.mood,
      orElse: () => {'emoji': '😐', 'value': 3},
    )['emoji'] as String;

    final urgeLabel = _urgeOptions.firstWhere(
      (o) => o['value'] == log.urgeLevel,
      orElse: () => {'label': '', 'value': 0},
    )['label'] as String;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅ 今日已记录', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 32),
          Text(moodEmoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          if (urgeLabel.isNotEmpty)
            Text(
              '想抽/喝程度: $urgeLabel',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('回去'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今天感觉怎么样？', style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _moodOptions.map((opt) {
                final value = opt['value'] as int;
                final selected = _mood == value;
                return GestureDetector(
                  onTap: () => setState(() => _mood = value),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? primary : Colors.grey.shade300,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        opt['emoji'] as String,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 48),
          Text('今天有想抽/喝吗？', style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _urgeOptions.map((opt) {
                final value = opt['value'] as int;
                final selected = _urgeLevel == value;
                return GestureDetector(
                  onTap: () => setState(() => _urgeLevel = value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: selected ? primary : Colors.transparent,
                      border: Border.all(
                        color: selected ? primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      opt['label'] as String,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 48),
          Text('今天有使用吗？', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _relapsed = false;
                  _consumption = null;
                  _consumptionController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: !_relapsed ? primary : Colors.transparent,
                    border: Border.all(
                      color: !_relapsed ? primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    '没有',
                    style: TextStyle(
                      color: !_relapsed ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _relapsed = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _relapsed ? primary : Colors.transparent,
                    border: Border.all(
                      color: _relapsed ? primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    '有',
                    style: TextStyle(
                      color: _relapsed ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_relapsed) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _consumptionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '支/杯',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (v) {
                  _consumption = int.tryParse(v);
                },
              ),
            ),
          ],
          const SizedBox(height: 48),
          Text(
            '想补充什么吗？',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: '可选',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _urgeLevel != null && !_saving ? _saveLog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Text('完成 ✓', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
