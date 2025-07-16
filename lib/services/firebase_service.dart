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

/// Manages Firebase connection and availability
class FirebaseConnectionManager {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  
  bool _isFirestoreAvailable = true;
  
  static const String _firestoreAvailableKey = 'firestore_available';
  static const Duration _connectionTimeout = Duration(seconds: 15);

  FirebaseConnectionManager({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  }) : _firestore = firestore, _prefs = prefs;

  bool get isFirestoreAvailable => _isFirestoreAvailable;

  Future<void> initialize() async {
    // Check previous availability status
    _isFirestoreAvailable = _prefs.getBool(_firestoreAvailableKey) ?? true;

    if (_isFirestoreAvailable) {
      await _configureFirestore();
      await _testConnection();
    }
  }

  Future<void> _configureFirestore() async {
    try {
      final settings = _firestore.settings;
      if (settings.persistenceEnabled != true) {
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }
    } catch (e) {
      _log('Failed to configure Firestore settings: $e');
    }
  }

  Future<void> _testConnection() async {
    try {
      await _firestore.collection('_connection_test').doc('test').get()
          .timeout(_connectionTimeout);
    } catch (e) {
      _log('Firestore connection test failed: $e');
      _isFirestoreAvailable = false;
      await _prefs.setBool(_firestoreAvailableKey, false);
    }
  }

  Future<void> resetConnection() async {
    _isFirestoreAvailable = true;
    await _prefs.setBool(_firestoreAvailableKey, true);
    await _testConnection();
  }

  void _log(String message) {
    if (kDebugMode) {
      print('ConnectionManager: $message');
    }
  }
}

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
      final doseData = _prepareDoseData(dose, userId);
      
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
      final doseData = _prepareDoseData(dose, userId);
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
          
          final dose = Dose.fromFirestore(data);
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

  Map<String, dynamic> _prepareDoseData(Dose dose, String userId) {
    return {
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
      final scheduleData = schedule.toMap();
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
      final scheduleData = schedule.toMap();
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
          schedules.add(Schedule.fromMap(data));
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

/// Handles error processing and logging
class FirebaseErrorHandler {
  Future<void> handleError(String context, dynamic error) async {
    final errorMessage = _getErrorMessage(error);
    _logError('$context: $errorMessage', error);
    
    // Could implement error reporting here
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      return error.message ?? 'Firebase error: ${error.code}';
    }
    if (error is TimeoutException) {
      return 'Operation timed out';
    }
    return error.toString();
  }

  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('FirebaseErrorHandler: $message');
      print('Error details: $error');
    }
  }
}
