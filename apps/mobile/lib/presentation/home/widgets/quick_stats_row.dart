import 'package:flutter/material.dart';
import '../../../domain/entity/user.dart';
import '../../../domain/entity/game_profile.dart';

/// Three compact stat cards showing savings, life regained, and streak.
///
/// Each card uses a subtle coloured background that matches the theme.
/// The widget hides itself when the user has no quit date.
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({
    super.key,
    required this.userFuture,
    required this.gameProfileFuture,
  });

  /// A future that resolves to the current [User] (may be `null`).
  final Future<User?> userFuture;

  /// A future that resolves to the current [GameProfile] (may be `null`).
  final Future<GameProfile?> gameProfileFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: userFuture,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null || !user.hasQuitDate) return const SizedBox.shrink();
        final colorScheme = Theme.of(context).colorScheme;
        final days = user.daysSinceQuit;
        final saved = user.dailyCost * days;
        final lifeMinutes = user.dailyLifeRegainedMinutes * days;
        final lifeDays = (lifeMinutes / 1440).toStringAsFixed(0);

        return FutureBuilder<GameProfile?>(
          future: gameProfileFuture,
          builder: (context, gpSnap) {
            final streak = gpSnap.data?.streakDays ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _statCard(
                    context,
                    Icons.savings_outlined,
                    '已节省',
                    '¥${saved.toStringAsFixed(0)}',
                    colorScheme.primaryContainer.withOpacity(0.5),
                    colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    context,
                    Icons.favorite_rounded,
                    '生命延长',
                    '+$lifeDays 天',
                    colorScheme.errorContainer.withOpacity(0.5),
                    colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    context,
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
      BuildContext context, IconData icon, String label, String value, Color bg, Color fg) {
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
}
