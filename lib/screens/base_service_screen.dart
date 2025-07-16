import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import '../services/service_locator.dart';
import '../services/firebase_service.dart';
import '../services/encryption_service.dart';
import '../services/cache_manager.dart';
import '../services/query_optimizer.dart';
import '../services/offline_sync_service.dart';

/// Base class for screens that need access to services
/// 
/// This class provides:
/// - Access to common services via dependency injection
/// - Standard error handling
/// - Loading state management
/// - Common UI elements for error and loading states
abstract class BaseServiceScreen extends StatefulWidget {
  const BaseServiceScreen({super.key});
}

/// Base state class for BaseServiceScreen
/// 
/// Provides:
/// - Access to services
/// - Error handling methods
/// - Loading state management
/// - UI helpers for common states
abstract class BaseServiceScreenState<T extends BaseServiceScreen> extends State<T> {
  /// Firebase service instance
  FirebaseService get firebaseService => ServiceLocator.get<FirebaseService>();
  
  /// Encryption service instance
  EncryptionService get encryptionService => ServiceLocator.get<EncryptionService>();
  
  /// Cache manager instance
  CacheManager get cacheManager => ServiceLocator.get<CacheManager>();
  
  /// Query optimizer instance
  QueryOptimizer get queryOptimizer => ServiceLocator.get<QueryOptimizer>();
  
  /// Offline sync service instance
  OfflineSyncService get offlineSyncService => ServiceLocator.get<OfflineSyncService>();
  
  /// Current error message to display
  String? _errorMessage;
  
  /// Whether the screen is in a loading state
  bool _isLoading = false;
  
  /// Whether the screen has encountered a critical error
  bool _hasCriticalError = false;
  
  /// Current error message to display
  String? get errorMessage => _errorMessage;
  
  /// Whether the screen is in a loading state
  bool get isLoading => _isLoading;
  
  /// Whether the screen has encountered a critical error
  bool get hasCriticalError => _hasCriticalError;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  /// Initialize any services needed by the screen
  /// 
  /// Override this method to perform initialization logic
  Future<void> _initializeServices() async {
    // Implement in subclasses if needed
  }
  
  /// Set the loading state
  /// 
  /// This will rebuild the widget with the new loading state
  void setLoading(bool loading) {
    if (mounted && _isLoading != loading) {
      setState(() {
        _isLoading = loading;
      });
    }
  }
  
  /// Set an error message
  /// 
  /// This will rebuild the widget with the new error message
  /// If [isCritical] is true, the screen will show a critical error UI
  void setError(String message, {bool isCritical = false}) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _hasCriticalError = isCritical;
      });
    }
  }
  
  /// Clear any current error message
  void clearError() {
    if (mounted && (_errorMessage != null || _hasCriticalError)) {
      setState(() {
        _errorMessage = null;
        _hasCriticalError = false;
      });
    }
  }
  
  /// Execute an async operation with loading state and error handling
  /// 
  /// This method will:
  /// 1. Set loading state to true
  /// 2. Clear any existing errors
  /// 3. Execute the operation
  /// 4. Set loading state to false
  /// 5. Handle any errors with proper error categorization
  /// 
  /// [operation] - The async operation to execute
  /// [onSuccess] - Optional callback when operation succeeds
  /// [onError] - Optional custom error handler
  /// [showLoadingIndicator] - Whether to show loading indicator
  /// [criticalOnError] - Whether errors should be treated as critical
  /// [timeout] - Optional timeout for the operation
  Future<T?> executeWithLoading<T>(
    Future<T> Function() operation, {
    Function(T result)? onSuccess,
    Function(Object error)? onError,
    bool showLoadingIndicator = true,
    bool criticalOnError = false,
    Duration? timeout,
  }) async {
    if (showLoadingIndicator) {
      setLoading(true);
    }
    clearError();
    
    try {
      Future<T> operationFuture = operation();
      
      // Add timeout if specified
      if (timeout != null) {
        operationFuture = operationFuture.timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'Operation timed out after ${timeout.inSeconds} seconds',
            timeout,
          ),
        );
      }
      
      final result = await operationFuture;
      if (onSuccess != null) {
        onSuccess(result);
      }
      return result;
    } catch (e) {
      if (onError != null) {
        onError(e);
      } else {
        final errorInfo = _categorizeError(e);
        setError(errorInfo.message, isCritical: errorInfo.isCritical || criticalOnError);
      }
      return null;
    } finally {
      if (showLoadingIndicator) {
        setLoading(false);
      }
    }
  }
  
  /// Categorize errors and provide user-friendly messages
  ErrorInfo _categorizeError(Object error) {
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    } else if (error is FirebaseException) {
      return _handleFirebaseError(error);
    } else if (error is SocketException) {
      return ErrorInfo(
        message: 'Network connection error. Please check your internet connection and try again.',
        isCritical: false,
        category: ErrorCategory.network,
      );
    } else if (error is TimeoutException) {
      return ErrorInfo(
        message: 'Operation timed out. Please try again.',
        isCritical: false,
        category: ErrorCategory.timeout,
      );
    } else if (error is FormatException) {
      return ErrorInfo(
        message: 'Invalid data format. Please check your input and try again.',
        isCritical: false,
        category: ErrorCategory.validation,
      );
    } else {
      return ErrorInfo(
        message: 'An unexpected error occurred. Please try again.',
        isCritical: true,
        category: ErrorCategory.unknown,
      );
    }
  }
  
  /// Handle Firebase Authentication errors
  ErrorInfo _handleFirebaseAuthError(FirebaseAuthException error) {
    String message;
    bool isCritical = false;
    
    switch (error.code) {
      case 'user-not-found':
        message = 'No account found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Please contact support.';
        isCritical = true;
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection and try again.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please choose a stronger password.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      default:
        message = error.message ?? 'Authentication failed. Please try again.';
        break;
    }
    
    return ErrorInfo(
      message: message,
      isCritical: isCritical,
      category: ErrorCategory.authentication,
    );
  }
  
  /// Handle Firebase Firestore errors
  ErrorInfo _handleFirebaseError(FirebaseException error) {
    String message;
    bool isCritical = false;
    
    switch (error.code) {
      case 'permission-denied':
        message = 'Access denied. Please check your permissions.';
        isCritical = true;
        break;
      case 'not-found':
        message = 'Requested data not found.';
        break;
      case 'already-exists':
        message = 'Data already exists.';
        break;
      case 'resource-exhausted':
        message = 'Service temporarily unavailable. Please try again later.';
        break;
      case 'failed-precondition':
        message = 'Operation cannot be completed. Please try again.';
        break;
      case 'aborted':
        message = 'Operation was aborted. Please try again.';
        break;
      case 'out-of-range':
        message = 'Invalid data range. Please check your input.';
        break;
      case 'unimplemented':
        message = 'Feature not available. Please contact support.';
        isCritical = true;
        break;
      case 'internal':
        message = 'Internal server error. Please try again later.';
        isCritical = true;
        break;
      case 'unavailable':
        message = 'Service temporarily unavailable. Please try again later.';
        break;
      case 'data-loss':
        message = 'Data corruption detected. Please contact support.';
        isCritical = true;
        break;
      case 'unauthenticated':
        message = 'Please sign in to continue.';
        isCritical = true;
        break;
      default:
        message = error.message ?? 'Database error. Please try again.';
        break;
    }
    
    return ErrorInfo(
      message: message,
      isCritical: isCritical,
      category: ErrorCategory.database,
    );
  }
  
  /// Build a loading indicator widget
  Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  /// Build an error message widget
  Widget buildErrorMessage({
    String? message,
    VoidCallback? onRetry,
    bool critical = false,
  }) {
    final errorMsg = message ?? _errorMessage ?? 'An error occurred';
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              critical ? Icons.error : Icons.warning,
              color: critical 
                  ? Theme.of(context).colorScheme.error 
                  : Theme.of(context).colorScheme.secondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: critical 
                    ? Theme.of(context).colorScheme.error 
                    : Theme.of(context).colorScheme.onBackground,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  clearError();
                  onRetry();
                },
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build a scaffold with loading and error handling
  /// 
  /// This is a convenience method for building a scaffold that handles:
  /// - Loading state (shows a loading indicator)
  /// - Error state (shows an error message)
  /// - Normal state (shows the content)
  /// 
  /// [appBar] - Optional app bar
  /// [body] - The main content builder
  /// [floatingActionButton] - Optional FAB
  /// [bottomNavigationBar] - Optional bottom nav
  /// [drawer] - Optional drawer
  /// [onRetry] - Optional retry callback for errors
  Widget buildServiceScaffold({
    PreferredSizeWidget? appBar,
    required Widget Function() body,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    Widget? drawer,
    VoidCallback? onRetry,
  }) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: _buildServiceBody(body, onRetry),
    );
  }
  
  /// Build the body with loading and error handling
  Widget _buildServiceBody(
    Widget Function() bodyBuilder,
    VoidCallback? onRetry,
  ) {
    if (_isLoading) {
      return buildLoadingIndicator();
    }
    
    if (_hasCriticalError) {
      return buildErrorMessage(
        critical: true,
        onRetry: onRetry,
      );
    }
    
    return Stack(
      children: [
        bodyBuilder(),
        if (_errorMessage != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              child: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: clearError,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Error categories for better error handling
enum ErrorCategory {
  authentication,
  database,
  network,
  timeout,
  validation,
  encryption,
  unknown,
}

/// Error information container
class ErrorInfo {
  final String message;
  final bool isCritical;
  final ErrorCategory category;
  
  const ErrorInfo({
    required this.message,
    required this.isCritical,
    required this.category,
  });
} 