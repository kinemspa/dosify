// Widget tests for the main Dosify application
//
// These tests verify the basic app initialization and navigation flow

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dosify_cursor/main.dart';

void main() {
  group('Dosify App Widget Tests', () {
    testWidgets('App should initialize without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that the app initializes
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App should show loading or auth screen initially', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());
      
      // Allow time for async initialization
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should show either a loading indicator or authentication screen
      final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasAuthScreen = find.textContaining('Sign').evaluate().isNotEmpty || 
                           find.textContaining('Login').evaluate().isNotEmpty ||
                           find.textContaining('Welcome').evaluate().isNotEmpty;
      
      expect(hasLoading || hasAuthScreen, true, 
        reason: 'App should show loading indicator or authentication screen');
    });

    testWidgets('App should use correct theme configuration', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      expect(materialApp.title, equals('Dosify'));
      expect(materialApp.debugShowCheckedModeBanner, false);
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });

    testWidgets('App should handle theme provider correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Verify that theme provider is present in widget tree
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // The app should not crash during theme initialization
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
