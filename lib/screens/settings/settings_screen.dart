import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../services/service_locator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseService _firebaseService = serviceLocator<FirebaseService>();

  Future<void> _clearDatabase() async {
    try {
      await _firebaseService.clearAllMedications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database cleared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing database: $e')),
      );
    }
  }

  Future<void> _testFirebaseConnection() async {
    final isConnected = _firebaseService.isFirestoreAvailable;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Firebase connection: ${isConnected ? "Connected" : "Disconnected"}')),
    );
  }

  Future<void> _compareLocalAndFirebase() async {
    // This is a placeholder; implement actual comparison logic
    // For example, fetch medications from local cache and Firebase, then compare
    try {
      final localMeds = await _firebaseService.getLocalMedications();
      final firebaseMeds = await _firebaseService.getMedications().first;
      final areEqual = localMeds.length == firebaseMeds.length; // Simple check; enhance as needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Local and Firebase data match: $areEqual')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error comparing data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: _clearDatabase,
            child: const Text('Clear Database'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _testFirebaseConnection,
            child: const Text('Test Firebase Connection'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _compareLocalAndFirebase,
            child: const Text('Compare Local and Firebase Data'),
          ),
        ],
      ),
    );
  }
}
