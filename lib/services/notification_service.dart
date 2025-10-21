import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for managing in-app and push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize notification service and request permissions
  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // For web, we'll use Firestore-based notifications
      // For mobile, we would initialize FCM here
      if (kIsWeb) {
        print('📱 Notification service initialized (Web mode - Firestore-based)');
      } else {
        // TODO: Initialize FCM for mobile platforms
        print('📱 Notification service initialized (Mobile - FCM required)');
      }

      // Mark the player as having notifications enabled
      await _firestore.collection('players').doc(user.uid).update({
        'notificationsEnabled': true,
        'lastNotificationCheck': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  /// Get unread notification count for current user
  Future<int> getUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('players')
          .doc(user.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      return snapshot.size;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Get all notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      Query query = _firestore
          .collection('players')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (unreadOnly) {
        query = query.where('read', isEqualTo: false);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Get global system notifications
  Future<List<Map<String, dynamic>>> getGlobalNotifications({
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('system_notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': 'global',
          'read': false, // Global notifications are always "new" each time viewed
          ...data,
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting global notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('players')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('players')
          .doc(user.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      print('✅ Marked ${snapshot.size} notifications as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('players')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Delete all read notifications
  Future<void> clearReadNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('players')
          .doc(user.uid)
          .collection('notifications')
          .where('read', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Cleared ${snapshot.size} read notifications');
    } catch (e) {
      print('❌ Error clearing read notifications: $e');
    }
  }

  /// Stream of notifications for real-time updates
  Stream<List<Map<String, dynamic>>> notificationStream({
    bool unreadOnly = false,
  }) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _firestore
        .collection('players')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50);

    if (unreadOnly) {
      query = query.where('read', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Create a local notification (for testing or system events)
  Future<void> createNotification({
    required String title,
    required String message,
    String type = 'info',
    Map<String, dynamic>? data,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('players')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'type': type,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data ?? {},
      });
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }
}
