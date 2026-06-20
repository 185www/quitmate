import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lightweight discovery page for users who are just browsing.
/// No commitment, no questionnaires — just interesting interactive content.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  int _currentCard = 0;

  final _cards = [
    _DiscoveryCard(
      emoji: '🫁',
      title: '你的肺龄是多少？',
      description: '大多数人不知道每天吸烟对肺部老化的影响有多大。20 分钟后，你的心率就开始恢复正常。24 小时后，心脏病发作风险开始降低。',
      action: '看看身体恢复时间线',
      route: '/onboarding/education',
    ),
    _DiscoveryCard(
      emoji: '💰',
      title: '你每年花多少？',
      description: '按每天一包烟 ¥15 计算，一年 ¥5,475。十年 ¥54,750。这够买一部新手机、一次全家旅行、或者为孩子的教育存一笔钱。',
      action: '算算我的花费',
      route: '/onboarding/reality-check',
    ),
    _DiscoveryCard(
      emoji: '🧠',
      title: '为什么戒那么难？',
      description: '尼古丁劫持了大脑的奖励系统，让你把"需要"和"想要"混为一谈。但好消息是——大脑可以在 90 天内完成自我修复。你只是暂时失去了一个工具，不是失去了能力。',
      action: '了解更多',
      route: '/onboarding/education',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('随便看看'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              '不急，慢慢看',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '如果你哪天想戒了，随时回来，你的数据都在',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: PageView.builder(
                itemCount: _cards.length,
                onPageChanged: (i) => setState(() => _currentCard = i),
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Card(
                      key: ValueKey(card.title),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(card.emoji, style: const TextStyle(fontSize: 64)),
                            const SizedBox(height: 20),
                            Text(card.title,
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(card.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => context.push(card.route),
                                child: Text(card.action),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_cards.length, (i) {
                final isActive = i == _currentCard;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? theme.colorScheme.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryCard {
  final String emoji;
  final String title;
  final String description;
  final String action;
  final String route;
  const _DiscoveryCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.action,
    required this.route,
  });
}
