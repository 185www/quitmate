import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/widgets/widget_service.dart';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';

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

  int _selectedMood = 3;
  int _selectedUrge = 4;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final uc = ref.read(userUseCaseProvider);
    final lc = ref.read(logUseCaseProvider);
    _userFuture = uc.getCurrentUser().then((user) async {
      // Check and auto-advance user stage based on days since quit
      final updated = await uc.checkAndAdvanceStage();
      return updated ?? user;
    });
    _todayLogFuture = lc.getTodayLog();
    if (mounted) setState(() {});
  }

  Future<void> _saveCheckin() async {
    final lc = ref.read(logUseCaseProvider);
    await lc.logToday(mood: _selectedMood, urgeLevel: _selectedUrge);
    final user = await ref.read(userUseCaseProvider).getCurrentUser();
    await WidgetService.updateWidget(user);
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
                Text('准备好了吗？', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('选一个好日子，正式开始', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/preparation/quit-date'),
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('选择开始日期'),
                ),
              ],
            ),
          );
        }
        final days = user.daysSinceQuit;
        // Empathetic, encouraging messages based on days
        String message;
        if (days == 0) {
          message = '今天是最重要的一天，你已经迈出了第一步';
        } else if (days <= 3) {
          message = '最难熬的头几天，你正在坚持，真了不起';
        } else if (days <= 7) {
          message = '第一周了！身体的修复已经悄悄开始';
        } else if (days <= 14) {
          message = '两周了，味觉和嗅觉都在恢复';
        } else if (days <= 30) {
          message = '一个月了，肺部开始清理，体力在回升';
        } else if (days <= 90) {
          message = '$days 天了，你的坚持正在重塑自己';
        } else {
          message = '$days 天，你已经是自己的英雄了';
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('第 $days 天', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, height: 1.1)),
              const SizedBox(height: 4),
              Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Column(
                      children: [
                        const Icon(Icons.savings_outlined, color: Colors.amber, size: 28),
                        const SizedBox(height: 4),
                        Text('已节省', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text('¥${saved.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber.shade700)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Column(
                      children: [
                        const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
                        const SizedBox(height: 4),
                        Text('生命', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text('+$lifeDays 天',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade400)),
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
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text('今日已记录', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('心情: ', style: Theme.of(context).textTheme.bodySmall),
                        Text(log.mood <= 2 ? '😢' : log.mood <= 4 ? '😐' : '😊', style: const TextStyle(fontSize: 24)),
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
                        _moodButton('😐', 3),
                        _moodButton('😊', 5),
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
    final Color bgColor = value <= 2 ? Colors.blue.shade50 : value <= 4 ? Colors.grey.shade200 : Colors.amber.shade50;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedOpacity(
          opacity: selected ? 1 : 0.35,
          duration: const Duration(milliseconds: 200),
          child: Text(emoji, style: TextStyle(fontSize: selected ? 36 : 28)),
        ),
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
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/action/urge-toolkit'),
          icon: const Icon(Icons.emergency, size: 22),
          label: const Text('渴望来了？帮你撑过去', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
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
            iconBgColor: Colors.deepPurple,
          ),
          _ActionTile(
            icon: Icons.edit_note, title: '每日记录', subtitle: '记录情绪、诱因和应对方式',
            onTap: () => context.push('/action/daily-log'),
            iconBgColor: Colors.teal,
          ),
          _ActionTile(
            icon: Icons.school, title: 'CBT技能训练', subtitle: '认知行为疗法技巧学习',
            onTap: () => context.push('/action/skills-lab'),
            iconBgColor: Colors.indigo,
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
            iconBgColor: Colors.orange,
          ),
          _ActionTile(
            icon: Icons.fitness_center, title: '生活方式重塑', subtitle: '运动、冥想、健康习惯',
            onTap: () => context.push('/maintenance/lifestyle'),
            iconBgColor: Colors.green,
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
            icon: Icons.analytics, title: '高危场景分析', subtitle: '查看你的渴望触发场景报告',
            onTap: () => context.push('/profile/analysis'),
            iconBgColor: Colors.blue,
          ),
          _ActionTile(
            icon: Icons.assessment, title: '评估报告', subtitle: '查看你的依赖性评估结果',
            onTap: () => context.push('/onboarding/assessment'),
            iconBgColor: Colors.blue,
          ),
          _ActionTile(
            icon: Icons.emoji_events, title: '我的成就', subtitle: '查看已获得的徽章',
            onTap: () => context.push('/profile/badges'),
            iconBgColor: Colors.amber,
          ),
          _ActionTile(
            icon: Icons.settings, title: '设置', subtitle: '通知、提醒、偏好设置',
            onTap: () => context.push('/profile/settings'),
            iconBgColor: Colors.grey,
          ),
          _ActionTile(
            icon: Icons.download, title: '导出数据', subtitle: '导出你的记录和报告',
            onTap: () => context.push('/profile/export'),
            iconBgColor: Colors.teal,
          ),
          _ActionTile(
            icon: Icons.info_outline, title: '关于', subtitle: '版本信息、隐私政策、免责声明',
            onTap: () => context.push('/profile/about'),
            iconBgColor: Colors.blue,
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
  final Color iconBgColor;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.iconBgColor = const Color(0xFF6750A4)});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconBgColor.withOpacity(0.15),
          child: Icon(icon, color: iconBgColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
