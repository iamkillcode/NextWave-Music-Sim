# Admin Gift System

## ✅ Implementation Complete

**Date**: January 2025  
**Status**: Fully Implemented - Ready to Use

## Overview

Admins can now send gifts (money, fame, energy, fans, streams, or preset packs) to players for testing and rewards. Recipients receive in-app notifications when they log in.

---

## 🎁 Gift Types

### Individual Resources

| Type | Icon | Description | Default Amount |
|------|------|-------------|----------------|
| **Money** | 💵 | Give cash to help with expenses | $1,000 |
| **Fame** | ⭐ | Boost their fame points | 10 |
| **Energy** | ⚡ | Restore energy (max 100) | 50 |
| **Fans** | 👥 | Add to their fanbase | 1,000 |
| **Streams** | 🎵 | Boost total stream count | 10,000 |

### Preset Packs

| Pack | Icon | Contents | Purpose |
|------|------|----------|---------|
| **Starter Pack** | 🎁 | $5,000 + 25 Fame + 100 Energy + 500 Fans | New testers, quick start |
| **Boost Pack** | 📦 | $15,000 + 50 Fame + 2,000 Fans + 50,000 Streams | Mid-game testing |
| **Premium Pack** | 👑 | $50,000 + 100 Fame + 10,000 Fans + 250,000 Streams | Advanced testing |

---

## 🎮 How to Use (Admin)

### Step 1: Access Admin Dashboard
1. Navigate to **Settings** → **Admin Dashboard**
2. Verify you have admin privileges

### Step 2: Send Gift
1. Click **"Send Gift to Player"** button (pink card icon)
2. **Select Recipient**: Choose from dropdown list of all players
   - Shows player name, fame, money, and fanbase
   - Sorted alphabetically
3. **Choose Gift Type**: Select from 8 different gift options
   - Individual resources (with custom amounts)
   - Preset packs (fixed amounts)
4. **Set Amount** (if applicable): 
   - For individual resources, enter custom amount
   - Auto-fills with default amount
   - Packs have fixed amounts
5. **Add Message** (optional):
   - Personal message to the recipient
   - Shows in their notification
6. Click **"Send Gift"** button

### Step 3: Confirmation
- Success dialog shows:
  - Gift description
  - Recipient name
  - Confirmation that notification was created

---

## 📱 Player Experience

### Receiving Gifts

1. **Login**: Player logs into the game
2. **Automatic Check**: System checks for unread Firebase notifications
3. **In-App Notification**: Gift appears in notification bell
   - 🎁 Gift icon for admin gifts
   - Title: "🎁 Gift Received!"
   - Message shows what was received
4. **Stats Updated**: Money, fame, fans, etc. automatically updated
5. **Mark as Read**: Notification marked as read after viewing

### Notification Display

```
🎁 Gift Received!
You've received a gift from the admin: $5,000

or

🎁 Gift Received!
You've received a gift from the admin: Starter Pack 
($5,000, 25 Fame, 100 Energy, 500 Fans)
```

---

## 🔧 Technical Implementation

### Backend (Cloud Functions)

**File**: `functions/index.js`

```javascript
exports.sendGiftToPlayer = functions.https.onCall(async (data, context) => {
  // Admin authentication check
  // Parse gift type and amount
  // Update player stats in Firestore
  // Create notification document
  // Log gift in admin_gifts collection
});
```

**Gift Processing**:
- Money: Adds to player's money
- Fame: Adds to player's fame
- Energy: Adds to energy (max 100)
- Fans: Adds to fanbase
- Streams: Adds to totalStreams
- Packs: Multiple resource updates

**Notification Structure**:
```javascript
{
  id: 'notification_id',
  type: 'admin_gift',
  title: '🎁 Gift Received!',
  message: 'Gift description',
  giftType: 'money',
  giftDescription: '$1,000',
  amount: 1000,
  timestamp: serverTimestamp,
  read: false,
  fromAdmin: true,
  adminId: 'admin_uid'
}
```

### Frontend (Flutter/Dart)

**File**: `lib/services/admin_service.dart`

```dart
Future<Map<String, dynamic>> sendGiftToPlayer({
  required String recipientId,
  required String giftType,
  int? amount,
  String? message,
}) async {
  // Admin check
  // Call Cloud Function
  // Return result
}

Future<List<Map<String, dynamic>>> getAllPlayers() async {
  // Get player list for dropdown
}
```

**File**: `lib/screens/admin_dashboard_screen.dart`
- Gift dialog UI with dropdowns
- Player selection
- Gift type selection
- Amount input
- Message input
- Send button

**File**: `lib/screens/dashboard_screen_new.dart`

```dart
Future<void> _loadFirebaseNotifications() async {
  // Query unread notifications
  // Add to in-app notification list
  // Mark as read in Firebase
}
```

---

## 🗄️ Database Structure

### Firestore Collections

**players/{userId}/notifications/{notificationId}**
```json
{
  "id": "notif_123",
  "type": "admin_gift",
  "title": "🎁 Gift Received!",
  "message": "You've received a gift from the admin: $5,000",
  "giftType": "money",
  "giftDescription": "$5,000",
  "amount": 5000,
  "timestamp": "2025-01-17T10:30:00Z",
  "read": false,
  "fromAdmin": true,
  "adminId": "admin_uid_123"
}
```

**admin_gifts/{giftId}** (audit log)
```json
{
  "recipientId": "user_123",
  "recipientName": "John Doe",
  "giftType": "starter_pack",
  "amount": null,
  "giftDescription": "Starter Pack ($5,000, 25 Fame, 100 Energy, 500 Fans)",
  "message": "Welcome to testing!",
  "adminId": "admin_uid_123",
  "timestamp": "2025-01-17T10:30:00Z"
}
```

**players/{userId}** (updated fields)
```json
{
  "money": 10000,      // Updated by gift
  "fame": 35,          // Updated by gift
  "energy": 100,       // Updated by gift
  "fanbase": 1500,     // Updated by gift
  "totalStreams": 5000 // Updated by gift
}
```

---

## 📊 Admin Audit Trail

All gifts are logged in the `admin_gifts` collection for:
- **Accountability**: Track who sent what to whom
- **Analytics**: See gift distribution patterns
- **Support**: Reference for player support requests
- **Debugging**: Verify gift delivery

Query example:
```javascript
// Get all gifts sent to a player
db.collection('admin_gifts')
  .where('recipientId', '==', userId)
  .orderBy('timestamp', 'desc')
  .get();

// Get all gifts sent by an admin
db.collection('admin_gifts')
  .where('adminId', '==', adminId)
  .orderBy('timestamp', 'desc')
  .get();
```

---

## 🎯 Use Cases

### Testing Scenarios

1. **New Tester Onboarding**
   - Gift: Starter Pack
   - Purpose: Give immediate resources to explore features
   - Message: "Welcome to NextWave testing! Here's a starter pack to help you get started."

2. **Feature Testing**
   - Gift: Premium Pack
   - Purpose: Test high-level features without grind
   - Message: "Testing the record label system? Here's a boost to get you there!"

3. **Bug Compensation**
   - Gift: Money or Fans
   - Purpose: Compensate for lost progress due to bugs
   - Message: "Sorry about that bug! Here's compensation for your time."

4. **Event Rewards**
   - Gift: Custom amount
   - Purpose: Reward community participation
   - Message: "Thanks for being an awesome tester! Here's a reward for your feedback."

5. **Milestone Celebration**
   - Gift: Fame + Fans
   - Purpose: Celebrate testing milestones
   - Message: "Congrats on reaching 100 fame! Here's a bonus for your progress."

---

## 🔒 Security & Permissions

### Admin Verification
- Cloud Function checks `context.auth`
- Admin status verified via `AdminService.isAdmin()`
- Hardcoded admin IDs in `ADMIN_USER_IDS`
- Firestore `admins` collection for dynamic permissions

### Rate Limiting
- ⚠️ **Not Implemented**: Consider adding rate limits
- Suggestion: Max 10 gifts per admin per hour
- Prevents accidental mass gifting

### Input Validation
- ✅ RecipientId required
- ✅ GiftType required
- ✅ Player existence check
- ✅ Gift type validation
- ⚠️ Amount validation (consider adding min/max limits)

---

## 🐛 Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Player not found" | Invalid recipientId | Check player list, ensure player exists |
| "Invalid gift type" | Typo in giftType | Use only defined gift types |
| "Unauthenticated" | Not logged in | Ensure admin is logged in |
| "Admin access required" | Not an admin | Add user to ADMIN_USER_IDS or admins collection |
| "Timeout" | Slow network | Retry operation |

### User Feedback
- Loading dialogs during operations
- Success dialogs with gift details
- Error dialogs with helpful messages
- SnackBar confirmations

---

## 🚀 Future Enhancements

### Planned Features

1. **Gift History View**
   - Show all gifts received by a player
   - Admin view of all gifts sent
   - Filter by date, type, recipient

2. **Scheduled Gifts**
   - Schedule gifts for specific dates
   - Auto-send on player milestones
   - Birthday/anniversary gifts

3. **Gift Templates**
   - Save custom gift configurations
   - Quick send common combinations
   - Preset messages

4. **Bulk Gifting**
   - Send to multiple players at once
   - Filter by criteria (fame level, join date, etc.)
   - Global rewards for all players

5. **Gift Items**
   - Studio time vouchers
   - Platform unlock tokens
   - Special cosmetic items
   - Exclusive features

6. **Player Gift Requests**
   - Players can request specific gifts
   - Admin approval system
   - Request tracking

---

## 📝 Testing Checklist

- [x] Create Cloud Function `sendGiftToPlayer`
- [x] Add admin service methods
- [x] Create gift dialog UI
- [x] Implement player dropdown
- [x] Implement gift type dropdown
- [x] Add amount input for individual resources
- [x] Add optional message field
- [x] Test money gift
- [x] Test fame gift
- [x] Test energy gift
- [x] Test fans gift
- [x] Test streams gift
- [x] Test starter pack
- [x] Test boost pack
- [x] Test premium pack
- [x] Test Firebase notification creation
- [x] Test notification display on login
- [x] Test notification mark as read
- [x] Test audit log creation
- [x] Test error handling
- [x] Test admin permission check
- [ ] Test with real testers
- [ ] Verify Firebase security rules

---

## 💡 Best Practices

### For Admins

1. **Use Appropriate Gifts**: Match gift to purpose
   - Testing features? → Premium Pack
   - New tester? → Starter Pack
   - Bug compensation? → Custom amount

2. **Add Personal Messages**: Makes gifts feel special
   - Explain why they're receiving it
   - Thank them for testing
   - Encourage specific testing

3. **Track Gifts**: Keep notes on who got what and why
   - Use admin_gifts collection
   - Document in testing logs
   - Monitor for balance issues

4. **Be Consistent**: Fair treatment across testers
   - Similar issues = similar compensation
   - Milestone rewards for all
   - Transparent gifting policy

### For Players

1. **Check Notifications**: Log in regularly to see gifts
2. **Report Issues**: If gift doesn't arrive, contact admin
3. **Use Wisely**: Gifts are for testing, not exploitation
4. **Provide Feedback**: Let admins know if gifts help testing

---

## 🔗 Related Documentation

- [Admin Service](../lib/services/admin_service.dart) - Admin functionality
- [Dashboard Screen](../lib/screens/dashboard_screen_new.dart) - Player UI
- [Cloud Functions](../functions/index.js) - Backend logic
- Firebase Notifications - Notification system

---

## 📞 Support

**For Admins:**
- Can't send gift? Check admin permissions
- Player not in list? They may not exist yet
- Gift failed? Check error message in dialog

**For Players:**
- Didn't receive gift? Check notification bell
- Stats not updated? Reload the game
- Gift issues? Contact admin

---

## 🎉 Summary

The Admin Gift System provides a flexible way to:
- ✅ Reward testers
- ✅ Compensate for bugs
- ✅ Enable feature testing
- ✅ Boost progression for testing
- ✅ Track all gifts for accountability

Recipients are notified in-app and gifts are automatically applied to their accounts. All gifts are logged for audit purposes.
