import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LifestyleScreen extends ConsumerWidget {
  const LifestyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = [
      {
        'icon': Icons.fitness_center,
        'title': '规律运动',
        'description': '每周至少150分钟中等强度运动，帮助缓解戒断症状和压力。',
        'category': '运动',
        'duration': '30分钟/天',
      },
      {
        'icon': Icons.bedtime,
        'title': '充足睡眠',
        'description': '每晚7-9小时睡眠，有助于情绪调节和意志力恢复。',
        'category': '休息',
        'duration': '7-9小时/晚',
      },
      {
        'icon': Icons.restaurant,
        'title': '均衡饮食',
        'description': '多吃水果蔬菜，减少咖啡因和糖分摄入。',
        'category': '饮食',
        'duration': '持续',
      },
      {
        'icon': Icons.spa,
        'title': '冥想练习',
        'description': '每天10分钟正念冥想，帮助管理压力和渴望。',
        'category': '心理',
        'duration': '10分钟/天',
      },
      {
        'icon': Icons.people,
        'title': '社交支持',
        'description': '与支持你的人保持联系，加入戒烟/酒互助小组。',
        'category': '社交',
        'duration': '持续',
      },
      {
        'icon': Icons.water_drop,
        'title': '多喝水',
        'description': '每天至少8杯水，帮助排出体内毒素。',
        'category': '习惯',
        'duration': '8杯/天',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('生活方式重塑'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(rec['icon'] as IconData),
              ),
              title: Text(rec['title'] as String),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(rec['description'] as String),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          rec['category'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rec['duration'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}