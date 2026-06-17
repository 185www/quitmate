import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UrgeToolkitScreen extends ConsumerStatefulWidget {
  const UrgeToolkitScreen({super.key});

  @override
  ConsumerState<UrgeToolkitScreen> createState() => _UrgeToolkitScreenState();
}

class _UrgeToolkitScreenState extends ConsumerState<UrgeToolkitScreen> {
  bool _isTimerRunning = false;
  int _timerSeconds = 300; // 5 minutes
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
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
            _buildSurfingCard(context),
            const SizedBox(height: 16),
            _buildAlternativesSection(context),
            const SizedBox(height: 16),
            _buildSOSCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSurfingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.waves,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '渴望冲浪',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '渴望通常会在5分钟内消退。让我们一起度过这段时间。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (_isTimerRunning) ...[
              Text(
                '${_timerSeconds ~/ 60}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _timerSeconds / 300,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _stopTimer,
                child: const Text('停止计时'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _startTimer,
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始5分钟冲浪'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativesSection(BuildContext context) {
    final alternatives = [
      {'icon': Icons.water_drop, 'title': '喝一杯水', 'description': '喝水可以缓解口腔渴望'},
      {'icon': Icons.directions_walk, 'title': '散步5分钟', 'description': '轻微运动帮助转移注意力'},
      {'icon': Icons.music_note, 'title': '听音乐', 'description': '听一首喜欢的歌放松心情'},
      {'icon': Icons.book, 'title': '阅读', 'description': '翻看一本书或文章'},
      {'icon': Icons.phone, 'title': '打电话给朋友', 'description': '与支持你的人聊天'},
      {'icon': Icons.sports_gymnastics, 'title': '深呼吸', 'description': '做10次深呼吸练习'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '替代行为',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...alternatives.map((alt) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(alt['icon'] as IconData),
                ),
                title: Text(alt['title'] as String),
                subtitle: Text(alt['description'] as String),
              ),
            )),
      ],
    );
  }

  Widget _buildSOSCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emergency,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  '紧急求助',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '如果你感到非常困难，可以联系：',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('心理援助热线'),
              subtitle: const Text('400-161-9995'),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('戒烟热线'),
              subtitle: const Text('400-808-5531'),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}