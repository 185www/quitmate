import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _references = [
    {
      'citation': 'Chaiton et al. (BMJ Open, 2016)',
      'detail': '平均需要6-30次尝试才能成功戒断 - 了解这一数据可以帮助减少对失败的恐惧，坚持尝试直至成功。',
    },
    {
      'citation': 'Prochaska & DiClemente (TTM Model)',
      'detail': '行为改变阶段理论 - 改变是一个渐进过程，包括前思考期、思考期、准备期、行动期和维持期五个阶段。',
    },
    {
      'citation': 'CDC (Centers for Disease Control and Prevention)',
      'detail': '戒烟后身体恢复时间线 - 停止使用后20分钟心率开始恢复正常，1年内冠心病风险降低50%。',
    },
    {
      'citation': 'Cochrane Database of Systematic Reviews',
      'detail': '认知行为疗法(CBT)的有效性 - CBT是帮助戒断最有效的心理干预方式之一，可显著提高戒断成功率。',
    },
    {
      'citation': 'USPSTF Guidelines',
      'detail': '美国预防服务工作组建议临床医生向所有成年烟草使用者提供戒烟咨询和行为干预。',
    },
    {
      'citation': 'Ussher et al. (Cochrane Review)',
      'detail': '运动可以减少50%的渴求强度 - 即使是短时间的中等强度运动也能有效减轻戒断症状和渴求感。',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.healing, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('QuitMate', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('版本 1.8.0', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  Text(
                    '科学戒断，重获自由',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('学术依据', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._references.map((ref) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_stories, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ref['citation']!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(ref['detail']!, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Text('免责声明', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '本应用仅作为健康管理辅助工具，不提供医疗诊断或治疗建议。'
                    '应用中的信息基于公开的医学研究和指南，但不能替代专业医疗建议。'
                    '如有健康问题，请咨询专业医疗人员。',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.privacy_tip, size: 18, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Text('隐私说明', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.tertiary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• 所有数据仅存储在本地设备\n'
                    '• 我们不收集、上传或分享任何个人数据\n'
                    '• 无需注册账号，无需网络连接即可使用\n'
                    '• 你可以随时导出或清除所有数据',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
