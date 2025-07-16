import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';
import 'encryption_service.dart';
import 'cache_manager.dart';
import 'query_optimizer.dart';
import 'offline_sync_service.dart';

/// Service locator for dependency injection
/// 
/// This class provides a centralized way to access services throughout the app.
/// It uses the GetIt package for dependency injection.
class ServiceLocator {
  /// Private constructor to prevent instantiation
  ServiceLocator._();
  
  /// The GetIt instance used for dependency injection
  static final GetIt _instance = GetIt.instance;
  
  /// Whether the service locator has been initialized
  static bool _isInitialized = false;
  
  /// Get a service from the service locator
  /// 
  /// Example: `final firebaseService = ServiceLocator.get<FirebaseService>();`
  static T get<T extends Object>() {
    if (!_isInitialized) {
      throw Exception('ServiceLocator not initialized. Call setupServiceLocator() first.');
    }
    return _instance.get<T>();
  }
  
  /// Initialize the service locator with all services
  /// 
  /// This method should be called once during app startup, before any services are used.
  /// It registers all services with the GetIt instance.
  static Future<void> setupServiceLocator() async {
    if (_isInitialized) {
      return;
    }
    
    try {
      // Register third-party services
      _instance.registerSingletonAsync<SharedPreferences>(
        () => SharedPreferences.getInstance(),
      );
      await _instance.isReady<SharedPreferences>();
      
      _instance.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
      _instance.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
      
      // Register app services
      _instance.registerSingleton<EncryptionService>(
        EncryptionService(),
      );
      
      _instance.registerSingleton<CacheManager>(
        CacheManager(
          prefs: _instance.get<SharedPreferences>(),
        ),
      );
      
      _instance.registerSingleton<QueryOptimizer>(
        QueryOptimizer(
          firestore: _instance.get<FirebaseFirestore>(),
          prefs: _instance.get<SharedPreferences>(),
        ),
      );
      
      _instance.registerSingleton<FirebaseService>(
        FirebaseService(
          firestore: _instance.get<FirebaseFirestore>(),
          auth: _instance.get<FirebaseAuth>(),
          encryptionService: _instance.get<EncryptionService>(),
          prefs: _instance.get<SharedPreferences>(),
          queryOptimizer: _instance.get<QueryOptimizer>(),
          cacheManager: _instance.get<CacheManager>(),
        ),
      );
      
      _instance.registerSingleton<OfflineSyncService>(
        OfflineSyncService(
          firestore: _instance.get<FirebaseFirestore>(),
          auth: _instance.get<FirebaseAuth>(),
          encryptionService: _instance.get<EncryptionService>(),
          prefs: _instance.get<SharedPreferences>(),
          cacheManager: _instance.get<CacheManager>(),
        ),
      );
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing ServiceLocator: $e');
      rethrow;
    }
  }
  
  /// Reset the service locator
  /// 
  /// This method is primarily used for testing purposes.
  /// It resets the GetIt instance and marks the service locator as uninitialized.
  static Future<void> reset() async {
    if (_isInitialized) {
      await _instance.reset();
      _isInitialized = false;
    }
  }
  
  /// Check if a service is registered with the service locator
  /// 
  /// Example: `final isRegistered = ServiceLocator.isRegistered<FirebaseService>();`
  static bool isRegistered<T extends Object>() {
    return _instance.isRegistered<T>();
  }
}

/// Global function to access the service locator
/// 
/// This is a convenience function for accessing the service locator.
/// Example: `final firebaseService = serviceLocator<FirebaseService>();`
/// 
/// Note: This function is provided for backward compatibility.
/// New code should use `ServiceLocator.get<T>()` instead.
T serviceLocator<T extends Object>() => ServiceLocator.get<T>(); 