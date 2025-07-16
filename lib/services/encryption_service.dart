import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for handling data encryption and decryption using AES-256
class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  static const _keyTag = 'encryption_key';
  static const _ivTag = 'encryption_iv';
  bool _isInitialized = false;
  
  crypto.Encrypter? _encrypter;
  late crypto.IV _iv;

  /// Initialize encryption with secure key generation
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _log('Initializing encryption service');
      
      // Generate or retrieve encryption key
      final keyString = await _getOrGenerateKey();
      final key = crypto.Key.fromBase64(keyString);
      
      // Generate or retrieve IV
      final ivString = await _getOrGenerateIV();
      _iv = crypto.IV.fromBase64(ivString);
      
      // Initialize encrypter with AES-256-CBC
      _encrypter = crypto.Encrypter(crypto.AES(key, mode: crypto.AESMode.cbc));
      
      _isInitialized = true;
      _log('Encryption service initialized successfully');
    } catch (e, stackTrace) {
      _logError('Error initializing encryption service', e, stackTrace);
      rethrow;
    }
  }
  
  /// Generate or retrieve encryption key from secure storage
  Future<String> _getOrGenerateKey() async {
    try {
      String? existingKey = await _storage.read(key: _keyTag);
      
      if (existingKey != null && existingKey.isNotEmpty) {
        _log('Retrieved existing encryption key from secure storage');
        return existingKey;
      }
      
      // Generate new 256-bit key
      final key = crypto.Key.fromSecureRandom(32);
      final keyString = key.base64;
      
      await _storage.write(key: _keyTag, value: keyString);
      _log('Generated and stored new encryption key');
      return keyString;
      
    } catch (e, stackTrace) {
      _logError('Error managing encryption key', e, stackTrace);
      rethrow;
    }
  }
  
  /// Generate or retrieve IV from secure storage
  Future<String> _getOrGenerateIV() async {
    try {
      String? existingIV = await _storage.read(key: _ivTag);
      
      if (existingIV != null && existingIV.isNotEmpty) {
        _log('Retrieved existing IV from secure storage');
        return existingIV;
      }
      
      // Generate new IV
      final iv = crypto.IV.fromSecureRandom(16);
      final ivString = iv.base64;
      
      await _storage.write(key: _ivTag, value: ivString);
      _log('Generated and stored new IV');
      return ivString;
      
    } catch (e, stackTrace) {
      _logError('Error managing IV', e, stackTrace);
      rethrow;
    }
  }
  
  /// Check if initialized and initialize if needed
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Encrypt sensitive data using AES-256
  Future<String> encrypt(String data) async {
    await _ensureInitialized();
    
    if (_encrypter == null) {
      throw Exception('Encryption service not properly initialized');
    }
    
    try {
      // Input validation
      if (data.isEmpty) {
        throw ArgumentError('Cannot encrypt empty data');
      }
      
      // Encrypt the data
      final encrypted = _encrypter!.encrypt(data, iv: _iv);
      return encrypted.base64;
      
    } catch (e, stackTrace) {
      _logError('Error encrypting data', e, stackTrace);
      rethrow;
    }
  }

  /// Decrypt sensitive data using AES-256
  Future<String> decrypt(String encryptedData) async {
    await _ensureInitialized();
    
    if (_encrypter == null) {
      throw Exception('Encryption service not properly initialized');
    }
    
    try {
      // Input validation
      if (encryptedData.isEmpty) {
        throw ArgumentError('Cannot decrypt empty data');
      }
      
      // Decrypt the data
      final encrypted = crypto.Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter!.decrypt(encrypted, iv: _iv);
      return decrypted;
      
    } catch (e, stackTrace) {
      _logError('Error decrypting data', e, stackTrace);
      rethrow;
    }
  }

  /// Hash sensitive data (for searching/indexing)
  String hashData(String data) {
    if (data.isEmpty) {
      return '';
    }
    
    try {
      return sha256.convert(utf8.encode(data)).toString();
    } catch (e, stackTrace) {
      _logError('Error hashing data', e, stackTrace);
      rethrow;
    }
  }
  
  /// Alias for encrypt for backward compatibility
  Future<String> encryptData(String data) async {
    return encrypt(data);
  }
  
  /// Alias for decrypt for backward compatibility
  Future<String> decryptData(String encryptedData) async {
    return decrypt(encryptedData);
  }

  /// Encrypt medication details with proper error handling
  Future<Map<String, dynamic>> encryptMedicationData(Map<String, dynamic> medicationData) async {
    await _ensureInitialized();
    
    try {
      Map<String, dynamic> encryptedData = {
        'type': medicationData['type'], // Non-sensitive enum
        'lastUpdate': DateTime.now().toIso8601String(),
      };
      
      // Encrypt the name
      if (medicationData.containsKey('name') && medicationData['name'] != null) {
        final nameStr = medicationData['name'].toString();
        encryptedData['name'] = await encrypt(nameStr);
        encryptedData['nameHash'] = hashData(nameStr); // For searching
      }
      
      // Encrypt numeric values
      for (String field in ['strength', 'tabletsInStock']) {
        if (medicationData.containsKey(field) && medicationData[field] != null) {
          encryptedData[field] = await encrypt(medicationData[field].toString());
        }
      }
      
      // Encrypt string values
      for (String field in ['strengthUnit', 'quantityUnit']) {
        if (medicationData.containsKey(field) && medicationData[field] != null) {
          encryptedData[field] = await encrypt(medicationData[field].toString());
        }
      }
      
      // Handle optional fields
      for (String field in ['reconstitutionVolume', 'reconstitutionVolumeUnit', 'concentrationAfterReconstitution']) {
        if (medicationData.containsKey(field) && medicationData[field] != null) {
          encryptedData[field] = await encrypt(medicationData[field].toString());
        }
      }
      
      return encryptedData;
      
    } catch (e, stackTrace) {
      _logError('Error encrypting medication data', e, stackTrace);
      rethrow;
    }
  }

  /// Decrypt medication details with proper error handling
  Future<Map<String, dynamic>> decryptMedicationData(Map<String, dynamic> encryptedData) async {
    await _ensureInitialized();
    
    try {
      Map<String, dynamic> decryptedData = {
        'type': encryptedData['type'], // Non-sensitive enum
        'lastUpdate': encryptedData['lastUpdate'],
      };
      
      // Decrypt name
      if (encryptedData.containsKey('name') && encryptedData['name'] != null) {
        decryptedData['name'] = await decrypt(encryptedData['name'].toString());
      }
      
      // Decrypt numeric values
      for (String field in ['strength', 'tabletsInStock']) {
        if (encryptedData.containsKey(field) && encryptedData[field] != null) {
          final decrypted = await decrypt(encryptedData[field].toString());
          decryptedData[field] = double.tryParse(decrypted) ?? 0.0;
        }
      }
      
      // Decrypt string values
      for (String field in ['strengthUnit', 'quantityUnit']) {
        if (encryptedData.containsKey(field) && encryptedData[field] != null) {
          decryptedData[field] = await decrypt(encryptedData[field].toString());
        }
      }
      
      // Handle optional fields
      for (String field in ['reconstitutionVolume', 'reconstitutionVolumeUnit', 'concentrationAfterReconstitution']) {
        if (encryptedData.containsKey(field) && encryptedData[field] != null) {
          final decrypted = await decrypt(encryptedData[field].toString());
          if (field == 'reconstitutionVolume' || field == 'concentrationAfterReconstitution') {
            decryptedData[field] = double.tryParse(decrypted);
          } else {
            decryptedData[field] = decrypted;
          }
        }
      }
      
      return decryptedData;
      
    } catch (e, stackTrace) {
      _logError('Error decrypting medication data', e, stackTrace);
      rethrow;
    }
  }
  
  /// Validate encrypted data integrity
  Future<bool> validateEncryptedData(String encryptedData) async {
    try {
      await decrypt(encryptedData);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Rotate encryption key (for security best practices)
  Future<void> rotateKeys() async {
    try {
      _log('Starting key rotation');
      
      // Generate new key and IV
      final newKey = crypto.Key.fromSecureRandom(32);
      final newIV = crypto.IV.fromSecureRandom(16);
      
      // Store new key and IV
      await _storage.write(key: _keyTag, value: newKey.base64);
      await _storage.write(key: _ivTag, value: newIV.base64);
      
      // Update encrypter
      _encrypter = crypto.Encrypter(crypto.AES(newKey, mode: crypto.AESMode.cbc));
      _iv = newIV;
      
      _log('Key rotation completed successfully');
    } catch (e, stackTrace) {
      _logError('Error during key rotation', e, stackTrace);
      rethrow;
    }
  }
  
  /// Clear all encryption keys (for testing or reset)
  Future<void> clearKeys() async {
    try {
      await _storage.delete(key: _keyTag);
      await _storage.delete(key: _ivTag);
      _isInitialized = false;
      _encrypter = null;
      _log('Encryption keys cleared');
    } catch (e, stackTrace) {
      _logError('Error clearing keys', e, stackTrace);
      rethrow;
    }
  }
  
  /// Get encryption status
  bool get isInitialized => _isInitialized;
  
  /// Logging for debugging (only in debug mode, sanitized)
  void _log(String message) {
    if (kDebugMode) {
      print('EncryptionService: $message');
    }
  }
  
  /// Error logging with stack trace (only in debug mode, sanitized)
  void _logError(String message, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('EncryptionService ERROR: $message');
      // Don't log the actual error details to prevent sensitive data exposure
      print('Error type: ${error.runtimeType}');
      if (stackTrace != null) {
        print('Stack trace available: true');
      }
    }
  }
}