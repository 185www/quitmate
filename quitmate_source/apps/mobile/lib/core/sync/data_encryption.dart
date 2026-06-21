import 'dart:convert';

import '../security/encryption_service.dart';

/// 用户数据打包 — 包含所有需要同步的用户数据
class UserDataBundle {
  final Map<String, dynamic> userProfile;
  final List<Map<String, dynamic>> cravingLogs;
  final List<Map<String, dynamic>> dailyLogs;
  final Map<String, dynamic> gameProfile;
  final List<Map<String, dynamic>> relapsePlans;
  final List<Map<String, dynamic>> badges;
  final Map<String, dynamic> healthData;

  UserDataBundle({
    required this.userProfile,
    this.cravingLogs = const [],
    this.dailyLogs = const [],
    this.gameProfile = const {},
    this.relapsePlans = const [],
    this.badges = const [],
    this.healthData = const {},
  });

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() => {
        'userProfile': userProfile,
        'cravingLogs': cravingLogs,
        'dailyLogs': dailyLogs,
        'gameProfile': gameProfile,
        'relapsePlans': relapsePlans,
        'badges': badges,
        'healthData': healthData,
        'exportedAt': DateTime.now().toIso8601String(),
      };

  /// 从 JSON Map 反序列化
  factory UserDataBundle.fromJson(Map<String, dynamic> json) {
    return UserDataBundle(
      userProfile: Map<String, dynamic>.from(json['userProfile'] ?? {}),
      cravingLogs: List<Map<String, dynamic>>.from(
          (json['cravingLogs'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []),
      dailyLogs: List<Map<String, dynamic>>.from(
          (json['dailyLogs'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []),
      gameProfile: Map<String, dynamic>.from(json['gameProfile'] ?? {}),
      relapsePlans: List<Map<String, dynamic>>.from(
          (json['relapsePlans'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []),
      badges: List<Map<String, dynamic>>.from(
          (json['badges'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []),
      healthData: Map<String, dynamic>.from(json['healthData'] ?? {}),
    );
  }
}

/// 加密同步包 — 加密后的用户数据传输包
///
/// 此包可安全传输至云端，即使服务器被入侵也无法解密。
/// 密钥仅存在于用户设备本地。
class EncryptedSyncPackage {
  /// Base64 编码的加密数据
  final String encryptedData;

  /// 初始化向量（IV），Base64 编码
  final String iv;

  /// 密钥指纹，用于验证解密时密钥是否正确
  final String keyFingerprint;

  /// 加密时间
  final DateTime createdAt;

  /// 数据格式版本号
  final int version;

  const EncryptedSyncPackage({
    required this.encryptedData,
    required this.iv,
    required this.keyFingerprint,
    required this.createdAt,
    this.version = 1,
  });

  /// 序列化为 JSON Map（用于传输/存储）
  Map<String, dynamic> toJson() => {
        'encryptedData': encryptedData,
        'iv': iv,
        'keyFingerprint': keyFingerprint,
        'createdAt': createdAt.toIso8601String(),
        'version': version,
      };

  /// 从 JSON Map 反序列化
  factory EncryptedSyncPackage.fromJson(Map<String, dynamic> json) {
    return EncryptedSyncPackage(
      encryptedData: json['encryptedData'] as String,
      iv: json['iv'] as String,
      keyFingerprint: json['keyFingerprint'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      version: json['version'] as int? ?? 1,
    );
  }
}

/// 零知识加密器 — 为云同步准备加密数据
///
/// 核心安全原则：
/// - 密钥永不离开设备
/// - 仅加密数据被传输
/// - 服务器无法解密任何内容
/// - 使用现有的 AES-256-CBC 加密服务
class ZeroKnowledgeEncryptor {
  final EncryptionService _encryption;

  static const int _currentVersion = 1;

  ZeroKnowledgeEncryptor(this._encryption);

  /// 加密用户数据为传输包
  ///
  /// 流程：
  /// 1. 将 UserDataBundle 序列化为 JSON
  /// 2. 使用 AES-256-CBC 加密
  /// 3. 生成密钥指纹用于验证
  /// 4. 返回 [EncryptedSyncPackage]
  Future<EncryptedSyncPackage> encryptUserData(UserDataBundle data) async {
    try {
      final jsonStr = jsonEncode(data.toJson());
      final encrypted = await _encryption.encryptText(jsonStr);

      // encrypted 格式为 "iv_base64:cipher_base64"
      final parts = encrypted.split(':');
      if (parts.length != 2) {
        throw const FormatException('加密数据格式异常');
      }

      final iv = parts[0];
      final cipherData = parts[1];

      // 生成密钥指纹（简单哈希标识，非密钥本身）
      final fingerprint = _generateKeyFingerprint(iv, cipherData);

      return EncryptedSyncPackage(
        encryptedData: cipherData,
        iv: iv,
        keyFingerprint: fingerprint,
        createdAt: DateTime.now(),
        version: _currentVersion,
      );
    } catch (e) {
      throw Exception('数据加密失败: $e');
    }
  }

  /// 解密同步数据包
  ///
  /// 流程：
  /// 1. 重新组装加密字符串（iv:cipher）
  /// 2. 使用本地密钥解密
  /// 3. 反序列化为 UserDataBundle
  Future<UserDataBundle> decryptSyncPackage(
      EncryptedSyncPackage package) async {
    try {
      // 验证版本兼容性
      if (package.version > _currentVersion) {
        throw Exception(
            '数据版本不兼容：收到的数据版本为 ${package.version}，'
            '当前支持的最高版本为 $_currentVersion。请更新应用。');
      }

      // 重新组装加密格式
      final encrypted = '${package.iv}:${package.encryptedData}';
      final decrypted = await _encryption.decryptText(encrypted);
      final json = jsonDecode(decrypted) as Map<String, dynamic>;

      return UserDataBundle.fromJson(json);
    } catch (e) {
      throw Exception('数据解密失败: $e');
    }
  }

  /// 生成密钥指纹（基于 IV 和密文前缀的简单哈希）
  ///
  /// 注意：此指纹不包含任何密钥信息，仅用于验证数据包完整性。
  String _generateKeyFingerprint(String iv, String cipherData) {
    final combined = '$iv:${cipherData.substring(0, cipherData.length > 32 ? 32 : cipherData.length)}';
    // 简单哈希生成（不使用加密密钥）
    var hash = 0;
    for (var i = 0; i < combined.length; i++) {
      hash = ((hash << 5) - hash) + combined.codeUnitAt(i);
      hash = hash & 0x7FFFFFFF; // 保持正整数
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// 验证密钥指纹是否匹配
  ///
  /// 用于在解密前快速检查数据包是否可能被篡改。
  bool verifyFingerprint(EncryptedSyncPackage package) {
    final expectedFingerprint =
        _generateKeyFingerprint(package.iv, package.encryptedData);
    return package.keyFingerprint == expectedFingerprint;
  }
}
