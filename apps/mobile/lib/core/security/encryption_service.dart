import 'dart:convert';
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
  /// 安全级别低于 Keystore，但对于纯离线本地的偏好设置足够
  Future<encrypt.Key> _getOrCreateFallbackKey() async {
    _useFallback = true;
    final db = await _openFallbackDb();
    final results = await db.query(
      _fallbackTableName,
      where: 'key = ?',
      whereArgs: [_keyStorageName],
    );

    if (results.isNotEmpty) {
      final storedValue = results.first['value'] as String?;
      if (storedValue != null) {
        _cachedKey = encrypt.Key.fromBase64(storedValue);
        return _cachedKey!;
      }
    }

    // 生成新密钥
    final newKey = encrypt.Key.fromSecureRandom(32);
    await db.insert(
      _fallbackTableName,
      {'key': _keyStorageName, 'value': newKey.base64},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _cachedKey = newKey;
    return _cachedKey!;
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
