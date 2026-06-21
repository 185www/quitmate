import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../domain/entity/badge.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeUseCase = ref.read(badgeUseCaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的成就')),
      body: FutureBuilder<List<AppBadge>>(
        future: badgeUseCase.getAllBadges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(child: Text('暂无徽章'));
          }
          final badges = snap.data!;
          final earned = badges.where((b) => b.earnedAt != null).length;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('已获得 $earned / ${badges.length}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: badges.length,
                  itemBuilder: (context, index) {
                    final badge = badges[index];
                    final isEarned = badge.earnedAt != null;
                    return _BadgeCard(badge: badge, isEarned: isEarned);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final AppBadge badge;
  final bool isEarned;
  const _BadgeCard({required this.badge, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: isEarned
          ? theme.colorScheme.primaryContainer.withOpacity(0.5)
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _badgeIcon(badge.code),
              size: 36,
              color: isEarned
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isEarned
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isEarned) ...[
              const SizedBox(height: 2),
              Text(
                _formatDate(badge.earnedAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _badgeIcon(String code) {
    switch (code) {
      case 'day_1':
        return Icons.flag;
      case 'day_7':
        return Icons.calendar_today;
      case 'day_30':
        return Icons.emoji_events;
      case 'day_90':
        return Icons.military_tech;
      case 'day_365':
        return Icons.stars;
      case 'assessment_done':
        return Icons.assignment_turned_in;
      case 'first_log':
        return Icons.edit_note;
      case 'streak_7':
        return Icons.local_fire_department;
      case 'streak_30':
        return Icons.whatshot;
      case 'sos_used':
        return Icons.emergency;
      case 'urge_surfed':
        return Icons.waves;
      default:
        return Icons.workspace_premium;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.month}/${d.day}';
  }
}
