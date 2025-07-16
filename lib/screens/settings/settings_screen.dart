import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../services/service_locator.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_decorations.dart';

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

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login screen or home
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Container(
        decoration: AppDecorations.screenBackground(context),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Theme Settings
            ListTile(
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  if (value) {
                    themeProvider.useDarkTheme();
                  } else {
                    themeProvider.useLightTheme();
                  }
                },
              ),
            ),
            const Divider(),
            // Data Management
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
            const Divider(),
            // Account
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
