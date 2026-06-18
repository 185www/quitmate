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
  int? _urgeLevel;
  bool _relapsed = false;
  bool _saving = false;
  bool _loading = true;
  bool _alreadyLogged = false;

  static const _moodOptions = [
    {'emoji': '😢', 'label': '很差', 'value': 1},
    {'emoji': '😟', 'label': '不好', 'value': 2},
    {'emoji': '😐', 'label': '一般', 'value': 3},
    {'emoji': '😊', 'label': '不错', 'value': 4},
    {'emoji': '🤩', 'label': '超棒', 'value': 5},
  ];

  static const _urgeConfig = [
    {'size': 16.0, 'color': Colors.green},
    {'size': 24.0, 'color': Colors.lightGreen},
    {'size': 32.0, 'color': Colors.orangeAccent},
    {'size': 40.0, 'color': Colors.orange},
    {'size': 48.0, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _checkTodayLog();
  }

  Future<void> _checkTodayLog() async {
    try {
      final log = await ref.read(logUseCaseProvider).getTodayLog();
      if (mounted) {
        setState(() {
          _alreadyLogged = log != null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveLog() async {
    setState(() => _saving = true);
    try {
      final logUseCase = ref.read(logUseCaseProvider);
      await logUseCase.logToday(
        mood: _mood,
        urgeLevel: _urgeLevel,
        relapsed: _relapsed,
      );

      final userUseCase = ref.read(userUseCaseProvider);
      final prefs = await userUseCase.getPreferences();
      final currentXp = (prefs['total_xp'] as int?) ?? 0;
      prefs['total_xp'] = currentXp + 10;
      await userUseCase.savePreferences(prefs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('打卡成功 +10 XP'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
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
        title: const Text('每日打卡'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alreadyLogged
              ? _buildAlreadyLogged()
              : _buildForm(),
    );
  }

  Widget _buildAlreadyLogged() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            '今日已打卡',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildMoodSection(),
          const SizedBox(height: 20),
          _buildUrgeSection(),
          const SizedBox(height: 20),
          _buildRelapseSection(),
          const Spacer(),
          _buildSaveButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _moodOptions.map((opt) {
            final value = opt['value'] as int;
            final selected = _mood == value;
            return GestureDetector(
              onTap: () => setState(() => _mood = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? Colors.orange : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.3 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(opt['emoji'] as String, style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: selected ? Colors.orange : Colors.grey,
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
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final value = i + 1;
            final selected = _urgeLevel == value;
            final config = _urgeConfig[i];
            final size = config['size'] as double;
            final color = config['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _urgeLevel = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: size + 16,
                height: size + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]
                      : null,
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? size + 4 : size,
                    height: selected ? size + 4 : size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? color : color.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRelapseSection() {
    return Card(
      color: _relapsed
          ? Colors.red.withOpacity(0.08)
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
                    '今天复吸/复喝了',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (_relapsed)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '没关系，明天继续💪',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: _relapsed,
              onChanged: (v) => setState(() => _relapsed = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveLog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: _saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✅ 打卡 +10 XP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}
