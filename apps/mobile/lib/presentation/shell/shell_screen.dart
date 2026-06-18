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
  Future<DailyLogEntry?>? _todayLogFuture;

  int _selectedMood = 3;
  int _selectedUrge = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final uc = ref.read(userUseCaseProvider);
    final lc = ref.read(logUseCaseProvider);
    final bc = ref.read(badgeUseCaseProvider);
    _userFuture = uc.getCurrentUser();
    _streakFuture = lc.getStreakDays();
    _recentLogsFuture = lc.getRecentLogs(limit: 7);
    _badgesFuture = bc.getEarnedBadges();
    _todayLogFuture = lc.getTodayLog();
    if (mounted) setState(() {});
  }

  int _calcLevel(int xp) {
    int level = 1;
    while (level * level * 100 <= xp) level++;
    return level;
  }

  int _nextXp(int level) => level * 100;

  Future<void> _saveCheckin() async {
    final lc = ref.read(logUseCaseProvider);
    final uc = ref.read(userUseCaseProvider);
    await lc.logToday(mood: _selectedMood, urgeLevel: _selectedUrge);
    final prefs = await uc.getPreferences();
    final xp = (prefs['total_xp'] as int? ?? 0) + 10;
    prefs['total_xp'] = xp;
    await uc.savePreferences(prefs);
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
                _buildStreakCard(),
                _buildBodyRecovery(),
                _buildCheckin(),
                _buildSosButton(),
                _buildLevelBadges(),
                _buildTrend(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snap) {
        final user = snap.data;
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        }
        if (user == null || !user.hasQuitDate) {
          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFF7C948)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/onboarding/assessment'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Column(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('开始你的旅程', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        final days = user.daysSinceQuit;
        final saved = user.dailyCost * days;
        return FutureBuilder<int>(
          future: _streakFuture,
          builder: (context, ssnap) {
            final streak = ssnap.data ?? 0;
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: streak > 0
                      ? [const Color(0xFFFF4500), const Color(0xFFFF8C00)]
                      : [const Color(0xFFFF6B35), const Color(0xFFF7C948)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 40 + (streak > 3 ? 8 : streak > 0 ? 4 : 0))),
                        if (streak > 1) ...[
                          const SizedBox(width: 4),
                          Text('🔥' * (streak > 3 ? 3 : streak), style: const TextStyle(fontSize: 14)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Day $days', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                    const SizedBox(height: 6),
                    Text('已节省 ¥${saved.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                    if (streak > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                          child: Text('🔥 连续 $streak 天', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
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
        Map<String, dynamic>? current, next;
        for (int i = milestones.length - 1; i >= 0; i--) {
          if (milestones[i]['days'] <= days) {
            current = milestones[i];
            if (i + 1 < milestones.length) next = milestones[i + 1];
            break;
          }
        }
        final pct = (current?['pct'] as int? ?? 0).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🫁', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text('身体恢复 ${pct.toInt()}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 10,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        pct < 50 ? Colors.orange : pct < 80 ? Colors.green : Colors.teal,
                      ),
                    ),
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 6),
                    Text('下一里程碑: ${next['title']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckin() {
    return FutureBuilder<DailyLogEntry?>(
      future: _todayLogFuture,
      builder: (context, snap) {
        final logged = snap.data != null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('今日打卡', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (logged) ...[
                    const Center(child: Text('✅ 已记录', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green))),
                  ] else ...[
                    Text('心情', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['😢', '😐', '🙂', '😊', '🤩'].asMap().entries.map((e) {
                        final i = e.key + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = i),
                          child: AnimatedOpacity(
                            opacity: _selectedMood == i ? 1 : 0.4,
                            duration: const Duration(milliseconds: 200),
                            child: Text(e.value, style: TextStyle(fontSize: _selectedMood == i ? 34 : 26)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Text('渴望程度', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (i) {
                        final level = i + 1;
                        final colors = [Colors.green, Colors.lightGreen, Colors.amber, Colors.orange, Colors.red];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedUrge = level),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _selectedUrge >= level ? colors[i] : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: Text('$level', style: TextStyle(color: _selectedUrge >= level ? Colors.white : Colors.grey, fontSize: 12))),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        height: 30,
                        child: TextButton.icon(
                          onPressed: _saveCheckin,
                          icon: const Icon(Icons.save, size: 14),
                          label: const Text('保存', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
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

  Widget _buildSosButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/action/urge-toolkit'),
          icon: const Icon(Icons.warning_amber_rounded, size: 26),
          label: const Text('SOS 紧急应对', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadges() {
    return FutureBuilder<List<AppBadge>>(
      future: _badgesFuture,
      builder: (context, snap) {
        final badges = snap.data ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<Map<String, dynamic>>(
                    future: ref.read(userUseCaseProvider).getPreferences(),
                    builder: (context, psnap) {
                      final prefs = psnap.data ?? {};
                      final xp = (prefs['total_xp'] as int? ?? 0);
                      final level = _calcLevel(xp);
                      final nextXp = _nextXp(level);
                      final prevXp = _nextXp(level - 1);
                      final progress = (xp - prevXp) / (nextXp - prevXp);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('等级 Lv.$level', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    Text('总XP $xp', style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              ...badges.take(4).map((b) => Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Tooltip(
                                  message: b.name,
                                  child: CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(_badgeIcon(b.code), size: 16, color: Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                              )),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                progress >= 1 ? Colors.amber : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrend() {
    return FutureBuilder<List<DailyLogEntry>>(
      future: _recentLogsFuture,
      builder: (context, snap) {
        final logs = snap.data ?? [];
        if (logs.isEmpty) return const SizedBox.shrink();
        final moods = ['', '😢', '😐', '🙂', '😊', '🤩'];
        final urgeColors = [Colors.grey, Colors.green, Colors.lightGreen, Colors.amber, Colors.orange, Colors.red];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('每周趋势', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: logs.reversed.toList().map((log) {
                      final dayStr = ['一', '二', '三', '四', '五', '六', '日'][log.date.weekday - 1];
                      return Column(
                        children: [
                          Text(moods[log.mood.clamp(1, 5)], style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: log.urgeLevel != null ? urgeColors[log.urgeLevel!.clamp(0, 5)] : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(dayStr, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
