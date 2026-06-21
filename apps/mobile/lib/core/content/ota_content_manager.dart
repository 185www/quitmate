import 'dart:convert';

import '../../data/database/app_database.dart';

/// 内容更新包 — OTA 内容更新的数据载体
class ContentUpdatePackage {
  /// 版本号（语义化版本，如 "1.2.0"）
  final String version;

  /// 目标内容类型
  final String targetContentType; // 'community_stories', 'exercises', 'assessments'

  /// 内容条目列表
  final List<Map<String, dynamic>> items;

  /// 发布日期
  final DateTime releaseDate;

  /// 更新说明
  final String releaseNotes;

  const ContentUpdatePackage({
    required this.version,
    required this.targetContentType,
    required this.items,
    required this.releaseDate,
    this.releaseNotes = '',
  });

  factory ContentUpdatePackage.fromJson(Map<String, dynamic> json) {
    return ContentUpdatePackage(
      version: json['version'] as String,
      targetContentType: json['targetContentType'] as String,
      items: List<Map<String, dynamic>>.from(
          (json['items'] as List).map((e) => Map<String, dynamic>.from(e as Map))),
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      releaseNotes: json['releaseNotes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'targetContentType': targetContentType,
        'items': items,
        'releaseDate': releaseDate.toIso8601String(),
        'releaseNotes': releaseNotes,
      };
}

/// 内容包信息 — 描述一个可用的内容包
class ContentPackInfo {
  /// 内容包唯一标识
  final String id;

  /// 内容包名称
  final String name;

  /// 内容包描述
  final String description;

  /// 条目数量
  final int itemCount;

  /// 当前安装的版本
  final String version;

  /// 是否已安装
  final bool installed;

  const ContentPackInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.itemCount,
    required this.version,
    this.installed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'itemCount': itemCount,
        'version': version,
        'installed': installed,
      };
}

/// OTA 内容管理器 — 空中内容更新系统
///
/// 当前为本地模式（不连接远程服务器），
/// 所有内容元数据存储在 app_config 表中。
/// 未来可扩展为连接自托管服务器获取内容更新。
///
/// 支持的内容类型：
/// - community_stories: 社区互助故事
/// - exercises: CBT/CET 练习内容
/// - assessments: 评估量表内容
class OtaContentManager {
  final AppDatabase _db;

  /// 配置键前缀
  static const String _configPrefix = 'ota_content_';
  static const String _versionKey = '${_configPrefix}version';
  static const String _packPrefix = '${_configPrefix}pack_';
  static const String _contentPrefix = '${_configPrefix}data_';

  /// 内置内容包定义（本地模式下的默认内容）
  static const List<Map<String, dynamic>> _builtInPacks = [
    {
      'id': 'builtin_community_stories',
      'name': '内置互助故事',
      'description': '应用内置的社区互助故事集合',
      'contentType': 'community_stories',
      'version': '1.0.0',
    },
    {
      'id': 'builtin_exercises',
      'name': '内置练习库',
      'description': '应用内置的 CBT/CET 练习内容',
      'contentType': 'exercises',
      'version': '1.0.0',
    },
    {
      'id': 'builtin_assessments',
      'name': '内置评估量表',
      'description': '应用内置的依赖评估量表',
      'contentType': 'assessments',
      'version': '1.0.0',
    },
  ];

  OtaContentManager(this._db);

  /// 获取当前内容版本
  ///
  /// 从 app_config 表中读取版本号。
  /// 如果未设置过版本，返回默认值 "1.0.0"。
  Future<String> getContentVersion() async {
    final version = await _db.getConfig(_versionKey);
    return version ?? '1.0.0';
  }

  /// 检查是否有内容更新可用
  ///
  /// 本地模式下始终返回 false（无远程服务器）。
  /// 未来实现可连接服务器检查最新版本。
  Future<bool> hasUpdateAvailable() async {
    // 本地模式：无远程服务器，始终无更新
    return false;
  }

  /// 应用内容更新
  ///
  /// 将内容更新包中的数据写入 app_config 表。
  /// 此方法可用于：
  /// - 从文件导入内容更新
  /// - 未来从服务器下载后应用
  ///
  /// 流程：
  /// 1. 验证版本号（新版本必须大于当前版本）
  /// 2. 存储内容条目到配置表
  /// 3. 更新内容包信息
  /// 4. 更新全局版本号
  Future<void> applyUpdate(ContentUpdatePackage update) async {
    // 1. 验证版本
    final currentVersion = await getContentVersion();
    if (!_isNewerVersion(update.version, currentVersion)) {
      throw Exception(
          '内容版本不合法：更新版本 ${update.version} 不高于当前版本 $currentVersion');
    }

    // 2. 存储内容条目
    final contentKey = '$_contentPrefix${update.targetContentType}';
    final contentJson = jsonEncode({
      'version': update.version,
      'items': update.items,
      'releaseDate': update.releaseDate.toIso8601String(),
      'releaseNotes': update.releaseNotes,
      'appliedAt': DateTime.now().toIso8601String(),
    });
    await _db.setConfig(contentKey, contentJson);

    // 3. 更新内容包信息
    final packKey =
        '$_packPrefix${update.targetContentType}';
    final packInfo = jsonEncode({
      'id': 'ota_${update.targetContentType}',
      'name': _contentTypeLabel(update.targetContentType),
      'description': 'OTA 更新的 ${_contentTypeLabel(update.targetContentType)} 内容',
      'itemCount': update.items.length,
      'version': update.version,
      'installed': true,
    });
    await _db.setConfig(packKey, packInfo);

    // 4. 更新全局版本号
    await _db.setConfig(_versionKey, update.version);
  }

  /// 获取所有可用内容包信息
  ///
  /// 返回内置内容包和已安装的 OTA 内容包信息。
  Future<List<ContentPackInfo>> getAvailablePacks() async {
    final packs = <ContentPackInfo>[];

    // 添加内置内容包
    for (final pack in _builtInPacks) {
      packs.add(ContentPackInfo(
        id: pack['id'] as String,
        name: pack['name'] as String,
        description: pack['description'] as String,
        itemCount: 0, // 内置包数量需从 ContentLoader 获取
        version: pack['version'] as String,
        installed: true,
      ));
    }

    // 检查已安装的 OTA 内容包
    for (final contentType in ['community_stories', 'exercises', 'assessments']) {
      final packKey = '$_packPrefix$contentType';
      final packJson = await _db.getConfig(packKey);
      if (packJson != null) {
        try {
          final packData = jsonDecode(packJson) as Map<String, dynamic>;
          // 检查是否已在列表中（避免重复）
          final exists = packs.any((p) => p.id == packData['id']);
          if (!exists) {
            packs.add(ContentPackInfo(
              id: packData['id'] as String,
              name: packData['name'] as String,
              description: packData['description'] as String,
              itemCount: packData['itemCount'] as int? ?? 0,
              version: packData['version'] as String,
              installed: packData['installed'] as bool? ?? true,
            ));
          }
        } catch (_) {
          // 忽略解析错误
        }
      }
    }

    return packs;
  }

  /// 获取指定内容类型的数据
  ///
  /// 从 app_config 表中读取已缓存的内容数据。
  /// 如果没有找到，返回 null。
  Future<List<Map<String, dynamic>>?> getContentData(
      String contentType) async {
    final contentKey = '$_contentPrefix$contentType';
    final contentJson = await _db.getConfig(contentKey);
    if (contentJson == null) return null;

    try {
      final content = jsonDecode(contentJson) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(
          (content['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (_) {
      return null;
    }
  }

  /// 比较版本号
  ///
  /// 返回 true 如果 [newVersion] 比 [currentVersion] 更新。
  bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      // 补齐长度
      while (newParts.length < 3) newParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (var i = 0; i < 3; i++) {
        if (newParts[i] > currentParts[i]) return true;
        if (newParts[i] < currentParts[i]) return false;
      }
      // 版本相同，不算更新
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 内容类型中文标签
  String _contentTypeLabel(String contentType) {
    switch (contentType) {
      case 'community_stories':
        return '社区故事';
      case 'exercises':
        return '练习内容';
      case 'assessments':
        return '评估量表';
      default:
        return contentType;
    }
  }
}
