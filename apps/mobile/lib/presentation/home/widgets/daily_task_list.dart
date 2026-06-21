import 'package:flutter/material.dart';
import '../../../domain/entity/daily_task.dart';

/// Daily task checklist with completion counter and XP summary.
///
/// Displays a header row with a completed-count badge, a list of
/// tappable task items (each showing type icon, title, description
/// and XP reward), and a footer with total / earned XP.
class DailyTaskList extends StatelessWidget {
  const DailyTaskList({
    super.key,
    required this.tasks,
    required this.completedTaskIds,
    required this.onComplete,
  });

  /// All tasks for today.
  final List<DailyTask> tasks;

  /// IDs of tasks the user has already completed.
  final Set<String> completedTaskIds;

  /// Fired when the user taps a task item to mark it complete.
  final ValueChanged<DailyTask> onComplete;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final completedCount =
        tasks.where((t) => completedTaskIds.contains(t.id)).length;
    final totalXp = tasks.fold<int>(0, (sum, t) => sum + t.xpReward);
    final earnedXp = tasks
        .where((t) => completedTaskIds.contains(t.id))
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedCount/${tasks.length}',
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
            ...List.generate(tasks.length, (i) {
              final task = tasks[i];
              final isCompleted = completedTaskIds.contains(task.id);
              return _buildTaskItem(context, task, isCompleted, i);
            }),
            const SizedBox(height: 10),
            Divider(color: colorScheme.surfaceContainerHighest, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 14, color: colorScheme.tertiary),
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

  Widget _buildTaskItem(
      BuildContext context, DailyTask task, bool isCompleted, int index) {
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
        onTap: isCompleted ? null : () => onComplete(task),
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
                  onChanged:
                      isCompleted ? null : (_) => onComplete(task),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
}
