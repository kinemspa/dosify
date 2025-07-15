import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// A class to manage caching of data with TTL support
class CacheManager {
  final SharedPreferences _prefs;
  
  // In-memory cache for faster access
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _expiryTimes = {};
  
  // Default TTL (Time To Live) for cache entries
  final Duration _defaultTtl;
  
  // Prefix for cache keys to avoid conflicts
  final String _keyPrefix;
  
  /// Creates a new CacheManager
  CacheManager({
    required SharedPreferences prefs,
    Duration? defaultTtl,
    String keyPrefix = 'app_cache_',
  }) : _prefs = prefs,
       _defaultTtl = defaultTtl ?? const Duration(hours: 1),
       _keyPrefix = keyPrefix;
  
  /// Initialize the cache manager
  Future<void> initialize() async {
    try {
      // Load expiry times from persistent storage
      final expiryData = _prefs.getString('${_keyPrefix}expiry_times');
      if (expiryData != null) {
        final Map<String, dynamic> expiryMap = json.decode(expiryData);
        expiryMap.forEach((key, value) {
          _expiryTimes[key] = DateTime.parse(value.toString());
        });
      }
      
      // Clean expired entries on initialization
      await cleanExpiredEntries();
      
      _log('Cache manager initialized');
    } catch (e) {
      _logError('Error initializing cache manager', e);
    }
  }
  
  /// Get a cached value
  T? get<T>(String key, {bool ignoreExpiry = false}) {
    final fullKey = _getFullKey(key);
    
    // Check if the value is expired
    if (!ignoreExpiry && _isExpired(key)) {
      _log('Cache entry expired: $key');
      return null;
    }
    
    // Try memory cache first
    if (_memoryCache.containsKey(key)) {
      _log('Cache hit (memory): $key');
      return _memoryCache[key] as T?;
    }
    
    // Try persistent cache
    try {
      if (T == String) {
        final value = _prefs.getString(fullKey);
        if (value != null) {
          _memoryCache[key] = value;
          _log('Cache hit (persistent): $key');
          return value as T?;
        }
      } else if (T == int) {
        final value = _prefs.getInt(fullKey);
        if (value != null) {
          _memoryCache[key] = value;
          _log('Cache hit (persistent): $key');
          return value as T?;
        }
      } else if (T == double) {
        final value = _prefs.getDouble(fullKey);
        if (value != null) {
          _memoryCache[key] = value;
          _log('Cache hit (persistent): $key');
          return value as T?;
        }
      } else if (T == bool) {
        final value = _prefs.getBool(fullKey);
        if (value != null) {
          _memoryCache[key] = value;
          _log('Cache hit (persistent): $key');
          return value as T?;
        }
      } else {
        // For complex objects, try to decode from JSON
        final value = _prefs.getString(fullKey);
        if (value != null) {
          final decodedValue = json.decode(value);
          _memoryCache[key] = decodedValue;
          _log('Cache hit (persistent): $key');
          return decodedValue as T?;
        }
      }
    } catch (e) {
      _logError('Error reading from cache', e);
    }
    
    _log('Cache miss: $key');
    return null;
  }
  
  /// Set a cached value
  Future<bool> set<T>(
    String key,
    T value, {
    Duration? ttl,
  }) async {
    final fullKey = _getFullKey(key);
    final expiryTime = DateTime.now().add(ttl ?? _defaultTtl);
    
    try {
      // Store in memory cache
      _memoryCache[key] = value;
      _expiryTimes[key] = expiryTime;
      
      // Store in persistent cache
      bool success;
      if (value is String) {
        success = await _prefs.setString(fullKey, value);
      } else if (value is int) {
        success = await _prefs.setInt(fullKey, value);
      } else if (value is double) {
        success = await _prefs.setDouble(fullKey, value);
      } else if (value is bool) {
        success = await _prefs.setBool(fullKey, value);
      } else {
        // For complex objects, encode as JSON
        final jsonValue = json.encode(value);
        success = await _prefs.setString(fullKey, jsonValue);
      }
      
      // Store expiry time
      await _saveExpiryTimes();
      
      _log('Cache set: $key (expires: ${expiryTime.toIso8601String()})');
      return success;
    } catch (e) {
      _logError('Error writing to cache', e);
      return false;
    }
  }
  
  /// Remove a cached value
  Future<bool> remove(String key) async {
    final fullKey = _getFullKey(key);
    
    try {
      // Remove from memory cache
      _memoryCache.remove(key);
      _expiryTimes.remove(key);
      
      // Remove from persistent cache
      final success = await _prefs.remove(fullKey);
      
      // Update expiry times
      await _saveExpiryTimes();
      
      _log('Cache removed: $key');
      return success;
    } catch (e) {
      _logError('Error removing from cache', e);
      return false;
    }
  }
  
  /// Clear all cached values
  Future<bool> clear() async {
    try {
      // Clear memory cache
      _memoryCache.clear();
      _expiryTimes.clear();
      
      // Clear persistent cache
      final keys = _prefs.getKeys()
          .where((key) => key.startsWith(_keyPrefix))
          .toList();
      
      for (final key in keys) {
        await _prefs.remove(key);
      }
      
      _log('Cache cleared');
      return true;
    } catch (e) {
      _logError('Error clearing cache', e);
      return false;
    }
  }
  
  /// Clean expired entries
  Future<int> cleanExpiredEntries() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      
      // Find expired keys
      _expiryTimes.forEach((key, expiryTime) {
        if (expiryTime.isBefore(now)) {
          expiredKeys.add(key);
        }
      });
      
      // Remove expired entries
      for (final key in expiredKeys) {
        await remove(key);
      }
      
      _log('Cleaned ${expiredKeys.length} expired cache entries');
      return expiredKeys.length;
    } catch (e) {
      _logError('Error cleaning expired cache entries', e);
      return 0;
    }
  }
  
  /// Check if a cached value exists
  bool containsKey(String key, {bool checkExpiry = true}) {
    if (checkExpiry && _isExpired(key)) {
      return false;
    }
    
    return _memoryCache.containsKey(key) || 
           _prefs.containsKey(_getFullKey(key));
  }
  
  /// Get the full key with prefix
  String _getFullKey(String key) => '$_keyPrefix$key';
  
  /// Check if a cached value is expired
  bool _isExpired(String key) {
    if (!_expiryTimes.containsKey(key)) {
      return false;
    }
    
    final expiryTime = _expiryTimes[key]!;
    return DateTime.now().isAfter(expiryTime);
  }
  
  /// Save expiry times to persistent storage
  Future<void> _saveExpiryTimes() async {
    try {
      final Map<String, String> expiryMap = {};
      _expiryTimes.forEach((key, value) {
        expiryMap[key] = value.toIso8601String();
      });
      
      await _prefs.setString('${_keyPrefix}expiry_times', json.encode(expiryMap));
    } catch (e) {
      _logError('Error saving expiry times', e);
    }
  }
  
  /// Log a message
  void _log(String message) {
    if (kDebugMode) {
      print('CacheManager: $message');
    }
  }
  
  /// Log an error
  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('CacheManager ERROR: $message');
      print('Error: $error');
    }
  }
} 