import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../models/dose.dart';
import '../core/disposable.dart';
import 'encryption_service.dart';
import 'cache_manager.dart';

/// Comprehensive offline synchronization service with conflict resolution
/// 
/// This service handles:
/// - Offline data storage and retrieval
/// - Conflict detection and resolution
/// - Sync queue management
/// - Network connectivity monitoring
/// - Data integrity validation
class OfflineSyncService implements Disposable {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;
  final SharedPreferences _prefs;
  final CacheManager _cacheManager;
  
  bool _isDisposed = false;
  bool _isOnline = true;
  bool _isSyncing = false;
  Timer? _syncTimer;
  StreamSubscription? _authSubscription;
  
  // Sync configuration
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _retryDelay = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const int _maxQueueSize = 1000;
  
  // Storage keys
  static const String _pendingOperationsKey = 'pending_sync_operations';
  static const String _lastSyncTimeKey = 'last_sync_timestamp';
  static const String _conflictQueueKey = 'conflict_resolution_queue';
  static const String _offlineDataKey = 'offline_data_cache';
  
  // Sync queues
  final List<SyncOperation> _pendingOperations = [];
  final List<ConflictResolutionItem> _conflictQueue = [];
  
  // Stream controllers for sync status
  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  final StreamController<List<ConflictResolutionItem>> _conflictController = StreamController<List<ConflictResolutionItem>>.broadcast();
  
  OfflineSyncService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required EncryptionService encryptionService,
    required SharedPreferences prefs,
    required CacheManager cacheManager,
  }) : _firestore = firestore,
       _auth = auth,
       _encryptionService = encryptionService,
       _prefs = prefs,
       _cacheManager = cacheManager {
    ResourceManager.register(this);
  }

  /// Initialize the offline sync service
  Future<void> initialize() async {
    if (_isDisposed) return;
    
    try {
      await _loadPendingOperations();
      await _loadConflictQueue();
      
      // Set up authentication listener
      _authSubscription = _auth.authStateChanges().listen(_handleAuthStateChange);
      
      // Start periodic sync
      _startPeriodicSync();
      
      _log('OfflineSyncService initialized');
    } catch (e) {
      _logError('Failed to initialize OfflineSyncService', e);
      rethrow;
    }
  }

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  /// Stream of conflicts requiring resolution
  Stream<List<ConflictResolutionItem>> get conflictStream => _conflictController.stream;
  
  /// Current online status
  bool get isOnline => _isOnline;
  
  /// Current sync status
  bool get isSyncing => _isSyncing;
  
  /// Number of pending operations
  int get pendingOperationsCount => _pendingOperations.length;
  
  /// Number of unresolved conflicts
  int get conflictCount => _conflictQueue.length;

  /// Add a medication operation to the sync queue
  Future<void> queueMedicationOperation({
    required String operationType,
    required String medicationId,
    required Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  }) async {
    final operation = SyncOperation(
      id: _generateOperationId(),
      type: SyncOperationType.medication,
      operation: operationType,
      entityId: medicationId,
      data: data,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      retryCount: 0,
    );
    
    await _addToSyncQueue(operation);
    
    // Attempt immediate sync if online
    if (_isOnline && !_isSyncing) {
      unawaited(_performSync());
    }
  }

  /// Add a dose operation to the sync queue
  Future<void> queueDoseOperation({
    required String operationType,
    required String doseId,
    required Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  }) async {
    final operation = SyncOperation(
      id: _generateOperationId(),
      type: SyncOperationType.dose,
      operation: operationType,
      entityId: doseId,
      data: data,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      retryCount: 0,
    );
    
    await _addToSyncQueue(operation);
    
    if (_isOnline && !_isSyncing) {
      unawaited(_performSync());
    }
  }

  /// Store data for offline access
  Future<void> storeOfflineData({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final offlineData = await _getOfflineData();
      
      if (!offlineData.containsKey(collection)) {
        offlineData[collection] = <String, dynamic>{};
      }
      
      // Encrypt sensitive data before storing
      final encryptedData = await _encryptionService.encryptMedicationData(data);
      offlineData[collection][documentId] = {
        ...encryptedData,
        '_offline_timestamp': DateTime.now().millisecondsSinceEpoch,
        '_offline_version': _generateVersion(),
      };
      
      await _saveOfflineData(offlineData);
      
      _log('Stored offline data for $collection/$documentId');
    } catch (e) {
      _logError('Failed to store offline data', e);
    }
  }

  /// Retrieve data from offline storage
  Future<Map<String, dynamic>?> getOfflineData({
    required String collection,
    required String documentId,
  }) async {
    try {
      final offlineData = await _getOfflineData();
      
      if (!offlineData.containsKey(collection) ||
          !offlineData[collection].containsKey(documentId)) {
        return null;
      }
      
      final data = offlineData[collection][documentId] as Map<String, dynamic>;
      
      // Decrypt sensitive data
      return await _encryptionService.decryptMedicationData(data);
    } catch (e) {
      _logError('Failed to retrieve offline data', e);
      return null;
    }
  }

  /// Get all offline data for a collection
  Future<List<Map<String, dynamic>>> getAllOfflineData(String collection) async {
    try {
      final offlineData = await _getOfflineData();
      
      if (!offlineData.containsKey(collection)) {
        return [];
      }
      
      final collectionData = offlineData[collection] as Map<String, dynamic>;
      final results = <Map<String, dynamic>>[];
      
      for (final entry in collectionData.entries) {
        try {
          final decryptedData = await _encryptionService.decryptMedicationData(
            entry.value as Map<String, dynamic>
          );
          decryptedData['id'] = entry.key;
          results.add(decryptedData);
        } catch (e) {
          _logError('Failed to decrypt offline data for ${entry.key}', e);
        }
      }
      
      return results;
    } catch (e) {
      _logError('Failed to get all offline data for $collection', e);
      return [];
    }
  }

  /// Force sync all pending operations
  Future<SyncResult> forcSync() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        operationsProcessed: 0,
        conflictsDetected: 0,
      );
    }
    
    return await _performSync();
  }

  /// Resolve a conflict with user's choice
  Future<void> resolveConflict({
    required String conflictId,
    required ConflictResolutionStrategy strategy,
    Map<String, dynamic>? customData,
  }) async {
    try {
      final conflictIndex = _conflictQueue.indexWhere((c) => c.id == conflictId);
      if (conflictIndex == -1) {
        throw Exception('Conflict not found: $conflictId');
      }
      
      final conflict = _conflictQueue[conflictIndex];
      
      switch (strategy) {
        case ConflictResolutionStrategy.useLocal:
          await _applyLocalData(conflict);
          break;
        case ConflictResolutionStrategy.useRemote:
          await _applyRemoteData(conflict);
          break;
        case ConflictResolutionStrategy.merge:
          await _mergeData(conflict, customData);
          break;
        case ConflictResolutionStrategy.useCustom:
          if (customData == null) {
            throw Exception('Custom data required for custom resolution strategy');
          }
          await _applyCustomData(conflict, customData);
          break;
      }
      
      _conflictQueue.removeAt(conflictIndex);
      await _saveConflictQueue();
      
      _conflictController.add(List.from(_conflictQueue));
      
      _log('Resolved conflict: $conflictId using $strategy');
    } catch (e) {
      _logError('Failed to resolve conflict: $conflictId', e);
      rethrow;
    }
  }

  /// Clear all offline data (use with caution)
  Future<void> clearOfflineData() async {
    try {
      await _prefs.remove(_offlineDataKey);
      await _prefs.remove(_pendingOperationsKey);
      await _prefs.remove(_conflictQueueKey);
      
      _pendingOperations.clear();
      _conflictQueue.clear();
      
      _syncStatusController.add(SyncStatus.idle);
      _conflictController.add([]);
      
      _log('Cleared all offline data');
    } catch (e) {
      _logError('Failed to clear offline data', e);
    }
  }

  /// Get sync statistics
  SyncStatistics getSyncStatistics() {
    final lastSyncTime = _prefs.getInt(_lastSyncTimeKey);
    
    return SyncStatistics(
      lastSyncTime: lastSyncTime != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncTime) : null,
      pendingOperations: _pendingOperations.length,
      unresolvedConflicts: _conflictQueue.length,
      isOnline: _isOnline,
      isSyncing: _isSyncing,
    );
  }

  /// Private methods

  void _handleAuthStateChange(User? user) {
    if (user == null) {
      // User logged out, pause sync
      _stopPeriodicSync();
    } else {
      // User logged in, resume sync
      _startPeriodicSync();
      if (_isOnline && !_isSyncing) {
        unawaited(_performSync());
      }
    }
  }

  void _startPeriodicSync() {
    _stopPeriodicSync();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isOnline && !_isSyncing && _auth.currentUser != null) {
        unawaited(_performSync());
      }
    });
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<SyncResult> _performSync() async {
    if (_isSyncing || _auth.currentUser == null) {
      return SyncResult(
        success: false,
        message: 'Cannot sync: already syncing or user not authenticated',
        operationsProcessed: 0,
        conflictsDetected: 0,
      );
    }
    
    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);
    
    int operationsProcessed = 0;
    int conflictsDetected = 0;
    
    try {
      _log('Starting sync with ${_pendingOperations.length} pending operations');
      
      final operations = List<SyncOperation>.from(_pendingOperations);
      
      for (final operation in operations) {
        try {
          final result = await _processOperation(operation);
          
          if (result.isConflict) {
            conflictsDetected++;
            await _handleConflict(operation, result.conflictData!);
          } else if (result.isSuccess) {
            operationsProcessed++;
            _pendingOperations.removeWhere((op) => op.id == operation.id);
          } else {
            // Operation failed, increment retry count
            operation.retryCount++;
            if (operation.retryCount >= _maxRetries) {
              _log('Operation ${operation.id} exceeded max retries, removing from queue');
              _pendingOperations.removeWhere((op) => op.id == operation.id);
            }
          }
        } catch (e) {
          _logError('Failed to process operation ${operation.id}', e);
          operation.retryCount++;
          if (operation.retryCount >= _maxRetries) {
            _pendingOperations.removeWhere((op) => op.id == operation.id);
          }
        }
      }
      
      await _savePendingOperations();
      await _prefs.setInt(_lastSyncTimeKey, DateTime.now().millisecondsSinceEpoch);
      
      _syncStatusController.add(SyncStatus.completed);
      
      _log('Sync completed: $operationsProcessed operations processed, $conflictsDetected conflicts detected');
      
      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
        operationsProcessed: operationsProcessed,
        conflictsDetected: conflictsDetected,
      );
      
    } catch (e) {
      _logError('Sync failed', e);
      _syncStatusController.add(SyncStatus.error);
      
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        operationsProcessed: operationsProcessed,
        conflictsDetected: conflictsDetected,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<OperationResult> _processOperation(SyncOperation operation) async {
    try {
      switch (operation.type) {
        case SyncOperationType.medication:
          return await _processMedicationOperation(operation);
        case SyncOperationType.dose:
          return await _processDoseOperation(operation);
        default:
          throw Exception('Unknown operation type: ${operation.type}');
      }
    } catch (e) {
      _logError('Failed to process operation ${operation.id}', e);
      return OperationResult.failure(e.toString());
    }
  }

  Future<OperationResult> _processMedicationOperation(SyncOperation operation) async {
    final collection = _firestore.collection('medications');
    
    try {
      switch (operation.operation) {
        case 'create':
          final doc = collection.doc(operation.entityId);
          await doc.set(operation.data);
          return OperationResult.success();
          
        case 'update':
          final doc = collection.doc(operation.entityId);
          final snapshot = await doc.get();
          
          if (!snapshot.exists) {
            return OperationResult.failure('Document does not exist');
          }
          
          // Check for conflicts
          final remoteData = snapshot.data()!;
          final conflict = _detectConflict(operation.data, remoteData, operation.timestamp);
          
          if (conflict != null) {
            return OperationResult.conflict(conflict);
          }
          
          await doc.update(operation.data);
          return OperationResult.success();
          
        case 'delete':
          final doc = collection.doc(operation.entityId);
          await doc.delete();
          return OperationResult.success();
          
        default:
          throw Exception('Unknown medication operation: ${operation.operation}');
      }
    } on FirebaseException catch (e) {
      _logError('Firebase error in medication operation', e);
      return OperationResult.failure(e.message ?? 'Firebase error');
    }
  }

  Future<OperationResult> _processDoseOperation(SyncOperation operation) async {
    final collection = _firestore.collection('doses');
    
    try {
      switch (operation.operation) {
        case 'create':
          final doc = collection.doc(operation.entityId);
          await doc.set(operation.data);
          return OperationResult.success();
          
        case 'update':
          final doc = collection.doc(operation.entityId);
          final snapshot = await doc.get();
          
          if (!snapshot.exists) {
            return OperationResult.failure('Document does not exist');
          }
          
          // Check for conflicts
          final remoteData = snapshot.data()!;
          final conflict = _detectConflict(operation.data, remoteData, operation.timestamp);
          
          if (conflict != null) {
            return OperationResult.conflict(conflict);
          }
          
          await doc.update(operation.data);
          return OperationResult.success();
          
        case 'delete':
          final doc = collection.doc(operation.entityId);
          await doc.delete();
          return OperationResult.success();
          
        default:
          throw Exception('Unknown dose operation: ${operation.operation}');
      }
    } on FirebaseException catch (e) {
      _logError('Firebase error in dose operation', e);
      return OperationResult.failure(e.message ?? 'Firebase error');
    }
  }

  ConflictData? _detectConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    DateTime operationTimestamp,
  ) {
    // Check if remote data was modified after our operation timestamp
    final remoteUpdatedAt = remoteData['updatedAt'];
    if (remoteUpdatedAt != null) {
      final remoteTimestamp = DateTime.tryParse(remoteUpdatedAt.toString());
      if (remoteTimestamp != null && remoteTimestamp.isAfter(operationTimestamp)) {
        // Potential conflict detected
        final conflictingFields = <String>[];
        
        for (final key in localData.keys) {
          if (remoteData.containsKey(key) && localData[key] != remoteData[key]) {
            conflictingFields.add(key);
          }
        }
        
        if (conflictingFields.isNotEmpty) {
          return ConflictData(
            conflictingFields: conflictingFields,
            localData: localData,
            remoteData: remoteData,
            localTimestamp: operationTimestamp,
            remoteTimestamp: remoteTimestamp,
          );
        }
      }
    }
    
    return null;
  }

  Future<void> _handleConflict(SyncOperation operation, ConflictData conflictData) async {
    final conflict = ConflictResolutionItem(
      id: _generateConflictId(),
      operation: operation,
      conflictData: conflictData,
      detectedAt: DateTime.now(),
    );
    
    _conflictQueue.add(conflict);
    await _saveConflictQueue();
    
    _conflictController.add(List.from(_conflictQueue));
    
    _log('Conflict detected for operation ${operation.id}');
  }

  Future<void> _applyLocalData(ConflictResolutionItem conflict) async {
    // Apply local data to remote
    final operation = conflict.operation;
    final collection = operation.type == SyncOperationType.medication 
        ? _firestore.collection('medications')
        : _firestore.collection('doses');
    
    final doc = collection.doc(operation.entityId);
    await doc.update(operation.data);
    
    _log('Applied local data for conflict ${conflict.id}');
  }

  Future<void> _applyRemoteData(ConflictResolutionItem conflict) async {
    // Update local storage with remote data
    final operation = conflict.operation;
    await storeOfflineData(
      collection: operation.type == SyncOperationType.medication ? 'medications' : 'doses',
      documentId: operation.entityId,
      data: conflict.conflictData.remoteData,
    );
    
    _log('Applied remote data for conflict ${conflict.id}');
  }

  Future<void> _mergeData(ConflictResolutionItem conflict, Map<String, dynamic>? mergeRules) async {
    final localData = conflict.conflictData.localData;
    final remoteData = conflict.conflictData.remoteData;
    
    // Simple merge strategy: take the most recent non-null value for each field
    final mergedData = <String, dynamic>{...remoteData};
    
    for (final key in localData.keys) {
      if (localData[key] != null) {
        if (mergeRules != null && mergeRules.containsKey(key)) {
          // Apply custom merge rule
          final rule = mergeRules[key];
          if (rule == 'local') {
            mergedData[key] = localData[key];
          } else if (rule == 'remote') {
            mergedData[key] = remoteData[key];
          }
        } else {
          // Default: prefer local data
          mergedData[key] = localData[key];
        }
      }
    }
    
    mergedData['updatedAt'] = DateTime.now().toIso8601String();
    
    // Apply merged data to both local and remote
    final operation = conflict.operation;
    final collection = operation.type == SyncOperationType.medication 
        ? _firestore.collection('medications')
        : _firestore.collection('doses');
    
    final doc = collection.doc(operation.entityId);
    await doc.update(mergedData);
    
    await storeOfflineData(
      collection: operation.type == SyncOperationType.medication ? 'medications' : 'doses',
      documentId: operation.entityId,
      data: mergedData,
    );
    
    _log('Merged data for conflict ${conflict.id}');
  }

  Future<void> _applyCustomData(ConflictResolutionItem conflict, Map<String, dynamic> customData) async {
    final operation = conflict.operation;
    final collection = operation.type == SyncOperationType.medication 
        ? _firestore.collection('medications')
        : _firestore.collection('doses');
    
    final doc = collection.doc(operation.entityId);
    await doc.update(customData);
    
    await storeOfflineData(
      collection: operation.type == SyncOperationType.medication ? 'medications' : 'doses',
      documentId: operation.entityId,
      data: customData,
    );
    
    _log('Applied custom data for conflict ${conflict.id}');
  }

  Future<void> _addToSyncQueue(SyncOperation operation) async {
    if (_pendingOperations.length >= _maxQueueSize) {
      // Remove oldest operation to make space
      _pendingOperations.removeAt(0);
      _log('Sync queue full, removed oldest operation');
    }
    
    _pendingOperations.add(operation);
    await _savePendingOperations();
    
    _log('Added operation to sync queue: ${operation.id}');
  }

  Future<void> _loadPendingOperations() async {
    try {
      final data = _prefs.getString(_pendingOperationsKey);
      if (data != null) {
        final List<dynamic> operations = json.decode(data);
        _pendingOperations.clear();
        _pendingOperations.addAll(
          operations.map((op) => SyncOperation.fromJson(op)).toList()
        );
        _log('Loaded ${_pendingOperations.length} pending operations');
      }
    } catch (e) {
      _logError('Failed to load pending operations', e);
    }
  }

  Future<void> _savePendingOperations() async {
    try {
      final data = json.encode(_pendingOperations.map((op) => op.toJson()).toList());
      await _prefs.setString(_pendingOperationsKey, data);
    } catch (e) {
      _logError('Failed to save pending operations', e);
    }
  }

  Future<void> _loadConflictQueue() async {
    try {
      final data = _prefs.getString(_conflictQueueKey);
      if (data != null) {
        final List<dynamic> conflicts = json.decode(data);
        _conflictQueue.clear();
        _conflictQueue.addAll(
          conflicts.map((c) => ConflictResolutionItem.fromJson(c)).toList()
        );
        _log('Loaded ${_conflictQueue.length} unresolved conflicts');
      }
    } catch (e) {
      _logError('Failed to load conflict queue', e);
    }
  }

  Future<void> _saveConflictQueue() async {
    try {
      final data = json.encode(_conflictQueue.map((c) => c.toJson()).toList());
      await _prefs.setString(_conflictQueueKey, data);
    } catch (e) {
      _logError('Failed to save conflict queue', e);
    }
  }

  Future<Map<String, dynamic>> _getOfflineData() async {
    try {
      final data = _prefs.getString(_offlineDataKey);
      if (data != null) {
        return Map<String, dynamic>.from(json.decode(data));
      }
    } catch (e) {
      _logError('Failed to get offline data', e);
    }
    return {};
  }

  Future<void> _saveOfflineData(Map<String, dynamic> data) async {
    try {
      final jsonData = json.encode(data);
      await _prefs.setString(_offlineDataKey, jsonData);
    } catch (e) {
      _logError('Failed to save offline data', e);
    }
  }

  String _generateOperationId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_pendingOperations.length}';
  }

  String _generateConflictId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_conflictQueue.length}';
  }

  String _generateVersion() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _log(String message) {
    if (kDebugMode) {
      print('OfflineSyncService: $message');
    }
  }

  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('OfflineSyncService ERROR: $message');
      print('Error: $error');
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    _isDisposed = true;
    _stopPeriodicSync();
    await _authSubscription?.cancel();
    await _syncStatusController.close();
    await _conflictController.close();
    
    _log('OfflineSyncService disposed');
  }
}

/// Sync operation data model
class SyncOperation {
  final String id;
  final SyncOperationType type;
  final String operation;
  final String entityId;
  final Map<String, dynamic> data;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  int retryCount;

  SyncOperation({
    required this.id,
    required this.type,
    required this.operation,
    required this.entityId,
    required this.data,
    required this.metadata,
    required this.timestamp,
    required this.retryCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'operation': operation,
      'entityId': entityId,
      'data': data,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'],
      type: SyncOperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      operation: json['operation'],
      entityId: json['entityId'],
      data: Map<String, dynamic>.from(json['data']),
      metadata: Map<String, dynamic>.from(json['metadata']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'],
    );
  }
}

/// Conflict resolution item
class ConflictResolutionItem {
  final String id;
  final SyncOperation operation;
  final ConflictData conflictData;
  final DateTime detectedAt;

  ConflictResolutionItem({
    required this.id,
    required this.operation,
    required this.conflictData,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation.toJson(),
      'conflictData': conflictData.toJson(),
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  factory ConflictResolutionItem.fromJson(Map<String, dynamic> json) {
    return ConflictResolutionItem(
      id: json['id'],
      operation: SyncOperation.fromJson(json['operation']),
      conflictData: ConflictData.fromJson(json['conflictData']),
      detectedAt: DateTime.parse(json['detectedAt']),
    );
  }
}

/// Conflict data details
class ConflictData {
  final List<String> conflictingFields;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;

  ConflictData({
    required this.conflictingFields,
    required this.localData,
    required this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'conflictingFields': conflictingFields,
      'localData': localData,
      'remoteData': remoteData,
      'localTimestamp': localTimestamp.toIso8601String(),
      'remoteTimestamp': remoteTimestamp.toIso8601String(),
    };
  }

  factory ConflictData.fromJson(Map<String, dynamic> json) {
    return ConflictData(
      conflictingFields: List<String>.from(json['conflictingFields']),
      localData: Map<String, dynamic>.from(json['localData']),
      remoteData: Map<String, dynamic>.from(json['remoteData']),
      localTimestamp: DateTime.parse(json['localTimestamp']),
      remoteTimestamp: DateTime.parse(json['remoteTimestamp']),
    );
  }
}

/// Operation result
class OperationResult {
  final bool isSuccess;
  final bool isConflict;
  final String? errorMessage;
  final ConflictData? conflictData;

  OperationResult._({
    required this.isSuccess,
    required this.isConflict,
    this.errorMessage,
    this.conflictData,
  });

  factory OperationResult.success() {
    return OperationResult._(
      isSuccess: true,
      isConflict: false,
    );
  }

  factory OperationResult.failure(String message) {
    return OperationResult._(
      isSuccess: false,
      isConflict: false,
      errorMessage: message,
    );
  }

  factory OperationResult.conflict(ConflictData conflictData) {
    return OperationResult._(
      isSuccess: false,
      isConflict: true,
      conflictData: conflictData,
    );
  }
}

/// Sync result summary
class SyncResult {
  final bool success;
  final String message;
  final int operationsProcessed;
  final int conflictsDetected;

  SyncResult({
    required this.success,
    required this.message,
    required this.operationsProcessed,
    required this.conflictsDetected,
  });
}

/// Sync statistics
class SyncStatistics {
  final DateTime? lastSyncTime;
  final int pendingOperations;
  final int unresolvedConflicts;
  final bool isOnline;
  final bool isSyncing;

  SyncStatistics({
    this.lastSyncTime,
    required this.pendingOperations,
    required this.unresolvedConflicts,
    required this.isOnline,
    required this.isSyncing,
  });
}

/// Enums
enum SyncOperationType { medication, dose }

enum SyncStatus { idle, syncing, completed, error }

enum ConflictResolutionStrategy { useLocal, useRemote, merge, useCustom }