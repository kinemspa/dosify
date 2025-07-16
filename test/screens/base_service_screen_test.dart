import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:dosify_cursor/screens/base_service_screen.dart';

@GenerateMocks([])
class TestBaseServiceScreen extends BaseServiceScreen {
  const TestBaseServiceScreen({super.key});

  @override
  State<TestBaseServiceScreen> createState() => _TestBaseServiceScreenState();
}

class _TestBaseServiceScreenState extends BaseServiceScreenState<TestBaseServiceScreen> {
  @override
  Widget build(BuildContext context) {
    return buildServiceScaffold(
      appBar: AppBar(title: const Text('Test Screen')),
      body: () => const Center(child: Text('Test Content')),
      onRetry: () => clearError(),
    );
  }
}

void main() {
  group('BaseServiceScreen', () {
    late Widget testWidget;

    setUp(() {
      testWidget = const MaterialApp(
        home: TestBaseServiceScreen(),
      );
    });

    group('loading state management', () {
      testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        
        final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
        state.setLoading(true);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Test Content'), findsNothing);
      });

      testWidgets('should hide loading indicator when not loading', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        
        final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
        state.setLoading(false);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Test Content'), findsOneWidget);
      });
    });

    group('error state management', () {
      testWidgets('should show error message when error is set', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        
        final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
        state.setError('Test error message');
        await tester.pump();

        expect(find.text('Test error message'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('should show critical error when critical flag is true', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        
        final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
        state.setError('Critical error', isCritical: true);
        await tester.pump();

        expect(find.text('Critical error'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text('Test Content'), findsNothing); // Content should be hidden for critical errors
      });

      testWidgets('should clear error when clearError is called', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        
        final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
        state.setError('Test error');
        await tester.pump();

        expect(find.text('Test error'), findsOneWidget);

        state.clearError();
        await tester.pump();

        expect(find.text('Test error'), findsNothing);
        expect(find.text('Test Content'), findsOneWidget);
      });

      testWidgets('should show retry button for errors', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        
        final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
        state.setError('Test error', isCritical: true);
        await tester.pump();

        expect(find.text('Retry'), findsOneWidget);
        
        // Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Error should be cleared
        expect(find.text('Test error'), findsNothing);
        expect(find.text('Test Content'), findsOneWidget);
      });

      testWidgets('should dismiss error banner when close button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        
        final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
        state.setError('Test error message');
        await tester.pump();

        expect(find.text('Test error message'), findsOneWidget);
        
        // Find and tap the close button
        final closeButton = find.byIcon(Icons.close);
        expect(closeButton, findsOneWidget);
        
        await tester.tap(closeButton);
        await tester.pump();

        expect(find.text('Test error message'), findsNothing);
      });
    });

    group('executeWithLoading', () {
      testWidgets('should handle successful operations', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        
        final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
        
        var operationCalled = false;
        var successCallbackCalled = false;
        
        final result = await state.executeWithLoading(
          () async {
            operationCalled = true;
            await Future.delayed(const Duration(milliseconds: 10));
            return 'success result';
          },
          onSuccess: (result) {
            successCallbackCalled = true;
            expect(result, equals('success result'));
          },
        );

        expect(operationCalled, true);
        expect(successCallbackCalled, true);
        expect(result, equals('success result'));
        expect(state.isLoading, false);
        expect(state.errorMessage, null);
      });

      testWidgets('should handle operation failures', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        
        final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
        
        var errorCallbackCalled = false;
        
        final result = await state.executeWithLoading(
          () async {
            throw Exception('Test operation failed');
          },
          onError: (error) {
            errorCallbackCalled = true;
            expect(error.toString(), contains('Test operation failed'));
          },
        );

        expect(errorCallbackCalled, true);
        expect(result, null);
        expect(state.isLoading, false);
      });

      testWidgets('should handle timeout operations', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        
        final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
        
        final result = await state.executeWithLoading(
          () async {
            // Simulate a slow operation
            await Future.delayed(const Duration(milliseconds: 200));
            return 'should not complete';
          },
          timeout: const Duration(milliseconds: 50),
        );

        expect(result, null);
        expect(state.isLoading, false);
        expect(state.errorMessage, contains('Operation timed out'));
      });
    });
  });

  group('Error Categorization', () {
    late _TestBaseServiceScreenState state;
    late Widget testWidget;

    setUp(() {
      testWidget = const MaterialApp(home: TestBaseServiceScreen());
    });

    testWidgets('should categorize FirebaseAuthException correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));

      await state.executeWithLoading(() async {
        throw FirebaseAuthException(code: 'user-not-found');
      });

      expect(state.errorMessage, equals('No account found with this email address.'));
    });

    testWidgets('should categorize FirebaseException correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));

      await state.executeWithLoading(() async {
        throw FirebaseException(plugin: 'firestore', code: 'permission-denied');
      });

      expect(state.errorMessage, equals('Access denied. Please check your permissions.'));
      expect(state.hasCriticalError, true);
    });

    testWidgets('should categorize SocketException correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));

      await state.executeWithLoading(() async {
        throw const SocketException('Network unreachable');
      });

      expect(state.errorMessage, equals('Network connection error. Please check your internet connection and try again.'));
      expect(state.hasCriticalError, false);
    });

    testWidgets('should categorize TimeoutException correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));

      await state.executeWithLoading(() async {
        throw TimeoutException('Request timeout', const Duration(seconds: 30));
      });

      expect(state.errorMessage, equals('Operation timed out. Please try again.'));
      expect(state.hasCriticalError, false);
    });

    testWidgets('should categorize FormatException correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));

      await state.executeWithLoading(() async {
        throw const FormatException('Invalid input format');
      });

      expect(state.errorMessage, equals('Invalid data format. Please check your input and try again.'));
      expect(state.hasCriticalError, false);
    });

    testWidgets('should categorize unknown errors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));

      await state.executeWithLoading(() async {
        throw Exception('Unknown error type');
      });

      expect(state.errorMessage, equals('An unexpected error occurred. Please try again.'));
      expect(state.hasCriticalError, true);
    });
  });

  group('Specific Firebase Error Codes', () {
    late _TestBaseServiceScreenState state;
    late Widget testWidget;

    setUp(() {
      testWidget = const MaterialApp(home: TestBaseServiceScreen());
    });

    final authErrorTests = {
      'user-not-found': 'No account found with this email address.',
      'wrong-password': 'Incorrect password. Please try again.',
      'invalid-email': 'Please enter a valid email address.',
      'user-disabled': 'This account has been disabled. Please contact support.',
      'too-many-requests': 'Too many failed attempts. Please try again later.',
      'network-request-failed': 'Network error. Please check your connection and try again.',
      'weak-password': 'Password is too weak. Please choose a stronger password.',
      'email-already-in-use': 'An account already exists with this email address.',
    };

    for (final entry in authErrorTests.entries) {
      testWidgets('should handle Firebase auth error: ${entry.key}', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));

        await state.executeWithLoading(() async {
          throw FirebaseAuthException(code: entry.key);
        });

        expect(state.errorMessage, equals(entry.value));
      });
    }

    final firestoreErrorTests = {
      'permission-denied': ('Access denied. Please check your permissions.', true),
      'not-found': ('Requested data not found.', false),
      'already-exists': ('Data already exists.', false),
      'resource-exhausted': ('Service temporarily unavailable. Please try again later.', false),
      'failed-precondition': ('Operation cannot be completed. Please try again.', false),
      'aborted': ('Operation was aborted. Please try again.', false),
      'out-of-range': ('Invalid data range. Please check your input.', false),
      'unimplemented': ('Feature not available. Please contact support.', true),
      'internal': ('Internal server error. Please try again later.', true),
      'unavailable': ('Service temporarily unavailable. Please try again later.', false),
      'data-loss': ('Data corruption detected. Please contact support.', true),
      'unauthenticated': ('Please sign in to continue.', true),
    };

    for (final entry in firestoreErrorTests.entries) {
      testWidgets('should handle Firestore error: ${entry.key}', (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);
        state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));

        await state.executeWithLoading(() async {
          throw FirebaseException(plugin: 'firestore', code: entry.key);
        });

        expect(state.errorMessage, equals(entry.value.$1));
        expect(state.hasCriticalError, equals(entry.value.$2));
      });
    }
  });

  group('Error State Persistence', () {
    testWidgets('should not update state when widget is not mounted', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestBaseServiceScreen()));
      
      final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
      
      // Remove the widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      
      // Try to set error on unmounted widget - should not crash
      state.setError('Should not crash');
      state.setLoading(true);
      state.clearError();
      
      // No expectations - just ensuring no crashes occur
    });

    testWidgets('should maintain error state across widget updates', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestBaseServiceScreen()));
      
      final state = tester.state<_TestBaseServiceScreenState>(find.byType(TestBaseServiceScreen));
      state.setError('Persistent error');
      await tester.pump();

      // Rebuild widget
      await tester.pumpWidget(const MaterialApp(home: TestBaseServiceScreen()));
      await tester.pump();

      // Error should still be visible (though this is a new instance, 
      // this tests the general error display behavior)
      expect(find.text('Persistent error'), findsOneWidget);
    });
  });
}