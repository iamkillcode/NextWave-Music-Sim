# Real-Time Firestore Listeners Implementation

## Overview
Implemented real-time Firestore listeners so players see stat updates **instantly** when they receive admin gifts or other changes to their account, without needing to refresh the app.

## What Was Added

### 1. StreamSubscriptions
Added two real-time listeners to `dashboard_screen_new.dart`:

```dart
StreamSubscription<DocumentSnapshot>? _playerDataSubscription;
StreamSubscription<QuerySnapshot>? _notificationsSubscription;
```

### 2. Player Data Listener
Listens to the player's document in Firestore:

**Path**: `players/{userId}`

**Triggers on**:
- Money changes (admin gifts, royalty payments)
- Fame changes (admin gifts, song releases)
- Energy changes (admin gifts, activities)
- Fanbase changes (admin gifts, new fans)
- Stats changes (any field update)

**What it does**:
- Automatically updates `artistStats` in real-time
- Reloads all player data including songs, regional fanbase, side hustles
- Updates UI instantly with `setState()`

### 3. Notifications Listener
Listens to unread notifications:

**Path**: `players/{userId}/notifications` where `read == false`

**Triggers on**:
- New admin gifts
- New achievements
- System notifications

**What it does**:
- Shows instant notification snackbar
- Marks notification as read
- Custom styling based on notification type (gift, achievement, warning)

### 4. Notification Snackbar
Displays instant notifications with:
- Custom colors based on type:
  - 🎁 Admin Gift: Gold (#FFD700)
  - 🏆 Achievement: Green (#32D74B)
  - ⚠️ Warning: Orange (#FF9500)
  - ℹ️ Info: Cyan (#00D9FF)
- Auto-dismiss after 5 seconds
- Floating design with rounded corners

## How It Works

### Setup Flow
```
1. Player logs in
2. _loadUserProfile() loads initial data
3. _setupRealtimeListeners() starts listeners
4. Listeners stay active until app closes
```

### Update Flow (Admin Sends Gift)
```
1. Admin clicks "Send Gift" in dashboard
2. Cloud Function updates Firestore: players/{userId}
3. Player's listener detects change instantly
4. _playerDataSubscription callback fires
5. setState() updates UI with new stats
6. Player sees updated money/fame/etc immediately

Simultaneously:

1. Cloud Function creates notification document
2. _notificationsSubscription detects new doc
3. Snackbar shows: "🎁 Gift Received! You received: $10,000"
4. Notification marked as read
```

### Cleanup
```dart
@override
void dispose() {
  // Cancel listeners to prevent memory leaks
  _playerDataSubscription?.cancel();
  _notificationsSubscription?.cancel();
  super.dispose();
}
```

## Code Example

### Listener Setup
```dart
void _setupRealtimeListeners() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Listen to player document
  _playerDataSubscription = FirebaseFirestore.instance
      .collection('players')
      .doc(user.uid)
      .snapshots()
      .listen((snapshot) {
        if (!snapshot.exists || !mounted) return;
        
        final data = snapshot.data()!;
        
        setState(() {
          artistStats = ArtistStats(
            money: (data['currentMoney'] ?? 0).toInt(),
            fame: (data['currentFame'] ?? 0).toInt(),
            // ... all other fields
          );
        });
      });

  // Listen to new notifications
  _notificationsSubscription = FirebaseFirestore.instance
      .collection('players')
      .doc(user.uid)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            _showNotificationSnackBar(
              data['title'],
              data['message'],
              data['type'],
            );
            // Mark as read
            change.doc.reference.update({'read': true});
          }
        }
      });
}
```

## Performance Considerations

### Firestore Reads
- **Player Data Listener**: 1 read on initial load, then 1 read per update
- **Notifications Listener**: 1 read on initial load, then 1 read per new notification
- **Total**: ~2 reads on load, ~2 reads per gift sent

### Cost Optimization
- Only listens to current user's data (not all players)
- Notifications limited to 10 most recent
- Only queries unread notifications
- Auto-marks as read to reduce future queries
- Listeners cancelled on dispose to prevent orphaned connections

### Expected Usage
For typical player:
- 1-2 admin gifts per week = ~4 reads/week
- Daily login = ~2 reads/day
- **Total**: ~18 reads/week per player

For 100 active players:
- ~1,800 reads/week = ~7,200 reads/month
- Well within free tier (50K reads/day)

## Testing

### Test Real-Time Updates
1. Open app and log in as Player A
2. Keep app open on dashboard
3. From another browser/device, log in as Admin
4. Send gift to Player A (e.g., $10,000)
5. **Expected**: Player A sees:
   - Money updates instantly in dashboard
   - Gold snackbar appears: "🎁 Gift Received! You received: $10,000"
   - No refresh needed

### Test Notification Types
```dart
// Admin Gift
{
  type: 'admin_gift',
  title: '🎁 Gift Received!',
  message: 'You received: $10,000'
}
// Shows gold snackbar with gift icon

// Achievement
{
  type: 'achievement',
  title: '🏆 Achievement Unlocked!',
  message: 'First 1K Streams!'
}
// Shows green snackbar with trophy icon

// System Notification
{
  type: 'info',
  title: 'ℹ️ Game Update',
  message: 'New features available!'
}
// Shows cyan snackbar with info icon
```

## Benefits

### For Players
- ✅ **Instant feedback** when receiving gifts
- ✅ **No refresh needed** to see stat changes
- ✅ **Real-time notifications** for important events
- ✅ **Better UX** - feels more responsive and modern

### For Admins
- ✅ **Immediate verification** that gifts were sent
- ✅ **Player sees changes right away** - no confusion
- ✅ **Better testing** - instant feedback loop

### For Development
- ✅ **Less manual refresh testing** needed
- ✅ **Easier debugging** - can see changes propagate live
- ✅ **More polished feel** - professional real-time experience

## Future Enhancements

### 1. Real-Time Leaderboards
```dart
// Listen to leaderboard changes
FirebaseFirestore.instance
  .collection('leaderboard_history')
  .doc('songs_${currentWeek}')
  .snapshots()
  .listen((snapshot) {
    // Update charts in real-time
  });
```

### 2. Real-Time EchoX Feed
```dart
// Listen to new posts
FirebaseFirestore.instance
  .collection('echox_posts')
  .orderBy('timestamp', descending: true)
  .limit(20)
  .snapshots()
  .listen((snapshot) {
    // Show new posts as they're created
  });
```

### 3. Real-Time Multiplayer Stats
```dart
// Listen to other players' stats
FirebaseFirestore.instance
  .collection('players')
  .where('fame', isGreaterThan: 100)
  .snapshots()
  .listen((snapshot) {
    // Update "Who's Hot" section in real-time
  });
```

### 4. Real-Time NPC Releases
```dart
// Listen to NPC activity
FirebaseFirestore.instance
  .collection('echox_posts')
  .where('isNPC', isEqualTo: true)
  .orderBy('timestamp', descending: true)
  .limit(5)
  .snapshots()
  .listen((snapshot) {
    // Show "NPC just released a song!" notifications
  });
```

## Troubleshooting

### Listener Not Firing
**Check**:
1. User is logged in: `FirebaseAuth.instance.currentUser != null`
2. Document exists: `players/{userId}` exists in Firestore
3. Listener is set up: `_playerDataSubscription != null`
4. Widget is mounted: `mounted == true`

### Multiple Updates
**Issue**: Listener fires multiple times for same change
**Solution**: Already handled - we use `setState()` which batches updates

### Memory Leaks
**Issue**: Listeners not cancelled
**Solution**: Already handled - cancelled in `dispose()`

### Notification Spam
**Issue**: Same notification shows multiple times
**Solution**: We mark as `read: true` after showing once

## Summary

**What changed**:
1. ✅ Added `StreamSubscription` fields to dashboard
2. ✅ Created `_setupRealtimeListeners()` method
3. ✅ Added `_showNotificationSnackBar()` for instant alerts
4. ✅ Cancelled listeners in `dispose()`

**Result**:
- Players see gift updates **instantly**
- No refresh needed
- Professional real-time experience
- Minimal performance impact

**Next**: Deploy Flutter web build and test end-to-end!
