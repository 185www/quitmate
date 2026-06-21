import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/breath_timing.dart';

/// 呼吸阶段枚举
enum _BreathPhase { inhale, hold, exhale }

/// 会话阶段枚举
enum _SessionPhase { prepare, breathing, complete }

/// 3-5分钟可视化呼吸引导界面 — 升级版渴望冲浪
///
/// 全屏沉浸式呼吸体验，包含：
/// - 准备阶段（10秒）：引导用户放松
/// - 呼吸引导阶段（180秒）：4-7-8呼吸循环
/// - 结束阶段（15秒）：正念收尾
class ImmersiveBreathingGuide extends StatefulWidget {
  /// 呼吸完成回调，返回总持续秒数
  final void Function(int durationSeconds) onComplete;

  const ImmersiveBreathingGuide({super.key, required this.onComplete});

  @override
  State<ImmersiveBreathingGuide> createState() =>
      _ImmersiveBreathingGuideState();
}

class _ImmersiveBreathingGuideState extends State<ImmersiveBreathingGuide>
    with TickerProviderStateMixin {
  // ── 阶段时长配置 ──
  static const int _prepareDuration = 10;
  static const int _breathingDuration = 180;
  static const int _completeDuration = 15;
  static const int _totalDuration =
      _prepareDuration + _breathingDuration + _completeDuration;

  // 4-7-8 呼吸相位时长（秒）
  static const int _inhaleDuration = BreathTiming.inhaleSeconds;
  static const int _holdDuration = BreathTiming.holdSeconds;
  static const int _exhaleDuration = BreathTiming.exhaleSeconds;
  static const int _cycleDuration = BreathTiming.cycleSeconds;

  // ── 状态 ──
  _SessionPhase _phase = _SessionPhase.prepare;
  int _elapsedSeconds = 0;
  Timer? _timer;
  double _phaseProgress = 0.0; // 0~1 当前阶段进度
  double _overallProgress = 0.0; // 0~1 整体进度

  // ── 动画控制器 ──
  late AnimationController _pulseController;
  late AnimationController _particleController;

  // ── 粒子数据 ──
  final List<_Particle> _particles = [];

  // ── 呼吸相位计算 ──
  _BreathPhase get _currentBreathPhase {
    final breathElapsed = _elapsedSeconds - _prepareDuration;
    if (breathElapsed < 0) return _BreathPhase.inhale;
    final cyclePos = breathElapsed % _cycleDuration;
    if (cyclePos < _inhaleDuration) return _BreathPhase.inhale;
    if (cyclePos < _inhaleDuration + _holdDuration) return _BreathPhase.hold;
    return _BreathPhase.exhale;
  }

  /// 当前呼吸循环内的 0~1 进度
  double get _breathCycleProgress {
    final breathElapsed = _elapsedSeconds - _prepareDuration;
    if (breathElapsed < 0) return 0;
    final cyclePos = breathElapsed % _cycleDuration;
    final phase = _currentBreathPhase;
    switch (phase) {
      case _BreathPhase.inhale:
        return cyclePos / _inhaleDuration;
      case _BreathPhase.hold:
        return (cyclePos - _inhaleDuration) / _holdDuration;
      case _BreathPhase.exhale:
        return (cyclePos - _inhaleDuration - _holdDuration) / _exhaleDuration;
    }
  }

  String get _breathPhaseLabel {
    switch (_currentBreathPhase) {
      case _BreathPhase.inhale:
        return '吸气...';
      case _BreathPhase.hold:
        return '屏息...';
      case _BreathPhase.exhale:
        return '呼气...';
    }
  }

  /// 呼吸圆的缩放系数（0.6 ~ 1.0）
  double get _breathCircleScale {
    switch (_currentBreathPhase) {
      case _BreathPhase.inhale:
        return 0.6 + 0.4 * _breathCycleProgress;
      case _BreathPhase.hold:
        return 1.0;
      case _BreathPhase.exhale:
        return 1.0 - 0.4 * _breathCycleProgress;
    }
  }

  /// 呼吸相位对应的渐变色
  List<Color> get _phaseGradientColors {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (_currentBreathPhase) {
      case _BreathPhase.inhale:
        return isDark
            ? [const Color(0xFF0D2F2A), const Color(0xFF1A5C52)]
            : [const Color(0xFFB2DFDB), const Color(0xFF4DB6AC)];
      case _BreathPhase.hold:
        return isDark
            ? [const Color(0xFF1A3A2A), const Color(0xFF2E5E3E)]
            : [const Color(0xFFC8E6C9), const Color(0xFF81C784)];
      case _BreathPhase.exhale:
        return isDark
            ? [const Color(0xFF0D1B2A), const Color(0xFF1B3A5C)]
            : [const Color(0xFFBBDEFB), const Color(0xFF64B5F6)];
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _initParticles();
    _startTimer();
  }

  void _initParticles() {
    final rng = Random(42);
    for (int i = 0; i < 24; i++) {
      _particles.add(_Particle(
        angle: rng.nextDouble() * 2 * pi,
        baseRadius: 0.6 + rng.nextDouble() * 0.5,
        speed: 0.2 + rng.nextDouble() * 0.3,
        size: 1.5 + rng.nextDouble() * 2.5,
        opacity: 0.3 + rng.nextDouble() * 0.5,
      ));
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds < _prepareDuration) {
          _phase = _SessionPhase.prepare;
          _phaseProgress = _elapsedSeconds / _prepareDuration;
        } else if (_elapsedSeconds <
            _prepareDuration + _breathingDuration) {
          _phase = _SessionPhase.breathing;
          _phaseProgress =
              (_elapsedSeconds - _prepareDuration) / _breathingDuration;
        } else if (_elapsedSeconds < _totalDuration) {
          _phase = _SessionPhase.complete;
          _phaseProgress =
              (_elapsedSeconds - _prepareDuration - _breathingDuration) /
                  _completeDuration;
        } else {
          _timer?.cancel();
          _phaseProgress = 1.0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onComplete(_totalDuration);
          });
        }
        _overallProgress = _elapsedSeconds / _totalDuration;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _exit() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _phase == _SessionPhase.breathing
                ? _phaseGradientColors
                : isDark
                    ? [const Color(0xFF0D2F2A), const Color(0xFF0D1B2A)]
                    : [const Color(0xFFE0F2F1), const Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── 整体进度条 ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildProgressBar(isDark),
              ),

              // ── 退出按钮 ──
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: _exit,
                  child: Text(
                    '退出',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              // ── 主内容 ──
              Center(
                child: _phase == _SessionPhase.prepare
                    ? _buildPreparePhase(isDark)
                    : _phase == _SessionPhase.breathing
                        ? _buildBreathingPhase(isDark)
                        : _buildCompletePhase(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 整体进度条 ──
  Widget _buildProgressBar(bool isDark) {
    return LinearProgressIndicator(
      value: _overallProgress.clamp(0.0, 1.0),
      backgroundColor: Colors.white.withOpacity(0.1),
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
      minHeight: 3,
    );
  }

  // ── 准备阶段 ──
  Widget _buildPreparePhase(bool isDark) {
    final pulseValue = _pulseController.value;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.6 + pulseValue * 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 脉冲圆点
              Container(
                width: 80 * (0.9 + pulseValue * 0.1),
                height: 80 * (0.9 + pulseValue * 0.1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2 + pulseValue * 0.15),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05 + pulseValue * 0.08),
                      blurRadius: 20 + pulseValue * 15,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.spa_rounded,
                  size: 32,
                  color: Colors.white.withOpacity(0.7 + pulseValue * 0.3),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '找一个舒适的姿势',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '闭上眼睛，放松身体',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                '${_prepareDuration - _elapsedSeconds}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 呼吸引导阶段 ──
  Widget _buildBreathingPhase(bool isDark) {
    final breathElapsed = _elapsedSeconds - _prepareDuration;
    final cycleNumber = (breathElapsed ~/ _cycleDuration) + 1;
    final totalCycles = (_breathingDuration / _cycleDuration).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 呼吸圆 + 粒子 ──
        SizedBox(
          width: 260,
          height: 260,
          child: AnimatedBuilder(
            animation: Listenable.merge(
                [_pulseController, _particleController]),
            builder: (context, child) {
              return CustomPaint(
                painter: _BreathCirclePainter(
                  scale: _breathCircleScale,
                  phase: _currentBreathPhase,
                  pulse: _pulseController.value,
                  particleAnim: _particleController.value,
                  particles: _particles,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 40),

        // ── 呼吸相位文字 ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _breathPhaseLabel,
            key: ValueKey(_currentBreathPhase),
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 循环计数 ──
        Text(
          '第 $cycleNumber / $totalCycles 次循环',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 32),

        // ── 动机文字 ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            '渴望正在像海浪一样退去',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        // ── 剩余时间 ──
        Text(
          '${(_prepareDuration + _breathingDuration - _elapsedSeconds) ~/ 60}'
          ':'
          '${(_prepareDuration + _breathingDuration - _elapsedSeconds) % 60}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ── 结束阶段 ──
  Widget _buildCompletePhase(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final fadeOut = _phaseProgress < 0.3
            ? _phaseProgress / 0.3
            : _phaseProgress > 0.8
                ? 1.0 - (_phaseProgress - 0.8) / 0.2
                : 1.0;

        return Opacity(
          opacity: fadeOut.clamp(0.0, 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.08),
                      blurRadius: 24,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '你做到了！',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '渴望正在过去',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '每一次冲浪都让你更加强大',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 粒子数据模型
// ═══════════════════════════════════════════════════════════════════════════════

class _Particle {
  final double angle;
  final double baseRadius;
  final double speed;
  final double size;
  final double opacity;

  const _Particle({
    required this.angle,
    required this.baseRadius,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// 呼吸圆 + 粒子 CustomPainter
// ═══════════════════════════════════════════════════════════════════════════════

class _BreathCirclePainter extends CustomPainter {
  final double scale;
  final _BreathPhase phase;
  final double pulse;
  final double particleAnim;
  final List<_Particle> particles;
  final bool isDark;

  _BreathCirclePainter({
    required this.scale,
    required this.phase,
    required this.pulse,
    required this.particleAnim,
    required this.particles,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.28;
    final radius = baseRadius * scale;
    final safeRadius = radius.isFinite ? radius.clamp(1.0, size.width / 2) : baseRadius;

    // ── 背景光晕 ──
    final glowColor = switch (phase) {
      _BreathPhase.inhale => const Color(0xFF4ECDC4).withOpacity(0.08 + pulse * 0.06),
      _BreathPhase.hold => const Color(0xFF81C784).withOpacity(0.06 + pulse * 0.04),
      _BreathPhase.exhale => const Color(0xFF64B5F6).withOpacity(0.08 + pulse * 0.06),
    };

    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, safeRadius * 1.8, glowPaint);

    // ── 主圆 ──
    final circleBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.15 + pulse * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, safeRadius, circleBorderPaint);

    // ── 内部填充 ──
    final fillColor = switch (phase) {
      _BreathPhase.inhale => Colors.white.withOpacity(0.04 + pulse * 0.03),
      _BreathPhase.hold => Colors.white.withOpacity(0.06),
      _BreathPhase.exhale => Colors.white.withOpacity(0.03 + pulse * 0.02),
    };
    final fillPaint = Paint()..color = fillColor;
    canvas.drawCircle(center, safeRadius, fillPaint);

    // ── 粒子 ──
    for (final p in particles) {
      final animOffset = particleAnim * p.speed * 2 * pi;
      final particleAngle = p.angle + animOffset;

      // 吸气时粒子靠近圆，呼气时远离
      final dispersion = switch (phase) {
        _BreathPhase.inhale => 0.8,
        _BreathPhase.hold => 1.0,
        _BreathPhase.exhale => 1.4,
      };

      final particleRadius = safeRadius * p.baseRadius * dispersion;
      final px = center.dx + cos(particleAngle) * particleRadius;
      final py = center.dy + sin(particleAngle) * particleRadius;

      final particleColor = switch (phase) {
        _BreathPhase.inhale => Colors.white.withOpacity(p.opacity * 0.7),
        _BreathPhase.hold => Colors.white.withOpacity(p.opacity * 0.4),
        _BreathPhase.exhale => const Color(0xFF90CAF9).withOpacity(p.opacity * 0.5),
      };

      final dotPaint = Paint()..color = particleColor;
      canvas.drawCircle(Offset(px, py), p.size, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BreathCirclePainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.phase != phase ||
        oldDelegate.pulse != pulse ||
        oldDelegate.particleAnim != particleAnim;
  }
}