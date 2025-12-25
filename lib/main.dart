import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Authenticate anonymously so we have a user token for later services
  try {
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint(
      "Signed in anonymously as ${FirebaseAuth.instance.currentUser?.uid}",
    );
  } catch (e) {
    debugPrint("Failed to sign in anonymously: $e");
  }

  runApp(const TailorMadeApp());
}

class TailorMadeApp extends StatelessWidget {
  const TailorMadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThreadLenz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
