import 'package:flutter/material.dart';
import '../../../domain/entity/user.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final Set<int> _expandedSections = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('认知教育')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            context,
            id: 0,
            icon: Icons.biotech,
            title: '成瘾的神经科学',
            subtitle: '了解成瘾如何改变大脑',
            content: _buildNeuroscienceContent(context),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            id: 1,
            icon: Icons.timeline,
            title: '身体恢复时间线',
            subtitle: '戒断后身体恢复的阶段',
            content: _buildRecoveryTimeline(context),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            id: 2,
            icon: Icons.favorite,
            title: '戒断的益处',
            subtitle: '身体和心理的积极变化',
            content: _buildBenefitsContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required int id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    final expanded = _expandedSections.contains(id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedSections.remove(id);
                } else {
                  _expandedSections.add(id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(icon, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: content,
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuroscienceContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '多巴胺与奖赏通路',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '尼古丁和酒精通过激活中脑边缘系统的多巴胺神经元，导致伏隔核（nucleus accumbens）释放大量多巴胺。'
            '这种人为的多巴胺激增（可达自然奖赏的2-10倍）强化了使用行为，形成"奖赏-记忆-渴求"的恶性循环。'
            '长期使用后，大脑的奖赏阈值升高，需要更多物质才能获得相同的快感，这是耐受性形成的基础。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 16),
          Text(
            '前额叶皮层与执行功能',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '前额叶皮层（PFC）负责冲动控制、决策和长期规划。慢性物质使用会损害PFC的功能，'
            '削弱个体抵抗渴求的能力。功能性MRI研究显示，成瘾者的PFC在面临物质相关线索时激活减弱，'
            '而杏仁核（amygdala）等情绪中心过度活跃，导致"想要"而非"喜欢"的强迫性使用行为。'
            'Goldstein & Volkow (2002) 提出的" impaired response inhibition and salience attribution "（iRISA）模型'
            '很好地解释了这一机制。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 16),
          Text(
            '杏仁核与压力反应',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '杏仁核在处理负面情绪和压力中起核心作用。戒断期间，杏仁核的过度激活导致焦虑、烦躁等戒断症状，'
            '这常成为复吸的重要诱因。Koob & Le Moal (2008) 的" anti-reward "理论指出，'
            '成瘾不仅是奖赏系统的过度激活，更是抗奖赏系统的过度适应，使得戒断者处于持续的负性情绪状态。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 16),
          _buildReference(context, 'Goldstein RZ, Volkow ND. Drug addiction and its underlying neurobiological basis: neuroimaging evidence for the involvement of the frontal cortex. Am J Psychiatry. 2002;159(10):1642-1652.'),
          const SizedBox(height: 4),
          _buildReference(context, 'Koob GF, Le Moal M. Addiction and the brain antireward system. Annu Rev Psychol. 2008;59:29-53.'),
          const SizedBox(height: 4),
          _buildReference(context, 'Volkow ND, Wang GJ, Tomasi D, Baler RD. Unbalanced neuronal circuits in addiction. Curr Opin Neurobiol. 2013;23(4):639-648.'),
        ],
      ),
    );
  }

  Widget _buildRecoveryTimeline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '戒断后身体的恢复是一个渐进的过程，以下是关键里程碑：',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 16),
          ...List.generate(HealthMilestone.milestones.length, (i) {
            final m = HealthMilestone.milestones[i];
            final days = m['days'] as int;
            final title = m['title'] as String;
            final desc = m['desc'] as String;
            final organ = m['organ'] as String;
            final pct = m['pct'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 60,
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: pct >= 100
                                ? Colors.green
                                : pct >= 50
                                    ? Colors.orange
                                    : Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              days > 0 ? '${days}d' : '0',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: pct >= 50 ? Colors.white : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        if (i < HealthMilestone.milestones.length - 1)
                          Container(
                            width: 2,
                            height: 30,
                            color: Theme.of(context).colorScheme.primaryContainer,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$organ · 恢复 $pct%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          _buildReference(context, 'CDC.gov/quit - Benefits of Quitting Smoking. Centers for Disease Control and Prevention.'),
          const SizedBox(height: 4),
          _buildReference(context, 'World Health Organization. Tobacco: Health benefits of smoking cessation. WHO Fact Sheet.'),
        ],
      ),
    );
  }

  Widget _buildBenefitsContent(BuildContext context) {
    final benefits = [
      {
        'time': '20分钟',
        'items': [
          '心率和血压开始恢复正常水平',
          '手脚温度回升至正常',
        ],
      },
      {
        'time': '24小时',
        'items': [
          '血液中一氧化碳水平降至正常',
          '氧气水平恢复正常',
          '心脏病发作风险开始降低',
        ],
      },
      {
        'time': '48小时',
        'items': [
          '尼古丁完全从体内清除',
          '味觉和嗅觉神经末梢开始再生',
          '嗅觉和味觉开始改善',
        ],
      },
      {
        'time': '72小时',
        'items': [
          '支气管开始放松',
          '呼吸变得更加顺畅',
          '精力水平提升',
        ],
      },
      {
        'time': '2周',
        'items': [
          '血液循环显著改善',
          '肺功能开始提升',
          '行走变得轻松',
        ],
      },
      {
        'time': '3个月',
        'items': [
          '肺功能改善5-10%',
          '循环系统功能大幅改善',
          '咳嗽和喘息减少',
        ],
      },
      {
        'time': '6个月',
        'items': [
          '心脏病风险降低50%',
          '免疫系统功能增强',
          '皮肤状态明显改善',
        ],
      },
      {
        'time': '1年',
        'items': [
          '冠心病风险降低50%',
          '口腔、咽喉、食道癌风险降低50%',
        ],
      },
      {
        'time': '5年',
        'items': [
          '肺癌风险降低50%',
          '口腔癌、食道癌、膀胱癌风险降低50%',
          '中风风险降至非使用者水平',
        ],
      },
      {
        'time': '10年',
        'items': [
          '肺癌死亡率降低50%',
          '心脏病风险降至与非使用者相同',
          '胰腺癌风险降低',
        ],
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '戒断后，身体会经历一系列惊人的修复过程。无论你使用多久，'
            '停止使用后身体都会立即开始修复：',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 16),
          ...benefits.map((b) {
            final time = b['time'] as String;
            final items = b['items'] as List<String>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                            Expanded(
                              child: Text(
                                item,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            '关于戒断的统计数据：',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '• 约60-70%的戒断者在使用后第一年内至少经历一次复吸（Chaiton et al., BMJ Open 2016）\n'
            '• 平均需要6-30次认真尝试才能成功戒断（Chaiton et al., BMJ Open 2016）\n'
            '• 使用行为咨询加药物辅助可将成功率提高2-3倍（Cochrane Database of Systematic Reviews）\n'
            '• 戒断5年后，肺癌风险降低约50%（CDC.gov/quit）',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.8),
          ),
          const SizedBox(height: 16),
          _buildReference(context, 'Chaiton M, Diemert L, Cohen JE, et al. Estimating the number of quit attempts it takes to quit smoking successfully in a longitudinal cohort of smokers. BMJ Open. 2016;6(6):e011045.'),
          const SizedBox(height: 4),
          _buildReference(context, 'Hartmann-Boyce J, Livingstone-Banks J, Ordóñez-Mena JM, et al. Behavioural interventions for smoking cessation: an overview and network meta-analysis. Cochrane Database Syst Rev. 2021;1(1):CD013229.'),
          const SizedBox(height: 4),
          _buildReference(context, 'CDC.gov/quit - Benefits of Quitting Smoking. Centers for Disease Control and Prevention.'),
        ],
      ),
    );
  }

  Widget _buildReference(BuildContext context, String ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📚 ',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Expanded(
          child: Text(
            ref,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}
