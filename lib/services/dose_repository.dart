import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/dose.dart';
import 'encryption_service.dart';
import 'query_optimizer.dart';
import 'firebase_cache_manager.dart';
import 'firebase_error_handler.dart';

/// Repository for dose-related operations
class DoseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;
  final QueryOptimizer? _queryOptimizer;
  final FirebaseCacheManager _cacheOperations;
  final FirebaseErrorHandler _errorHandler;

  static const Duration _operationTimeout = Duration(seconds: 10);

  DoseRepository({
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

  CollectionReference get _collection => _firestore.collection('doses');

  Future<void> addDose(Dose dose) async {
    final userId = _requireUserId();
    
    try {
      final doseData = await _prepareDoseData(dose, userId);
      
      await _collection.doc(dose.id).set(doseData)
          .timeout(_operationTimeout);
      
      _log('Dose added successfully: ${dose.id}');
    } catch (e) {
      await _errorHandler.handleError('Failed to add dose', e);
      rethrow;
    }
  }

  Future<void> updateDose(Dose dose) async {
    final userId = _requireUserId();
    
    try {
      final doseData = await _prepareDoseData(dose, userId);
      doseData['updatedAt'] = DateTime.now().toIso8601String();
      
      await _collection.doc(dose.id).update(doseData)
          .timeout(_operationTimeout);
      
      _log('Dose updated successfully: ${dose.id}');
    } catch (e) {
      await _errorHandler.handleError('Failed to update dose', e);
      rethrow;
    }
  }

  Future<void> deleteDose(String doseId) async {
    _requireUserId();
    
    try {
      await _collection.doc(doseId).delete()
          .timeout(_operationTimeout);
      
      _log('Dose deleted successfully: $doseId');
    } catch (e) {
      await _errorHandler.handleError('Failed to delete dose', e);
      rethrow;
    }
  }

  Future<List<Dose>> getDosesForMedication(String medicationId) async {
    final userId = _requireUserId();
    
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('medicationId', isEqualTo: medicationId)
          .orderBy('scheduledTime', descending: true)
          .get()
          .timeout(_operationTimeout);
      
      final doses = <Dose>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          final decryptedData = await _encryptionService.decryptDoseData(data);
          final dose = Dose.fromFirestore(decryptedData);
          doses.add(dose);
        } catch (e) {
          _log('Error processing dose ${doc.id}: $e');
        }
      }
      
      return doses;
    } catch (e) {
      await _errorHandler.handleError('Failed to get doses for medication', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> _prepareDoseData(Dose dose, String userId) async {
    final doseData = {
      'medicationId': dose.medicationId,
      'amount': dose.amount,
      'unit': dose.unit,
      'scheduledTime': Timestamp.fromDate(dose.scheduledTime),
      'actualTime': dose.actualTime != null ? Timestamp.fromDate(dose.actualTime!) : null,
      'status': dose.status.toString().split('.').last,
      'notes': dose.notes,
      'userId': userId,
      'createdAt': Timestamp.fromDate(dose.createdAt ?? DateTime.now()),
    };
    
    return await _encryptionService.encryptDoseData(doseData);
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
      print('DoseRepository: $message');
    }
  }
}
