import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';

class UrgeToolkitScreen extends ConsumerStatefulWidget {
  const UrgeToolkitScreen({super.key});

  @override
  ConsumerState<UrgeToolkitScreen> createState() => _UrgeToolkitScreenState();
}

class _UrgeToolkitScreenState extends ConsumerState<UrgeToolkitScreen>
    with SingleTickerProviderStateMixin {
  bool _isTimerRunning = false;
  int _timerSeconds = 300;
  Timer? _timer;

  bool _sosActive = false;
  int _sosCycle = 0;
  int _sosPhase = 0;
  int _sosPhaseSeconds = 0;
  Timer? _sosTimer;
  bool _sosComplete = false;

  bool _groundingActive = false;
  int _groundingStep = 0;
  int _groundingSubStep = 0;
  Timer? _groundingTimer;

  late AnimationController _breathAnimController;
  late Animation<double> _breathAnim;

  static const _sosPhases = [
    {'label': '吸气4秒', 'seconds': 4},
    {'label': '屏息7秒', 'seconds': 7},
    {'label': '呼气8秒', 'seconds': 8},
  ];

  @override
  void initState() {
    super.initState();
    _breathAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _breathAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _breathAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sosTimer?.cancel();
    _groundingTimer?.cancel();
    _breathAnimController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      _timerSeconds = 300;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _isTimerRunning = false;
          timer.cancel();
          _onUrgeSurfingComplete();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerSeconds = 300;
    });
  }

  void _onUrgeSurfingComplete() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('你成功冲过了这次渴望！')),
    );
    try {
      await ref.read(cravingUseCaseProvider).logCraving(
            5,
            trigger: '渴望冲浪',
            context: '完成5分钟渴望冲浪练习',
            copingUsed: '渴望冲浪',
            resolved: true,
          );
      await ref.read(badgeRepositoryProvider).earnBadge('urge_surfed');
    } catch (_) {}
  }

  void _startSOS() async {
    setState(() {
      _sosActive = true;
      _sosCycle = 0;
      _sosPhase = 0;
      _sosPhaseSeconds = 0;
      _sosComplete = false;
    });
    _breathAnimController.repeat(reverse: true);
    _runSOSStep();
  }

  void _runSOSStep() {
    if (_sosCycle >= 3) {
      _breathAnimController.stop();
      setState(() {
        _sosActive = false;
        _sosComplete = true;
      });
      _onSOSComplete();
      return;
    }
    final phase = _sosPhases[_sosPhase];
    final seconds = phase['seconds'] as int;
    setState(() {
      _sosPhaseSeconds = seconds;
    });
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sosPhaseSeconds--;
      });
      if (_sosPhaseSeconds <= 0) {
        timer.cancel();
        int nextPhase = _sosPhase + 1;
        int nextCycle = _sosCycle;
        if (nextPhase >= _sosPhases.length) {
          nextPhase = 0;
          nextCycle++;
        }
        _sosPhase = nextPhase;
        _sosCycle = nextCycle;
        _runSOSStep();
      }
    });
  }

  void _onSOSComplete() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('渴望已经过去！你做到了！')),
    );
    try {
      await ref.read(cravingUseCaseProvider).logCraving(
            8,
            trigger: 'SOS紧急求助',
            context: '完成4-7-8呼吸法',
            copingUsed: '4-7-8呼吸法',
            resolved: true,
          );
      await ref.read(badgeRepositoryProvider).earnBadge('sos_used');
    } catch (_) {}
  }

  void _launchGrounding() {
    setState(() {
      _groundingActive = true;
      _groundingStep = 0;
      _groundingSubStep = 0;
    });
    _runGroundingStep();
  }

  void _runGroundingStep() {
    const steps = [
      '看5样东西',
      '摸4样东西',
      '听3种声音',
      '闻2种气味',
      '尝1种味道',
    ];
    if (_groundingStep >= steps.length) {
      setState(() {
        _groundingActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('接地练习完成！感觉如何？')),
      );
      return;
    }
    const durations = [15, 12, 10, 10, 8];
    if (_groundingSubStep >= durations[_groundingStep]) {
      setState(() {
        _groundingStep++;
        _groundingSubStep = 0;
      });
      _runGroundingStep();
      return;
    }
    _groundingTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _groundingSubStep++;
      });
      _runGroundingStep();
    });
  }

  void _logAlternative(String title) async {
    try {
      await ref.read(cravingUseCaseProvider).logCraving(
            3,
            trigger: '替代行为',
            context: '使用了替代行为: $title',
            copingUsed: title,
            resolved: true,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已记录：$title')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('渴望管理工具箱'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSOSCard(),
            const SizedBox(height: 16),
            _buildSurfingCard(),
            const SizedBox(height: 16),
            _buildAlternativesSection(),
            const SizedBox(height: 16),
            _buildGroundingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSCard() {
    return Card(
      color: _sosActive || _sosComplete
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.emergency,
                  color: _sosActive || _sosComplete
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'SOS 紧急求助',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _sosActive || _sosComplete
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '4-7-8呼吸法 - 3个循环帮助平复渴望',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_sosComplete)
              Column(
                children: [
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    '渴望已经过去！',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _sosComplete = false;
                      });
                    },
                    child: const Text('再来一次'),
                  ),
                ],
              )
            else if (_sosActive)
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _breathAnim,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(160, 160),
                        painter: _BreathCirclePainter(
                          progress: _breathAnim.value,
                          phase: _sosPhases[_sosPhase]['label'] as String,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _sosPhases[_sosPhase]['label'] as String,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '循环 ${_sosCycle + 1}/3',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      _sosTimer?.cancel();
                      _breathAnimController.stop();
                      setState(() {
                        _sosActive = false;
                        _sosComplete = false;
                        _sosCycle = 0;
                        _sosPhase = 0;
                      });
                    },
                    child: const Text('取消'),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _startSOS,
                  icon: const Icon(Icons.emergency, size: 28),
                  label: const Text(
                    'SOS 紧急求助',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurfingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.waves,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '渴望冲浪',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '渴望像海浪一样，来了又会退去',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '研究表明渴望通常在5-20分钟内达到峰值后消退 (Chaiton et al., 2016)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: _isTimerRunning ? _timerSeconds / 300 : 0,
                      strokeWidth: 10,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isTimerRunning
                            ? '${_timerSeconds ~/ 60}:${(_timerSeconds % 60).toString().padLeft(2, '0')}'
                            : '5:00',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      Text(
                        '分钟',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isTimerRunning)
                  OutlinedButton.icon(
                    onPressed: _stopTimer,
                    icon: const Icon(Icons.stop),
                    label: const Text('停止'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始5分钟冲浪'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativesSection() {
    final alternatives = [
      {'icon': Icons.water_drop, 'title': '喝水'},
      {'icon': Icons.directions_walk, 'title': '散步'},
      {'icon': Icons.music_note, 'title': '听音乐'},
      {'icon': Icons.air, 'title': '深呼吸'},
      {'icon': Icons.phone, 'title': '打电话'},
      {'icon': Icons.cleaning_services, 'title': '刷牙'},
      {'icon': Icons.circle, 'title': '嚼口香糖'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '替代行为',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '点击选择一项替代行为来应对渴望',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: alternatives.map((alt) {
            return InkWell(
              onTap: () => _logAlternative(alt['title'] as String),
              borderRadius: BorderRadius.circular(16),
              child: Card(
                child: Container(
                  width: (MediaQuery.of(context).size.width - 56) / 4,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        alt['icon'] as IconData,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        alt['title'] as String,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGroundingCard() {
    const steps = [
      '看5样东西',
      '摸4样东西',
      '听3种声音',
      '闻2种气味',
      '尝1种味道',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'CBT即时技巧 - 5-4-3-2-1接地练习',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '通过感官察觉将注意力带回当下，有效打断渴望循环',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (_groundingActive)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _groundingStep / steps.length +
                        (_groundingSubStep.toDouble() /
                            ([15, 12, 10, 10, 8][_groundingStep] *
                                steps.length)),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 16),
                  Icon(
                    Icons.timer_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[_groundingStep],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_groundingSubStep + 1}/'
                    '${[15, 12, 10, 10, 8][_groundingStep]}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      _groundingTimer?.cancel();
                      setState(() {
                        _groundingActive = false;
                        _groundingStep = 0;
                        _groundingSubStep = 0;
                      });
                    },
                    child: const Text('结束练习'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    '看5样东西 - 摸4样 - 听3种声音 - 闻2种气味 - 尝1种味道',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _launchGrounding,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('开始练习'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BreathCirclePainter extends CustomPainter {
  final double progress;
  final String phase;

  _BreathCirclePainter({required this.progress, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.7 * progress;
    final fullRadius = size.width / 2 * 0.7;

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, fullRadius, paint);

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, fillPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: phase.contains('吸')
            ? '🌬️'
            : phase.contains('屏')
                ? '⏸️'
                : '😮‍💨',
        style: const TextStyle(fontSize: 32),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _BreathCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}
