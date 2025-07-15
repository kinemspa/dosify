import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../services/firebase_service.dart';
import '../services/encryption_service.dart';
import '../services/cache_manager.dart';
import '../services/query_optimizer.dart';

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
abstract class BaseServiceState<T extends BaseServiceScreen> extends State<T> {
  /// Firebase service instance
  FirebaseService get firebaseService => ServiceLocator.get<FirebaseService>();
  
  /// Encryption service instance
  EncryptionService get encryptionService => ServiceLocator.get<EncryptionService>();
  
  /// Cache manager instance
  CacheManager get cacheManager => ServiceLocator.get<CacheManager>();
  
  /// Query optimizer instance
  QueryOptimizer get queryOptimizer => ServiceLocator.get<QueryOptimizer>();
  
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
  /// 5. Handle any errors
  /// 
  /// [operation] - The async operation to execute
  /// [onSuccess] - Optional callback when operation succeeds
  /// [onError] - Optional custom error handler
  /// [showLoadingIndicator] - Whether to show loading indicator
  /// [criticalOnError] - Whether errors should be treated as critical
  Future<T?> executeWithLoading<T>(
    Future<T> Function() operation, {
    Function(T result)? onSuccess,
    Function(Object error)? onError,
    bool showLoadingIndicator = true,
    bool criticalOnError = false,
  }) async {
    if (showLoadingIndicator) {
      setLoading(true);
    }
    clearError();
    
    try {
      final result = await operation();
      if (onSuccess != null) {
        onSuccess(result);
      }
      return result;
    } catch (e) {
      if (onError != null) {
        onError(e);
      } else {
        setError('An error occurred: ${e.toString()}', isCritical: criticalOnError);
      }
      return null;
    } finally {
      if (showLoadingIndicator) {
        setLoading(false);
      }
    }
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