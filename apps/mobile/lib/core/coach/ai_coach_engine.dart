import 'dart:math';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/coach_message.dart';

/// Generates personalized, empathetic coaching responses based on user context.
///
/// Uses a rule-based expert system with:
/// - Context-aware response generation based on user's stage, days quit, mood, craving patterns
/// - Motivational interviewing (MI) techniques (OARS: Open questions, Affirmations, Reflections, Summaries)
/// - TTM (Transtheoretical Model) stage-matched interventions
/// - Personalized insights from user's actual data (streak, cravings, triggers)
class AiCoachEngine {
  // ---- Public API ----

  /// Generate a contextual opening message based on user state
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

  /// Generate a response to user input
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

  String _buildGreetingText(User? user, GameProfile? gameProfile, DailyLogEntry? todayLog) {
    if (user == null || !user.hasQuitDate) {
      return _randomFrom([
        '你好！我是你的戒烟教练。今天想聊聊什么？',
        '欢迎回来！有什么我能帮你的吗？',
        '准备好开始了吗？我们可以聊聊你的计划。',
      ]);
    }

    final days = user.daysSinceQuit;
    final streak = gameProfile?.streakDays ?? 0;
    final level = gameProfile?.levelTitle ?? '';

    if (days == 0) {
      return _randomFrom([
        '今天是你的第一天，这是最重要的一天。感觉怎么样？',
        '你做出了一个很棒的决定！第一天通常最难，但你知道为什么而战。',
        '${_timeGreeting()}！今天是你戒断的第一天。有什么让你焦虑的吗？',
      ]);
    }

    if (days <= 3) {
      return _randomFrom([
        '第$days天了，最难熬的阶段。你的身体正在适应，有什么不舒服的感觉吗？',
        '${_timeGreeting()}！你已经坚持了$days天了。让我知道你现在的感受。',
        '前三天是身体戒断反应最强的时候。你现在感觉怎么样？',
      ]);
    }

    if (days <= 7) {
      return _randomFrom([
        '一周快到了！身体的修复已经开始了。最近有什么挑战吗？',
        '${_timeGreeting()}，$level！连续$streak天打卡，真了不起。今天有什么想聊的？',
        '第一个里程碑近在咫尺。聊聊这周的经历吧？',
      ]);
    }

    if (days <= 30) {
      return _randomFrom([
        '${_timeGreeting()}！$level，你已经坚持了$days天。这个阶段，心理习惯是最大的挑战。',
        '$days天！你的意志力让我印象深刻。最近有什么触发了你的渴望吗？',
        '一个月快到了。你现在对戒断有什么新的认识吗？',
      ]);
    }

    if (days <= 90) {
      return _randomFrom([
        '${_timeGreeting()}，$level！$days天的坚持，你已经重塑了很多习惯。',
        '$level级别，连续$streak天！你有什么经验想分享吗？',
        '$days天了，你的恢复程度已经很显著。让我知道你最近的状态。',
      ]);
    }

    return _randomFrom([
      '${_timeGreeting()}，$level！$days天，你已经是真正的$level了。',
      '你保持着$streak天的连续打卡记录。有什么新的感悟吗？',
      '$days天的旅程！你现在对以前的习惯有什么看法？',
    ]);
  }

  // ---- Response Generation ----

  String _buildResponseText(String userInput, User? user, GameProfile? gameProfile) {
    final input = userInput.toLowerCase();
    final days = user?.daysSinceQuit ?? 0;
    final stage = user?.stage ?? UserStage.preContemplation;

    if (_containsAny(input, ['渴', '想抽', '想喝', '忍不住', '好难', '难受', '戒断', '痛苦'])) {
      return _handleCraving(input, days, stage);
    }
    if (_containsAny(input, ['心情', '难过', '开心', '焦虑', '压力', '烦躁', '生气', '情绪'])) {
      return _handleEmotion(input, days);
    }
    if (_containsAny(input, ['体重', '胖', '吃', '食欲', '嘴馋'])) {
      return _handleWeightConcern(days);
    }
    if (_containsAny(input, ['失败', '复吸', '破戒', '抽了', '喝了', '没忍住', '后悔'])) {
      return _handleRelapse(days, stage);
    }
    if (_containsAny(input, ['朋友', '社交', '聚会', '同事', '别人', '嘲笑'])) {
      return _handleSocialPressure(days);
    }
    if (_containsAny(input, ['睡觉', '失眠', '睡眠', '睡不好', '累', '疲劳'])) {
      return _handleSleepIssue(days);
    }
    if (_containsAny(input, ['帮助', '怎么办', '方法', '技巧', '怎么', '建议'])) {
      return _handleHelpRequest(days, stage);
    }
    if (_containsAny(input, ['坚持', '做到了', '成功了', '太棒', '很好', '不错'])) {
      return _handleSuccess(days, gameProfile);
    }
    if (_containsAny(input, ['进展', '数据', '统计', '记录', '报告'])) {
      return _handleProgress(days, gameProfile);
    }
    if (_containsAny(input, ['你好', '嗨', 'hi', 'hello', '在吗'])) {
      return _randomFrom([
        '我在的！随时可以跟我聊。你今天感觉怎么样？',
        '你好！有什么想聊的吗？',
        '${_timeGreeting()}！有什么我可以帮你的吗？',
      ]);
    }
    if (_containsAny(input, ['sos', '紧急', '呼吸', '冲浪'])) {
      return _handleSosRequest();
    }

    // Default: motivational interviewing reflection
    return _handleGeneralReflection(input, days);
  }

  // ---- Handler Methods ----

  String _handleCraving(String input, int days, UserStage stage) {
    if (days <= 3) {
      return _randomFrom([
        '前几天的渴望是最正常的生理反应。你知道吗，大多数渴望在3-5分钟内就会消退。'
            '试试按下SOS按钮，跟随呼吸练习，等待它过去。你现在就在做这个，很棒。',
        '你正在经历的身体反应说明你的身体正在恢复。渴望是暂时的，但你的进步是永久的。'
            '你现在最需要的是什么？',
      ]);
    }
    return _randomFrom([
      '渴望像海浪——它会升起，达到峰值，然后自然消退。你现在感受到的这个渴望，'
          '大概率会在5分钟内减弱。你之前成功抵抗过多少次了？你已经证明过自己了。',
      '能跟我说说是什么触发了这个渴望吗？了解触发因素是管理它们的第一步。'
          '是某个场景、情绪，还是习惯性的时间？',
      '记住HALT原则：你是否Hungry(饿)、Angry(生气)、Lonely(孤独)、Tired(累)？'
          '很多渴望实际上来自这些基本需求。先检查一下这些。',
    ]);
  }

  String _handleEmotion(String input, int days) {
    if (_containsAny(input, ['焦虑', '压力', '烦躁', '生气'])) {
      return _randomFrom([
        '情绪波动在戒断过程中很常见。你的大脑正在重新学习如何处理压力，'
            '不再依赖那个"快速解决方法"。这个过程需要时间，但你的大脑适应能力很强。\n\n'
            '现在试试这个：闭上眼睛，做3次深呼吸。把注意力放在呼吸的感觉上。'
            '这个简单的练习可以激活你的副交感神经系统，帮助降低焦虑。',
        '压力和烦躁是戒断最常见的挑战之一。很多人用抽烟/喝酒来应对压力，'
            '现在你需要新的工具。\n\n'
            '试试"行动"标签里的技能训练，里面有经过科学验证的压力管理技巧。'
            '你今天想试试哪个？',
      ]);
    }
    if (_containsAny(input, ['难过', '低落', '抑郁'])) {
      return _randomFrom([
        '戒断期间情绪低落是正常的——你的大脑正在调整多巴胺水平。这通常是暂时的。\n\n'
            '建议你：保持社交联系，做些让自己开心的小事，适度运动。'
            '如果持续超过两周，建议寻求专业帮助。',
        '我理解你的感受。戒断旅程中情绪起伏是预料之中的。'
            '重要的是不要孤立自己——跟信任的人聊聊你的感受。\n\n'
            '你现在有什么让你特别难过的事情吗？',
      ]);
    }
    return _randomFrom([
      '情绪变化是戒断过程中正常的部分。你的大脑化学正在重新平衡。'
          '能具体说说你现在的感受吗？',
      '关注自己的情绪其实是件好事——这说明你在用心体验自己的感受。'
          '你觉得这个情绪和渴望有关系吗？',
    ]);
  }

  String _handleWeightConcern(int days) {
    return _randomFrom([
      '食欲增加是戒断后的常见反应，因为你的代谢和味觉正在恢复。'
          '好消息是，这通常在几周内稳定下来。\n\n'
          '建议：准备一些低热量的零食（水果、坚果、胡萝卜条），'
          '在渴望来袭时替代。同时，适度运动不仅控制体重，还能减少渴望。',
      '很多人担心这个问题。实际上，戒断后体重的平均增加只有2-3公斤，'
          '而且可以通过简单的生活方式调整来管理。\n\n'
          '喝水、嚼无糖口香糖、运动——这些都是有效的替代策略。'
          '你目前有什么应对方式吗？',
    ]);
  }

  String _handleRelapse(int days, UserStage stage) {
    return _randomFrom([
      '首先，我想让你知道：这完全正常。平均需要6-30次尝试才能成功戒断。'
          '一次复吸不代表失败——它是学习的机会。\n\n'
          '能跟我聊聊发生了什么吗？是什么触发的？你在那一刻的感受是什么？'
          '了解这些可以帮助你制定更好的预防计划。',
      '深呼吸。你不是一个人在面对这个。复吸是戒断旅程中的常见部分，'
          '而不是终点。\n\n'
          '让我们从中学习：什么触发了它？你能提前做些什么来应对类似的情境？'
          '你已经在"维持"标签里有复发预防计划，可能需要更新一下。',
      '你知道吗？每一次尝试，你成功的概率都在增加。'
          '研究显示，从每次复吸中学到东西的人，下一次坚持的时间会更长。\n\n'
          '今天最重要的事情是：不要因为这一次而放弃。明天又是新的一天。'
          '你愿意聊聊发生了什么吗？',
    ]);
  }

  String _handleSocialPressure(int days) {
    return _randomFrom([
      '社交压力是很多人复吸的主要原因之一。这很常见，但你不需要为此感到不好意思。\n\n'
          '你可以准备几句简单的拒绝话术："我最近在健身，戒了"、"医生建议我停一段时间"、'
          '"我试过了，不想再回去了"。\n\n'
          '真正的朋友会尊重你的决定。你有什么具体的社交场景让你担心吗？',
      '这个挑战很多人都会遇到。关键是提前做好心理准备。\n\n'
          '建议你在聚会前设定明确的界限，告诉至少一个朋友你的决定，'
          '让他们支持你。你也可以准备一些替代活动（喝茶、嚼口香糖）。',
    ]);
  }

  String _handleSleepIssue(int days) {
    return _randomFrom([
      '睡眠问题是戒断初期最常见的症状之一，通常在2-4周内改善。'
          '你的身体正在适应没有尼古丁/酒精的状态。\n\n'
          '建议：保持固定的作息时间，睡前避免咖啡因和屏幕，'
          '可以试试"技能训练"里的渐进式放松练习。',
      '睡眠质量下降是暂时的。你的身体正在重新学习自然入睡。\n\n'
          '试试这些方法：\n'
          '1. 每天同一时间起床和睡觉\n'
          '2. 睡前30分钟不看手机\n'
          '3. 卧室保持凉爽和安静\n'
          '4. 试试4-7-8呼吸法：吸气4秒，屏住7秒，呼气8秒',
    ]);
  }

  String _handleHelpRequest(int days, UserStage stage) {
    if (days == 0) {
      return _randomFrom([
        '很高兴你想了解！这里有几个经过科学验证的方法：\n\n'
            '1. 设定明确的戒断日期\n'
            '2. 告诉朋友和家人获得支持\n'
            '3. 识别你的触发因素\n'
            '4. 准备替代行为（口香糖、运动、喝水）\n'
            '5. 使用APP的工具箱（SOS呼吸、冲浪法、CBT练习）\n\n'
            '你现在最想了解哪个方面？',
      ]);
    }
    return _randomFrom([
      '根据你的进度，我建议：\n\n'
          '• 渴望来袭时 → 使用SOS呼吸或冲浪法\n'
          '• 压力大时 → 尝试CBT技能训练中的渐进式放松\n'
          '• 社交场合 → 提前准备拒绝话术\n'
          '• 日常维护 → 坚持每日打卡，保持意识觉察\n\n'
          '有什么具体场景你想聊聊吗？',
    ]);
  }

  String _handleSuccess(int days, GameProfile? profile) {
    final streak = profile?.streakDays ?? 0;
    return _randomFrom([
      '这太棒了！每一次成功都在强化你的决心。你知道吗，每抵抗一次渴望，'
          '你大脑中的戒断通路就会变得更弱一些。你在物理层面上正在改变自己的大脑！',
      '你的坚持正在创造奇迹。连续$streak天的打卡记录就是最好的证明。'
          '把这份成功记在心里——下次遇到困难时，它会给你力量。',
      '为你感到骄傲！记住这种感觉。当困难来临时，回想一下现在的成就。'
          '你已经证明了你可以做到。',
    ]);
  }

  String _handleProgress(int days, GameProfile? profile) {
    if (profile == null) {
      return '你还没有开始记录哦。完成每日打卡后，我就能给你更详细的分析和建议了。';
    }
    final streak = profile.streakDays;
    final level = profile.levelTitle;
    final cravingsResisted = profile.cravingsResisted;
    return '让我给你总结一下你的进展：\n\n'
        '📊 等级：$level（Lv.${profile.level}）\n'
        '🔥 连续打卡：$streak 天\n'
        '💪 成功抵抗渴望：$cravingsResisted 次\n'
        '⏱️ 戒断天数：$days 天\n'
        '🏅 最长连续记录：${profile.longestStreak} 天\n\n'
        '你对这些数据有什么疑问吗？';
  }

  String _handleSosRequest() {
    return _randomFrom([
      '如果渴望现在很强烈，立刻试试这个方法：\n\n'
          '1. 暂停一切，站起来\n'
          '2. 做4-7-8呼吸：吸气4秒 → 屏住7秒 → 呼气8秒\n'
          '3. 重复3-5次\n'
          '4. 喝一杯冷水\n'
          '5. 等待5分钟——渴望会自然消退\n\n'
          '你也可以回到首页使用SOS呼吸引导功能。',
    ]);
  }

  String _handleGeneralReflection(String input, int days) {
    return _randomFrom([
      '谢谢你的分享。能多说说吗？你刚才提到的让我想到——你是怎么看待自己戒断旅程的？',
      '我听到了你的想法。你觉得这些感受和你的戒断目标之间有什么联系吗？',
      '有意思。你今天有什么特别想达成的目标吗？即使是小小的进步也值得庆祝。',
      '每个人的旅程都是独特的。你现在最关心的是哪个方面？'
          '我可以给你更有针对性的建议。',
    ]);
  }

  // ---- Quick Reply Generation ----

  List<String> _initialQuickReplies() {
    return ['最近有点难熬', '坚持得还不错', '有什么好方法？', '我有点焦虑'];
  }

  List<String> _contextualQuickReplies(String userInput, String response) {
    final input = userInput.toLowerCase();

    // After craving discussion
    if (_containsAny(input, ['渴', '想抽', '想喝', '忍不住', '难受', '戒断'])) {
      return ['SOS按钮在哪？', '冲浪法怎么做？', '我之前抵抗过', '说点别的'];
    }

    // After emotion discussion
    if (_containsAny(input, ['心情', '焦虑', '压力', '烦躁', '生气', '难过'])) {
      return ['深呼吸怎么做？', '我该运动吗？', '还有什么方法？', '说说我的进展'];
    }

    // After relapse
    if (_containsAny(input, ['失败', '复吸', '破戒', '抽了', '喝了', '没忍住'])) {
      return ['我不想放弃', '帮我分析原因', '更新预防计划', '我需要鼓励'];
    }

    // After social pressure
    if (_containsAny(input, ['朋友', '社交', '聚会', '同事'])) {
      return ['怎么拒绝？', '有点尴尬', '孤独怎么办？', '还有什么建议？'];
    }

    // After sleep issue
    if (_containsAny(input, ['睡觉', '失眠', '睡眠', '累'])) {
      return ['4-7-8呼吸法', '还有什么方法？', '什么时候能好转？', '我有点焦虑'];
    }

    // After help request
    if (_containsAny(input, ['帮助', '怎么办', '方法', '建议'])) {
      return ['说说我的进展', '我有点焦虑', '睡眠不好怎么办？', '社交压力'];
    }

    // After success
    if (_containsAny(input, ['坚持', '做到了', '成功', '太棒', '很好'])) {
      return ['最近有点难熬', '说说我的进展', '有什么好方法？', '我有点焦虑'];
    }

    // After progress check
    if (_containsAny(input, ['进展', '数据', '统计', '记录'])) {
      return ['有什么建议？', '我有点焦虑', '最近有点难熬', '我做到了！'];
    }

    // Default general replies
    final options = [
      ['说说我的进展', '有什么建议？', '我有点焦虑', '坚持不住了'],
      ['最近有点难熬', '睡眠不好怎么办？', '社交压力大', '帮我分析原因'],
    ];
    return options[Random().nextInt(options.length)];
  }

  // ---- Category Detection ----

  String? _categorizeResponse(String response) {
    if (response.contains('渴望') && response.contains('消退')) return 'tip';
    if (response.contains('HALT')) return 'tip';
    if (response.contains('呼吸')) return 'tip';
    if (response.contains('方法') || response.contains('建议')) return 'tip';
    if (response.contains('?') || response.contains('？')) return 'question';
    if (response.contains('骄傲') || response.contains('棒')) return 'encouragement';
    if (response.contains('？')) return 'question';
    if (response.contains('进步') || response.contains('成功')) return 'encouragement';
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
}
