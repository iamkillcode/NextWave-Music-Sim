import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// One-time script to fix incorrect careerStartDate values for existing players
/// 
/// PROBLEM: Players created before this fix have careerStartDate set to real-world
/// date (Oct 2025) instead of game-world date (Jan 2020). This causes their age
/// to display incorrectly (e.g., 14 instead of 18).
/// 
/// SOLUTION: Update all players' careerStartDate to the game-world start date.
Future<void> main() async {
  print('🔧 Fixing Career Start Dates...');
  print('');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  
  try {
    // Get game world start date
    final gameSettingsDoc = await firestore
        .collection('gameSettings')
        .doc('globalTime')
        .get();
    
    DateTime gameWorldStartDate;
    if (gameSettingsDoc.exists) {
      final data = gameSettingsDoc.data()!;
      gameWorldStartDate = (data['gameWorldStartDate'] as Timestamp).toDate();
      print('✅ Game world start date: $gameWorldStartDate');
    } else {
      // Default to Jan 1, 2020 if not set
      gameWorldStartDate = DateTime(2020, 1, 1);
      print('⚠️  Using default game world start date: $gameWorldStartDate');
    }
    
    print('');
    print('📋 Scanning for players with incorrect careerStartDate...');
    print('');
    
    // Get all players
    final playersSnapshot = await firestore.collection('players').get();
    
    int totalPlayers = playersSnapshot.size;
    int fixedCount = 0;
    int skippedCount = 0;
    
    for (var playerDoc in playersSnapshot.docs) {
      final data = playerDoc.data();
      final displayName = data['displayName'] ?? 'Unknown';
      final age = data['age'] ?? 18;
      
      // Check if careerStartDate exists and is in the future (real-world date)
      if (data.containsKey('careerStartDate')) {
        final careerStartDate = (data['careerStartDate'] as Timestamp).toDate();
        
        // If careerStartDate is after game world start (2020), it's wrong
        if (careerStartDate.year > 2020) {
          print('🔄 Fixing $displayName (age $age)');
          print('   Old: $careerStartDate');
          print('   New: $gameWorldStartDate');
          
          await playerDoc.reference.update({
            'careerStartDate': Timestamp.fromDate(gameWorldStartDate),
          });
          
          fixedCount++;
        } else {
          print('✓  $displayName - Already correct');
          skippedCount++;
        }
      } else {
        // No careerStartDate field, add it
        print('➕ Adding careerStartDate for $displayName');
        await playerDoc.reference.update({
          'careerStartDate': Timestamp.fromDate(gameWorldStartDate),
        });
        fixedCount++;
      }
    }
    
    print('');
    print('✅ Career start date fix complete!');
    print('   Total players: $totalPlayers');
    print('   Fixed: $fixedCount');
    print('   Already correct: $skippedCount');
    print('');
    print('🎯 Players should now see their correct age!');
    print('   (You may need to logout/login or restart the app)');
    
  } catch (e) {
    print('❌ Error fixing career start dates: $e');
    print('');
    print('🔧 Troubleshooting:');
    print('1. Make sure Firebase is properly configured');
    print('2. Check your internet connection');
    print('3. Verify Firestore security rules allow updates');
  }
}
