import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scene_dialog.dart';

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
  late AnimationController _waveAnimController;

  String? _lastLoggedAlternative;

  static const _sosPhases = [
    {'label': '吸气', 'seconds': 4, 'emoji': '🌬️'},
    {'label': '屏息', 'seconds': 7, 'emoji': '⏸️'},
    {'label': '呼气', 'seconds': 8, 'emoji': '😮‍💨'},
  ];

  @override
  void initState() {
    super.initState();
    _breathAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sosTimer?.cancel();
    _groundingTimer?.cancel();
    _breathAnimController.dispose();
    _waveAnimController.dispose();
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

  void _onUrgeSurfingComplete() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ 完成')),
    );
    showModalBottomSheet(
      context: context,
      builder: (_) => SceneCaptureDialog(
        intensity: 7,
        trigger: '渴望冲浪',
        copingUsed: '渴望冲浪',
        resolved: true,
      ),
    );
  }

  void _startSOS() async {
    setState(() {
      _sosActive = true;
      _sosCycle = 0;
      _sosPhase = 0;
      _sosPhaseSeconds = (_sosPhases[0]['seconds'] as int);
      _sosComplete = false;
    });
    _breathAnimController.forward();
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

    _breathAnimController.duration = Duration(seconds: seconds);
    if (phase['label'] == '吸气') {
      _breathAnimController.forward(from: 0);
    } else if (phase['label'] == '屏息') {
      _breathAnimController.forward(from: 1);
    } else {
      _breathAnimController.reverse(from: 1);
    }

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

  void _cancelSOS() {
    _sosTimer?.cancel();
    _breathAnimController.stop();
    setState(() {
      _sosActive = false;
      _sosComplete = false;
      _sosCycle = 0;
      _sosPhase = 0;
    });
  }

  void _onSOSComplete() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SceneCaptureDialog(
        intensity: 10,
        trigger: 'SOS紧急求助',
        copingUsed: '4-7-8呼吸法',
        resolved: true,
      ),
    );
  }

  void _launchGrounding() {
    setState(() {
      _groundingActive = true;
      _groundingStep = 0;
      _groundingSubStep = 0;
    });
    _runGroundingStep();
  }

  void _stopGrounding() {
    _groundingTimer?.cancel();
    setState(() {
      _groundingActive = false;
      _groundingStep = 0;
      _groundingSubStep = 0;
    });
  }

  void _runGroundingStep() {
    const steps = [
      '👀 说出5样你看到的东西',
      '🖐️ 说出4样你摸到的东西',
      '👂 说出3种你听到的声音',
      '👃 说出2种你闻到的东西',
      '👅 说出1种你尝到的味道',
    ];
    const durations = [15, 12, 10, 10, 8];
    if (_groundingStep >= steps.length) {
      setState(() {
        _groundingActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 完成')),
      );
      return;
    }
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

  void _logAlternative(String title) {
    setState(() {
      _lastLoggedAlternative = title;
    });
    showModalBottomSheet(
      context: context,
      builder: (_) => SceneCaptureDialog(
        intensity: 5,
        trigger: '替代行为',
        copingUsed: title,
        resolved: true,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (_lastLoggedAlternative == title) {
            _lastLoggedAlternative = null;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧘 渴望管理工具箱'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSOSCard(),
            const SizedBox(height: 16),
            _buildSurfingCard(),
            const SizedBox(height: 16),
            _buildGroundingCard(),
            const SizedBox(height: 16),
            _buildAlternativesSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: _sosComplete
              ? const LinearGradient(
                  colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : _sosActive
                  ? const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF9d4edd)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF4facfe), Color(0xFF667eea)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('🌬️', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '4-7-8 呼吸',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '3个循环 · 约1分钟',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_sosComplete)
                _buildSOSComplete()
              else if (_sosActive)
                _buildSOSActive()
              else
                _buildSOSIdle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSIdle() {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: _startSOS,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4facfe),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌬️', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Text(
              '4-7-8 呼吸',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSActive() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _breathAnimController,
          builder: (context, child) {
            final phaseData = _sosPhases[_sosPhase];
            final phaseLabel = phaseData['label'] as String;
            final emoji = phaseData['emoji'] as String;
            return Column(
              children: [
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _BreathCirclePainter(
                    progress: _breathAnimController.value,
                    phase: phaseLabel,
                    emoji: emoji,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 4),
                Text(
                  phaseLabel,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_sosPhaseSeconds',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '第 ${_sosCycle + 1}/3 轮',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _cancelSOS,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.7),
          ),
          child: const Text('取消', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildSOSComplete() {
    return Column(
      children: [
        const Text('✅', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(
          '完成',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _sosComplete = false;
            });
          },
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text(
            '再来一次',
            style: TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSurfingCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF667eea)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🏄',
                    style: TextStyle(
                      fontSize: 32,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '渴望冲浪',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '渴望像海浪一样，来了又会退去',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '5分钟计时',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: _isTimerRunning ? _timerSeconds / 300 : 0,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        color: Colors.white.withOpacity(0.9),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isTimerRunning
                                ? '${_timerSeconds ~/ 60}:${(_timerSeconds % 60).toString().padLeft(2, '0')}'
                                : '5:00',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '分钟',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _waveAnimController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 50),
                    painter: _WavePainter(
                      progress: _waveAnimController.value,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isTimerRunning
                    ? ElevatedButton.icon(
                        onPressed: _stopTimer,
                        icon: const Icon(Icons.stop),
                        label: const Text(
                          '停止',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _startTimer,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          '开始',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4facfe),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroundingCard() {
    const steps = [
      '👀 说出5样你看到的东西',
      '🖐️ 说出4样你摸到的东西',
      '👂 说出3种你听到的声音',
      '👃 说出2种你闻到的东西',
      '👅 说出1种你尝到的味道',
    ];
    const stepEmojis = ['👀', '🖐️', '👂', '👃', '👅'];
    const durations = [15, 12, 10, 10, 8];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9d4edd), Color(0xFF667eea)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('🎯', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '5-4-3-2-1 接地练习',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '感官察觉 • 打断渴望循环',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_groundingActive)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_groundingStep * durations[_groundingStep] +
                                _groundingSubStep) /
                            (durations.reduce((a, b) => a + b)),
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$_groundingSubStep',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      steps[_groundingStep],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '剩余 ${durations[_groundingStep] - _groundingSubStep} 秒',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: _stopGrounding,
                      icon: const Icon(Icons.close, color: Colors.white70),
                      label: Text(
                        '结束练习',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Text(
                      '利用5种感官将注意力带回当下',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '👀 → 🖐️ → 👂 → 👃 → 👅',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _launchGrounding,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          '开始练习',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667eea),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativesSection() {
    const alternatives = [
      {'emoji': '🚶', 'title': '散步'},
      {'emoji': '💧', 'title': '喝水'},
      {'emoji': '🎵', 'title': '音乐'},
      {'emoji': '📞', 'title': '打电话'},
      {'emoji': '🧘', 'title': '冥想'},
      {'emoji': '🪥', 'title': '刷牙'},
      {'emoji': '🍬', 'title': '口香糖'},
      {'emoji': '🏋️', 'title': '运动'},
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('💪', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '替代行为',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '点击选择一项来应对渴望',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: alternatives.length,
                itemBuilder: (context, index) {
                  final alt = alternatives[index];
                  final isLogged = _lastLoggedAlternative == alt['title'];
                  return GestureDetector(
                    onTap: () => _logAlternative(alt['title']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isLogged
                            ? Colors.white.withOpacity(0.35)
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLogged
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          width: isLogged ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLogged)
                            const Text(
                              '✓',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            alt['emoji']!,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alt['title']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_lastLoggedAlternative != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      '已记录 $_lastLoggedAlternative ✓',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathCirclePainter extends CustomPainter {
  final double progress;
  final String phase;
  final String emoji;

  _BreathCirclePainter({
    required this.progress,
    required this.phase,
    required this.emoji,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 * 0.8;
    final innerRadius = maxRadius * (0.4 + 0.6 * progress);

    final outerPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, maxRadius, outerPaint);

    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.05),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerRadius, fillPaint);

    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, innerRadius, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _BreathCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final halfHeight = size.height / 2;
    final amplitude = halfHeight * 0.4;

    path.moveTo(0, halfHeight);
    for (double x = 0; x <= size.width; x++) {
      final y = halfHeight +
          amplitude *
              sin(
                (x / size.width) * 2 * pi * 2 +
                    progress * 2 * pi,
              );
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path2 = Path();
    path2.moveTo(0, halfHeight - 8);
    for (double x = 0; x <= size.width; x++) {
      final y = halfHeight -
          8 +
          amplitude *
              0.6 *
              sin(
                (x / size.width) * 2 * pi * 2 +
                    progress * 2 * pi +
                    1.5,
              );
      path2.lineTo(x, y);
    }
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
