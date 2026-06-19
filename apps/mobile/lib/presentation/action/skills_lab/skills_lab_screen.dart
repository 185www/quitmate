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
              content: Text('✅ 已完成 $total/${_allExercises.length} 个练习'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('SkillsLab: 保存完成状态失败: $e');
    }
  }

  // ── Category definitions ──
  static const _categories = <_CategoryDef>[
    _CategoryDef(id: 'cbt', name: 'CBT 认知行为疗法', icon: Icons.psychology, emoji: '🧠'),
    _CategoryDef(id: 'act', name: 'ACT 接受与承诺疗法', icon: Icons.explore, emoji: '🌿'),
    _CategoryDef(id: 'motivation', name: '动机增强', icon: Icons.bolt, emoji: '💪'),
    _CategoryDef(id: 'health', name: '健康教育', icon: Icons.health_and_safety, emoji: '🫁'),
    _CategoryDef(id: 'behavior', name: '行为替代', icon: Icons.directions_run, emoji: '🏃'),
    _CategoryDef(id: 'relapse', name: '复发预防', icon: Icons.shield, emoji: '🛡️'),
    _CategoryDef(id: 'mindfulness', name: '正念减压', icon: Icons.self_improvement, emoji: '🧘'),
  ];

  // ── All 30 exercises ──
  static const _allExercises = <_ExerciseData>[
    // ──────── CBT 认知行为疗法 (1-8) ────────
    _ExerciseData(
      icon: Icons.edit_note,
      title: '思维记录',
      subtitle: '捕捉自动思维，用理性回应挑战',
      category: 'cbt',
      description:
          '自动思维是我们在面对情境时瞬间产生的想法，通常带有偏差。通过记录和挑战这些想法，你可以打破消极思维模式。',
      steps: [
        '描述触发情境：发生了什么？',
        '记录自动思维：脑海中闪过了什么想法？',
        '寻找支持证据：有什么事实支持这个想法？',
        '寻找反驳证据：有什么事实不支持这个想法？',
        '写下理性回应：更平衡、更现实的想法是什么？',
      ],
      reference: '认知行为疗法通过识别和重构自动思维，可显著降低物质渴求 (Beck et al., 1993)',
      duration: '5分钟',
    ),
    _ExerciseData(
      icon: Icons.waves,
      title: '渴望冲浪',
      subtitle: '观察渴望如海浪般自然起伏消退',
      category: 'cbt',
      description:
          '渴望就像海浪，有起有落。与其对抗，不如观察它、接纳它，让它自然消退。研究表明渴望通常在5-20分钟内达到峰值后消退。',
      steps: [
        '找个舒适的位置坐下，闭上眼睛',
        '注意身体哪里感受到渴望（胸口、喉咙、腹部等）',
        '像冲浪者观察海浪一样观察这种感觉',
        '不要评判或抗拒，只是看着它变化',
        '注意渴望的强度如何自然变化直到消退',
      ],
      reference: '渴望冲浪技术基于正念认知疗法，效果显著 (Bowen et al., 2009)',
      duration: '5分钟',
    ),
    _ExerciseData(
      icon: Icons.visibility,
      title: '5-4-3-2-1接地练习',
      subtitle: '用感官将注意力带回当下',
      category: 'cbt',
      description:
          '当渴望或焦虑来袭时，接地练习可以帮助你快速回到当下，打断自动化的渴求反应。通过调动五种感官，将注意力从内在冲动转移到现在。',
      steps: [
        '看：环顾四周，说出你看到的5样东西',
        '摸：注意身体触感，说出你摸到的4样东西',
        '听：仔细倾听，说出你听到的3种声音',
        '闻：深呼吸，说出你闻到的2种气味',
        '尝：注意口腔中的味道，说出你尝到的1种味道',
      ],
      reference: '接地技术是CBT和DBT的核心技能，对情绪调节有立竿见影的效果 (Linehan, 2014)',
      duration: '3分钟',
    ),
    _ExerciseData(
      icon: Icons.balance,
      title: '成本效益分析',
      subtitle: '理性权衡使用与戒断的利弊',
      category: 'cbt',
      description:
          '写下使用和戒断的短期与长期利弊，可以帮助你在渴望时看清真正的选择。大脑在渴望时会高估短期满足、低估长期代价。',
      steps: [
        '写下继续使用的好处（短期快感、缓解压力等）',
        '写下继续使用的代价（健康、金钱、关系等）',
        '写下戒断的好处（健康恢复、省钱、自尊等）',
        '写下戒断的代价（不适感、社交压力等）',
        '比较两栏，思考什么对你真正重要',
      ],
      reference: '决策平衡技术是动机性访谈的核心，能有效增强戒断动机 (Miller & Rollnick, 2012)',
      duration: '10分钟',
    ),
    _ExerciseData(
      icon: Icons.credit_card,
      title: '应对卡',
      subtitle: '创建个人化紧急应对方案',
      category: 'cbt',
      description:
          '应对卡是你在渴望来临时可以立刻使用的"急救工具"。提前准备好，当渴望出现时不用思考就能执行。',
      steps: [
        '列出你最可能使用的情境（如压力、社交、无聊）',
        '针对每种情境写下3个可以做的替代行为',
        '写下当你渴望时提醒自己的话（如"渴望会在20分钟内消退"）',
        '把应对卡保存在手机或钱包里随时查看',
        '定期更新和复习你的应对卡',
      ],
      reference: '应对卡是CBT复发预防的关键工具，能显著降低复发率 (Marlatt & Donovan, 2005)',
      duration: '15分钟',
    ),
    _ExerciseData(
      icon: Icons.self_improvement,
      title: '渐进式放松',
      subtitle: '逐组紧张和放松肌肉来缓解压力',
      category: 'cbt',
      description:
          '渐进式肌肉放松（PMR）通过交替紧张和放松不同肌群，帮助身体深度放松。这可以缓解压力诱发的渴望，改善睡眠质量。',
      steps: [
        '找个安静的地方坐下或躺下，深呼吸3次',
        '紧张双脚和脚踝5秒，然后突然放松，感受松弛感',
        '依次紧张并放松：小腿→大腿→腹部→双手→手臂',
        '继续：肩膀→颈部→面部（皱眉、张嘴）',
        '全身扫描：检查是否还有紧张的部位，再做一次放松',
      ],
      reference: '渐进式放松法由Jacobson(1938)创立，对焦虑和物质渴求有显著缓解效果',
      duration: '10分钟',
    ),
    _ExerciseData(
      icon: Icons.map,
      title: '诱因地图',
      subtitle: '识别高危情境并提前规划',
      category: 'cbt',
      description:
          '了解你的个人诱因是预防复发的第一步。通过绘制诱因地图，你可以提前识别高危情境并制定应对策略。',
      steps: [
        '回顾过去的使用模式：何时何地最想使用？',
        '分类列出诱因：情绪诱因、社交诱因、环境诱因',
        '评估风险等级：对每个诱因打分1-10',
        '针对高风险诱因制定具体应对方案',
        '建立支持系统：谁可以在关键时刻帮助你？',
      ],
      reference: '诱因识别与应对规划是CBT复发预防模型的核心 (Witkiewitz & Marlatt, 2004)',
      duration: '10分钟',
    ),
    _ExerciseData(
      icon: Icons.auto_fix_high,
      title: '认知重构',
      subtitle: '识别并挑战自动消极思维',
      category: 'cbt',
      description:
          '许多戒断困难源于认知扭曲——比如"全或无"思维（一次失败就永远失败）、灾难化思维（戒不了了）。通过识别和重构这些扭曲，你可以建立更现实、更有支持力的思维方式。',
      steps: [
        '觉察：捕捉让你想放弃的自动想法（如"我做不到"）',
        '识别扭曲类型：它是全或无？灾难化？读心术？',
        '质疑证据：有什么证据支持或反驳这个想法？',
        '替换：用更平衡的想法替代（如"今天很困难，但我已经坚持了X天"）',
        '记录：写下前后对比，感受认知转变',
      ],
      reference: '认知重构是CBT核心技术，Burns(1980)总结了10种常见认知扭曲及其应对方法',
      duration: '8分钟',
    ),

    // ──────── ACT 接受与承诺疗法 (9-12) ────────
    _ExerciseData(
      icon: Icons.explore,
      title: '价值观澄清',
      subtitle: '明确你为什么而戒',
      category: 'act',
      description:
          '当你的行动与你真正在乎的价值观一致时，改变会变得更有动力。价值观不是目标（目标可以达成），而是你想要持续成为的人和生活的方式。',
      steps: [
        '想象你理想的一天：你希望怎样度过？和谁在一起？',
        '从以下领域选择最重要的3个：家庭、健康、事业、友情、个人成长、社区',
        '为每个价值观写下一个理由：为什么这对你重要？',
        '反思：继续使用是否与你的价值观一致？',
        '写下承诺：我将因为（价值观）而坚持戒断',
      ],
      reference: '价值观澄清是ACT的第一步，能显著提升内在动机 (Hayes et al., 2006)',
      duration: '10分钟',
    ),
    _ExerciseData(
      icon: Icons.open_in_full,
      title: '接纳练习',
      subtitle: '学会接受不舒服的感觉',
      category: 'act',
      description:
          '戒断时不适感是正常的生理和心理反应。与其拼命消除这些感觉（往往适得其反），不如学会为它们腾出空间，让它们自然来去。',
      steps: [
        '闭上眼睛，注意此刻身体有什么不舒服的感觉',
        '想象这个感觉是一个物体：它是什么形状、颜色、温度？',
        '告诉自己："我注意到这种感觉的存在，我允许它在这里"',
        '继续呼吸，观察这个感觉是否在变化',
        '提醒自己：感觉不等于事实，不舒服不等于需要使用',
      ],
      reference: '经验性回避是心理困扰的核心，接纳练习能有效减少回避行为 (Hayes et al., 1999)',
      duration: '5分钟',
    ),
    _ExerciseData(
      icon: Icons.label_off,
      title: '认知解离',
      subtitle: '"我有了这个想法" vs "我是这个想法"',
      category: 'act',
      description:
          '当我们把想法当成"事实"时，它们就会控制我们。认知解离帮助我们退后一步，看到想法只是大脑产生的文字和图像，不等于现实。',
      steps: [
        '找一个让你想放弃的重复性想法（如"我受不了了"）',
        '在前面加"我注意到我有了这个想法："，重新说一遍',
        '用滑稽的声音把这个想法大声说出来（改变语境）',
        '想象这个想法像云一样飘过，你只是观察者',
        '选择：基于这个想法行动，还是基于你的价值观行动？',
      ],
      reference: '认知解离是ACT六大核心过程之一，能有效减少想法对行为的控制 (Masuda et al., 2004)',
      duration: '5分钟',
    ),
    _ExerciseData(
      icon: Icons.flag,
      title: '承诺行动',
      subtitle: '设定本周的具体行动计划',
      category: 'act',
      description:
          '知道"为什么"戒之后，需要转化为具体的"做什么"。承诺行动是将价值观转化为现实行为的过程，重点在于即便有不适感也坚持行动。',
      steps: [
        '回顾你的核心价值观，选择本周最想体现的一个',
        '设定一个SMART目标：具体、可衡量、可实现、相关、有时限',
        '识别可能的障碍：什么可能阻止你？',
        '制定"如果...就..."计划：如果X发生，我就做Y',
        '写下承诺声明：本周我将通过（行动）来体现（价值观）',
      ],
      reference: '承诺行动结合价值观导向的SMART目标设定效果最佳 (Hayes et al., 2011)',
      duration: '10分钟',
    ),

    // ──────── 动机增强 (13-15) ────────
    _ExerciseData(
      icon: Icons.compare_arrows,
      title: '决策平衡',
      subtitle: '戒的好处 vs 不戒的好处',
      category: 'motivation',
      description:
          '人们改变行为通常不是因为被告知应该改变，而是因为自己意识到了改变的充分理由。通过系统性地比较改变和不改变的利弊，可以激发内在动机。',
      steps: [
        '画一个四象限表格',
        '左上：继续使用的好处（诚实地写，不评判自己）',
        '左下：继续使用的代价',
        '右上：戒断的好处（短期和长期分开写）',
        '右下：戒断的代价（承认困难是诚实的表现）',
        '整体比较：哪个方向的长期收益更大？',
      ],
      reference: '决策平衡是跨理论模型(TTM)的核心技术，能有效促进行为改变 (Prochaska & DiClemente, 1983)',
      duration: '10分钟',
    ),
    _ExerciseData(
      icon: Icons.visibility_outlined,
      title: '未来自我想象',
      subtitle: '想象戒断成功后的自己',
      category: 'motivation',
      description:
          '研究表明，能够生动想象未来积极自我的人，更愿意为长期目标付出短期代价。这个练习帮助你"预览"成功后的生活。',
      steps: [
        '闭上眼睛，深呼吸3次放松身体',
        '想象6个月后的你：你看起来怎么样？感觉如何？',
        '具体化：你在做什么？和谁在一起？周围是什么环境？',
        '注意6个月后你的呼吸、体力、皮肤、精神状态',
        '睁开眼睛，写下3个最让你心动的画面，作为动力提醒',
      ],
      reference: '未来自我连续性理论表明，对未来自我越清晰，当下越能做出有利决策 (Hershfield, 2011)',
      duration: '5分钟',
    ),
    _ExerciseData(
      icon: Icons.straighten,
      title: '动机尺',
      subtitle: '量化你的戒断动机并追踪变化',
      category: 'motivation',
      description:
          '动机不是固定不变的，它会随着时间、情境和经历而波动。定期量化你的动机，可以帮助你识别动机低谷期并提前干预。',
      steps: [
        '在0-10的尺度上：你有多想戒？（0=完全不想，10=极其想戒）',
        '写下选择这个数字的理由：为什么不是更少？为什么不是更多？',
        '回顾上次的分数：上升了还是下降了？是什么导致的？',
        '如果分数低于5：列出3个能提升动机的具体行动',
        '设定提醒：明天同一时间再做一次评估',
      ],
      reference: '重要性-自信心标尺是动机性访谈的经典工具 (Miller & Rollnick, 2013)',
      duration: '3分钟',
    ),

    // ──────── 健康教育 (16-18) ────────
    _ExerciseData(
      icon: Icons.timeline,
      title: '身体恢复时间线',
      subtitle: '了解你的身体如何修复',
      category: 'health',
      description:
          '了解戒断后身体的具体恢复过程，可以给你提供科学依据和希望。这些时间线基于大规模流行病学研究，是你的身体正在发生的真实变化。',
      steps: [
        '20分钟：心率和血压开始恢复正常',
        '8小时：血液中一氧化碳和尼古丁水平下降一半',
        '24小时：心脏病发作风险开始降低',
        '48小时：味觉和嗅觉神经末梢开始再生',
        '2-12周：循环改善，肺功能增强30%',
        '1年：冠心病风险降低50%',
      ],
      reference: '数据来源：美国疾病控制中心(CDC)、世界卫生组织(WHO)戒烟时间线',
      duration: '3分钟',
    ),
    _ExerciseData(
      icon: Icons.medical_information,
      title: '戒断症状管理',
      subtitle: '了解和管理常见戒断反应',
      category: 'health',
      description:
          '了解戒断症状是正常的、暂时的，可以减少对它们的恐惧。大多数症状在2-4周内达到峰值后逐渐消退。知道"这是正常的"本身就是一种强大的应对。',
      steps: [
        '头痛：多喝水、轻柔按摩太阳穴、保证睡眠',
        '焦虑/烦躁：深呼吸、渐进式放松、适量运动',
        '失眠：建立规律作息、睡前避免咖啡因、用呼吸法放松',
        '注意力下降：一次只做一件事、适当休息、不要苛责自己',
        '食欲增加：选择健康零食、用低热量食物替代、规律进餐',
        '记住：这些症状都在2-4周内显著减轻',
      ],
      reference: '戒断症状管理指南 (Hughes, 2007; American Psychiatric Association, 2013)',
      duration: '5分钟',
    ),
    _ExerciseData(
      icon: Icons.family_restroom,
      title: '二手烟/酒危害',
      subtitle: '了解对身边人的影响',
      category: 'health',
      description:
          '你的戒断不仅对自己有益，也在保护你爱的人。了解二手烟/二手酒对家人尤其是儿童的危害，可以为你提供额外的动力来源。',
      steps: [
        '二手烟导致非吸烟者肺癌风险增加20-30%（WHO数据）',
        '儿童暴露于二手烟：哮喘风险增加40%，中耳炎增加60%',
        '家庭成员的饮酒模式会显著影响孩子的未来饮酒行为',
        '想象你的家人因为你的戒断而获得更健康的未来',
        '写下你想保护的那个人的名字，放在显眼的地方',
      ],
      reference: 'WHO全球烟草流行报告(2021)；美国儿科学会关于二手烟的政策声明',
      duration: '3分钟',
    ),

    // ──────── 行为替代 (19-22) ────────
    _ExerciseData(
      icon: Icons.air,
      title: '深呼吸练习',
      subtitle: '4-7-8呼吸法详解',
      category: 'behavior',
      description:
          '4-7-8呼吸法由Andrew Weil博士推广，是一种简单有效的自主神经系统调节技术。吸气4秒激活副交感神经，屏息7秒促进氧气交换，呼气8秒深度放松。',
      steps: [
        '坐直身体，舌尖抵住上颚门牙后方',
        '完全呼气，发出"呼"的声音',
        '闭上嘴，用鼻子安静吸气，默数4秒',
        '屏住呼吸，默数7秒',
        '用嘴呼气（发出"呼"声），默数8秒',
        '这是1个循环，重复4个循环',
      ],
      reference: '4-7-8呼吸法基于瑜伽调息法，临床研究显示可显著降低焦虑和心率 (Ma et al., 2017)',
      duration: '2分钟',
    ),
    _ExerciseData(
      icon: Icons.hourglass_top,
      title: '渴望延迟技巧',
      subtitle: 'WAIT法则',
      category: 'behavior',
      description:
          'WAIT是"Watch Your Inner Thoughts"（观察你的内心想法）的缩写。核心原则是：不是"永远不使用"，而是"今天此刻不使用"。研究表明大多数渴望在15-20分钟内消退。',
      steps: [
        'W - Watch（观察）：注意到渴望出现了，不评判',
        'A - Accept（接受）：告诉自己对这种感觉感到不舒服是正常的',
        'I - Investigate（探究）：这种感觉在身体的哪个部位？强度1-10？',
        'T - Take action（采取行动）：做一件需要双手的事（喝水、散步、聊天）',
        '设定一个15分钟计时器：告诉自己"15分钟后再决定"',
        '15分钟后重新评估：渴望通常已经明显减弱',
      ],
      reference: '延迟策略是冲动控制训练的核心技术 (Dougherty et al., 2007)',
      duration: '即时',
    ),
    _ExerciseData(
      icon: Icons.list_alt,
      title: '健康替代行为清单',
      subtitle: '建立个人替代菜单',
      category: 'behavior',
      description:
          '当渴望来临时，大脑需要一个新的"出口"。提前准备好替代行为清单，可以在关键时刻提供即时的替代选择。关键是这些行为要容易获取、无需太多准备。',
      steps: [
        '即时替代（30秒内可做）：喝冷水、深呼吸3次、嚼口香糖',
        '短期替代（5-10分钟）：散步、打电话给朋友、洗把脸',
        '中期替代（30分钟）：运动、做饭、看电影、读一章书',
        '感官替代：闻柠檬/薄荷精油、握冰块、弹橡皮筋',
        '从上面选择5-8个最适合你的，写下来随身携带',
      ],
      reference: '替代行为训练是行为疗法的基础技术，有效性得到大量临床研究支持 (Carroll, 1998)',
      duration: '10分钟',
    ),
    _ExerciseData(
      icon: Icons.fitness_center,
      title: '运动处方',
      subtitle: '根据喜好定制运动计划',
      category: 'behavior',
      description:
          '运动是天然的"抗渴求剂"。研究显示仅15分钟的中等强度运动就能减少50%的渴求感，效果可持续50分钟以上。运动还能促进多巴胺和内啡肽分泌，改善情绪。',
      steps: [
        '选择你喜欢的运动类型：快走、跑步、骑车、游泳、瑜伽等',
        '新手处方：每天快走15-20分钟，或每周3次30分钟有氧运动',
        '关键原则：选择你真正享受的，而不是"应该"做的',
        '应急运动：当渴望来临时，做20个开合跳或下楼走一圈',
        '进阶：尝试运动时正念（注意呼吸、肌肉感觉、周围环境）',
      ],
      reference: '运动对物质渴求的急性减少效应 (Ussher et al., 2014); 运动与成瘾恢复综述 (Williams & Gerber, 2022)',
      duration: '15-30分钟',
    ),

    // ──────── 复发预防 (23-26) ────────
    _ExerciseData(
      icon: Icons.warning_amber,
      title: '高危情境识别',
      subtitle: '找出你的危险场景',
      category: 'relapse',
      description:
          'Marlatt和Gordon的复发预防模型指出，复发往往不是突然发生的，而是由特定的高危情境触发的。提前识别这些情境是预防复发的关键。',
      steps: [
        '回顾你过去复发的经历（如果有的话）：之前发生了什么？',
        '列出你的个人高危情境：社交聚会、压力、负面情绪、无聊',
        '对每个情境评估风险等级（1-10）和发生频率（高/中/低）',
        '识别高×高组合：这些是你的首要防范目标',
        '为每个高危情境提前准备好应对策略',
      ],
      reference: 'GWIM模型（GORSCHA-Williams跨理论整合模型）基于Marlatt复发预防理论 (Marlatt & Witkiewitz, 2005)',
      duration: '10分钟',
    ),
    _ExerciseData(
      icon: Icons.record_voice_over,
      title: '拒绝技巧训练',
      subtitle: '练习说"不"的多种方式',
      category: 'relapse',
      description:
          '社交压力是复发的最常见诱因之一。预先练习拒绝技巧，可以在真实场景中减少"措手不及"的情况。反复练习直到拒绝变成自动反应。',
      steps: [
        '直接拒绝法："不了，谢谢，我已经戒了"',
        '延迟法："我现在不方便，待会再说"（争取时间离开）',
        '转移法："我不抽，但我们可以聊聊"（改变话题）',
        '坚定法："我的健康比这个更重要"，说完转身走',
        '在镜子前大声练习至少3遍，直到说起来自然',
      ],
      reference: '社交技能训练和拒绝技巧是复发预防的标准化干预 (Brownell et al., 1986)',
      duration: '5分钟',
    ),
    _ExerciseData(
      icon: Icons.trending_down,
      title: '滑坡模型',
      subtitle: '了解"只是吸一口"的危险',
      category: 'relapse',
      description:
          '"就这一次"是复发的经典入口。滑坡模型帮助你理解，一次"小小的例外"如何通过认知扭曲和心理反应链导致完全复发。',
      steps: [
        '第一阶段：违规决定（"就一口/一杯，没事的"）',
        '第二阶段：违规行为（实际使用了一点点）',
        '第三阶段：失调反应（"我已经破了戒了，干脆算了吧"）',
        '第四阶段：积极后果减少（动机下降，不再抵抗）',
        '防御策略：在第一阶段就喊停，用4-7-8呼吸和应对卡',
      ],
      reference: '违禁效果（Abstinence Violation Effect）理论 (Marlatt & Gordon, 1985)',
      duration: '5分钟',
    ),
    _ExerciseData(
      icon: Icons.backpack,
      title: '复发应急包',
      subtitle: '准备你的随身应对工具包',
      category: 'relapse',
      description:
          '当危机来临时，大脑的前额叶（理性决策区域）功能下降，你很难临时想出好的应对策略。提前准备一个物理或数字的"应急包"，可以在关键时刻救命。',
      steps: [
        '口袋/手机：紧急联系人（支持你的朋友或家人号码）',
        '物品：薄荷糖/口香糖、压力球、小瓶薄荷精油',
        '数字：保存一段你的"决心录音"或家人的照片到手机',
        '行动清单：写下3个即时可以做的事（如"出去走10分钟"）',
        '应急话术："渴望会在20分钟内消退，我只需要等一等"',
      ],
      reference: '复发预防工具包是循证干预的标准组件 (Witkiewitz & Marlatt, 2007)',
      duration: '15分钟',
    ),

    // ──────── 正念减压 (27-30) ────────
    _ExerciseData(
      icon: Icons.accessibility_new,
      title: '身体扫描',
      subtitle: '10分钟全身觉察练习',
      category: 'mindfulness',
      description:
          '身体扫描是MBSR（正念减压疗法）的核心练习之一。通过系统性地将注意力带到身体各部位，你可以增强身心连接，减少自动化反应，提升对渴求的觉察力。',
      steps: [
        '平躺或坐着，闭上眼睛，做3次深呼吸',
        '从脚趾开始，注意那里的感觉（温度、触感、紧张度）',
        '缓慢向上移动注意力：脚→小腿→膝盖→大腿→骨盆',
        '继续：腹部→胸部→双手→手臂→肩膀→颈部→面部',
        '如果走神了（这很正常），温柔地把注意力带回到当前部位',
        '最后感受整个身体作为一个整体的存在',
      ],
      reference: '身体扫描是MBSR的标准化练习，Kabat-Zinn(1990)创立的正念减压疗法已被广泛应用',
      duration: '10分钟',
    ),
    _ExerciseData(
      icon: Icons.timer,
      title: '三分钟呼吸空间',
      subtitle: 'MBSR核心练习',
      category: 'mindfulness',
      description:
          '三分钟呼吸空间是MBSR中最精炼的练习，分为三个阶段：觉察（acknowledge）、收集（collect）、扩展（expand）。它可以在任何时间、任何地点进行，是日常正念练习的基石。',
      steps: [
        '第1分钟 - 觉察：问自己"此刻我正在经历什么？"——念头、情绪、身体感觉',
        '第2分钟 - 收集：将全部注意力集中在呼吸上，感受每一次吸气和呼气',
        '第3分钟 - 扩展：将注意力从呼吸扩展到整个身体，接纳此刻的一切',
        '练习结束后，带着觉察回到日常活动中',
        '建议：每天在固定时间练习（如起床后、午休、睡前）',
      ],
      reference: '三分钟呼吸空间源自MBCT（正念认知疗法），Segal et al.(2002)',
      duration: '3分钟',
    ),
    _ExerciseData(
      icon: Icons.restaurant,
      title: '正念进食',
      subtitle: '用正念方式吃饭/喝水',
      category: 'mindfulness',
      description:
          '正念进食将正念练习融入日常生活。很多人在使用后通过暴饮暴食来补偿。正念进食帮助你重建与食物的健康关系，同时也是一种随时可以进行的正念练习。',
      steps: [
        '选择一顿饭或一个零食，关掉手机和电视',
        '在吃之前，用全部感官观察食物：颜色、形状、气味',
        '缓慢地咬一小口，注意口感、味道、温度的层次变化',
        '放下餐具，充分咀嚼，感受吞咽的感觉',
        '每吃一口都重复这个过程，注意饱腹感何时出现',
      ],
      reference: '正念进食训练可有效减少暴饮暴食行为 (Kristeller & Wolever, 2011)',
      duration: '15分钟',
    ),
    _ExerciseData(
      icon: Icons.favorite,
      title: '感恩练习',
      subtitle: '记录3件感恩的事',
      category: 'mindfulness',
      description:
          '感恩练习是积极心理学中被研究最广泛的干预之一。定期练习感恩可以增加积极情绪、改善睡眠、增强免疫力，并减少对消极事物的关注。在戒断过程中，它能帮你重新发现生活的美好。',
      steps: [
        '找一段安静的时间（睡前或早起最好）',
        '写下今天3件你感恩的事情（可以很小：一杯好喝的茶、一个微笑）',
        '对每件事，写下你为什么感恩——这能加深感受',
        '如果觉得困难，可以试试"对比"视角：想象没有这件事会怎样',
        '坚持一周，你会发现自己开始更多地注意到积极的事物',
      ],
      reference: '感恩干预对主观幸福感的元分析 (Emmons & McCullough, 2003); Wood et al.(2010)',
      duration: '5分钟',
    ),
  ];

  // ── Helper: get filtered exercises ──
  List<_ExerciseData> get _filteredExercises {
    if (_selectedCategory == 'all') return _allExercises;
    return _allExercises.where((e) => e.category == _selectedCategory).toList();
  }

  // Map global index to local filtered index for tracking
  int _globalIndex(int localIndex) {
    final filtered = _filteredExercises;
    if (localIndex >= filtered.length) return -1;
    return _allExercises.indexOf(filtered[localIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('干预技能库'),
        actions: [
          if (!_loadingPreferences)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(
                  '${_completedExercises.length}/${_allExercises.length}',
                  style: const TextStyle(fontSize: 12),
                ),
                avatar: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: _completedExercises.length >= 20
                      ? Colors.amber
                      : _completedExercises.length >= 10
                          ? Colors.blue
                          : _completedExercises.length >= 5
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: _loadingPreferences
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category filter chips
                _buildCategoryFilter(),
                // Header info
                _buildHeader(),
                // Exercise list
                Expanded(
                  child: _buildExerciseList(),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip('all', '全部', Icons.apps, _allExercises.length),
          ..._categories.map((c) {
            final count = _allExercises.where((e) => e.category == c.id).length;
            return _filterChip(c.id, '${c.emoji} ${c.name}', c.icon, count);
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label, IconData icon, int count) {
    final selected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = id;
            _expandedIndex = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.3)
                      : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final cat = _categories.where((c) => c.id == _selectedCategory).firstOrNull;
    final title = cat != null ? '${cat.emoji} ${cat.name}' : '多类别循证干预技能';
    final desc = cat != null
        ? '已完成 ${_completedExercises.where((i) => i < _allExercises.length && _allExercises[i].category == _selectedCategory).length} / ${_allExercises.where((e) => e.category == _selectedCategory).length} 个练习'
        : '基于CBT、ACT、正念等循证方法的30个干预技能';
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (_completedExercises.length >= 20)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        '技能大师',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_completedExercises.length >= 10)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.military_tech, size: 14, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        '技能探索者',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_completedExercises.length >= 5)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'CBT学徒',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    final exercises = _filteredExercises;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final ex = exercises[index];
        final gi = _globalIndex(index);
        final isExpanded = _expandedIndex == gi;
        final isCompleted = gi >= 0 && _completedExercises.contains(gi);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    ex.icon,
                    size: 20,
                    color: isCompleted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ex.title,
                        style: isCompleted
                            ? TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              )
                            : null,
                      ),
                    ),
                    if (ex.duration.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ex.duration,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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
                    _expandedIndex = isExpanded ? null : gi;
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
                          onPressed: () => _completeExercise(gi),
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
    );
  }
}

class _ExerciseData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String category;
  final String description;
  final List<String> steps;
  final String reference;
  final String duration;

  const _ExerciseData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.description,
    required this.steps,
    required this.reference,
    this.duration = '',
  });
}

class _CategoryDef {
  final String id;
  final String name;
  final IconData icon;
  final String emoji;

  const _CategoryDef({
    required this.id,
    required this.name,
    required this.icon,
    required this.emoji,
  });
}