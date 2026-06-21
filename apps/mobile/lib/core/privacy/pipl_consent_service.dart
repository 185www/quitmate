import '../../data/database/app_database.dart';

/// PIPL 隐私同意服务 — 持久化用户隐私协议同意状态
///
/// 根据《中华人民共和国个人信息保护法》要求，应用首次启动时必须
/// 弹出隐私协议，用户明确同意后方可使用应用全部功能。
class PiplConsentService {
  static const _keyConsented = 'pipl_consented';
  static const _keyConsentVersion = 'pipl_consent_version';
  static const _keyConsentedAt = 'pipl_consented_at';
  static const _currentVersion = '1.0.0';

  final AppDatabase _db;

  PiplConsentService(this._db);

  /// 检查用户是否已同意当前版本的隐私协议
  Future<bool> hasConsented() async {
    final consented = await _db.getConfig(_keyConsented);
    final version = await _db.getConfig(_keyConsentVersion);
    return consented == 'true' && version == _currentVersion;
  }

  /// 记录用户同意隐私协议
  Future<void> setConsented() async {
    final now = DateTime.now().toIso8601String();
    await _db.setConfig(_keyConsented, 'true');
    await _db.setConfig(_keyConsentVersion, _currentVersion);
    await _db.setConfig(_keyConsentedAt, now);
  }
}
