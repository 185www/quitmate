import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';
import '../../../domain/entity/user.dart';
import 'widgets/body_age_comparison.dart';
import 'widgets/money_timeline_visualization.dart';
import 'widgets/social_comparison_card.dart';

/// Reality Check screen: shows users their habits in concrete numbers
/// without judgment. Goal is self-awareness, not assessment scoring.
class RealityCheckScreen extends ConsumerStatefulWidget {
  const RealityCheckScreen({super.key});

  @override
  ConsumerState<RealityCheckScreen> createState() => _RealityCheckScreenState();
}

class _RealityCheckScreenState extends ConsumerState<RealityCheckScreen> {
  TargetType _targetType = TargetType.smoking;
  final _amountController = TextEditingController(text: '10');
  int _currentStep = 0;
  bool _saving = false;

  // Auto-estimated fields (pre-filled with smart defaults)
  int _dailyCost = 15;
  int _years = 5;
  int _age = 30;

  @override
  void initState() {
    super.initState();
    _updateDefaults();
    _loadExistingAge();
  }

  Future<void> _loadExistingAge() async {
    final user = await ref.read(userUseCaseProvider).getCurrentUser();
    if (user != null && user.age != null && mounted) {
      setState(() => _age = user.age!);
    }
  }

  void _updateDefaults() {
    switch (_targetType) {
      case TargetType.smoking:
        _amountController.text = '10';
        _dailyCost = 15;
        break;
      case TargetType.alcohol:
        _amountController.text = '3';
        _dailyCost = 30;
        break;
      case TargetType.both:
        _amountController.text = '10';
        _dailyCost = 25;
        break;
    }
    _years = 5;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int get _dailyAmount => (int.tryParse(_amountController.text) ?? 10);
  // _dailyCost, _years, _age are auto-estimated fields (not user input)

  // Calculated data
  int get _yearlyCost => _dailyCost * 365;
  int get _totalSpent => _yearlyCost * _years;
  int get _totalAmount => _dailyAmount * 365 * _years;
  double get _dailyMinutes =>
      _dailyAmount * (_targetType == TargetType.alcohol ? 15 : 5);
  int get _yearlyDays => (_dailyMinutes * 365 ~/ 1440);
  int get _totalDays => _yearlyDays * _years;

  String get _unitLabel {
    switch (_targetType) {
      case TargetType.smoking:
        return '支烟';
      case TargetType.alcohol:
        return '杯酒';
      case TargetType.both:
        return '支烟+杯酒';
    }
  }

  String get _healthImpact {
    final years = _years;
    if (years < 2) return '身体的伤害还处于早期阶段，但已经在累积';
    if (years < 5) return '器官功能已经开始出现可测量的下降';
    if (years < 10) return '心血管和呼吸系统的损伤已经比较明显';
    if (years < 20) return '多项健康指标已显著偏离正常水平';
    return '长期使用带来的健康风险已经非常现实';
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Step 0 just selects target type, always allow
      if (mounted) setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      // Step 1 requires at least one number entered
      final amount = int.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入一个大概的数字')),
        );
        return;
      }
      if (mounted) setState(() => _currentStep++);
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _saving = true);
    try {
      await ref.read(userUseCaseProvider).updateAssessment(
            targetType: _targetType,
            dailyConsumption: _dailyAmount.toDouble(),
            yearsOfUse: _years,
            age: _age,
            dailyCostAmount: _dailyCost.toDouble(),
          );
      if (mounted) {
        context.push('/onboarding/education');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('出错了: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Show a quick slider dialog to adjust an estimate value.
  Future<void> _showEstimateAdjuster({
    required String title,
    required int currentValue,
    required int min,
    required int max,
    required String unit,
    required ValueChanged<int> onSaved,
  }) async {
    if (!mounted) return;
    var tempValue = currentValue;
    final controller = TextEditingController(text: '$currentValue');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: tempValue.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min) > 20 ? (max - min) ~/ 5 : (max - min),
                label: '$tempValue$unit',
                onChanged: (v) {
                  setDialogState(() {
                    tempValue = v.round();
                    controller.text = '$tempValue';
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  suffixText: unit,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) {
                  tempValue = int.tryParse(v) ?? min;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, tempValue),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result != currentValue) {
      onSaved(result);
      if (mounted) setState(() {});
    }
  }

  void _showCostAdjuster() => _showEstimateAdjuster(
    title: '调整每日花费',
    currentValue: _dailyCost,
    min: 1,
    max: 200,
    unit: '元',
    onSaved: (v) => _dailyCost = v,
  );

  void _showYearsAdjuster() => _showEstimateAdjuster(
    title: '调整使用年数',
    currentValue: _years,
    min: 1,
    max: 50,
    unit: '年',
    onSaved: (v) => _years = v,
  );

  void _showAgeAdjuster() => _showEstimateAdjuster(
    title: '调整年龄',
    currentValue: _age,
    min: 14,
    max: 80,
    unit: '岁',
    onSaved: (v) => _age = v,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('看看自己的情况'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              _currentStep > 0 ? setState(() => _currentStep--) : context.pop(),
        ),
      ),
      body: _currentStep < 2 ? _buildInputStep() : _buildResultStep(),
    );
  }

  Widget _buildInputStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(
            children: [
              _ProgDot(active: true, done: _currentStep > 0),
              _ProgLine(done: _currentStep > 0),
              _ProgDot(active: _currentStep >= 1, done: _currentStep > 1),
              _ProgLine(done: _currentStep > 1),
              _ProgDot(active: _currentStep >= 2, done: false),
            ],
          ),
          const SizedBox(height: 32),
          if (_currentStep == 0) _buildStep1(),
          if (_currentStep == 1) _buildStep2(),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _nextStep,
              child: const Text('下一步'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('你主要想了解哪方面？',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('选一个你关心的，也可以两个都选',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        // Target type selector with icons and descriptions
        _TargetOption(
          icon: Icons.smoking_rooms,
          color: Colors.orange,
          title: '吸烟',
          desc: '香烟、电子烟',
          selected: _targetType == TargetType.smoking,
          onTap: () => setState(() {
            _targetType = TargetType.smoking;
            _updateDefaults();
          }),
        ),
        const SizedBox(height: 12),
        _TargetOption(
          icon: Icons.local_bar,
          color: Colors.brown,
          title: '饮酒',
          desc: '啤酒、白酒、红酒',
          selected: _targetType == TargetType.alcohol,
          onTap: () => setState(() {
            _targetType = TargetType.alcohol;
            _updateDefaults();
          }),
        ),
        const SizedBox(height: 12),
        _TargetOption(
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
          title: '两个都有',
          desc: '烟酒都有',
          selected: _targetType == TargetType.both,
          onTap: () => setState(() {
            _targetType = TargetType.both;
            _updateDefaults();
          }),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('大概说说你的情况',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('只需一个数字，其他我们帮你估算',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        // Daily amount — the ONLY required field
        _InputField(
          label: '每天大概多少$_unitLabel？',
          controller: _amountController,
          icon: Icons.today,
          hint: _targetType == TargetType.alcohol ? '比如 3' : '比如 10',
        ),
        const SizedBox(height: 24),
        // Auto-estimated summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('智能估算', style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              _EstimateRow(
                icon: Icons.attach_money,
                label: '每日花费',
                value: '¥$_dailyCost',
                onTap: _showCostAdjuster,
              ),
              const SizedBox(height: 8),
              _EstimateRow(
                icon: Icons.calendar_today,
                label: '使用年数',
                value: '$_years 年',
                onTap: _showYearsAdjuster,
              ),
              const SizedBox(height: 8),
              _EstimateRow(
                icon: Icons.person_rounded,
                label: '你的年龄',
                value: '$_age 岁',
                onTap: _showAgeAdjuster,
              ),
              const SizedBox(height: 8),
              Text(
                '点击数字可以调整估算值',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(
            children: const [
              _ProgDot(active: true, done: true),
              _ProgLine(done: true),
              _ProgDot(active: true, done: true),
              _ProgLine(done: true),
              _ProgDot(active: true, done: false),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '这是你的数字',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '没有对错，只是事实',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // Money card
          _ResultCard(
            icon: Icons.attach_money,
            iconColor: Colors.amber.shade700,
            bgColor: Colors.amber.shade50,
            title: '这些年花掉的',
            items: [
              ('每天', '¥$_dailyCost'),
              ('每年', '¥${NumberFormat.decimalPattern().format(_yearlyCost)}'),
              (
                '$_years 年来',
                '¥${NumberFormat.decimalPattern().format(_totalSpent)}'
              ),
            ],
            footer:
                '相当于 ${(_totalSpent / 5000).toStringAsFixed(1)} 部 iPhone，或 ${(_totalSpent / 300).toStringAsFixed(0)} 顿火锅',
          ),
          const SizedBox(height: 16),

          // Time card
          _ResultCard(
            icon: Icons.schedule,
            iconColor: Colors.blue.shade700,
            bgColor: Colors.blue.shade50,
            title: '花在$_unitLabel上的时间',
            items: [
              ('每天', '${_dailyMinutes.round()} 分钟'),
              ('每年', '$_yearlyDays 天'),
              ('$_years 年来', '$_totalDays 天'),
            ],
            footer:
                '相当于 ${(_totalDays / 365).toStringAsFixed(1)} 年——${(_totalDays / 30).toStringAsFixed(0)} 个月整',
          ),
          const SizedBox(height: 16),

          // Quantity card
          _ResultCard(
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.deepPurple.shade700,
            bgColor: Colors.deepPurple.shade50,
            title: '累计用量',
            items: [
              ('每天', '$_dailyAmount $_unitLabel'),
              (
                '每年',
                '${NumberFormat.decimalPattern().format(_dailyAmount * 365)} $_unitLabel'
              ),
              (
                '$_years 年来',
                '${NumberFormat.decimalPattern().format(_totalAmount)} $_unitLabel'
              ),
            ],
            footer: '如果每天少$_unitLabel，这些就不会进入你的身体',
          ),
          const SizedBox(height: 24),

          // Body Age Comparison (immersive)
          BodyAgeComparison(
            actualAge: _age,
            yearsOfUse: _years,
            targetTypeLabel: _targetType == TargetType.alcohol ? '饮酒' : '吸烟',
          ),
          const SizedBox(height: 16),

          // Money Timeline (immersive)
          MoneyTimelineVisualization(
            dailyCost: _dailyCost,
            yearsOfUse: _years,
            unitLabel: _unitLabel,
          ),
          const SizedBox(height: 16),

          // Social Comparison (immersive)
          SocialComparisonCard(
            userAge: _age,
            targetTypeLabel: _targetType == TargetType.alcohol ? '饮酒' : '吸烟',
          ),
          const SizedBox(height: 16),

          // Health impact — not preachy, just factual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.healing, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('健康提示',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _healthImpact,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Reflective question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  '看完这些数字，你有什么想法？',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  '不管你的答案是什么，我们都可以帮你想清楚接下来怎么做',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _saveAndContinue,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('继续，了解更多'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                try {
                  await ref.read(userUseCaseProvider).updateAssessment(
                        targetType: _targetType,
                        dailyConsumption: _dailyAmount.toDouble(),
                        yearsOfUse: _years,
                        age: _age,
                        dailyCostAmount: _dailyCost.toDouble(),
                      );
                  if (mounted) context.go('/');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('保存失败: $e')),
                    );
                  }
                }
              },
              child: Text(
                '先到这里，我需要想一想',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────

class _ProgDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _ProgDot({required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final color = done
        ? Theme.of(context).colorScheme.primary
        : active
            ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? color : Colors.transparent,
          border: Border.all(color: color, width: 2)),
    );
  }
}

class _ProgLine extends StatelessWidget {
  final bool done;
  const _ProgLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: done
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
      ),
    );
  }
}

class _TargetOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _TargetOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: selected
                        ? color
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 16)),
                    Text(desc,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13)),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;

  const _InputField(
      {required this.label,
      required this.controller,
      required this.icon,
      required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final List<(String, String)> items;
  final String footer;

  const _ResultCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.items,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(item.$1,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ),
                      Text(
                        item.$2,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 16),
            Text(
              footer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estimate Row & Adjuster ─────────────────────────────────────

class _EstimateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _EstimateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.edit, size: 14, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
