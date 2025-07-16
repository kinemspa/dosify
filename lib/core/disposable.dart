/// Interface for objects that need to be disposed of to prevent memory leaks
abstract class Disposable {
  /// Dispose of resources and clean up
  Future<void> dispose();
}

/// Resource manager to track and dispose of resources
class ResourceManager {
  static final Set<Disposable> _resources = {};
  
  /// Register a resource for tracking
  static void register(Disposable resource) {
    _resources.add(resource);
  }
  
  /// Unregister a resource
  static void unregister(Disposable resource) {
    _resources.remove(resource);
  }
  
  /// Dispose of all tracked resources
  static Future<void> disposeAll() async {
    for (final resource in _resources.toList()) {
      try {
        await resource.dispose();
      } catch (e) {
        print('Error disposing resource: $e');
      }
    }
    _resources.clear();
  }
  
  /// Get count of tracked resources (for debugging)
  static int get resourceCount => _resources.length;
}