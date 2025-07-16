import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Test setup utilities and common mock configurations
class TestSetup {
  /// Set up common mocks and test environment
  static void setUp() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Create a mock SharedPreferences with default values
  static MockSharedPreferences createMockSharedPreferences() {
    final mock = MockSharedPreferences();
    
    // Set up default behaviors
    when(mock.getString(any)).thenReturn(null);
    when(mock.getInt(any)).thenReturn(null);
    when(mock.getDouble(any)).thenReturn(null);
    when(mock.getBool(any)).thenReturn(null);
    when(mock.getStringList(any)).thenReturn(null);
    when(mock.getKeys()).thenReturn(<String>{});
    when(mock.containsKey(any)).thenReturn(false);
    
    when(mock.setString(any, any)).thenAnswer((_) async => true);
    when(mock.setInt(any, any)).thenAnswer((_) async => true);
    when(mock.setDouble(any, any)).thenAnswer((_) async => true);
    when(mock.setBool(any, any)).thenAnswer((_) async => true);
    when(mock.setStringList(any, any)).thenAnswer((_) async => true);
    when(mock.remove(any)).thenAnswer((_) async => true);
    when(mock.clear()).thenAnswer((_) async => true);
    
    return mock;
  }

  /// Create a mock FlutterSecureStorage with default values
  static MockFlutterSecureStorage createMockSecureStorage() {
    final mock = MockFlutterSecureStorage();
    
    // Set up default behaviors
    when(mock.read(key: any)).thenAnswer((_) async => null);
    when(mock.write(key: any, value: any)).thenAnswer((_) async {});
    when(mock.delete(key: any)).thenAnswer((_) async {});
    when(mock.deleteAll()).thenAnswer((_) async {});
    when(mock.readAll()).thenAnswer((_) async => <String, String>{});
    when(mock.containsKey(key: any)).thenAnswer((_) async => false);
    
    return mock;
  }
}

/// Mock classes for common dependencies
class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Test data generators
class TestDataGenerator {
  /// Generate a sample medication data map
  static Map<String, dynamic> sampleMedicationData({
    String name = 'Test Medication',
    double strength = 100.0,
    String strengthUnit = 'mg',
    String type = 'tablet',
    double currentInventory = 50.0,
    String? notes,
    String? userId,
  }) {
    return {
      'name': name,
      'strength': strength,
      'strengthUnit': strengthUnit,
      'type': type,
      'currentInventory': currentInventory,
      if (notes != null) 'notes': notes,
      if (userId != null) 'userId': userId,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Generate sample user credentials
  static Map<String, String> sampleUserCredentials({
    String email = 'test@example.com',
    String password = 'TestPass123!',
  }) {
    return {
      'email': email,
      'password': password,
    };
  }

  /// Generate sample validation test cases
  static Map<String, bool> validationTestCases({
    required Map<String, bool> cases,
  }) {
    return cases;
  }

  /// Generate a list of test strings for various scenarios
  static List<String> testStrings() {
    return [
      '', // Empty string
      'a', // Single character
      'Hello World', // Normal text
      '1234567890', // Numbers
      'Special!@#\$%^&*()_+', // Special characters
      'Multi\nLine\nText', // Multi-line
      'Very long text that exceeds normal limits ' * 10, // Long text
      '   Whitespace   ', // Whitespace
      '<script>alert("xss")</script>', // HTML/XSS
      'Unicode: äöü 中文 🚀', // Unicode characters
    ];
  }

  /// Generate test numbers for validation
  static List<String> testNumbers() {
    return [
      '0',
      '1',
      '10',
      '100.5',
      '0.1',
      '9999',
      '10000',
      '-1',
      '-100',
      'abc',
      '10.5.5',
      '1e10',
      'Infinity',
      'NaN',
    ];
  }

  /// Generate test email addresses
  static Map<String, bool> testEmails() {
    return {
      'valid@example.com': true,
      'user123@gmail.com': true,
      'first.last@company.co.uk': true,
      'test+tag@domain.org': true,
      'user_name@test-domain.com': true,
      '': false,
      'invalid-email': false,
      '@domain.com': false,
      'user@': false,
      'user..name@domain.com': false,
      'user@domain': false,
      'user name@domain.com': false,
      'very-long-email-address-that-exceeds-the-normal-limits@very-long-domain-name-that-is-too-long.com': false,
    };
  }

  /// Generate test passwords
  static Map<String, bool> testPasswords() {
    return {
      'StrongPass123!': true,
      'MyPassword#456': true,
      'TestP@ssw0rd': true,
      'Complex1ty&Security': true,
      'Valid123\$Password': true,
      '12345678': false, // No letters or special chars
      'password': false, // No uppercase, numbers, or special chars
      'PASSWORD': false, // No lowercase, numbers, or special chars
      'Pass123': false, // No special characters and too short
      'Password!': false, // No numbers
      'password123': false, // No uppercase or special chars
      'PASSWORD123!': false, // No lowercase
      'short': false, // Too short
      '': false, // Empty
    };
  }
}

/// Custom matchers for testing
class TestMatchers {
  /// Matcher for checking if a string is a valid Base64
  static Matcher isValidBase64() {
    return predicate<String>((value) {
      try {
        final decoded = RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(value);
        return decoded && value.length % 4 == 0;
      } catch (e) {
        return false;
      }
    }, 'is valid Base64');
  }

  /// Matcher for checking if a string is encrypted (not equal to original)
  static Matcher isEncrypted(String original) {
    return predicate<String>((value) {
      return value != original && value.isNotEmpty;
    }, 'is encrypted (different from original)');
  }

  /// Matcher for checking if a validation result is successful
  static Matcher isValidationSuccess() {
    return predicate<dynamic>((value) {
      return value.isValid == true && value.error == null;
    }, 'is validation success');
  }

  /// Matcher for checking if a validation result is failure
  static Matcher isValidationFailure([String? expectedError]) {
    return predicate<dynamic>((value) {
      final isFailure = value.isValid == false && value.error != null;
      if (expectedError != null) {
        return isFailure && value.error == expectedError;
      }
      return isFailure;
    }, expectedError != null 
        ? 'is validation failure with error: $expectedError'
        : 'is validation failure');
  }
}

/// Performance testing utilities
class PerformanceTestHelper {
  /// Measure execution time of a function
  static Future<Duration> measureExecutionTime(Future<void> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Assert that an operation completes within a time limit
  static Future<void> assertExecutionTime(
    Future<void> Function() operation,
    Duration maxDuration, {
    String? message,
  }) async {
    final duration = await measureExecutionTime(operation);
    expect(
      duration,
      lessThan(maxDuration),
      reason: message ?? 'Operation took too long: ${duration.inMilliseconds}ms',
    );
  }

  /// Run multiple iterations of an operation and measure average time
  static Future<Duration> measureAverageExecutionTime(
    Future<void> Function() operation,
    int iterations,
  ) async {
    final durations = <Duration>[];
    
    for (int i = 0; i < iterations; i++) {
      final duration = await measureExecutionTime(operation);
      durations.add(duration);
    }
    
    final totalMicroseconds = durations
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b);
    
    return Duration(microseconds: totalMicroseconds ~/ iterations);
  }
}