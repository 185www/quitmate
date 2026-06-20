import 'package:flutter/material.dart';
import '../data/exercise_library.dart';

/// Horizontal scrollable filter chips for skill categories.
class CategoryFilterBar extends StatelessWidget {
  final String selectedCategory;
  final List<SkillCategory> categories;
  final List<ExerciseData> allExercises;
  final ValueChanged<String> onCategoryToggle;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.allExercises,
    required this.onCategoryToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            id: 'all',
            label: '全部',
            icon: Icons.apps,
            count: allExercises.length,
            selected: selectedCategory == 'all',
            onTap: onCategoryToggle,
          ),
          ...categories.map((c) {
            final count =
                allExercises.where((e) => e.category == c.id).length;
            return _FilterChip(
              id: c.id,
              label: '${c.emoji} ${c.name}',
              icon: c.icon,
              count: count,
              selected: selectedCategory == c.id,
              onTap: onCategoryToggle,
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final ValueChanged<String> onTap;

  const _FilterChip({
    required this.id,
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.3)
                      : colorScheme.onSurfaceVariant.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
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
