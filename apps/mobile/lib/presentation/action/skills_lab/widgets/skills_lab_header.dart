import 'package:flutter/material.dart';
import '../data/exercise_library.dart';

/// Header section showing the current category title, badge status, and
/// completion stats.
class SkillsLabHeader extends StatelessWidget {
  final String selectedCategory;
  final Set<int> completedExercises;
  final List<ExerciseData> allExercises;
  final List<SkillCategory> categories;

  const SkillsLabHeader({
    super.key,
    required this.selectedCategory,
    required this.completedExercises,
    required this.allExercises,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalCompleted = completedExercises.length;

    final cat =
        categories.where((c) => c.id == selectedCategory).firstOrNull;
    final title =
        cat != null ? '${cat.emoji} ${cat.name}' : '多类别循证干预技能';

    final categoryTotal = selectedCategory == 'all'
        ? allExercises.length
        : allExercises.where((e) => e.category == selectedCategory).length;
    final categoryCompleted = selectedCategory == 'all'
        ? totalCompleted
        : completedExercises.where((i) =>
                i < allExercises.length &&
                allExercises[i].category == selectedCategory)
            .length;

    final desc = selectedCategory == 'all'
        ? '基于CBT、ACT、正念等循证方法的30个干预技能'
        : '已完成 $categoryCompleted / $categoryTotal 个练习';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (totalCompleted >= 20)
                _BadgeChip(
                  icon: Icons.emoji_events,
                  label: '技能大师',
                  bgColor: Colors.amber.withOpacity(0.1),
                  iconColor: Colors.amber,
                  textColor: Colors.amber,
                )
              else if (totalCompleted >= 10)
                _BadgeChip(
                  icon: Icons.military_tech,
                  label: '技能探索者',
                  bgColor: Colors.blue.withOpacity(0.1),
                  iconColor: Colors.blue,
                  textColor: Colors.blue,
                )
              else if (totalCompleted >= 5)
                _BadgeChip(
                  icon: Icons.emoji_events,
                  label: 'CBT学徒',
                  bgColor: Colors.green.withOpacity(0.1),
                  iconColor: Colors.green,
                  textColor: Colors.green,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final Color textColor;

  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
