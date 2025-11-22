import 'package:chat_app/screens/auth_screen.dart';
import 'package:chat_app/screens/chat_list_screen.dart';
import 'package:chat_app/firebase_options.dart'; // Ensure this file exists from FlutterFire CLI
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dardash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Indigo primary color
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor:
            const Color(0xFFF3F4F6), // Light grey background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827),
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Listens to Auth State to decide which screen to show
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Waiting for Firebase to initialize auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // User is logged in
        if (snapshot.hasData) {
          return const ChatListScreen();
        }

        // User is logged out
        return const AuthScreen();
      },
    );
  }
}
