/// Response templates for the AI Coach engine.
///
/// v6.1 重构：从"教练建议"模式重塑为"动机访谈倾听"模式。
/// 核心变更：
/// - 移除所有"建议你"、"你需要"、"应该"类输出
/// - 改为共情反射 + 开放式提问
/// - 新增"抗拒"和"价值观"两个主题处理器
/// - 快捷回复更偏向倾听式话题延续
///
/// Placeholders like {days}, {streak}, {level}, {time_greeting} are
/// interpolated at runtime by the engine.

import 'dart:math';

// ── Data Models ────────────────────────────────────────────────────────────────

/// A group of coach response templates sharing the same trigger condition.
class CoachTemplateGroup {
  final String id;
  final String? condition;
  final List<String> responses;

  const CoachTemplateGroup({
    required this.id,
    this.condition,
    required this.responses,
  });
}

/// A topic-based handler with keyword matching, sub-routed response groups,
/// and associated quick-reply suggestions.
class CoachTopicHandler {
  final String id;
  final List<String> keywords;
  final Map<String, List<String>> subKeywords;
  final Map<String, CoachTemplateGroup> responses;
  final List<String> quickReplies;

  const CoachTopicHandler({
    required this.id,
    required this.keywords,
    this.subKeywords = const {},
    required this.responses,
    this.quickReplies = const [],
  });
}

// ── Template Registry ──────────────────────────────────────────────────────────

class CoachResponseTemplates {
  CoachResponseTemplates._();

  // ── Greeting Templates ──────────────────────────────────

  static const greetings = <CoachTemplateGroup>[
    CoachTemplateGroup(
      id: 'no_user',
      condition: 'user_is_null',
      responses: [
        '你好，我在这里。今天想聊点什么吗？',
        '欢迎回来。有什么想说的吗？随时都可以。',
        '嘿，你来了。今天过得怎么样？',
      ],
    ),
    CoachTemplateGroup(
      id: 'day_0',
      condition: 'days_since_quit == 0',
      responses: [
        '第一天。不管你是怎么来到这里的，能迈出这一步本身就不容易。今天有什么感受吗？',
        '你做了一个决定。不管结果怎样，我想听听你的想法——是什么让你今天想要做这个尝试？',
        '{time_greeting}！今天对你来说可能是个特别的日子。你现在心里是什么感觉？',
      ],
    ),
    CoachTemplateGroup(
      id: 'days_1_to_3',
      condition: '1 <= days_since_quit <= 3',
      responses: [
        '第{days}天了。身体在适应新的节奏，这并不容易。你现在感觉怎么样？',
        '{time_greeting}！{days}天了。这个阶段身体会有一些反应——你有没有注意到什么变化？',
        '前几天往往是最不适应的。你今天经历了什么？想聊聊吗？',
      ],
    ),
    CoachTemplateGroup(
      id: 'days_4_to_7',
      condition: '4 <= days_since_quit <= 7',
      responses: [
        '快一周了。回想这{days}天，你觉得自己有什么变化吗？哪怕很小的。',
        '{time_greeting}，连续{streak}天了。这周你最想跟我聊的一件事是什么？',
        '一周是个小节点。你心里现在是什么感觉？跟第一天比呢？',
      ],
    ),
    CoachTemplateGroup(
      id: 'days_8_to_30',
      condition: '8 <= days_since_quit <= 30',
      responses: [
        '{time_greeting}！{days}天了。这个阶段，心理上的习惯可能是更大的课题。你最近有没有什么发现？',
        '{days}天——你对自己有什么新的认识吗？',
        '快一个月了。如果你愿意，可以跟我聊聊这段时间对你来说意味着什么。',
      ],
    ),
    CoachTemplateGroup(
      id: 'days_31_to_90',
      condition: '31 <= days_since_quit <= 90',
      responses: [
        '{time_greeting}，{days}天。你已经走了很远。回过头看，你觉得自己最大的变化是什么？',
        '{streak}天的连续记录。你有没有发现生活中有什么不一样了？',
        '{days}天了。如果你现在能对第一天时的自己说一句话，你会说什么？',
      ],
    ),
    CoachTemplateGroup(
      id: 'days_over_90',
      condition: 'days_since_quit > 90',
      responses: [
        '{time_greeting}！{days}天，你已经在走一条很不一样的路了。最近有什么新的感悟吗？',
        '{streak}天了。你现在对以前那个习惯有什么感觉？',
        '{days}天的旅程。你今天有什么想分享的吗？',
      ],
    ),
  ];

  // ── Topic Handler Templates ──────────────────────────────

  static const topicHandlers = <CoachTopicHandler>[

    // ── Resistance（新增 v6.1：最高优先级，在渴望之前匹配）──
    CoachTopicHandler(
      id: 'resistance',
      keywords: ['不想戒', '别烦我', '别说了', '我就想喝', '我就想抽', '不想改',
                 '不可能', '做不到', '算了', '不管了', '无所谓', '你不懂',
                 '少说教', '别劝我', '我的事', '别管我', '烦死了'],
      responses: {
        'default': CoachTemplateGroup(id: 'resistance_default', responses: [
          '我完全理解。这是你的人生，你当然有权利做自己的选择。'
              '我只是在这里，如果你想聊，随时可以。',
          '听到了。我不会再说这个话题。'
              '你想聊点别的吗？或者只是安静待一会儿也行。',
          '你说得对，这是你的选择。我尊重。'
              '如果哪天你想找人聊聊，我在这里。',
          '我没有任何要说服你的意思。你今天愿意打开这个App，就已经够了。',
        ]),
      },
      quickReplies: ['我今天很累', '说说别的吧', '我想自己待着', '刚才有点冲动'],
    ),

    // ── Values（新增 v6.1：检测用户在意的价值观线索）──
    CoachTopicHandler(
      id: 'values',
      keywords: ['女儿', '儿子', '孩子', '老婆', '老公', '爸妈', '妈妈', '爸爸',
                 '家人', '家庭', '父母', '宝宝', '工作', '事业', '升职',
                 '梦想', '未来', '身体', '健康', '长寿', '跑步', '运动'],
      responses: {
        'default': CoachTemplateGroup(id: 'values_default', responses: [
          '你刚才提到了{keyword}——听起来这对你来说很重要。'
              '在你目前的生活中，这个和你的日常习惯之间有什么关系吗？',
          '{keyword}……你提到这个的时候，语气好像有些不一样。'
              '这个对你意味着什么？',
          '我注意到你很在意{keyword}。'
              '如果你闭上眼睛想象五年后的自己，你希望那时候的{keyword}是什么样的？',
        ]),
      },
      quickReplies: ['是很重要', '没想过', '有点矛盾', '说不清'],
    ),

    // ── Craving（重写 v6.1：去掉直接建议，改为共情反射+提问）──
    CoachTopicHandler(
      id: 'craving',
      keywords: ['渴', '想抽', '想喝', '忍不住', '好难', '难受', '戒断', '痛苦'],
      responses: {
        'early': CoachTemplateGroup(id: 'craving_early', responses: [
          '身体在适应新的状态，这些反应是真实的。你现在具体是什么感觉？'
              '能描述一下吗？',
          '前几天身体会有一些反应。你现在最不好受的是什么？',
          '这种感觉一定不好受。你之前经历过类似的情况吗？'
              '那时候你是怎么度过的？',
        ]),
        'default': CoachTemplateGroup(id: 'craving_default', responses: [
          '渴望来了。你现在能感觉到它有多强吗？'
              '在0到10之间，你会怎么打分？',
          '这种渴望——你觉得它更像是一种身体的反应，还是心里的某个声音？',
          '在你经历这种渴望之前，发生了什么？'
              '你在做什么，或者脑子里在想什么？',
          '渴望有时候像海浪，来了又走了。你以前注意过它持续多久吗？',
        ]),
      },
      quickReplies: ['大概有7分', '是心里的声音', '刚才跟人吵架了', '感觉快过去了'],
    ),

    // ── Emotion（重写 v6.1：去掉建议，改为共情+开放式提问）──
    CoachTopicHandler(
      id: 'emotion',
      keywords: ['心情', '难过', '开心', '焦虑', '压力', '烦躁', '生气', '情绪',
                 '沮丧', '孤独', '低落', '崩溃', '抑郁', '害怕', '恐惧'],
      subKeywords: {
        'negative': ['焦虑', '压力', '烦躁', '生气', '难过', '沮丧', '孤独', '低落', '崩溃', '抑郁', '害怕', '恐惧'],
        'positive': ['开心', '高兴', '不错', '挺好'],
      },
      responses: {
        'negative': CoachTemplateGroup(id: 'emotion_negative', responses: [
          '听起来你现在承受了不少。这种感受持续多久了？'
              '是什么时候开始的？',
          '你说的这些，听起来真的很不容易。'
              '在这之前，发生了什么让你有这种感觉的事吗？',
          '我在听。你现在最想跟我说的是哪部分？',
          '这种时候，你通常会怎么做？以前什么方式对你来说是有效的？',
        ]),
        'positive': CoachTemplateGroup(id: 'emotion_positive', responses: [
          '听起来今天还不错。是什么让你有这种感觉的？',
          '能感受到你心情好了一些——你觉得是什么带来了这个变化？',
          '嗯，这个状态挺好的。你今天做了什么跟往常不一样的事吗？',
        ]),
        'default': CoachTemplateGroup(id: 'emotion_default', responses: [
          '你提到情绪这个词——你现在能具体说说是什么感受吗？',
          '关注自己的情绪其实挺不容易的。你现在最想表达的是什么？',
          '嗯，我在听。你觉得这个情绪和你今天经历的什么事有关吗？',
        ]),
      },
      quickReplies: ['持续好几天了', '刚才发生了一件事', '不知道怎么说', '就是觉得累'],
    ),

    // ── Weight Concern（重写 v6.1：去掉建议列表）──
    CoachTopicHandler(
      id: 'weight',
      keywords: ['体重', '胖', '吃', '食欲', '嘴馋', '长胖'],
      responses: {
        'default': CoachTemplateGroup(id: 'weight_default', responses: [
          '身体在变化，你注意到了这一点。这让你感到困扰吗？',
          '味觉和食欲的变化是真实的。你现在最担心的是什么？',
          '很多人都会经历这个阶段。你觉得自己现在吃的跟以前比有什么不同？',
        ]),
      },
      quickReplies: ['确实胖了', '总想吃东西', '还好吧', '说不清'],
    ),

    // ── Relapse（重写 v6.1：去掉分析指导，改为好奇+接纳）──
    CoachTopicHandler(
      id: 'relapse',
      keywords: ['失败', '复吸', '破戒', '抽了', '喝了', '没忍住', '后悔',
                 '又喝了', '又抽了', '控制不住', '倒退了'],
      responses: {
        'default': CoachTemplateGroup(id: 'relapse_default', responses: [
          '你愿意告诉我这些，说明你在面对。'
              '发生了什么？当时是什么情况？',
          '这很常见。你不用急着给自己下定义。'
              '你能跟我说说那一刻你内心经历了什么吗？',
          '谢谢你跟我说实话。在那个时刻之前，你经历了什么？'
              '是什么让你走到了那一步？',
          '听到了。你现在有什么感受？'
              '除了后悔之外，还有别的吗？',
        ]),
      },
      quickReplies: ['当时压力很大', '朋友递过来的', '自己也说不清', '不想聊这个'],
    ),

    // ── Social Pressure（重写 v6.1：去掉话术建议，改为探索）──
    CoachTopicHandler(
      id: 'social',
      keywords: ['朋友', '社交', '聚会', '同事', '别人', '嘲笑', '面子',
                 '敬酒', '递烟', '劝酒'],
      responses: {
        'default': CoachTemplateGroup(id: 'social_default', responses: [
          '社交场合有时候确实让人不太好办。你遇到的具体是什么情况？',
          '在你朋友面前，你觉得他们理解你的处境吗？'
              '还是说你觉得不太方便跟他们聊这个？',
          '这种时候你会怎么做？你之前有遇到过类似的情况吗？',
          '在社交中感到有压力是正常的。你最担心的是什么？'
              '是被拒绝，还是觉得自己"不合群"？',
        ]),
      },
      quickReplies: ['他们不理解', '不知道怎么拒绝', '觉得很不自在', '没什么朋友'],
    ),

    // ── Sleep Issue（重写 v6.1：去掉建议列表）──
    CoachTopicHandler(
      id: 'sleep',
      keywords: ['睡觉', '失眠', '睡眠', '睡不好', '累', '疲劳', '睡不着',
                 '半夜醒', '做噩梦'],
      responses: {
        'default': CoachTemplateGroup(id: 'sleep_default', responses: [
          '睡不好真的很折磨人。这种状况持续多久了？',
          '身体在适应，睡眠可能会受到一些影响。你晚上通常是什么时候开始翻来覆去的？',
          '失眠的时候，你脑子里一般在想什么？',
          '你之前有过睡不好的时候吗？那时候你找到了什么让自己放松的方式？',
        ]),
      },
      quickReplies: ['已经好几天了', '脑子里停不下来', '半夜总是醒', '白天太累了'],
    ),

    // ── Help Request（重写 v6.1：先了解再回应）──
    CoachTopicHandler(
      id: 'help',
      keywords: ['帮助', '怎么办', '方法', '技巧', '怎么', '建议', '有什么用'],
      responses: {
        'day_0': CoachTemplateGroup(id: 'help_day_0', responses: [
          '你在寻找一些方向。在你之前的经历中，有没有什么方法是让你觉得'
              '"这个可能对我有用"的？哪怕只是一点点。',
          '每个人找到适合自己的方式都不一样。你之前有没有尝试过什么？'
              '什么让你觉得有效，什么让你觉得没用？',
        ]),
        'default': CoachTemplateGroup(id: 'help_default', responses: [
          '你想找到一些对自己有效的方式。你之前试过什么？'
              '什么让你觉得可能有用，什么让你觉得不太对？',
          '你现在最想解决的是哪个方面的问题？'
              '是身体上的不适，还是心里的某个坎？',
        ]),
      },
      quickReplies: ['之前试过但没坚持', '不知道从哪开始', '身体不舒服', '心里很矛盾'],
    ),

    // ── Success / Achievement（重写 v6.1：肯定具体行为而非泛泛鼓励）──
    CoachTopicHandler(
      id: 'success',
      keywords: ['坚持', '做到了', '成功了', '太棒', '很好', '不错', '忍住了',
                 '没抽', '没喝', '挺过来了'],
      responses: {
        'default': CoachTemplateGroup(id: 'success_default', responses: [
          '你是怎么做到的？当时是什么让你选择了不去做？'
              '你心里的那个声音说了什么？',
          '你刚才说的这件事——你自己觉得是什么力量让你挺过来的？',
          '嗯，这不容易。你今天做的这个选择，你自己怎么看？',
        ]),
      },
      quickReplies: ['就是不想输', '想到了女儿', '没什么特别的', '说实话有点难'],
    ),

    // ── Progress / Stats ──
    CoachTopicHandler(
      id: 'progress',
      keywords: ['进展', '数据', '统计', '记录', '报告'],
      responses: {
        'no_profile': CoachTemplateGroup(id: 'progress_no_profile', responses: [
          '你还没有开始记录。不过没关系——你今天来了，这就是开始。',
        ]),
        'default': CoachTemplateGroup(id: 'progress_default', responses: [
          '让我给你看看你的记录：\n\n'
              '连续 {streak} 天\n'
              '戒断 {days} 天\n'
              '成功抵抗渴望 {cravings_resisted} 次\n'
              '最长连续 {longest_streak} 天\n\n'
              '看到这些数据，你心里是什么感觉？',
        ]),
      },
      quickReplies: ['没想到坚持了这么久', '感觉还行', '中间失败过', '数据不重要'],
    ),

    // ── Greeting (user says hello) ──
    CoachTopicHandler(
      id: 'greeting_input',
      keywords: ['你好', '嗨', 'hi', 'hello', '在吗', '嘿'],
      responses: {
        'default': CoachTemplateGroup(id: 'greeting_input_default', responses: [
          '我在。你今天过得怎么样？',
          '嘿，你来了。有什么想聊的吗？',
          '{time_greeting}！今天有什么想说的吗？',
        ]),
      },
    ),

    // ── SOS / Emergency ──
    CoachTopicHandler(
      id: 'sos',
      keywords: ['sos', '紧急', '呼吸', '冲浪', '帮帮我', '快不行了'],
      responses: {
        'default': CoachTemplateGroup(id: 'sos_default', responses: [
          '现在这种感觉一定很难受。先停下来，什么都不做。'
              '跟我一起做：吸气……屏住……呼气……你愿意试试吗？',
          '我在这里陪着你。这种渴望再强烈，它也终会过去。'
              '你现在能跟我描述一下你身体的感受吗？',
        ]),
      },
    ),

    // ── General / Catch-all (matched last by the engine) ──
    CoachTopicHandler(
      id: 'general',
      keywords: [], // empty keywords → engine uses as fallback
      responses: {
        'default': CoachTemplateGroup(id: 'general_default', responses: [
          '嗯，我在听。你能再多说一点吗？',
          '你刚才说的让我想到了一些东西。你觉得这件事对你来说意味着什么？',
          '每个人都有自己的节奏和故事。你今天想聊的，是关于什么？',
          '我听到了。有时候把心里的话说出来本身就有帮助。你还有什么想说的吗？',
        ]),
      },
    ),
  ];

  // ── Quick Reply Templates ──────────────────────────────────────────────────

  /// Quick replies shown with the initial greeting (before any user input).
  /// v6.1: 更偏向倾听式，增加"无意愿"选项
  static const initialQuickReplies = <String>[
    '今天感觉不太好',
    '我今天喝了/抽了',
    '坚持得还行',
    '我有点矛盾',
    '我不想戒',
  ];

  /// Topic-keyed quick replies used after a handler fires.
  static const quickRepliesByTopic = <String, List<String>>{
    'resistance': ['我今天很累', '说说别的吧', '我想自己待着', '刚才有点冲动'],
    'values':    ['是很重要', '没想过', '有点矛盾', '说不清'],
    'craving':   ['大概有7分', '是心里的声音', '刚才跟人吵架了', '感觉快过去了'],
    'emotion':   ['持续好几天了', '刚才发生了一件事', '不知道怎么说', '就是觉得累'],
    'relapse':   ['当时压力很大', '朋友递过来的', '自己也说不清', '不想聊这个'],
    'social':    ['他们不理解', '不知道怎么拒绝', '觉得很不自在', '没什么朋友'],
    'sleep':     ['已经好几天了', '脑子里停不下来', '半夜总是醒', '白天太累了'],
    'help':      ['之前试过但没坚持', '不知道从哪开始', '身体不舒服', '心里很矛盾'],
    'success':   ['就是不想输', '想到了女儿', '没什么特别的', '说实话有点难'],
    'progress':  ['没想到坚持了这么久', '感觉还行', '中间失败过', '数据不重要'],
    'sos':       ['我呼吸一下', '太难受了', '帮帮我', '我想转移注意力'],
  };

  /// Fallback quick replies when no topic-specific set matches.
  static const defaultQuickReplies = <List<String>>[
    ['今天有点难熬', '有点矛盾', '什么都不想说', '就是来看看'],
    ['刚才发生了一件事', '感觉还好', '有点累', '聊聊别的'],
  ];

  // ── Utility ──────────────────────────────────────────────────────────────────

  static String randomFrom(List<String> options) {
    return options[Random().nextInt(options.length)];
  }
}