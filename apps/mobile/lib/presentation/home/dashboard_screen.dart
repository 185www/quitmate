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
import 'sos_breathing_sheet.dart';

/// Modern minimalist dashboard – hero timer, stat cards, check-in,
/// AI insight card, daily tasks, milestone timeline, and SOS button.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<User?>? _userFuture;
  Future<DailyLogEntry?>? _todayLogFuture;
  Future<GameProfile?>? _gameProfileFuture;

  int _selectedMood = 3;
  int _selectedUrge = 1;

  // XP floating animation state
  String? _floatingXpText;
  bool _showXpAnimation = false;

  // Daily task state
  List<DailyTask> _dailyTasks = [];
  final Set<String> _completedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final uc = ref.read(userUseCaseProvider);
    final lc = ref.read(logUseCaseProvider);
    final gc = ref.read(gameUseCaseProvider);
    _userFuture = uc.getCurrentUser().then((user) async {
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

  void _initDailyTasks() {
    _userFuture?.then((user) {
      if (mounted) {
        setState(() {
          _dailyTasks = DailyTaskGenerator.generateForToday(user);
        });
      }
    });
  }

  Future<void> _saveCheckin() async {
    final lc = ref.read(logUseCaseProvider);
    await lc.logToday(mood: _selectedMood, urgeLevel: _selectedUrge);
    final user = await ref.read(userUseCaseProvider).getCurrentUser();
    if (user != null) {
      final gc = ref.read(gameUseCaseProvider);
      final updated = await gc.processCheckin(user.id);
      if (updated != null) {
        _showXpGain(
            '+${XpRewards.dailyCheckin + updated.streakDays * XpRewards.streakBonus} XP');
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
      '"每一个不使用的时刻，都是胜利。"',
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

  String _moodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😊';
      default:
        return '😐';
    }
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

  void _showSosBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const SosBreathingSheet(),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildLevelBar(),
              _buildHeroTimer(),
              _buildQuickStats(),
              const SizedBox(height: 6),
              _buildCheckin(),
              const SizedBox(height: 6),
              _buildAiInsightCard(),
              const SizedBox(height: 6),
              _buildDailyTasks(),
              const SizedBox(height: 6),
              _buildCompanionPreview(),
              _buildSosButton(),
              _buildNextMilestone(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // LEVEL BAR (compact XP strip at top)
  // ──────────────────────────────────────────────────────────────

  Widget _buildLevelBar() {
    return FutureBuilder<GameProfile?>(
      future: _gameProfileFuture,
      builder: (context, snap) {
        final gp = snap.data;
        if (gp == null) return const SizedBox.shrink();
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: GestureDetector(
            onTap: () => context.push('/profile/game-profile'),
            child: Row(
              children: [
                // Level badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.tertiary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lv.${gp.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${gp.levelEmoji} ${gp.levelTitle}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 6),
                // Streak pill
                if (gp.streakDays > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 2),
                        Text(
                          '${gp.streakDays}天',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // XP progress mini bar
                SizedBox(
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: gp.levelProgress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor:
                          AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  gp.xpDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    size: 16, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  // HERO TIMER — "第 X 天" centrepiece
  // ──────────────────────────────────────────────────────────────

  Widget _buildHeroTimer() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snap) {
        final user = snap.data;
        final colorScheme = Theme.of(context).colorScheme;

        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 180, child: Center(child: CircularProgressIndicator()));
        }

        if (user == null || !user.hasQuitDate) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '准备好了吗？',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '选一个好日子，正式开始你的戒断之旅',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.push('/preparation/quit-date'),
                  icon: const Icon(Icons.edit_calendar_rounded),
                  label: const Text('选择开始日期'),
                ),
              ],
            ),
          );
        }

        final days = user.daysSinceQuit;
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
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big day counter
              Text(
                '第 $days 天',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 48,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                _dailyQuote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.65),
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  // QUICK STATS ROW — 3 subtle cards
  // ──────────────────────────────────────────────────────────────

  Widget _buildQuickStats() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null || !user.hasQuitDate) return const SizedBox.shrink();
        final colorScheme = Theme.of(context).colorScheme;
        final days = user.daysSinceQuit;
        final saved = user.dailyCost * days;
        final lifeMinutes = user.dailyLifeRegainedMinutes * days;
        final lifeDays = (lifeMinutes / 1440).toStringAsFixed(0);

        return FutureBuilder<GameProfile?>(
          future: _gameProfileFuture,
          builder: (context, gpSnap) {
            final streak = gpSnap.data?.streakDays ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _statCard(
                    Icons.savings_outlined,
                    '已节省',
                    '¥${saved.toStringAsFixed(0)}',
                    colorScheme.primaryContainer.withOpacity(0.5),
                    colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    Icons.favorite_rounded,
                    '生命延长',
                    '+$lifeDays 天',
                    colorScheme.errorContainer.withOpacity(0.5),
                    colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    Icons.local_fire_department_rounded,
                    '连续签到',
                    '$streak 天',
                    colorScheme.tertiaryContainer.withOpacity(0.5),
                    colorScheme.tertiary,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statCard(
      IconData icon, String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // CHECK-IN — mood + urge pill selectors
  // ──────────────────────────────────────────────────────────────

  Widget _buildCheckin() {
    return FutureBuilder<DailyLogEntry?>(
      future: _todayLogFuture,
      builder: (context, snap) {
        final log = snap.data;
        final logged = log != null;
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (logged) ...[
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '今日已记录',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('心情 ',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(_moodEmoji(log.mood),
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 20),
                      Text('渴望 ',
                          style: Theme.of(context).textTheme.bodySmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (log.urgeLevel != null && log.urgeLevel! > 5)
                              ? colorScheme.errorContainer.withOpacity(0.6)
                              : colorScheme.primaryContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          log.urgeLevel != null
                              ? (log.urgeLevel! <= 3
                                  ? '无渴望'
                                  : log.urgeLevel! <= 6
                                      ? '有点想'
                                      : '非常想')
                              : '无',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (log.urgeLevel != null &&
                                    log.urgeLevel! > 5)
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '今天感觉怎么样？',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 14),
                  // Mood emojis
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
                  const SizedBox(height: 14),
                  // Urge pills
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
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 36,
                      child: FilledButton.tonal(
                        onPressed: _saveCheckin,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('保存打卡'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _moodButton(String emoji, int value) {
    final selected = _selectedMood == value;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedMood = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withOpacity(0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          shape: BoxShape.rectangle,
        ),
        child: AnimatedOpacity(
          opacity: selected ? 1.0 : 0.35,
          duration: const Duration(milliseconds: 200),
          child: Text(emoji, style: TextStyle(fontSize: selected ? 34 : 28)),
        ),
      ),
    );
  }

  Widget _urgePill(String label, int value) {
    final selected = _selectedUrge == value;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedUrge = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // AI INSIGHT CARD (placeholder)
  // ──────────────────────────────────────────────────────────────

  Widget _buildAiInsightCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
              Theme.of(context).colorScheme.tertiary.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日AI洞察',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '分析你的记录后，为你提供个性化建议',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // DAILY TASKS — clean checklist
  // ──────────────────────────────────────────────────────────────

  Widget _buildDailyTasks() {
    if (_dailyTasks.isEmpty) return const SizedBox.shrink();
    final completedCount =
        _dailyTasks.where((t) => _completedTaskIds.contains(t.id)).length;
    final totalXp =
        _dailyTasks.fold<int>(0, (sum, t) => sum + t.xpReward);
    final earnedXp = _dailyTasks
        .where((t) => _completedTaskIds.contains(t.id))
        .fold<int>(0, (sum, t) => sum + t.xpReward);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(Icons.task_alt_rounded,
                    color: colorScheme.primary, size: 20),
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
                    color: colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedCount/${_dailyTasks.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_dailyTasks.length, (i) {
              final task = _dailyTasks[i];
              final isCompleted = _completedTaskIds.contains(task.id);
              return _buildTaskItem(task, isCompleted, i);
            }),
            const SizedBox(height: 10),
            Divider(
                color: colorScheme.surfaceContainerHighest, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star_rounded,
                    size: 14, color: colorScheme.tertiary),
                const SizedBox(width: 4),
                Text(
                  '可获得 $totalXp XP',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (earnedXp > 0)
                  Text(
                    '已获得 $earnedXp XP',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(DailyTask task, bool isCompleted, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    final typeColor = switch (task.type) {
      'exercise' => colorScheme.primary,
      'challenge' => colorScheme.tertiary,
      'reflection' => colorScheme.secondary,
      _ => colorScheme.primary,
    };
    final typeIcon = switch (task.type) {
      'exercise' => Icons.fitness_center_rounded,
      'challenge' => Icons.emoji_events_rounded,
      'reflection' => Icons.psychology_rounded,
      _ => Icons.check_circle_outline_rounded,
    };

    return Padding(
      padding: EdgeInsets.only(top: index > 0 ? 8 : 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isCompleted ? null : () => _completeDailyTask(task),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isCompleted
                ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isCompleted,
                  onChanged: isCompleted
                      ? null
                      : (_) => _completeDailyTask(task),
                  shape: const CircleBorder(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, size: 14, color: typeColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      task.description,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? colorScheme.primary.withOpacity(0.1)
                      : colorScheme.tertiaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? '✓' : '+${task.xpReward}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? colorScheme.primary
                        : colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // COMPANION PREVIEW
  // ──────────────────────────────────────────────────────────────

  Widget _buildCompanionPreview() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, userSnap) {
        final user = userSnap.data;
        if (user == null || !user.hasQuitDate) return const SizedBox.shrink();
        final daysSinceQuit = user.daysSinceQuit;
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push('/action/companion'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Text('🤝', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '小明说：',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          QuitCompanion.dailyChallenge(daysSinceQuit),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SOS BUTTON — warm, not harsh
  // ──────────────────────────────────────────────────────────────

  Widget _buildSosButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showSosBottomSheet(),
              icon: const Icon(Icons.air_rounded, size: 20),
              label: const Text(
                '渴望来了？呼吸一下',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push('/action/coach'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '或者跟AI教练聊聊',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // NEXT MILESTONE TIMELINE — horizontal dots
  // ──────────────────────────────────────────────────────────────

  Widget _buildNextMilestone() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null || !user.hasQuitDate) return const SizedBox.shrink();
        final colorScheme = Theme.of(context).colorScheme;
        final days = user.daysSinceQuit;
        final milestones = HealthMilestone.milestones;

        // Find current index
        int currentIdx = 0;
        for (int i = milestones.length - 1; i >= 0; i--) {
          if (milestones[i]['days'] <= days) {
            currentIdx = i;
            break;
          }
        }

        // Next 3 milestones
        final next = <Map<String, dynamic>>[];
        for (int i = currentIdx + 1;
            i < milestones.length && next.length < 3;
            i++) {
          next.add(milestones[i]);
        }
        if (next.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '下一个里程碑',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(next.length * 2 - 1, (idx) {
                  final isDot = idx.isEven;
                  final i = idx ~/ 2;

                  if (!isDot) {
                    // Connector line
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: colorScheme.surfaceContainerHighest,
                      ),
                    );
                  }

                  // Dot + label
                  return Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i == 0
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == 0
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: i == 0
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant,
                                  width: 2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i == 0
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          next[i]['title'],
                          style: TextStyle(
                            fontSize: 11,
                            color: i == 0
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight:
                                i == 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${next[i]['days']} 天',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
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
