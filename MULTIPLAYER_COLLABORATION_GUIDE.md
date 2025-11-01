# 🤝 Multiplayer Collaboration System - Implementation Guide

## Overview
Players collaborate with **other real players** to create songs together. This is a **true multiplayer feature** where players can work on written songs, record together (with travel bonus), or send recordings remotely via StarChat.

---

## 🎯 Core Concept

### Collaboration Flow:
1. **Player A** has a **written song** (not yet recorded)
2. **Player A** searches for other players in StarChat/Collaborations
3. **Player A** sends collaboration request to **Player B**
4. **Player B** receives request in StarChat with notification
5. **Player B** accepts or rejects
6. **IF ACCEPTED:**
   - **Same Region**: Both can record together instantly (+30% boost)
   - **Different Regions**: 
     - Option 1: **Travel to record together** (costs money, +30% boost)
     - Option 2: **Send recording via StarChat** (remote, standard boost)
7. **Player A** receives recording/confirmation
8. **Player A** accepts the recording
9. Song is now **ready to release** as collaborative track
10. **Both players share earnings** based on split percentage (default 30%)

---

## 📊 Collaboration Types

| Type | Description | Boost | Requirements |
|------|-------------|-------|--------------|
| **Written** | Collab on written song before recording | Standard | Both have written songs |
| **Remote** | Record separately, send via StarChat | 1.2x-1.8x | Accept + Send recording |
| **In-Person** | Travel to same location, record together | **(1.2x-1.8x) × 1.3** | Travel cost + Same studio |

---

## 💰 Travel System

### Travel Costs Between Regions:
```
USA → Europe: $5,000
USA → Asia: $7,000
USA → Africa: $6,000
USA → Latin America: $4,000

Europe → Asia: $6,000
Europe → Africa: $4,000

Asia → Africa: $5,000

(Symmetric for reverse directions)
```

### Travel Benefits:
- **+30% stream boost** on top of base collaboration boost
- **+10 quality bonus**
- **+10 fame bonus**
- Unlocks "Recorded Together" badge on song

---

## 🎁 Collaboration Bonuses

### Base Boost (by featuring artist's fame):
| Featuring Artist Fame | Stream Multiplier | Quality Bonus | Fame Bonus | Fanbase Gain |
|-----------------------|-------------------|---------------|------------|--------------|
| 0-49 | 1.2x | +5 | +5 | 10% of fame |
| 50-99 | 1.3x | +7 | +10 | 10% of fame |
| 100-199 | 1.5x | +10 | +15 | 10% of fame |
| 200+ | 1.8x | +15 | +25 | 10% of fame |

### Bonus Multipliers:
- **Recorded Together**: ×1.3 stream boost, +10 quality, +10 fame
- **Same Region** (remote): ×1.1 stream boost, +3 quality
- **Genre Match**: ×1.15 stream boost, +5 quality, +5 fame

### Example Calculation:
```
Player A (100 fame) collabs with Player B (150 fame)
- Base: 1.5x streams, +10 quality, +15 fame
- Recorded Together: 1.5 × 1.3 = 1.95x streams, +20 quality, +25 fame
- Genre Match (both Hip Hop): 1.95 × 1.15 = 2.24x streams, +25 quality, +30 fame
```

---

## 💸 Revenue Sharing

### Default Split: 70/30
- **Primary Artist (song owner)**: 70%
- **Featuring Artist**: 30%

### Negotiable Range: 50/50 to 80/20
- Higher-fame artists can negotiate better splits
- Displayed in collaboration request

### How It Works:
1. Song generates $10,000 in streams
2. Primary earns: $7,000
3. Featuring earns: $3,000
4. Both see earnings in their analytics
5. Tracked per collaboration in Firebase

---

## 📱 StarChat Integration

### New Message Types:

#### 1. Collaboration Request
```json
{
  "type": "collaboration_request",
  "fromUserId": "player_a_id",
  "fromUserName": "Player A",
  "toUserId": "player_b_id",
  "collaborationId": "collab_123",
  "songTitle": "Summer Vibes",
  "message": "Hey! Want to collab on this track?",
  "splitPercentage": 30,
  "timestamp": "...",
  "read": false
}
```

#### 2. Recording Received
```json
{
  "type": "recording_received",
  "fromUserId": "player_b_id",
  "fromUserName": "Player B",
  "toUserId": "player_a_id",
  "collaborationId": "collab_123",
  "message": "sent their recording for 'Summer Vibes'",
  "recordingUrl": "...", // Optional audio file
  "timestamp": "...",
  "read": false
}
```

#### 3. Collaboration Accepted/Rejected
```json
{
  "type": "collaboration_accepted",
  "fromUserId": "player_b_id",
  "toUserId": "player_a_id",
  "collaborationId": "collab_123",
  "message": "accepted your collaboration request!",
  "timestamp": "...",
  "read": false
}
```

---

## 🗄️ Firebase Collections

### `collaborations` Collection:
```javascript
{
  id: "collab_123",
  songId: "song_456",
  primaryArtistId: "player_a_id",
  primaryArtistName: "Player A",
  featuringArtistId: "player_b_id",
  featuringArtistName: "Player B",
  featuringArtistAvatar: "https://...",
  status: "pending", // pending, accepted, recording, recorded, released, rejected, cancelled
  type: "remote", // written, remote, in_person
  createdDate: Timestamp,
  acceptedDate: Timestamp,
  recordedDate: Timestamp,
  releasedDate: Timestamp,
  splitPercentage: 30,
  totalEarnings: 0,
  primaryArtistEarnings: 0,
  featuringArtistEarnings: 0,
  primaryRegion: "usa",
  featuringRegion: "europe",
  recordedTogether: false,
  metadata: {
    songTitle: "Summer Vibes",
    genre: "Hip Hop",
    message: "Hey! Want to collab?",
    recordingUrl: "..." // If remote
  }
}
```

### Index Required:
```
collaborations:
- featuringArtistId + status
- status (whereIn query)
```

---

## 🎮 User Interface

### 3 Main Tabs:

#### 1. Find Players
- **Search bar** with filters:
  - Genre dropdown
  - Region dropdown
  - Fame range slider
- **Player cards** showing:
  - Avatar/initials
  - Name + fame badge
  - Primary genre
  - Current region
  - Online status (green dot)
  - Last active time
- **Tap card** → Opens player profile with "Send Collab Request" button

#### 2. Pending Requests
- **Incoming** (requests you received):
  - Song title + genre
  - From player name/avatar
  - Split percentage offer
  - Accept/Reject buttons
- **Outgoing** (requests you sent):
  - Song title
  - To player name/avatar
  - Status: Waiting for response
  - Cancel button

#### 3. Active Collabs
- **Cards for each collaboration**:
  - Song title
  - Collaborator name/avatar
  - Status indicator:
    - "🎤 Ready to Record"
    - "🎵 Recording in Progress"
    - "✅ Recorded, Ready to Release"
  - Action buttons:
    - "Record Together" (if same region or can travel)
    - "Send Recording" (if remote)
    - "Accept Recording" (if received)
    - "Release Song" (if recorded)

---

## 🔧 Implementation Files

### Models:
- `lib/models/collaboration.dart` ✅ Updated for multiplayer
  - `Collaboration` class
  - `CollaborationStatus` enum (7 states)
  - `CollaborationType` enum (3 types)
  - `PlayerArtist` class (search results)

### Services:
- `lib/services/collaboration_service.dart` ✅ Rewritten for Firebase
  - `searchPlayers()` - Find collaborators
  - `getRecommendedPlayers()` - Smart suggestions
  - `sendCollaborationRequest()` - Send via StarChat
  - `getPendingRequests()` - Stream of requests
  - `getActiveCollaborations()` - Stream of active collabs
  - `acceptCollaboration()` - Accept request
  - `rejectCollaboration()` - Reject request
  - `recordTogether()` - Mark as recorded together
  - `sendRecordingRemotely()` - Send via StarChat
  - `acceptRecording()` - Finalize collaboration
  - `calculateCollaborationBoost()` - Compute bonuses
  - `calculateTravelCost()` - Region travel costs

### Screens:
- `lib/screens/collaboration_screen.dart` ⚠️ **NEEDS COMPLETE REWRITE**

---

## 🚀 Integration Steps

### Step 1: Update StarChat
Add collaboration message handlers:

```dart
// In StarChat message display
if (message['type'] == 'collaboration_request') {
  return CollaborationRequestCard(
    message: message,
    onAccept: () => _acceptCollaboration(message['collaborationId']),
    onReject: () => _rejectCollaboration(message['collaborationId']),
  );
}

if (message['type'] == 'recording_received') {
  return RecordingReceivedCard(
    message: message,
    onAccept: () => _acceptRecording(message['collaborationId']),
  );
}
```

### Step 2: Add to Activity Hub
```dart
_buildActivityCard(
  title: '🤝 Collaborations',
  icon: Icons.people,
  color: Colors.purple,
  description: 'Collab with other players',
  onTap: () => Navigator.push(...CollaborationScreen()),
),
```

### Step 3: Update Song Release
When releasing collaborative song:

```dart
// Check if song has collaboration
final collab = await _getCollaboration(song.id);
if (collab != null) {
  // Apply boost
  final boost = CollaborationService().calculateCollaborationBoost(...);
  final boostedStreams = (baseStreams * boost.streamMultiplier).round();
  
  // Update song with featuring info
  song = song.copyWith(
    streams: boostedStreams,
    metadata: {
      ...song.metadata,
      'featuringArtist': collab.featuringArtistName,
      'collaborationBoost': boost.streamMultiplier,
    },
  );
  
  // Mark collaboration as released
  await CollaborationService().markAsReleased(collab.id);
}
```

### Step 4: Revenue Distribution
When calculating daily earnings:

```dart
// For collaborative songs
final collab = await _getCollaboration(song.id);
if (collab != null) {
  final totalEarnings = calculateSongEarnings(song);
  final primaryShare = (totalEarnings * (100 - collab.splitPercentage) / 100).round();
  final featuringShare = totalEarnings - primaryShare;
  
  // Update collaboration earnings
  await _firestore.collection('collaborations').doc(collab.id).update({
    'totalEarnings': FieldValue.increment(totalEarnings),
    'primaryArtistEarnings': FieldValue.increment(primaryShare),
    'featuringArtistEarnings': FieldValue.increment(featuringShare),
  });
  
  // Pay featuring artist
  await _firestore.collection('users').doc(collab.featuringArtistId).update({
    'currentMoney': FieldValue.increment(featuringShare),
  });
}
```

---

## ⚡ Cloud Functions (Optional)

### Auto-Reject After 7 Days:
```javascript
exports.autoRejectExpiredCollaborations = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    );
    
    const expired = await admin.firestore()
      .collection('collaborations')
      .where('status', '==', 'pending')
      .where('createdDate', '<', sevenDaysAgo)
      .get();
    
    const batch = admin.firestore().batch();
    expired.docs.forEach(doc => {
      batch.update(doc.ref, { status: 'cancelled' });
    });
    
    await batch.commit();
  });
```

### Distribute Earnings Daily:
```javascript
exports.distributeCollaborationEarnings = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    // Calculate and distribute earnings for all released collaborative songs
    // Update totalEarnings, primaryArtistEarnings, featuringArtistEarnings
  });
```

---

## ✅ Testing Checklist

### Basic Flow:
- [ ] Search for players by genre
- [ ] Search for players by region
- [ ] Send collaboration request
- [ ] Receive request in StarChat
- [ ] Accept request
- [ ] Reject request
- [ ] Cancel outgoing request

### Recording Flow:
- [ ] Same region: Record together
- [ ] Different regions: Choose travel or remote
- [ ] Travel to another region (cost deducted)
- [ ] Send recording remotely
- [ ] Receive recording notification
- [ ] Accept received recording
- [ ] Verify boost calculations

### Release & Earnings:
- [ ] Release collaborative song
- [ ] Song shows "feat. Artist Name"
- [ ] Stream boost applied correctly
- [ ] Revenue split calculated properly
- [ ] Both artists receive earnings
- [ ] Collaboration marked as "released"

### Edge Cases:
- [ ] Player goes offline during collab
- [ ] Player changes region after accepting
- [ ] Multiple collaborations on same song
- [ ] Collaboration with deleted user account

---

## 🎯 Success Metrics

Track these for feature health:
1. **Collaboration Rate**: % of players who send/accept collabs
2. **In-Person vs Remote**: Ratio of travel collabs to remote
3. **Genre Distribution**: Which genres collaborate most
4. **Cross-Region**: % of collabs between different regions
5. **Completion Rate**: % of accepted collabs that get released
6. **Earnings Split**: Average revenue per collaborative song

---

## 🔮 Future Enhancements

1. **Group Collabs**: 3+ artists on one track
2. **Collab Albums**: Full collaborative EPs/albums
3. **Remix System**: Remix other players' songs
4. **Collab Challenges**: Weekly themed collaboration events
5. **Collab Playlists**: Curated collaborative tracks
6. **Live Session**: Real-time recording sessions
7. **Collab Badges**: Achievements for collaborations
8. **Featured Collabs**: Spotlight on homepage

---

**Status**: 🚧 **Core Backend Complete** | UI Screen Needs Full Rebuild  
**Next Step**: Create new `collaboration_screen.dart` for multiplayer  
**Version**: 2.0 (Multiplayer)  
**Created**: November 1, 2025
