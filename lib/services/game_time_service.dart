import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GameTimeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Time conversion constant: 1 real hour = 1 game day
  static const int hoursPerGameDay = 1;
  
  /// Initialize the global game time system in Firestore
  /// This should only run once when the first player joins
  Future<void> initializeGameTime() async {
    try {
      final gameSettingsRef = _firestore.collection('gameSettings').doc('globalTime');
      final doc = await gameSettingsRef.get();
      
      if (!doc.exists) {
        // First time initialization - set the anchor point
        final realWorldStartDate = DateTime(2025, 10, 1, 0, 0); // Oct 1, 2025 00:00
        final gameWorldStartDate = DateTime(2020, 1, 1); // Jan 1, 2020
        
        await gameSettingsRef.set({
          'realWorldStartDate': Timestamp.fromDate(realWorldStartDate),
          'gameWorldStartDate': Timestamp.fromDate(gameWorldStartDate),
          'hoursPerDay': hoursPerGameDay, // 1 real hour = 1 game day
          'description': '1 real world hour equals 1 in-game day',
        });
        
        print('✅ Game time system initialized!');
        print('   Real Start: ${DateFormat('MMM dd, yyyy HH:mm').format(realWorldStartDate)}');
        print('   Game Start: ${DateFormat('MMM dd, yyyy').format(gameWorldStartDate)}');
        print('   Time Ratio: 1 hour = 1 game day');
      }
    } catch (e) {
      print('❌ Error initializing game time: $e');
    }
  }
  
  /// Get the current synchronized game date based on real-world time elapsed
  Future<DateTime> getCurrentGameDate() async {
    try {
      final gameSettingsRef = _firestore.collection('gameSettings').doc('globalTime');
      final doc = await gameSettingsRef.get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final realWorldStartDate = (data['realWorldStartDate'] as Timestamp).toDate();
        final gameWorldStartDate = (data['gameWorldStartDate'] as Timestamp).toDate();
        final hoursPerDay = data['hoursPerDay'] as int;
        
        // Calculate how much real time has passed
        final now = DateTime.now();
        final totalRealMinutes = now.difference(realWorldStartDate).inMinutes;
        
        // Convert to game time: 1 real hour = 1 game day
        // So 1 real minute = 24 game minutes (60 min / 1 day = 1440 min)
        final gameDays = totalRealMinutes ~/ 60; // Full days
        final remainingMinutes = totalRealMinutes % 60; // Minutes within the hour
        
        // Convert remaining real minutes to game hours
        // 60 real minutes = 24 game hours, so 1 real minute = 24/60 = 0.4 game hours
        final gameHours = (remainingMinutes * 24 / 60).floor();
        final gameMinutes = ((remainingMinutes * 24 % 60)).floor();
        
        // Calculate current game date with time
        final currentGameDate = gameWorldStartDate.add(
          Duration(days: gameDays, hours: gameHours, minutes: gameMinutes)
        );
        
        return currentGameDate;
      } else {
        // Fallback if not initialized
        print('⚠️ Game time not initialized, using fallback');
        return DateTime(2020, 1, 1);
      }
    } catch (e) {
      print('❌ Error getting game date: $e');
      return DateTime(2020, 1, 1); // Fallback
    }
  }
  
  /// Format game date for display
  String formatGameDate(DateTime gameDate) {
    return DateFormat('MMMM d, yyyy').format(gameDate);
  }
  
  /// Format game time for display
  String formatGameTime(DateTime gameDate) {
    return DateFormat('HH:mm').format(gameDate);
  }
  
  /// Calculate player age based on career start date and current game date
  int calculatePlayerAge(int startingAge, DateTime careerStartDate, DateTime currentGameDate) {
    final yearsElapsed = currentGameDate.difference(careerStartDate).inDays ~/ 365;
    return startingAge + yearsElapsed;
  }
  
  /// Get time until next game day (for scheduling features)
  Duration getTimeUntilNextGameDay() {
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    return nextHour.difference(now);
  }
  
  /// Check if a scheduled date has been reached
  bool hasDatePassed(DateTime scheduledGameDate, DateTime currentGameDate) {
    return currentGameDate.isAfter(scheduledGameDate) || 
           currentGameDate.isAtSameMomentAs(scheduledGameDate);
  }
  
  /// Convert a real-world duration to game time duration
  Duration convertRealToGameDuration(Duration realDuration) {
    // 1 real hour = 1 game day = 24 game hours
    final realHours = realDuration.inHours;
    final gameDays = realHours; // Direct 1:1 conversion
    return Duration(days: gameDays);
  }
}
