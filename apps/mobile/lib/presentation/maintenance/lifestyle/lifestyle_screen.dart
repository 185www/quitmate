import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';

class LifestyleScreen extends ConsumerWidget {
  const LifestyleScreen({super.key});

  static const _recommendations = [
    {
      'icon': Icons.directions_run,
      'title': '规律运动',
      'description': '每周至少150分钟中等强度运动（如快走、游泳、骑行），帮助缓解戒断症状和压力。运动释放内啡肽，自然提升情绪。',
      'category': '运动',
      'duration': '30分钟/天',
      'key': 'exercise',
    },
    {
      'icon': Icons.bedtime,
      'title': '保持充足睡眠',
      'description': '每晚7-9小时高质量睡眠，有助于情绪调节和意志力恢复。建立规律的作息时间，睡前避免使用电子设备。',
      'category': '睡眠',
      'duration': '7-9小时/晚',
      'key': 'sleep',
    },
    {
      'icon': Icons.restaurant,
      'title': '均衡饮食',
      'description': '多摄入水果蔬菜和全谷物，减少咖啡因和糖分摄入。咖啡因可能加剧焦虑和渴求感，建议适量饮用。',
      'category': '饮食',
      'duration': '持续',
      'key': 'diet',
    },
    {
      'icon': Icons.self_improvement,
      'title': '每日冥想',
      'description': '每天10分钟正念冥想，帮助管理压力和渴求。专注于呼吸，观察思绪而不加评判，增强自我觉察能力。',
      'category': '冥想',
      'duration': '10分钟/天',
      'key': 'meditation',
    },
    {
      'icon': Icons.people,
      'title': '建立社交支持网络',
      'description': '与理解和支持你的人保持联系，考虑加入戒烟/酒互助小组。分享你的经历可以获得情感支持和实用建议。',
      'category': '社交',
      'duration': '持续',
      'key': 'social',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('生活方式重塑'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._recommendations.map((rec) => _LifestyleCard(
            icon: rec['icon'] as IconData,
            title: rec['title'] as String,
            description: rec['description'] as String,
            category: rec['category'] as String,
            duration: rec['duration'] as String,
            prefKey: rec['key'] as String,
          )),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_stories, color: theme.colorScheme.tertiary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '研究表明运动可以减少50%的渴求强度 (Ussher et al., Cochrane Review)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontStyle: FontStyle.italic,
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
    );
  }
}

class _LifestyleCard extends ConsumerStatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String category;
  final String duration;
  final String prefKey;

  const _LifestyleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.prefKey,
  });

  @override
  ConsumerState<_LifestyleCard> createState() => _LifestyleCardState();
}

class _LifestyleCardState extends ConsumerState<_LifestyleCard> {
  bool _expanded = false;
  bool _added = false;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _checkAdded();
  }

  Future<void> _checkAdded() async {
    try {
      final prefs = await ref.read(userUseCaseProvider).getPreferences();
      if (mounted) {
        setState(() {
          _added = prefs['daily_${widget.prefKey}'] == true;
          _loadingPrefs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrefs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(widget.icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(widget.category, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.schedule, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(widget.duration, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text(widget.description, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loadingPrefs ? null : _toggleDaily,
                      icon: Icon(_added ? Icons.check_circle : Icons.add_circle_outline),
                      label: Text(_added ? '已添加到日常' : '添加到日常'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _added ? Colors.green : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDaily() async {
    final newVal = !_added;
    setState(() => _added = newVal);
    try {
      final existing = await ref.read(userUseCaseProvider).getPreferences();
      existing['daily_${widget.prefKey}'] = newVal;
      await ref.read(userUseCaseProvider).savePreferences(existing);
    } catch (e) {
      if (mounted) setState(() => _added = !newVal);
    }
  }
}
