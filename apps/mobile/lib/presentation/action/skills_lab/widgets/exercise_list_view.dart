import 'package:flutter/material.dart';
import '../data/exercise_library.dart';

/// Scrollable exercise card list with expand/collapse details.
class ExerciseListView extends StatelessWidget {
  /// The (already filtered) exercise list to display.
  final List<ExerciseData> exercises;

  /// The full exercise library, used to compute global indices.
  final List<ExerciseData> allExercises;

  /// Currently expanded exercise global index, or null.
  final int? expandedIndex;

  /// Set of global indices that have been completed.
  final Set<int> completedExercises;

  /// Called with the global index when the user taps a card header.
  final ValueChanged<int> onToggleExpand;

  /// Called with the global index when the user presses "开始练习".
  final ValueChanged<int> onCompleteExercise;

  const ExerciseListView({
    super.key,
    required this.exercises,
    required this.allExercises,
    required this.expandedIndex,
    required this.completedExercises,
    required this.onToggleExpand,
    required this.onCompleteExercise,
  });

  /// Map a local (filtered) index to the corresponding global index.
  int _globalIndex(int localIndex) {
    if (localIndex >= exercises.length) return -1;
    return allExercises.indexOf(exercises[localIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final ex = exercises[index];
        final gi = _globalIndex(index);
        final isExpanded = expandedIndex == gi;
        final isCompleted = gi >= 0 && completedExercises.contains(gi);

        return _ExerciseCard(
          exercise: ex,
          isExpanded: isExpanded,
          isCompleted: isCompleted,
          onTap: () => onToggleExpand(gi),
          onComplete: () => onCompleteExercise(gi),
        );
      },
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseData exercise;
  final bool isExpanded;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const _ExerciseCard({
    required this.exercise,
    required this.isExpanded,
    required this.isCompleted,
    required this.onTap,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                exercise.icon,
                size: 20,
                color: isCompleted ? Colors.green : colorScheme.primary,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.title,
                    style: isCompleted
                        ? TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
                if (exercise.duration.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise.duration,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (isCompleted) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle,
                      size: 16, color: Colors.green),
                ],
              ],
            ),
            subtitle: Text(
              exercise.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: onTap,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '步骤：',
                    style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(exercise.steps.length, (si) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${si + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exercise.steps[si],
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_stories,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exercise.reference,
                            style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: Icon(
                        isCompleted ? Icons.check_circle : Icons.play_arrow,
                      ),
                      label: Text(
                        isCompleted ? '已完成' : '开始练习',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted ? Colors.green : null,
                        foregroundColor: isCompleted ? Colors.white : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
