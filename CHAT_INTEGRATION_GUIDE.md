# StarChat Integration Guide

## Quick Start: Adding StarChat to Your App

### 1. StarChat in Media Hub (✅ COMPLETED)

**StarChat is now accessible from the Media Hub screen!**
- Located in the Social Media section
- Shows real-time unread message count badge
- Gradient icon (neon green to neon purple)
- Tapping opens the StarChat conversation list

### 2. Add Messages Button to Dashboard (Optional)

**File:** `lib/screens/dashboard_screen_new.dart`

Add to top bar actions:
```dart
actions: [
  // Existing notifications button
  _buildNotificationButton(),
  
  // NEW: Messages button with unread badge
  StreamBuilder<int>(
    stream: ChatService().streamTotalUnreadCount(),
    builder: (context, snapshot) {
      final unreadCount = snapshot.data ?? 0;
      return Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversationListScreen(),
                ),
              );
            },
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  ),
],
```

**Imports needed:**
```dart
import 'services/chat_service.dart';
import 'screens/conversation_list_screen.dart';
```

### 2. Add "Send Message" to Player Profiles

**Example Location:** When viewing another player's profile/stats

```dart
// Button to start DM conversation
ElevatedButton.icon(
  onPressed: () async {
    final chatService = ChatService();
    final conversation = await chatService.startConversation(
      otherUserId: playerData.userId,
      otherUserName: playerData.displayName,
      otherUserAvatar: playerData.avatarUrl,
    );
    
    if (conversation != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversation.id,
            otherUserId: playerData.userId,
            otherUserName: playerData.displayName,
            otherUserAvatar: playerData.avatarUrl,
          ),
        ),
      );
    }
  },
  icon: const Icon(Icons.send),
  label: const Text('Send Message'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.neonGreen,
    foregroundColor: Colors.black,
  ),
)
```

### 3. Add Messages Icon to Bottom Navigation

**File:** `lib/widgets/glassmorphic_bottom_nav.dart` (or your navigation widget)

Add new nav item:
```dart
BottomNavigationBarItem(
  icon: StreamBuilder<int>(
    stream: ChatService().streamTotalUnreadCount(),
    builder: (context, snapshot) {
      final unreadCount = snapshot.data ?? 0;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.chat_bubble_outline),
          if (unreadCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  ),
  label: 'Messages',
)
```

Then in your screen navigation logic:
```dart
case 3: // Messages tab index
  return const ConversationListScreen();
```

### 4. Add DM Button to Charts/Leaderboards

**Example:** Next to each player in the charts

```dart
// In your leaderboard list tile
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text('#${index + 1}', style: rankStyle),
    const SizedBox(width: 8),
    
    // NEW: Quick DM button
    IconButton(
      icon: Icon(Icons.chat, color: AppTheme.neonGreen, size: 20),
      onPressed: () async {
        final chatService = ChatService();
        final conversation = await chatService.startConversation(
          otherUserId: player.userId,
          otherUserName: player.displayName,
          otherUserAvatar: player.avatarUrl,
        );
        
        if (conversation != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversation.id,
                otherUserId: player.userId,
                otherUserName: player.displayName,
                otherUserAvatar: player.avatarUrl,
              ),
            ),
          );
        }
      },
      tooltip: 'Send message',
    ),
  ],
)
```

### 5. Add Comments to NexTube Videos (Next Phase)

**Example:** Video detail screen

```dart
// After video player/info
Divider(color: Colors.white.withOpacity(0.2)),
Text(
  'Comments',
  style: TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 16),

// Comments list (to be implemented in Phase 2)
StreamBuilder<List<Comment>>(
  stream: FirebaseFirestore.instance
      .collection('comments')
      .where('contextType', isEqualTo: 'video')
      .where('contextId', isEqualTo: videoId)
      .where('parentCommentId', isNull: true) // Top-level only
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Comment.fromJson(doc.data()))
          .toList()),
  builder: (context, snapshot) {
    // Comment UI to be implemented
    return CommentsList(comments: snapshot.data ?? []);
  },
)
```

## Testing Your Integration

### Test DM Flow:
1. Click messages button in top bar → Opens conversation list
2. Search for player → Shows filtered results
3. Click conversation → Opens chat screen
4. Send message → Appears immediately
5. Check unread count → Updates in real-time
6. Long-press message → Shows reaction options
7. Add reaction → Appears on message
8. Open options menu → Block/report options

### Test From Different Entry Points:
- [ ] Dashboard top bar → Conversations
- [ ] Bottom navigation → Conversations
- [ ] Player profile → Start DM → Chat screen
- [ ] Leaderboard → Quick DM button → Chat screen

## Common Issues & Solutions

### Issue: "ChatService not found"
**Solution:** Add import:
```dart
import '../services/chat_service.dart';
```

### Issue: "ConversationListScreen not found"
**Solution:** Add import:
```dart
import '../screens/conversation_list_screen.dart';
```

### Issue: Unread count not updating
**Solution:** Make sure you're using `StreamBuilder` and the stream from `ChatService().streamTotalUnreadCount()`

### Issue: Messages not appearing in real-time
**Solution:** Check that you're using `StreamBuilder` with `chatService.streamMessages(conversationId)`

### Issue: "Permission denied" errors
**Solution:** Ensure Firestore rules are deployed:
```bash
firebase deploy --only firestore:rules
```

## UI Customization

### Change Message Bubble Colors:
**File:** `lib/screens/chat_screen.dart`

Line ~440:
```dart
color: isMe ? AppTheme.neonGreen : AppTheme.surfaceDark,
// Change to your preferred colors
```

### Change Typing Indicator Color:
**File:** `lib/screens/conversation_list_screen.dart`

Line ~410:
```dart
color: AppTheme.neonGreen,
// Change to your preferred color
```

### Adjust Message Caching:
**File:** `lib/services/chat_service.dart`

Line ~12:
```dart
static const int _maxRecentMessages = 20;
// Increase for more cached messages (costs more storage)
// Decrease for less storage (costs more reads)
```

## Performance Tips

1. **Don't create multiple ChatService instances** - Reuse the same instance when possible
2. **Dispose StreamBuilders properly** - Always in a StatefulWidget that disposes streams
3. **Use pagination** - Don't load all messages at once (ChatScreen handles this automatically)
4. **Monitor Firestore usage** - Check Firebase console for read/write costs

## Next Steps After Integration

1. **Test with real users** - Get feedback on UX
2. **Add analytics** - Track message send rates, conversation starts
3. **Implement comments** - Phase 2 feature
4. **Add beef tracking** - Phase 3 feature (messages that start beefs)
5. **Create crews** - Phase 4 feature (group chat)

## Support Resources

- **Data Models:** `lib/models/chat_*.dart` and `lib/models/comment.dart`
- **Service Layer:** `lib/services/chat_service.dart`
- **UI Examples:** `lib/screens/conversation_list_screen.dart` and `lib/screens/chat_screen.dart`
- **Complete Documentation:** `CHAT_SYSTEM_PHASE1_COMPLETE.md`

---

**Questions or Issues?** Check the implementation files or refer to the complete documentation.
