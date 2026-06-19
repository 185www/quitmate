import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/widgets/widget_service.dart';
import '../../../domain/entity/user.dart';

class QuitDateWizardScreen extends ConsumerStatefulWidget {
  const QuitDateWizardScreen({super.key});

  @override
  ConsumerState<QuitDateWizardScreen> createState() =>
      _QuitDateWizardScreenState();
}

class _QuitDateWizardScreenState extends ConsumerState<QuitDateWizardScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = true;
  bool _hasExistingQuitDate = false;
  bool _saving = false;

  static const _motivationalMessages = [
    {'days': 0, 'message': '今天就是最好的开始！', 'subtitle': '每一分钟都在为健康投资'},
    {'days': 3, 'message': '3天后，新的征程开始！', 'subtitle': '准备好迎接改变了吗？'},
    {'days': 7, 'message': '一周准备，一生受益', 'subtitle': '给自己一周时间做好充分准备'},
    {'days': 14, 'message': '两周倒计时，稳步前行', 'subtitle': '时间越长，准备越充分'},
    {'days': 30, 'message': '一个月规划，为长久成功', 'subtitle': '研究表明提前规划显著提高成功率'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ref.read(userUseCaseProvider).getCurrentUser();
      if (user != null && user.quitDate != null) {
        setState(() {
          _selectedDate = user.quitDate!;
          _hasExistingQuitDate = true;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('QuitDateWizard: 加载用户失败: $e');
      setState(() => _loading = false);
    }
  }

  String _getMotivationalMessage() {
    final days = _selectedDate.difference(DateTime.now()).inDays;
    String bestMatch = _motivationalMessages.last['message'] as String;
    String bestSub = _motivationalMessages.last['subtitle'] as String;
    for (final msg in _motivationalMessages) {
      if (days >= (msg['days'] as int)) {
        bestMatch = msg['message'] as String;
        bestSub = msg['subtitle'] as String;
      }
    }
    return '$bestMatch\n$bestSub';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '选择戒断日',
      cancelText: '取消',
      confirmText: '确认',
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirmDate() async {
    setState(() => _saving = true);
    try {
      final userUseCase = ref.read(userUseCaseProvider);
      if (!_hasExistingQuitDate) {
        final user = await userUseCase.getCurrentUser();
        if (user == null) {
          await userUseCase.createUser(
            targetType: TargetType.smoking,
            quitDate: _selectedDate,
          );
        } else {
          await userUseCase.setQuitDate(_selectedDate);
        }
      } else {
        await userUseCase.setQuitDate(_selectedDate);
      }
      if (mounted) {
        final user = await ref.read(userUseCaseProvider).getCurrentUser();
        await WidgetService.updateWidget(user);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('戒断日已设置！新的旅程即将开始'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('设置失败: $e'),
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('选个好日子')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final daysUntil = _selectedDate.difference(DateTime.now()).inDays;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_hasExistingQuitDate ? '修改戒断日' : '设置戒断日'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event,
                size: 56,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _hasExistingQuitDate ? '修改你的戒断日' : '选择你的戒断日',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _hasExistingQuitDate ? '选择一个更有意义的日期重新开始' : '选择一个有意义的日期开始你的新生活',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        daysUntil == 0 ? '就是今天！' : '$daysUntil 天后',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getMotivationalMessage(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_hasExistingQuitDate) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        '当前戒断日已为 ${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      daysUntil <= 1
                          ? '研究表明，立即行动的人成功率更高！'
                          : daysUntil <= 7
                              ? '短时间准备有助于保持动力，不要拖太久'
                              : '充足的准备时间可以制定更好的计划',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.edit_calendar),
                label: Text(
                  _hasExistingQuitDate ? '修改日期' : '更改日期',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _confirmDate,
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _hasExistingQuitDate ? '确认修改' : '确认并开始',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '你可以随时在设置中修改戒断日',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
