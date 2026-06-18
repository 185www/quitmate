import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quitmate/core/di/providers.dart';

class MotivationScreen extends ConsumerStatefulWidget {
  const MotivationScreen({super.key});

  @override
  ConsumerState<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends ConsumerState<MotivationScreen> {
  final Set<String> _selectedReasons = {};
  int? _prosScore;
  int? _consScore;
  bool _showQuotes = false;
  bool _saving = false;

  final _reasons = [
    {'key': 'health', 'label': '健康', 'icon': Icons.favorite, 'desc': '改善身体状况，降低疾病风险'},
    {'key': 'money', 'label': '省钱', 'icon': Icons.savings, 'desc': '节省大量开支，改善财务状况'},
    {'key': 'family', 'label': '家人', 'icon': Icons.family_restroom, 'desc': '为家人创造无烟/无酒环境'},
    {'key': 'image', 'label': '形象', 'icon': Icons.face, 'desc': '改善外貌，去除烟/酒味'},
    {'key': 'freedom', 'label': '自由', 'icon': Icons.flight_takeoff, 'desc': '摆脱依赖，重获选择自由'},
    {'key': 'performance', 'label': '表现', 'icon': Icons.trending_up, 'desc': '提高工作和运动表现'},
    {'key': 'mental', 'label': '心理健康', 'icon': Icons.psychology, 'desc': '减少焦虑和抑郁症状'},
    {'key': 'social', 'label': '社交', 'icon': Icons.people, 'desc': '改善人际关系和社交质量'},
    {'key': 'longevity', 'label': '长寿', 'icon': Icons.elderly, 'desc': '延长寿命，提高生活质量'},
    {'key': 'pregnancy', 'label': '生育健康', 'icon': Icons.baby_changing_station, 'desc': '保护生育能力和胎儿健康'},
  ];

  final _quotes = [
    {'text': '戒烟不是放弃什么，而是摆脱什么。你失去的只是一个牢笼。', 'author': '— Allen Carr'},
    {'text': '每一次拒绝一支烟，你都在重新夺回对自己生命的控制权。', 'author': '— 未知'},
    {'text': '戒断不是惩罚，而是你给自己最好的礼物。', 'author': '— 匿名'},
    {'text': '渴望像海浪一样——它来的时候汹涌澎湃，但如果你不去迎合它，它终将退去。', 'author': '— 冲浪法创始人'},
    {'text': '你不是在放弃吸烟/饮酒，你是在选择自由、健康和生活。', 'author': '— 匿名'},
    {'text': '统计显示，戒断者平均需要6-30次尝试才能成功。每一次失败都是通向成功的阶梯。', 'author': '— Chaiton et al., BMJ Open 2016'},
    {'text': '戒断后20分钟，你的身体就开始修复。每一分钟都在变得更好。', 'author': '— CDC'},
    {'text': '最艰难的一步不是开始，而是决定开始。你已经做到了。', 'author': '— 匿名'},
  ];

  Future<void> _save() async {
    if (_selectedReasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个戒断理由')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(userUseCaseProvider).savePreferences({
        'reasons': _selectedReasons.toList(),
        'decisional_balance': {
          'pros_score': _prosScore,
          'cons_score': _consScore,
        },
        'onboarding_completed': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('动机设置已保存')),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('动机提升')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReasonsSection(context),
          const SizedBox(height: 16),
          _buildDecisionalBalance(context),
          const SizedBox(height: 16),
          _buildSuccessStories(context),
          const SizedBox(height: 24),
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedReasons.isNotEmpty ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('完成设置，开始旅程'),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReasonsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('我的戒断理由', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '选择你最重要的戒断理由（可多选）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((r) {
              final key = r['key'] as String;
              final label = r['label'] as String;
              final icon = r['icon'] as IconData;
              final desc = r['desc'] as String;
              final selected = _selectedReasons.contains(key);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedReasons.remove(key);
                      } else {
                        _selectedReasons.add(key);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: selected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            icon,
                            size: 18,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              Text(
                                desc,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionalBalance(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.balance, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Decisional Balance（决策平衡）', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '评估戒断的好处与继续使用的坏处，帮助你坚定决心',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '戒断的好处对你来说有多重要？',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildScale(context, _prosScore, (v) => setState(() => _prosScore = v)),
            const SizedBox(height: 16),
            Text(
              '继续使用的坏处对你来说有多严重？',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildScale(context, _consScore, (v) => setState(() => _consScore = v)),
            if (_prosScore != null && _consScore != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _prosScore! >= _consScore!
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _prosScore! >= _consScore!
                      ? '你的决策平衡偏向戒断，这是很好的基础！'
                      : '你仍然认为继续使用有一些"好处"。思考一下这些好处是否值得你付出健康代价？',
                  style: TextStyle(
                    color: _prosScore! >= _consScore! ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScale(BuildContext context, int? value, ValueChanged<int> onChanged) {
    return Row(
      children: List.generate(5, (i) {
        final score = i + 1;
        final labels = ['不重要', '有点重要', '重要', '很重要', '极其重要'];
        final isSelected = value == score;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(score),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSuccessStories(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _showQuotes = !_showQuotes),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(Icons.auto_stories, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('成功故事与激励', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Icon(
                    _showQuotes ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '看看统计数据和他人的经验',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_showQuotes) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.insights, color: Colors.orange),
                    const SizedBox(height: 8),
                    Text(
                      '你需要记住的数据',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _statRow(context, '60-70%', '的戒断者在第一年内至少经历一次复吸'),
                    _statRow(context, '6-30次', '认真尝试才能成功戒断（平均水平）'),
                    _statRow(context, '2-3倍', '咨询+药物辅助可提高成功率'),
                    _statRow(context, '50%', '戒断5年后肺癌风险降低一半'),
                    _statRow(context, '¥数万', '每年节省的烟/酒支出'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ..._quotes.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"${q['text']}"',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              q['author'] as String,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statRow(BuildContext context, String number, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
