import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Encryption {
  final _storage = const FlutterSecureStorage();
  static const _keyStorage = 'encryption_key';

  Future<String> _getOrCreateKey() async {
    String? storedKey = await _storage.read(key: _keyStorage);
    if (storedKey == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      storedKey = base64Encode(key.bytes);
      await _storage.write(key: _keyStorage, value: storedKey);
    }
    return storedKey;
  }

  Future<void> initKey() async{
    await _getOrCreateKey();
  }

  Future<String> encryptText(String text) async {
    final key = encrypt.Key.fromBase64(await _getOrCreateKey());
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(text, iv: iv);
    return '${base64UrlEncode(iv.bytes)}:${encrypted.base64}';
  }

  Future<String> decryptText(String encryptedText) async {
    final parts = encryptedText.split(':');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);

    final key = encrypt.Key.fromBase64(await _getOrCreateKey());
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encryptedData, iv: iv);
  }
}