import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/onboarding_stepper.dart';
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
          style: theme.textTheme.titleMedium
              ?.copyWith(color: Colors.grey.shade600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          const OnboardingStepper(currentStep: 1),
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
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
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
              Text('大脑奖励系统',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '戒断后，你的大脑正在重新平衡',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
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
                  _brainLabel('🧘 PFC\n自控', Colors.blue.shade100),
                  _brainLabel('🧪 NAc\n奖赏', Colors.orange.shade100),
                  _brainLabel('😌 杏仁核\n情绪', Colors.red.shade100),
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

  Widget _brainLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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
                  Text(data.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(data.subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(data.duration,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
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
              Text('身体修复时间线',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '滑动查看身体恢复里程碑',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Text('恢复 $pct%',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.primary)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(
                                pct >= 100
                                    ? Colors.green
                                    : pct >= 50
                                        ? Colors.orange
                                        : theme.colorScheme.primary,
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

const _benefits = [
  _BenefitDetail(
    emoji: '💰',
    title: '省钱',
    shortDesc: '省下真金白银',
    detail: '按每天的花费计算，一年省下的钱相当于一部新手机。十年省下的钱够一次全家旅行。如果继续下去，这些钱只会越来越多，而且你的医疗费用也会随之上升。',
    ifContinue: '每多一年，你在烟酒上的花费都在增长。很多长期吸烟者的终身花费超过几十万元。',
  ),
  _BenefitDetail(
    emoji: '❤️',
    title: '健康',
    shortDesc: '身体开始修复',
    detail: '戒断 20 分钟后心率恢复正常。24 小时后心脏病发作风险开始降低。1 年后冠心病风险降低一半。5 年后中风风险降至非吸烟者水平。10 年后肺癌风险降低一半。',
    ifContinue: '长期使用导致 COPD、肺癌、心血管疾病风险持续上升。越早戒，恢复得越好。',
  ),
  _BenefitDetail(
    emoji: '😊',
    title: '心情',
    shortDesc: '情绪更稳定',
    detail: '戒断初期可能有 2-3 周的焦虑波动，但之后情绪会显著改善。研究表明戒断者抑郁症状减少，焦虑水平降低，整体心理幸福感提升。',
    ifContinue: '尼古丁的波动让你长期处于"焦虑→缓解→再焦虑"的恶性循环中，这不是真正的放松。',
  ),
  _BenefitDetail(
    emoji: '👨‍👩‍👧',
    title: '家人',
    shortDesc: '关系更和谐',
    detail: '二手烟/酒气会导致家人呼吸道疾病风险增加 20-30%，儿童中耳炎风险增加。戒断后家庭氛围更和谐，孩子也更不容易模仿这个习惯。',
    ifContinue: '你的家人可能正在默默承受二手烟/二手酒气的影响。孩子的模仿行为在 12 岁前最为敏感。',
  ),
  _BenefitDetail(
    emoji: '🏃',
    title: '精力',
    shortDesc: '活力充沛',
    detail: '戒断后血氧水平提升，体力恢复明显。原本爬三层楼就喘，一个月后你会发现耐力显著改善。不再每天午后犯困，运动表现提升。',
    ifContinue: '长期使用导致慢性缺氧，体力持续下降，精力越来越差，这是一个不可逆的趋势。',
  ),
  _BenefitDetail(
    emoji: '🧠',
    title: '自信',
    shortDesc: '自控力变强',
    detail: '每成功抵抗一次渴望，你的前额叶皮层就在强化。神经科学证实意志力像肌肉，越练越强。成功戒断的人普遍报告更高的自我效能感和生活掌控感。',
    ifContinue: '持续依赖意味着你的一部分自由选择权已经被剥夺了，每次"需要"使用的时候你其实没有选择。',
  ),
];

class _BenefitDetail {
  final String emoji;
  final String title;
  final String shortDesc;
  final String detail;
  final String ifContinue;
  const _BenefitDetail({
    required this.emoji,
    required this.title,
    required this.shortDesc,
    required this.detail,
    required this.ifContinue,
  });
}

class _LifePage extends StatefulWidget {
  @override
  State<_LifePage> createState() => _LifePageState();
}

class _LifePageState extends State<_LifePage> {
  final Set<int> _expanded = {};

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
              Text('戒断的好处',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '点击展开了解详情',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _benefits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final b = _benefits[index];
                final isExpanded = _expanded.contains(index);
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isExpanded
                        ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                        : BorderSide.none,
                  ),
                  color: isExpanded ? theme.colorScheme.primaryContainer.withOpacity(0.3) : Colors.grey.shade50,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() {
                      if (isExpanded) {
                        _expanded.remove(index);
                      } else {
                        _expanded.add(index);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(b.emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(b.shortDesc,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Text(b.detail,
                                style: TextStyle(fontSize: 14, height: 1.6, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                                  Expanded(
                                    child: Text(b.ifContinue,
                                        style: TextStyle(fontSize: 13, color: Colors.orange.shade800, height: 1.5)),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
              Text('科学告诉你',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '基于研究的戒断数据',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
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
                    style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600),
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
            Text(data.label,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade700, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
