import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entity/user.dart';
import '../../domain/entity/companion.dart';

/// Companion preview card showing a daily challenge message from
/// [QuitCompanion].
///
/// Tapping navigates to `/action/companion`.  Hides itself when the
/// user has no quit date.
class CompanionPreviewCard extends StatelessWidget {
  const CompanionPreviewCard({super.key, required this.userFuture});

  /// A future that resolves to the current [User] (may be `null`).
  final Future<User?> userFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: userFuture,
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
}
