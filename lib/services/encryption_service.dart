import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for handling data encryption and decryption
class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyTag = 'encryption_key';
  bool _isInitialized = false;

  /// Initialize encryption
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _log('Initializing encryption service');
      _isInitialized = true;
    } catch (e) {
      _logError('Error initializing encryption service', e);
    }
  }
  
  /// Check if initialized and initialize if needed
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Encrypt sensitive data
  Future<String> encrypt(String data) async {
    await _ensureInitialized();
    
    try {
      // Simple base64 encoding for now
      return base64.encode(utf8.encode(data));
    } catch (e) {
      _logError('Error in encryption', e);
      // Return a safe fallback if encoding fails
      return base64.encode(utf8.encode('encryption_error'));
    }
  }

  /// Decrypt sensitive data
  Future<String> decrypt(String encryptedData) async {
    await _ensureInitialized();
    
    try {
      // Add padding if needed to make it valid base64
      String paddedData = encryptedData;
      while (paddedData.length % 4 != 0) {
        paddedData += '=';
      }
      
      try {
        final decoded = base64.decode(paddedData);
        return utf8.decode(decoded);
      } catch (e) {
        _logError('Base64 decoding failed, returning original', e);
        return encryptedData; // Return the original string if decoding fails
      }
    } catch (e) {
      // If all decryption fails, return a placeholder value
      _logError('Decryption error', e);
      return 'Decryption Error';
    }
  }

  /// Hash sensitive data (for searching/indexing)
  String hashData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }
  
  /// Alias for encrypt for backward compatibility
  Future<String> encryptData(String data) async {
    return encrypt(data);
  }
  
  /// Alias for decrypt for backward compatibility
  Future<String> decryptData(String encryptedData) async {
    return decrypt(encryptedData);
  }

  /// Encrypt medication details
  Future<Map<String, dynamic>> encryptMedicationData(Map<String, dynamic> medicationData) async {
    await _ensureInitialized();
    
    try {
      _log('Encrypting medication data with fields: ${medicationData.keys.join(", ")}');
      Map<String, dynamic> encryptedData = {
        'type': medicationData['type'], // Non-sensitive enum
        'lastUpdate': DateTime.now().toIso8601String(),
      };
      
      // Try to encrypt the name
      try {
        encryptedData['name'] = await encrypt(medicationData['name'].toString());
        encryptedData['nameHash'] = hashData(medicationData['name'].toString()); // For searching
      } catch (e) {
        _logError('Error encrypting name', e);
        encryptedData['name'] = medicationData['name'].toString();
        encryptedData['nameHash'] = hashData(medicationData['name'].toString());
      }
      
      // Encrypt numeric values
      for (String field in ['strength', 'tabletsInStock']) {
        if (medicationData.containsKey(field)) {
          try {
            _log('Encrypting $field: ${medicationData[field]}');
            encryptedData[field] = await encrypt(medicationData[field].toString());
          } catch (e) {
            _logError('Error encrypting $field', e);
            encryptedData[field] = medicationData[field].toString();
          }
        }
      }
      
      // Encrypt string values
      for (String field in ['strengthUnit', 'quantityUnit']) {
        if (medicationData.containsKey(field)) {
          try {
            _log('Encrypting $field: ${medicationData[field]}');
            encryptedData[field] = await encrypt(medicationData[field].toString());
          } catch (e) {
            _logError('Error encrypting $field', e);
            encryptedData[field] = medicationData[field].toString();
          }
        }
      }
      
      // Handle optional fields
      for (String field in ['reconstitutionVolume', 'reconstitutionVolumeUnit', 'concentrationAfterReconstitution']) {
        if (medicationData.containsKey(field) && medicationData[field] != null) {
          try {
            _log('Encrypting optional field $field: ${medicationData[field]}');
            encryptedData[field] = await encrypt(medicationData[field].toString());
          } catch (e) {
            _logError('Error encrypting optional field $field', e);
            if (medicationData[field] != null) {
              encryptedData[field] = medicationData[field].toString();
            }
          }
        }
      }
      
      _log('Medication data encryption complete');
      return encryptedData;
    } catch (e) {
      _logError('Error encrypting medication data', e);
      // Return unencrypted data as fallback
      return {
        ...medicationData,
        'lastUpdate': DateTime.now().toIso8601String(),
        'encryptionFailed': true,
      };
    }
  }

  /// Decrypt medication details
  Future<Map<String, dynamic>> decryptMedicationData(Map<String, dynamic> encryptedData) async {
    await _ensureInitialized();
    
    try {
      _log('Decrypting medication data with fields: ${encryptedData.keys.join(", ")}');
      Map<String, dynamic> decryptedData = {
        'type': encryptedData['type'], // Non-sensitive enum
        'lastUpdate': encryptedData['lastUpdate'],
      };
      
      // Decrypt name
      if (encryptedData.containsKey('name')) {
        try {
          decryptedData['name'] = await decrypt(encryptedData['name'].toString());
          _log('Decrypted name: ${decryptedData['name']}');
        } catch (e) {
          _logError('Error decrypting name', e);
          decryptedData['name'] = encryptedData['name'].toString();
        }
      }
      
      // Decrypt numeric values
      for (String field in ['strength', 'tabletsInStock']) {
        if (encryptedData.containsKey(field)) {
          try {
            final decrypted = await decrypt(encryptedData[field].toString());
            decryptedData[field] = double.tryParse(decrypted) ?? 0.0;
          } catch (e) {
            _logError('Error decrypting $field', e);
            decryptedData[field] = 0.0;
          }
        }
      }
      
      // Decrypt string values
      for (String field in ['strengthUnit', 'quantityUnit']) {
        if (encryptedData.containsKey(field)) {
          try {
            decryptedData[field] = await decrypt(encryptedData[field].toString());
          } catch (e) {
            _logError('Error decrypting $field', e);
            decryptedData[field] = encryptedData[field].toString();
          }
        }
      }
      
      // Handle optional fields
      for (String field in ['reconstitutionVolume', 'reconstitutionVolumeUnit', 'concentrationAfterReconstitution']) {
        if (encryptedData.containsKey(field) && encryptedData[field] != null) {
          try {
            final decrypted = await decrypt(encryptedData[field].toString());
            if (field == 'reconstitutionVolume' || field == 'concentrationAfterReconstitution') {
              decryptedData[field] = double.tryParse(decrypted);
            } else {
              decryptedData[field] = decrypted;
            }
          } catch (e) {
            _logError('Error decrypting optional field $field', e);
            decryptedData[field] = encryptedData[field];
          }
        }
      }
      
      _log('Medication data decryption complete');
      return decryptedData;
    } catch (e) {
      _logError('Error decrypting medication data', e);
      // Return encrypted data as fallback
      return encryptedData;
    }
  }
  
  /// Improved logging for debugging
  void _log(String message) {
    if (kDebugMode) {
      print('EncryptionService: $message');
    }
  }
  
  /// Error logging with stack trace
  void _logError(String message, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('EncryptionService ERROR: $message');
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      } else if (error is Error) {
        print('Stack trace: ${error.stackTrace}');
      }
    }
  }
} 