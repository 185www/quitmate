import 'dart:math';

import '../../domain/entity/user.dart';
import '../../domain/entity/daily_log.dart';
import '../sync/data_encryption.dart';

/// FHIR 数据导出器 — 将用户戒断数据转换为 FHIR 标准格式
///
/// 遵循 HL7 FHIR R4 标准，生成的资源包括：
/// - Patient: 最小化患者信息（年龄范围 + 性别，不含真实 PII）
/// - Observation: 渴望频率、情绪、冲动强度等观察数据
/// - Goal: 戒断目标
/// - Condition: 烟草/酒精使用障碍（ICD-10: F17/F10）
///
/// 适用于中国医疗机构的数据对接需求。
class FhirExporter {
  static const String _quitMateSystem =
      'https://quitmate.app/fhir';

  /// 生成唯一资源 ID
  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(999999);
    return 'qm-$now-$rand';
  }

  /// 导出为 FHIR 标准格式 JSON
  ///
  /// [data] 包含用户的所有戒断旅程数据。
  /// 返回完整的 FHIR Bundle 资源。
  Future<Map<String, dynamic>> exportToFhir(UserDataBundle data) async {
    final bundleId = _generateId();
    final entries = <Map<String, dynamic>>[];

    // 1. Patient 资源（最小化 — 仅年龄范围 + 性别，不含真实 PII）
    final patientResource = _buildPatientResource(data);
    entries.add({
      'fullUrl': 'urn:uuid:${patientResource['id']}',
      'resource': patientResource,
    });

    // 2. Condition 资源（烟草/酒精使用障碍）
    final conditionResource =
        _buildConditionResource(data, patientResource['id'] as String);
    entries.add({
      'fullUrl': 'urn:uuid:${conditionResource['id']}',
      'resource': conditionResource,
    });

    // 3. Goal 资源（戒断目标）
    final goalResource =
        _buildGoalResource(data, patientResource['id'] as String);
    entries.add({
      'fullUrl': 'urn:uuid:${goalResource['id']}',
      'resource': goalResource,
    });

    // 4. Observation 资源（渴望频率、情绪、冲动强度）
    final observations =
        _buildObservationResources(data, patientResource['id'] as String);
    for (final obs in observations) {
      entries.add({
        'fullUrl': 'urn:uuid:${obs['id']}',
        'resource': obs,
      });
    }

    return {
      'resourceType': 'Bundle',
      'id': bundleId,
      'type': 'collection',
      'meta': {
        'lastUpdated': DateTime.now().toIso8601String(),
        'profile': ['$_quitMateSystem/StructureDefinition/QuitJourneyBundle'],
      },
      'entry': entries,
    };
  }

  /// 导出为面向中国医疗机构的结构化报告
  ///
  /// 生成一份适合打印或 PDF 转换的结构化报告。
  Future<Map<String, dynamic>> exportAsReport(UserDataBundle data) async {
    final profile = data.userProfile;
    final cravings = data.cravingLogs;
    final dailyLogs = data.dailyLogs;

    // 计算统计数据
    final totalCravings = cravings.length;
    final resolvedCravings =
        cravings.where((c) => c['resolved'] == 1 || c['resolved'] == true).length;
    final avgIntensity = totalCravings > 0
        ? (cravings
                .map((c) => (c['intensity'] as num?)?.toInt() ?? 5)
                .reduce((a, b) => a + b) /
            totalCravings)
        : 0.0;
    final totalDays = dailyLogs.length;
    final relapseDays =
        dailyLogs.where((d) => d['relapsed'] == 1 || d['relapsed'] == true).length;
    final avgMood = totalDays > 0
        ? (dailyLogs
                .map((d) => (d['mood'] as num?)?.toInt() ?? 3)
                .reduce((a, b) => a + b) /
            totalDays)
        : 0.0;

    return {
      'reportType': 'quit_journey_report',
      'generatedAt': DateTime.now().toIso8601String(),
      'generator': 'QuitMate FHIR Exporter v3.2',
      'section': '戒断旅程报告',
      'patientInfo': {
        'ageRange': _inferAgeRange(profile),
        'gender': _inferGender(profile),
        'targetType': _targetTypeLabel(profile),
        'yearsOfUse': profile['years_of_use'],
        'assessmentScore': profile['target_type'] == 'smoking'
            ? profile['fagerstrom_score']
            : profile['audit_score'],
      },
      'summary': {
        'totalDaysRecorded': totalDays,
        'totalCravingsLogged': totalCravings,
        'resolvedCravings': resolvedCravings,
        'cravingResolutionRate':
            totalCravings > 0 ? (resolvedCravings / totalCravings * 100).toStringAsFixed(1) : '0.0',
        'relapseDays': relapseDays,
        'averageCravingIntensity': avgIntensity.toStringAsFixed(1),
        'averageMood': avgMood.toStringAsFixed(1),
      },
      'recommendation': _generateRecommendation(
          totalCravings, resolvedCravings, relapseDays, totalDays),
      'disclaimer': '本报告由 QuitMate 应用自动生成，仅供健康参考，不构成医疗诊断或治疗建议。',
    };
  }

  /// 导出为 CSV 格式（用于数据分析）
  ///
  /// [cravings] 渴望记录列表
  /// [logs] 每日日志列表
  Future<String> exportAsCsv(List<CravingEntry> cravings, List<DailyLogEntry> logs) async {
    final buffer = StringBuffer();

    // CSV 头 — 渴望记录
    buffer.writeln('类型,日期,时间,强度,触发因素,应对方式,是否解决');
    for (final c in cravings) {
      final date = c.timestamp.toIso8601String().substring(0, 10);
      final time = c.timestamp.toIso8601String().substring(11, 19);
      buffer.writeln(
          '渴望记录,$date,$time,${c.intensity},${c.trigger ?? ''},${c.copingUsed ?? ''},${c.resolved ? '是' : '否'}');
    }

    // CSV 头 — 每日日志
    buffer.writeln('');
    buffer.writeln('类型,日期,情绪评分,冲动强度,触发因素,应对方式,是否复发,消费量,备注');
    for (final d in logs) {
      final date = d.date.toIso8601String().substring(0, 10);
      final triggers = d.triggers?.join(';') ?? '';
      buffer.writeln(
          '每日记录,$date,${d.mood},${d.urgeLevel ?? ''},$triggers,${d.coping ?? ''},${d.relapsed ? '是' : '否'},${d.consumption ?? ''},${d.notes ?? ''}');
    }

    buffer.writeln('');
    buffer.writeln('本数据由 QuitMate 应用导出');
    buffer.writeln('导出时间: ${DateTime.now().toIso8601String()}');

    // 添加 BOM 头以便 Excel 正确识别 UTF-8
    return '\uFEFF${buffer.toString()}';
  }

  /// 构建最小化 Patient 资源
  Map<String, dynamic> _buildPatientResource(UserDataBundle data) {
    final profile = data.userProfile;
    final id = _generateId();

    return {
      'resourceType': 'Patient',
      'id': id,
      'meta': {
        'profile': ['$_quitMateSystem/StructureDefinition/AnonymizedPatient'],
      },
      'text': {
        'status': 'generated',
        'div': '<div xmlns="http://www.w3.org/1999/xhtml">匿名患者（年龄范围: ${_inferAgeRange(profile)}）</div>',
      },
      'gender': _inferGender(profile),
      'extension': [
        {
          'url': '$_quitMateSystem/StructureDefinition/age-range',
          'valueString': _inferAgeRange(profile),
        },
        {
          'url': '$_quitMateSystem/StructureDefinition/years-of-use',
          'valueInteger': profile['years_of_use'] as int?,
        },
      ],
    };
  }

  /// 构建 Condition 资源（烟草/酒精使用障碍）
  Map<String, dynamic> _buildConditionResource(
      UserDataBundle data, String patientId) {
    final profile = data.userProfile;
    final targetType = profile['target_type'] as String? ?? 'smoking';
    final id = _generateId();

    // ICD-10 编码：F17 = 烟草使用障碍, F10 = 酒精使用障碍
    final (code, display) = targetType == 'alcohol'
        ? ('F10', '酒精使用障碍')
        : ('F17', '烟草使用障碍');

    return {
      'resourceType': 'Condition',
      'id': id,
      'clinicalStatus': {
        'coding': [
          {'system': 'http://terminology.hl7.org/CodeSystem/condition-clinical', 'code': 'active'}
        ],
      },
      'verificationStatus': {
        'coding': [
          {'system': 'http://terminology.hl7.org/CodeSystem/condition-ver-status', 'code': 'unconfirmed'}
        ],
      },
      'code': {
        'coding': [
          {'system': 'http://hl7.org/fhir/icd-10', 'code': code, 'display': display},
        ],
        'text': display,
      },
      'subject': {'reference': 'urn:uuid:$patientId'},
      'onsetDateTime': data.userProfile['created_at'],
      'note': [
        {
          'text': '数据来源于 QuitMate 应用自我报告评估，'
              'Fagerström/AUDIT 评分: ${targetType == 'alcohol' ? profile['audit_score'] : profile['fagerstrom_score']}',
        },
      ],
    };
  }

  /// 构建 Goal 资源（戒断目标）
  Map<String, dynamic> _buildGoalResource(
      UserDataBundle data, String patientId) {
    final profile = data.userProfile;
    final targetType = profile['target_type'] as String? ?? 'smoking';
    final id = _generateId();

    final description = targetType == 'alcohol' ? '戒除酒精依赖' : '戒烟';

    return {
      'resourceType': 'Goal',
      'id': id,
      'lifecycleStatus': 'active',
      'description': {
        'text': description,
      },
      'subject': {'reference': 'urn:uuid:$patientId'},
      'target': [
        {
          'measure': {
            'text': '连续无使用天数',
          },
          'detailQuantity': {
            'value': profile['quit_date'] != null
                ? _calculateDaysSince(profile['quit_date'] as String)
                : 0,
            'unit': '天',
          },
        },
      ],
      'startDate': profile['quit_date'],
    };
  }

  /// 构建 Observation 资源列表
  List<Map<String, dynamic>> _buildObservationResources(
      UserDataBundle data, String patientId) {
    final observations = <Map<String, dynamic>>[];

    // 每日日志 → 情绪观察
    for (final log in data.dailyLogs) {
      final id = _generateId();
      observations.add({
        'resourceType': 'Observation',
        'id': id,
        'status': 'final',
        'category': [
          {
            'coding': [
              {
                'system': 'http://terminology.hl7.org/CodeSystem/observation-category',
                'code': 'survey',
                'display': '调查问卷',
              },
            ],
          },
        ],
        'code': {
          'coding': [
            {
              'system': '$_quitMateSystem/CodeSystem/quitmate-obs',
              'code': 'daily-mood',
              'display': '每日情绪评分',
            },
          ],
          'text': '每日情绪评分',
        },
        'subject': {'reference': 'urn:uuid:$patientId'},
        'effectiveDateTime': log['date'],
        'valueQuantity': {
          'value': log['mood'] as int? ?? 3,
          'unit': '分',
          'system': 'http://unitsofmeasure.org',
          'code': '{score}',
        },
      });

      // 冲动强度观察
      if (log['urge_level'] != null) {
        final urgeId = _generateId();
        observations.add({
          'resourceType': 'Observation',
          'id': urgeId,
          'status': 'final',
          'category': [
            {
              'coding': [
                {
                  'system': 'http://terminology.hl7.org/CodeSystem/observation-category',
                  'code': 'survey',
                  'display': '调查问卷',
                },
              ],
            },
          ],
          'code': {
            'coding': [
              {
                'system': '$_quitMateSystem/CodeSystem/quitmate-obs',
                'code': 'urge-level',
                'display': '冲动强度',
              },
            ],
            'text': '每日冲动强度',
          },
          'subject': {'reference': 'urn:uuid:$patientId'},
          'effectiveDateTime': log['date'],
          'valueQuantity': {
            'value': log['urge_level'] as int? ?? 0,
            'unit': '分',
            'system': 'http://unitsofmeasure.org',
            'code': '{score}',
          },
        });
      }
    }

    // 渴望记录 → 渴望强度观察
    for (final craving in data.cravingLogs) {
      final id = _generateId();
      observations.add({
        'resourceType': 'Observation',
        'id': id,
        'status': 'final',
        'category': [
          {
            'coding': [
              {
                'system': 'http://terminology.hl7.org/CodeSystem/observation-category',
                'code': 'survey',
                'display': '调查问卷',
              },
            ],
          },
        ],
        'code': {
          'coding': [
            {
              'system': '$_quitMateSystem/CodeSystem/quitmate-obs',
              'code': 'craving-intensity',
              'display': '渴望强度',
            },
          ],
          'text': '渴望强度记录',
        },
        'subject': {'reference': 'urn:uuid:$patientId'},
        'effectiveDateTime': craving['timestamp'],
        'valueQuantity': {
          'value': craving['intensity'] as int? ?? 5,
          'unit': '分',
          'system': 'http://unitsofmeasure.org',
          'code': '{score}',
        },
        'note': [
          {
            'text': '触发因素: ${craving['trigger'] ?? '未记录'}，'
                '应对方式: ${craving['coping_used'] ?? '未记录'}，'
                '是否解决: ${craving['resolved'] == 1 || craving['resolved'] == true ? '是' : '否'}',
          },
        ],
      });
    }

    return observations;
  }

  /// 推断年龄范围
  String _inferAgeRange(Map<String, dynamic> profile) {
    final yearsOfUse = profile['years_of_use'] as int?;
    if (yearsOfUse == null) return '未提供';
    if (yearsOfUse <= 5) return '20-30岁';
    if (yearsOfUse <= 15) return '25-45岁';
    if (yearsOfUse <= 25) return '35-55岁';
    return '45-70岁';
  }

  /// 推断性别（从偏好设置中获取，默认未知）
  String _inferGender(Map<String, dynamic> profile) {
    // 偏好设置中的性别信息可能是加密的，默认返回未知
    return 'unknown';
  }

  /// 获取目标类型标签
  String _targetTypeLabel(Map<String, dynamic> profile) {
    final targetType = profile['target_type'] as String? ?? 'smoking';
    switch (targetType) {
      case 'alcohol':
        return '酒精';
      case 'both':
        return '烟草+酒精';
      default:
        return '烟草';
    }
  }

  /// 计算自某日期以来的天数
  int _calculateDaysSince(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day)
          .difference(DateTime(date.year, date.month, date.day))
          .inDays;
    } catch (_) {
      return 0;
    }
  }

  /// 生成建议文字
  String _generateRecommendation(int totalCravings, int resolvedCravings,
      int relapseDays, int totalDays) {
    final rate = totalCravings > 0 ? resolvedCravings / totalCravings : 1.0;
    final relapseRate = totalDays > 0 ? relapseDays / totalDays : 0.0;

    if (rate >= 0.8 && relapseRate < 0.1) {
      return '戒断进展良好。渴望管理能力较强，建议继续保持当前策略。';
    } else if (rate >= 0.6 && relapseRate < 0.2) {
      return '戒断进展稳步推进。建议加强应对策略的学习，关注高触发场景。';
    } else if (relapseRate >= 0.3) {
      return '近期复发频率较高，建议寻求专业医疗支持或调整戒断计划。';
    } else {
      return '戒断过程中存在一定挑战，建议结合专业指导持续优化应对策略。';
    }
  }
}
