import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Simple script to manually add admin to Firestore
Future<void> main() async {
  print('🔧 Initializing Admin Access in Firestore...');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  final adminUserId = 'xjJFuMCEKMZwkI8uIP34Jl2bfQA3';
  
  try {
    // Check if admin already exists
    final existingDoc = await firestore.collection('admins').doc(adminUserId).get();
    
    if (existingDoc.exists) {
      print('⚠️  Admin already exists in Firestore:');
      print('   UID: $adminUserId');
      print('   Data: ${existingDoc.data()}');
      print('');
      print('🔧 If admin dashboard still not showing, try:');
      print('1. Clear app cache/data');
      print('2. Logout and login again');
      print('3. Check console for any authentication errors');
      return;
    }

    // Add admin record to Firestore
    await firestore.collection('admins').doc(adminUserId).set({
      'isAdmin': true,
      'grantedBy': 'manual_initialization',
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
    print('1. Login to the app with account: $adminUserId');
    print('2. Go to Settings screen');
    print('3. Look for cyan "Admin Dashboard" card');
    print('4. Click "OPEN ADMIN DASHBOARD"');
    print('');
    print('👑 You now have full admin access!');
    
    // Verify the admin was created
    final verifyDoc = await firestore.collection('admins').doc(adminUserId).get();
    if (verifyDoc.exists) {
      print('');
      print('✅ Verification: Admin document confirmed in Firestore');
    } else {
      print('');
      print('❌ Verification failed: Admin document not found');
    }
    
  } catch (e) {
    print('❌ Error initializing admin access: $e');
    print('');
    print('🔧 Troubleshooting:');
    print('1. Make sure Firebase is properly configured');
    print('2. Check Firestore security rules allow admin collection writes');
    print('3. Verify the admin UID is correct');
    print('4. Check network connectivity');
    print('');
    print('📝 Error details: $e');
  }
}