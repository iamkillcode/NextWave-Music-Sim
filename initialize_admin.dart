import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nextwave/firebase_options.dart';

/// Temporary script to initialize admin access in Firestore
/// Run this once to set up admin access for UID: xjJFuMCEKMZwkI8uIP34Jl2bfQA3
Future<void> main() async {
  print('🔧 Initializing Admin Access...');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  final adminUserId = 'xjJFuMCEKMZwkI8uIP34Jl2bfQA3';
  
  try {
    // Add admin record to Firestore
    await firestore.collection('admins').doc(adminUserId).set({
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
    
    print('✅ Admin access initialized successfully!');
    print('📋 Admin UID: $adminUserId');
    print('🎯 Admin document created in Firestore admins collection');
    print('');
    print('🚀 Next steps:');
    print('1. Login to the app with the admin account');
    print('2. Go to Settings');
    print('3. Look for the cyan "Admin Dashboard" card');
    print('4. Click "OPEN ADMIN DASHBOARD" to access admin features');
    print('');
    print('👑 You now have full admin access!');
    
  } catch (e) {
    print('❌ Error initializing admin access: $e');
    print('');
    print('🔧 Troubleshooting:');
    print('1. Make sure Firebase is properly configured');
    print('2. Check Firestore security rules allow admin creation');
    print('3. Verify the admin UID is correct');
  }
}