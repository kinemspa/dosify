import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

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
