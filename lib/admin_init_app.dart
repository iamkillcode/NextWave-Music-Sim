import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// Simple Flutter app to initialize admin access
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const AdminInitApp());
}

class AdminInitApp extends StatelessWidget {
  const AdminInitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Init',
      theme: ThemeData.dark(),
      home: const AdminInitScreen(),
    );
  }
}

class AdminInitScreen extends StatefulWidget {
  const AdminInitScreen({super.key});

  @override
  State<AdminInitScreen> createState() => _AdminInitScreenState();
}

class _AdminInitScreenState extends State<AdminInitScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String adminUserId = 'xjJFuMCEKMZwkI8uIP34Jl2bfQA3';
  bool _isLoading = false;
  String _statusMessage = 'Ready to initialize admin access';

  Future<void> _initializeAdminAccess() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing admin access...';
    });

    try {
      // Add admin record to Firestore
      await _firestore.collection('admins').doc(adminUserId).set({
        'isAdmin': true,
        'grantedBy': 'system_initialization',
        'grantedAt': FieldValue.serverTimestamp(),
        'role': 'primary_admin',
        'permissions': [
          'all_admin_operations',
          'grant_admin_access',
          'revoke_admin_access',
          'system_management',
          'player_management',
          'npc_management',
        ],
      });

      setState(() {
        _statusMessage = '✅ Admin access initialized successfully!\n\n'
            '📋 Admin UID: $adminUserId\n'
            '🎯 Admin document created in Firestore\n\n'
            '🚀 Next steps:\n'
            '1. Login to the app with the admin account\n'
            '2. Go to Settings\n'
            '3. Look for "Admin Dashboard" card\n'
            '4. Click "OPEN ADMIN DASHBOARD"\n\n'
            '👑 You now have full admin access!';
      });

    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e\n\n'
            '🔧 Troubleshooting:\n'
            '1. Check Firebase configuration\n'
            '2. Verify Firestore permissions\n'
            '3. Ensure admin UID is correct';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Admin Access Initialization'),
        backgroundColor: const Color(0xFF00D9FF),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👑 NextWave Music Sim Admin Setup',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00D9FF),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin UID to Initialize:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    adminUserId,
                    style: TextStyle(
                      color: const Color(0xFF00D9FF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _initializeAdminAccess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Initializing...')
                        ],
                      )
                    : Text(
                        'Initialize Admin Access',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}