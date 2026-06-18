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
  Future<DailyLogEntry?>? _todayLogFuture;

  int _selectedMood = 2;
  int _selectedUrge = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final uc = ref.read(userUseCaseProvider);
    final lc = ref.read(logUseCaseProvider);
    _userFuture = uc.getCurrentUser();
    _todayLogFuture = lc.getTodayLog();
    if (mounted) setState(() {});
  }

  Future<void> _saveCheckin() async {
    final lc = ref.read(logUseCaseProvider);
    await lc.logToday(mood: _selectedMood, urgeLevel: _selectedUrge);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                _buildGreeting(),
                _buildBodyRecovery(),
                _buildStatCards(),
                _buildCheckin(),
                _buildSosButton(),
                _buildTimeline(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snap) {
        final user = snap.data;
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }
        if (user == null || !user.hasQuitDate) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
            child: Column(
              children: [
                Text('开始你的旅程', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w300)),
                const SizedBox(height: 4),
                Text('设定一个目标', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/onboarding/assessment'),
                  child: const Text('开始'),
                ),
              ],
            ),
          );
        }
        final days = user.daysSinceQuit;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('第 $days 天', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w200, height: 1.1)),
              const SizedBox(height: 4),
              Text('你的身体正在恢复', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBodyRecovery() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null || !user.hasQuitDate) return const SizedBox.shrink();
        final days = user.daysSinceQuit;
        final milestones = HealthMilestone.milestones;
        Map<String, dynamic>? current;
        for (int i = milestones.length - 1; i >= 0; i--) {
          if (milestones[i]['days'] <= days) {
            current = milestones[i];
            break;
          }
        }
        final pct = (current?['pct'] as int? ?? 0).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text('身体恢复 ${pct.toInt()}%', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
              if (current != null) ...[
                const SizedBox(height: 2),
                Text('${current['organ']} — ${current['title']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null || !user.hasQuitDate) return const SizedBox.shrink();
        final days = user.daysSinceQuit;
        final saved = user.dailyCost * days;
        final lifeMinutes = user.dailyLifeRegainedMinutes * days;
        final lifeDays = (lifeMinutes / 1440).toStringAsFixed(0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Column(
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text('已节省', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text('¥${saved.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Column(
                      children: [
                        const Text('❤️', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text('生命', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text('+$lifeDays 天',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckin() {
    return FutureBuilder<DailyLogEntry?>(
      future: _todayLogFuture,
      builder: (context, snap) {
        final log = snap.data;
        final logged = log != null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (logged) ...[
                    Row(
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text('今日已记录', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('心情: ', style: Theme.of(context).textTheme.bodySmall),
                        Text(['😢', '😐', '😊'][(log.mood - 1).clamp(0, 2)], style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 24),
                        Text('渴望: ', style: Theme.of(context).textTheme.bodySmall),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: log.urgeLevel != null && log.urgeLevel! > 5
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            log.urgeLevel != null
                                ? (log.urgeLevel! <= 3 ? '无渴望' : log.urgeLevel! <= 6 ? '有点想' : '非常想')
                                : '无',
                            style: TextStyle(
                              fontSize: 13,
                              color: log.urgeLevel != null && log.urgeLevel! > 5
                                  ? Colors.orange.shade800
                                  : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text('今天感觉怎么样？', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _moodButton('😢', 1),
                        _moodButton('😐', 2),
                        _moodButton('😊', 3),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _urgePill('无渴望', 1),
                        _urgePill('有点想', 4),
                        _urgePill('非常想', 8),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: SizedBox(
                        height: 32,
                        child: TextButton(
                          onPressed: _saveCheckin,
                          child: const Text('保存', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _moodButton(String emoji, int value) {
    final selected = _selectedMood == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = value),
      child: AnimatedOpacity(
        opacity: selected ? 1 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Text(emoji, style: TextStyle(fontSize: selected ? 36 : 28)),
      ),
    );
  }

  Widget _urgePill(String label, int value) {
    final selected = _selectedUrge == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedUrge = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSosButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/action/urge-toolkit'),
          icon: const Icon(Icons.self_improvement, size: 22),
          label: const Text('SOS 呼吸法', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null || !user.hasQuitDate) return const SizedBox.shrink();
        final days = user.daysSinceQuit;
        final milestones = HealthMilestone.milestones;
        int currentIdx = 0;
        for (int i = milestones.length - 1; i >= 0; i--) {
          if (milestones[i]['days'] <= days) {
            currentIdx = i;
            break;
          }
        }
        final next = <Map<String, dynamic>>[];
        for (int i = currentIdx + 1; i < milestones.length && next.length < 3; i++) {
          next.add(milestones[i]);
        }
        if (next.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('下一个里程碑', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(next.length, (i) {
                  return Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (i > 0)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == 0 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                border: Border.all(
                                  color: i == 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                                  width: 2,
                                ),
                              ),
                            ),
                            if (i < next.length - 1)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(next[i]['title'], style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${next[i]['days']} 天', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
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
