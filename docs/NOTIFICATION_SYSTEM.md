# Global Notification System Implementation Guide

## Overview

The NextWave Music Sim now has a comprehensive notification system that allows admins to send broadcast messages to all players and provides a beautiful notification center for players to view all their notifications.

## Features Implemented

### 📱 **Notification Service** (`lib/services/notification_service.dart`)
A centralized service for managing all notifications with the following capabilities:

#### Personal Notifications
- **Unread Count**: Track how many unread notifications each player has
- **Get Notifications**: Retrieve personal notifications with pagination
- **Mark as Read**: Individual or bulk mark as read
- **Delete**: Remove individual notifications or clear all read notifications
- **Real-time Streams**: Listen to notification changes in real-time

#### Global Announcements
- **System Notifications**: Admin broadcasts visible to all players
- **Persistent Storage**: Global notifications stored in `system_notifications` collection
- **Individual Distribution**: Each player receives a copy in their personal notifications

### 🔔 **Notifications Screen** (`lib/screens/notifications_screen.dart`)
A dedicated full-screen UI for managing notifications:

#### Two Tabs
1. **Personal Tab**
   - Shows gifts from admins, royalty payments, achievements, warnings
   - Unread badge on notifications
   - Swipe to delete
   - Tap to mark as read

2. **Announcements Tab**
   - Global admin broadcasts
   - Game updates and announcements
   - Always visible (not marked as read)

#### Features
- **Pull to Refresh**: Update notifications manually
- **Contextual Icons**: Different icons for notification types
- **Time Formatting**: "Just now", "5m ago", "2h ago", etc.
- **Empty States**: Friendly messages when no notifications
- **Bulk Actions**:
  - Mark all as read
  - Clear read notifications

### 🎯 **Dashboard Integration** (`lib/screens/dashboard_screen_new.dart`)
- **Notification Bell**: Top-right corner with unread badge
- **Real-time Count**: Shows number of unread notifications
- **One-Tap Access**: Opens full notifications screen
- **Auto-Refresh**: Count updates after viewing notifications

### ☁️ **Cloud Functions** (`functions/index.js`)

#### `sendGlobalNotificationToPlayers`
Server-side function that distributes global notifications to all players:

```javascript
exports.sendGlobalNotificationToPlayers = functions.https.onCall(async (data, context) => {
  // Admin-only access
  await validateAdminAccess(context);
  
  // Batch creates notifications for all players
  // Handles up to 500 writes per batch
  // Returns success count
});
```

**Features:**
- ✅ Admin validation required
- ✅ Batch processing (500 writes/batch for efficiency)
- ✅ Creates individual notification for each player
- ✅ Returns statistics (players notified, notifications sent)

### 🎨 **Notification Types**

| Type | Icon | Color | Use Case |
|------|------|-------|----------|
| `admin_gift` | 🎁 | Gold | Admin sent you a gift |
| `royalty_payment` | 💰 | Green | Daily royalties from songs |
| `achievement` | 🏆 | Green | Unlocked achievement |
| `warning` | ⚠️ | Orange | System warnings |
| `global` | 📢 | Cyan | Admin broadcasts |
| `info` | ℹ️ | Cyan | General information |

## Usage Guide

### For Players

#### Viewing Notifications
1. Look for notification bell icon (🔔) in top-right of dashboard
2. Badge shows unread count (e.g., "3")
3. Tap bell to open Notifications screen
4. Switch between "Personal" and "Announcements" tabs

#### Managing Notifications
- **Mark as Read**: Tap unread notification
- **Delete**: Swipe left on notification (Personal only)
- **Mark All Read**: Menu button → "Mark All as Read"
- **Clear Read**: Menu button → "Clear Read"

### For Admins

#### Sending Global Notifications

**Via Admin Dashboard:**
1. Open Admin Dashboard
2. Click "Send Global Notification" button
3. Enter title and message
4. Click "Send"
5. Notification is instantly distributed to all players

**Behind the Scenes:**
```
Admin clicks Send
    ↓
1. Creates entry in system_notifications collection
    ↓
2. Calls Cloud Function sendGlobalNotificationToPlayers
    ↓
3. Function gets all players from Firestore
    ↓
4. Creates individual notification for each player
    ↓
5. Batch commits notifications (500 at a time)
    ↓
6. Players see notification in real-time
```

## Database Structure

### Player Notifications
```
players/{playerId}/notifications/{notificationId}
{
  "title": "💰 Daily Royalties",
  "message": "You earned $1,234 from 5,678 streams!",
  "type": "royalty_payment",
  "read": false,
  "timestamp": Timestamp,
  "data": {
    "amount": 1234,
    "streams": 5678
  }
}
```

### System Notifications
```
system_notifications/{docId}
{
  "title": "🎉 Version 2.0 Released!",
  "message": "Check out the new features...",
  "createdAt": Timestamp,
  "createdBy": "adminUID",
  "type": "global"
}
```

## Firestore Security Rules

Ensure these rules are in place:

```javascript
// Player notifications (personal)
match /players/{userId}/notifications/{notificationId} {
  // Players can read and update their own notifications
  allow read, update: if request.auth.uid == userId;
  
  // Only server (Cloud Functions) can create
  allow create: if false; // Prevent client-side creation
  
  // Players can delete their own
  allow delete: if request.auth.uid == userId;
}

// System notifications (global)
match /system_notifications/{notificationId} {
  // Everyone can read
  allow read: if request.auth != null;
  
  // Only server can write
  allow write: if false; // Admin writes via Cloud Function
}
```

## Testing

### Test Global Notification Flow

1. **As Admin:**
   ```
   1. Log in as admin
   2. Open Admin Dashboard
   3. Click "Send Global Notification"
   4. Title: "🎮 Test Notification"
   5. Message: "This is a test of the global notification system!"
   6. Click Send
   ```

2. **As Player:**
   ```
   1. Log in as regular player
   2. Look for notification bell badge (should show "1")
   3. Click bell icon
   4. See test notification in both Personal and Announcements tabs
   ```

3. **Verify in Firebase Console:**
   ```
   Check: system_notifications collection → Should have new document
   Check: players/{playerId}/notifications → Should have new notification
   ```

### Test Personal Notifications

The system already creates notifications for:
- ✅ Admin gifts (via Cloud Function)
- ✅ Daily royalties (via Cloud Function)
- ✅ Real-time listener picks them up automatically

## Performance Considerations

### Batching Strategy
- Cloud Function processes 500 notifications per batch
- For 1,000 players: 2 batches (< 2 seconds)
- For 10,000 players: 20 batches (< 20 seconds)
- Scales linearly with player count

### Firestore Costs
- **Read**: Each notification view = 1 read
- **Write**: Each global notification = 1 write per player
- **Storage**: ~100 bytes per notification
- **Example**: 1,000 players × 1 notification = 1,000 writes

### Optimization Tips
1. **Limit Frequency**: Don't send global notifications too often
2. **Clear Old Notifications**: Use admin "Clear Old Notifications" feature
3. **Pagination**: Notification screen loads only 50 at a time
4. **Real-time**: Uses snapshot listeners (efficient)

## Future Enhancements

### Push Notifications (Not Yet Implemented)
To add Firebase Cloud Messaging (FCM) push notifications:

1. **Add Dependencies:**
   ```yaml
   # pubspec.yaml
   dependencies:
     firebase_messaging: ^14.0.0
   ```

2. **Request Permissions:**
   ```dart
   // In notification_service.dart
   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
   
   await _messaging.requestPermission(
     alert: true,
     badge: true,
     sound: true,
   );
   ```

3. **Get FCM Token:**
   ```dart
   final token = await _messaging.getToken();
   // Store in Firestore players/{uid}/fcmToken
   ```

4. **Send from Cloud Function:**
   ```javascript
   // In sendGlobalNotificationToPlayers
   const messaging = admin.messaging();
   
   await messaging.sendToTopic('all_players', {
     notification: {
       title: title,
       body: message,
     },
   });
   ```

## Troubleshooting

### Notification Bell Shows Wrong Count
**Solution:** Pull down to refresh the dashboard

### Notifications Not showing up
1. Check Firebase Console → players/{uid}/notifications
2. Verify real-time listener is active (check console logs)
3. Ensure player is logged in

### Cloud Function Fails
1. Check Firebase Console → Functions → Logs
2. Verify admin permissions (checkAdminStatus)
3. Check Firestore permissions

### Global Notification Not Distributed
1. Verify Cloud Function deployed: `firebase deploy --only functions:sendGlobalNotificationToPlayers`
2. Check function logs in Firebase Console
3. Test with small player count first

## Code Examples

### Creating a Custom Notification (Server-Side)
```javascript
// In any Cloud Function
await db.collection('players')
  .doc(playerId)
  .collection('notifications')
  .add({
    title: '🎵 Song Went Viral!',
    message: 'Your song "Summer Vibes" reached 1M streams!',
    type: 'achievement',
    read: false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    data: {
      songId: 'song_123',
      streams: 1000000,
    },
  });
```

### Subscribing to Notifications (Client-Side)
```dart
// Already implemented in dashboard_screen_new.dart
NotificationService().notificationStream(unreadOnly: true)
  .listen((notifications) {
    print('Unread: ${notifications.length}');
  });
```

## Summary

✅ **Implemented:**
- Notification service
- Notifications screen UI
- Dashboard integration
- Cloud Function for global distribution
- Real-time updates
- Swipe-to-delete
- Unread badges
- Time formatting

⏳ **Pending:**
- Push notifications (FCM)
- Android/iOS native notifications
- Notification sounds

🎉 **Result:**
Players now receive and can manage all types of notifications through a beautiful, intuitive interface. Admins can broadcast announcements to all players instantly via the Cloud Function system!
