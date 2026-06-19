import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entity/user.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '身体恢复之旅',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _StepIndicator(step: 1, label: '评估', active: true, done: true),
                _StepLine(done: true),
                _StepIndicator(step: 2, label: '了解', active: true, done: false),
                _StepLine(done: false),
                _StepIndicator(step: 3, label: '动机', active: false, done: false),
                _StepLine(done: false),
                _StepIndicator(step: 4, label: '开始', active: false, done: false),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _BrainPage(),
                _BodyPage(),
                _LifePage(),
                _StatsPage(),
              ],
            ),
          ),
          _BottomBar(currentPage: _currentPage, controller: _controller),
        ],
      ),
    );
  }
}

/// Step indicator showing onboarding progress
class _StepIndicator extends StatelessWidget {
  final int step;
  final String label;
  final bool active;
  final bool done;

  const _StepIndicator({
    required this.step,
    required this.label,
    required this.active,
    required this.done,
  });

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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? Theme.of(context).colorScheme.primary : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Center(
                  child: Text(
                    '$step',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: active ? FontWeight.w600 : FontWeight.normal),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: done
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentPage;
  final PageController controller;

  const _BottomBar({required this.currentPage, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Row(
        children: [
          _Dots(count: 4, current: currentPage),
          const Spacer(),
          FilledButton(
            onPressed: () {
              if (isLast) {
                // Navigate forward to motivation screen instead of popping back
                context.go('/onboarding/motivation');
              } else {
                controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Text(isLast ? '完成' : '下一步'),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int current;
  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Page 1: 🧠 大脑 ─────────────────────────────────────────

const _brainCards = [
  _BrainCardData('🧪', '多巴胺下降', '渴求减少', '14天'),
  _BrainCardData('🧘', '前额叶恢复', '自控力提升', '30天'),
  _BrainCardData('😌', '杏仁核稳定', '焦虑减轻', '90天'),
];

class _BrainCardData {
  final String icon;
  final String title;
  final String subtitle;
  final String duration;
  const _BrainCardData(this.icon, this.title, this.subtitle, this.duration);
}

class _BrainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🧠', style: theme.textTheme.displaySmall),
              const SizedBox(width: 8),
              Text('大脑奖励系统', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '戒断后，你的大脑正在重新平衡',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          // Simple brain diagram representation
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BrainLabel('🧘 PFC\n自控', Colors.blue.shade100),
                  _BrainLabel('🧪 NAc\n奖赏', Colors.orange.shade100),
                  _BrainLabel('😌 杏仁核\n情绪', Colors.red.shade100),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ..._brainCards.map((c) => _BrainCard(c)),
        ],
      ),
    );
  }

  Widget _BrainLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _BrainCard extends StatelessWidget {
  final _BrainCardData data;
  const _BrainCard(this.data);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(data.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(data.subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(data.duration, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 2: 🫁 身体 ─────────────────────────────────────────

class _BodyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final milestones = HealthMilestone.milestones;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🫁', style: theme.textTheme.displaySmall),
              const SizedBox(width: 8),
              Text('身体修复时间线', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '滑动查看身体恢复里程碑',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: milestones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final m = milestones[i];
                final days = m['days'] as int;
                final title = m['title'] as String;
                final desc = m['desc'] as String;
                final organ = m['organ'] as String;
                final pct = m['pct'] as int;

                final cardWidth = 180.0;
                return SizedBox(
                  width: cardWidth,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(organ, style: const TextStyle(fontSize: 28)),
                              const Spacer(),
                              Text(
                                '${days}d',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Text('恢复 $pct%', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(
                                pct >= 100 ? Colors.green : pct >= 50 ? Colors.orange : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 3: 💰 生活 ──────────────────────────────────────────

const _benefitGrid = [
  _BenefitItem('💰', '省钱', '省了'),
  _BenefitItem('❤️', '健康', '身体变好'),
  _BenefitItem('😊', '心情', '情绪稳定'),
  _BenefitItem('👨‍👩‍👧', '家人', '关系改善'),
  _BenefitItem('🏃', '精力', '活力充沛'),
  _BenefitItem('🧠', '自信', '自控力强'),
];

class _BenefitItem {
  final String emoji;
  final String title;
  final String subtitle;
  const _BenefitItem(this.emoji, this.title, this.subtitle);
}

class _LifePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('💰', style: theme.textTheme.displaySmall),
              const SizedBox(width: 8),
              Text('戒断的好处', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '戒断后，生活变得更好',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              physics: const NeverScrollableScrollPhysics(),
              children: _benefitGrid.map((b) => _BenefitCard(b)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final _BenefitItem data;
  const _BenefitCard(this.data);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(data.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(data.subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Page 4: 📊 数据 ──────────────────────────────────────────

const _statCards = [
  _StatItem('6-30次', '平均尝试\n成功次数'),
  _StatItem('2-3倍', '专业帮助\n提高成功率'),
  _StatItem('50%', '5年肺癌\n风险降低'),
];

class _StatItem {
  final String number;
  final String label;
  const _StatItem(this.number, this.label);
}

class _StatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('📊', style: theme.textTheme.displaySmall),
              const SizedBox(width: 8),
              Text('科学告诉你', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '基于研究的戒断数据',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          ..._statCards.map((s) => _StatCard(s)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💪', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '每一次尝试都让你更接近成功！',
                    style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
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
}

class _StatCard extends StatelessWidget {
  final _StatItem data;
  const _StatCard(this.data);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Text(
              data.number,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Text(data.label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
