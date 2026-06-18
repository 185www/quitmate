import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../domain/entity/relapse_plan.dart';
import '../../../domain/entity/user.dart';

class RelapsePlanScreen extends ConsumerStatefulWidget {
  const RelapsePlanScreen({super.key});

  @override
  ConsumerState<RelapsePlanScreen> createState() => _RelapsePlanScreenState();
}

class _RelapsePlanScreenState extends ConsumerState<RelapsePlanScreen> {
  final List<RelapsePlanItem> _fallbackTemplates = const [
    RelapsePlanItem(id: -1, userId: 0, situation: '朋友递烟/酒时，不好意思拒绝', trigger: '社交压力', copingPlan: '提前告知朋友我在戒烟/酒；手里拿饮料；准备借口如"我在吃药"', priority: 4, isTemplate: true, category: '社交'),
    RelapsePlanItem(id: -2, userId: 0, situation: '聚会中看到其他人都在抽烟/喝酒', trigger: '从众心理', copingPlan: '找一个同样不抽烟/酒的朋友聊天；必要时可以提前离场', priority: 3, isTemplate: true, category: '社交'),
    RelapsePlanItem(id: -3, userId: 0, situation: '工作压力大，想用烟/酒缓解', trigger: '压力', copingPlan: '做5分钟深呼吸；出去散步10分钟；听一首喜欢的歌', priority: 5, isTemplate: true, category: '压力'),
    RelapsePlanItem(id: -4, userId: 0, situation: '遇到挫折或失败时', trigger: '情绪低落', copingPlan: '给支持你的朋友打电话；写下三件值得感恩的事', priority: 4, isTemplate: true, category: '压力'),
    RelapsePlanItem(id: -5, userId: 0, situation: '饭后习惯性想抽烟', trigger: '习惯', copingPlan: '立刻刷牙；吃一块口香糖；站起来走动', priority: 3, isTemplate: true, category: '习惯'),
    RelapsePlanItem(id: -6, userId: 0, situation: '喝咖啡/茶时想抽烟', trigger: '条件反射', copingPlan: '换成喝茶或果汁；用吸管喝水模拟抽烟动作', priority: 2, isTemplate: true, category: '习惯'),
    RelapsePlanItem(id: -7, userId: 0, situation: '感到愤怒或沮丧', trigger: '负面情绪', copingPlan: '做10次深呼吸；数到10；离开当前环境散步', priority: 4, isTemplate: true, category: '情绪'),
    RelapsePlanItem(id: -8, userId: 0, situation: '感到无聊或孤独', trigger: '空虚感', copingPlan: '找一项爱好；给朋友打电话；看一部电影', priority: 3, isTemplate: true, category: '情绪'),
  ];

  List<RelapsePlanItem> _templates = [];
  List<RelapsePlanItem> _userPlans = [];
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final planUseCase = ref.read(planUseCaseProvider);
      final user = await ref.read(userUseCaseProvider).getCurrentUser();
      final templates = await planUseCase.getTemplatePlans();
      if (mounted) {
        setState(() {
          _user = user;
          _templates = templates.isNotEmpty ? templates : _fallbackTemplates;
          _userPlans = [];
        });
      }
      if (user != null) {
        final plans = await planUseCase.getPlansForUser(user.id);
        if (mounted) {
          setState(() {
            _userPlans = plans.where((p) => !p.isTemplate).toList();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _templates = _fallbackTemplates;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _categoryLabel(String? cat) {
    switch (cat) {
      case '社交': return '社交场合';
      case '压力': return '压力情境';
      case '习惯': return '习惯情境';
      case '情绪': return '情绪情境';
      default: return cat ?? '其他';
    }
  }

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case '社交': return Icons.people;
      case '压力': return Icons.psychology;
      case '习惯': return Icons.repeat;
      case '情绪': return Icons.mood_bad;
      default: return Icons.warning_amber;
    }
  }

  Color _priorityColor(int priority) {
    if (priority >= 4) return Colors.red;
    if (priority >= 3) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ['社交', '压力', '习惯', '情绪'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('复发预防计划'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPlanSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '模板计划',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...categories.map((cat) => _buildTemplateSection(cat, theme)),
                  if (_userPlans.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '我的自定义计划',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._userPlans.asMap().entries.map((e) => _buildPlanCard(e.value, theme, true)),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '根据 Abstinence Violation Effect 研究，一次失误不等于失败。重要的是分析原因并继续前进。',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTemplateSection(String category, ThemeData theme) {
    final items = _templates.where((t) => t.category == category).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Icon(_categoryIcon(category), size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(_categoryLabel(category), style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
            ],
          ),
        ),
        ...items.map((item) => _buildPlanCard(item, theme, false)),
      ],
    );
  }

  Widget _buildPlanCard(RelapsePlanItem plan, ThemeData theme, bool deletable) {
    return Dismissible(
      key: ValueKey(plan.id ?? plan.hashCode),
      direction: deletable ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (_) async {
        if (!deletable) return false;
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这个计划吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        if (plan.id != null) {
          await ref.read(planUseCaseProvider).deletePlan(plan.id!);
          _loadData();
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plan.situation, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _priorityColor(plan.priority).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'P${plan.priority}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _priorityColor(plan.priority),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (plan.trigger != null && plan.trigger!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('触发: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
                Text(plan.trigger!, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              Text('应对: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(plan.copingPlan, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPlanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddPlanSheet(
        onSave: (situation, trigger, coping, category, priority) async {
          if (_user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('请先完成初始设置')),
            );
            return;
          }
          final plan = RelapsePlanItem(
            userId: _user!.id,
            situation: situation,
            trigger: trigger,
            copingPlan: coping,
            priority: priority,
            isTemplate: false,
            category: category,
          );
          await ref.read(planUseCaseProvider).createPlan(plan);
          _loadData();
        },
      ),
    );
  }
}

class _AddPlanSheet extends StatefulWidget {
  final Future<void> Function(String situation, String trigger, String coping, String category, int priority) onSave;

  const _AddPlanSheet({required this.onSave});

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  final _situationCtrl = TextEditingController();
  final _triggerCtrl = TextEditingController();
  final _copingCtrl = TextEditingController();
  String _category = '社交';
  double _priority = 3;
  bool _saving = false;

  final _categories = ['社交', '压力', '习惯', '情绪'];

  @override
  void dispose() {
    _situationCtrl.dispose();
    _triggerCtrl.dispose();
    _copingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('添加新计划', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _situationCtrl,
            decoration: const InputDecoration(labelText: '情境描述', hintText: '例如：参加聚会时有人递烟'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _triggerCtrl,
            decoration: const InputDecoration(labelText: '触发因素', hintText: '例如：社交压力'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _copingCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '应对策略', hintText: '描述你的应对计划...'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: '分类'),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('优先级: ${_priority.toInt()}', style: theme.textTheme.bodyMedium),
              Expanded(
                child: Slider(
                  value: _priority,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _priority.toInt().toString(),
                  onChanged: (v) => setState(() => _priority = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_situationCtrl.text.trim().isEmpty || _copingCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写情境描述和应对策略')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _situationCtrl.text.trim(),
        _triggerCtrl.text.trim(),
        _copingCtrl.text.trim(),
        _category,
        _priority.toInt(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }
}
