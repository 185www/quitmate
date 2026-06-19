import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import 'data/exercise_library.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/exercise_list_view.dart';
import 'widgets/skills_lab_header.dart';

class SkillsLabScreen extends ConsumerStatefulWidget {
  const SkillsLabScreen({super.key});

  @override
  ConsumerState<SkillsLabScreen> createState() => _SkillsLabScreenState();
}

class _SkillsLabScreenState extends ConsumerState<SkillsLabScreen> {
  int? _expandedIndex;
  final Set<int> _completedExercises = {};
  bool _loadingPreferences = true;
  String _selectedCategory = 'all'; // 'all' or category id

  @override
  void initState() {
    super.initState();
    _loadCompletedExercises();
  }

  Future<void> _loadCompletedExercises() async {
    try {
      final prefs = await ref.read(userUseCaseProvider).getPreferences();
      final completed = prefs['completed_skills'] as List<dynamic>?;
      if (completed != null) {
        setState(() {
          _completedExercises.addAll(completed.cast<int>());
          _loadingPreferences = false;
        });
      } else {
        setState(() => _loadingPreferences = false);
      }
    } catch (e) {
      debugPrint('SkillsLab: 加载完成状态失败: $e');
      setState(() => _loadingPreferences = false);
    }
  }

  Future<void> _completeExercise(int index) async {
    if (_completedExercises.contains(index)) return;
    setState(() {
      _completedExercises.add(index);
    });
    try {
      final userUseCase = ref.read(userUseCaseProvider);
      final prefs = await userUseCase.getPreferences();
      final completed =
          List<int>.from(prefs['completed_skills'] as List<dynamic>? ?? []);
      if (!completed.contains(index)) {
        completed.add(index);
      }
      await userUseCase.savePreferences({
        ...prefs,
        'completed_skills': completed,
      });
      // Award exercise XP
      final user = await ref.read(userUseCaseProvider).getCurrentUser();
      if (user != null) {
        await ref.read(gameUseCaseProvider).awardExerciseCompleted(user.id);
      }
      final total = _completedExercises.length;
      if (total >= 20) {
        await ref.read(badgeRepositoryProvider).earnBadge('skills_master');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🏆 恭喜你获得 技能大师 徽章！'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (total >= 10) {
        await ref.read(badgeRepositoryProvider).earnBadge('skills_explorer');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎖️ 恭喜你获得 技能探索者 徽章！'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (total >= 5) {
        await ref.read(badgeRepositoryProvider).earnBadge('cbt_master');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 恭喜你获得 CBT学徒 徽章！'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 已完成 $total/${exerciseLibrary.length} 个练习'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('SkillsLab: 保存完成状态失败: $e');
    }
  }

  // ── Helpers ──
  List<ExerciseData> get _filteredExercises {
    if (_selectedCategory == 'all') return exerciseLibrary;
    return exerciseLibrary
        .where((e) => e.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPreferences) {
      return const Scaffold(
        appBar: AppBar(title: Text('干预技能库')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalCompleted = _completedExercises.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('干预技能库'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(
                '$totalCompleted/${exerciseLibrary.length}',
                style: const TextStyle(fontSize: 12),
              ),
              avatar: Icon(
                Icons.check_circle,
                size: 16,
                color: totalCompleted >= 20
                    ? Colors.amber
                    : totalCompleted >= 10
                        ? Colors.blue
                        : totalCompleted >= 5
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          CategoryFilterBar(
            selectedCategory: _selectedCategory,
            categories: skillCategories,
            allExercises: exerciseLibrary,
            onCategoryToggle: (id) {
              setState(() {
                _selectedCategory = id;
                _expandedIndex = null;
              });
            },
          ),
          SkillsLabHeader(
            selectedCategory: _selectedCategory,
            completedExercises: _completedExercises,
            allExercises: exerciseLibrary,
            categories: skillCategories,
          ),
          Expanded(
            child: ExerciseListView(
              exercises: _filteredExercises,
              allExercises: exerciseLibrary,
              expandedIndex: _expandedIndex,
              completedExercises: _completedExercises,
              onToggleExpand: (gi) {
                setState(() {
                  _expandedIndex = _expandedIndex == gi ? null : gi;
                });
              },
              onCompleteExercise: _completeExercise,
            ),
          ),
        ],
      ),
    );
  }
}
