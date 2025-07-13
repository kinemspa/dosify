import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyTag = 'encryption_key';
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;

  // Initialize encryption
  Future<void> initialize() async {
    String? storedKey = await _storage.read(key: _keyTag);
    if (storedKey == null) {
      // Generate new key if none exists
      final key = encrypt.Key.fromSecureRandom(32);
      await _storage.write(key: _keyTag, value: base64.encode(key.bytes));
      storedKey = base64.encode(key.bytes);
    }

    final key = encrypt.Key(base64.decode(storedKey));
    _iv = encrypt.IV.fromSecureRandom(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  // Encrypt sensitive data
  String encryptData(String data) {
    return _encrypter.encrypt(data, iv: _iv).base64;
  }

  // Decrypt sensitive data
  String decryptData(String encryptedData) {
    final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  // Hash sensitive data (for searching/indexing)
  String hashData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  // Encrypt medication details
  Map<String, dynamic> encryptMedicationData(Map<String, dynamic> medicationData) {
    return {
      'name': encryptData(medicationData['name']),
      'nameHash': hashData(medicationData['name']), // For searching
      'strength': encryptData(medicationData['strength'].toString()),
      'type': medicationData['type'], // Non-sensitive enum
      'quantity': encryptData(medicationData['quantity'].toString()),
      // Add other fields as needed
    };
  }

  // Decrypt medication details
  Map<String, dynamic> decryptMedicationData(Map<String, dynamic> encryptedData) {
    return {
      'name': decryptData(encryptedData['name']),
      'strength': double.parse(decryptData(encryptedData['strength'])),
      'type': encryptedData['type'],
      'quantity': double.parse(decryptData(encryptedData['quantity'])),
      // Add other fields as needed
    };
  }
} 