import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async'; // Add this import for TimeoutException
import '../models/medication.dart';
import '../models/dose.dart';
import '../models/schedule.dart' as schedule_lib;
import '../models/medication_schedule.dart' as med_schedule_lib;
import '../models/notification_settings.dart';
import 'encryption_service.dart';
import 'query_optimizer.dart';
import 'cache_manager.dart';
import 'package:flutter/foundation.dart';

/// Service for handling Firebase and local storage operations
class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;
  final SharedPreferences _prefs;
  final QueryOptimizer? _queryOptimizer;
  final CacheManager? _cacheManager;
  
  bool _isInitialized = false;
  bool _isFirestoreAvailable = true; // Track if Firestore is available
  
  // Local cache keys
  static const String _medicationsKey = 'local_medications';
  static const String _lastSyncKey = 'last_sync_time';
  static const String _firestoreAvailableKey = 'firestore_available';

  /// Creates a new FirebaseService instance with required dependencies
  FirebaseService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required EncryptionService encryptionService,
    required SharedPreferences prefs,
    QueryOptimizer? queryOptimizer,
    CacheManager? cacheManager,
  }) : _firestore = firestore,
       _auth = auth,
       _encryptionService = encryptionService,
       _prefs = prefs,
       _queryOptimizer = queryOptimizer,
       _cacheManager = cacheManager;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _encryptionService.initialize();
      
      // Check if we've previously determined Firestore is unavailable
      _isFirestoreAvailable = _prefs.getBool(_firestoreAvailableKey) ?? true;
      
      if (_isFirestoreAvailable) {
        // Configure Firestore for offline persistence
        final settings = _firestore.settings;
        if (settings.persistenceEnabled != true) {
          // Enable offline persistence
          _firestore.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
        }
        
        try {
          // Test if Firestore is available with a timeout
          await _firestore.collection('test').doc('test').get()
              .timeout(const Duration(seconds: 5), onTimeout: () {
            throw TimeoutException('Firestore connection timed out');
          });
        } catch (e) {
          // Firestore is not available
          _logError('Firestore is not available', e);
          _isFirestoreAvailable = false;
          
          // Save this information for future app starts
          await _prefs.setBool(_firestoreAvailableKey, false);
        }
      } else {
        _log('Firestore was previously marked as unavailable, skipping connection attempt');
      }
      
      _isInitialized = true;
    } catch (e) {
      _logError('Failed to initialize FirebaseService', e);
      rethrow;
    }
  }

  /// Reset Firestore availability status (for testing)
  Future<void> resetFirestoreStatus() async {
    try {
      await _prefs.setBool(_firestoreAvailableKey, true);
      _isFirestoreAvailable = true;
      _log('Firestore availability status reset to true');
    } catch (e) {
      _logError('Failed to reset Firestore status', e);
      rethrow;
    }
  }

  /// Check if Firestore database exists
  Future<bool> checkDatabaseExists() async {
    await _ensureInitialized();
    
    try {
      // Try to access a collection to see if the database exists
      await _firestore.collection('test').doc('test').get()
          .timeout(const Duration(seconds: 5));
      
      // If we get here, the database exists
      _isFirestoreAvailable = true;
      await _prefs.setBool(_firestoreAvailableKey, true);
      return true;
    } catch (e) {
      if (e.toString().contains('NOT_FOUND') && 
          e.toString().contains('database') && 
          e.toString().contains('does not exist')) {
        _log('Firestore database does not exist');
        _isFirestoreAvailable = false;
        await _prefs.setBool(_firestoreAvailableKey, false);
        return false;
      }
      
      // Some other error
      _logError('Error checking database', e);
      return false;
    }
  }

  /// Get Firestore status
  bool get isFirestoreAvailable => _isFirestoreAvailable;

  /// Ensure initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // Clear all medications from local storage
  Future<void> clearAllMedications() async {
    await _ensureInitialized();
    
    print('=== CLEARING ALL MEDICATIONS ===');
    
    try {
      // Clear encrypted storage
      await _prefs.remove(_medicationsKey);
      print('Cleared encrypted medications');
      
      // Clear unencrypted storage
      await _prefs.remove('unencrypted_medications');
      print('Cleared unencrypted medications');
      
      print('All medications cleared successfully');
    } catch (e) {
      print('Error clearing medications: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to clear medications: $e');
    }
  }

  // Improved addMedication method with better failsafe mechanisms
  Future<void> addMedication(Medication medication) async {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    print('=== MEDICATION SAVE DEBUG ===');
    print('Medication type: ${medication.type}');
    print('Medication name: ${medication.name}');
    print('Medication ID: ${medication.id}');
    print('User ID: ${userId ?? "Not authenticated"}');
    
    // Create medication data map
    final medicationData = {
      'name': medication.name,
      'strength': medication.strength,
      'strengthUnit': medication.strengthUnit,
      'type': medication.type.toString().split('.').last, // Store just the enum value name
      'tabletsInStock': medication.currentInventory,
      'quantityUnit': medication.quantityUnit,
      'lastUpdate': DateTime.now().toIso8601String(),
    };
    
    print('Medication data created with fields: ${medicationData.keys.join(", ")}');
    
    // Add reconstitution fields if available
    if (medication.reconstitutionVolume != null) {
      medicationData['reconstitutionVolume'] = medication.reconstitutionVolume!;
    }
    if (medication.reconstitutionVolumeUnit != null) {
      medicationData['reconstitutionVolumeUnit'] = medication.reconstitutionVolumeUnit!;
    }
    if (medication.concentrationAfterReconstitution != null) {
      medicationData['concentrationAfterReconstitution'] = medication.concentrationAfterReconstitution!;
    }
    
    // Add injection-specific fields
    if (medication.isPreFilled != null) {
      medicationData['isPreFilled'] = medication.isPreFilled!;
    }
    if (medication.needsReconstitution != null) {
      medicationData['needsReconstitution'] = medication.needsReconstitution!;
    }
    if (medication.isPrefillPen != null) {
      medicationData['isPrefillPen'] = medication.isPrefillPen!;
    }
    
    // Add new injection-specific fields
    if (medication.injectionType != null) {
      medicationData['injectionType'] = medication.injectionType.toString().split('.').last;
    }
    if (medication.routeOfAdministration != null) {
      medicationData['routeOfAdministration'] = medication.routeOfAdministration!;
    }
    if (medication.diluent != null) {
      medicationData['diluent'] = medication.diluent!;
    }
    
    try {
      // Encrypt sensitive fields
      print('Encrypting medication data...');
      final encryptedData = await _encryptionService.encryptMedicationData(medicationData);
      print('Encryption complete. Fields: ${encryptedData.keys.join(", ")}');
      
      // Always save locally first as a fallback
      await _saveLocalMedicationUnencrypted(medication);
      print('Saved unencrypted data as primary local storage');
      
      // Store in Firestore if available
      if (_isFirestoreAvailable && userId != null) {
        try {
          print('Saving to Firestore...');
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(medication.id)
              .set(encryptedData);
          print('Saved to Firestore successfully');
        } catch (e) {
          print('Firestore save failed: $e');
          _isFirestoreAvailable = false;
          await _prefs.setBool(_firestoreAvailableKey, false);
          
          // Schedule a retry for Firebase sync in the background
          _scheduleFirebaseRetry(medication, medicationData);
        }
      } else {
        if (!_isFirestoreAvailable) {
          print('Firestore is not available, saving locally only');
          // Schedule a retry for Firebase sync in the background
          _scheduleFirebaseRetry(medication, medicationData);
        } else {
          print('User not authenticated, saving locally only');
        }
      }
      
      print('=== MEDICATION SAVE COMPLETE ===');
    } catch (e) {
      print('Error during medication save: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to save medication: $e');
    }
  }
  
  // Schedule a retry for Firebase sync
  void _scheduleFirebaseRetry(Medication medication, Map<String, dynamic> medicationData) {
    // Don't retry if user is not authenticated
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    // Schedule a retry after 30 seconds
    Future.delayed(const Duration(seconds: 30), () async {
      if (!_isFirestoreAvailable) {
        // Try to check if Firestore is available now
        try {
          await _firestore.collection('test').doc('test').get()
              .timeout(const Duration(seconds: 5));
          
          // If we get here, Firestore is available again
          _isFirestoreAvailable = true;
          await _prefs.setBool(_firestoreAvailableKey, true);
          
          // Try to save to Firebase again
          try {
            print('Retrying Firebase save for ${medication.name}...');
            
            // Encrypt sensitive data before sending to Firebase
            Map<String, dynamic> encryptedDataForFirebase = await _encryptDataForFirebase(medicationData);
            
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('medications')
                .doc(medication.id)
                .set(encryptedDataForFirebase)
                .timeout(const Duration(seconds: 3));
            
            print('Retry Firebase save successful!');
          } catch (e) {
            print('Retry Firebase save failed: $e');
          }
        } catch (e) {
          print('Firestore is still unavailable during retry: $e');
        }
      }
    });
  }

  // Encrypt data before sending to Firebase
  Future<Map<String, dynamic>> _encryptDataForFirebase(Map<String, dynamic> medicationData) async {
    Map<String, dynamic> encryptedData = {};
    
    // Keep non-sensitive fields unencrypted
    encryptedData['type'] = medicationData['type'];
    encryptedData['lastUpdate'] = medicationData['lastUpdate'];
    
    // Encrypt sensitive fields
    encryptedData['name'] = await _encryptionService.encryptData(medicationData['name'].toString());
    
    // Encrypt numeric values
    for (String field in ['strength', 'tabletsInStock']) {
      if (medicationData.containsKey(field)) {
        encryptedData[field] = await _encryptionService.encryptData(medicationData[field].toString());
      }
    }
    
    // Encrypt string values
    for (String field in ['strengthUnit', 'quantityUnit']) {
      if (medicationData.containsKey(field)) {
        encryptedData[field] = await _encryptionService.encryptData(medicationData[field].toString());
      }
    }
    
    // Encrypt optional fields
    for (String field in ['reconstitutionVolume', 'reconstitutionVolumeUnit', 'concentrationAfterReconstitution']) {
      if (medicationData.containsKey(field) && medicationData[field] != null) {
        encryptedData[field] = await _encryptionService.encryptData(medicationData[field].toString());
      }
    }
    
    print('Data encrypted for Firebase storage');
    return encryptedData;
  }
  
  // Save medication locally (encrypted)
  Future<void> _saveLocalMedication(String id, Map<String, dynamic> encryptedData) async {
    // Get existing medicationsR
    final String? storedData = _prefs.getString(_medicationsKey);
    Map<String, dynamic> allMedications = {};
    
    if (storedData != null) {
      try {
        allMedications = json.decode(storedData);
      } catch (e) {
        print('Error parsing stored medications: $e');
        // Continue with empty map if parsing fails
      }
    }
    
    // Add or update medication
    allMedications[id] = encryptedData;
    
    // Save back to shared preferences
    try {
      await _prefs.setString(_medicationsKey, json.encode(allMedications));
      print('Successfully saved medication $id to local storage');
    } catch (e) {
      print('Error saving to SharedPreferences: $e');
      throw Exception('Failed to save medication locally: $e');
    }
  }
  
  // Save medication locally (unencrypted - emergency fallback)
  Future<void> _saveLocalMedicationUnencrypted(Medication medication) async {
    // Get existing medications
    final String? storedData = _prefs.getString('unencrypted_medications');
    Map<String, dynamic> allMedications = {};
    
    if (storedData != null) {
      try {
        allMedications = json.decode(storedData);
      } catch (e) {
        print('Error parsing unencrypted medications: $e');
        // Continue with empty map if parsing fails
      }
    }
    
    // Add or update medication
    allMedications[medication.id] = {
      'name': medication.name,
      'type': medication.type.toString().split('.').last,
      'strength': medication.strength,
      'strengthUnit': medication.strengthUnit,
      'tabletsInStock': medication.currentInventory,
      'quantityUnit': medication.quantityUnit,
      'lastUpdate': DateTime.now().toIso8601String(),
    };
    
    // Add reconstitution fields if available
    if (medication.reconstitutionVolume != null) {
      allMedications[medication.id]['reconstitutionVolume'] = medication.reconstitutionVolume;
    }
    if (medication.reconstitutionVolumeUnit != null) {
      allMedications[medication.id]['reconstitutionVolumeUnit'] = medication.reconstitutionVolumeUnit;
    }
    if (medication.concentrationAfterReconstitution != null) {
      allMedications[medication.id]['concentrationAfterReconstitution'] = medication.concentrationAfterReconstitution;
    }
    
    // Add injection-specific fields
    if (medication.isPreFilled != null) {
      allMedications[medication.id]['isPreFilled'] = medication.isPreFilled;
    }
    if (medication.needsReconstitution != null) {
      allMedications[medication.id]['needsReconstitution'] = medication.needsReconstitution;
    }
    if (medication.isPrefillPen != null) {
      allMedications[medication.id]['isPrefillPen'] = medication.isPrefillPen;
    }
    
    // Add new injection-specific fields
    if (medication.injectionType != null) {
      allMedications[medication.id]['injectionType'] = medication.injectionType.toString().split('.').last;
    }
    if (medication.routeOfAdministration != null) {
      allMedications[medication.id]['routeOfAdministration'] = medication.routeOfAdministration;
    }
    if (medication.diluent != null) {
      allMedications[medication.id]['diluent'] = medication.diluent;
    }
    
    // Save back to shared preferences
    try {
      await _prefs.setString('unencrypted_medications', json.encode(allMedications));
      print('Successfully saved unencrypted medication ${medication.id} to local storage');
    } catch (e) {
      print('Error saving unencrypted medication to SharedPreferences: $e');
      throw Exception('Failed to save unencrypted medication locally: $e');
    }
  }

  // Get user's medications with optimized caching
  Stream<List<Medication>> getMedications() async* {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    List<Medication> medications = [];
    
    _log('=== GET MEDICATIONS DEBUG ===');
    _log('User ID: ${userId ?? "Not authenticated"}');
    
    // Check if we have cached medications
    if (_cacheManager != null) {
      final cachedMedications = _cacheManager!.get<List<dynamic>>('medications_$userId');
      if (cachedMedications != null) {
        try {
          medications = cachedMedications.map((item) {
            return Medication(
              id: item['id'],
              name: item['name'],
              type: _parseMedicationType(item['type']),
              strength: item['strength'],
              strengthUnit: item['strengthUnit'],
              quantity: item['quantity'],
              quantityUnit: item['quantityUnit'],
              currentInventory: item['currentInventory'],
              lastInventoryUpdate: DateTime.parse(item['lastInventoryUpdate']),
              reconstitutionVolume: item['reconstitutionVolume'],
              reconstitutionVolumeUnit: item['reconstitutionVolumeUnit'],
              concentrationAfterReconstitution: item['concentrationAfterReconstitution'],
              isPreFilled: item['isPreFilled'],
              needsReconstitution: item['needsReconstitution'],
              isPrefillPen: item['isPrefillPen'],
              injectionType: _parseInjectionType(item['injectionType']),
              routeOfAdministration: item['routeOfAdministration'],
              diluent: item['diluent'],
            );
          }).toList();
          
          _log('Retrieved ${medications.length} medications from cache');
          yield medications;
        } catch (e) {
          _logError('Error parsing cached medications', e);
          // Fall back to local storage
        }
      }
    }
    
    // Get local data if cache is empty
    if (medications.isEmpty) {
      medications = await _getLocalMedications();
      _log('Retrieved ${medications.length} medications from local storage');
      yield medications;
    }
    
    // Only try to get from Firebase if Firestore is available and user is authenticated
    if (_isFirestoreAvailable && userId != null) {
      try {
        _log('Setting up Firebase medications stream...');
        
        final query = _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .where('isDeleted', isEqualTo: false);
        
        // Use query optimizer if available
        if (_queryOptimizer != null) {
          _log('Using query optimizer for medications');
          
          try {
            // Initial query with cache
            final snapshot = await _queryOptimizer!.getQueryWithCache(
              query,
              cacheKey: 'medications_query_$userId',
              cacheDuration: const Duration(minutes: 5),
            );
            
            final remoteMeds = await _processMedicationsSnapshot(snapshot);
            
            // Merge with local-only medications
            final localOnlyMeds = medications.where(
              (local) => !remoteMeds.any((remote) => remote.id == local.id)
            ).toList();
            
            medications = [...remoteMeds, ...localOnlyMeds];
            
            // Update local cache
            _updateLocalMedicationsCache(medications);
            
            // Update memory cache
            if (_cacheManager != null) {
              await _cacheManager!.set(
                'medications_$userId', 
                medications.map((m) => m.toJson()).toList(),
                ttl: const Duration(minutes: 30),
              );
            }
            
            yield medications;
          } catch (e) {
            _logError('Error using query optimizer', e);
            // Fall back to regular stream
          }
        }
        
        // Set up regular stream (either as fallback or primary method)
        await for (var snapshot in query
            .snapshots()
            .timeout(const Duration(seconds: 5), onTimeout: (sink) {
              _log('Firebase stream timed out');
              sink.close();
            })) {
          
          final remoteMeds = await _processMedicationsSnapshot(snapshot);
          
          _log('Retrieved ${remoteMeds.length} medications from Firebase');
          
          // Merge with local-only medications
          final localOnlyMeds = medications.where(
            (local) => !remoteMeds.any((remote) => remote.id == local.id)
          ).toList();
          
          medications = [...remoteMeds, ...localOnlyMeds];
          
          // Update local cache
          _updateLocalMedicationsCache(medications);
          
          // Update memory cache
          if (_cacheManager != null) {
            await _cacheManager!.set(
              'medications_$userId', 
              medications.map((m) => m.toJson()).toList(),
              ttl: const Duration(minutes: 30),
            );
          }
          
          yield medications;
        }
      } catch (e) {
        // If Firebase fails, just use local data
        _logError('Firebase stream error', e);
        
        // If this is a NOT_FOUND error for the database, mark Firestore as unavailable
        if (e.toString().contains('NOT_FOUND') && 
            e.toString().contains('database') && 
            e.toString().contains('does not exist')) {
          _log('Firestore database does not exist, marking as unavailable');
          _isFirestoreAvailable = false;
          await _prefs.setBool(_firestoreAvailableKey, false);
        }
        
        yield medications;
      }
    } else {
      // Set up a periodic check for Firestore availability if currently unavailable
      if (!_isFirestoreAvailable) {
        Timer.periodic(const Duration(minutes: 5), (timer) async {
          try {
            _log('Checking if Firestore is available now...');
            await _firestore.collection('test').doc('test').get()
                .timeout(const Duration(seconds: 5));
            
            // If we get here, Firestore is available
            _log('Firestore is now available!');
            _isFirestoreAvailable = true;
            await _prefs.setBool(_firestoreAvailableKey, true);
            
            // Cancel the timer as we don't need to check anymore
            timer.cancel();
            
            _log('Local medications will be refreshed on next access');
          } catch (e) {
            _logError('Firestore is still unavailable', e);
          }
        });
      }
    }
  }
  
  // Process medications snapshot from Firestore
  Future<List<Medication>> _processMedicationsSnapshot(QuerySnapshot snapshot) async {
    List<Medication> remoteMeds = [];
    
    for (var doc in snapshot.docs) {
      try {
        final encryptedData = doc.data() as Map<String, dynamic>;
        
        // Skip deleted medications
        if (encryptedData['isDeleted'] == true) {
          continue;
        }
        
        _log('Processing medication document: ${doc.id}');
        
        // Decrypt the data from Firebase
        final data = await _decryptDataFromFirebase(encryptedData);
        
        // Verify name was properly decrypted
        if (data['name'] == null || data['name'].toString().isEmpty) {
          _log('WARNING: Medication name is empty after decryption for ${doc.id}');
          // Try direct decryption as fallback
          if (encryptedData.containsKey('name')) {
            try {
              data['name'] = await _safeDecrypt(encryptedData['name'].toString(), defaultValue: 'Unknown Medication');
              _log('Fallback decryption of name: ${data['name']}');
            } catch (e) {
              _logError('Fallback decryption failed', e);
              data['name'] = 'Unknown Medication';
            }
          }
        } else {
          _log('Successfully processed medication: ${data['name']}');
        }
        
        // Extract reconstitution data if available
        double? reconstitutionVolume;
        String? reconstitutionVolumeUnit;
        double? concentrationAfterReconstitution;
        
        if (data.containsKey('reconstitutionVolume')) {
          reconstitutionVolume = data['reconstitutionVolume'] is num ? 
              (data['reconstitutionVolume'] as num).toDouble() : null;
        }
        if (data.containsKey('reconstitutionVolumeUnit')) {
          reconstitutionVolumeUnit = data['reconstitutionVolumeUnit']?.toString();
        }
        if (data.containsKey('concentrationAfterReconstitution')) {
          concentrationAfterReconstitution = data['concentrationAfterReconstitution'] is num ? 
              (data['concentrationAfterReconstitution'] as num).toDouble() : null;
        }
        
        final strength = data['strength'] is num ? 
            (data['strength'] as num).toDouble() : 0.0;
        final inventory = data['tabletsInStock'] is num ? 
            (data['tabletsInStock'] as num).toDouble() : 0.0;
        
        remoteMeds.add(Medication(
          id: doc.id,
          name: data['name']?.toString() ?? 'Unknown Medication',
          type: _parseMedicationType(data['type']?.toString()),
          strength: strength,
          strengthUnit: data['strengthUnit']?.toString() ?? 'mg',
          quantity: inventory, // Use inventory for quantity
          quantityUnit: data['quantityUnit']?.toString() ?? 'tablets',
          currentInventory: inventory,
          lastInventoryUpdate: DateTime.now(),
          reconstitutionVolume: reconstitutionVolume,
          reconstitutionVolumeUnit: reconstitutionVolumeUnit,
          concentrationAfterReconstitution: concentrationAfterReconstitution,
          isPreFilled: data['isPreFilled'] as bool?,
          needsReconstitution: data['needsReconstitution'] as bool?,
          isPrefillPen: data['isPrefillPen'] as bool?,
          // New injection-specific fields
          injectionType: _parseInjectionType(data['injectionType']?.toString()),
          routeOfAdministration: data['routeOfAdministration']?.toString(),
          diluent: data['diluent']?.toString(),
        ));
      } catch (e) {
        // Skip medications that can't be processed
        _logError('Error processing remote medication', e);
      }
    }
    
    return remoteMeds;
  }

  // Decrypt data from Firebase
  Future<Map<String, dynamic>> _decryptDataFromFirebase(Map<String, dynamic> encryptedData) async {
    Map<String, dynamic> decryptedData = {};
    
    // Copy non-sensitive fields directly
    decryptedData['type'] = encryptedData['type'];
    if (encryptedData.containsKey('lastUpdate')) {
      decryptedData['lastUpdate'] = encryptedData['lastUpdate'];
    }
    
    // Decrypt sensitive fields
    if (encryptedData.containsKey('name')) {
      try {
        final encryptedName = encryptedData['name'].toString();
        _log('Decrypting medication name: $encryptedName');
        decryptedData['name'] = await _safeDecrypt(encryptedName, defaultValue: 'Unknown Medication');
        _log('Successfully decrypted name to: ${decryptedData['name']}');
      } catch (e) {
        _logError('Error decrypting name', e);
        // Fallback to using the original value
        decryptedData['name'] = encryptedData['name'].toString();
        _log('Using fallback name: ${decryptedData['name']}');
      }
    }
    
    // Decrypt numeric values
    for (String field in ['strength', 'tabletsInStock']) {
      if (encryptedData.containsKey(field)) {
        final decryptedStr = await _safeDecrypt(encryptedData[field].toString());
        decryptedData[field] = double.tryParse(decryptedStr) ?? 0.0;
      }
    }
    
    // Decrypt string values
    for (String field in ['strengthUnit', 'quantityUnit']) {
      if (encryptedData.containsKey(field)) {
        decryptedData[field] = await _safeDecrypt(encryptedData[field].toString());
      }
    }
    
    // Decrypt optional fields
    for (String field in ['reconstitutionVolume', 'reconstitutionVolumeUnit', 'concentrationAfterReconstitution']) {
      if (encryptedData.containsKey(field) && encryptedData[field] != null) {
        final decrypted = await _safeDecrypt(encryptedData[field].toString());
        if (field == 'reconstitutionVolume' || field == 'concentrationAfterReconstitution') {
          decryptedData[field] = double.tryParse(decrypted) ?? 0.0;
        } else {
          decryptedData[field] = decrypted;
        }
      }
    }
    
    // Copy any additional fields that might be needed
    for (String field in ['isPreFilled', 'needsReconstitution', 'isPrefillPen', 'injectionType', 'routeOfAdministration', 'diluent']) {
      if (encryptedData.containsKey(field)) {
        decryptedData[field] = encryptedData[field];
      }
    }
    
    _log('Data decrypted from Firebase storage');
    return decryptedData;
  }
  
  // Get medications from local storage
  Future<List<Medication>> _getLocalMedications() async {
    final List<Medication> medications = [];
    
    // Try to get unencrypted medications first (more reliable)
    final String? unencryptedData = _prefs.getString('unencrypted_medications');
    if (unencryptedData != null) {
      try {
        final Map<String, dynamic> allMedications = json.decode(unencryptedData);
        print('Retrieved ${allMedications.length} unencrypted medications from local storage');
        
        for (var entry in allMedications.entries) {
          try {
            final id = entry.key;
            final data = entry.value;
            
            if (data is Map<String, dynamic>) {
              // Skip deleted medications
              if (data['isDeleted'] == true) {
                continue;
              }
              
              _log('Processing local medication: $id');
              
              // Check if the name needs decryption
              String name = 'Unknown Medication';
              if (data.containsKey('name')) {
                try {
                  // Try to decrypt the name
                  name = await _safeDecrypt(data['name'].toString(), defaultValue: 'Unknown Medication');
                  _log('Processed local medication name: $name');
                } catch (e) {
                  _logError('Failed to process local medication name', e);
                  name = data['name'].toString();
                }
              }
              
              // Extract reconstitution data if available
              double? reconstitutionVolume;
              String? reconstitutionVolumeUnit;
              double? concentrationAfterReconstitution;
              
              if (data.containsKey('reconstitutionVolume')) {
                reconstitutionVolume = data['reconstitutionVolume'] is num ? 
                    (data['reconstitutionVolume'] as num).toDouble() : null;
              }
              if (data.containsKey('reconstitutionVolumeUnit')) {
                reconstitutionVolumeUnit = data['reconstitutionVolumeUnit']?.toString();
              }
              if (data.containsKey('concentrationAfterReconstitution')) {
                concentrationAfterReconstitution = data['concentrationAfterReconstitution'] is num ? 
                    (data['concentrationAfterReconstitution'] as num).toDouble() : null;
              }
              
              final strength = data['strength'] is num ? 
                  (data['strength'] as num).toDouble() : 0.0;
              final inventory = data['tabletsInStock'] is num ? 
                  (data['tabletsInStock'] as num).toDouble() : 0.0;
              
              medications.add(Medication(
                id: id,
                name: name,
                type: _parseMedicationType(data['type']?.toString()),
                strength: strength,
                strengthUnit: data['strengthUnit']?.toString() ?? 'mg',
                quantity: inventory, // Use inventory for quantity
                quantityUnit: data['quantityUnit']?.toString() ?? 'tablets',
                currentInventory: inventory,
                lastInventoryUpdate: DateTime.now(),
                reconstitutionVolume: reconstitutionVolume,
                reconstitutionVolumeUnit: reconstitutionVolumeUnit,
                concentrationAfterReconstitution: concentrationAfterReconstitution,
                isPreFilled: data['isPreFilled'] as bool?,
                needsReconstitution: data['needsReconstitution'] as bool?,
                isPrefillPen: data['isPrefillPen'] as bool?,
              ));
            }
          } catch (e) {
            // Skip invalid medications
            print('Error loading unencrypted medication: $e');
          }
        }
      } catch (e) {
        print('Error loading unencrypted medications: $e');
      }
    }
    
    // If we already have medications from unencrypted storage, return them
    if (medications.isNotEmpty) {
      print('Returning ${medications.length} medications from unencrypted storage');
      return medications;
    }
    
    // Otherwise try to get encrypted medications
    final String? storedData = _prefs.getString(_medicationsKey);
    if (storedData != null) {
      try {
        final Map<String, dynamic> allMedications = json.decode(storedData);
        print('Retrieved ${allMedications.length} encrypted medications from local storage');
        
        for (var entry in allMedications.entries) {
          try {
            final id = entry.key;
            final data = entry.value;
            
            if (data is Map<String, dynamic>) {
              // Skip deleted medications
              if (data.containsKey('isDeleted')) {
                final String decryptedValue = await _encryptionService.decryptData(data['isDeleted']);
                if (decryptedValue == 'true') {
                  continue;
                }
              }
              
              final decryptedData = await _encryptionService.decryptMedicationData(
                Map<String, dynamic>.from(data)
              );
              
              // Extract reconstitution data if available
              double? reconstitutionVolume;
              String? reconstitutionVolumeUnit;
              double? concentrationAfterReconstitution;
              
              if (decryptedData.containsKey('reconstitutionVolume')) {
                reconstitutionVolume = decryptedData['reconstitutionVolume'] is num ? 
                    (decryptedData['reconstitutionVolume'] as num).toDouble() : null;
              }
              if (decryptedData.containsKey('reconstitutionVolumeUnit')) {
                reconstitutionVolumeUnit = decryptedData['reconstitutionVolumeUnit']?.toString();
              }
              if (decryptedData.containsKey('concentrationAfterReconstitution')) {
                concentrationAfterReconstitution = decryptedData['concentrationAfterReconstitution'] is num ? 
                    (decryptedData['concentrationAfterReconstitution'] as num).toDouble() : null;
              }
              
              final strength = decryptedData['strength'] is num ? 
                  (decryptedData['strength'] as num).toDouble() : 0.0;
              final inventory = decryptedData['tabletsInStock'] is num ? 
                  (decryptedData['tabletsInStock'] as num).toDouble() : 0.0;
              
              medications.add(Medication(
                id: id,
                name: decryptedData['name']?.toString() ?? 'Unknown Medication',
                type: MedicationType.values.firstWhere(
                    (e) => e.toString() == decryptedData['type']?.toString(),
                    orElse: () => MedicationType.tablet),
                strength: strength,
                strengthUnit: decryptedData['strengthUnit']?.toString() ?? 'mg',
                quantity: inventory, // Use inventory for quantity
                quantityUnit: decryptedData['quantityUnit']?.toString() ?? 'tablets',
                currentInventory: inventory,
                lastInventoryUpdate: DateTime.now(),
                reconstitutionVolume: reconstitutionVolume,
                reconstitutionVolumeUnit: reconstitutionVolumeUnit,
                concentrationAfterReconstitution: concentrationAfterReconstitution,
                isPreFilled: decryptedData['isPreFilled'] as bool?,
                needsReconstitution: decryptedData['needsReconstitution'] as bool?,
                isPrefillPen: decryptedData['isPrefillPen'] as bool?,
              ));
            }
          } catch (e) {
            // Skip medications that can't be decrypted
            print('Error decrypting local medication: $e');
          }
        }
      } catch (e) {
        print('Error loading local medications: $e');
      }
    }
    
    print('Returning ${medications.length} medications from local storage');
    return medications;
  }
  
  // Update local cache with latest medications
  Future<void> _updateLocalMedicationsCache(List<Medication> medications) async {
    Map<String, dynamic> allMedications = {};
    
    // Convert medications to encrypted format and save
    for (var med in medications) {
      try {
        final medicationData = {
          'name': med.name,
          'strength': med.strength,
          'strengthUnit': med.strengthUnit,
          'type': med.type.toString(),
          'tabletsInStock': med.currentInventory,
        };
        
        final encryptedData = await _encryptionService.encryptMedicationData(medicationData);
        allMedications[med.id] = encryptedData;
      } catch (e) {
        print('Error encrypting medication for cache: $e');
      }
    }
    
    // Save to shared preferences
    await _prefs.setString(_medicationsKey, json.encode(allMedications));
    await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Add a dose
  Future<void> addDose(Dose dose) async {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    print('=== DOSE SAVE DEBUG ===');
    print('Dose ID: ${dose.id}');
    print('Medication ID: ${dose.medicationId}');
    print('Amount: ${dose.amount}');
    print('Unit: ${dose.unit}');
    print('Name: ${dose.name}');
    print('User ID: ${userId ?? "Not authenticated"}');
    
    // Create dose data map
    final doseData = {
      'medicationId': dose.medicationId,
      'amount': dose.amount,
      'unit': dose.unit,
      'lastUpdate': DateTime.now().toIso8601String(),
    };
    
    print('Dose data created with fields: ${doseData.keys.join(", ")}');
    
    // Add optional fields
    if (dose.name != null) {
      doseData['name'] = dose.name as Object;
      print('Added name field: ${dose.name}');
    }
    if (dose.notes != null) {
      doseData['notes'] = dose.notes as Object;
      print('Added notes field');
    }
    if (dose.requiresCalculation) {
      doseData['requiresCalculation'] = true;
      print('Added requiresCalculation field');
    }
    if (dose.calculationFormula != null) {
      doseData['calculationFormula'] = dose.calculationFormula as Object;
      print('Added calculationFormula field');
    }
    
    try {
      // Save unencrypted dose data first as a fallback
      print('Saving unencrypted dose data locally...');
      await _saveLocalDoseUnencrypted(dose);
      print('Unencrypted dose data saved locally');
      
      // Try to save to Firebase if user is authenticated and Firestore is available
      if (userId != null && _isFirestoreAvailable) {
        try {
          print('Attempting to save to Firebase...');
          // Encrypt sensitive data before sending to Firebase
          Map<String, dynamic> encryptedDataForFirebase = await _encryptDataForFirebase(doseData);
          print('Data encrypted for Firebase');
          
          print('Collection path: users/$userId/medications/${dose.medicationId}/doses/${dose.id}');
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(dose.medicationId)
              .collection('doses')
              .doc(dose.id)
              .set(encryptedDataForFirebase)
              .timeout(const Duration(seconds: 3));
          
          print('Firebase save successful!');
        } catch (e) {
          print('Failed to save dose to Firebase: $e');
          print('Stack trace: ${StackTrace.current}');
          // If Firebase fails, we already have local data saved
        }
      } else {
        if (!_isFirestoreAvailable) {
          print('Firestore is not available, saving locally only');
        } else {
          print('User not authenticated, saving locally only');
        }
      }
      
      print('=== DOSE SAVE COMPLETE ===');
    } catch (e) {
      print('Error saving dose: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to save dose: $e');
    }
  }
  
  // Save dose to local storage (unencrypted)
  Future<void> _saveLocalDoseUnencrypted(Dose dose) async {
    // Get existing doses
    final String? storedData = _prefs.getString('unencrypted_doses');
    Map<String, dynamic> allDoses = {};
    
    if (storedData != null) {
      try {
        allDoses = json.decode(storedData);
      } catch (e) {
        print('Error parsing stored doses: $e');
      }
    }
    
    // Add the new dose
    allDoses[dose.id] = {
      'medicationId': dose.medicationId,
      'amount': dose.amount,
      'unit': dose.unit,
      'name': dose.name,
      'notes': dose.notes,
      'requiresCalculation': dose.requiresCalculation,
      'calculationFormula': dose.calculationFormula,
      'lastUpdate': DateTime.now().toIso8601String(),
    };
    
    // Save back to shared preferences
    await _prefs.setString('unencrypted_doses', json.encode(allDoses));
    print('Successfully saved unencrypted dose ${dose.id} to local storage');
  }
  
  // Get doses for a medication
  Future<List<Dose>> getDosesForMedication(String medicationId) async {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    List<Dose> doses = [];
    
    // Get local data
    doses = await _getLocalDosesForMedication(medicationId);
    
    // Only try to get from Firebase if Firestore is available and user is authenticated
    if (_isFirestoreAvailable && userId != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .doc(medicationId)
            .collection('doses')
            .where('isDeleted', isEqualTo: false)  // Filter out soft-deleted doses
            .get()
            .timeout(const Duration(seconds: 5));
        
        List<Dose> remoteDoses = [];
        
        for (var doc in snapshot.docs) {
          try {
            final encryptedData = doc.data();
            
            // Skip deleted doses
            if (encryptedData['isDeleted'] == true) {
              continue;
            }
            
            // Decrypt the data from Firebase
            final data = await _decryptDataFromFirebase(encryptedData);
            
            remoteDoses.add(Dose(
              id: doc.id,
              medicationId: medicationId,
              amount: data['amount'] is num ? (data['amount'] as num).toDouble() : 0.0,
              unit: data['unit']?.toString() ?? '',
              name: data['name']?.toString(),
              notes: data['notes']?.toString(),
              requiresCalculation: data['requiresCalculation'] as bool? ?? false,
              calculationFormula: data['calculationFormula']?.toString(),
            ));
          } catch (e) {
            // Skip doses that can't be processed
            print('Error processing remote dose: $e');
          }
        }
        
        // Merge with local-only doses
        final localOnlyDoses = doses.where(
          (local) => !remoteDoses.any((remote) => remote.id == local.id)
        ).toList();
        
        doses = [...remoteDoses, ...localOnlyDoses];
        
        // Update local cache with the latest data
        _updateLocalDosesCache(doses);
      } catch (e) {
        // If Firebase fails, just use local data
        print('Firebase error getting doses: $e');
      }
    }
    
    return doses;
  }
  
  // Get doses from local storage
  Future<List<Dose>> _getLocalDosesForMedication(String medicationId) async {
    final List<Dose> doses = [];
    
    // Try to get unencrypted doses first
    final String? unencryptedData = _prefs.getString('unencrypted_doses');
    if (unencryptedData != null) {
      try {
        final Map<String, dynamic> allDoses = json.decode(unencryptedData);
        
        for (var entry in allDoses.entries) {
          try {
            final id = entry.key;
            final data = entry.value;
            
            if (data is Map<String, dynamic> && data['medicationId'] == medicationId) {
              // Skip deleted doses
              if (data['isDeleted'] == true) {
                continue;
              }
              
              doses.add(Dose(
                id: id,
                medicationId: medicationId,
                amount: data['amount'] is num ? (data['amount'] as num).toDouble() : 0.0,
                unit: data['unit']?.toString() ?? '',
                name: data['name']?.toString(),
                notes: data['notes']?.toString(),
                requiresCalculation: data['requiresCalculation'] as bool? ?? false,
                calculationFormula: data['calculationFormula']?.toString(),
              ));
            }
          } catch (e) {
            // Skip invalid doses
            print('Error loading unencrypted dose: $e');
          }
        }
      } catch (e) {
        print('Error loading unencrypted doses: $e');
      }
    }
    
    return doses;
  }
  
  // Update local cache with latest doses
  Future<void> _updateLocalDosesCache(List<Dose> doses) async {
    Map<String, dynamic> allDoses = {};
    
    // Convert doses to format and save
    for (var dose in doses) {
      allDoses[dose.id] = {
        'medicationId': dose.medicationId,
        'amount': dose.amount,
        'unit': dose.unit,
        'name': dose.name,
        'notes': dose.notes,
        'requiresCalculation': dose.requiresCalculation,
        'calculationFormula': dose.calculationFormula,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    }
    
    // Save to shared preferences
    await _prefs.setString('unencrypted_doses', json.encode(allDoses));
  }

  // Delete a dose (soft delete)
  Future<void> deleteDose(String doseId, String medicationId) async {
    await _ensureInitialized();
    
    print('=== DOSE DELETE DEBUG ===');
    print('Dose ID: $doseId');
    print('Medication ID: $medicationId');
    
    final userId = _auth.currentUser?.uid;
    print('User ID: ${userId ?? "Not authenticated"}');
    
    try {
      bool localDeleteSuccessful = false;
      
      // First, mark as deleted in unencrypted storage (primary storage)
      final String? unencryptedData = _prefs.getString('unencrypted_doses');
      if (unencryptedData != null) {
        try {
          final Map<String, dynamic> allDoses = json.decode(unencryptedData);
          if (allDoses.containsKey(doseId)) {
            // Mark as deleted instead of removing
            if (allDoses[doseId] is Map<String, dynamic>) {
              allDoses[doseId]['isDeleted'] = true;
              allDoses[doseId]['deletedAt'] = DateTime.now().toIso8601String();
              await _prefs.setString('unencrypted_doses', json.encode(allDoses));
              print('Dose marked as deleted in unencrypted local storage');
              localDeleteSuccessful = true;
            }
          }
        } catch (e) {
          print('Error marking dose as deleted in unencrypted storage: $e');
        }
      }
      
      // Try to mark as deleted in Firebase if user is authenticated and Firestore is available
      if (userId != null && _isFirestoreAvailable) {
        try {
          print('Attempting to mark dose as deleted in Firebase...');
          print('Collection path: users/$userId/medications/$medicationId/doses/$doseId');
          
          // Use a shorter timeout for Firebase operations
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(medicationId)
              .collection('doses')
              .doc(doseId)
              .update({
                'isDeleted': true,
                'deletedAt': DateTime.now().toIso8601String(),
              })
              .timeout(const Duration(seconds: 3));
          
          print('Firebase mark dose as deleted successful!');
        } catch (e) {
          // Firebase operation failed, but local delete was successful
          print('Firebase mark dose as deleted error: $e');
          print('Stack trace: ${StackTrace.current}');
          
          // If this is a NOT_FOUND error for the database, mark Firestore as unavailable
          if (e.toString().contains('NOT_FOUND') && 
              e.toString().contains('database') && 
              e.toString().contains('does not exist')) {
            print('Firestore database does not exist, marking as unavailable');
            _isFirestoreAvailable = false;
            await _prefs.setBool(_firestoreAvailableKey, false);
          }
          
          print('Continuing with local delete only');
          
          // If local delete also failed, throw an exception
          if (!localDeleteSuccessful) {
            throw Exception('Failed to mark dose as deleted in both local and remote storage');
          }
        }
      } else {
        if (!_isFirestoreAvailable) {
          print('Firestore is not available, marked dose as deleted locally only');
        } else {
          print('User not authenticated, marked dose as deleted locally only');
        }
      }
      
      print('=== DOSE DELETE COMPLETE ===');
    } catch (e) {
      print('Error during dose delete: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to delete dose: $e');
    }
  }

  // Schedules
  Future<void> addSchedule(schedule_lib.Schedule schedule) async {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Convert schedule to map
      final scheduleData = schedule.toMap();
      
      // Save to Firestore if available
      if (_isFirestoreAvailable) {
        try {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('schedules')
              .doc(schedule.id)
              .set(scheduleData);
        } catch (e) {
          print('Error saving schedule to Firestore: $e');
          // Fall back to local storage
        }
      }
      
      // Always save locally as backup
      await _saveLocalSchedule(schedule);
      
    } catch (e) {
      print('Error saving schedule: $e');
      throw Exception('Failed to save schedule: $e');
    }
  }

  // Update inventory
  Future<void> updateMedicationInventory(String medicationId, double newInventory) async {
    await _ensureInitialized();
    
    // Get the medication first
    final medications = await _getLocalMedications();
    final medIndex = medications.indexWhere((m) => m.id == medicationId);
    
    if (medIndex >= 0) {
      final med = medications[medIndex];
      final updatedMed = med.copyWithNewInventory(newInventory);
      
      // Save the updated medication
      await addMedication(updatedMed);
    }
  }

  // Improved deleteMedication method with better failsafe mechanisms
  Future<void> deleteMedication(String medicationId) async {
    await _ensureInitialized();
    
    print('=== MEDICATION DELETE DEBUG ===');
    print('Medication ID: $medicationId');
    
    final userId = _auth.currentUser?.uid;
    print('User ID: ${userId ?? "Not authenticated"}');
    
    try {
      bool localDeleteSuccessful = false;
      
      // First, mark as deleted in unencrypted storage (primary storage)
      final String? unencryptedData = _prefs.getString('unencrypted_medications');
      if (unencryptedData != null) {
        try {
          final Map<String, dynamic> allMedications = json.decode(unencryptedData);
          if (allMedications.containsKey(medicationId)) {
            // Mark as deleted instead of removing
            if (allMedications[medicationId] is Map<String, dynamic>) {
              allMedications[medicationId]['isDeleted'] = true;
              allMedications[medicationId]['deletedAt'] = DateTime.now().toIso8601String();
              await _prefs.setString('unencrypted_medications', json.encode(allMedications));
              print('Medication marked as deleted in unencrypted local storage');
              localDeleteSuccessful = true;
            }
          }
        } catch (e) {
          print('Error marking as deleted in unencrypted storage: $e');
        }
      }
      
      // Mark as deleted in encrypted storage (secondary storage)
      final String? storedData = _prefs.getString(_medicationsKey);
      if (storedData != null) {
        try {
          final Map<String, dynamic> allMedications = json.decode(storedData);
          if (allMedications.containsKey(medicationId)) {
            // Mark as deleted instead of removing
            if (allMedications[medicationId] is Map<String, dynamic>) {
              allMedications[medicationId]['isDeleted'] = await _encryptionService.encryptData('true');
              allMedications[medicationId]['deletedAt'] = await _encryptionService.encryptData(DateTime.now().toIso8601String());
              await _prefs.setString(_medicationsKey, json.encode(allMedications));
              print('Medication marked as deleted in encrypted local storage');
              localDeleteSuccessful = true;
            }
          }
        } catch (e) {
          print('Error marking as deleted in encrypted storage: $e');
        }
      }
      
      if (!localDeleteSuccessful) {
        print('Warning: Medication not found in local storage');
      }
      
      // Try to mark as deleted in Firebase if user is authenticated and Firestore is available
      if (userId != null && _isFirestoreAvailable) {
        try {
          print('Attempting to mark as deleted in Firebase...');
          print('Collection path: users/$userId/medications/$medicationId');
          
          // Use a shorter timeout for Firebase operations
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(medicationId)
              .update({
                'isDeleted': true,
                'deletedAt': DateTime.now().toIso8601String(),
              })
              .timeout(const Duration(seconds: 3));
          
          print('Firebase mark as deleted successful!');
        } catch (e) {
          // Firebase operation failed, but local delete was successful
          print('Firebase mark as deleted error: $e');
          print('Stack trace: ${StackTrace.current}');
          
          // If this is a NOT_FOUND error for the database, mark Firestore as unavailable
          if (e.toString().contains('NOT_FOUND') && 
              e.toString().contains('database') && 
              e.toString().contains('does not exist')) {
            print('Firestore database does not exist, marking as unavailable');
            _isFirestoreAvailable = false;
            await _prefs.setBool(_firestoreAvailableKey, false);
          }
          
          print('Continuing with local delete only');
          
          // If local delete also failed, throw an exception
          if (!localDeleteSuccessful) {
            throw Exception('Failed to mark medication as deleted in both local and remote storage');
          }
        }
      } else {
        if (!_isFirestoreAvailable) {
          print('Firestore is not available, marked as deleted locally only');
        } else {
          print('User not authenticated, marked as deleted locally only');
        }
      }
      
      print('=== MEDICATION DELETE COMPLETE ===');
    } catch (e) {
      print('Error during medication delete: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to delete medication: $e');
    }
  }

  // Permanently delete soft-deleted medications
  Future<void> purgeDeletedMedications() async {
    await _ensureInitialized();
    
    print('=== PURGE DELETED MEDICATIONS START ===');
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('User not authenticated, cannot purge deleted medications');
      return;
    }
    
    try {
      // Purge from local storage first
      final String? unencryptedData = _prefs.getString('unencrypted_medications');
      if (unencryptedData != null) {
        try {
          final Map<String, dynamic> allMedications = json.decode(unencryptedData);
          final List<String> idsToRemove = [];
          
          // Find all deleted medications
          for (final entry in allMedications.entries) {
            if (entry.value is Map<String, dynamic> && 
                entry.value['isDeleted'] == true) {
              idsToRemove.add(entry.key);
            }
          }
          
          // Remove them
          for (final id in idsToRemove) {
            allMedications.remove(id);
          }
          
          await _prefs.setString('unencrypted_medications', json.encode(allMedications));
          print('Purged ${idsToRemove.length} deleted medications from unencrypted storage');
        } catch (e) {
          print('Error purging from unencrypted storage: $e');
        }
      }
      
      // Purge from encrypted storage
      final String? storedData = _prefs.getString(_medicationsKey);
      if (storedData != null) {
        try {
          final Map<String, dynamic> allMedications = json.decode(storedData);
          final List<String> idsToRemove = [];
          
          // Find all deleted medications
          for (final entry in allMedications.entries) {
            if (entry.value is Map<String, dynamic> && 
                entry.value['isDeleted'] != null) {
              try {
                final String decryptedValue = await _encryptionService.decryptData(entry.value['isDeleted']);
                if (decryptedValue == 'true') {
                  idsToRemove.add(entry.key);
                }
              } catch (e) {
                print('Error decrypting isDeleted field: $e');
              }
            }
          }
          
          // Remove them
          for (final id in idsToRemove) {
            allMedications.remove(id);
          }
          
          await _prefs.setString(_medicationsKey, json.encode(allMedications));
          print('Purged ${idsToRemove.length} deleted medications from encrypted storage');
        } catch (e) {
          print('Error purging from encrypted storage: $e');
        }
      }
      
      // Purge from Firebase if available
      if (_isFirestoreAvailable) {
        try {
          // Get all deleted medications
          final snapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .where('isDeleted', isEqualTo: true)
              .get();
          
          // Delete them permanently
          final batch = _firestore.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          
          await batch.commit();
          print('Purged ${snapshot.docs.length} deleted medications from Firebase');
        } catch (e) {
          print('Error purging from Firebase: $e');
        }
      } else {
        print('Firestore is not available, skipping Firebase purge');
      }
      
      print('=== PURGE DELETED MEDICATIONS COMPLETE ===');
    } catch (e) {
      print('Error during purge: $e');
      throw Exception('Failed to purge deleted medications: $e');
    }
  }

  // Helper method to parse medication type from string
  MedicationType _parseMedicationType(String? typeString) {
    if (typeString == null) {
      return MedicationType.tablet; // Default to tablet
    }
    
    // Handle both formats: "MedicationType.tablet" and "tablet"
    final String normalizedType = typeString.contains('.') 
        ? typeString.split('.').last 
        : typeString;
    
    switch (normalizedType.toLowerCase()) {
      case 'tablet':
        return MedicationType.tablet;
      case 'capsule':
        return MedicationType.capsule;
      case 'injection':
      case 'prefilled_syringe':
      case 'prefilled_pen':
      case 'vial':
      case 'vial_premixed':
      case 'vial_powdered_known':
      case 'vial_powdered_recon':
        return MedicationType.injection;
      default:
        print('Unknown medication type: $typeString, defaulting to tablet');
        return MedicationType.tablet;
    }
  }
  
  // Helper method to parse injection type from string
  InjectionType? _parseInjectionType(String? typeString) {
    if (typeString == null) {
      return null; // Return null if no type provided
    }
    
    // Handle both formats: "InjectionType.liquidVial" and "liquidVial"
    final String normalizedType = typeString.contains('.') 
        ? typeString.split('.').last 
        : typeString;
    
    switch (normalizedType.toLowerCase()) {
      case 'liquidvial':
        return InjectionType.liquidVial;
      case 'powdervial':
        return InjectionType.powderVial;
      case 'prefilledsyringe':
        return InjectionType.prefilledSyringe;
      case 'prefilledpen':
        return InjectionType.prefilledPen;
      case 'cartridge':
        return InjectionType.cartridge;
      case 'ampule':
        return InjectionType.ampule;
      default:
        print('Unknown injection type: $typeString, returning null');
        return null;
    }
  }

  // Get all schedules for a specific dose
  Future<List<schedule_lib.Schedule>> getSchedulesForDose(String doseId) async {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      List<schedule_lib.Schedule> schedules = [];
      
      // Try to get from Firestore first
      if (_isFirestoreAvailable) {
        try {
          final snapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('schedules')
              .where('doseId', isEqualTo: doseId)
              .get();
          
          for (var doc in snapshot.docs) {
            schedules.add(schedule_lib.Schedule.fromMap(doc.data()));
          }
        } catch (e) {
          print('Error getting schedules from Firestore: $e');
          // Fall back to local storage
        }
      }
      
      // If Firestore failed or returned no results, try local storage
      if (schedules.isEmpty) {
        schedules = await _getLocalSchedulesForDose(doseId);
      }
      
      return schedules;
    } catch (e) {
      print('Error getting schedules: $e');
      throw Exception('Failed to get schedules: $e');
    }
  }
  
  // Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Delete from Firestore if available
      if (_isFirestoreAvailable) {
        try {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('schedules')
              .doc(scheduleId)
              .delete();
        } catch (e) {
          print('Error deleting schedule from Firestore: $e');
          // Continue to delete from local storage
        }
      }
      
      // Delete from local storage
      await _deleteLocalSchedule(scheduleId);
      
    } catch (e) {
      print('Error deleting schedule: $e');
      throw Exception('Failed to delete schedule: $e');
    }
  }
  
  // Update a dose status in a schedule
  Future<void> updateDoseStatus(String scheduleId, DateTime dateTime, dynamic status) async {
    await _ensureInitialized();
    
    try {
      // Get the schedule
      final schedule = await _getScheduleById(scheduleId);
      if (schedule == null) {
        throw Exception('Schedule not found');
      }
      
      // Update the status - convert the status to the correct type
      final scheduleStatus = status.toString().split('.').last;
      
      // Use the correct DoseStatus enum based on the schedule type
      final correctStatus = schedule_lib.DoseStatus.values.firstWhere(
          (s) => s.toString().split('.').last == scheduleStatus
      );
      
      final updatedSchedule = schedule.markDoseStatus(dateTime, correctStatus);
      
      // Save the updated schedule
      await addSchedule(updatedSchedule);
      
    } catch (e) {
      print('Error updating dose status: $e');
      throw Exception('Failed to update dose status: $e');
    }
  }
  
  // Get a schedule by ID
  Future<schedule_lib.Schedule?> _getScheduleById(String scheduleId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Try to get from Firestore first
      if (_isFirestoreAvailable) {
        try {
          final doc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('schedules')
              .doc(scheduleId)
              .get();
          
          if (doc.exists) {
            return schedule_lib.Schedule.fromMap(doc.data()!);
          }
        } catch (e) {
          print('Error getting schedule from Firestore: $e');
          // Fall back to local storage
        }
      }
      
      // Try to get from local storage
      return await _getLocalScheduleById(scheduleId);
      
    } catch (e) {
      print('Error getting schedule: $e');
      throw Exception('Failed to get schedule: $e');
    }
  }
  
  // Save a schedule to local storage
  Future<void> _saveLocalSchedule(schedule_lib.Schedule schedule) async {
    // Get existing schedules
    final String? schedulesJson = _prefs.getString('local_schedules');
    Map<String, dynamic> schedulesMap = json.decode(schedulesJson ?? '{}');
    
    // Add or update this schedule
    schedulesMap[schedule.id] = schedule.toMap();
    
    // Save back to preferences
    await _prefs.setString('local_schedules', json.encode(schedulesMap));
  }
  
  // Get all schedules for a dose from local storage
  Future<List<schedule_lib.Schedule>> _getLocalSchedulesForDose(String doseId) async {
    // Get all schedules
    final String? schedulesJson = _prefs.getString('local_schedules');
    Map<String, dynamic> schedulesMap = json.decode(schedulesJson ?? '{}');
    
    // Filter schedules for this dose
    List<schedule_lib.Schedule> schedules = [];
    schedulesMap.forEach((id, data) {
      if (data['doseId'] == doseId) {
        schedules.add(schedule_lib.Schedule.fromMap(data));
      }
    });
    
    return schedules;
  }
  
  // Get a schedule by ID from local storage
  Future<schedule_lib.Schedule?> _getLocalScheduleById(String scheduleId) async {
    // Get all schedules
    final String? schedulesJson = _prefs.getString('local_schedules');
    Map<String, dynamic> schedulesMap = json.decode(schedulesJson ?? '{}');
    
    // Find the schedule by ID
    if (schedulesMap.containsKey(scheduleId)) {
      return schedule_lib.Schedule.fromMap(schedulesMap[scheduleId]);
    }
    
    return null;
  }
  
  // Delete a schedule from local storage
  Future<void> _deleteLocalSchedule(String scheduleId) async {
    // Get existing schedules
    final String? schedulesJson = _prefs.getString('local_schedules');
    Map<String, dynamic> schedulesMap = json.decode(schedulesJson ?? '{}');
    
    // Remove this schedule
    schedulesMap.remove(scheduleId);
    
    // Save back to preferences
    await _prefs.setString('local_schedules', json.encode(schedulesMap));
  }

  // Add a medication schedule
  Future<void> addMedicationSchedule(med_schedule_lib.MedicationSchedule schedule) async {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    print('=== MEDICATION SCHEDULE SAVE DEBUG ===');
    print('Schedule ID: ${schedule.id}');
    print('Medication ID: ${schedule.medicationId}');
    print('Dose ID: ${schedule.doseId}');
    print('Schedule Name: ${schedule.name}');
    print('User ID: ${userId ?? "Not authenticated"}');
    
    try {
      // Save to local storage first
      await _saveLocalMedicationSchedule(schedule);
      print('Saved schedule to local storage');
      
      // Try to save to Firebase if user is authenticated and Firestore is available
      if (userId != null && _isFirestoreAvailable) {
        try {
          print('Attempting to save schedule to Firebase...');
          
          // Convert schedule to map
          final scheduleData = schedule.toMap();
          
          // Encrypt sensitive data
          Map<String, dynamic> encryptedData = await _encryptDataForFirebase(scheduleData);
          
          // Save to Firebase
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(schedule.medicationId)
              .collection('doses')
              .doc(schedule.doseId)
              .collection('schedules')
              .doc(schedule.id)
              .set(encryptedData)
              .timeout(const Duration(seconds: 5));
          
          print('Firebase schedule save successful!');
        } catch (e) {
          print('Firebase schedule save error: $e');
          print('Continuing with local save only');
        }
      } else {
        print('User not authenticated or Firestore unavailable, saving locally only');
      }
    } catch (e) {
      print('Error saving medication schedule: $e');
      throw Exception('Failed to save medication schedule: $e');
    }
  }
  
  // Get all schedules for a specific dose
  Future<List<med_schedule_lib.MedicationSchedule>> getMedicationSchedules(String medicationId, String doseId) async {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    print('=== GET MEDICATION SCHEDULES DEBUG ===');
    print('Medication ID: $medicationId');
    print('Dose ID: $doseId');
    print('User ID: ${userId ?? "Not authenticated"}');
    
    try {
      // Get from local storage first
      final localSchedules = await _getLocalMedicationSchedules(medicationId, doseId);
      print('Retrieved ${localSchedules.length} schedules from local storage');
      
      // Try to get from Firebase if user is authenticated and Firestore is available
      if (userId != null && _isFirestoreAvailable) {
        try {
          print('Attempting to get schedules from Firebase...');
          
          final querySnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(medicationId)
              .collection('doses')
              .doc(doseId)
              .collection('schedules')
              .get()
              .timeout(const Duration(seconds: 5));
          
          if (querySnapshot.docs.isNotEmpty) {
            print('Retrieved ${querySnapshot.docs.length} schedules from Firebase');
            
            // Decrypt and convert to MedicationSchedule objects
            final List<med_schedule_lib.MedicationSchedule> schedules = [];
            for (var doc in querySnapshot.docs) {
              try {
                final decryptedData = await _decryptDataFromFirebase(doc.data());
                final schedule = med_schedule_lib.MedicationSchedule.fromMap(decryptedData);
                schedules.add(schedule);
              } catch (e) {
                print('Error decrypting schedule ${doc.id}: $e');
              }
            }
            
            // Save to local storage for offline access
            await _saveLocalMedicationSchedules(schedules);
            
            return schedules;
          }
        } catch (e) {
          print('Firebase get schedules error: $e');
          print('Falling back to local storage');
        }
      }
      
      // Return local schedules if Firebase retrieval failed or user is not authenticated
      return localSchedules;
    } catch (e) {
      print('Error getting medication schedules: $e');
      return [];
    }
  }
  
  // Mark a dose as taken and update inventory if needed
  Future<void> markDoseTaken(dynamic schedule, DateTime doseDateTime) async {
    await _ensureInitialized();
    
    print('=== MARK DOSE TAKEN DEBUG ===');
    print('Schedule ID: ${schedule.id}');
    print('Medication ID: ${schedule.medicationId}');
    print('Dose ID: ${schedule.doseId}');
    print('Dose DateTime: $doseDateTime');
    
    try {
      // Get the dose to calculate inventory reduction
      final dose = await getDose(schedule.doseId, schedule.medicationId);
      if (dose == null) {
        print('Dose not found, cannot mark as taken');
        return;
      }
      
      // Get the medication to update inventory
      final medication = await getMedication(schedule.medicationId);
      if (medication == null) {
        print('Medication not found, cannot update inventory');
        return;
      }
      
      // Update the schedule status
      // Use the correct DoseStatus enum based on the schedule type
      dynamic updatedSchedule;
      
      if (schedule.runtimeType.toString().contains('MedicationSchedule')) {
        // Use MedicationSchedule's DoseStatus
        final takenStatus = med_schedule_lib.DoseStatus.taken;
        updatedSchedule = schedule.markDoseStatus(doseDateTime, takenStatus);
        await addMedicationSchedule(updatedSchedule);
      } else {
        // Use Schedule's DoseStatus
        final takenStatus = schedule_lib.DoseStatus.taken;
        updatedSchedule = schedule.markDoseStatus(doseDateTime, takenStatus);
        await addSchedule(updatedSchedule);
      }
      
      // Deduct from inventory if enabled
      bool deductFromInventory = true;
      if (schedule.runtimeType.toString().contains('MedicationSchedule')) {
        deductFromInventory = schedule.deductFromInventory;
      }
      
      if (deductFromInventory) {
        // Calculate how much to deduct
        final inventoryReduction = dose.calculateInventoryReduction(medication.strength);
        
        // Update medication inventory
        final newInventory = medication.currentInventory - inventoryReduction;
        final updatedMedication = medication.copyWithNewInventory(
            newInventory < 0 ? 0 : newInventory);
        
        // Save updated medication
        await addMedication(updatedMedication);
        
        print('Updated medication inventory: ${medication.currentInventory} -> ${updatedMedication.currentInventory}');
      }
    } catch (e) {
      print('Error marking dose as taken: $e');
      throw Exception('Failed to mark dose as taken: $e');
    }
  }
  
  // Local storage methods for medication schedules
  Future<void> _saveLocalMedicationSchedule(med_schedule_lib.MedicationSchedule schedule) async {
    // Get existing schedules
    final List<med_schedule_lib.MedicationSchedule> schedules = await _getLocalMedicationSchedules(
        schedule.medicationId ?? '', schedule.doseId);
    
    // Replace or add the schedule
    final index = schedules.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      schedules[index] = schedule;
    } else {
      schedules.add(schedule);
    }
    
    // Save back to local storage
    await _saveLocalMedicationSchedules(schedules);
  }
  
  Future<void> _saveLocalMedicationSchedules(List<med_schedule_lib.MedicationSchedule> schedules) async {
    if (schedules.isEmpty) return;
    
    // Group schedules by medication and dose
    final Map<String, Map<String, List<Map<String, dynamic>>>> groupedSchedules = {};
    
    for (var schedule in schedules) {
      final medicationId = schedule.medicationId ?? '';
      final doseId = schedule.doseId;
      
      if (!groupedSchedules.containsKey(medicationId)) {
        groupedSchedules[medicationId] = {};
      }
      
      if (!groupedSchedules[medicationId]!.containsKey(doseId)) {
        groupedSchedules[medicationId]![doseId] = [];
      }
      
      groupedSchedules[medicationId]![doseId]!.add(schedule.toMap());
    }
    
    // Save each group
    for (var medicationId in groupedSchedules.keys) {
      for (var doseId in groupedSchedules[medicationId]!.keys) {
        final key = 'medication_schedules_${medicationId}_${doseId}';
        final jsonData = jsonEncode(groupedSchedules[medicationId]![doseId]);
        
        // Encrypt the data
        final encryptedData = await _encryptionService.encrypt(jsonData);
        await _prefs.setString(key, encryptedData);
      }
    }
  }
  
  Future<List<med_schedule_lib.MedicationSchedule>> _getLocalMedicationSchedules(
      String medicationId, String doseId) async {
    final key = 'medication_schedules_${medicationId}_${doseId}';
    
    // Get encrypted data
    final String? encryptedData = _prefs.getString(key);
    if (encryptedData == null) {
      return [];
    }
    
    try {
      // Decrypt the data
      final String decryptedData = await _encryptionService.decrypt(encryptedData);
      final List<dynamic> jsonData = jsonDecode(decryptedData);
      
      // Convert to MedicationSchedule objects
      return jsonData.map((data) => 
          med_schedule_lib.MedicationSchedule.fromMap(Map<String, dynamic>.from(data))).toList();
    } catch (e) {
      print('Error decrypting medication schedules: $e');
      return [];
    }
  }
  
  // Delete a medication schedule
  Future<void> deleteMedicationSchedule(String scheduleId, String medicationId, String doseId) async {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    print('=== DELETE MEDICATION SCHEDULE DEBUG ===');
    print('Schedule ID: $scheduleId');
    print('Medication ID: $medicationId');
    print('Dose ID: $doseId');
    print('User ID: ${userId ?? "Not authenticated"}');
    
    try {
      // Delete from local storage first
      final schedules = await _getLocalMedicationSchedules(medicationId, doseId);
      final filteredSchedules = schedules.where((s) => s.id != scheduleId).toList();
      await _saveLocalMedicationSchedules(filteredSchedules);
      
      // Try to delete from Firebase if user is authenticated and Firestore is available
      if (userId != null && _isFirestoreAvailable) {
        try {
          print('Attempting to delete schedule from Firebase...');
          
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(medicationId)
              .collection('doses')
              .doc(doseId)
              .collection('schedules')
              .doc(scheduleId)
              .delete()
              .timeout(const Duration(seconds: 5));
          
          print('Firebase schedule delete successful!');
        } catch (e) {
          print('Firebase schedule delete error: $e');
        }
      }
    } catch (e) {
      print('Error deleting medication schedule: $e');
      throw Exception('Failed to delete medication schedule: $e');
    }
  }

  // Get a specific medication by ID
  Future<Medication?> getMedication(String medicationId) async {
    await _ensureInitialized();
    
    print('=== GET MEDICATION DEBUG ===');
    print('Medication ID: $medicationId');
    
    try {
      // Try to get from local storage first
      final medicationsStream = await getMedications();
      final medications = await medicationsStream.first;
      final medication = medications.firstWhere(
        (med) => med.id == medicationId,
        orElse: () => throw Exception('Medication not found'),
      );
      
      print('Medication found: ${medication.name}');
      return medication;
    } catch (e) {
      print('Error getting medication: $e');
      return null;
    }
  }
  
  // Get a specific dose by ID
  Future<Dose?> getDose(String doseId, String medicationId) async {
    await _ensureInitialized();
    
    print('=== GET DOSE DEBUG ===');
    print('Dose ID: $doseId');
    print('Medication ID: $medicationId');
    
    try {
      // Try to get from local storage first
      final List<Dose> doses = await getDosesForMedication(medicationId);
      final dose = doses.firstWhere(
        (d) => d.id == doseId,
        orElse: () => throw Exception('Dose not found'),
      );
      
      print('Dose found: ${dose.amount} ${dose.unit}');
      return dose;
    } catch (e) {
      print('Error getting dose: $e');
      return null;
    }
  }
  
  // Get all doses for a medication
  Future<List<Dose>> getDoses(String medicationId) async {
    return getDosesForMedication(medicationId);
  }

  /// Improved logging for debugging
  void _log(String message) {
    if (kDebugMode) {
      print('FirebaseService: $message');
    }
  }
  
  /// Error logging with stack trace
  void _logError(String message, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('FirebaseService ERROR: $message');
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      } else if (error is Error) {
        print('Stack trace: ${error.stackTrace}');
      }
    }
  }

  // Utility method to safely decrypt a string
  Future<String> _safeDecrypt(String? value, {String defaultValue = ''}) async {
    if (value == null || value.isEmpty) {
      return defaultValue;
    }
    
    try {
      // Try to decrypt the value
      final decrypted = await _encryptionService.decryptData(value);
      return decrypted;
    } catch (e) {
      _logError('Safe decrypt failed', e);
      // Return the original value if decryption fails
      return value;
    }
  }
} 
