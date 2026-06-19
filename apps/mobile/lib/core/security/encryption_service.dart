import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _keyStorageName = 'encryption_master_key';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  encrypt.Key? _cachedKey;

  Future<encrypt.Key> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;
    String? existingKey = await _secureStorage.read(key: _keyStorageName);
    if (existingKey == null) {
      final newKey = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(key: _keyStorageName, value: newKey.base64);
      _cachedKey = newKey;
    } else {
      _cachedKey = encrypt.Key.fromBase64(existingKey);
    }
    return _cachedKey!;
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
    if (parts.length != 2)
      throw const FormatException('Invalid encrypted text');
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
    await _secureStorage.delete(key: _keyStorageName);
    _cachedKey = null;
  }
}
