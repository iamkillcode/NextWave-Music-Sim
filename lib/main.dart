import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/dashboard_screen_new.dart';
import 'screens/auth_screen.dart';
import 'firebase_options.dart';
import 'utils/firebase_status.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  await _initializeFirebase();
  
  runApp(const MusicArtistApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firebase initialization timeout - check internet connection or try another platform (Windows/Android)');
      },
    );
    FirebaseStatus.setInitialized(true);
    print('✅ Firebase initialization successful');
  } catch (e) {
    FirebaseStatus.setInitialized(false, e.toString());
    print('❌ Firebase initialization failed: $e');
    print('💡 Tip: If running on Chrome/Web, try Windows instead: flutter run -d windows');
    print('App will run in demo mode without Firebase features.');
  }
}

class MusicArtistApp extends StatelessWidget {
  const MusicArtistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextWave',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0D1117), // GitHub dark background
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF21262D),
          selectedItemColor: Color(0xFF00D9FF), // Cyan
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: _getInitialScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _getInitialScreen() {
    // Check if user is already authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // User is signed in, go to dashboard
      return const DashboardScreen();
    } else {
      // User is not signed in, show auth screen
      return const AuthScreen();
    }
  }
}
