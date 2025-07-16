import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/medication.dart';
import '../models/paginated_result.dart';
import 'encryption_service.dart';
import 'query_optimizer.dart';
import 'firebase_cache_manager.dart';
import 'firebase_error_handler.dart';

/// Repository for medication-related operations
class MedicationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;
  final QueryOptimizer? _queryOptimizer;
  final FirebaseCacheManager _cacheOperations;
  final FirebaseErrorHandler _errorHandler;

  static const Duration _operationTimeout = Duration(seconds: 10);
  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 100;

  MedicationRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required EncryptionService encryptionService,
    required QueryOptimizer? queryOptimizer,
    required FirebaseCacheManager cacheOperations,
    required FirebaseErrorHandler errorHandler,
  }) : _firestore = firestore,
       _auth = auth,
       _encryptionService = encryptionService,
       _queryOptimizer = queryOptimizer,
       _cacheOperations = cacheOperations,
       _errorHandler = errorHandler;

  CollectionReference get _collection => _firestore.collection('medications');

  Future<void> addMedication(Medication medication) async {
    final userId = _requireUserId();
    
    try {
      final medicationData = await _prepareMedicationData(medication, userId);
      
      // Save locally first
      await _cacheOperations.storeMedicationLocally(medication.id, medicationData);
      
      // Then save to Firestore if available
      await _collection.doc(medication.id).set(medicationData)
          .timeout(_operationTimeout);
      
      _log('Medication added successfully: ${medication.id}');
    } catch (e) {
      await _errorHandler.handleError('Failed to add medication', e);
      rethrow;
    }
  }

  Future<void> updateMedication(Medication medication) async {
    final userId = _requireUserId();
    
    try {
      final medicationData = await _prepareMedicationData(medication, userId);
      medicationData['updatedAt'] = DateTime.now().toIso8601String();
      
      // Update locally first
      await _cacheOperations.storeMedicationLocally(medication.id, medicationData);
      
      // Then update Firestore if available
      await _collection.doc(medication.id).update(medicationData)
          .timeout(_operationTimeout);
      
      _log('Medication updated successfully: ${medication.id}');
    } catch (e) {
      await _errorHandler.handleError('Failed to update medication', e);
      rethrow;
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    _requireUserId();
    
    try {
      // Delete locally first
      await _cacheOperations.deleteMedicationLocally(medicationId);
      
      // Then delete from Firestore if available
      await _collection.doc(medicationId).delete()
          .timeout(_operationTimeout);
      
      _log('Medication deleted successfully: $medicationId');
    } catch (e) {
      await _errorHandler.handleError('Failed to delete medication', e);
      rethrow;
    }
  }

  Future<Medication?> getMedication(String medicationId) async {
    final userId = _requireUserId();
    
    try {
      // Try cache first
      final cachedData = await _cacheOperations.getMedicationLocally(medicationId);
      if (cachedData != null) {
        return Medication.fromFirestoreData(cachedData);
      }
      
      // Fall back to Firestore
      final doc = await _collection.doc(medicationId).get()
          .timeout(_operationTimeout);
      
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      
      // Decrypt and cache
      final decryptedData = await _encryptionService.decryptMedicationData(data);
      await _cacheOperations.storeMedicationLocally(medicationId, decryptedData);
      
      return Medication.fromFirestoreData(decryptedData);
    } catch (e) {
      await _errorHandler.handleError('Failed to get medication', e);
      return null;
    }
  }

  Stream<List<Medication>> getMedications() async* {
    final userId = _requireUserId();
    
    try {
      // First yield cached medications
      final cachedMedications = await _cacheOperations.getAllMedicationsLocally();
      if (cachedMedications.isNotEmpty) {
        yield cachedMedications;
      }
      
      // Then listen to Firestore updates
      await for (final snapshot in _collection
          .where('userId', isEqualTo: userId)
          .snapshots()
          .timeout(_operationTimeout)) {
        
        final medications = <Medication>[];
        
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            
            final decryptedData = await _encryptionService.decryptMedicationData(data);
            final medication = Medication.fromFirestoreData(decryptedData);
            medications.add(medication);
            
            // Cache each medication
            await _cacheOperations.storeMedicationLocally(doc.id, decryptedData);
          } catch (e) {
            _log('Error processing medication ${doc.id}: $e');
          }
        }
        
        yield medications;
      }
    } catch (e) {
      await _errorHandler.handleError('Failed to get medications stream', e);
      // Fall back to cached data
      final cachedMedications = await _cacheOperations.getAllMedicationsLocally();
      yield cachedMedications;
    }
  }

  Future<PaginatedResult<Medication>> getMedicationsPaginated({
    int pageSize = _defaultPageSize,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    MedicationType? filterByType,
    bool? lowStock,
  }) async {
    final userId = _requireUserId();
    
    if (pageSize > _maxPageSize) pageSize = _maxPageSize;
    
    try {
      Query query = _collection
          .where('userId', isEqualTo: userId)
          .orderBy('name');
      
      // Apply filters
      if (filterByType != null) {
        query = query.where('type', isEqualTo: filterByType.toString().split('.').last);
      }
      
      if (lowStock == true) {
        query = query.where('currentInventory', isLessThan: 10);
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThan: searchQuery + '\uf8ff');
      }
      
      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      query = query.limit(pageSize + 1);
      
      // Use query optimizer if available
      final QuerySnapshot snapshot;
      if (_queryOptimizer != null) {
        snapshot = await _queryOptimizer!.getQueryWithCache(
          query,
          cacheDuration: const Duration(minutes: 5),
        );
      } else {
        snapshot = await query.get().timeout(_operationTimeout);
      }
      
      final medications = <Medication>[];
      DocumentSnapshot? nextPageToken;
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        if (i == pageSize) {
          nextPageToken = snapshot.docs[i];
          break;
        }
        
        try {
          final data = snapshot.docs[i].data() as Map<String, dynamic>;
          data['id'] = snapshot.docs[i].id;
          
          final decryptedData = await _encryptionService.decryptMedicationData(data);
          final medication = Medication.fromFirestoreData(decryptedData);
          medications.add(medication);
        } catch (e) {
          _log('Error processing medication ${snapshot.docs[i].id}: $e');
        }
      }
      
      return PaginatedResult<Medication>(
        items: medications,
        nextPageToken: nextPageToken,
        hasMore: nextPageToken != null,
        totalCount: medications.length,
      );
    } catch (e) {
      await _errorHandler.handleError('Failed to get paginated medications', e);
      rethrow;
    }
  }

  Future<List<Medication>> searchMedications({
    required String query,
    int limit = 20,
    MedicationType? filterByType,
  }) async {
    final userId = _requireUserId();
    
    if (query.isEmpty) return [];
    
    try {
      // Check cache first
      final cacheKey = 'search_${userId}_${query}_${filterByType?.toString() ?? ''}_$limit';
      // Implementation would use cache manager here
      
      Query firestoreQuery = _collection
          .where('userId', isEqualTo: userId)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + '\uf8ff')
          .orderBy('name')
          .limit(limit);
      
      if (filterByType != null) {
        firestoreQuery = firestoreQuery.where('type', 
            isEqualTo: filterByType.toString().split('.').last);
      }
      
      final snapshot = await firestoreQuery.get().timeout(_operationTimeout);
      
      final medications = <Medication>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          final decryptedData = await _encryptionService.decryptMedicationData(data);
          final medication = Medication.fromFirestoreData(decryptedData);
          medications.add(medication);
        } catch (e) {
          _log('Error processing search result ${doc.id}: $e');
        }
      }
      
      return medications;
    } catch (e) {
      await _errorHandler.handleError('Failed to search medications', e);
      return [];
    }
  }

  Future<MedicationStats> getMedicationStats() async {
    final userId = _requireUserId();
    
    try {
      final cacheKey = 'medication_stats_$userId';
      // Check cache first - implementation would use cache manager
      
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(_operationTimeout);
      
      final countByType = <MedicationType, int>{};
      int lowStockCount = 0;
      int expiredCount = 0;
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Parse type
          final typeString = data['type'] as String?;
          if (typeString != null) {
            final type = MedicationType.values.firstWhere(
              (e) => e.toString().split('.').last == typeString,
              orElse: () => MedicationType.tablet,
            );
            countByType[type] = (countByType[type] ?? 0) + 1;
          }
          
          // Check low stock
          final currentInventory = (data['currentInventory'] as num?)?.toDouble() ?? 0;
          if (currentInventory < 10) {
            lowStockCount++;
          }
          
          // Check expired
          final expiryDateString = data['expiryDate'] as String?;
          if (expiryDateString != null) {
            final expiryDate = DateTime.tryParse(expiryDateString);
            if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
              expiredCount++;
            }
          }
        } catch (e) {
          _log('Error processing stats for ${doc.id}: $e');
        }
      }
      
      return MedicationStats(
        totalMedications: snapshot.docs.length,
        countByType: countByType,
        lowStockCount: lowStockCount,
        expiredCount: expiredCount,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      await _errorHandler.handleError('Failed to get medication stats', e);
      rethrow;
    }
  }

  Future<void> updateInventory(String medicationId, double newInventory) async {
    final userId = _requireUserId();
    
    try {
      await _collection.doc(medicationId).update({
        'currentInventory': newInventory,
        'lastInventoryUpdate': DateTime.now().toIso8601String(),
      }).timeout(_operationTimeout);
      
      _log('Inventory updated for medication: $medicationId');
    } catch (e) {
      await _errorHandler.handleError('Failed to update inventory', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _prepareMedicationData(Medication medication, String userId) async {
    final medicationData = {
      'name': medication.name,
      'strength': medication.strength,
      'strengthUnit': medication.strengthUnit,
      'type': medication.type.toString().split('.').last,
      'tabletsInStock': medication.currentInventory,
      'quantityUnit': medication.quantityUnit,
      'currentInventory': medication.currentInventory,
      'userId': userId,
      'createdAt': medication.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    // Add optional fields
    if (medication.reconstitutionVolume != null) {
      medicationData['reconstitutionVolume'] = medication.reconstitutionVolume!;
    }
    if (medication.injectionType != null) {
      medicationData['injectionType'] = medication.injectionType.toString().split('.').last;
    }
    if (medication.routeOfAdministration != null) {
      medicationData['routeOfAdministration'] = medication.routeOfAdministration!;
    }
    
    // Encrypt sensitive data
    return await _encryptionService.encryptMedicationData(medicationData);
  }

  String _requireUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }

  void _log(String message) {
    if (kDebugMode) {
      print('MedicationRepository: $message');
    }
  }
}
