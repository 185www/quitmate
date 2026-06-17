import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RelapsePlanScreen extends ConsumerStatefulWidget {
  const RelapsePlanScreen({super.key});

  @override
  ConsumerState<RelapsePlanScreen> createState() => _RelapsePlanScreenState();
}

class _RelapsePlanScreenState extends ConsumerState<RelapsePlanScreen> {
  final List<Map<String, String>> _plans = [
    {
      'situation': '参加聚会，有人递烟/酒',
      'trigger': '社交压力',
      'plan': '提前告知朋友我在戒烟/酒；手里拿饮料；如果感到不舒服，可以提前离开',
    },
    {
      'situation': '工作压力大，想用烟/酒缓解',
      'trigger': '压力',
      'plan': '做5分钟深呼吸；出去散步；听一首喜欢的歌；给朋友打电话',
    },
    {
      'situation': '饭后，习惯性想抽烟',
      'trigger': '习惯',
      'plan': '立刻刷牙；吃一块口香糖；站起来走动',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('复发预防计划'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPlan,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plan['situation']!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    '触发因素：${plan['trigger']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '应对计划：',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(plan['plan']!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _addPlan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddPlanSheet(
        onAdd: (situation, trigger, plan) {
          setState(() {
            _plans.add({
              'situation': situation,
              'trigger': trigger,
              'plan': plan,
            });
          });
        },
      ),
    );
  }
}

class _AddPlanSheet extends StatefulWidget {
  final Function(String, String, String) onAdd;

  const _AddPlanSheet({required this.onAdd});

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  final _situationController = TextEditingController();
  final _triggerController = TextEditingController();
  final _planController = TextEditingController();

  @override
  void dispose() {
    _situationController.dispose();
    _triggerController.dispose();
    _planController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            '添加新计划',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _situationController,
            decoration: const InputDecoration(
              labelText: '高危情境',
              hintText: '例如：参加聚会时',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _triggerController,
            decoration: const InputDecoration(
              labelText: '触发因素',
              hintText: '例如：社交压力',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _planController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '应对计划',
              hintText: '描述你的应对策略...',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onAdd(
                  _situationController.text,
                  _triggerController.text,
                  _planController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}