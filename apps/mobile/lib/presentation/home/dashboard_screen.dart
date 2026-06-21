import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/di/ai_providers.dart';
import '../../core/widgets/widget_service.dart';
import '../../core/widgets/widget_service_v2.dart';
import '../../core/coach/ai_agent_service.dart';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/daily_task.dart';
import '../../core/daily_task/daily_task_generator.dart';
import 'sos_breathing_sheet.dart';
import 'widgets/hero_timer.dart';
import 'widgets/checkin_card.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/daily_task_list.dart';
import 'widgets/companion_preview_card.dart';
import 'widgets/sos_button_section.dart';
import 'widgets/milestone_timeline.dart';
import 'widgets/virtual_plant_card.dart';
import 'widgets/money_savings_animator.dart';
import 'widgets/health_insight_card.dart';

/// Modern minimalist dashboard – hero timer, stat cards, check-in,
/// AI insight card, daily tasks, milestone timeline, and SOS button.
///
/// The build method composes standalone widgets extracted into
/// `widgets/`, keeping only state management and orchestration logic
/// in this file.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<User?>? _userFuture;
  Future<DailyLogEntry?>? _todayLogFuture;
  Future<GameProfile?>? _gameProfileFuture;

  // XP floating animation state
  // String? _floatingXpText; // unused
  // bool _showXpAnimation = false; // unused

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

  Future<void> _saveCheckin(int mood, int urge) async {
    final lc = ref.read(logUseCaseProvider);
    await lc.logToday(mood: mood, urgeLevel: urge);
    final user = await ref.read(userUseCaseProvider).getCurrentUser();
    if (user != null) {
      final gc = ref.read(gameUseCaseProvider);
      final updated = await gc.processCheckin(user.id);
      if (updated != null) {
        _showXpGain(
            '+${XpRewards.dailyCheckin + updated.streakDays * XpRewards.streakBonus} XP');
      }
    }
    // Use WidgetServiceV2 for enriched widget data
    final gameProfile = user != null
        ? await ref.read(gameUseCaseProvider).getGameProfile(user.id)
        : null;
    final todayLog = await lc.getTodayLog();
    await WidgetServiceV2.updateWidgetData(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
      cravingIntensity: urge,
      dailyTasksCompleted: _completedTaskIds.length,
      dailyTasksTotal: _dailyTasks.length,
      llmService: AiAgentService.instance.llmService,
    );
    _loadData();
  }

  void _showXpGain(String text) {
    setState(() {
      // _floatingXpText = text;
      // _showXpAnimation = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          // _showXpAnimation = false;
        });
      }
    });
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
        onRefresh: () async {
          _loadData();
          // Also refresh the AI insight card
          ref.invalidate(dailyInsightProvider);
        },
        color: colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildLevelBar(),
              HeroTimerSection(userFuture: _userFuture!),
              QuickStatsRow(
                userFuture: _userFuture!,
                gameProfileFuture: _gameProfileFuture!,
              ),
              const SizedBox(height: 6),
              CheckinCard(
                todayLogFuture: _todayLogFuture!,
                onSave: _saveCheckin,
              ),
              const SizedBox(height: 6),
              const AiInsightCard(), // ConsumerStatefulWidget — self-managed
              const SizedBox(height: 6),
              const HealthInsightCard(),
              const SizedBox(height: 6),
              DailyTaskList(
                tasks: _dailyTasks,
                completedTaskIds: _completedTaskIds,
                onComplete: _completeDailyTask,
              ),
              const SizedBox(height: 6),
              _GamificationSection(
                userFuture: _userFuture!,
                gameProfileFuture: _gameProfileFuture!,
              ),
              const SizedBox(height: 6),
              CompanionPreviewCard(userFuture: _userFuture!),
              SosButtonSection(
                onSos: _showSosBottomSheet,
                onCoach: () => context.push('/action/coach'),
              ),
              MilestoneTimeline(userFuture: _userFuture!),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
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
}

// ──────────────────────────────────────────────────────────────
// GAMIFICATION SECTION (virtual plant + money savings)
// ──────────────────────────────────────────────────────────────

class _GamificationSection extends StatelessWidget {
  final Future<User?> userFuture;
  final Future<GameProfile?> gameProfileFuture;

  const _GamificationSection({
    required this.userFuture,
    required this.gameProfileFuture,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GameProfile?>(
      future: gameProfileFuture,
      builder: (context, gameSnap) {
        final gp = gameSnap.data;
        return FutureBuilder<User?>(
          future: userFuture,
          builder: (context, userSnap) {
            final user = userSnap.data;

            // Calculate money saved
            final dailyCost = user?.dailyCostAmount ?? 0;
            final quitDate = user?.quitDate;
            int daysQuit = 0;
            if (quitDate != null) {
              daysQuit = DateTime.now().difference(quitDate).inDays;
            }
            final totalSaved = dailyCost * daysQuit;

            return Column(
              children: [
                VirtualPlantCard(
                  streakDays: gp?.streakDays ?? 0,
                  level: gp?.level ?? 1,
                  levelProgress: gp?.levelProgress ?? 0,
                  isWithering: false,
                  onWater: () {
                    // Water action triggers check-in flow
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('浇水成功！记得完成今日打卡哦'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                if (daysQuit > 0)
                  MoneySavingsAnimator(
                    totalSavedYuan: totalSaved,
                    dailySavedYuan: dailyCost,
                    daysQuit: daysQuit,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
