import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';

class SceneCaptureDialog extends ConsumerStatefulWidget {
  final int intensity;
  final String? trigger;
  final String? copingUsed;
  final bool resolved;

  const SceneCaptureDialog({
    super.key,
    required this.intensity,
    this.trigger,
    this.copingUsed,
    this.resolved = false,
  });

  @override
  ConsumerState<SceneCaptureDialog> createState() => _SceneCaptureDialogState();
}

class _SceneCaptureDialogState extends ConsumerState<SceneCaptureDialog> {
  String? _location;
  String? _social;
  String? _activity;

  static const _locations = ['家', '公司', '酒吧/餐厅', '车里', '户外', '公共场所', '其他'];
  static const _socials = ['独自一人', '配偶/伴侣', '朋友', '同事', '家人', '社交聚会', '其他'];
  static const _activities = [
    '工作/学习',
    '放松/休息',
    '吃饭/喝水',
    '喝酒/派对',
    '压力/焦虑',
    '无聊/空闲',
    '熬夜/失眠',
    '其他'
  ];

  Future<void> _save() async {
    try {
      await ref.read(cravingUseCaseProvider).logCraving(
            widget.intensity,
            trigger: widget.trigger,
            copingUsed: widget.copingUsed,
            resolved: widget.resolved,
            location: _location,
            socialContext: _social,
            activity: _activity,
          );
      // Award XP if craving was resisted
      if (widget.resolved) {
        final user = await ref.read(userUseCaseProvider).getCurrentUser();
        if (user != null) {
          await ref.read(gameUseCaseProvider).awardCravingResisted(user.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存场景记录失败: $e')),
        );
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('记录当时场景',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('了解触发场景有助于预防复发',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          Text('你在哪里？', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _locations
                .map((l) => ChoiceChip(
                      label: Text(l),
                      selected: _location == l,
                      onSelected: (_) => setState(() => _location = l),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text('和谁在一起？', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _socials
                .map((s) => ChoiceChip(
                      label: Text(s),
                      selected: _social == s,
                      onSelected: (_) => setState(() => _social = s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text('在做什么？', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _activities
                .map((a) => ChoiceChip(
                      label: Text(a),
                      selected: _activity == a,
                      onSelected: (_) => setState(() => _activity = a),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
