import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// A class to optimize Firestore queries with caching and batching
class QueryOptimizer {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  
  // Cache configuration
  final Duration _defaultCacheDuration = const Duration(minutes: 30);
  final Map<String, DateTime> _lastQueryTimes = {};
  final Map<String, dynamic> _queryCache = {};
  
  // Batch operation configuration
  final int _maxBatchSize = 500;
  
  // Retry configuration
  final int _maxRetries = 3;
  final Duration _initialRetryDelay = const Duration(seconds: 1);
  
  /// Creates a new QueryOptimizer
  QueryOptimizer({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  }) : _firestore = firestore,
       _prefs = prefs;
  
  /// Get a document with caching
  Future<DocumentSnapshot?> getDocumentWithCache(
    DocumentReference docRef, {
    Duration? cacheDuration,
    String? cacheKey,
    bool forceRefresh = false,
  }) async {
    final key = cacheKey ?? 'doc_${docRef.path}';
    final duration = cacheDuration ?? _defaultCacheDuration;
    
    // Check if we should use cache
    if (!forceRefresh && _isCacheValid(key, duration)) {
      final cachedData = _getCachedData(key);
      if (cachedData != null) {
        _log('Using cached data for $key');
        return _documentFromCache(docRef, cachedData);
      }
    }
    
    // If not in cache or cache expired, fetch from Firestore
    try {
      final doc = await _retryOperation(() => docRef.get());
      
      // Cache the result
      _cacheData(key, doc.data());
      
      return doc;
    } catch (e) {
      _logError('Error fetching document', e);
      
      // Return cached data if available, even if expired
      final cachedData = _getCachedData(key);
      if (cachedData != null) {
        _log('Using expired cached data for $key after fetch error');
        return _documentFromCache(docRef, cachedData);
      }
      
      rethrow;
    }
  }
  
  /// Get a query with caching
  Future<QuerySnapshot> getQueryWithCache(
    Query query, {
    Duration? cacheDuration,
    String? cacheKey,
    bool forceRefresh = false,
  }) async {
    final key = cacheKey ?? 'query_${query.parameters.hashCode}';
    final duration = cacheDuration ?? _defaultCacheDuration;
    
    // Check if we should use cache
    if (!forceRefresh && _isCacheValid(key, duration)) {
      final cachedData = _getCachedData(key);
      if (cachedData != null) {
        _log('Using cached data for $key');
        return _queryFromCache(query, cachedData);
      }
    }
    
    // If not in cache or cache expired, fetch from Firestore
    try {
      final querySnapshot = await _retryOperation(() => query.get());
      
      // Cache the result
      _cacheQueryData(key, querySnapshot);
      
      return querySnapshot;
    } catch (e) {
      _logError('Error fetching query', e);
      
      // Return cached data if available, even if expired
      final cachedData = _getCachedData(key);
      if (cachedData != null) {
        _log('Using expired cached data for $key after fetch error');
        return _queryFromCache(query, cachedData);
      }
      
      rethrow;
    }
  }
  
  /// Perform a batch write operation
  Future<void> performBatchOperation(
    List<Map<String, dynamic>> operations,
  ) async {
    // Split operations into batches to avoid hitting Firestore limits
    for (var i = 0; i < operations.length; i += _maxBatchSize) {
      final end = (i + _maxBatchSize < operations.length) 
          ? i + _maxBatchSize 
          : operations.length;
      
      final batch = _firestore.batch();
      
      for (var j = i; j < end; j++) {
        final op = operations[j];
        
        switch (op['type']) {
          case 'set':
            batch.set(
              op['ref'] as DocumentReference,
              op['data'] as Map<String, dynamic>,
              op['options'] as SetOptions?,
            );
            break;
          case 'update':
            batch.update(
              op['ref'] as DocumentReference,
              op['data'] as Map<String, dynamic>,
            );
            break;
          case 'delete':
            batch.delete(op['ref'] as DocumentReference);
            break;
        }
      }
      
      await _retryOperation(() => batch.commit());
      _log('Batch committed: ${end - i} operations');
    }
  }
  
  /// Clear all cached data
  Future<void> clearCache() async {
    _queryCache.clear();
    _lastQueryTimes.clear();
    
    // Clear persisted cache
    final keys = _prefs.getKeys()
        .where((key) => key.startsWith('query_cache_') || key.startsWith('doc_cache_'))
        .toList();
    
    for (final key in keys) {
      await _prefs.remove(key);
    }
    
    _log('Cache cleared');
  }
  
  /// Clear specific cached data
  Future<void> clearCacheForKey(String key) async {
    _queryCache.remove(key);
    _lastQueryTimes.remove(key);
    
    // Clear persisted cache
    await _prefs.remove('query_cache_$key');
    await _prefs.remove('doc_cache_$key');
    
    _log('Cache cleared for key: $key');
  }
  
  /// Check if cache is valid
  bool _isCacheValid(String key, Duration duration) {
    if (!_lastQueryTimes.containsKey(key)) {
      return false;
    }
    
    final lastQueryTime = _lastQueryTimes[key]!;
    return DateTime.now().difference(lastQueryTime) < duration;
  }
  
  /// Get cached data
  dynamic _getCachedData(String key) {
    // Try memory cache first
    if (_queryCache.containsKey(key)) {
      return _queryCache[key];
    }
    
    // Try persistent cache
    final persistedData = _prefs.getString('query_cache_$key') ?? _prefs.getString('doc_cache_$key');
    if (persistedData != null) {
      try {
        final data = json.decode(persistedData);
        _queryCache[key] = data;
        return data;
      } catch (e) {
        _logError('Error parsing cached data', e);
      }
    }
    
    return null;
  }
  
  /// Cache data
  Future<void> _cacheData(String key, dynamic data) async {
    if (data == null) return;
    
    _queryCache[key] = data;
    _lastQueryTimes[key] = DateTime.now();
    
    try {
      final jsonData = json.encode(data);
      await _prefs.setString('doc_cache_$key', jsonData);
    } catch (e) {
      _logError('Error caching data', e);
    }
  }
  
  /// Cache query data
  Future<void> _cacheQueryData(String key, QuerySnapshot snapshot) async {
    try {
      final List<Map<String, dynamic>> documents = [];
      
      for (final doc in snapshot.docs) {
        documents.add({
          'id': doc.id,
          'path': doc.reference.path,
          'data': doc.data(),
        });
      }
      
      final data = {
        'documents': documents,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      _queryCache[key] = data;
      _lastQueryTimes[key] = DateTime.now();
      
      final jsonData = json.encode(data);
      await _prefs.setString('query_cache_$key', jsonData);
    } catch (e) {
      _logError('Error caching query data', e);
    }
  }
  
  /// Create a document snapshot from cache
  DocumentSnapshot _documentFromCache(DocumentReference docRef, dynamic data) {
    // This is a simplified version that doesn't create a real DocumentSnapshot
    // In a real implementation, you would need to create a proper DocumentSnapshot
    throw UnimplementedError('Creating DocumentSnapshot from cache is not implemented');
  }
  
  /// Create a query snapshot from cache
  QuerySnapshot _queryFromCache(Query query, dynamic data) {
    // This is a simplified version that doesn't create a real QuerySnapshot
    // In a real implementation, you would need to create a proper QuerySnapshot
    throw UnimplementedError('Creating QuerySnapshot from cache is not implemented');
  }
  
  /// Retry an operation with exponential backoff
  Future<T> _retryOperation<T>(Future<T> Function() operation) async {
    int attempts = 0;
    Duration delay = _initialRetryDelay;
    
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= _maxRetries) {
          _logError('Operation failed after $_maxRetries attempts', e);
          rethrow;
        }
        
        _log('Operation failed, retrying in ${delay.inMilliseconds}ms (attempt $attempts)');
        await Future.delayed(delay);
        
        // Exponential backoff
        delay *= 2;
      }
    }
  }
  
  /// Log a message
  void _log(String message) {
    if (kDebugMode) {
      print('QueryOptimizer: $message');
    }
  }
  
  /// Log an error
  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('QueryOptimizer ERROR: $message');
      print('Error: $error');
    }
  }
} 