import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/constants/breath_timing.dart';

/// Full-screen SOS breathing sheet with teal-to-dark gradient,
/// pulsing white breathing circle, and calming phase guidance.
///
/// Uses the medically-backed 4-7-8 breathing technique:
/// - Inhale: 4 seconds
/// - Hold: 7 seconds
/// - Exhale: 8 seconds
/// - Cycle: 19 seconds
class SosBreathingSheet extends ConsumerStatefulWidget {
  const SosBreathingSheet({super.key});

  @override
  ConsumerState<SosBreathingSheet> createState() => _SosBreathingSheetState();
}

class _SosBreathingSheetState extends ConsumerState<SosBreathingSheet>
    with SingleTickerProviderStateMixin {
  // ── Breathing state ──
  int _secondsRemaining = BreathTiming.sosSessionDuration;
  Timer? _timer;
  bool _breathing = true;
  bool _complete = false;
  bool _isSubmitting = false;

  /// Seconds elapsed since breathing started (after the session timer started)
  int _breathElapsed = 0;

  // ── Animation for subtle circle pulse overlay ──
  late AnimationController _pulseController;

  // ── Phase messages ──
  final _phaseMessages = [
    '承认渴望的存在，不评判自己',
    '你不需要和渴望对抗，只需等待',
    '渴望像海浪，会来也会走',
    '每次抵抗，你都在变强',
    '想想你为什么要戒掉',
    '你值得更好的生活',
  ];

  // ── Breathing phase calculation (4-7-8) ──
  _BreathPhase get _currentBreathPhase {
    final cyclePos = _breathElapsed % BreathTiming.cycleSeconds;
    if (cyclePos < BreathTiming.inhaleSeconds) return _BreathPhase.inhale;
    if (cyclePos < BreathTiming.inhaleSeconds + BreathTiming.holdSeconds) {
      return _BreathPhase.hold;
    }
    return _BreathPhase.exhale;
  }

  /// Progress within the current breath phase (0.0 to 1.0)
  double get _breathPhaseProgress {
    final cyclePos = _breathElapsed % BreathTiming.cycleSeconds;
    switch (_currentBreathPhase) {
      case _BreathPhase.inhale:
        return cyclePos / BreathTiming.inhaleSeconds;
      case _BreathPhase.hold:
        return (cyclePos - BreathTiming.inhaleSeconds) / BreathTiming.holdSeconds;
      case _BreathPhase.exhale:
        return (cyclePos - BreathTiming.inhaleSeconds - BreathTiming.holdSeconds) /
            BreathTiming.exhaleSeconds;
    }
  }

  /// Circle scale factor (0.6 min, 1.0 max)
  double get _breathCircleScale {
    switch (_currentBreathPhase) {
      case _BreathPhase.inhale:
        return 0.6 + 0.4 * _breathPhaseProgress;
      case _BreathPhase.hold:
        return 1.0;
      case _BreathPhase.exhale:
        return 1.0 - 0.4 * _breathPhaseProgress;
    }
  }

  String get _breathPhaseLabel {
    switch (_currentBreathPhase) {
      case _BreathPhase.inhale:
        return '吸气';
      case _BreathPhase.hold:
        return '屏息';
      case _BreathPhase.exhale:
        return '呼气';
    }
  }

  // ── Session phase (3 phases over 180s) ──
  int get _currentPhase {
    if (_secondsRemaining > 120) return 1;
    if (_secondsRemaining > 60) return 2;
    return 3;
  }

  String get _phaseLabel {
    switch (_currentPhase) {
      case 1:
        return '承认渴望';
      case 2:
        return '深呼吸放松';
      case 3:
        return '巩固决心';
      default:
        return '';
    }
  }

  String get _phaseInstruction {
    switch (_currentPhase) {
      case 1:
        return '感觉它，观察它，不评判';
      case 2:
        return '跟随圆圈的节奏呼吸';
      case 3:
        return '你已经做到了，再坚持一下';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _breathElapsed++;
        } else {
          _timer?.cancel();
          _breathing = false;
          _complete = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onComplete() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final cravingUC = ref.read(cravingUseCaseProvider);
      await cravingUC.logCraving(
        8,
        trigger: 'SOS紧急救援',
        copingUsed: '4-7-8呼吸法+正念',
        resolved: true,
      );
      final badgeRepo = ref.read(badgeRepositoryProvider);
      await badgeRepo.earnBadge('sos_used');
    } catch (_) {
      // Silently handle
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A5C52),
            Color(0xFF0D2F2A),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '退出',
                      style: TextStyle(color: Colors.white60, fontSize: 15),
                    ),
                  ),
                  const Text(
                    'SOS 紧急救援',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Phase indicator pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Column(
                children: [
                  Text(
                    '第$_currentPhase阶段 · $_phaseLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _phaseInstruction,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Breathing circle with 4-7-8 rhythm
            if (_breathing)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = _breathCircleScale;
                  final pulse = _pulseController.value;
                  final size = 160.0 * scale * (0.95 + pulse * 0.05);
                  final glowOpacity = 0.08 + (scale - 0.6) * 0.15;

                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: Colors.white
                            .withOpacity(0.2 + (scale - 0.6) * 0.3),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(glowOpacity),
                          blurRadius: 30 * scale,
                          spreadRadius: 6 * scale,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _breathPhaseLabel,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getPhaseCountdown(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.35), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 24,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Center(
                  child:
                      Icon(Icons.check_rounded, size: 64, color: Colors.white70),
                ),
              ),

            const Spacer(flex: 2),

            // Timer or complete text
            Text(
              _complete
                  ? '你撑过去了!'
                  : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: _complete ? 28 : 48,
                fontWeight: FontWeight.w700,
                color: _complete ? Colors.white : Colors.white.withOpacity(0.95),
                letterSpacing: _complete ? 0 : 2,
              ),
            ),

            const SizedBox(height: 20),

            // Motivational message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _complete
                      ? '每次抵抗都是胜利，你正在改变自己'
                      : _phaseMessages[
                          _secondsRemaining ~/ 30 % _phaseMessages.length],
                  key: ValueKey(_secondsRemaining ~/ 30),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const Spacer(flex: 2),

            // Complete button
            if (_complete)
              Padding(
                padding: const EdgeInsets.all(32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _onComplete,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A5C52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A5C52),
                            ),
                          )
                        : const Icon(Icons.celebration_rounded),
                    label: Text(
                      _isSubmitting ? '保存中...' : '我做到了!',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Returns the countdown text for the current breath phase (e.g., "3s")
  String _getPhaseCountdown() {
    final cyclePos = _breathElapsed % BreathTiming.cycleSeconds;
    int remaining;
    switch (_currentBreathPhase) {
      case _BreathPhase.inhale:
        remaining = BreathTiming.inhaleSeconds - cyclePos;
        break;
      case _BreathPhase.hold:
        remaining =
            BreathTiming.inhaleSeconds + BreathTiming.holdSeconds - cyclePos;
        break;
      case _BreathPhase.exhale:
        remaining = BreathTiming.inhaleSeconds +
            BreathTiming.holdSeconds +
            BreathTiming.exhaleSeconds -
            cyclePos;
        break;
    }
    return '${remaining}s';
  }
}

/// Breathing phase enum for the 4-7-8 technique
enum _BreathPhase { inhale, hold, exhale }
