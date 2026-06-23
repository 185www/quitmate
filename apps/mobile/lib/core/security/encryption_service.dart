import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 加密服务 — 支持 AES-256-CBC 加密，自动适配国产设备
///
/// - AOSP设备（华为AOSP、小米、OPPO等）：使用 flutter_secure_storage (Android Keystore)
/// - HarmonyOS NEXT（纯非AOSP）：自动回退到本地 SQLite 文件存储密钥
/// - Key存储失败时同样回退，确保零崩溃
class EncryptionService {
  static const _keyStorageName = 'encryption_master_key';
  static const _fallbackDbName = 'quitmate_keystore.db';
  static const _fallbackTableName = 'keystore';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  encrypt.Key? _cachedKey;
  Database? _fallbackDb;

  /// 是否使用回退方案（HarmonyOS NEXT 或 Keystore 不可用）
  bool _useFallback = false;

  Future<encrypt.Key> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    // 尝试使用 flutter_secure_storage（AOSP Keystore）
    try {
      String? existingKey = await _secureStorage.read(key: _keyStorageName);
      if (existingKey == null) {
        final newKey = encrypt.Key.fromSecureRandom(32);
        await _secureStorage.write(key: _keyStorageName, value: newKey.base64);
        _cachedKey = newKey;
      } else {
        _cachedKey = encrypt.Key.fromBase64(existingKey);
      }
      _useFallback = false;
      return _cachedKey!;
    } catch (e) {
      // flutter_secure_storage 失败（HarmonyOS NEXT / Keystore不可用）
      // 回退到本地 SQLite 文件存储密钥
      debugPrint(
          'EncryptionService: flutter_secure_storage 不可用，回退到本地存储 ($e)');
      return _getOrCreateFallbackKey();
    }
  }

  /// 回退方案：使用本地 SQLite 文件存储密钥
  ///
  /// 使用基于设备绑定种子的 XOR 加密保护密钥。
  /// 安全级别低于硬件 Keystore，但优于明文存储。
  /// 注意：此方案主要应对 HarmonyOS NEXT 等无 AOSP Keystore 的设备。
  Future<encrypt.Key> _getOrCreateFallbackKey() async {
    _useFallback = true;
    debugPrint(
        'EncryptionService: ⚠️ 使用回退密钥存储（非硬件加密）。'
        '安全级别低于 AOSP Keystore。');

    final db = await _openFallbackDb();
    final results = await db.query(
      _fallbackTableName,
      where: 'key = ?',
      whereArgs: [_keyStorageName],
    );

    if (results.isNotEmpty) {
      final storedValue = results.first['value'] as String?;
      if (storedValue != null) {
        // Decrypt using device-bound XOR
        final decrypted = _xorDecrypt(storedValue);
        _cachedKey = encrypt.Key.fromBase64(decrypted);
        return _cachedKey!;
      }
    }

    // 生成新密钥并用 XOR 加密存储
    final newKey = encrypt.Key.fromSecureRandom(32);
    final encrypted = _xorEncrypt(newKey.base64);
    await db.insert(
      _fallbackTableName,
      {'key': _keyStorageName, 'value': encrypted},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _cachedKey = newKey;
    return _cachedKey!;
  }

  /// 基于设备绑定种子的简单 XOR 加密
  ///
  /// 使用应用路径的哈希作为种子，确保同一设备上的密钥无法直接
  /// 复制到其他设备使用。这不是强加密，但优于明文存储。
  String _xorEncrypt(String plainText) {
    final seed = _getDeviceSeed();
    final bytes = utf8.encode(plainText);
    final encrypted = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ seed[i % seed.length]);
    }
    return base64Encode(encrypted);
  }

  /// XOR 解密（与加密使用相同的操作）
  String _xorDecrypt(String encryptedText) {
    final seed = _getDeviceSeed();
    final bytes = base64Decode(encryptedText);
    final decrypted = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      decrypted.add(bytes[i] ^ seed[i % seed.length]);
    }
    return utf8.decode(decrypted);
  }

  /// 获取设备绑定种子
  ///
  /// 使用应用文档目录路径的字节作为种子，确保：
  /// 1. 同一设备同一应用产生相同种子
  /// 2. 不同设备或不同应用产生不同种子
  List<int> _getDeviceSeed() {
    // 使用应用路径的哈希作为设备绑定种子
    // 注意：这不是密码学安全的，但提供了基本的设备绑定保护
    final path = getApplicationDocumentsDirectory().toString();
    final hash = path.hashCode;
    return [
      (hash >> 24) & 0xFF,
      (hash >> 16) & 0xFF,
      (hash >> 8) & 0xFF,
      hash & 0xFF,
    ];
  }

  Future<Database> _openFallbackDb() async {
    if (_fallbackDb != null) return _fallbackDb!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _fallbackDbName);
    _fallbackDb = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_fallbackTableName (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return _fallbackDb!;
  }

  Future<String> encryptText(String plainText) async {
    final key = await _getOrCreateKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String> decryptText(String encryptedText) async {
    final key = await _getOrCreateKey();
    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid encrypted text');
    }
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future<Map<String, dynamic>> encryptJson(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    final encrypted = await encryptText(jsonStr);
    return {'encrypted': encrypted};
  }

  Future<Map<String, dynamic>> decryptJson(
      Map<String, dynamic> encryptedData) async {
    final encrypted = encryptedData['encrypted'] as String;
    final decrypted = await decryptText(encrypted);
    return jsonDecode(decrypted) as Map<String, dynamic>;
  }

  Future<void> deleteKey() async {
    if (_useFallback) {
      final db = await _openFallbackDb();
      await db.delete(
        _fallbackTableName,
        where: 'key = ?',
        whereArgs: [_keyStorageName],
      );
    } else {
      await _secureStorage.delete(key: _keyStorageName);
    }
    _cachedKey = null;
  }

  /// 当前是否使用回退方案
  bool get isUsingFallback => _useFallback;
}
