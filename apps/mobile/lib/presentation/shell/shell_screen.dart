import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/widgets/widget_service.dart';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/companion.dart';
import '../../domain/entity/daily_task.dart';
import '../../core/daily_task/daily_task_generator.dart';

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
  Future<GameProfile?>? _gameProfileFuture;

  int _selectedMood = 3;
  int _selectedUrge = 1;

  // XP animation state
  String? _floatingXpText;
  bool _showXpAnimation = false;

  // Daily task state
  List<DailyTask> _dailyTasks = [];
  final Set<String> _completedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _initDailyTasks();
  }

  void _initDailyTasks() {
    _userFuture?.then((user) {
      if (mounted) {
        setState(() {
          _dailyTasks = DailyTaskGenerator.generateForToday(user);
        });
      }
    });
  }

  void _loadData() {
    final uc = ref.read(userUseCaseProvider);
    final lc = ref.read(logUseCaseProvider);
    final gc = ref.read(gameUseCaseProvider);
    _userFuture = uc.getCurrentUser().then((user) async {
      // Check and auto-advance user stage based on days since quit
      final updated = await uc.checkAndAdvanceStage();
      return updated ?? user;
    });
    _todayLogFuture = lc.getTodayLog();
    _gameProfileFuture = _userFuture?.then((user) {
      if (user != null) return gc.getGameProfile(user.id);
      return Future<GameProfile?>.value(null);
    });
    if (mounted) setState(() {});
    _initDailyTasks();
  }

  Future<void> _saveCheckin() async {
    final lc = ref.read(logUseCaseProvider);
    await lc.logToday(mood: _selectedMood, urgeLevel: _selectedUrge);
    final user = await ref.read(userUseCaseProvider).getCurrentUser();
    if (user != null) {
      final gc = ref.read(gameUseCaseProvider);
      final updated = await gc.processCheckin(user.id);
      if (updated != null) {
        _showXpGain('+${XpRewards.dailyCheckin + updated.streakDays * XpRewards.streakBonus} XP');
      }
    }
    await WidgetService.updateWidget(user);
    _loadData();
  }

  String get _dailyQuote {
    final quotes = [
      '"每一次抵抗，你都在重写自己的大脑。"',
      '"平均需要6-30次尝试——你只是还没到达终点。"',
      '"渴望像海浪，会来也会走。你不需要和它对抗。"',
      '"你的身体在20分钟内就开始修复。"',
      '"一年后，你的冠心病风险降低50%。"',
      '"运动可以在15分钟内减少50%的渴求感。"',
      '"你不是在放弃什么——你是在赢得自由。"',
      '"每一个不抽烟/不喝酒的时刻，都是胜利。"',
    ];
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return quotes[dayOfYear % quotes.length];
  }

  void _showXpGain(String text) {
    setState(() {
      _floatingXpText = text;
      _showXpAnimation = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showXpAnimation = false;
        });
      }
    });
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
                _buildLevelBar(),
                _buildGreeting(),
                _buildBodyRecovery(),
                _buildStatCards(),
                _buildCheckin(),
                _buildDailyTasks(),
                _buildCompanionPreview(),
                _buildSosButton(),
                _buildTimeline(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBar() {
    return FutureBuilder<GameProfile?>(
      future: _gameProfileFuture,
      builder: (context, snap) {
        final gp = snap.data;
        if (gp == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => context.push('/profile/game-profile'),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Level badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.tertiary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Lv.${gp.level}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${gp.levelEmoji} ${gp.levelTitle}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            // Streak badge
                            if (gp.streakDays > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 2),
                                    Text(
                                      '连续${gp.streakDays}天',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // XP progress bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: gp.levelProgress.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              gp.xpDisplay,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // XP floating animation overlay
              if (_showXpAnimation && _floatingXpText != null)
                Positioned(
                  right: 24,
                  top: -8,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: 1 - value,
                        child: Transform.translate(
                          offset: Offset(0, -30 * value),
                          child: Text(
                            _floatingXpText!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
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
              const SizedBox(height: 8),
              Text(
                _dailyQuote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
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
                        Text(_moodEmoji(log.mood), style: const TextStyle(fontSize: 24)),
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
                        _moodButton('😕', 2),
                        _moodButton('😐', 3),
                        _moodButton('🙂', 4),
                        _moodButton('😊', 5),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _urgePill('无渴望', 1),
                        _urgePill('轻微', 3),
                        _urgePill('中等', 5),
                        _urgePill('较强', 7),
                        _urgePill('强烈', 10),
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
    final Color bgColor = value <= 1 ? Colors.blue.shade50 : value <= 2 ? Colors.indigo.shade50 : value <= 3 ? Colors.grey.shade200 : value <= 4 ? Colors.lime.shade50 : Colors.amber.shade50;
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

  String _moodEmoji(int mood) {
    switch (mood) {
      case 1: return '😢';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😊';
      default: return '😐';
    }
  }

  Widget _buildCompanionPreview() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, userSnap) {
        final user = userSnap.data;
        if (user == null || !user.hasQuitDate) return const SizedBox.shrink();
        final daysSinceQuit = user.daysSinceQuit;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            color: Colors.pink.shade50,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/action/companion'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Text('🤝', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '小明说：',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.pink.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  QuitCompanion.dailyChallenge(daysSinceQuit),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.pink),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyTasks() {
    if (_dailyTasks.isEmpty) return const SizedBox.shrink();
    final completedCount = _dailyTasks.where((t) => _completedTaskIds.contains(t.id)).length;
    final totalXp = _dailyTasks.fold<int>(0, (sum, t) => sum + t.xpReward);
    final earnedXp = _dailyTasks.where((t) => _completedTaskIds.contains(t.id)).fold<int>(0, (sum, t) => sum + t.xpReward);

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
                  const Text('📋', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '今日任务',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedCount/${_dailyTasks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_dailyTasks.length, (i) {
                final task = _dailyTasks[i];
                final isCompleted = _completedTaskIds.contains(task.id);
                return _buildTaskItem(task, isCompleted, i);
              }),
              const SizedBox(height: 8),
              Divider(color: Theme.of(context).colorScheme.surfaceContainerHighest, height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '可获得 $totalXp XP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  if (earnedXp > 0)
                    Text(
                      '已获得 $earnedXp XP',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(DailyTask task, bool isCompleted, int index) {
    final typeColor = switch (task.type) {
      'exercise' => Colors.teal,
      'challenge' => Colors.orange,
      'reflection' => Colors.purple,
      _ => Theme.of(context).colorScheme.primary,
    };
    final typeIcon = switch (task.type) {
      'exercise' => Icons.fitness_center,
      'challenge' => Icons.emoji_events,
      'reflection' => Icons.psychology,
      _ => Icons.check_circle_outline,
    };

    return Padding(
      padding: EdgeInsets.only(top: index > 0 ? 6 : 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isCompleted ? null : () => _completeDailyTask(task),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isCompleted
                ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: isCompleted,
                  onChanged: isCompleted ? null : (_) => _completeDailyTask(task),
                  shape: const CircleBorder(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(typeIcon, size: 14, color: typeColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : null,
                          ),
                    ),
                    Text(
                      task.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? '✓' : '+${task.xpReward}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeDailyTask(DailyTask task) async {
    if (_completedTaskIds.contains(task.id)) return;
    setState(() {
      _completedTaskIds.add(task.id);
    });
    try {
      final user = await ref.read(userUseCaseProvider).getCurrentUser();
      if (user != null) {
        await ref.read(gameUseCaseProvider).awardExerciseCompleted(user.id);
        _showXpGain('+${task.xpReward} XP');
      }
    } catch (e) {
      debugPrint('Dashboard: 完成每日任务失败: $e');
    }
  }

  Widget _buildSosButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _showSosBottomSheet(),
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.emergency, size: 22),
              ),
              label: const Text('渴望来了？按下开始呼吸',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Theme.of(context).colorScheme.error.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push('/action/coach'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '或者跟教练聊聊',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSosBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SosBreathingSheet(),
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


class _SosBreathingSheet extends ConsumerStatefulWidget {
  const _SosBreathingSheet();

  @override
  ConsumerState<_SosBreathingSheet> createState() => _SosBreathingSheetState();
}

class _SosBreathingSheetState extends ConsumerState<_SosBreathingSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  int _secondsRemaining = 180;
  Timer? _timer;
  bool _breathing = true;
  bool _complete = false;
  bool _isSubmitting = false;

  final _phaseMessages = [
    '承认渴望的存在，不评判自己',
    '你不需要和渴望对抗，只需等待',
    '渴望像海浪，会来也会走',
    '每次抵抗，你都在变强',
    '想想你为什么要戒掉',
    '你值得更好的生活',
  ];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _breathing = false;
          _complete = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  int get _currentPhase {
    if (_secondsRemaining > 120) return 1;
    if (_secondsRemaining > 60) return 2;
    return 3;
  }

  String get _phaseLabel {
    switch (_currentPhase) {
      case 1:
        return '承认渴望';
      case 2:
        return '深呼吸放松';
      case 3:
        return '巩固决心';
      default:
        return '';
    }
  }

  String get _phaseInstruction {
    switch (_currentPhase) {
      case 1:
        return '感觉它，观察它，不评判';
      case 2:
        return '跟随圆圈的节奏呼吸';
      case 3:
        return '你已经做到了，再坚持一下';
      default:
        return '';
    }
  }

  Future<void> _onComplete() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final cravingUC = ref.read(cravingUseCaseProvider);
      await cravingUC.logCraving(
        8,
        trigger: 'SOS紧急救援',
        copingUsed: '4-7-8呼吸法+正念',
        resolved: true,
      );
      final badgeRepo = ref.read(badgeRepositoryProvider);
      await badgeRepo.earnBadge('sos_used');
    } catch (_) {
      // Silently handle errors — the user still completed the SOS
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: screenHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.errorContainer,
            colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('退出',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 15)),
                  ),
                  Text('SOS 紧急救援',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 60), // balance
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Phase indicator
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '第$_currentPhase阶段: $_phaseLabel',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _phaseInstruction,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Breathing circle
            if (_breathing)
              AnimatedBuilder(
                animation: _breathController,
                builder: (context, child) {
                  final scale = 1 + _breathController.value * 0.3;
                  final size = 160.0 * scale;
                  final breathValue = _breathController.value;
                  final opacity = 0.15 + breathValue * 0.15;

                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(opacity),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3 + breathValue * 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(opacity * 0.5),
                          blurRadius: 20 * breathValue,
                          spreadRadius: 4 * breathValue,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        breathValue < 0.4
                            ? '吸气'
                            : breathValue < 0.6
                                ? '屏息'
                                : '呼气',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.15),
                  border: Border.all(color: Colors.green, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.check_circle, size: 64, color: Colors.green),
                ),
              ),

            const Spacer(flex: 2),

            // Timer
            Text(
              _complete
                  ? '你撑过去了!'
                  : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: _complete ? 28 : 48,
                fontWeight: FontWeight.bold,
                color: _complete ? Colors.green : colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            // Motivational message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _complete
                      ? '每次抵抗都是胜利，你正在改变自己'
                      : _phaseMessages[
                          _secondsRemaining ~/ 30 % _phaseMessages.length],
                  key: ValueKey(_secondsRemaining ~/ 30),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const Spacer(flex: 2),

            // Complete button
            if (_complete)
              Padding(
                padding: const EdgeInsets.all(32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _onComplete,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.celebration),
                    label: Text(
                      _isSubmitting ? '保存中...' : '我做到了!',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
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
            icon: Icons.smart_toy, title: 'AI戒烟教练', subtitle: '随时聊聊你的感受和挑战',
            onTap: () => context.push('/action/coach'),
            iconBgColor: Colors.purple,
          ),
          _ActionTile(
            icon: Icons.favorite, title: '戒烟伙伴', subtitle: '小明的每日问候和挑战',
            onTap: () => context.push('/action/companion'),
            iconBgColor: Colors.pink,
          ),
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
          _ActionTile(
            icon: Icons.emoji_events, title: '每周挑战', subtitle: '7天打卡挑战，赢取XP奖励',
            onTap: () => context.push('/action/challenge'),
            iconBgColor: Colors.amber,
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
            icon: Icons.stars, title: '我的等级', subtitle: '查看等级、经验和战斗数据',
            onTap: () => context.push('/profile/game-profile'),
            iconBgColor: Colors.deepPurple,
          ),
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
