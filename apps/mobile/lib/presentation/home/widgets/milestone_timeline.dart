import 'package:flutter/material.dart';
import '../../domain/entity/user.dart';

/// Horizontal milestone timeline showing the next 3 health milestones
/// the user is working towards.
///
/// Uses [HealthMilestone.milestones] from the domain layer to find the
/// current position and render up to three upcoming dots connected by
/// lines.
class MilestoneTimeline extends StatelessWidget {
  const MilestoneTimeline({super.key, required this.userFuture});

  /// A future that resolves to the current [User] (may be `null`).
  final Future<User?> userFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: userFuture,
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
