import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 2×3 feature card grid — each card has a subtle icon background,
/// clean typography, and a brief description.
/// NOT a boring menu list.
class ActionScreen extends StatelessWidget {
  const ActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('行动'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择一个工具，开始你的改变',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
                physics: const BouncingScrollPhysics(),
                children: [
                  _ActionCard(
                    icon: Icons.smart_toy_rounded,
                    title: 'AI教练',
                    subtitle: '随时聊聊感受和挑战',
                    color: colorScheme.primary,
                    onTap: () => context.push('/action/coach'),
                  ),
                  _ActionCard(
                    icon: Icons.favorite_rounded,
                    title: '渴望工具箱',
                    subtitle: '冲浪、替代、SOS求助',
                    color: colorScheme.error,
                    onTap: () => context.push('/action/urge-toolkit'),
                  ),
                  _ActionCard(
                    icon: Icons.edit_note_rounded,
                    title: '每日记录',
                    subtitle: '情绪、诱因和应对方式',
                    color: colorScheme.secondary,
                    onTap: () => context.push('/action/daily-log'),
                  ),
                  _ActionCard(
                    icon: Icons.school_rounded,
                    title: '技能训练',
                    subtitle: 'CBT认知行为疗法技巧',
                    color: colorScheme.tertiary,
                    onTap: () => context.push('/action/skills-lab'),
                  ),
                  _ActionCard(
                    icon: Icons.emoji_events_rounded,
                    title: '挑战',
                    subtitle: '打卡挑战，赢取XP奖励',
                    color: colorScheme.tertiary,
                    onTap: () => context.push('/action/challenge'),
                  ),
                  _ActionCard(
                    icon: Icons.people_rounded,
                    title: '伙伴',
                    subtitle: '小明的每日问候和挑战',
                    color: colorScheme.secondary,
                    onTap: () => context.push('/action/companion'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single feature card in the 2×3 grid.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtle icon background
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
