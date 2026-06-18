import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/badge.dart';

class ShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);
    if (index != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = index);
      });
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          final routes = ['/', '/action', '/maintenance', '/profile'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: '行动'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: '维持'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/action')) return 1;
    if (location.startsWith('/maintenance')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }
}

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  Future<User?>? _userFuture;
  Future<int>? _streakFuture;
  Future<List<DailyLogEntry>>? _recentLogsFuture;
  Future<List<AppBadge>>? _badgesFuture;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final useCase = ref.read(userUseCaseProvider);
    final logUseCase = ref.read(logUseCaseProvider);
    final badgeUseCase = ref.read(badgeUseCaseProvider);
    _userFuture = useCase.getCurrentUser();
    _streakFuture = logUseCase.getStreakDays();
    _recentLogsFuture = logUseCase.getRecentLogs(limit: 3);
    _badgesFuture = badgeUseCase.getEarnedBadges();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuitMate'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStreakSection(context),
              const SizedBox(height: 16),
              _buildQuickStatsSection(context),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 16),
              _buildRecentLogsSection(context),
              const SizedBox(height: 16),
              _buildBadgesSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())));
        }
        final user = snapshot.data;
        if (user == null) return _buildOnboardingPrompt(context);

        final days = user.daysSinceQuit;
        final moneySaved = user.dailyCost * days;
        return FutureBuilder<int>(
          future: _streakFuture,
          builder: (context, streakSnapshot) {
            final streak = streakSnapshot.data ?? 0;
            return Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('坚持戒断', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      '$days 天',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '已节省 ¥${moneySaved.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (streak > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '连续记录 $streak 天',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOnboardingPrompt(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/onboarding/assessment'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.rocket_launch, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('开始你的戒断之旅', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '完成评估，制定个性化计划',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/onboarding/assessment'),
                child: const Text('开始评估'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection(BuildContext context) {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

        final days = user.daysSinceQuit;
        final moneySaved = user.dailyCost * days;
        final lifeRegained = (user.dailyLifeRegainedMinutes * days).toStringAsFixed(0);
        final cigarettesAvoided = user.estimatedDailyCigarettes * days;
        final drinksAvoided = user.estimatedDailyDrinks * days;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('快速统计', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: user.targetType != TargetType.alcohol ? Icons.smoking_rooms : Icons.local_bar,
                    label: '已避免',
                    value: user.targetType != TargetType.alcohol ? '$cigarettesAvoided 支' : '$drinksAvoided 杯',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.savings, label: '已节省', value: '¥${moneySaved.toStringAsFixed(0)}', color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer, label: '生命恢复', value: '$lifeRegained 分钟', color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.auto_graph, label: '日成本', value: '¥${user.dailyCost.toStringAsFixed(1)}', color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快速操作', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.edit_note, label: '今日记录', onTap: () => context.push('/action/daily-log'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.warning_amber, label: 'SOS紧急', onTap: () => context.push('/action/urge-toolkit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.school, label: 'CBT练习', onTap: () => context.push('/action/skills-lab'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentLogsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('最近记录', style: Theme.of(context).textTheme.titleMedium),
            TextButton(onPressed: () => context.go('/action'), child: const Text('查看全部')),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<DailyLogEntry>>(
          future: _recentLogsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2))));
            }
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '还没有记录，开始记录你的第一天吧',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: logs.map((log) => _LogEntryTile(log: log)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBadgesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('我的徽章', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder<List<AppBadge>>(
          future: _badgesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            }
            final badges = snapshot.data ?? [];
            if (badges.isEmpty) {
              return SizedBox(
                height: 60,
                child: Center(
                  child: Text(
                    '坚持记录就能获得徽章',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          _badgeIcon(badge.code),
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(badge.name, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _badgeIcon(String code) {
    switch (code) {
      case 'first_log': return Icons.emoji_events;
      case 'day_1': return Icons.star;
      case 'day_7': return Icons.auto_awesome;
      case 'day_30': return Icons.diamond;
      case 'day_90': return Icons.military_tech;
      case 'day_365': return Icons.workspace_premium;
      default: return Icons.emoji_events;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final DailyLogEntry log;
  const _LogEntryTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateStr = '${log.date.month}月${log.date.day}日';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: log.relapsed
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            log.relapsed ? Icons.error_outline : Icons.check_circle_outline,
            color: log.relapsed ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text('$dateStr - 情绪${log.mood}/5'),
        subtitle: Text(
          log.triggers != null && log.triggers!.isNotEmpty ? '诱因: ${log.triggers!.join(", ")}' : log.notes ?? '无备注',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: log.urgeLevel != null
            ? Text(
                '渴望 ${log.urgeLevel}/10',
                style: TextStyle(
                  color: log.urgeLevel! > 7
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              )
            : null,
      ),
    );
  }
}

class ActionTabScreen extends StatelessWidget {
  const ActionTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('行动改变')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionTile(
            icon: Icons.psychology, title: '渴望管理工具箱', subtitle: '冲浪法、替代行为、SOS求助',
            onTap: () => context.push('/action/urge-toolkit'),
          ),
          _ActionTile(
            icon: Icons.edit_note, title: '每日记录', subtitle: '记录情绪、诱因和应对方式',
            onTap: () => context.push('/action/daily-log'),
          ),
          _ActionTile(
            icon: Icons.school, title: 'CBT技能训练', subtitle: '认知行为疗法技巧学习',
            onTap: () => context.push('/action/skills-lab'),
          ),
        ],
      ),
    );
  }
}

class MaintenanceTabScreen extends StatelessWidget {
  const MaintenanceTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('维持防复发')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionTile(
            icon: Icons.shield, title: '复发预防计划', subtitle: '高危情境预案和应对策略',
            onTap: () => context.push('/maintenance/relapse-plan'),
          ),
          _ActionTile(
            icon: Icons.fitness_center, title: '生活方式重塑', subtitle: '运动、冥想、健康习惯',
            onTap: () => context.push('/maintenance/lifestyle'),
          ),
        ],
      ),
    );
  }
}

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionTile(
            icon: Icons.assessment, title: '评估报告', subtitle: '查看你的依赖性评估结果',
            onTap: () => context.push('/onboarding/assessment'),
          ),
          _ActionTile(
            icon: Icons.settings, title: '设置', subtitle: '通知、提醒、偏好设置',
            onTap: () => context.push('/profile/settings'),
          ),
          _ActionTile(
            icon: Icons.download, title: '导出数据', subtitle: '导出你的记录和报告',
            onTap: () => context.push('/profile/export'),
          ),
          _ActionTile(
            icon: Icons.info_outline, title: '关于', subtitle: '版本信息、隐私政策、免责声明',
            onTap: () => context.push('/profile/about'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
