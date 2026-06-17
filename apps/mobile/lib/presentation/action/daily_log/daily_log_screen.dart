import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  int _urgeLevel = 5;
  final List<String> _selectedTriggers = [];
  String _coping = '';
  bool _relapsed = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日记录'),
        actions: [
          TextButton(
            onPressed: _saveLog,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUrgeSection(),
            const SizedBox(height: 24),
            _buildTriggerSection(),
            const SizedBox(height: 24),
            _buildCopingSection(),
            const SizedBox(height: 24),
            _buildRelapseSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveLog,
                child: const Text('保存今日记录'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今天的渴望程度',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '0 = 完全没有，10 = 非常强烈',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _urgeLevel.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: _urgeLevel.toString(),
                onChanged: (value) {
                  setState(() => _urgeLevel = value.round());
                },
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                _urgeLevel.toString(),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTriggerSection() {
    final triggers = ['压力', '社交场合', '无聊', '愤怒', '疲惫', '饭后', '看到别人使用', '其他'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '诱因（可多选）',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: triggers.map((trigger) {
            final selected = _selectedTriggers.contains(trigger);
            return FilterChip(
              label: Text(trigger),
              selected: selected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTriggers.add(trigger);
                  } else {
                    _selectedTriggers.remove(trigger);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCopingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '应对方式',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '你是如何应对渴望的？',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _coping = value,
        ),
      ],
    );
  }

  Widget _buildRelapseSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今天有复发吗？',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '没关系，这只是过程的一部分',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Switch(
          value: _relapsed,
          onChanged: (value) => setState(() => _relapsed = value),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日感想',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '记录今天的心情、成就或困难...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Future<void> _saveLog() async {
    final logUseCase = ref.read(logUseCaseProvider);
    await logUseCase.logToday(
      urgeLevel: _urgeLevel,
      triggers: _selectedTriggers.isNotEmpty ? _selectedTriggers : null,
      coping: _coping.isNotEmpty ? _coping : null,
      relapsed: _relapsed,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录已保存')),
      );
      Navigator.pop(context);
    }
  }
}