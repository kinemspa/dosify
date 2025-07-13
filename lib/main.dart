import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_service.dart';
import 'services/encryption_service.dart';
import 'screens/auth/auth_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firebase Auth settings for development
  if (!const bool.fromEnvironment('dart.vm.product')) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
      forceRecaptchaFlow: false,
    );
  }
  
  // Initialize services
  final firebaseService = FirebaseService();
  final encryptionService = EncryptionService();
  await encryptionService.initialize();
  await firebaseService.initialize();
  
  runApp(MyApp(
    firebaseService: firebaseService,
    encryptionService: encryptionService,
  ));
}

class MyApp extends StatelessWidget {
  final FirebaseService firebaseService;
  final EncryptionService encryptionService;

  const MyApp({
    super.key,
    required this.firebaseService,
    required this.encryptionService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>.value(value: firebaseService),
        Provider<EncryptionService>.value(value: encryptionService),
      ],
      child: MaterialApp(
        title: 'Dosify',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthenticationWrapper(),
      ),
    );
  }
}
