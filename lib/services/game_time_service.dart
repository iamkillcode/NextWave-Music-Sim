import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GameTimeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Time conversion constant: 1 real hour = 1 game day
  static const int hoursPerGameDay = 1;

  /// Initialize the global game time system in Firestore
  Future<void> initializeGameTime() async {
    try {
      final gameSettingsRef = _firestore
          .collection('gameSettings')
          .doc('globalTime');
      final doc = await gameSettingsRef.get();

      if (!doc.exists) {
        // Use server timestamp for precision
        final realWorldStartDate = DateTime(2025, 10, 1, 0, 0);
        final gameWorldStartDate = DateTime(2020, 1, 1);

        await gameSettingsRef.set({
          'realWorldStartDate': Timestamp.fromDate(realWorldStartDate),
          'gameWorldStartDate': Timestamp.fromDate(gameWorldStartDate),
          'hoursPerDay': hoursPerGameDay,
          'description': '1 real world hour equals 1 in-game day',
          'lastUpdated': FieldValue.serverTimestamp(), // Use server time
        });

        print('✅ Game time system initialized!');
        print(
          '   Real Start: ${DateFormat('MMM dd, yyyy HH:mm').format(realWorldStartDate)}',
        );
        print(
          '   Game Start: ${DateFormat('MMM dd, yyyy').format(gameWorldStartDate)}',
        );
        print('   Time Ratio: 1 hour = 1 game day');
      }
    } catch (e) {
      print('❌ Error initializing game time: $e');
    }
  }

  /// Get the current synchronized game date based on FIREBASE SERVER TIME
  /// Pure date-only system: 1 real hour = 1 game day
  Future<DateTime> getCurrentGameDate() async {
    try {
      final gameSettingsRef = _firestore
          .collection('gameSettings')
          .doc('globalTime');
      final doc = await gameSettingsRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        final realWorldStartDate = (data['realWorldStartDate'] as Timestamp)
            .toDate();
        final gameWorldStartDate = (data['gameWorldStartDate'] as Timestamp)
            .toDate();
        // hoursPerDay is now implicit: always 1 real hour = 1 game day

        // CRITICAL: Use Firebase server time, not device time
        // This ensures all users calculate from the exact same moment
        final serverTimeRef = _firestore
            .collection('serverTime')
            .doc('current');
        await serverTimeRef.set({'timestamp': FieldValue.serverTimestamp()});
        final serverTimeDoc = await serverTimeRef.get();
        final serverTimestamp =
            serverTimeDoc.data()?['timestamp'] as Timestamp?;

        final now = serverTimestamp?.toDate() ?? DateTime.now();

        // Calculate real HOURS elapsed (not seconds) - simplified!
        final realHoursElapsed = now.difference(realWorldStartDate).inHours;

        // Convert to game days: 1 real hour = 1 game day
        final gameDaysElapsed = realHoursElapsed;

        // Calculate current game date (add days only, no time component)
        final calculatedDate = gameWorldStartDate.add(
          Duration(days: gameDaysElapsed),
        );

        // Return date at midnight (strip time component)
        final currentGameDate = DateTime(
          calculatedDate.year,
          calculatedDate.month,
          calculatedDate.day,
        );

        return currentGameDate;
      } else {
        print('⚠️ Game time not initialized');
        return DateTime(2020, 1, 1);
      }
    } catch (e) {
      print('❌ Error getting game date: $e');
      return DateTime(2020, 1, 1);
    }
  }

  /// Format game date for display
  String formatGameDate(DateTime gameDate) {
    return DateFormat('MMM d, yyyy').format(gameDate);
  }

  /// Format game time for display (deprecated - date-only system)
  String formatGameTime(DateTime gameDate) {
    // Return empty string since we no longer track time
    return '';
  }

  /// Calculate player age based on career start date and current game date
  int calculatePlayerAge(
    int startingAge,
    DateTime careerStartDate,
    DateTime currentGameDate,
  ) {
    final yearsElapsed =
        currentGameDate.difference(careerStartDate).inDays ~/ 365;
    return startingAge + yearsElapsed;
  }

  /// Get time until next game day
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
}
