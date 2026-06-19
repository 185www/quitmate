import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../domain/entity/game_profile.dart';

class GameProfileScreen extends ConsumerStatefulWidget {
  const GameProfileScreen({super.key});

  @override
  ConsumerState<GameProfileScreen> createState() => _GameProfileScreenState();
}

class _GameProfileScreenState extends ConsumerState<GameProfileScreen> {
  Future<GameProfile?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await ref.read(userUseCaseProvider).getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _profileFuture =
            ref.read(gameUseCaseProvider).getOrCreateProfile(user.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的等级')),
      body: FutureBuilder<GameProfile?>(
        future: _profileFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final gp = snap.data;
          if (gp == null) {
            return const Center(child: Text('暂无游戏数据'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(gp),
                const SizedBox(height: 24),
                _buildXpProgressSection(gp),
                const SizedBox(height: 24),
                _buildStatsGrid(gp),
                const SizedBox(height: 24),
                _buildXpBreakdownSection(),
                const SizedBox(height: 24),
                _buildMilestonesSection(gp),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(GameProfile gp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Large level emoji and number
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(gp.levelEmoji, style: const TextStyle(fontSize: 32)),
                    Text(
                      '${gp.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              gp.levelTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '累计 ${gp.totalXp} 经验值',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXpProgressSection(GameProfile gp) {
    final progress = gp.levelProgress.clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '距离 Lv.${gp.level + 1}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${gp.xp} XP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  '${gp.xpToNextLevel} XP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '还需 ${gp.xpToNextLevel - gp.xp} XP 升级',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(GameProfile gp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '战斗数据',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              icon: Icons.local_fire_department,
              iconColor: Colors.orange,
              label: '当前连续',
              value: '${gp.streakDays} 天',
              bgColor: Colors.orange.shade50,
            ),
            _StatCard(
              icon: Icons.emoji_events,
              iconColor: Colors.amber,
              label: '最长连续',
              value: '${gp.longestStreak} 天',
              bgColor: Colors.amber.shade50,
            ),
            _StatCard(
              icon: Icons.calendar_today,
              iconColor: Colors.teal,
              label: '总签到',
              value: '${gp.checkinTotal} 次',
              bgColor: Colors.teal.shade50,
            ),
            _StatCard(
              icon: Icons.shield,
              iconColor: Colors.green,
              label: '抵抗渴望',
              value: '${gp.cravingsResisted} 次',
              bgColor: Colors.green.shade50,
            ),
            _StatCard(
              icon: Icons.school,
              iconColor: Colors.deepPurple,
              label: '完成练习',
              value: '${gp.exercisesCompleted} 个',
              bgColor: Colors.deepPurple.shade50,
            ),
            _StatCard(
              icon: Icons.emergency,
              iconColor: Colors.red,
              label: 'SOS求助',
              value: '${gp.sosUsedCount} 次',
              bgColor: Colors.red.shade50,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildXpBreakdownSection() {
    final breakdowns = [
      {
        'action': '每日签到',
        'xp': XpRewards.dailyCheckin,
        'icon': Icons.check_circle,
        'color': Colors.green,
        'desc': '每天签到获得基础经验'
      },
      {
        'action': '连续签到奖励',
        'xp': XpRewards.streakBonus,
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
        'desc': '每连续一天额外获得'
      },
      {
        'action': '抵抗一次渴望',
        'xp': XpRewards.cravingResisted,
        'icon': Icons.shield,
        'color': Colors.teal,
        'desc': '成功抵抗一次渴求'
      },
      {
        'action': '完成CBT练习',
        'xp': XpRewards.exerciseCompleted,
        'icon': Icons.school,
        'color': Colors.deepPurple,
        'desc': '完成一次技能训练'
      },
      {
        'action': '使用SOS',
        'xp': XpRewards.sosUsed,
        'icon': Icons.emergency,
        'color': Colors.red,
        'desc': '使用紧急求助功能'
      },
      {
        'action': '达成里程碑',
        'xp': XpRewards.milestoneReached,
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'desc': '达成重要健康里程碑'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '经验值获取',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: List.generate(breakdowns.length, (i) {
              final b = breakdowns[i];
              return Column(
                children: [
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (b['color'] as Color).withOpacity(0.1),
                      child: Icon(b['icon'] as IconData,
                          color: b['color'] as Color, size: 20),
                    ),
                    title: Text(b['action'] as String),
                    subtitle: Text(
                      b['desc'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${b['xp']} XP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesSection(GameProfile gp) {
    const milestones = LevelMilestone.milestones;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '等级里程碑',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: List.generate(milestones.length, (i) {
              final m = milestones[i];
              final achieved = gp.level >= m.level;
              final isNext =
                  !achieved && (i == 0 || gp.level >= milestones[i - 1].level);
              return Column(
                children: [
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: achieved
                            ? Theme.of(context).colorScheme.primaryContainer
                            : isNext
                                ? Colors.orange.shade50
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                      ),
                      child: Center(
                        child: achieved
                            ? const Icon(Icons.check,
                                color: Colors.green, size: 20)
                            : isNext
                                ? const Icon(Icons.arrow_upward,
                                    color: Colors.orange, size: 18)
                                : Text(
                                    '${m.level}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          'Lv.${m.level} ${m.title}',
                          style: TextStyle(
                            fontWeight:
                                achieved ? FontWeight.bold : FontWeight.normal,
                            color: achieved
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                        if (isNext) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '下一目标',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(m.description),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: achieved
                            ? Colors.green.shade50
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        achieved ? '已达成' : m.reward,
                        style: TextStyle(
                          fontSize: 11,
                          color: achieved
                              ? Colors.green
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight:
                              achieved ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
