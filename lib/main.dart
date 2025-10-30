import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/dashboard_screen_new.dart';
import 'screens/auth_screen.dart';
import 'firebase_options.dart';
import 'utils/firebase_status.dart';
import 'services/remote_config_service.dart';
import 'services/push_notification_service.dart';
import 'widgets/remote_config_guard.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  await _initializeFirebase();

  // Set up background message handler (skip on web; only after init)
  if (FirebaseStatus.isInitialized && !kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Initialize Remote Config
  if (FirebaseStatus.isInitialized) {
    await _initializeRemoteConfig();
  }

  runApp(const MusicArtistApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      // Give web more time before declaring a timeout
      kIsWeb ? const Duration(seconds: 30) : const Duration(seconds: 10),
      onTimeout: () {
        throw Exception(
          'Firebase initialization timeout - check internet connection or try another platform (Windows/Android)',
        );
      },
    );

    // Set persistence to LOCAL for web to keep user signed in
    // This ensures auth state persists across hot reloads and app restarts
    // Note: setPersistence() is only supported on web platforms
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      print('✅ Auth persistence set to LOCAL');
    }

    FirebaseStatus.setInitialized(true);
    print('✅ Firebase initialization successful');
  } catch (e) {
    FirebaseStatus.setInitialized(false, e.toString());
    print('❌ Firebase initialization failed: $e');
    print(
      '💡 Tip: If running on Chrome/Web, try Windows instead: flutter run -d windows',
    );
    print('App will run in demo mode without Firebase features.');
  }
}

Future<void> _initializeRemoteConfig() async {
  try {
    await RemoteConfigService().initialize();
    print('✅ Remote Config loaded successfully');
  } catch (e) {
    print('❌ Remote Config initialization failed: $e');
    print('App will use default configuration values.');
  }
}

class MusicArtistApp extends StatefulWidget {
  const MusicArtistApp({super.key});

  @override
  State<MusicArtistApp> createState() => _MusicArtistAppState();
}

class _MusicArtistAppState extends State<MusicArtistApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextWave',
      theme: AppTheme.darkTheme,
      home: _getInitialScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/dashboard': (context) => DashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _getInitialScreen() {
    // If Firebase failed to initialize, avoid touching Firebase APIs on web.
    if (!FirebaseStatus.isInitialized) {
      final error = FirebaseStatus.errorMessage;
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Running in demo mode',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  error ??
                      'Firebase not initialized. Some features are unavailable.',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _initializeFirebase();
                    if (mounted) setState(() {});
                  },
                  child: const Text('Retry initialization'),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Tip: On web, initialization can be slower on first load. You can also try Windows: flutter run -d windows',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Wrap with RemoteConfigGuard to check maintenance mode & updates
    return RemoteConfigGuard(
      currentVersion: '1.0.0', // TODO: Get from package_info_plus
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading screen while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0D1117),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
              ),
            );
          }

          // Check if user is authenticated
          if (snapshot.hasData && snapshot.data != null) {
            // User is signed in, go to dashboard
            return DashboardScreen();
          } else {
            // User is not signed in, show auth screen
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
