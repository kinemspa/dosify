import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/medication.dart';
import '../models/dose.dart';
import '../models/schedule.dart';
import '../models/paginated_result.dart';
import '../core/disposable.dart';
import 'encryption_service.dart';
import 'query_optimizer.dart';
import 'cache_manager.dart';
import 'firebase_connection_manager.dart';
import 'medication_repository.dart';
import 'dose_repository.dart';
import 'schedule_repository.dart';
import 'firebase_cache_manager.dart';
import 'firebase_error_handler.dart';
/// Refactored Firebase service with improved architecture and separation of concerns
/// 
/// This service is split into focused modules:
/// - Connection management
/// - Data operations (medications, doses)
/// - Caching and offline support
/// - Error handling and resilience
class FirebaseService implements Disposable {
  // Core dependencies
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;
  final SharedPreferences _prefs;
  final QueryOptimizer? _queryOptimizer;
  final CacheManager? _cacheManager;

  // Service modules
  late final FirebaseConnectionManager _connectionManager;
  late final MedicationRepository _medicationRepository;
  late final DoseRepository _doseRepository;
  late final ScheduleRepository _scheduleRepository;
  late final FirebaseCacheManager _cacheOperations;
  late final FirebaseErrorHandler _errorHandler;

  // State
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Resource tracking
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];

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
       _cacheManager = cacheManager {
    _initializeModules();
    ResourceManager.register(this);
  }

  /// Initialize service modules
  void _initializeModules() {
    _connectionManager = FirebaseConnectionManager(
      firestore: _firestore,
      prefs: _prefs,
    );

    _errorHandler = FirebaseErrorHandler();

    _cacheOperations = FirebaseCacheManager(
      cacheManager: _cacheManager,
      encryptionService: _encryptionService,
      prefs: _prefs,
    );

    _medicationRepository = MedicationRepository(
      firestore: _firestore,
      auth: _auth,
      encryptionService: _encryptionService,
      queryOptimizer: _queryOptimizer,
      cacheOperations: _cacheOperations,
      errorHandler: _errorHandler,
    );

    _doseRepository = DoseRepository(
      firestore: _firestore,
      auth: _auth,
      encryptionService: _encryptionService,
      queryOptimizer: _queryOptimizer,
      cacheOperations: _cacheOperations,
      errorHandler: _errorHandler,
    );

    _scheduleRepository = ScheduleRepository(
      firestore: _firestore,
      auth: _auth,
      encryptionService: _encryptionService,
      queryOptimizer: _queryOptimizer,
      cacheOperations: _cacheOperations,
      errorHandler: _errorHandler,
    );
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      // Initialize dependencies
      await _encryptionService.initialize();
      await _connectionManager.initialize();
      await _cacheOperations.initialize();

      _isInitialized = true;
      _log('FirebaseService initialized successfully');
    } catch (e) {
      _logError('Failed to initialize FirebaseService', e);
      rethrow;
    }
  }

  // Public API - Medication Operations
  Future<void> addMedication(Medication medication) => 
      _medicationRepository.addMedication(medication);
  
  Future<void> updateMedication(Medication medication) => 
      _medicationRepository.updateMedication(medication);
  
  Future<void> deleteMedication(String medicationId) => 
      _medicationRepository.deleteMedication(medicationId);
  
  Future<Medication?> getMedication(String medicationId) => 
      _medicationRepository.getMedication(medicationId);
  
  Stream<List<Medication>> getMedications() => 
      _medicationRepository.getMedications();
  
  Future<PaginatedResult<Medication>> getMedicationsPaginated({
    int pageSize = 20,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    MedicationType? filterByType,
    bool? lowStock,
  }) => _medicationRepository.getMedicationsPaginated(
    pageSize: pageSize,
    lastDocument: lastDocument,
    searchQuery: searchQuery,
    filterByType: filterByType,
    lowStock: lowStock,
  );

  Future<List<Medication>> searchMedications({
    required String query,
    int limit = 20,
    MedicationType? filterByType,
  }) => _medicationRepository.searchMedications(
    query: query,
    limit: limit,
    filterByType: filterByType,
  );

  // Public API - Dose Operations
  Future<void> addDose(Dose dose) => _doseRepository.addDose(dose);
  
  Future<void> updateDose(Dose dose) => _doseRepository.updateDose(dose);
  
  Future<void> deleteDose(String doseId) => _doseRepository.deleteDose(doseId);
  
  Future<List<Dose>> getDosesForMedication(String medicationId) => 
      _doseRepository.getDosesForMedication(medicationId);

  // Public API - Schedule Operations
  Future<void> addSchedule(Schedule schedule) => 
      _scheduleRepository.addSchedule(schedule);
  
  Future<void> updateSchedule(Schedule schedule) => 
      _scheduleRepository.updateSchedule(schedule);
  
  Future<void> deleteSchedule(String doseId, String scheduleId) => 
      _scheduleRepository.deleteSchedule(doseId, scheduleId);
  
  Future<List<Schedule>> getSchedulesForDose(String doseId) => 
      _scheduleRepository.getSchedulesForDose(doseId);
  
  Future<void> markDoseTaken(Schedule schedule, DateTime dateTime) => 
      _scheduleRepository.markDoseTaken(schedule, dateTime);

  // Public API - Utility Operations
  Future<void> clearAllMedications() => _cacheOperations.clearAllMedications();
  
  Future<List<Medication>> getLocalMedications() => _cacheOperations.getAllMedicationsLocally();
  
  Future<MedicationStats> getMedicationStats() => 
      _medicationRepository.getMedicationStats();

  Future<void> updateMedicationInventory(String medicationId, double newInventory) => 
      _medicationRepository.updateInventory(medicationId, newInventory);

  // Public API - Connection Status
  bool get isFirestoreAvailable => _connectionManager.isFirestoreAvailable;
  String? get currentUserId => _auth.currentUser?.uid;

  /// Dispose resources
  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    // Cancel all subscriptions and timers
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    _log('FirebaseService disposed');
  }

  void _log(String message) {
    if (kDebugMode) {
      print('FirebaseService: $message');
    }
  }

  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('FirebaseService ERROR: $message');
      print('Error: $error');
    }
  }
}
