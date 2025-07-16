import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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
