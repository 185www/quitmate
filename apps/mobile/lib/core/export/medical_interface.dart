/// 匿名化报告 — 仅包含聚合统计数据，不含任何个人数据
///
/// 此报告可用于研究机构获取宏观统计信息，
/// 所有个人可识别信息已被完全移除。
class AnonymizedReport {
  /// 总用户数（统计计数，非真实用户列表）
  final int totalUsers;

  /// 平均戒断持续天数
  final double averageQuitDuration;

  /// 平均成功率（百分比）
  final double averageSuccessRate;

  /// 跨理论模型（TTM）阶段分布
  final Map<String, int> stageDistribution;

  /// 报告生成时间
  final DateTime generatedAt;

  const AnonymizedReport({
    required this.totalUsers,
    required this.averageQuitDuration,
    required this.averageSuccessRate,
    required this.stageDistribution,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'totalUsers': totalUsers,
        'averageQuitDuration': averageQuitDuration,
        'averageSuccessRate': averageSuccessRate,
        'stageDistribution': stageDistribution,
        'generatedAt': generatedAt.toIso8601String(),
        'disclaimer': '本报告完全匿名化，不包含任何个人可识别信息。',
      };
}

/// 医疗机构接口 — 医疗/研究机构访问匿名化数据的抽象接口
///
/// 设计原则：
/// - 宏观报告完全匿名化，不含任何个人数据
/// - 个人数据导出需要用户每次明确同意
/// - 遵守《个人信息保护法》（PIPL）相关规定
/// - 默认实现返回占位数据，真实实现需连接服务器
abstract class MedicalInterface {
  /// 生成宏观匿名报告（完全匿名化，不含个人数据）
  ///
  /// 此接口仅返回聚合统计信息，适用于研究机构获取群体趋势。
  /// 所有个人可识别信息已被完全移除。
  Future<AnonymizedReport> generateMacroReport();

  /// 导出个人数据（需要用户每次明确同意）
  ///
  /// [format] 导出格式：'fhir'（FHIR JSON）、'csv'（CSV 表格）、'report'（结构化报告）
  /// [includeCravings] 是否包含渴望记录
  /// [includeDailyLogs] 是否包含每日日志
  ///
  /// 返回对应格式的数据。FHIR 和 report 返回 Map，CSV 返回包含 'csv' 键的 Map。
  Future<Map<String, dynamic>> exportIndividualData({
    required String format,
    required bool includeCravings,
    required bool includeDailyLogs,
  });
}

/// 本地默认医疗接口实现 — 返回占位/示例数据
///
/// 此实现不连接任何远程服务，所有数据来源于本地。
/// 适用于完全离线使用的场景。
class LocalMedicalInterface implements MedicalInterface {
  LocalMedicalInterface();

  @override
  Future<AnonymizedReport> generateMacroReport() async {
    // 本地模式：无法获取多用户聚合数据，返回占位报告
    return AnonymizedReport(
      totalUsers: 1, // 仅当前用户
      averageQuitDuration: 0.0,
      averageSuccessRate: 0.0,
      stageDistribution: {
        '前意向阶段': 0,
        '意向阶段': 0,
        '准备阶段': 0,
        '行动阶段': 0,
        '维持阶段': 0,
      },
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<Map<String, dynamic>> exportIndividualData({
    required String format,
    required bool includeCravings,
    required bool includeDailyLogs,
  }) async {
    switch (format) {
      case 'fhir':
        // FHIR 导出需要完整数据包，本地模式返回空 bundle
        return {
          'resourceType': 'Bundle',
          'id': 'local-placeholder',
          'type': 'collection',
          'entry': [],
          'message': '本地模式：请提供 UserDataBundle 以生成完整 FHIR 数据。',
        };

      case 'csv':
        // CSV 导出
        const csvHeader =
            '\uFEFF类型,日期,时间,强度,触发因素,应对方式,是否解决\n';
        return {
          'csv': csvHeader,
          'message': '本地模式：请提供 CravingEntry 和 DailyLogEntry 列表以生成完整 CSV 数据。',
        };

      case 'report':
        // 结构化报告
        return {
          'reportType': 'quit_journey_report',
          'generatedAt': DateTime.now().toIso8601String(),
          'generator': 'QuitMate LocalMedicalInterface',
          'message': '本地模式：请提供 UserDataBundle 以生成完整报告。',
          'section': '戒断旅程报告（本地模式）',
          'disclaimer': '本报告由 QuitMate 应用本地模式生成，仅供健康参考，不构成医疗诊断或治疗建议。',
        };

      default:
        throw ArgumentError('不支持的导出格式: $format。支持格式: fhir, csv, report');
    }
  }
}
