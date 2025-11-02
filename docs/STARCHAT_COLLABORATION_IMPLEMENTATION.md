# Collaboration via StarChat - Complete Implementation

## Overview
Players can now send collaboration requests via StarChat with optional feature fees. The requests appear as special cards in the chat interface with Accept/Decline buttons.

## Complete User Flow

### 1. Sending a Collaboration Request

**Player A (Primary Artist):**
1. Opens the Collaboration screen
2. Searches for another player (e.g., Player B)
3. Selects a written song (e.g., "Still Dre")
4. Optionally enters a feature fee (e.g., $500)
5. Sets the split percentage (e.g., 70/30)
6. Clicks "Send Request"

**Behind the scenes:**
- Creates a `Collaboration` document in Firestore with status='pending'
- Sends a special message to `starchat_messages` collection with type='collaboration_request'
- Message includes: songTitle, featureFee, splitPercentage, collaborationId

### 2. Receiving the Request in StarChat

**Player B (Featuring Artist):**
1. Opens StarChat inbox
2. Sees a new message from Player A
3. Opens the conversation
4. Sees a **special collaboration request card** (not regular text) with:
   - 🎵 Song title: "Still Dre"
   - Message: "wants to collaborate with you on 'Still Dre'"
   - Split details: 70% / 30%
   - Feature fee: $500 (if applicable)
   - **Accept** and **Decline** buttons

### 3. Accepting the Collaboration

**Player B clicks "Accept":**
- System checks if Player A can afford the feature fee
- Automatically deducts $500 from Player A
- Automatically pays $500 to Player B
- Updates collaboration status to 'accepted'
- Adds featuring artist info to song metadata:
  ```json
  {
    "metadata": {
      "featuringArtist": "Player B Name",
      "featuringArtistId": "player_b_id",
      "isCollaboration": true
    }
  }
  ```
- Marks the StarChat message as read (buttons disappear, shows "✓ Responded")
- Shows success notification

### 4. After Acceptance

**Both players:**
- Can now see the collaboration in their "Active Collabs" tab
- Can proceed to record the song
- Can choose to record remotely or travel to record together (bonus boost)

### 5. Song Title Display

**Throughout the app, the song will display as:**
- For Player A (Primary): "Still Dre (feat. Player B)"
- For Player B (Featuring): "Still Dre (feat. Player A)"
- On public charts/leaderboards: "Still Dre - Player A feat. Player B"

## Technical Implementation

### Files Modified:

1. **lib/services/chat_service.dart**
   - Added `streamCollabRequests()` - Streams collaboration request messages
   - Added `markCollabRequestAsRead()` - Marks requests as handled

2. **lib/screens/chat_screen.dart**
   - Updated to combine regular messages + collab requests
   - Added `_buildCollabRequestCard()` - Renders special collab card
   - Added `_handleAcceptCollab()` - Processes acceptance with payment
   - Added `_handleDeclineCollab()` - Processes rejection

3. **lib/services/collaboration_service.dart**
   - Updated `acceptCollaboration()` to add featuring artist to song metadata
   - Already had `sendCollaborationRequest()` that sends to StarChat

4. **lib/utils/song_display_helper.dart** (NEW)
   - `getFormattedTitle()` - Formats song titles with "(feat. Artist)"
   - `isCollaboration()` - Checks if song is a collab
   - `getFeaturingArtist()` - Gets featuring artist name

5. **lib/models/chat_message.dart** (Already had)
   - `MessageType.collabRequest` enum value
   - `metadata` field for collaboration details

### Data Flow:

```
Collaboration Screen
    ↓
sendCollaborationRequest()
    ↓
Firestore: collaborations collection (status='pending')
    ↓
Firestore: starchat_messages collection (type='collaboration_request')
    ↓
Chat Screen streams both:
  - Regular messages from chat_conversations/{id}/messagesArchive
  - Collab requests from starchat_messages
    ↓
Displays special card for collab requests
    ↓
User clicks Accept
    ↓
acceptCollaboration()
  - Updates song metadata with featuring artist
  - Processes payment if feature fee exists
  - Updates collaboration status to 'accepted'
  - Marks message as read
    ↓
Success! Both artists can now record
```

## Key Features

### ✅ No Conflicts Between Systems
- Collaboration screen continues to work as before for managing active collabs
- StarChat is ONLY used for the initial request/acceptance flow
- After acceptance, all collaboration management happens in the Collaboration screen

### ✅ Proper Song Title Display
- Song metadata stores featuring artist info after acceptance
- Use `SongDisplayHelper.getFormattedTitle(song)` anywhere you display song titles
- Example: "Still Dre" → "Still Dre (feat. Snoop Dogg)"

### ✅ Payment Flow
- Feature fees are optional
- Payment happens automatically on acceptance
- If primary artist can't afford fee, acceptance fails with error message
- Featuring artist receives payment instantly

### ✅ Visual Design
- Collab requests have a special gradient card design (purple to green)
- Clear action buttons (green Accept, red Decline)
- Shows all relevant info: song title, split %, fee amount
- After response, shows "✓ Responded" to prevent double-action

## Usage Example

### Displaying Song Titles Anywhere:

```dart
import '../utils/song_display_helper.dart';

// In any widget that displays songs:
Text(
  SongDisplayHelper.getFormattedTitle(song),
  style: TextStyle(fontSize: 16),
)

// This will automatically show:
// - "Still Dre (feat. Snoop Dogg)" if it's a collab
// - "Still Dre" if it's a solo song
```

### Checking if Song is a Collaboration:

```dart
if (SongDisplayHelper.isCollaboration(song)) {
  final featuringArtist = SongDisplayHelper.getFeaturingArtist(song);
  print('Featuring: $featuringArtist');
}
```

## Testing Checklist

- [ ] Send collab request from Player A to Player B
- [ ] Verify request appears in Player B's StarChat
- [ ] Verify special card displays correctly with all info
- [ ] Accept request and verify payment processes
- [ ] Verify song metadata updated with featuring artist
- [ ] Verify collaboration appears in both players' Active Collabs
- [ ] Verify song title displays with "(feat. Artist)" in various screens
- [ ] Decline request and verify collaboration status updates
- [ ] Test with and without feature fees
- [ ] Test error handling (insufficient funds)

## Future Enhancements

1. **Notifications**: Push notification when collab request received
2. **Counter Offers**: Allow featuring artist to negotiate split/fee
3. **Expiration**: Auto-decline requests after X days
4. **History**: View declined/expired collaboration requests
5. **Group Collabs**: Support more than 2 artists on one song
