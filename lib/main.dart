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
    
    // Set persistence to LOCAL for web to keep user signed in
    // This ensures auth state persists across hot reloads and app restarts
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    
    FirebaseStatus.setInitialized(true);
    print('✅ Firebase initialization successful');
    print('✅ Auth persistence set to LOCAL');
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
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _getInitialScreen() {
    // Use StreamBuilder to listen for auth state changes
    // This ensures the UI updates when auth state changes (login/logout)
    // and persists across hot reloads
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D1117),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D9FF),
              ),
            ),
          );
        }
        
        // Check if user is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, go to dashboard
          return const DashboardScreen();
        } else {
          // User is not signed in, show auth screen
          return const AuthScreen();
        }
      },
    );
  }
}
