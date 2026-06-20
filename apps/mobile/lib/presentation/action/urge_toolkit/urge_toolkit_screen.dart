import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scene_dialog.dart';
import '../../../core/di/providers.dart';
import '../../../core/coach/urge_state.dart';

/// Urge Toolkit Screen — 状态机重构版
///
/// 重构要点：
/// - 使用 [UrgeStateMachine] 管理状态转换，替代手动 Timer 管理
/// - 将延迟计时 / 呼吸练习 / 冲浪 / 接地技术拆分为独立方法区块
/// - 主 Screen 作为状态机协调器，根据 [UrgeToolState] 渲染对应工具
/// - 所有 Timer 在状态转换和 dispose 时正确清理
class UrgeToolkitScreen extends ConsumerStatefulWidget {
  const UrgeToolkitScreen({super.key});

  @override
  ConsumerState<UrgeToolkitScreen> createState() => _UrgeToolkitScreenState();
}

class _UrgeToolkitScreenState extends ConsumerState<UrgeToolkitScreen>
    with SingleTickerProviderStateMixin {
  // ---- 状态机 ----
  final UrgeStateMachine _sm = UrgeStateMachine();

  // ---- 延迟计时器状态 ----
  int _delaySeconds = 300;
  Timer? _delayTimer;

  // ---- SOS 呼吸状态 ----
  int _sosPhase = 0;
  int _sosPhaseSeconds = 0;
  Timer? _sosTimer;
  bool _sosComplete = false;
  bool _sosActive = false;

  // ---- 接地技术状态 ----
  int _groundingStep = 0;
  int _groundingSubStep = 0;
  Timer? _groundingTimer;

  // ---- 动画控制器 ----
  late AnimationController _breathAnimController;
  late AnimationController _waveAnimController;

  String? _lastLoggedAlternative;
  int _selectedIntensity = 5;

  static const _sosPhases = [
    {'label': '吸气', 'seconds': 4, 'emoji': '🌬'},
    {'label': '屏息', 'seconds': 7, 'emoji': '⏸'},
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
    _cancelAllTimers();
    _breathAnimController.dispose();
    _waveAnimController.dispose();
    super.dispose();
  }

  void _cancelAllTimers() {
    _delayTimer?.cancel();
    _sosTimer?.cancel();
    _groundingTimer?.cancel();
  }

  // ---- 状态机驱动的工具启动 ----

  void _startTool(UrgeToolState tool, {int intensity = 0, String? trigger}) {
    if (!_sm.transitionTo(tool, intensity: intensity, trigger: trigger)) return;
    _cancelAllTimers();

    switch (tool) {
      case UrgeToolState.delayTimer:
        _startDelayTimer();
        break;
      case UrgeToolState.breathing:
        _startBreathing();
        break;
      case UrgeToolState.urgeSurfing:
        // 冲浪由动画驱动，不需要 Timer
        break;
      case UrgeToolState.grounding:
        _startGrounding();
        break;
      case UrgeToolState.completed:
      case UrgeToolState.idle:
        break;
    }
    setState(() {});
  }

  void _cancelTool() {
    _cancelAllTimers();
    _breathAnimController.stop();
    _sm.cancel();
    setState(() {});
  }

  void _completeTool() {
    _cancelAllTimers();
    _breathAnimController.stop();

    final session = _sm.currentSession;
    if (session != null) {
      _logCravingSession(session);
    }

    _sm.transitionTo(UrgeToolState.completed);
    setState(() {});
  }

  void _resetToIdle() {
    _cancelAllTimers();
    _sm.reset();
    setState(() {});
  }

  // ---- 延迟计时器 ----

  void _startDelayTimer() {
    _delaySeconds = 300;
    _delayTimer?.cancel();
    _delayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_delaySeconds > 0) {
          _delaySeconds--;
        } else {
          _delayTimer?.cancel();
          _completeTool();
        }
      });
    });
  }

  // ---- SOS 呼吸练习 ----

  void _startBreathing() {
    _sosActive = true;
    _sosPhase = 0;
    _sosPhaseSeconds = _sosPhases[0]['seconds'] as int;
    _sosComplete = false;
    _breathAnimController.repeat(reverse: true);

    _sosTimer?.cancel();
    _tickSosBreathing();
  }

  void _tickSosBreathing() {
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _sosPhaseSeconds--;
        if (_sosPhaseSeconds <= 0) {
          _sosPhase++;
          if (_sosPhase >= _sosPhases.length) {
            _sosTimer?.cancel();
            _sosComplete = true;
            _sosActive = false;
            _breathAnimController.stop();
            _completeTool();
            return;
          }
          _sosPhaseSeconds = _sosPhases[_sosPhase]['seconds'] as int;
        }
      });
    });
  }

  // ---- 接地技术 ----

  void _startGrounding() {
    _groundingStep = 0;
    _groundingSubStep = 0;
    _groundingTimer?.cancel();
    setState(() {});
  }

  void _advanceGrounding() {
    setState(() {
      _groundingSubStep++;
      if (_groundingSubStep >= _groundingStepCounts[_groundingStep]) {
        _groundingStep++;
        _groundingSubStep = 0;
        if (_groundingStep >= _groundingStepCounts.length) {
          _groundingTimer?.cancel();
          _completeTool();
        }
      }
    });
  }

  static const _groundingStepCounts = [5, 4, 3, 2, 1];
  static const _groundingLabels = [
    '看到',
    '摸到',
    '听到',
    '闻到',
    '尝到',
  ];

  // ---- 渴望记录 ----

  void _logCravingSession(UrgeSessionRecord session) {
    try {
      final cravingRepo = ref.read(cravingRepositoryProvider);
      final user = ref.read(userUseCaseProvider).getCurrentUser();
      if (user != null) {
        cravingRepo.logCraving(
          user.id,
          session.intensity,
          trigger: session.trigger ?? 'urge_toolkit',
          copingUsed: session.toolUsed.name,
          resolved: session.completed,
        );
      }
    } catch (_) {
      // 日志记录失败不阻断用户体验
    }
  }

  // ---- 构建 UI ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sm.currentToolLabel),
        leading: _sm.isToolActive
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelTool,
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_sm.state) {
      case UrgeToolState.idle:
        return _buildToolSelector();
      case UrgeToolState.delayTimer:
        return _buildDelayTimerUI();
      case UrgeToolState.breathing:
        return _buildBreathingUI();
      case UrgeToolState.urgeSurfing:
        return _buildSurfingUI();
      case UrgeToolState.grounding:
        return _buildGroundingUI();
      case UrgeToolState.completed:
        return _buildCompletedUI();
    }
  }

  /// 工具选择列表
  Widget _buildToolSelector() {
    final tools = [
      _ToolOption(
        icon: Icons.timer_outlined,
        title: '延迟 5 分钟',
        subtitle: '大多数渴望在 5 分钟内消退',
        color: Colors.blue,
        state: UrgeToolState.delayTimer,
      ),
      _ToolOption(
        icon: Icons.air,
        title: 'SOS 呼吸',
        subtitle: '4-7-8 呼吸法快速缓解',
        color: Colors.teal,
        state: UrgeToolState.breathing,
      ),
      _ToolOption(
        icon: Icons.waves_outlined,
        title: '渴望冲浪',
        subtitle: '观察渴望如海浪般升起又消退',
        color: Colors.indigo,
        state: UrgeToolState.urgeSurfing,
      ),
      _ToolOption(
        icon: Icons.touch_app_outlined,
        title: '5-4-3-2-1 接地',
        subtitle: '用感官回到当下',
        color: Colors.orange,
        state: UrgeToolState.grounding,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text(
          '选择一个工具来帮助你度过这次渴望',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ),
      // 强度选择
      _buildIntensityPicker(),
      const SizedBox(height: 16),
      ...tools.map((tool) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildToolCard(tool),
          )),
    ];
  }

  Widget _buildToolCard(_ToolOption tool) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tool.color.withOpacity(0.1),
          child: Icon(tool.icon, color: tool.color),
        ),
        title: Text(tool.title),
        subtitle: Text(tool.subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _startTool(tool.state, intensity: _selectedIntensity),
      ),
    );
  }

  Widget _buildIntensityPicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('渴望强度（1-10）',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Slider(
              value: _selectedIntensity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_selectedIntensity',
              onChanged: (v) => setState(() {
                _selectedIntensity = v.toInt();
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 延迟计时器 UI ----

  Widget _buildDelayTimerUI() {
    final minutes = _delaySeconds ~/ 60;
    final seconds = _delaySeconds % 60;
    final progress = 1.0 - (_delaySeconds / 300.0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('等待渴望消退...', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
                Center(
                  child: Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('渴望通常在 3-5 分钟内自然消退',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _cancelTool,
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // ---- 呼吸练习 UI ----

  Widget _buildBreathingUI() {
    if (_sosComplete) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text('呼吸练习完成！',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('你的渴望正在消退'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetToIdle,
              child: const Text('返回工具箱'),
            ),
          ],
        ),
      );
    }

    final phase = _sosPhases[_sosPhase];
    final breathValue = _breathAnimController.value;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 呼吸动画圆圈
          AnimatedBuilder(
            animation: _breathAnimController,
            builder: (context, child) {
              final scale = 0.6 + breathValue * 0.4;
              return Container(
                width: 180 * scale,
                height: 180 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withOpacity(0.1),
                  border: Border.all(color: Colors.teal, width: 3),
                ),
                child: Center(
                  child: Text(
                    '${phase['label']}\n${_sosPhaseSeconds}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text('${phase['emoji']} ${phase['label']} ${phase['seconds']}秒',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('第 ${_sosPhase + 1}/3 轮',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _cancelTool,
            child: const Text('提前结束'),
          ),
        ],
      ),
    );
  }

  // ---- 冲浪 UI ----

  Widget _buildSurfingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('观察渴望如海浪', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          const Text('它正在升起...不要对抗，只是观察',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          // 波形动画
          SizedBox(
            width: 300,
            height: 150,
            child: AnimatedBuilder(
              animation: _waveAnimController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavePainter(_waveAnimController.value),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          const Text('渴望会达到峰值，然后自然消退',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: _cancelTool, child: const Text('停止')),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _completeTool,
                child: const Text('渴望已消退'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- 接地技术 UI ----

  Widget _buildGroundingUI() {
    if (_groundingStep >= _groundingLabels.length) {
      return _buildCompletedUI();
    }

    final label = _groundingLabels[_groundingStep];
    final count = _groundingStepCounts[_groundingStep];
    final progress = _groundingSubStep / count;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_groundingStep + 1}/5',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '说出 $_groundingLabels[_groundingStep] 的 $count 样东西',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '当前第 ${_groundingSubStep + 1}/$count 个',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _advanceGrounding,
            child: Text(_groundingSubStep < count - 1 ? '下一个' : '下一步'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _cancelTool, child: const Text('跳过')),
        ],
      ),
    );
  }

  // ---- 完成页 ----

  Widget _buildCompletedUI() {
    final session = _sm.currentSession;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text('做得好！',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('你又成功抵抗了一次渴望'),
            if (session != null) ...[
              const SizedBox(height: 16),
              Text('使用工具: ${_sm.currentToolLabel}'),
              Text('强度: ${session.intensity}/10'),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetToIdle,
              child: const Text('继续'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 工具选项数据
class _ToolOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final UrgeToolState state;

  const _ToolOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.state,
  });
}

/// 简单波形绘制器
class _WavePainter extends CustomPainter {
  final double animationValue;

  _WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var x = 0.0; x <= size.width; x++) {
      final normalizedX = x / size.width;
      final y = size.height / 2 +
          sin((normalizedX * 4 * pi) + animationValue * 2 * pi) *
              size.height *
              0.3;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.animationValue != animationValue;
}
