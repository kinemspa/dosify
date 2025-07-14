import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyTag = 'encryption_key';
  static const _ivTag = 'encryption_iv';
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;
  bool _isInitialized = false;
  bool _isUsingFallback = false;

  // Initialize encryption
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('Initializing encryption service');
      
      // Get or create encryption key
      String? storedKey = await _storage.read(key: _keyTag);
      if (storedKey == null) {
        // Generate new key if none exists
        print('No encryption key found, generating new key');
        final key = encrypt.Key.fromSecureRandom(32);
        await _storage.write(key: _keyTag, value: base64.encode(key.bytes));
        storedKey = base64.encode(key.bytes);
        print('New encryption key generated and stored');
      } else {
        print('Existing encryption key found');
      }

      // Get or create IV
      String? storedIV = await _storage.read(key: _ivTag);
      if (storedIV == null) {
        // Generate new IV if none exists
        print('No IV found, generating new IV');
        final iv = encrypt.IV.fromSecureRandom(16);
        await _storage.write(key: _ivTag, value: base64.encode(iv.bytes));
        storedIV = base64.encode(iv.bytes);
        print('New IV generated and stored');
      } else {
        print('Existing IV found');
      }

      try {
        final keyBytes = base64.decode(storedKey);
        final ivBytes = base64.decode(storedIV);
        
        if (keyBytes.length != 32 || ivBytes.length != 16) {
          throw Exception('Invalid key or IV length');
        }
        
        final key = encrypt.Key(keyBytes);
        _iv = encrypt.IV(ivBytes);
        _encrypter = encrypt.Encrypter(encrypt.AES(key));
        _isInitialized = true;
        _isUsingFallback = false;
        print('Encryption service initialized successfully with AES');
      } catch (e) {
        print('Error setting up encryption with stored keys: $e');
        _useFallbackEncryption();
      }
    } catch (e) {
      print('Error initializing encryption service: $e');
      print('Stack trace: ${StackTrace.current}');
      _useFallbackEncryption();
    }
  }
  
  // Setup fallback encryption
  void _useFallbackEncryption() {
    // Fallback to a default key and IV if secure storage fails
    print('Using fallback encryption key and IV');
    // Create a fixed-length 32-byte key for AES-256
    final defaultKey = encrypt.Key.fromUtf8('dosify_default_key_for_fallback_use_32');
    // Create a fixed-length 16-byte IV
    _iv = encrypt.IV.fromUtf8('dosify_iv_16bytes');
    _encrypter = encrypt.Encrypter(encrypt.AES(defaultKey));
    _isInitialized = true;
    _isUsingFallback = true;
    print('Fallback encryption initialized with AES');
  }

  // Check if initialized and initialize if needed
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // Encrypt sensitive data
  Future<String> encryptData(String data) async {
    await _ensureInitialized();
    
    try {
      if (_isUsingFallback) {
        print('Using AES encryption with fallback key');
      } else {
        print('Using AES encryption with secure key');
      }
      
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      print('AES encryption successful');
      return encrypted.base64;
    } catch (e) {
      print('Error in AES encryption: $e');
      // Fallback to base64 if AES fails
      print('Falling back to base64 encoding');
      try {
        return base64.encode(utf8.encode(data));
      } catch (e2) {
        print('Error in fallback encryption: $e2');
        // Return a safe fallback if encoding fails
        return base64.encode(utf8.encode('encryption_error'));
      }
    }
  }

  // Decrypt sensitive data
  Future<String> decryptData(String encryptedData) async {
    await _ensureInitialized();
    
    try {
      if (_isUsingFallback) {
        print('Using AES decryption with fallback key');
      } else {
        print('Using AES decryption with secure key');
      }
      
      try {
        // Try AES decryption first
        final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
        final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
        print('AES decryption successful');
        return decrypted;
      } catch (e) {
        print('AES decryption failed, trying base64: $e');
        
        // Add padding if needed to make it valid base64
        String paddedData = encryptedData;
        while (paddedData.length % 4 != 0) {
          paddedData += '=';
        }
        
        try {
          return utf8.decode(base64.decode(paddedData));
        } catch (e2) {
          print('Base64 decoding failed, returning original: $e2');
          return encryptedData; // Return the original string if decoding fails
        }
      }
    } catch (e) {
      // If all decryption fails, return a placeholder value
      print('Decryption error: $e');
      return 'Decryption Error';
    }
  }

  // Hash sensitive data (for searching/indexing)
  String hashData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  // Encrypt medication details
  Future<Map<String, dynamic>> encryptMedicationData(Map<String, dynamic> medicationData) async {
    await _ensureInitialized();
    
    try {
      print('Encrypting medication data with fields: ${medicationData.keys.join(", ")}');
      Map<String, dynamic> encryptedData = {
        'type': medicationData['type'], // Non-sensitive enum
        'lastUpdate': DateTime.now().toIso8601String(),
      };
      
      // Try to encrypt the name
      try {
        encryptedData['name'] = await encryptData(medicationData['name'].toString());
        encryptedData['nameHash'] = hashData(medicationData['name'].toString()); // For searching
      } catch (e) {
        print('Error encrypting name: $e');
        encryptedData['name'] = medicationData['name'].toString();
        encryptedData['nameHash'] = hashData(medicationData['name'].toString());
      }
      
      // Encrypt numeric values
      for (String field in ['strength', 'tabletsInStock']) {
        if (medicationData.containsKey(field)) {
          try {
            print('Encrypting $field: ${medicationData[field]}');
            encryptedData[field] = await encryptData(medicationData[field].toString());
          } catch (e) {
            print('Error encrypting $field: $e');
            encryptedData[field] = medicationData[field].toString();
          }
        }
      }
      
      // Encrypt string values
      for (String field in ['strengthUnit', 'quantityUnit']) {
        if (medicationData.containsKey(field)) {
          try {
            print('Encrypting $field: ${medicationData[field]}');
            encryptedData[field] = await encryptData(medicationData[field].toString());
          } catch (e) {
            print('Error encrypting $field: $e');
            encryptedData[field] = medicationData[field].toString();
          }
        }
      }
      
      // Handle optional fields
      for (String field in ['reconstitutionVolume', 'reconstitutionVolumeUnit', 'concentrationAfterReconstitution']) {
        if (medicationData.containsKey(field) && medicationData[field] != null) {
          try {
            print('Encrypting optional field $field: ${medicationData[field]}');
            encryptedData[field] = await encryptData(medicationData[field].toString());
          } catch (e) {
            print('Error encrypting optional field $field: $e');
            if (medicationData[field] != null) {
              encryptedData[field] = medicationData[field].toString();
            }
          }
        }
      }
      
      print('Medication data encryption complete');
      return encryptedData;
    } catch (e) {
      print('Error encrypting medication data: $e');
      print('Stack trace: ${StackTrace.current}');
      // Return unencrypted data as fallback
      return {
        ...medicationData,
        'lastUpdate': DateTime.now().toIso8601String(),
        'encryptionFailed': true,
      };
    }
  }

  // Decrypt medication details
  Future<Map<String, dynamic>> decryptMedicationData(Map<String, dynamic> encryptedData) async {
    await _ensureInitialized();
    
    try {
      Map<String, dynamic> decryptedData = {
        'type': encryptedData['type'],
      };
      
      // Try to decrypt the name
      try {
        decryptedData['name'] = await decryptData(encryptedData['name']);
      } catch (e) {
        print('Error decrypting name: $e');
        decryptedData['name'] = encryptedData['name'] is String ? encryptedData['name'] : 'Unknown Medication';
      }
      
      // Decrypt numeric values
      if (encryptedData.containsKey('strength')) {
        try {
          final decryptedStr = await decryptData(encryptedData['strength']);
          decryptedData['strength'] = double.tryParse(decryptedStr) ?? 0.0;
        } catch (e) {
          print('Error decrypting strength: $e');
          decryptedData['strength'] = 0.0;
        }
      }
      
      if (encryptedData.containsKey('tabletsInStock')) {
        try {
          final decryptedStr = await decryptData(encryptedData['tabletsInStock']);
          decryptedData['tabletsInStock'] = double.tryParse(decryptedStr) ?? 0.0;
        } catch (e) {
          print('Error decrypting tabletsInStock: $e');
          decryptedData['tabletsInStock'] = 0.0;
        }
      }
      
      // Decrypt string values
      for (String field in ['strengthUnit', 'quantityUnit']) {
        if (encryptedData.containsKey(field)) {
          try {
            decryptedData[field] = await decryptData(encryptedData[field]);
          } catch (e) {
            print('Error decrypting $field: $e');
            decryptedData[field] = field == 'strengthUnit' ? 'mg' : 'tablets';
          }
        }
      }
      
      // Handle optional fields
      for (String field in ['reconstitutionVolume', 'reconstitutionVolumeUnit', 'concentrationAfterReconstitution']) {
        if (encryptedData.containsKey(field) && encryptedData[field] != null) {
          try {
            final decrypted = await decryptData(encryptedData[field]);
            if (field == 'reconstitutionVolume' || field == 'concentrationAfterReconstitution') {
              decryptedData[field] = double.tryParse(decrypted) ?? 0.0;
            } else {
              decryptedData[field] = decrypted;
            }
          } catch (e) {
            print('Error decrypting optional field $field: $e');
            // Skip this field if decryption fails
          }
        }
      }
      
      return decryptedData;
    } catch (e) {
      print('Error during medication data decryption: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Return a basic medication data structure as fallback
      return {
        'name': 'Decryption Error',
        'type': encryptedData['type'] ?? 'MedicationType.tablet',
        'strength': 0.0,
        'strengthUnit': 'mg',
        'tabletsInStock': 0.0,
        'decryptionFailed': true,
      };
    }
  }
} 