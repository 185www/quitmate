import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../domain/entity/user.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  final List<int?> _ftndAnswers = List.filled(6, null);
  final List<int?> _auditAnswers = List.filled(3, null);
  TargetType _targetType = TargetType.smoking;
  bool _saving = false;
  bool _loading = true;

  List<Map<String, dynamic>> _ftndQuestions = [];
  List<Map<String, dynamic>> _auditQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestionsFromAssets();
  }

  Future<void> _loadQuestionsFromAssets() async {
    try {
      final contentLoader = ref.read(contentLoaderProvider);
      _ftndQuestions = await contentLoader.loadAssessmentQuestions('ftnd');
      _auditQuestions = await contentLoader.loadAssessmentQuestions('audit_c');
    } catch (e) {
      // Fallback: if JSON loading fails, use hardcoded questions
      _ftndQuestions = _fallbackFtndQuestions();
      _auditQuestions = _fallbackAuditQuestions();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _fallbackFtndQuestions() => [
    {
      'text': '醒后多久吸第一支烟？',
      'options': [
        {'text': '≤5分钟', 'score': 3},
        {'text': '6-30分钟', 'score': 2},
        {'text': '31-60分钟', 'score': 1},
        {'text': '>60分钟', 'score': 0},
      ],
    },
    {
      'text': '在禁烟场所是否难以控制不吸烟？',
      'options': [
        {'text': '是', 'score': 1},
        {'text': '否', 'score': 0},
      ],
    },
    {
      'text': '哪一支烟最难以放弃？',
      'options': [
        {'text': '早晨第一支', 'score': 1},
        {'text': '其他时间', 'score': 0},
      ],
    },
    {
      'text': '每天吸多少支烟？',
      'options': [
        {'text': '≤10支', 'score': 0},
        {'text': '11-20支', 'score': 1},
        {'text': '21-30支', 'score': 2},
        {'text': '≥31支', 'score': 3},
      ],
    },
    {
      'text': '早晨醒来后的第一个小时是否比其他时间吸烟更多？',
      'options': [
        {'text': '是', 'score': 1},
        {'text': '否', 'score': 0},
      ],
    },
    {
      'text': '生病卧床时是否仍然吸烟？',
      'options': [
        {'text': '是', 'score': 1},
        {'text': '否', 'score': 0},
      ],
    },
  ];

  List<Map<String, dynamic>> _fallbackAuditQuestions() => [
    {
      'text': '您喝酒的频率是？',
      'options': [
        {'text': '从不', 'score': 0},
        {'text': '每月1次或以下', 'score': 1},
        {'text': '每月2-4次', 'score': 2},
        {'text': '每周2-3次', 'score': 3},
        {'text': '每周4次以上', 'score': 4},
      ],
    },
    {
      'text': '在喝酒的一天中，您通常喝多少标准杯？',
      'options': [
        {'text': '1-2杯', 'score': 0},
        {'text': '3-4杯', 'score': 1},
        {'text': '5-6杯', 'score': 2},
        {'text': '7-9杯', 'score': 3},
        {'text': '10杯以上', 'score': 4},
      ],
    },
    {
      'text': '一次性喝酒超过6杯（标准杯）的频率是？',
      'options': [
        {'text': '从不', 'score': 0},
        {'text': '少于每月1次', 'score': 1},
        {'text': '每月1次', 'score': 2},
        {'text': '每周1次', 'score': 3},
        {'text': '每天或几乎每天', 'score': 4},
      ],
    },
  ];

  int get _ftndScore {
    int score = 0;
    for (final a in _ftndAnswers) {
      if (a != null) score += a;
    }
    return score;
  }

  int get _auditScore {
    int score = 0;
    for (final a in _auditAnswers) {
      if (a != null) score += a;
    }
    return score;
  }

  bool get _ftndComplete => _ftndAnswers.every((a) => a != null);

  bool get _auditComplete => _auditAnswers.every((a) => a != null);

  bool get _canSave {
    switch (_targetType) {
      case TargetType.smoking:
        return _ftndComplete;
      case TargetType.alcohol:
        return _auditComplete;
      case TargetType.both:
        return _ftndComplete && _auditComplete;
    }
  }

  String _ftndInterpretation(int score) {
    if (score <= 3) return '轻度依赖';
    if (score <= 6) return '中度依赖';
    return '重度依赖';
  }

  Color _ftndColor(int score) {
    if (score <= 3) return Colors.green;
    if (score <= 6) return Colors.orange;
    return Colors.red;
  }

  String _ftndDetail(int score) {
    if (score <= 3) return '你的尼古丁依赖程度较低，戒断相对容易。建议制定明确的戒断计划。';
    if (score <= 6) return '你有中等程度的尼古丁依赖，可能需要一些辅助手段（如尼古丁替代疗法）。';
    return '你有严重的尼古丁依赖，建议在医生指导下进行戒断，可能需要药物辅助。';
  }

  String _auditInterpretation(int score) {
    if (score == 0) return '无风险';
    if (score <= 3) return '低风险饮酒';
    if (score <= 7) return '中度风险';
    return '高风险/可能有酒精依赖';
  }

  Color _auditColor(int score) {
    if (score <= 3) return Colors.green;
    if (score <= 7) return Colors.orange;
    return Colors.red;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(userUseCaseProvider).updateAssessment(
            fagerstromScore: _targetType != TargetType.alcohol ? _ftndScore : null,
            auditScore: _targetType != TargetType.smoking ? _auditScore : null,
            targetType: _targetType,
          );
      // Award assessment badge
      await ref.read(badgeRepositoryProvider).earnBadge('assessment_done');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评估结果已保存')),
        );
        context.push('/onboarding/education');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('自我评估')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('了解一下自己')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                _StepDot(step: 1, label: '评估', active: true, done: false),
                _StepLineSeg(done: false),
                _StepDot(step: 2, label: '了解', active: false, done: false),
                _StepLineSeg(done: false),
                _StepDot(step: 3, label: '动机', active: false, done: false),
                _StepLineSeg(done: false),
                _StepDot(step: 4, label: '开始', active: false, done: false),
              ],
            ),
          ),
          // Friendly intro
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '先简单了解一下你的情况，这能帮我们为你提供更适合的建议',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('选择你的戒断目标', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SegmentedButton<TargetType>(
                    segments: const [
                      ButtonSegment(value: TargetType.smoking, label: Text('戒烟'), icon: Icon(Icons.smoking_rooms)),
                      ButtonSegment(value: TargetType.alcohol, label: Text('戒酒'), icon: Icon(Icons.local_bar)),
                      ButtonSegment(value: TargetType.both, label: Text('两者'), icon: Icon(Icons.sync_alt)),
                    ],
                    selected: {_targetType},
                    onSelectionChanged: (v) => setState(() => _targetType = v.first),
                  ),
                  if (_targetType == TargetType.both)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '同时戒烟戒酒需要完成两项评估',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_targetType != TargetType.alcohol) ..._buildFtndSection(context),
          if (_targetType == TargetType.both) const SizedBox(height: 24),
          if (_targetType != TargetType.smoking) ..._buildAuditSection(context),
          const SizedBox(height: 24),
          _buildResultsSection(context),
          const SizedBox(height: 24),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('保存并继续'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Quick start: skip assessment, go straight to education with defaults
                    ref.read(userUseCaseProvider).updateAssessment(
                      fagerstromScore: _targetType != TargetType.alcohol ? 3 : null,
                      auditScore: _targetType != TargetType.smoking ? 2 : null,
                      targetType: _targetType,
                    );
                    context.push('/onboarding/education');
                  },
                  child: Text(
                    '暂时跳过，稍后再填',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildFtndSection(BuildContext context) {
    final complete = _ftndComplete;
    final score = _ftndScore;
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.smoking_rooms, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('FTND 尼古丁依赖评估', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (complete)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _ftndColor(score).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '得分: $score/10',
                        style: TextStyle(color: _ftndColor(score), fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(_ftndQuestions.length, (i) {
                final q = _ftndQuestions[i];
                final options = (q['options'] as List).cast<Map<String, dynamic>>();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}. ${q['text']}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      ...options.map((opt) {
                        final optScore = opt['score'] as int;
                        return RadioListTile<int>(
                          title: Text(opt['text'] as String),
                          value: optScore,
                          groupValue: _ftndAnswers[i],
                          onChanged: (v) => setState(() => _ftndAnswers[i] = v),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildAuditSection(BuildContext context) {
    final complete = _auditComplete;
    final score = _auditScore;
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_bar, color: Colors.brown),
                  const SizedBox(width: 8),
                  Text('AUDIT-C 酒精使用评估', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (complete)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _auditColor(score).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '得分: $score/12',
                        style: TextStyle(color: _auditColor(score), fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(_auditQuestions.length, (i) {
                final q = _auditQuestions[i];
                final options = (q['options'] as List).cast<Map<String, dynamic>>();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}. ${q['text']}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      ...options.map((opt) {
                        final optScore = opt['score'] as int;
                        return RadioListTile<int>(
                          title: Text(opt['text'] as String),
                          value: optScore,
                          groupValue: _auditAnswers[i],
                          onChanged: (v) => setState(() => _auditAnswers[i] = v),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildResultsSection(BuildContext context) {
    final ftndComplete = _ftndComplete;
    final auditComplete = _auditComplete;
    final ftndScore = _ftndScore;
    final auditScore = _auditScore;

    if (!ftndComplete && !auditComplete) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('评估结果', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_targetType != TargetType.alcohol && ftndComplete) ...[
              Row(
                children: [
                  const Icon(Icons.smoking_rooms, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '尼古丁依赖: ${_ftndInterpretation(ftndScore)} ($ftndScore/10)',
                    style: TextStyle(color: _ftndColor(ftndScore), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Text(_ftndDetail(ftndScore), style: Theme.of(context).textTheme.bodySmall),
              ),
              if (_targetType == TargetType.both) const SizedBox(height: 12),
            ],
            if (_targetType != TargetType.smoking && auditComplete) ...[
              Row(
                children: [
                  const Icon(Icons.local_bar, size: 20, color: Colors.brown),
                  const SizedBox(width: 8),
                  Text(
                    '酒精使用: ${_auditInterpretation(auditScore)} ($auditScore/12)',
                    style: TextStyle(color: _auditColor(auditScore), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Text(
                  auditScore <= 3
                      ? '你的饮酒水平在安全范围内。'
                      : auditScore <= 7
                          ? '建议减少饮酒量，存在中等健康风险。'
                          : '你的饮酒水平偏高，建议寻求专业帮助。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Step dot for onboarding progress
class _StepDot extends StatelessWidget {
  final int step;
  final String label;
  final bool active;
  final bool done;

  const _StepDot({required this.step, required this.label, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final color = done
        ? Theme.of(context).colorScheme.primary
        : active
            ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? Theme.of(context).colorScheme.primary : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Center(
                  child: Text('$step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: color)),
      ],
    );
  }
}

class _StepLineSeg extends StatelessWidget {
  final bool done;
  const _StepLineSeg({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
      ),
    );
  }
}
