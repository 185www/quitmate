import 'dart:math';

/// A message from the virtual companion
class CompanionMessage {
  final String id;
  final String text;
  final String category; // 'morning_greeting', 'encouragement', 'challenge', 'tip', 'checkin_reminder', 'celebration'
  final DateTime timestamp;
  final bool read;
  final String? emoji;

  const CompanionMessage({
    required this.id,
    required this.text,
    required this.category,
    required this.timestamp,
    this.read = false,
    this.emoji,
  });
}

/// Virtual companion character
class QuitCompanion {
  static const String name = '小明';
  static const String emoji = '🤝';
  static const String subtitle = '你的戒烟伙伴';

  /// Generate a morning greeting based on user context
  static String morningGreeting(int daysSinceQuit, int streakDays, String levelTitle) {
    if (daysSinceQuit == 0) {
      return _randomFrom([
        '$emoji 早上好！今天是你的第一天，我在这里陪你。准备好了吗？',
        '$emoji 新的一天，新的开始！第一天虽然紧张，但你不是一个人在战斗。',
      ]);
    }
    if (streakDays >= 30) {
      return _randomFrom([
        '$emoji 早上好！${levelTitle}，你已经连续${streakDays}天了。继续保持！',
        '$emoji ${levelTitle}的早晨！${streakDays}天的坚持——你每天都在创造奇迹。',
      ]);
    }
    if (streakDays >= 7) {
      return _randomFrom([
        '$emoji 早上好！连续${streakDays}天打卡！你这周感觉怎么样？',
        '$emoji ${levelTitle}的早晨！${streakDays}天了，你的身体正在恢复。今天记得打卡哦！',
      ]);
    }
    return _randomFrom([
      '$emoji 早上好！第${daysSinceQuit}天，你今天感觉怎么样？来打个卡吧！',
      '$emoji 新的一天！你是${levelTitle}级别，再坚持一下。记得打卡！',
      '$emoji 早上好！别忘了记录今天的感受。我在这里陪着你。',
    ]);
  }

  /// Generate encouragement based on context
  static String encouragement(int streakDays, int cravingsResisted, int level) {
    if (cravingsResisted > 50) {
      return _randomFrom([
        '$emoji 你已经成功抵抗了${cravingsResisted}次渴求！每一次都是胜利。',
        '$emoji ${cravingsResisted}次！你知道这意味着什么吗？你的大脑正在改变。',
      ]);
    }
    if (streakDays >= 14) {
      return _randomFrom([
        '$emoji 两周了！你的味觉和嗅觉已经恢复了很多，感受到了吗？',
        '$emoji ${streakDays}天连续打卡，你已经成为自己的榜样了。',
      ]);
    }
    if (streakDays >= 7) {
      return _randomFrom([
        '$emoji 一周了！你已经度过了最难熬的阶段。接下来的每一天都会更容易。',
        '$emoji 7天！你知道吗？前3天是最难的时候，而你已经挺过来了。',
      ]);
    }
    return _randomFrom([
      '$emoji 每一天都是进步。即使是艰难的日子，你也选择了不放弃。',
      '$emoji 我知道有时候很难。但记住，你已经做得比你想象的要好。',
    ]);
  }

  /// Generate a daily challenge or tip
  static String dailyChallenge(int daysSinceQuit) {
    final challenges = [
      '💪 今日挑战：今天主动避开一个通常的触发场景',
      '🚶 今日挑战：散步15分钟，运动可以减少50%的渴求',
      '💧 今日挑战：今天多喝3杯水，保持身体水分充足',
      '🧘 今日挑战：做一次5分钟的正念呼吸练习',
      '📝 今日挑战：写下3个你戒烟的理由，随身携带',
      '🍎 今日挑战：今天吃一份水果替代习惯性的行为',
      '📞 今日挑战：告诉一个朋友你的戒烟进展，获得支持',
      '😴 今日挑战：今晚提前30分钟上床，充足睡眠帮助恢复',
      '🎯 今日挑战：设定今天的"不碰"时间段，严格执行',
      '🌿 今日挑战：找一个你喜欢的放松活动，今天尝试一下',
    ];
    // Rotate based on day
    return challenges[daysSinceQuit % challenges.length];
  }

  /// Generate check-in reminder
  static String checkinReminder(bool checkedInToday) {
    if (checkedInToday) {
      return _randomFrom([
        '$emoji 已打卡！今天的你也很棒。继续加油！',
        '$emoji 看到你打卡了，我为你高兴！今天还有什么需要我帮忙的吗？',
      ]);
    }
    return _randomFrom([
      '$emoji 还没打卡哦！花1分钟记录一下今天的感受吧',
      '$emoji 等你打卡！记录感受是了解自己、进步更快的好方法',
    ]);
  }

  /// Generate celebration for milestones
  static String celebration(String milestone) {
    return _randomFrom([
      '$emoji🎉 $milestone！你太厉害了！这一刻值得记住！',
      '$emoji✨ $milestone！每一个里程碑都是你用意志力换来的！',
    ]);
  }

  static String _randomFrom(List<String> options) {
    return options[Random().nextInt(options.length)];
  }
}
