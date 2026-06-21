import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';

/// v6.1 觉察日记页面 — 替代强制打卡的低门槛记录方式。
///
/// 设计理念：
/// - 不要求用户"没有使用"，允许诚实记录饮酒/吸烟行为
/// - AI 绝不批评，只做共情反射
/// - 极简设计：3个快捷按钮降低使用门槛
/// - 保存后给予正向反馈（"觉察是改变的第一步"）
class AwarenessDiaryScreen extends ConsumerStatefulWidget {
  const AwarenessDiaryScreen({super.key});

  @override
  ConsumerState<AwarenessDiaryScreen> createState() =>
      _AwarenessDiaryScreenState();
}

class _AwarenessDiaryScreenState extends ConsumerState<AwarenessDiaryScreen> {
  final _controller = TextEditingController();
  String? _awarenessType;
  bool _saving = false;

  static const _quickTemplates = [
    _QuickTemplate(
      label: '我今天感觉很糟，想喝酒',
      icon: Icons.cloud,
      type: 'emotion',
      text: '我今天感觉很糟，想喝酒。',
    ),
    _QuickTemplate(
      label: '我刚才喝了，有点后悔',
      icon: Icons.wine_bar,
      type: 'consumption',
      text: '我刚才喝了，有点后悔。',
    ),
    _QuickTemplate(
      label: '我不想戒，别烦我',
      icon: Icons.block,
      type: 'free',
      text: '我不想戒，别烦我。',
    ),
    _QuickTemplate(
      label: '刚才跟人吵架了，很烦躁',
      icon: Icons.chat_bubble_outline,
      type: 'trigger',
      text: '刚才跟人吵架了，很烦躁。',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);
    try {
      await ref.read(logUseCaseProvider).logToday(
            mood: 3, // neutral default
            urgeLevel: null,
            relapsed: true, // awareness diary doesn't judge
            notes: text,
            isAwarenessLog: true,
            awarenessType: _awarenessType ?? 'free',
            rawInput: text,
          );

      if (mounted) {
        // Show positive feedback — no judgment
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.favorite,
                  size: 48,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '谢谢你诚实面对自己的感受',
                  style: Theme.of(ctx).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '觉察是改变的第一步',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                child: const Text('好的'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('觉察日记'),
        subtitle: Text(
          '记录你的真实感受，没有对错',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Explanation card ──
            Card(
              color: primary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '这里没有"打卡"的压力。你可以记录任何真实的感受和经历。'
                        '你不需要证明自己"没喝"或"没抽"——诚实就是最大的勇气。',
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Quick fill buttons ──
            Text('快速记录', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickTemplates.map((tmpl) {
                return ActionChip(
                  avatar: Icon(tmpl.icon, size: 18),
                  label: Text(tmpl.label),
                  onPressed: () {
                    setState(() {
                      _controller.text = tmpl.text;
                      _awarenessType = tmpl.type;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Free text input ──
            Text('你想说什么？', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '用你自己的话记录……',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (_) {
                // Clear awareness type when user edits manually
                if (_awarenessType != null) {
                  // Check if text still matches a quick template
                  final text = _controller.text.trim();
                  bool matches = _quickTemplates.any(
                    (t) => t.text == text,
                  );
                  if (!matches) {
                    setState(() => _awarenessType = 'free');
                  }
                }
              },
            ),
            const SizedBox(height: 32),

            // ── Save button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    _controller.text.trim().isNotEmpty && !_saving ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Text('记录下来', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '你的记录只存在本地，不会上传到任何地方',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTemplate {
  final String label;
  final IconData icon;
  final String type;
  final String text;

  const _QuickTemplate({
    required this.label,
    required this.icon,
    required this.type,
    required this.text,
  });
}