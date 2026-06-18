import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';

class SkillsLabScreen extends ConsumerStatefulWidget {
  const SkillsLabScreen({super.key});

  @override
  ConsumerState<SkillsLabScreen> createState() => _SkillsLabScreenState();
}

class _SkillsLabScreenState extends ConsumerState<SkillsLabScreen> {
  int? _expandedIndex;
  final Set<int> _completedExercises = {};
  bool _loadingPreferences = true;

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
    } catch (_) {
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
      if (_completedExercises.length >= 5) {
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
              content: Text('✅ 已完成 ${_completedExercises.length}/7 个练习'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final exercises = [
      _ExerciseData(
        icon: Icons.edit_note,
        title: '思维记录',
        subtitle: '捕捉自动思维，用理性回应挑战',
        description:
            '自动思维是我们在面对情境时瞬间产生的想法，通常带有偏差。通过记录和挑战这些想法，你可以打破消极思维模式。',
        steps: [
          '描述触发情境：发生了什么？',
          '记录自动思维：脑海中闪过了什么想法？',
          '寻找支持证据：有什么事实支持这个想法？',
          '寻找反驳证据：有什么事实不支持这个想法？',
          '写下理性回应：更平衡、更现实的想法是什么？',
        ],
        reference:
            '认知行为疗法通过识别和重构自动思维，可显著降低物质渴求 (Beck et al., 1993)',
      ),
      _ExerciseData(
        icon: Icons.waves,
        title: '渴望冲浪',
        subtitle: '观察渴望如海浪般自然起伏消退',
        description:
            '渴望就像海浪，有起有落。与其对抗，不如观察它、接纳它，让它自然消退。研究表明渴望通常在5-20分钟内达到峰值后消退。',
        steps: [
          '找个舒适的位置坐下，闭上眼睛',
          '注意身体哪里感受到渴望（胸口、喉咙、腹部等）',
          '像冲浪者观察海浪一样观察这种感觉',
          '不要评判或抗拒，只是看着它变化',
          '注意渴望的强度如何自然变化直到消退',
        ],
        reference:
            '渴望冲浪技术基于正念认知疗法，效果显著 (Bowen et al., 2009)',
      ),
      _ExerciseData(
        icon: Icons.visibility,
        title: '5-4-3-2-1接地练习',
        subtitle: '用感官将注意力带回当下',
        description:
            '当渴望或焦虑来袭时，接地练习可以帮助你快速回到当下，打断自动化的渴求反应。通过调动五种感官，将注意力从内在冲动转移到现在。',
        steps: [
          '看：环顾四周，说出你看到的5样东西',
          '摸：注意身体触感，说出你摸到的4样东西',
          '听：仔细倾听，说出你听到的3种声音',
          '闻：深呼吸，说出你闻到的2种气味',
          '尝：注意口腔中的味道，说出你尝到的1种味道',
        ],
        reference:
            '接地技术是CBT和DBT的核心技能，对情绪调节有立竿见影的效果 (Linehan, 2014)',
      ),
      _ExerciseData(
        icon: Icons.balance,
        title: '成本效益分析',
        subtitle: '理性权衡使用与戒断的利弊',
        description:
            '写下使用和戒断的短期与长期利弊，可以帮助你在渴望时看清真正的选择。大脑在渴望时会高估短期满足、低估长期代价。',
        steps: [
          '写下继续使用的好处（短期快感、缓解压力等）',
          '写下继续使用的代价（健康、金钱、关系等）',
          '写下戒断的好处（健康恢复、省钱、自尊等）',
          '写下戒断的代价（不适感、社交压力等）',
          '比较两栏，思考什么对你真正重要',
        ],
        reference:
            '决策平衡技术是动机性访谈的核心，能有效增强戒断动机 (Miller & Rollnick, 2012)',
      ),
      _ExerciseData(
        icon: Icons.credit_card,
        title: '应对卡',
        subtitle: '创建个人化紧急应对方案',
        description:
            '应对卡是你在渴望来临时可以立刻使用的"急救工具"。提前准备好，当渴望出现时不用思考就能执行。',
        steps: [
          '列出你最可能使用的情境（如压力、社交、无聊）',
          '针对每种情境写下3个可以做的替代行为',
          '写下当你渴望时提醒自己的话（如"渴望会在20分钟内消退"）',
          '把应对卡保存在手机或钱包里随时查看',
          '定期更新和复习你的应对卡',
        ],
        reference:
            '应对卡是CBT复发预防的关键工具，能显著降低复发率 (Marlatt & Donovan, 2005)',
      ),
      _ExerciseData(
        icon: Icons.self_improvement,
        title: '渐进式放松',
        subtitle: '逐组紧张和放松肌肉来缓解压力',
        description:
            '渐进式肌肉放松（PMR）通过交替紧张和放松不同肌群，帮助身体深度放松。这可以缓解压力诱发的渴望，改善睡眠质量。',
        steps: [
          '找个安静的地方坐下或躺下，深呼吸3次',
          '紧张双脚和脚踝5秒，然后突然放松，感受松弛感',
          '依次紧张并放松：小腿→大腿→腹部→双手→手臂',
          '继续：肩膀→颈部→面部（皱眉、张嘴）',
          '全身扫描：检查是否还有紧张的部位，再做一次放松',
        ],
        reference:
            '渐进式放松法由Jacobson(1938)创立，对焦虑和物质渴求有显著缓解效果',
      ),
      _ExerciseData(
        icon: Icons.map,
        title: '诱因地图',
        subtitle: '识别高危情境并提前规划',
        description:
            '了解你的个人诱因是预防复发的第一步。通过绘制诱因地图，你可以提前识别高危情境并制定应对策略。',
        steps: [
          '回顾过去的使用模式：何时何地最想使用？',
          '分类列出诱因：情绪诱因、社交诱因、环境诱因',
          '评估风险等级：对每个诱因打分1-10',
          '针对高风险诱因制定具体应对方案',
          '建立支持系统：谁可以在关键时刻帮助你？',
        ],
        reference:
            '诱因识别与应对规划是CBT复发预防模型的核心 (Witkiewitz & Marlatt, 2004)',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CBT技能训练'),
        actions: [
          if (!_loadingPreferences)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(
                  '${_completedExercises.length}/7',
                  style: const TextStyle(fontSize: 12),
                ),
                avatar: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: _completedExercises.length >= 5
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: _loadingPreferences
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '认知行为疗法技能训练',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CBT是国际公认最有效的成瘾行为干预方法之一',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (_completedExercises.length >= 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.emoji_events,
                                      size: 16, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    '已完成5个练习，获得 CBT学徒 徽章！',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                final i = index - 1;
                final ex = exercises[i];
                final isExpanded = _expandedIndex == i;
                final isCompleted = _completedExercises.contains(i);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            ex.icon,
                            color: isCompleted
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(ex.title),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle,
                                  size: 16, color: Colors.green),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          ex.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : i;
                          });
                        },
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '步骤：',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(ex.steps.length, (si) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${si + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          ex.steps[si],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
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
                                        ex.reference,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
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
                                  onPressed: () => _completeExercise(i),
                                  icon: Icon(
                                    isCompleted
                                        ? Icons.check_circle
                                        : Icons.play_arrow,
                                  ),
                                  label: Text(
                                    isCompleted ? '已完成' : '开始练习',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isCompleted
                                        ? Colors.green
                                        : null,
                                    foregroundColor:
                                        isCompleted ? Colors.white : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ExerciseData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> steps;
  final String reference;

  const _ExerciseData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.steps,
    required this.reference,
  });
}
