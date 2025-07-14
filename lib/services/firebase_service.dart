import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async'; // Add this import for TimeoutException
import '../models/medication.dart';
import '../models/dose.dart';
import '../models/schedule.dart';
import 'encryption_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryptionService = EncryptionService();
  bool _isInitialized = false;
  bool _isFirestoreAvailable = true; // Track if Firestore is available
  
  // Local cache keys
  static const String _medicationsKey = 'local_medications';
  static const String _lastSyncKey = 'last_sync_time';
  static const String _firestoreAvailableKey = 'firestore_available';

  // Initialize
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _encryptionService.initialize();
    
    // Check if we've previously determined Firestore is unavailable
    final prefs = await SharedPreferences.getInstance();
    _isFirestoreAvailable = prefs.getBool(_firestoreAvailableKey) ?? true;
    
    if (_isFirestoreAvailable) {
      // Configure Firestore for offline persistence
      // Fix: Don't use await on a non-Future value
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
        print('Firestore is not available: $e');
        _isFirestoreAvailable = false;
        
        // Save this information for future app starts
        await prefs.setBool(_firestoreAvailableKey, false);
      }
    } else {
      print('Firestore was previously marked as unavailable, skipping connection attempt');
    }
    
    _isInitialized = true;
  }

  // Reset Firestore availability status (for testing)
  Future<void> resetFirestoreStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firestoreAvailableKey, true);
    _isFirestoreAvailable = true;
    print('Firestore availability status reset to true');
  }

  // Check if Firestore database exists
  Future<bool> checkDatabaseExists() async {
    await _ensureInitialized();
    
    try {
      // Try to access a collection to see if the database exists
      await _firestore.collection('test').doc('test').get()
          .timeout(const Duration(seconds: 5));
      
      // If we get here, the database exists
      _isFirestoreAvailable = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firestoreAvailableKey, true);
      return true;
    } catch (e) {
      if (e.toString().contains('NOT_FOUND') && 
          e.toString().contains('database') && 
          e.toString().contains('does not exist')) {
        print('Firestore database does not exist');
        _isFirestoreAvailable = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_firestoreAvailableKey, false);
        return false;
      }
      
      // Some other error
      print('Error checking database: $e');
      return false;
    }
  }

  // Get Firestore status
  bool get isFirestoreAvailable => _isFirestoreAvailable;

  // Ensure initialized
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
      final prefs = await SharedPreferences.getInstance();
      
      // Clear encrypted storage
      await prefs.remove(_medicationsKey);
      print('Cleared encrypted medications');
      
      // Clear unencrypted storage
      await prefs.remove('unencrypted_medications');
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
      'type': medication.type.toString(),
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
    
    try {
      // IMPORTANT: Always save unencrypted data first as a guaranteed fallback
      await _saveLocalMedicationUnencrypted(medication);
      print('Saved unencrypted data as primary local storage');
      
      // Try to save to Firebase if user is authenticated and Firestore is available
      bool firebaseSaveSuccessful = false;
      if (userId != null && _isFirestoreAvailable) {
        try {
          print('Attempting to save to Firebase...');
          print('Collection path: users/$userId/medications/${medication.id}');
          
          // Encrypt sensitive data before sending to Firebase
          Map<String, dynamic> encryptedDataForFirebase = await _encryptDataForFirebase(medicationData);
          
          // Use a shorter timeout for Firebase operations
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(medication.id)
              .set(encryptedDataForFirebase)
              .timeout(const Duration(seconds: 3));
          
          print('Firebase save successful!');
          firebaseSaveSuccessful = true;
        } catch (e) {
          // Firebase operation failed, continue with local save only
          print('Firebase save error: $e');
          print('Stack trace: ${StackTrace.current}');
          
          // If this is a NOT_FOUND error for the database, mark Firestore as unavailable
          if (e.toString().contains('NOT_FOUND') && 
              e.toString().contains('database') && 
              e.toString().contains('does not exist')) {
            print('Firestore database does not exist, marking as unavailable');
            _isFirestoreAvailable = false;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_firestoreAvailableKey, false);
          }
          
          print('Continuing with local save only');
        }
      } else {
        if (!_isFirestoreAvailable) {
          print('Firestore is not available, saving locally only');
        } else {
          print('User not authenticated, saving locally only');
        }
      }
      
      // Only try encryption as a secondary storage option
      try {
        print('Attempting to encrypt medication data...');
        final encryptedData = await _encryptionService.encryptMedicationData(medicationData);
        print('Encryption successful');
        
        // Save encrypted data locally as a secondary backup
        await _saveLocalMedication(medication.id, encryptedData);
        print('Local encrypted save successful');
      } catch (e) {
        print('Encryption error: $e');
        print('Stack trace: ${StackTrace.current}');
        print('Skipping encrypted local storage');
      }
      
      print('=== MEDICATION SAVE COMPLETE ===');
    } catch (e) {
      print('Error during medication save: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to save medication: $e');
    }
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
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing medications
    final String? storedData = prefs.getString(_medicationsKey);
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
      await prefs.setString(_medicationsKey, json.encode(allMedications));
      print('Successfully saved medication $id to local storage');
    } catch (e) {
      print('Error saving to SharedPreferences: $e');
      throw Exception('Failed to save medication locally: $e');
    }
  }
  
  // Save medication locally (unencrypted - emergency fallback)
  Future<void> _saveLocalMedicationUnencrypted(Medication medication) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing medications
    final String? storedData = prefs.getString('unencrypted_medications');
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
      'type': medication.type.toString(),
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
    
    // Save back to shared preferences
    try {
      await prefs.setString('unencrypted_medications', json.encode(allMedications));
      print('Successfully saved unencrypted medication ${medication.id} to local storage');
    } catch (e) {
      print('Error saving unencrypted medication to SharedPreferences: $e');
      throw Exception('Failed to save unencrypted medication locally: $e');
    }
  }

  // Get user's medications
  Stream<List<Medication>> getMedications() async* {
    await _ensureInitialized();
    
    final userId = _auth.currentUser?.uid;
    List<Medication> medications = [];
    
    print('=== GET MEDICATIONS DEBUG ===');
    print('User ID: ${userId ?? "Not authenticated"}');
    
    if (!_isFirestoreAvailable) {
      print('Firestore is not available, using local-only mode');
    } else if (userId == null) {
      print('User not authenticated, using local-only mode');
    } else {
      print('Firestore is available, attempting to get remote data');
    }
    
    // Get local data
    medications = await _getLocalMedications();
    print('Retrieved ${medications.length} medications from local storage');
    yield medications;
    
    // Only try to get from Firebase if Firestore is available and user is authenticated
    if (_isFirestoreAvailable && userId != null) {
      try {
        print('Setting up Firebase medications stream...');
        await for (var snapshot in _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .snapshots()
            .timeout(const Duration(seconds: 5), onTimeout: (sink) {
              print('Firebase stream timed out');
              sink.close();
            })) {
          
          List<Medication> remoteMeds = [];
          
          for (var doc in snapshot.docs) {
            try {
              final encryptedData = doc.data();
              
              // Decrypt the data from Firebase
              final data = await _decryptDataFromFirebase(encryptedData);
              
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
                type: MedicationType.values.firstWhere(
                    (e) => e.toString() == data['type']?.toString(),
                    orElse: () => MedicationType.tablet),
                strength: strength,
                strengthUnit: data['strengthUnit']?.toString() ?? 'mg',
                quantity: inventory, // Use inventory for quantity
                quantityUnit: data['quantityUnit']?.toString() ?? 'tablets',
                currentInventory: inventory,
                lastInventoryUpdate: DateTime.now(),
                reconstitutionVolume: reconstitutionVolume,
                reconstitutionVolumeUnit: reconstitutionVolumeUnit,
                concentrationAfterReconstitution: concentrationAfterReconstitution,
              ));
            } catch (e) {
              // Skip medications that can't be processed
              print('Error processing remote medication: $e');
            }
          }
          
          print('Retrieved ${remoteMeds.length} medications from Firebase');
          
          // Merge with local-only medications
          final localOnlyMeds = medications.where(
            (local) => !remoteMeds.any((remote) => remote.id == local.id)
          ).toList();
          
          medications = [...remoteMeds, ...localOnlyMeds];
          
          // Update local cache with the latest data
          _updateLocalMedicationsCache(medications);
          
          yield medications;
        }
      } catch (e) {
        // If Firebase fails, just use local data
        print('Firebase stream error: $e');
        
        // If this is a NOT_FOUND error for the database, mark Firestore as unavailable
        if (e.toString().contains('NOT_FOUND') && 
            e.toString().contains('database') && 
            e.toString().contains('does not exist')) {
          print('Firestore database does not exist, marking as unavailable');
          _isFirestoreAvailable = false;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_firestoreAvailableKey, false);
        }
        
        yield medications;
      }
    }
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
      decryptedData['name'] = await _encryptionService.decryptData(encryptedData['name']);
    }
    
    // Decrypt numeric values
    for (String field in ['strength', 'tabletsInStock']) {
      if (encryptedData.containsKey(field)) {
        final decryptedStr = await _encryptionService.decryptData(encryptedData[field]);
        decryptedData[field] = double.tryParse(decryptedStr) ?? 0.0;
      }
    }
    
    // Decrypt string values
    for (String field in ['strengthUnit', 'quantityUnit']) {
      if (encryptedData.containsKey(field)) {
        decryptedData[field] = await _encryptionService.decryptData(encryptedData[field]);
      }
    }
    
    // Decrypt optional fields
    for (String field in ['reconstitutionVolume', 'reconstitutionVolumeUnit', 'concentrationAfterReconstitution']) {
      if (encryptedData.containsKey(field) && encryptedData[field] != null) {
        final decrypted = await _encryptionService.decryptData(encryptedData[field]);
        if (field == 'reconstitutionVolume' || field == 'concentrationAfterReconstitution') {
          decryptedData[field] = double.tryParse(decrypted) ?? 0.0;
        } else {
          decryptedData[field] = decrypted;
        }
      }
    }
    
    print('Data decrypted from Firebase storage');
    return decryptedData;
  }
  
  // Get medications from local storage
  Future<List<Medication>> _getLocalMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Medication> medications = [];
    
    // Try to get unencrypted medications first (more reliable)
    final String? unencryptedData = prefs.getString('unencrypted_medications');
    if (unencryptedData != null) {
      try {
        final Map<String, dynamic> allMedications = json.decode(unencryptedData);
        print('Retrieved ${allMedications.length} unencrypted medications from local storage');
        
        for (var entry in allMedications.entries) {
          try {
            final id = entry.key;
            final data = entry.value;
            
            if (data is Map<String, dynamic>) {
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
                name: data['name']?.toString() ?? 'Unknown Medication',
                type: MedicationType.values.firstWhere(
                    (e) => e.toString() == data['type']?.toString(),
                    orElse: () => MedicationType.tablet),
                strength: strength,
                strengthUnit: data['strengthUnit']?.toString() ?? 'mg',
                quantity: inventory, // Use inventory for quantity
                quantityUnit: data['quantityUnit']?.toString() ?? 'tablets',
                currentInventory: inventory,
                lastInventoryUpdate: DateTime.now(),
                reconstitutionVolume: reconstitutionVolume,
                reconstitutionVolumeUnit: reconstitutionVolumeUnit,
                concentrationAfterReconstitution: concentrationAfterReconstitution,
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
    final String? storedData = prefs.getString(_medicationsKey);
    if (storedData != null) {
      try {
        final Map<String, dynamic> allMedications = json.decode(storedData);
        print('Retrieved ${allMedications.length} encrypted medications from local storage');
        
        for (var entry in allMedications.entries) {
          try {
            final id = entry.key;
            final data = entry.value;
            
            if (data is Map<String, dynamic>) {
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
    final prefs = await SharedPreferences.getInstance();
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
    await prefs.setString(_medicationsKey, json.encode(allMedications));
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Doses
  Future<void> addDose(Dose dose) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final encryptedData = {
      'medicationId': dose.medicationId,
      'amount': _encryptionService.encryptData(dose.amount.toString()),
      'unit': _encryptionService.encryptData(dose.unit),
      'notes': dose.notes != null ? _encryptionService.encryptData(dose.notes!) : null,
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('doses')
        .doc(dose.id)
        .set(encryptedData);
  }

  // Schedules
  Future<void> addSchedule(Schedule schedule) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final encryptedData = {
      'doseId': schedule.doseId,
      'frequency': schedule.frequency.toString(),
      'startDate': schedule.startDate.toIso8601String(),
      'endDate': schedule.endDate?.toIso8601String(),
      'scheduledTimes': schedule.scheduledTimes
          .map((time) => time.toIso8601String())
          .toList(),
      'completedDoses': Map.fromEntries(
        schedule.completedDoses.entries.map(
          (e) => MapEntry(e.key.toIso8601String(), e.value),
        ),
      ),
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('schedules')
        .doc(schedule.id)
        .set(encryptedData);
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
      
      // First, delete from unencrypted storage (primary storage)
      final prefs = await SharedPreferences.getInstance();
      final String? unencryptedData = prefs.getString('unencrypted_medications');
      if (unencryptedData != null) {
        try {
          final Map<String, dynamic> allMedications = json.decode(unencryptedData);
          if (allMedications.containsKey(medicationId)) {
            allMedications.remove(medicationId);
            await prefs.setString('unencrypted_medications', json.encode(allMedications));
            print('Medication removed from unencrypted local storage');
            localDeleteSuccessful = true;
          }
        } catch (e) {
          print('Error removing from unencrypted storage: $e');
        }
      }
      
      // Delete from encrypted storage (secondary storage)
      final String? storedData = prefs.getString(_medicationsKey);
      if (storedData != null) {
        try {
          final Map<String, dynamic> allMedications = json.decode(storedData);
          if (allMedications.containsKey(medicationId)) {
            allMedications.remove(medicationId);
            await prefs.setString(_medicationsKey, json.encode(allMedications));
            print('Medication removed from encrypted local storage');
            localDeleteSuccessful = true;
          }
        } catch (e) {
          print('Error removing from encrypted storage: $e');
        }
      }
      
      if (!localDeleteSuccessful) {
        print('Warning: Medication not found in local storage');
      }
      
      // Try to delete from Firebase if user is authenticated and Firestore is available
      if (userId != null && _isFirestoreAvailable) {
        try {
          print('Attempting to delete from Firebase...');
          print('Collection path: users/$userId/medications/$medicationId');
          
          // Use a shorter timeout for Firebase operations
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(medicationId)
              .delete()
              .timeout(const Duration(seconds: 3));
          
          print('Firebase delete successful!');
        } catch (e) {
          // Firebase operation failed, but local delete was successful
          print('Firebase delete error: $e');
          print('Stack trace: ${StackTrace.current}');
          
          // If this is a NOT_FOUND error for the database, mark Firestore as unavailable
          if (e.toString().contains('NOT_FOUND') && 
              e.toString().contains('database') && 
              e.toString().contains('does not exist')) {
            print('Firestore database does not exist, marking as unavailable');
            _isFirestoreAvailable = false;
            await prefs.setBool(_firestoreAvailableKey, false);
          }
          
          print('Continuing with local delete only');
          
          // If local delete also failed, throw an exception
          if (!localDeleteSuccessful) {
            throw Exception('Failed to delete medication from both local and remote storage');
          }
        }
      } else {
        if (!_isFirestoreAvailable) {
          print('Firestore is not available, deleted locally only');
        } else {
          print('User not authenticated, deleted locally only');
        }
      }
      
      print('=== MEDICATION DELETE COMPLETE ===');
    } catch (e) {
      print('Error during medication delete: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to delete medication: $e');
    }
  }
} 
