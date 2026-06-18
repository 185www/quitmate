import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  int _mood = 3;
  int _urgeLevel = 5;
  final List<String> _selectedTriggers = [];
  final TextEditingController _copingController = TextEditingController();
  bool _relapsed = false;
  final TextEditingController _consumptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _saving = false;

  static const _moodOptions = [
    {'emoji': '😫', 'label': '非常差', 'value': 1},
    {'emoji': '😟', 'label': '差', 'value': 2},
    {'emoji': '😐', 'label': '一般', 'value': 3},
    {'emoji': '😊', 'label': '好', 'value': 4},
    {'emoji': '🥳', 'label': '非常好', 'value': 5},
  ];

  static const _triggerOptions = [
    '压力',
    '社交场合',
    '无聊',
    '愤怒',
    '疲惫',
    '饭后',
    '看到别人使用',
    '习惯性',
    '其他',
  ];

  @override
  void dispose() {
    _copingController.dispose();
    _consumptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    setState(() => _saving = true);
    try {
      final logUseCase = ref.read(logUseCaseProvider);
      await logUseCase.logToday(
        mood: _mood,
        urgeLevel: _urgeLevel,
        triggers: _selectedTriggers.isNotEmpty ? _selectedTriggers : null,
        coping: _copingController.text.isNotEmpty ? _copingController.text : null,
        relapsed: _relapsed,
        consumption: _consumptionController.text.isNotEmpty
            ? int.tryParse(_consumptionController.text)
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('今日记录已保存！继续加油 💪'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日记录'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMoodSection(),
            const SizedBox(height: 24),
            _buildUrgeSection(),
            const SizedBox(height: 24),
            _buildTriggerSection(),
            const SizedBox(height: 24),
            _buildCopingSection(),
            const SizedBox(height: 24),
            _buildRelapseSection(),
            const SizedBox(height: 24),
            _buildConsumptionSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveLog,
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存今日记录', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今天的心情',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _moodOptions.map((opt) {
            final value = opt['value'] as int;
            final selected = _mood == value;
            return GestureDetector(
              onTap: () => setState(() => _mood = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      opt['emoji'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opt['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUrgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '渴望程度',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '0 = 完全没有，10 = 非常强烈',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('0', style: TextStyle(fontSize: 12)),
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
            const Text('10', style: TextStyle(fontSize: 12)),
          ],
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: _urgeLevel > 7
                  ? Colors.red.withOpacity(0.1)
                  : _urgeLevel > 4
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_urgeLevel/10',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _urgeLevel > 7
                        ? Colors.red
                        : _urgeLevel > 4
                            ? Colors.orange
                            : Colors.green,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '诱因（可多选）',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '什么引发了你的渴望？',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _triggerOptions.map((trigger) {
            final selected = _selectedTriggers.contains(trigger);
            return FilterChip(
              label: Text(trigger),
              selected: selected,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _selectedTriggers.add(trigger);
                  } else {
                    _selectedTriggers.remove(trigger);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedTriggers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '已选: ${_selectedTriggers.join('、')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
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
        const SizedBox(height: 4),
        Text(
          '你是如何应对渴望的？',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _copingController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '例如：深呼吸、散步、打电话给朋友...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildRelapseSection() {
    return Card(
      color: _relapsed
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今天有复发吗？',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _relapsed ? '没关系，这只是过程的一部分，明天继续' : '坚持就是胜利！',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _relapsed
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _relapsed,
              onChanged: (value) => setState(() => _relapsed = value),
              activeColor: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '使用量',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '今天使用了多少（支烟/杯酒）？',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _consumptionController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '输入数量',
            border: const OutlineInputBorder(),
            suffixText: '支/杯',
            suffixStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
        const SizedBox(height: 4),
        Text(
          '记录今天的心情、成就或困难...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '今天有什么想记录的吗？',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
