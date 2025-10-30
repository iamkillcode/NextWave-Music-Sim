import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Run this from your admin panel or as a standalone script
/// Sends the balance update announcement to all players
Future<void> sendBalanceUpdateAnnouncement() async {
  final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final firestore = FirebaseFirestore.instance;

  const title = '🎵 Balance Update Live!';
  const message = '''Major game improvements are now active!

✨ What's New:
• Hype system now fully functional with daily decay
• Inspiration regenerates +10/day
• Quality <30 songs give 0 fans (spam prevention)
• Loyal fans grow 2x faster (2,500 streams = 1 loyal fan)
• Fame bonuses rebalanced (still powerful but fair)
• Minimum streams now depend on fanbase size

🎯 Key Changes:
- Focus on quality over quantity
- Stay active to maintain hype (-5 to -8/day decay)
- Manage your inspiration wisely
- Strategic releases beat spam

📖 Full details in the announcements section!

This update makes the game more fair and rewarding for all artists. Good luck! 🚀''';

  try {
    print('📢 Sending balance update announcement...');

    // 1. Create system announcement (visible in game)
    await firestore.collection('system_notifications').add({
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'balance_update',
      'icon': '🎵',
      'priority': 'high',
    });

    print('✅ System notification created');

    // 2. Send to all players via Cloud Function
    try {
      final callable = functions.httpsCallable('sendGlobalNotificationToPlayers');
      final result = await callable.call({
        'title': title,
        'message': message,
      });

      print('✅ Global notification sent to all players');
      print('📊 Result: ${result.data}');
    } catch (e) {
      print('⚠️ Cloud Function error (notification saved but not distributed): $e');
      print('💡 Players will still see it in announcements section');
    }

    print('');
    print('🎉 Announcement successfully sent!');
    print('');
    print('Players will see:');
    print('- In-game notification popup');
    print('- Entry in announcements section');
    print('- Dashboard notification badge');
  } catch (e) {
    print('❌ Error sending announcement: $e');
    rethrow;
  }
}

/// Main function for standalone execution
void main() async {
  // Initialize Firebase first if running standalone
  // If running from admin panel, Firebase is already initialized
  
  await sendBalanceUpdateAnnouncement();
}
