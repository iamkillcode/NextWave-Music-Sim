# 🔧 Critical Fixes - October 17, 2025 (Part 2)

## Overview
Addressing 8 critical issues identified during testing and gameplay.

---

## Issue 1: Non-Released Songs Count Towards songsWritten ❌

### **Problem:**
`songsWritten` counter increments when a song is created (written state), but should only count when songs are RELEASED.

### **Current Behavior:**
```dart
// dashboard_screen_new.dart, write_song_screen.dart
setState(() {
  artistStats = artistStats.copyWith(
    songsWritten: artistStats.songsWritten + 1, // ❌ Increments on write
    songs: [...artistStats.songs, newSong],
  );
});
```

### **Expected Behavior:**
- `songsWritten` should only increment when `song.state == SongState.released`
- Written and recorded songs don't count until released

### **Solution:**
1. Remove `songsWritten + 1` from all song creation methods
2. Add `songsWritten + 1` only when releasing songs (in studio_screen.dart)
3. Add `songsReleased` counter for clarity

### **Files to Modify:**
- `lib/screens/dashboard_screen_new.dart` (2 locations)
- `lib/screens/write_song_screen.dart` (2 locations)
- `lib/screens/studio_screen.dart` (add increment on release)
- `lib/models/artist_stats.dart` (add songsReleased field)

---

## Issue 2: Admin Daily Update Fails - "Game time not initialized" ❌

### **Problem:**
Admin dashboard "Trigger Daily Update" button fails with error:
```
[firebase_functions/internal] Game time not initialized
```

### **Root Cause:**
`functions/index.js` line 993 throws error if `game_state/global_time` doesn't exist:
```javascript
if (!gameTimeDoc.exists) {
  throw new functions.https.HttpsError('not-found', 'Game time not initialized');
}
```

### **Solution:**
Initialize game time if it doesn't exist:
```javascript
if (!gameTimeDoc.exists) {
  // Initialize game time
  const startDate = new Date('2020-01-01');
  await gameTimeRef.set({
    currentGameDate: admin.firestore.Timestamp.fromDate(startDate),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  });
  const currentGameDate = startDate;
}
```

### **Files to Modify:**
- `functions/index.js` - triggerDailyUpdate function (~line 987)

---

## Issue 3: Active Hustles Shows 0 When Players Have Active Hustles ❌

### **Problem:**
Admin dashboard "Active Hustles" statistic shows 0 even when players have active side hustles.

### **Root Cause:**
`admin_service.dart` line 205 queries `side_hustle_contracts` collection with `isActive` field:
```dart
final hustleSnapshot = await _firestore
    .collection('side_hustle_contracts')
    .where('isActive', isEqualTo: true)
    .get();
```

But side hustles are stored in `players.activeSideHustle`, NOT in a separate collection!

### **Solution:**
Count players who have non-null `activeSideHustle`:
```dart
int activeHustles = 0;
for (var player in playersSnapshot.docs) {
  final sideHustle = player.data()['activeSideHustle'];
  if (sideHustle != null) {
    activeHustles++;
  }
}
```

### **Files to Modify:**
- `lib/services/admin_service.dart` - getGameStats() method (~line 205)

---

## Issue 4: Monthly Listeners Logic & Platform Differences 📊

### **Current Implementation:**
```dart
// tunify_screen.dart line 42
final monthlyListeners = (totalStreams * 0.3).round();
```

### **Analysis:**
Monthly listeners are currently:
- **Tunify:** 30% of total streams (simulating unique listeners)
- **Maple Music:** Not separately calculated

### **Reality Check:**
- Tunify has 85% reach → More monthly listeners
- Maple Music has 65% reach → Fewer monthly listeners
- Both should be calculated separately based on platform-specific streams

### **Proposed Enhancement:**
```dart
// Tunify monthly listeners
final tunifyStreams = _getTunifyStreams(); // streams × 0.85
final tunifyMonthlyListeners = (tunifyStreams * 0.35).round();

// Maple Music followers (different metric)
final mapleStreams = _getMapleMusicStreams(); // streams × 0.65
final mapleFollowers = (mapleStreams * 0.25).round();
```

**Explanation:**
- Tunify uses "monthly listeners" (35% of platform streams)
- Maple Music uses "followers" (25% of platform streams)
- Reflects different user behavior per platform

### **Files to Document:**
- `docs/systems/MONTHLY_LISTENERS_LOGIC.md` (NEW)

---

## Issue 5: Fame Should Decay Based on Idleness 📉

### **Problem:**
Fame never decreases. Inactive artists maintain fame indefinitely.

### **Proposed System:**
```javascript
// Daily fame decay for inactive artists
const daysSinceLastActivity = calculateDaysSince(playerData.lastActivityDate);

if (daysSinceLastActivity > 7) {
  // 1% fame loss per day after 7 days of inactivity
  const fameDecay = Math.floor(playerData.fame * 0.01 * (daysSinceLastActivity - 7));
  updates.fame = Math.max(0, playerData.fame - fameDecay);
}
```

### **Tracking Activity:**
Update `lastActivityDate` when player:
- Releases a song
- Performs on ViralWave
- Posts on EchoX
- Gains streams

### **Files to Modify:**
- `functions/index.js` - processDailyStreamsForPlayer() add fame decay
- `lib/models/artist_stats.dart` - add lastActivityDate field
- `lib/screens/dashboard_screen_new.dart` - update lastActivityDate on actions
- `lib/screens/viralwave_screen.dart` - update on campaigns
- `lib/screens/echox_screen.dart` - update on posts

---

## Issue 6: ViralWave EP/Album Promotion Issues 🚫

### **Problem 1: No Validation**
Artists can promote EPs/Albums even with 0 released songs!

### **Problem 2: Fixed Investment**
Current system has fixed costs. User can't set budget or duration.

### **Current System:**
```dart
'ep': {
  'energyCost': 20,
  'moneyCost': 800,
  'baseReach': 25000,
},
```

### **Proposed Redesign:**

#### **Validation:**
```dart
bool canPromoteEP() {
  final releasedCount = songs.where((s) => s.state == SongState.released).length;
  return releasedCount >= 3;
}

bool canPromoteLPAlbum() {
  final releasedCount = songs.where((s) => s.state == SongState.released).length;
  return releasedCount >= 7;
}
```

#### **Custom Investment:**
```dart
// Let user set:
- Investment amount ($100 - $10,000)
- Campaign duration (1-7 days)

// Rewards scale with investment and duration:
baseReach = investmentAmount * 50
dailyReach = baseReach / duration
fansGained = (totalReach * conversionRate * quality/100)
```

#### **Progressive Rewards:**
```dart
// Rewards given daily over campaign duration
for (day in 1..duration) {
  dailyFans = totalFans / duration
  dailyStreams = totalStreams / duration
  
  // Update artist stats each day
  applyDailyRewards()
}
```

### **Files to Modify:**
- `lib/screens/viralwave_screen.dart` - Add validation + custom investment UI
- `lib/models/promotion_campaign.dart` (NEW) - Track active campaigns
- `lib/screens/dashboard_screen_new.dart` - Apply daily campaign rewards

---

## Issue 7: Force NPC Release Admin Function 🤖

### **Problem:**
No way to manually trigger NPC song releases for testing.

### **Proposed Solution:**

#### **Admin Function:**
```javascript
exports.forceNPCRelease = functions.https.onCall(async (data, context) => {
  const { npcId } = data;
  
  // Get NPC
  const npcDoc = await db.collection('npc_artists').doc(npcId).get();
  const npc = npcDoc.data();
  
  // Generate new song
  const newSong = {
    id: `${npc.id}_song_${Date.now()}`,
    title: generateNPCSongTitle(npc.primaryGenre),
    genre: Math.random() > 0.7 ? npc.secondaryGenre : npc.primaryGenre,
    quality: Math.floor(Math.random() * 25) + 65,
    totalStreams: Math.floor(npc.baseStreams * 0.1),
    last7DaysStreams: Math.floor(npc.baseStreams * 0.1),
    releasedDate: admin.firestore.Timestamp.fromDate(new Date()),
    daysOld: 0,
    platforms: ['tunify', 'maple_music'],
  };
  
  // Update NPC
  await npcDoc.ref.update({
    songs: admin.firestore.FieldValue.arrayUnion(newSong),
    lastReleaseDate: admin.firestore.Timestamp.fromDate(new Date()),
  });
  
  return { success: true, song: newSong };
});
```

#### **Admin Dashboard UI:**
```dart
// Add to admin_dashboard_screen.dart
Widget _buildForceNPCReleaseCard() {
  return Column(
    children: [
      Text('Force NPC Release'),
      DropdownButton<String>(
        items: npcList.map((npc) => 
          DropdownMenuItem(value: npc.id, child: Text(npc.name))
        ).toList(),
        onChanged: (npcId) {
          _forceNPCRelease(npcId);
        },
      ),
    ],
  );
}
```

### **Files to Modify:**
- `functions/index.js` - Add forceNPCRelease function
- `lib/services/admin_service.dart` - Add forceNPCRelease() method
- `lib/screens/admin_dashboard_screen.dart` - Add NPC release UI

---

## Issue 8: EchoX Comments Functionality 💬

### **Problem:**
EchoX has no comment/reply system. Players can't have conversations.

### **Proposed System:**

#### **Data Model:**
```dart
class EchoComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime timestamp;
  final int likes;
  final List<String> likedBy;
}
```

#### **Firestore Structure:**
```
echox_posts/{postId}/comments/{commentId}
```

#### **UI Features:**
- Comment icon on each post showing count
- Tap to view comments
- Reply dialog (50 chars max)
- Delete own comments
- Like comments

#### **Game Mechanics:**
- **Post Comment:** -2 energy, +0.5 fame
- **Like Comment:** Free
- **Delete Comment:** Free

### **Files to Create:**
- `lib/models/echo_comment.dart` (NEW)

### **Files to Modify:**
- `lib/screens/echox_screen.dart` - Add comment UI
- `lib/screens/echox_comments_screen.dart` (NEW) - Full comment thread view

---

## Implementation Priority

### **🔴 Critical (Fix ASAP):**
1. ✅ Issue 2: Admin daily update error
2. ✅ Issue 3: Active hustles count
3. ✅ Issue 1: songsWritten counter

### **🟡 High (This Week):**
4. Issue 6: ViralWave validation
5. Issue 5: Fame decay
6. Issue 7: Force NPC release

### **🟢 Medium (Next Week):**
7. Issue 8: EchoX comments
8. Issue 4: Monthly listeners docs

---

## Testing Checklist

### **After Fixes:**
- [ ] Create song → check songsWritten doesn't increment
- [ ] Release song → check songsWritten increments
- [ ] Admin trigger daily update → no errors
- [ ] Admin dashboard → Active Hustles shows correct count
- [ ] Check fame decays after 7 days idle
- [ ] Try to promote EP with <3 songs → blocked
- [ ] Try to promote Album with <7 songs → blocked
- [ ] Force NPC release → new song appears
- [ ] Post comment on EchoX → shows in thread
- [ ] Delete own comment → removes from thread

---

**Created:** October 17, 2025  
**Status:** Planning Complete - Ready for Implementation
