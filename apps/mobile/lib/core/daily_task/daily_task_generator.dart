import '../../domain/entity/daily_task.dart';
import '../../domain/entity/user.dart';

class DailyTaskGenerator {
  /// Generate personalized daily tasks based on user context
  static List<DailyTask> generateForToday(
    User? user, {
    int streakDays = 0,
    int completedExercises = 0,
  }) {
    final tasks = <DailyTask>[];
    final today = DateTime.now();
    final dayOfYear =
        DateTime.now().difference(DateTime(today.year)).inDays;

    // ── Always: daily check-in task ──
    tasks.add(DailyTask(
      id: 'checkin_${today.toIso8601String()}',
      title: '每日打卡',
      description: '花1分钟记录今天的情绪和渴求水平',
      type: 'action',
      xpReward: 20,
      completed: false,
      date: today,
    ));

    // ── Exercise task (rotate through exercises) ──
    final exercisePool = [
      DailyTask(
        id: 'ex_${dayOfYear}_0',
        title: '思维记录',
        description: '记录一个触发你渴望的想法，挑战它的合理性',
        type: 'exercise',
        xpReward: 25,
        date: today,
        relatedExerciseId: 'thought_record',
      ),
      DailyTask(
        id: 'ex_${dayOfYear}_1',
        title: '深呼吸练习',
        description: '做3轮4-7-8呼吸法，感受身体放松',
        type: 'exercise',
        xpReward: 15,
        date: today,
        relatedExerciseId: 'breathing',
      ),
      DailyTask(
        id: 'ex_${dayOfYear}_2',
        title: '身体扫描',
        description: '用10分钟觉察全身的感受',
        type: 'exercise',
        xpReward: 25,
        date: today,
        relatedExerciseId: 'body_scan',
      ),
      DailyTask(
        id: 'ex_${dayOfYear}_3',
        title: '价值观澄清',
        description: '写下你戒烟/戒酒最重要的3个理由',
        type: 'reflection',
        xpReward: 15,
        date: today,
        relatedExerciseId: 'values',
      ),
      DailyTask(
        id: 'ex_${dayOfYear}_4',
        title: '感恩练习',
        description: '记录今天3件值得感恩的事情',
        type: 'reflection',
        xpReward: 10,
        date: today,
        relatedExerciseId: 'gratitude',
      ),
      DailyTask(
        id: 'ex_${dayOfYear}_5',
        title: '拒绝技巧训练',
        description: '在镜子前练习3种拒绝方式',
        type: 'exercise',
        xpReward: 20,
        date: today,
        relatedExerciseId: 'refusal',
      ),
      DailyTask(
        id: 'ex_${dayOfYear}_6',
        title: '三分钟呼吸空间',
        description: 'MBSR核心练习：觉察-收集-扩展',
        type: 'exercise',
        xpReward: 15,
        date: today,
        relatedExerciseId: 'breath_space',
      ),
      DailyTask(
        id: 'ex_${dayOfYear}_7',
        title: '渴望冲浪',
        description: '观察渴望如海浪般自然起伏消退',
        type: 'exercise',
        xpReward: 20,
        date: today,
        relatedExerciseId: 'urge_surfing',
      ),
      DailyTask(
        id: 'ex_${dayOfYear}_8',
        title: '认知解离',
        description: '"我有了这个想法" vs "我是这个想法"',
        type: 'exercise',
        xpReward: 20,
        date: today,
        relatedExerciseId: 'defusion',
      ),
      DailyTask(
        id: 'ex_${dayOfYear}_9',
        title: '成本效益分析',
        description: '理性权衡继续使用与戒断的利弊',
        type: 'exercise',
        xpReward: 20,
        date: today,
        relatedExerciseId: 'cost_benefit',
      ),
    ];

    // Select 1 exercise task based on day
    tasks.add(exercisePool[dayOfYear % exercisePool.length]);

    // ── Reflection task ──
    final reflectionPool = [
      DailyTask(
        id: 'ref_${dayOfYear}_0',
        title: '今日反思',
        description: '回答：今天我最自豪的一件事是什么？',
        type: 'reflection',
        xpReward: 10,
        date: today,
      ),
      DailyTask(
        id: 'ref_${dayOfYear}_1',
        title: '触发日记',
        description: '记录今天遇到的一个触发场景及你的应对',
        type: 'reflection',
        xpReward: 15,
        date: today,
      ),
      DailyTask(
        id: 'ref_${dayOfYear}_2',
        title: '进步笔记',
        description: '写下今天感受到的一个积极变化',
        type: 'reflection',
        xpReward: 10,
        date: today,
      ),
      DailyTask(
        id: 'ref_${dayOfYear}_3',
        title: '自我肯定',
        description: '写下3句对自己的肯定和鼓励',
        type: 'reflection',
        xpReward: 10,
        date: today,
      ),
      DailyTask(
        id: 'ref_${dayOfYear}_4',
        title: '未来想象',
        description: '闭上眼睛想象戒断成功3个月后的自己',
        type: 'reflection',
        xpReward: 15,
        date: today,
      ),
    ];
    tasks.add(reflectionPool[dayOfYear % reflectionPool.length]);

    // ── Challenge task (only after first week) ──
    final daysSinceQuit = user?.daysSinceQuit ?? 0;
    if (daysSinceQuit >= 7) {
      final challengePool = [
        DailyTask(
          id: 'ch_${dayOfYear}_0',
          title: '散步15分钟',
          description: '中等强度运动可减少50%渴求',
          type: 'challenge',
          xpReward: 30,
          date: today,
        ),
        DailyTask(
          id: 'ch_${dayOfYear}_1',
          title: '喝8杯水',
          description: '充足的水分帮助身体排毒和减少渴求',
          type: 'challenge',
          xpReward: 15,
          date: today,
        ),
        DailyTask(
          id: 'ch_${dayOfYear}_2',
          title: '告诉一个人你的进展',
          description: '社会支持是成功戒断的重要因素',
          type: 'challenge',
          xpReward: 20,
          date: today,
        ),
        DailyTask(
          id: 'ch_${dayOfYear}_3',
          title: '提前30分钟睡觉',
          description: '充足睡眠帮助身体恢复和减少渴望',
          type: 'challenge',
          xpReward: 15,
          date: today,
        ),
        DailyTask(
          id: 'ch_${dayOfYear}_4',
          title: '健康饮食一顿',
          description: '选择一顿营养均衡的餐食，避免垃圾食品',
          type: 'challenge',
          xpReward: 15,
          date: today,
        ),
        DailyTask(
          id: 'ch_${dayOfYear}_5',
          title: '做一件让自己开心的事',
          description: '培养正向体验，建立新的奖赏回路',
          type: 'challenge',
          xpReward: 15,
          date: today,
        ),
      ];
      tasks.add(challengePool[dayOfYear % challengePool.length]);
    }

    return tasks;
  }
}