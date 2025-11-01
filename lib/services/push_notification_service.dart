import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for managing Firebase Cloud Messaging push notifications
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  bool _initialized = false;

  /// Initialize push notifications and request permissions
  Future<void> initialize() async {
    if (_initialized) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Request notification permissions
      if (!kIsWeb) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('✅ Push notification permissions granted');
        } else if (settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
          print('⚠️ Push notification permissions provisional');
        } else {
          print('❌ Push notification permissions denied');
          return;
        }
      } else {
        print('📱 Push notifications on web - using browser notifications');
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('📱 FCM Token: $_fcmToken');

        // Store token in Firestore
        await _saveFCMToken(_fcmToken!);

        // Listen for token refreshes
        _messaging.onTokenRefresh.listen(_saveFCMToken);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      _initialized = true;
      print('✅ Push notification service initialized');
    } catch (e) {
      print('❌ Error initializing push notifications: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('players').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
      });
      print('✅ FCM token saved to Firestore');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message received');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');

    // Notification will be shown automatically by the OS
    // Additional in-app handling can be added here
  }

  /// Handle notification tap (when user taps notification)
  void _handleMessageTap(RemoteMessage message) {
    print('👆 Notification tapped');
    print('   Data: ${message.data}');

    // Handle navigation based on notification type
    final type = message.data['type'] as String?;
    final deepLink = message.data['deepLink'] as String?;

    switch (type) {
      case 'post_engagement':
        // Navigate to Media Hub / EchoX
        print('   → Navigate to post: ${message.data['postId']}');
        break;
      case 'chart_achievement':
        // Navigate to Charts
        print('   → Navigate to charts: ${message.data['chartType']}');
        break;
      case 'rival_overtake':
        // Navigate to Charts / Leaderboard
        print(
            '   → Navigate to rivalry: ${message.data['rivalName']} overtook you');
        break;
      default:
        if (deepLink != null) {
          print('   → Navigate to: $deepLink');
        }
    }
  }

  /// Subscribe to a topic (e.g., 'all_players', 'chart_updates')
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if push notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background message received');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
}
