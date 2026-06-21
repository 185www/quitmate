import 'dart:math';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/coach_message.dart';

/// Generates personalized, empathetic coaching responses based on user context.
///
/// v6.1 重构：从"教练建议"模式重塑为"动机访谈倾听"模式。
///
/// Uses a rule-based expert system with:
/// - Motivational interviewing (MI) OARS techniques as the core approach
/// - "Resistance first" matching — acceptance before anything else
/// - Values detection — Socratic questioning to surface inner conflict
/// - Zero direct advice — all responses are empathic reflections + open questions
/// - TTM (Transtheoretical Model) stage-aware but never prescriptive
class AiCoachEngine {
  // ---- Public API ----

  /// Generate a contextual opening message based on user state.
  CoachMessage generateGreeting({
    User? user,
    GameProfile? gameProfile,
    DailyLogEntry? todayLog,
  }) {
    final text = _buildGreetingText(user, gameProfile, todayLog);
    return CoachMessage(
      id: CoachMessage.generateId(),
      isUser: false,
      text: text,
      timestamp: DateTime.now(),
      category: 'greeting',
      quickReplies: _initialQuickReplies(),
    );
  }

  /// Generate a response to user input.
  CoachMessage generateResponse({
    required String userInput,
    User? user,
    GameProfile? gameProfile,
    DailyLogEntry? todayLog,
  }) {
    final text = _buildResponseText(userInput, user, gameProfile);
    final category = _categorizeResponse(text);
    final replies = _contextualQuickReplies(userInput, text);
    return CoachMessage(
      id: CoachMessage.generateId(),
      isUser: false,
      text: text,
      timestamp: DateTime.now(),
      category: category,
      quickReplies: replies,
    );
  }

  // ---- Greeting Generation ----

  String _buildGreetingText(
      User? user, GameProfile? gameProfile, DailyLogEntry? todayLog) {
    if (user == null || !user.hasQuitDate) {
      return _randomFrom([
        '你好，我在这里。今天想聊点什么吗？',
        '欢迎回来。有什么想说的吗？随时都可以。',
        '嘿，你来了。今天过得怎么样？',
      ]);
    }

    final days = user.daysSinceQuit;
    final streak = gameProfile?.streakDays ?? 0;

    if (days == 0) {
      return _randomFrom([
        '第一天。不管你是怎么来到这里的，能迈出这一步本身就不容易。今天有什么感受吗？',
        '你做了一个决定。不管结果怎样，我想听听你的想法——是什么让你今天想要做这个尝试？',
        '${_timeGreeting()}！今天对你来说可能是个特别的日子。你现在心里是什么感觉？',
      ]);
    }

    if (days <= 3) {
      return _randomFrom([
        '第$days天了。身体在适应新的节奏，这并不容易。你现在感觉怎么样？',
        '${_timeGreeting()}！$days天了。这个阶段身体会有一些反应——你有没有注意到什么变化？',
        '前几天往往是最不适应的。你今天经历了什么？想聊聊吗？',
      ]);
    }

    if (days <= 7) {
      return _randomFrom([
        '快一周了。回想这$days天，你觉得自己有什么变化吗？哪怕很小的。',
        '${_timeGreeting()}，连续$streak天了。这周你最想跟我聊的一件事是什么？',
        '一周是个小节点。你心里现在是什么感觉？跟第一天比呢？',
      ]);
    }

    if (days <= 30) {
      return _randomFrom([
        '${_timeGreeting()}！$days天了。这个阶段，心理上的习惯可能是更大的课题。你最近有没有什么发现？',
        '$days天——你对自己有什么新的认识吗？',
        '快一个月了。如果你愿意，可以跟我聊聊这段时间对你来说意味着什么。',
      ]);
    }

    if (days <= 90) {
      return _randomFrom([
        '${_timeGreeting()}，$days天。你已经走了很远。回过头看，你觉得自己最大的变化是什么？',
        '$streak天的连续记录。你有没有发现生活中有什么不一样了？',
        '$days天了。如果你现在能对第一天时的自己说一句话，你会说什么？',
      ]);
    }

    return _randomFrom([
      '${_timeGreeting()}！$days天，你已经在走一条很不一样的路了。最近有什么新的感悟吗？',
      '$streak天了。你现在对以前那个习惯有什么感觉？',
      '$days天的旅程。你今天有什么想分享的吗？',
    ]);
  }

  // ---- Response Generation ----
  //
  // v6.1 关键变更：匹配顺序调整，resistance 和 values 优先于 craving。

  String _buildResponseText(
      String userInput, User? user, GameProfile? gameProfile) {
    final input = userInput.toLowerCase();
    final days = user?.daysSinceQuit ?? 0;

    // 1. 抗拒检测（最高优先级）
    if (_containsAny(input, [
      '不想戒', '别烦我', '别说了', '我就想喝', '我就想抽', '不想改',
      '不可能', '做不到', '算了', '不管了', '无所谓', '你不懂',
      '少说教', '别劝我', '我的事', '别管我', '烦死了',
    ])) {
      return _handleResistance();
    }

    // 2. 价值观线索检测
    if (_containsAny(input, [
      '女儿', '儿子', '孩子', '老婆', '老公', '爸妈', '妈妈', '爸爸',
      '家人', '家庭', '父母', '宝宝', '工作', '事业', '升职',
      '梦想', '未来', '身体', '健康', '长寿',
    ])) {
      return _handleValues(input);
    }

    // 3. 渴望
    if (_containsAny(input, ['渴', '想抽', '想喝', '忍不住', '好难', '难受', '戒断', '痛苦'])) {
      return _handleCraving(input, days);
    }

    // 4. 情绪
    if (_containsAny(input, ['心情', '难过', '开心', '焦虑', '压力', '烦躁', '生气', '情绪',
        '沮丧', '孤独', '低落', '崩溃', '抑郁', '害怕', '恐惧'])) {
      return _handleEmotion(input);
    }

    // 5. 体重
    if (_containsAny(input, ['体重', '胖', '吃', '食欲', '嘴馋'])) {
      return _handleWeightConcern();
    }

    // 6. 复发
    if (_containsAny(input, ['失败', '复吸', '破戒', '抽了', '喝了', '没忍住', '后悔'])) {
      return _handleRelapse();
    }

    // 7. 社交
    if (_containsAny(input, ['朋友', '社交', '聚会', '同事', '别人', '嘲笑', '面子'])) {
      return _handleSocialPressure();
    }

    // 8. 睡眠
    if (_containsAny(input, ['睡觉', '失眠', '睡眠', '睡不好', '累', '疲劳'])) {
      return _handleSleepIssue();
    }

    // 9. 求助
    if (_containsAny(input, ['帮助', '怎么办', '方法', '技巧', '怎么', '建议'])) {
      return _handleHelpRequest();
    }

    // 10. 成功
    if (_containsAny(input, ['坚持', '做到了', '成功了', '太棒', '很好', '不错'])) {
      return _handleSuccess();
    }

    // 11. 进展
    if (_containsAny(input, ['进展', '数据', '统计', '记录', '报告'])) {
      return _handleProgress(days, gameProfile);
    }

    // 12. 打招呼
    if (_containsAny(input, ['你好', '嗨', 'hi', 'hello', '在吗'])) {
      return _randomFrom([
        '我在。你今天过得怎么样？',
        '嘿，你来了。有什么想聊的吗？',
        '${_timeGreeting()}！今天有什么想说的吗？',
      ]);
    }

    // 13. SOS
    if (_containsAny(input, ['sos', '紧急', '呼吸', '冲浪'])) {
      return _handleSosRequest();
    }

    // Default: open-ended reflection
    return _handleGeneralReflection();
  }

  // ---- Handler Methods (v6.1: all rewritten) ----

  /// 新增 v6.1：处理用户抗拒——接纳+顺从，卸下心理防御
  String _handleResistance() {
    return _randomFrom([
      '我完全理解。这是你的人生，你当然有权利做自己的选择。'
          '我只是在这里，如果你想聊，随时可以。',
      '听到了。我不会再说这个话题。'
          '你想聊点别的吗？或者只是安静待一会儿也行。',
      '你说得对，这是你的选择。我尊重。'
          '如果哪天你想找人聊聊，我在这里。',
      '我没有任何要说服你的意思。你今天愿意打开这个App，就已经够了。',
    ]);
  }

  /// 新增 v6.1：检测价值观线索，苏格拉底式提问
  String _handleValues(String input) {
    final keyword = _extractMatchedKeyword(input, [
      '女儿', '儿子', '孩子', '老婆', '老公', '爸妈', '妈妈', '爸爸',
      '家人', '家庭', '父母', '宝宝', '工作', '事业', '升职',
      '梦想', '未来', '身体', '健康', '长寿',
    ]);

    if (keyword != null) {
      return _randomFrom([
        '你刚才提到了$keyword——听起来这对你来说很重要。'
            '在你目前的生活中，这个和你的日常习惯之间有什么关系吗？',
        '$keyword……你提到这个的时候，语气好像有些不一样。'
            '这个对你意味着什么？',
        '我注意到你很在意$keyword。'
            '如果你闭上眼睛想象五年后的自己，你希望那时候的$keyword是什么样的？',
      ]);
    }

    return '你说的这些对你来说一定很重要。能多聊聊吗？';
  }

  /// v6.1 重写：去掉直接建议，改为共情反射+打分提问
  String _handleCraving(String input, int days) {
    if (days <= 3) {
      return _randomFrom([
        '身体在适应新的状态，这些反应是真实的。你现在具体是什么感觉？'
            '能描述一下吗？',
        '前几天身体会有一些反应。你现在最不好受的是什么？',
        '这种感觉一定不好受。你之前经历过类似的情况吗？'
            '那时候你是怎么度过的？',
      ]);
    }
    return _randomFrom([
      '渴望来了。你现在能感觉到它有多强吗？'
          '在0到10之间，你会怎么打分？',
      '这种渴望——你觉得它更像是一种身体的反应，还是心里的某个声音？',
      '在你经历这种渴望之前，发生了什么？'
          '你在做什么，或者脑子里在想什么？',
      '渴望有时候像海浪，来了又走了。你以前注意过它持续多久吗？',
    ]);
  }

  /// v6.1 重写：去掉建议，分为消极/积极/默认三路
  String _handleEmotion(String input) {
    if (_containsAny(input, ['焦虑', '压力', '烦躁', '生气', '难过', '沮丧', '孤独', '低落', '崩溃', '抑郁', '害怕', '恐惧'])) {
      return _randomFrom([
        '听起来你现在承受了不少。这种感受持续多久了？'
            '是什么时候开始的？',
        '你说的这些，听起来真的很不容易。'
            '在这之前，发生了什么让你有这种感觉的事吗？',
        '我在听。你现在最想跟我说的是哪部分？',
        '这种时候，你通常会怎么做？以前什么方式对你来说是有效的？',
      ]);
    }
    if (_containsAny(input, ['开心', '高兴', '不错', '挺好'])) {
      return _randomFrom([
        '听起来今天还不错。是什么让你有这种感觉的？',
        '能感受到你心情好了一些——你觉得是什么带来了这个变化？',
        '嗯，这个状态挺好的。你今天做了什么跟往常不一样的事吗？',
      ]);
    }
    return _randomFrom([
      '你提到情绪这个词——你现在能具体说说是什么感受吗？',
      '关注自己的情绪其实挺不容易的。你现在最想表达的是什么？',
      '嗯，我在听。你觉得这个情绪和你今天经历的什么事有关吗？',
    ]);
  }

  /// v6.1 重写：去掉建议列表，改为探索
  String _handleWeightConcern() {
    return _randomFrom([
      '身体在变化，你注意到了这一点。这让你感到困扰吗？',
      '味觉和食欲的变化是真实的。你现在最担心的是什么？',
      '很多人都会经历这个阶段。你觉得自己现在吃的跟以前比有什么不同？',
    ]);
  }

  /// v6.1 重写：去掉分析指导，改为好奇+接纳
  String _handleRelapse() {
    return _randomFrom([
      '你愿意告诉我这些，说明你在面对。'
          '发生了什么？当时是什么情况？',
      '这很常见。你不用急着给自己下定义。'
          '你能跟我说说那一刻你内心经历了什么吗？',
      '谢谢你跟我说实话。在那个时刻之前，你经历了什么？'
          '是什么让你走到了那一步？',
      '听到了。你现在有什么感受？'
          '除了后悔之外，还有别的吗？',
    ]);
  }

  /// v6.1 重写：去掉拒绝话术，改为探索社交感受
  String _handleSocialPressure() {
    return _randomFrom([
      '社交场合有时候确实让人不太好办。你遇到的具体是什么情况？',
      '在你朋友面前，你觉得他们理解你的处境吗？'
          '还是说你觉得不太方便跟他们聊这个？',
      '这种时候你会怎么做？你之前有遇到过类似的情况吗？',
      '在社交中感到有压力是正常的。你最担心的是什么？'
          '是被拒绝，还是觉得自己"不合群"？',
    ]);
  }

  /// v6.1 重写：去掉建议列表，改为开放式提问
  String _handleSleepIssue() {
    return _randomFrom([
      '睡不好真的很折磨人。这种状况持续多久了？',
      '身体在适应，睡眠可能会受到一些影响。你晚上通常是什么时候开始翻来覆去的？',
      '失眠的时候，你脑子里一般在想什么？',
      '你之前有过睡不好的时候吗？那时候你找到了什么让自己放松的方式？',
    ]);
  }

  /// v6.1 重写：先了解再回应，不直接给建议
  String _handleHelpRequest() {
    return _randomFrom([
      '你想找到一些对自己有效的方式。你之前试过什么？'
          '什么让你觉得可能有用，什么让你觉得不太对？',
      '你现在最想解决的是哪个方面的问题？'
          '是身体上的不适，还是心里的某个坎？',
      '每个人找到适合自己的方式都不一样。'
          '你之前有没有什么时刻觉得自己"好像有点靠谱"的？',
    ]);
  }

  /// v6.1 重写：肯定具体行为，问"你是怎么做到的"
  String _handleSuccess() {
    return _randomFrom([
      '你是怎么做到的？当时是什么让你选择了不去做？'
          '你心里的那个声音说了什么？',
      '你刚才说的这件事——你自己觉得是什么力量让你挺过来的？',
      '嗯，这不容易。你今天做的这个选择，你自己怎么看？',
    ]);
  }

  String _handleProgress(int days, GameProfile? profile) {
    if (profile == null) {
      return '你还没有开始记录。不过没关系——你今天来了，这就是开始。';
    }
    final streak = profile.streakDays;
    final cravingsResisted = profile.cravingsResisted;
    return '让我给你看看你的记录：\n\n'
        '连续 $streak 天\n'
        '戒断 $days 天\n'
        '成功抵抗渴望 $cravingsResisted 次\n'
        '最长连续 ${profile.longestStreak} 天\n\n'
        '看到这些数据，你心里是什么感觉？';
  }

  String _handleSosRequest() {
    return _randomFrom([
      '现在这种感觉一定很难受。先停下来，什么都不做。'
          '跟我一起做：吸气……屏住……呼气……你愿意试试吗？',
      '我在这里陪着你。这种渴望再强烈，它也终会过去。'
          '你现在能跟我描述一下你身体的感受吗？',
    ]);
  }

  String _handleGeneralReflection() {
    return _randomFrom([
      '嗯，我在听。你能再多说一点吗？',
      '你刚才说的让我想到了一些东西。你觉得这件事对你来说意味着什么？',
      '每个人都有自己的节奏和故事。你今天想聊的，是关于什么？',
      '我听到了。有时候把心里的话说出来本身就有帮助。你还有什么想说的吗？',
    ]);
  }

  // ---- Quick Reply Generation ----

  List<String> _initialQuickReplies() {
    return ['今天感觉不太好', '我今天喝了/抽了', '坚持得还行', '我有点矛盾', '我不想戒'];
  }

  List<String> _contextualQuickReplies(String userInput, String response) {
    final input = userInput.toLowerCase();

    // After resistance
    if (_containsAny(input, ['不想戒', '别烦我', '别说了', '我就想喝', '不想改', '无所谓', '烦死了'])) {
      return ['我今天很累', '说说别的吧', '我想自己待着', '刚才有点冲动'];
    }

    // After values discussion
    if (_containsAny(input, ['女儿', '儿子', '孩子', '老婆', '家人', '工作', '健康'])) {
      return ['是很重要', '没想过', '有点矛盾', '说不清'];
    }

    // After craving
    if (_containsAny(input, ['渴', '想抽', '想喝', '忍不住', '难受'])) {
      return ['大概有7分', '是心里的声音', '刚才跟人吵架了', '感觉快过去了'];
    }

    // After emotion
    if (_containsAny(input, ['心情', '焦虑', '压力', '烦躁', '难过', '孤独'])) {
      return ['持续好几天了', '刚才发生了一件事', '不知道怎么说', '就是觉得累'];
    }

    // After relapse
    if (_containsAny(input, ['失败', '复吸', '破戒', '抽了', '喝了', '没忍住'])) {
      return ['当时压力很大', '朋友递过来的', '自己也说不清', '不想聊这个'];
    }

    // After social
    if (_containsAny(input, ['朋友', '社交', '聚会', '同事'])) {
      return ['他们不理解', '不知道怎么拒绝', '觉得很不自在', '没什么朋友'];
    }

    // After sleep
    if (_containsAny(input, ['睡觉', '失眠', '睡眠', '累'])) {
      return ['已经好几天了', '脑子里停不下来', '半夜总是醒', '白天太累了'];
    }

    // After help
    if (_containsAny(input, ['帮助', '怎么办', '方法', '建议'])) {
      return ['之前试过但没坚持', '不知道从哪开始', '身体不舒服', '心里很矛盾'];
    }

    // After success
    if (_containsAny(input, ['坚持', '做到了', '成功', '太棒'])) {
      return ['就是不想输', '想到了女儿', '没什么特别的', '说实话有点难'];
    }

    // After progress
    if (_containsAny(input, ['进展', '数据', '统计', '记录'])) {
      return ['没想到坚持了这么久', '感觉还行', '中间失败过', '数据不重要'];
    }

    // Default
    final options = [
      ['今天有点难熬', '有点矛盾', '什么都不想说', '就是来看看'],
      ['刚才发生了一件事', '感觉还好', '有点累', '聊聊别的'],
    ];
    return options[Random().nextInt(options.length)];
  }

  // ---- Category Detection ----

  String? _categorizeResponse(String response) {
    if (response.contains('？')) return 'question';
    if (response.contains('?')) return 'question';
    // v6.1: reflection is now the dominant category
    return 'reflection';
  }

  // ---- Utilities ----

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  String _randomFrom(List<String> options) {
    return options[Random().nextInt(options.length)];
  }

  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k));
  }

  /// Extract the first matched keyword from input for use in responses.
  String? _extractMatchedKeyword(String input, List<String> keywords) {
    for (final k in keywords) {
      if (input.contains(k)) return k;
    }
    return null;
  }
}