import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SkillsLabScreen extends ConsumerWidget {
  const SkillsLabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = [
      {
        'icon': Icons.psychology,
        'title': '认知重构',
        'description': '识别和改变消极思维模式',
        'category': 'CBT',
      },
      {
        'icon': Icons.air,
        'title': '深呼吸练习',
        'description': '4-7-8呼吸法缓解焦虑',
        'category': '放松',
      },
      {
        'icon': Icons.visibility,
        'title': '正念冥想',
        'description': '活在当下，观察渴望而不行动',
        'category': '正念',
      },
      {
        'icon': Icons.record_voice_over,
        'title': '拒绝技巧',
        'description': '学会说"不"的技巧',
        'category': '社交',
      },
      {
        'icon': Icons.mood,
        'title': '情绪管理',
        'description': '识别和调节情绪的方法',
        'category': '情绪',
      },
      {
        'icon': Icons.timer,
        'title': '延迟满足',
        'description': '等待渴望自然消退',
        'category': '自控',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CBT技能训练'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: skills.length,
        itemBuilder: (context, index) {
          final skill = skills[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(skill['icon'] as IconData),
              ),
              title: Text(skill['title'] as String),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(skill['description'] as String),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(
                      skill['category'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 导航到技能详情页
              },
            ),
          );
        },
      ),
    );
  }
}