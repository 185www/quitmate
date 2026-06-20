/// AI Coach 有状态引擎 — 基于对话上下文生成连贯的个性化回应
///
/// 相比 [AiCoachEngine] 的无状态设计，本引擎：
/// - 接收 [ConversationContext] 跟踪对话历史
/// - 检测话题切换并生成衔接性回应
/// - 基于已讨论主题避免重复建议
/// - 生成上下文感知的跟进问题
library;

import 'dart:math';
import 'conversation_context.dart';
import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../../domain/entity/game_profile.dart';
import '../../domain/entity/coach_message.dart';

/// 有状态 AI Coach 引擎
///
/// 使用方式：
/// ```dart
/// final engine = AiCoachEngineV2();
/// // 第一轮
/// var response = engine.generateResponse(userInput: '我很难受', user: user);
/// // 更新上下文
/// context = context.addTurn(ConversationTurn(...));
/// // 第二轮 — 引擎会参考上下文
/// response = engine.generateResponse(userInput: '就是想抽烟', user: user, context: context);
/// ```
class AiCoachEngineV2 {
  /// 最大上下文轮数（超出后自动截断）
  static const maxContextTurns = 20;

  // ---- Public API ----

  /// 生成上下文感知的问候语
  CoachMessage generateGreeting({
    User? user,
    GameProfile? gameProfile,
    DailyLogEntry? todayLog,
    ConversationContext? context,
  }) {
    final text = _buildGreetingText(user, gameProfile, todayLog, context);
    return CoachMessage(
      id: CoachMessage.generateId(),
      isUser: false,
      text: text,
      timestamp: DateTime.now(),
      category: 'greeting',
      quickReplies: _initialQuickReplies(context),
    );
  }

  /// 生成上下文感知的回应
  CoachMessage generateResponse({
    required String userInput,
    User? user,
    GameProfile? gameProfile,
    DailyLogEntry? todayLog,
    ConversationContext? context,
  }) {
    // 1. 检测当前输入的主题和情绪
    final currentTopic = _detectTopic(userInput);
    final currentEmotion = _detectEmotion(userInput);

    // 2. 检测话题切换
    final topicSwitched = context != null &&
        context.lastTopic != null &&
        context.lastTopic != currentTopic;

    // 3. 构建回应文本（考虑上下文）
    String text;
    if (topicSwitched && context != null) {
      // 话题切换时，先承认之前的讨论，再回应新话题
      text = _buildTopicSwitchResponse(
        previousTopic: context.lastTopic!,
        newTopic: currentTopic,
        userInput: userInput,
        user: user,
        gameProfile: gameProfile,
        context: context,
      );
    } else {
      text = _buildContextualResponse(
        userInput: userInput,
        topic: currentTopic,
        user: user,
        gameProfile: gameProfile,
        context: context,
      );
    }

    // 4. 生成分类和快捷回复
    final category = _categorizeResponse(text);
    final replies = _contextualQuickReplies(
      userInput,
      text,
      context: context,
      currentTopic: currentTopic,
    );

    return CoachMessage(
      id: CoachMessage.generateId(),
      isUser: false,
      text: text,
      timestamp: DateTime.now(),
      category: category,
      quickReplies: replies,
      // 附加元数据，供上层保存到对话历史
    );
  }

  // ---- Greeting ----

  String _buildGreetingText(
    User? user,
    GameProfile? gameProfile,
    DailyLogEntry? todayLog,
    ConversationContext? context,
  ) {
    // 有上下文时生成跟进式问候
    if (context != null && context.hasContext) {
      return _buildFollowUpGreeting(user, gameProfile, context);
    }
    return _buildFirstTimeGreeting(user, gameProfile);
  }

  String _buildFollowUpGreeting(
    User? user,
    GameProfile? gameProfile,
    ConversationContext context,
  ) {
    final lastTopic = context.lastTopic ?? '日常';
    final moodLabel = _moodLabel(context.moodTrend);

    // 基于上次话题生成跟进问候
    final greetings = <String>[
      '欢迎回来！上次我们聊了关于${lastTopic}的话题。$moodLabel，今天想继续聊这个，还是换个话题？',
      '${_timeGreeting()}！上次你提到${_summarizeLastTopic(context)}。'
          '现在感觉怎么样？有什么新的想聊的吗？',
    ];

    // 情绪趋势 declining 时给予额外关怀
    if (context.moodTrend == MoodTrend.declining) {
      greetings.add(
        '${_timeGreeting()}！我注意到你最近情绪有些波动，想聊聊吗？'
            '无论发生什么，我都在这里。',
      );
    }

    return _randomFrom(greetings);
  }

  String _summarizeLastTopic(ConversationContext context) {
    final last = context.lastTopic;
    switch (last) {
      case ConversationTopics.craving:
        return '渴望的问题';
      case ConversationTopics.emotion:
        return '情绪方面';
      case ConversationTopics.sleep:
        return '睡眠问题';
      case ConversationTopics.social:
        return '社交压力';
      case ConversationTopics.relapse:
        return '一次挫折';
      default:
        return '一些想法';
    }
  }

  String _buildFirstTimeGreeting(User? user, GameProfile? gameProfile) {
    if (user == null || !user.hasQuitDate) {
      return _randomFrom([
        '你好！我是你的戒烟戒酒教练。随时可以跟我聊，无论是想倾诉、寻求建议，还是只是想说说话。',
        '欢迎来到 QuitMate！我是你的 AI 教练，会陪你走过每一步。'
            '有什么想聊的吗？',
      ]);
    }

    final days = user.daysSinceQuit;
    final streak = gameProfile?.streakDays ?? 0;
    final level = gameProfile?.levelTitle ?? '';

    if (days == 0) {
      return _randomFrom([
        '今天是你的第一天，这是最重要的一天。有任何感受都可以跟我说——'
            '焦虑、兴奋、犹豫，都是正常的。',
        '你做出了一个很棒的决定！第一天通常最难，'
            '但你知道为什么而战。需要聊聊吗？',
      ]);
    }

    if (days <= 3) {
      return '第$days天了，最难熬的阶段。你的身体正在适应。'
          '${level.isNotEmpty ? "$level，" : ""}有什么不舒服的感觉吗？';
    }

    if (days <= 7) {
      return '一周快到了！连续$streak天打卡，身体修复已经开始。'
          '今天有什么挑战或想分享的吗？';
    }

    if (days <= 30) {
      return '$days天了！这个阶段心理习惯是最大挑战。'
          '最近有什么触发了你的渴望吗？';
    }

    if (days <= 90) {
      return '$days天的坚持，你已经重塑了很多习惯。'
          '连续$streak天打卡，有什么新的感悟吗？';
    }

    return '$days天，你已经是真正的$level了！保持$streak天的连续记录。'
        '有什么想聊的吗？';
  }

  // ---- Topic Switch Response ----

  String _buildTopicSwitchResponse({
    required String previousTopic,
    required String newTopic,
    required String userInput,
    User? user,
    GameProfile? gameProfile,
    required ConversationContext context,
  }) {
    final transition = _randomFrom([
      '关于${previousTopic}的话题我们先到这里。', // 可以随时再聊。
      '好的，我们先换个话题。',
      '我理解，让我来聊聊$newTopic。',
    ]);

    // 生成新话题的回应
    final mainResponse = _buildTopicHandlerResponse(
      userInput: userInput,
      topic: newTopic,
      user: user,
      gameProfile: gameProfile,
      context: context,
    );

    return '$transition\n\n$mainResponse';
  }

  // ---- Contextual Response ----

  String _buildContextualResponse({
    required String userInput,
    required String topic,
    User? user,
    GameProfile? gameProfile,
    ConversationContext? context,
  }) {
    // 优先使用有上下文感知的处理器
    final text = _buildTopicHandlerResponse(
      userInput: userInput,
      topic: topic,
      user: user,
      gameProfile: gameProfile,
      context: context,
    );

    // 如果有上下文，附加跟进提示
    if (context != null && context.hasContext) {
      return _appendFollowUpHint(text, topic, context);
    }
    return text;
  }

  /// 基于主题分发到对应处理器（有上下文版本）
  String _buildTopicHandlerResponse({
    required String userInput,
    required String topic,
    User? user,
    GameProfile? gameProfile,
    ConversationContext? context,
  }) {
    final days = user?.daysSinceQuit ?? 0;
    final stage = user?.stage ?? UserStage.preContemplation;
    final input = userInput.toLowerCase();

    switch (topic) {
      case ConversationTopics.craving:
        return _handleCraving(input, days, stage, context);
      case ConversationTopics.emotion:
        return _handleEmotion(input, days, context);
      case ConversationTopics.weight:
        return _handleWeightConcern(days);
      case ConversationTopics.relapse:
        return _handleRelapse(days, stage, context);
      case ConversationTopics.social:
        return _handleSocialPressure(days, context);
      case ConversationTopics.sleep:
        return _handleSleepIssue(days, context);
      case ConversationTopics.help:
        return _handleHelpRequest(days, stage, context);
      case ConversationTopics.success:
        return _handleSuccess(days, gameProfile, context);
      case ConversationTopics.progress:
        return _handleProgress(days, gameProfile);
      case ConversationTopics.sos:
        return _handleSosRequest();
      default:
        return _handleGeneralReflection(input, days, context);
    }
  }

  // ---- Stateful Handlers ----

  String _handleCraving(
    String input,
    int days,
    UserStage stage,
    ConversationContext? context,
  ) {
    // 有上下文时：检查是否重复讨论渴望
    if (context != null && context.recentlyDiscussed(ConversationTopics.craving)) {
      return _randomFrom([
        '渴望又来了是吗？我理解这种感觉。还记得上次我们讨论的吗——'
            '渴望像海浪，会自然消退。这次你能识别出触发因素吗？',
        '又遇到渴望了。你已经证明过自己可以抵抗。'
            '这次和上次有什么不同吗？同样的时间、场景、情绪？',
      ]);
    }

    if (days <= 3) {
      return _randomFrom([
        '前几天的渴望是最正常的生理反应。你知道吗，大多数渴望在3-5分钟内就会消退。'
            '试试按下SOS按钮，跟随呼吸练习，等待它过去。',
        '你正在经历的身体反应说明你的身体正在恢复。'
            '渴望是暂时的，但你的进步是永久的。你现在最需要的是什么？',
      ]);
    }

    return _randomFrom([
      '渴望像海浪——它会升起，达到峰值，然后自然消退。'
          '你之前成功抵抗过很多次了。能说说是什么触发了这次渴望吗？',
      '记住HALT原则：你是否Hungry(饿)、Angry(生气)、Lonely(孤独)、Tired(累)？'
          '很多渴望实际上来自这些基本需求。先检查一下这些。',
      '能告诉我这次渴望的强度吗？1-10分。了解你的渴望模式，'
          '能帮助我给你更精准的建议。',
    ]);
  }

  String _handleEmotion(
    String input,
    int days,
    ConversationContext? context,
  ) {
    // 情绪趋势 declining 时给予更深入的关注
    if (context?.moodTrend == MoodTrend.declining) {
      return _randomFrom([
        '我注意到你最近情绪一直不太稳定，这让我有点担心。'
            '持续的低落或焦虑如果超过两周，建议寻求专业帮助。\n\n'
            '现在，试着做3次深呼吸，把注意力放在呼吸上。'
            '这个简单练习可以激活副交感神经，帮助缓解焦虑。',
        '连续的情绪低落说明可能需要更多的支持。'
            '除了和我聊天，你还跟谁聊过你的感受吗？'
            '有时候，跟信任的人面对面聊聊会有帮助。',
      ]);
    }

    if (_containsAny(input, ['焦虑', '压力', '烦躁', '生气'])) {
      return _randomFrom([
        '情绪波动在戒断过程中很常见。你的大脑正在重新学习如何处理压力。\n\n'
            '现在试试这个：闭上眼睛，做3次深呼吸。'
            '把注意力放在呼吸的感觉上。'
            '你也可以试试"技能训练"里的压力管理技巧。',
        '压力和烦躁是戒断最常见的挑战。'
            '很多人用抽烟/喝酒来应对压力，现在你需要新的工具。\n\n'
            '"行动"标签里的技能训练有经过科学验证的压力管理技巧。',
      ]);
    }

    if (_containsAny(input, ['难过', '低落', '抑郁'])) {
      return _randomFrom([
        '戒断期间情绪低落是正常的——大脑正在调整多巴胺水平。'
            '保持社交联系、适度运动。'
            '如果持续超过两周，建议寻求专业帮助。',
        '我理解你的感受。重要的是不要孤立自己——'
            '跟信任的人聊聊。你现在有什么特别难过的事情吗？',
      ]);
    }

    return '情绪变化是戒断过程中正常的部分。'
        '你的大脑化学正在重新平衡。能具体说说你现在的感受吗？';
  }

  String _handleRelapse(
    int days,
    UserStage stage,
    ConversationContext? context,
  ) {
    // 有上下文且之前讨论过预防策略时，引导回顾
    if (context != null &&
        context.recentlyDiscussed(ConversationTopics.social, withinTurns: 8)) {
      return _randomFrom([
        '看来社交场景确实是一个挑战。上次我们讨论了拒绝话术，'
            '这次情况是类似的吗？我们可以一起回顾并改进你的预防计划。',
        '之前聊到社交压力时，你似乎已经有了一些想法。'
            '这次触发复吸的因素和之前讨论的有关系吗？',
      ]);
    }

    return _randomFrom([
      '首先，这完全正常。平均需要6-30次尝试才能成功戒断。'
          '一次复吸不代表失败——它是学习的机会。\n\n'
          '能跟我聊聊发生了什么吗？了解触发因素可以帮助制定更好的预防计划。',
      '深呼吸。你不是一个人在面对这个。复吸是旅程中的常见部分，而不是终点。\n\n'
          '让我们从中学习：什么触发了它？你能提前做些什么来应对？',
      '你知道吗？每一次尝试，你成功的概率都在增加。'
          '今天最重要的是：不要因为这一次而放弃。'
          '愿意聊聊发生了什么吗？',
    ]);
  }

  String _handleSocialPressure(
    int days,
    ConversationContext? context,
  ) {
    if (context != null &&
        context.mentionedTriggers.contains('聚会')) {
      return '聚会场景确实不容易。你之前提到过这个挑战。'
          '这次有没有提前准备什么应对策略？'
          '比如提前告诉朋友你的决定，或者准备替代活动？';
    }

    return _randomFrom([
      '社交压力是很多人复吸的主要原因之一。'
          '准备几句简单的拒绝话术："我最近在健身，戒了"、'
          '"医生建议我停一段时间"。\n\n'
          '真正的朋友会尊重你的决定。有什么具体的社交场景让你担心吗？',
      '关键是提前做好心理准备。在聚会前设定明确的界限，'
          '告诉至少一个朋友你的决定。也可以准备替代活动（喝茶、嚼口香糖）。',
    ]);
  }

  String _handleSleepIssue(
    int days,
    ConversationContext? context,
  ) {
    if (context != null &&
        context.recentlyDiscussed(ConversationTopics.sleep)) {
      return '睡眠问题还在持续是吗？如果超过2-4周没有改善，'
          '建议咨询医生。同时可以试试：\n'
          '1. 每天同一时间起床和睡觉\n'
          '2. 睡前30分钟不看手机\n'
          '3. 试试4-7-8呼吸法\n\n'
          '有什么新变化吗？';
    }

    return _randomFrom([
      '睡眠问题是戒断初期最常见的症状之一，通常在2-4周内改善。\n\n'
          '建议：保持固定作息，睡前避免咖啡因和屏幕，'
          '可以试试"技能训练"里的渐进式放松练习。',
      '试试这些方法：\n'
          '1. 每天同一时间起床和睡觉\n'
          '2. 睡前30分钟不看手机\n'
          '3. 卧室保持凉爽和安静\n'
          '4. 4-7-8呼吸法：吸气4秒，屏住7秒，呼气8秒',
    ]);
  }

  String _handleHelpRequest(
    int days,
    UserStage stage,
    ConversationContext? context,
  ) {
    // 有上下文时：基于已讨论内容给出针对性建议
    if (context != null && context.hasContext) {
      final discussed = context.discussedTopics;
      if (discussed.contains(ConversationTopics.craving)) {
        return '根据我们之前的讨论，你的主要挑战是渴望管理。'
            '我建议你重点关注：\n\n'
            '1. 渴望来袭时 → SOS呼吸或冲浪法\n'
            '2. 识别你的高危时段（通常在饭后或压力大时）\n'
            '3. 提前准备好替代行为\n\n'
            '想深入了解哪个方面？';
      }
      if (discussed.contains(ConversationTopics.emotion)) {
        return '根据我们聊过的，情绪管理是你的重点。建议：\n\n'
            '• 焦虑时 → CBT渐进式放松\n'
            '• 低落时 → 保持社交、适度运动\n'
            '• 压力大时 → 正念呼吸\n\n'
            '"技能训练"里有对应的练习，想试试哪个？';
      }
    }

    if (days == 0) {
      return '很高兴你想了解！几个经过科学验证的方法：\n\n'
          '1. 设定明确的戒断日期\n'
          '2. 告诉朋友和家人获得支持\n'
          '3. 识别你的触发因素\n'
          '4. 准备替代行为（口香糖、运动、喝水）\n'
          '5. 使用工具箱（SOS呼吸、冲浪法、CBT练习）\n\n'
          '最想了解哪个方面？';
    }

    return '根据你的进度，我建议：\n\n'
        '• 渴望来袭时 → SOS呼吸或冲浪法\n'
        '• 压力大时 → CBT技能训练\n'
        '• 社交场合 → 提前准备拒绝话术\n'
        '• 日常维护 → 坚持每日打卡\n\n'
        '有什么具体场景想聊聊？';
  }

  String _handleSuccess(
    int days,
    GameProfile? profile,
    ConversationContext? context,
  ) {
    final streak = profile?.streakDays ?? 0;

    // 如果之前讨论过困难，现在成功了，给予特别认可
    if (context != null &&
        context.recentlyDiscussed(ConversationTopics.craving)) {
      return '太棒了！你刚才还在和渴望作斗争，现在已经成功抵抗了。'
          '这种从困难中坚持下来的力量，才是真正的进步！'
          '连续$streak天的记录就是最好的证明。';
    }

    return _randomFrom([
      '这太棒了！每抵抗一次渴望，你大脑中的戒断通路就会更弱一些。'
          '你在物理层面上正在改变自己的大脑！',
      '你的坚持正在创造奇迹。连续$streak天的打卡记录就是最好的证明。'
          '把这份成功记在心里——下次遇到困难时，它会给你力量。',
    ]);
  }

  String _handleWeightConcern(int days) {
    return _randomFrom([
      '食欲增加是戒断后的常见反应，因为你的代谢和味觉正在恢复。'
          '好消息是，这通常在几周内稳定下来。\n\n'
          '建议：准备低热量零食（水果、坚果、胡萝卜条），'
          '适度运动不仅控制体重还能减少渴望。',
      '戒断后体重平均增加只有2-3公斤，'
          '可以通过简单的生活方式调整来管理。'
          '喝水、嚼无糖口香糖、运动——这些都是有效的替代策略。',
    ]);
  }

  String _handleProgress(int days, GameProfile? profile) {
    if (profile == null) {
      return '你还没有开始记录哦。完成每日打卡后，'
          '我就能给你更详细的分析和建议了。';
    }
    return '让我给你总结一下进展：\n\n'
        '等级：${profile.levelTitle}（Lv.${profile.level}）\n'
        '连续打卡：${profile.streakDays} 天\n'
        '成功抵抗渴望：${profile.cravingsResisted} 次\n'
        '戒断天数：$days 天\n'
        '最长连续记录：${profile.longestStreak} 天\n\n'
        '对这些数据有什么疑问吗？';
  }

  String _handleSosRequest() {
    return '如果渴望现在很强烈，立刻试试：\n\n'
        '1. 暂停一切，站起来\n'
        '2. 4-7-8呼吸：吸气4秒 → 屏住7秒 → 呼气8秒\n'
        '3. 重复3-5次\n'
        '4. 喝一杯冷水\n'
        '5. 等待5分钟——渴望会自然消退\n\n'
        '也可以回到首页使用SOS呼吸引导功能。';
  }

  String _handleGeneralReflection(
    String input,
    int days,
    ConversationContext? context,
  ) {
    // 有上下文时：生成更有针对性的反思
    if (context != null && context.hasContext) {
      final discussed = context.discussedTopics.toList();
      final topicStr =
          discussed.length > 2 ? discussed.sublist(0, 2).join('和') : discussed.join('和');

      return _randomFrom([
        '谢谢你的分享。我们之前聊了${topicStr.isEmpty ? "一些话题" : topicStr}，'
            '你刚才提到的让我想到新的角度——你觉得这些感受和你的戒断目标之间有什么联系吗？',
        '我听到了你的想法。能多说说吗？'
            '有时候说出来本身就有帮助。',
        '有意思的观察。你现在最关心的是哪个方面？'
            '我可以给你更有针对性的建议。',
      ]);
    }

    return _randomFrom([
      '谢谢你的分享。能多说说吗？你是怎么看待自己戒断旅程的？',
      '我听到了你的想法。你觉得这些感受和你的戒断目标之间有什么联系吗？',
      '每个人的旅程都是独特的。你现在最关心的是哪个方面？',
    ]);
  }

  // ---- Follow-up Hints ----

  /// 在回应末尾附加上下文感知的跟进提示
  String _appendFollowUpHint(
    String text,
    String topic,
    ConversationContext context,
  ) {
    // 不在以下情况追加（避免过度打扰）
    if (text.length > 300) return text;
    if (topic == ConversationTopics.sos) return text;

    // 生成基于对话历史的跟进提示
    final hints = <String>[];

    // 如果之前讨论过情绪，现在讨论渴望，可以桥接
    if (topic == ConversationTopics.craving &&
        context.recentlyDiscussed(ConversationTopics.emotion)) {
      hints.add('这次渴望和你的情绪有关系吗？');
    }

    // 如果之前讨论过社交压力，可以跟进
    if (topic == ConversationTopics.craving &&
        context.recentlyDiscussed(ConversationTopics.social)) {
      hints.add('这次是在社交场合吗？');
    }

    if (hints.isEmpty) return text;

    return '$text\n\n${hints.first}';
  }

  // ---- Quick Replies ----

  List<String> _initialQuickReplies(ConversationContext? context) {
    if (context != null && context.hasContext) {
      return ['继续上次的话题', '聊聊新的问题', '我最近有点难熬', '说说我的进展'];
    }
    return ['最近有点难熬', '坚持得还不错', '有什么好方法？', '我有点焦虑'];
  }

  List<String> _contextualQuickReplies(
    String userInput,
    String response, {
    ConversationContext? context,
    String? currentTopic,
  }) {
    final input = userInput.toLowerCase();

    // 基于当前话题的标准回复
    if (currentTopic == ConversationTopics.craving) {
      return ['SOS按钮在哪？', '冲浪法怎么做？', '我之前抵抗过', '说点别的'];
    }
    if (currentTopic == ConversationTopics.emotion) {
      return ['深呼吸怎么做？', '我该运动吗？', '还有什么方法？', '说说我的进展'];
    }
    if (currentTopic == ConversationTopics.relapse) {
      return ['我不想放弃', '帮我分析原因', '更新预防计划', '我需要鼓励'];
    }
    if (currentTopic == ConversationTopics.social) {
      return ['怎么拒绝？', '有点尴尬', '孤独怎么办？', '还有什么建议？'];
    }
    if (currentTopic == ConversationTopics.sleep) {
      return ['4-7-8呼吸法', '还有什么方法？', '什么时候能好转？', '我有点焦虑'];
    }

    // 有上下文时的通用回复（包含跨话题选项）
    if (context != null && context.hasContext) {
      final discussed = context.discussedTopics;
      // 提供尚未讨论过的话题作为选项
      final un-discussed = ConversationTopics.all
          .where((t) => !discussed.contains(t))
          .take(2)
          .toList();

      if (undiscussed.isNotEmpty) {
        return [
          '继续聊这个话题',
          ...undiscussed.map(_topicToQuickReply),
          '说说我的进展',
        ];
      }
    }

    // 默认回复
    return _randomFrom([
      ['说说我的进展', '有什么建议？', '我有点焦虑', '坚持不住了'],
      ['最近有点难熬', '睡眠不好怎么办？', '社交压力大', '帮我分析原因'],
    ]);
  }

  String _topicToQuickReply(String topic) {
    switch (topic) {
      case ConversationTopics.craving:
        return '我有点难熬';
      case ConversationTopics.emotion:
        return '我有点焦虑';
      case ConversationTopics.sleep:
        return '睡眠不好怎么办？';
      case ConversationTopics.social:
        return '社交压力大';
      case ConversationTopics.help:
        return '有什么好方法？';
      case ConversationTopics.progress:
        return '说说我的进展';
      default:
        return '聊聊别的';
    }
  }

  // ---- Detection ----

  String _detectTopic(String input) {
    final lower = input.toLowerCase();
    // 注意顺序：更具体的匹配优先
    if (_containsAny(lower, [
      '渴', '想抽', '想喝', '忍不住', '好难', '难受', '戒断', '痛苦'
    ])) {
      return ConversationTopics.craving;
    }
    if (_containsAny(lower, [
      '心情', '难过', '开心', '焦虑', '压力', '烦躁', '生气', '情绪'
    ])) {
      return ConversationTopics.emotion;
    }
    if (_containsAny(lower, ['体重', '胖', '吃', '食欲', '嘴馋'])) {
      return ConversationTopics.weight;
    }
    if (_containsAny(lower, [
      '失败', '复吸', '破戒', '抽了', '喝了', '没忍住', '后悔'
    ])) {
      return ConversationTopics.relapse;
    }
    if (_containsAny(lower, ['朋友', '社交', '聚会', '同事', '别人', '嘲笑'])) {
      return ConversationTopics.social;
    }
    if (_containsAny(lower, ['睡觉', '失眠', '睡眠', '睡不好', '累', '疲劳'])) {
      return ConversationTopics.sleep;
    }
    if (_containsAny(lower, ['帮助', '怎么办', '方法', '技巧', '怎么', '建议'])) {
      return ConversationTopics.help;
    }
    if (_containsAny(lower, ['坚持', '做到了', '成功了', '太棒', '很好', '不错'])) {
      return ConversationTopics.success;
    }
    if (_containsAny(lower, ['进展', '数据', '统计', '记录', '报告'])) {
      return ConversationTopics.progress;
    }
    if (_containsAny(lower, ['sos', '紧急', '呼吸', '冲浪'])) {
      return ConversationTopics.sos;
    }
    return 'general';
  }

  String _detectEmotion(String input) {
    final lower = input.toLowerCase();
    if (const ['焦虑', '压力', '烦躁', '生气', '痛苦'].any((k) => lower.contains(k))) {
      return 'negative';
    }
    if (const ['开心', '高兴', '不错', '很好', '成功', '坚持', '太棒']
        .any((k) => lower.contains(k))) {
      return 'positive';
    }
    return 'neutral';
  }

  // ---- Category Detection ----

  String? _categorizeResponse(String response) {
    if (response.contains('渴望') && response.contains('消退')) return 'tip';
    if (response.contains('HALT')) return 'tip';
    if (response.contains('呼吸')) return 'tip';
    if (response.contains('方法') || response.contains('建议')) return 'tip';
    if (response.contains('?') || response.contains('？')) return 'question';
    if (response.contains('骄傲') || response.contains('棒') || response.contains('成功'))
      return 'encouragement';
    return 'reflection';
  }

  // ---- Utilities ----

  String _moodLabel(MoodTrend trend) {
    switch (trend) {
      case MoodTrend.improving:
        return '看到你在好转';
      case MoodTrend.declining:
        return '我注意到你最近状态不太好';
      case MoodTrend.neutral:
        return '一切还好吗';
    }
  }

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
