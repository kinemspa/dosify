import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/medication.dart';
import 'encryption_service.dart';
import 'cache_manager.dart';

/// Handles caching operations for Firebase data
class FirebaseCacheManager {
  final CacheManager? _cacheManager;
  final EncryptionService _encryptionService;
  final SharedPreferences _prefs;

  static const String _medicationsKey = 'local_medications';

  FirebaseCacheManager({
    required CacheManager? cacheManager,
    required EncryptionService encryptionService,
    required SharedPreferences prefs,
  }) : _cacheManager = cacheManager,
       _encryptionService = encryptionService,
       _prefs = prefs;

  Future<void> initialize() async {
    // Initialize cache operations
  }

  Future<void> storeMedicationLocally(String medicationId, Map<String, dynamic> data) async {
    try {
      final encryptedData = await _encryptionService.encryptMedicationData(data);
      final localMedications = await _getLocalMedications();
      localMedications[medicationId] = encryptedData;
      await _saveLocalMedications(localMedications);
    } catch (e) {
      _log('Failed to store medication locally: $e');
    }
  }

  Future<Map<String, dynamic>?> getMedicationLocally(String medicationId) async {
    try {
      final localMedications = await _getLocalMedications();
      final encryptedData = localMedications[medicationId];
      if (encryptedData != null) {
        return await _encryptionService.decryptMedicationData(
          Map<String, dynamic>.from(encryptedData)
        );
      }
    } catch (e) {
      _log('Failed to get medication locally: $e');
    }
    return null;
  }

  Future<void> deleteMedicationLocally(String medicationId) async {
    try {
      final localMedications = await _getLocalMedications();
      localMedications.remove(medicationId);
      await _saveLocalMedications(localMedications);
    } catch (e) {
      _log('Failed to delete medication locally: $e');
    }
  }

  Future<List<Medication>> getAllMedicationsLocally() async {
    try {
      final localMedications = await _getLocalMedications();
      final medications = <Medication>[];
      
      for (final entry in localMedications.entries) {
        try {
          final decryptedData = await _encryptionService.decryptMedicationData(
            Map<String, dynamic>.from(entry.value)
          );
          decryptedData['id'] = entry.key;
          medications.add(Medication.fromFirestoreData(decryptedData));
        } catch (e) {
          _log('Error processing cached medication ${entry.key}: $e');
        }
      }
      
      return medications;
    } catch (e) {
      _log('Failed to get all medications locally: $e');
      return [];
    }
  }

  Future<void> clearAllMedications() async {
    try {
      await _prefs.remove(_medicationsKey);
      _log('Cleared all local medications');
    } catch (e) {
      _log('Failed to clear all medications: $e');
    }
  }

  Future<Map<String, dynamic>> _getLocalMedications() async {
    try {
      final data = _prefs.getString(_medicationsKey);
      if (data != null) {
        return Map<String, dynamic>.from(json.decode(data));
      }
    } catch (e) {
      _log('Failed to parse local medications: $e');
    }
    return {};
  }

  Future<void> _saveLocalMedications(Map<String, dynamic> medications) async {
    try {
      final data = json.encode(medications);
      await _prefs.setString(_medicationsKey, data);
    } catch (e) {
      _log('Failed to save local medications: $e');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      print('FirebaseCacheManager: $message');
    }
  }
}
