import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// PIPL 隐私协议同意页面 — 首次启动必弹，用户必须同意后方可使用应用
///
/// 遵循《中华人民共和国个人信息保护法》合规要求：
/// - 未经用户明确同意，不得展示任何应用功能
/// - "不同意"则退出应用
/// - 协议内容必须可完整阅读
class PiplConsentScreen extends StatefulWidget {
  final VoidCallback onConsent;

  const PiplConsentScreen({super.key, required this.onConsent});

  @override
  State<PiplConsentScreen> createState() => _PiplConsentScreenState();
}

class _PiplConsentScreenState extends State<PiplConsentScreen> {
  bool _agreed = false;
  bool _isConsenting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── 头部：应用标识 ──
            Padding(
              padding: const EdgeInsets.only(top: 48, bottom: 8),
              child: Icon(
                Icons.spa_rounded,
                size: 56,
                color: colorScheme.primary,
              ),
            ),
            Text(
              'QuitMate',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),

            // ── 标题 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '用户隐私协议',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 隐私协议内容（可滚动） ──
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context, '更新日期'),
                        _bodyText(context, '2025年1月1日'),
                        const SizedBox(height: 16),

                        _sectionTitle(context, '引言'),
                        _bodyText(
                          context,
                          '欢迎使用 QuitMate（以下简称"本应用"）。我们深知个人信息对您的重要性，'
                          '并会尽全力保护您的个人信息安全。我们致力于维持您对我们的信任，'
                          '恪守以下原则保护您的个人信息：权责一致原则、目的明确原则、'
                          '选择同意原则、最少够用原则、确保安全原则、主体参与原则、'
                          '公开透明原则等。',
                        ),
                        const SizedBox(height: 16),

                        _sectionTitle(context, '一、数据收集范围'),
                        _bodyText(
                          context,
                          '本应用是一款纯离线运行的戒烟戒酒干预工具。我们郑重声明：\n\n'
                          '• 本应用不会收集、上传或传输任何个人信息到任何远程服务器\n'
                          '• 您的所有数据均保存在您的设备本地\n'
                          '• 本应用不要求任何必须的网络权限\n'
                          '• 本应用不获取设备唯一标识符（IMEI、IDFA 等）\n'
                          '• 本应用不收集位置信息、通讯录、相册等敏感权限数据\n\n'
                          '本应用仅在您主动使用时记录以下本地数据：\n'
                          '• 戒烟/戒酒目标设置信息（目标类型、戒断日期、每日消耗量等）\n'
                          '• 依赖程度评估结果（Fagerström/AUDIT 量表得分）\n'
                          '• 每日心情与渴求记录\n'
                          '• 复发应对计划\n'
                          '• 游戏化激励数据（等级、经验值、成就）\n'
                          '• 健康自述数据（心率、睡眠、压力等自我报告）',
                        ),
                        const SizedBox(height: 16),

                        _sectionTitle(context, '二、数据用途'),
                        _bodyText(
                          context,
                          '您的数据仅用于以下目的：\n\n'
                          '• 提供戒烟戒酒干预功能的核心服务\n'
                          '• 个性化您的戒断进度追踪与统计\n'
                          '• 提供每日心情、渴求波动分析\n'
                          '• 生成周报/月报等健康分析报告\n'
                          '• 游戏化激励系统运行（经验值、等级、成就徽章）\n'
                          '• 复发预防计划的制定与管理\n'
                          '• 本地通知提醒功能的调度\n\n'
                          '我们不会将您的数据用于任何其他目的，也不会进行任何形式的用户画像或行为分析。',
                        ),
                        const SizedBox(height: 16),

                        _sectionTitle(context, '三、数据存储方式'),
                        _bodyText(
                          context,
                          '• 所有数据均使用 SQLite 数据库存储在您的设备本地\n'
                          '• 敏感个人信息（如用户偏好设置）采用 AES 加密存储\n'
                          '• 数据仅存在于您的设备上，卸载应用即永久删除所有数据\n'
                          '• 本应用不进行任何云端备份或同步\n'
                          '• 本应用不提供数据导出至第三方的功能',
                        ),
                        const SizedBox(height: 16),

                        _sectionTitle(context, '四、用户权利'),
                        _bodyText(
                          context,
                          '根据《个人信息保护法》，您享有以下权利：\n\n'
                          '• 查看权：您可在应用内随时查看您的所有个人数据\n'
                          '• 导出权：您可在"设置 > 数据导出"中导出您的全部数据\n'
                          '• 删除权：您可在"设置 > 清除数据"中删除您的全部数据\n'
                          '• 撤回同意权：您可随时卸载本应用以彻底清除所有数据\n'
                          '• 更正权：您可在应用内随时修改您的个人信息\n\n'
                          '如需行使以上权利，您可通过以下方式联系我们。',
                        ),
                        const SizedBox(height: 16),

                        _sectionTitle(context, '五、第三方 SDK 声明'),
                        _bodyText(
                          context,
                          '• 本应用不集成任何第三方数据分析 SDK（如友盟、极光、TalkingData 等）\n'
                          '• 本应用不集成任何广告 SDK\n'
                          '• 本应用不集成任何社会化分享 SDK\n'
                          '• 本应用不集成任何推送服务 SDK（通知均为系统本地调度）\n'
                          '• 本应用使用的 Flutter 框架本身不会收集用户数据',
                        ),
                        const SizedBox(height: 16),

                        _sectionTitle(context, '六、未成年人保护'),
                        _bodyText(
                          context,
                          '本应用的服务面向成年人。如果您是未满 18 周岁的未成年人，'
                          '请在监护人的陪同下阅读本协议，并在取得监护人同意后使用本应用。',
                        ),
                        const SizedBox(height: 16),

                        _sectionTitle(context, '七、隐私政策的变更'),
                        _bodyText(
                          context,
                          '我们可能会适时修订本隐私协议。当协议发生变更时，'
                          '我们会在应用内重新弹出隐私协议供您确认。'
                          '未经您的明确同意，我们不会依据修订后的隐私协议处理您的个人信息。',
                        ),
                        const SizedBox(height: 16),

                        _sectionTitle(context, '八、联系方式'),
                        _bodyText(
                          context,
                          '如果您对本隐私协议有任何疑问、意见或建议，请通过以下方式联系我们：\n\n'
                          '• 电子邮箱：privacy@quitmate.app\n'
                          '• 应用内反馈：设置 > 关于 > 意见反馈\n\n'
                          '我们将在收到您的请求后 15 个工作日内予以回复。',
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 同意勾选 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (value) {
                        setState(() => _agreed = value ?? false);
                      },
                      activeColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _agreed = !_agreed);
                      },
                      child: Text(
                        '我已阅读并同意以上《用户隐私协议》',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 底部按钮 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: [
                  // 同意并继续
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _agreed && !_isConsenting
                          ? _handleConsent
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        disabledBackgroundColor: isDark
                            ? colorScheme.primary.withOpacity(0.3)
                            : colorScheme.primary.withOpacity(0.5),
                        disabledForegroundColor: isDark
                            ? colorScheme.onPrimary.withOpacity(0.3)
                            : colorScheme.onPrimary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isConsenting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              '同意并继续',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 不同意
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: _handleDisagree,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant
                            .withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        '不同意',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConsent() async {
    setState(() => _isConsenting = true);
    // 短暂延迟以展示加载状态
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onConsent();
  }

  void _handleDisagree() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '确定要退出吗？',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '不同意隐私协议将无法使用应用',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              '再想想',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              SystemNavigator.pop();
            },
            child: Text(
              '确定退出',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
          letterSpacing: 0.02,
        ),
      ),
    );
  }

  Widget _bodyText(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.7,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.01,
      ),
    );
  }
}
