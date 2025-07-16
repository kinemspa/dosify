import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'utils/input_validator_test.dart' as input_validator_tests;
import 'services/cache_manager_test.dart' as cache_manager_tests;
import 'services/encryption_service_test.dart' as encryption_service_tests;
import 'screens/base_service_screen_test.dart' as base_service_screen_tests;
import 'models/paginated_result_test.dart' as paginated_result_tests;

/// Comprehensive test suite for the Dosify application
/// 
/// This file runs all unit tests for critical services and components.
/// Execute with: flutter test test/all_tests.dart
void main() {
  group('🏥 Dosify App Test Suite', () {
    setUpAll(() {
      print('🚀 Starting Dosify comprehensive test suite...');
      print('📊 Testing critical services for security and reliability');
    });

    tearDownAll(() {
      print('✅ All tests completed!');
      print('🔒 Security and performance validated');
    });

    group('🛡️ Security & Validation Tests', () {
      group('Input Validator', input_validator_tests.main);
      group('Encryption Service', encryption_service_tests.main);
    });

    group('⚡ Performance & Caching Tests', () {
      group('Cache Manager', cache_manager_tests.main);
      group('Paginated Results', paginated_result_tests.main);
    });

    group('🏗️ Architecture & Error Handling Tests', () {
      group('Base Service Screen', base_service_screen_tests.main);
    });
  });
}

/// Run specific test suites for targeted testing
void runSecurityTests() {
  group('🔐 Security-Focused Test Suite', () {
    group('Input Validation Security', input_validator_tests.main);
    group('Data Encryption Security', encryption_service_tests.main);
  });
}

void runPerformanceTests() {
  group('⚡ Performance-Focused Test Suite', () {
    group('Cache Performance', cache_manager_tests.main);
    group('Pagination Performance', paginated_result_tests.main);
  });
}

void runErrorHandlingTests() {
  group('🚨 Error Handling Test Suite', () {
    group('Service Error Handling', base_service_screen_tests.main);
  });
}