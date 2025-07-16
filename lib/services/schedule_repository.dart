import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/dose.dart';
import '../models/schedule.dart';
import 'encryption_service.dart';
import 'query_optimizer.dart';
import 'firebase_cache_manager.dart';
import 'firebase_error_handler.dart';

/// Repository for schedule-related operations
class ScheduleRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;
  final QueryOptimizer? _queryOptimizer;
  final FirebaseCacheManager _cacheOperations;
  final FirebaseErrorHandler _errorHandler;

  static const Duration _operationTimeout = Duration(seconds: 10);

  ScheduleRepository({
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

  Future<void> addSchedule(Schedule schedule) async {
    final userId = _requireUserId();
    
    try {
      final scheduleData = await _encryptionService.encryptScheduleData(schedule.toMap());
      scheduleData['userId'] = userId;
      scheduleData['updatedAt'] = DateTime.now().toIso8601String();
      
      final doseRef = _firestore.collection('doses').doc(schedule.doseId);
      await doseRef.collection('schedules').doc(schedule.id).set(scheduleData)
          .timeout(_operationTimeout);
      
      _log('Schedule added successfully: ${schedule.id}');
    } catch (e) {
      await _errorHandler.handleError('Failed to add schedule', e);
      rethrow;
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    final userId = _requireUserId();
    
    try {
      final scheduleData = await _encryptionService.encryptScheduleData(schedule.toMap());
      scheduleData['userId'] = userId;
      scheduleData['updatedAt'] = DateTime.now().toIso8601String();
      
      final doseRef = _firestore.collection('doses').doc(schedule.doseId);
      await doseRef.collection('schedules').doc(schedule.id).update(scheduleData)
          .timeout(_operationTimeout);
      
      _log('Schedule updated successfully: ${schedule.id}');
    } catch (e) {
      await _errorHandler.handleError('Failed to update schedule', e);
      rethrow;
    }
  }

  Future<void> deleteSchedule(String doseId, String scheduleId) async {
    _requireUserId();
    
    try {
      final doseRef = _firestore.collection('doses').doc(doseId);
      await doseRef.collection('schedules').doc(scheduleId).delete()
          .timeout(_operationTimeout);
      
      _log('Schedule deleted successfully: $scheduleId');
    } catch (e) {
      await _errorHandler.handleError('Failed to delete schedule', e);
      rethrow;
    }
  }

  Future<List<Schedule>> getSchedulesForDose(String doseId) async {
    final userId = _requireUserId();
    
    try {
      final doseRef = _firestore.collection('doses').doc(doseId);
      final snapshot = await doseRef.collection('schedules')
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(_operationTimeout);
      
      final schedules = <Schedule>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final decryptedData = await _encryptionService.decryptScheduleData(data);
          schedules.add(Schedule.fromMap(decryptedData));
        } catch (e) {
          _log('Error processing schedule ${doc.id}: $e');
        }
      }
      
      return schedules;
    } catch (e) {
      await _errorHandler.handleError('Failed to get schedules for dose', e);
      return [];
    }
  }

  Future<void> markDoseTaken(Schedule schedule, DateTime dateTime) async {
    try {
      final updatedSchedule = schedule.markDoseStatus(dateTime, DoseStatus.taken);
      await updateSchedule(updatedSchedule);
      
      // If deductFromInventory, update medication inventory
      if (updatedSchedule.deductFromInventory && updatedSchedule.medicationId != null) {
        // TODO: Implement inventory deduction
        // await updateMedicationInventory(updatedSchedule.medicationId, -1);
      }
    } catch (e) {
      await _errorHandler.handleError('Failed to mark dose taken', e);
      rethrow;
    }
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
      print('ScheduleRepository: $message');
    }
  }
}
