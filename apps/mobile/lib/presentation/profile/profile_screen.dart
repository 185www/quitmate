import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../domain/entity/game_profile.dart';

/// Profile tab — user summary card at top with streak/level,
/// then clean sectioned list of options.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<GameProfile?> _loadProfile() async {
    final uc = ref.read(userUseCaseProvider);
    final gc = ref.read(gameUseCaseProvider);
    final user = await uc.getCurrentUser();
    if (user != null) return gc.getGameProfile(user.id);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<GameProfile?>(
        future: _loadProfile(),
        builder: (context, snap) {
          final gp = snap.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              // ── User summary card ──
              _UserSummaryCard(gameProfile: gp),

              const SizedBox(height: 28),

              // ── Section: 我的数据 ──
              Text(
                '我的数据',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _ProfileMenuItem(
                icon: Icons.stars_rounded,
                title: '我的等级',
                subtitle: '查看等级、经验和战斗数据',
                color: colorScheme.primary,
                onTap: () => context.push('/profile/game-profile'),
              ),
              _ProfileMenuItem(
                icon: Icons.analytics_rounded,
                title: '高危场景分析',
                subtitle: '查看你的渴望触发场景报告',
                color: colorScheme.tertiary,
                onTap: () => context.push('/profile/analysis'),
              ),
              _ProfileMenuItem(
                icon: Icons.assessment_rounded,
                title: '评估报告',
                subtitle: '查看你的依赖性评估结果',
                color: colorScheme.secondary,
                onTap: () => context.push('/onboarding/assessment'),
              ),
              _ProfileMenuItem(
                icon: Icons.emoji_events_rounded,
                title: '我的成就',
                subtitle: '查看已获得的徽章',
                color: colorScheme.tertiary,
                onTap: () => context.push('/profile/badges'),
              ),

              const SizedBox(height: 24),

              // ── Section: 设置 ──
              Text(
                '设置',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _ProfileMenuItem(
                icon: Icons.settings_rounded,
                title: '设置',
                subtitle: '通知、提醒、偏好设置',
                color: colorScheme.onSurfaceVariant,
                onTap: () => context.push('/profile/settings'),
              ),
              _ProfileMenuItem(
                icon: Icons.download_rounded,
                title: '导出数据',
                subtitle: '导出你的记录和报告',
                color: colorScheme.onSurfaceVariant,
                onTap: () => context.push('/profile/export'),
              ),
              _ProfileMenuItem(
                icon: Icons.info_outline_rounded,
                title: '关于',
                subtitle: '版本信息、隐私政策、免责声明',
                color: colorScheme.onSurfaceVariant,
                onTap: () => context.push('/profile/about'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Top summary card showing user level, title, streak, and XP progress.
class _UserSummaryCard extends StatelessWidget {
  final GameProfile? gameProfile;

  const _UserSummaryCard({this.gameProfile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gp = gameProfile;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.5),
            colorScheme.tertiaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Avatar + level
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    gp != null ? gp.levelEmoji : '🌱',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gp != null ? gp.levelTitle : '初学者',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Lv.${gp?.level ?? 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        if (gp != null && gp.streakDays > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer
                                  .withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 2),
                                Text(
                                  '${gp.streakDays}天',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),

          // XP progress bar
          if (gp != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: gp.levelProgress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor:
                          colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  gp.xpDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A single menu item row for the profile settings list.
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
