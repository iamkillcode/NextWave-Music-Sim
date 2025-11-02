# Crew System - Implementation Status & Deployment Guide

**Date**: November 1, 2025  
**Status**: Phases 1-3 Complete, Phase 4 Documented for Future

---

## ✅ Phase 4 Design Documented

**File**: `docs/CREW_PHASE_4_DESIGN.md`

### Key Systems Designed:
1. **Crew Perks System** - Unlock permanent bonuses (Economic, Performance, Creative, Social)
2. **Crew Achievements** - 100+ collectible badges across 6 categories
3. **Crew Customization** - Colors, themes, banners, logos, custom emojis
4. **Crew Events** - Limited-time special modes (Double XP, Mega Challenges, Battle Royale)
5. **Advanced Social** - Feed, announcements, polls, calendar
6. **Reputation System** - Tiered ranking system (Newcomer → Icon)
7. **Crew Alliances** - Temporary partnerships between crews
8. **Crew Broadcasting** - Live streaming crew activities

### Implementation Priority:
- **High**: Perks, Achievements, Reputation (core engagement)
- **Medium**: Events, Social features, Customization
- **Low**: Alliances, Broadcasting (complex/niche)

### Estimated Timeline:
- **15-25 days** for complete Phase 4 implementation

---

## ✅ Collaboration Screen Filters - Status Check

**File**: `lib/screens/collaboration_screen.dart`

### Filter Implementation Review:

#### 1. **Search Filters Available** ✅
```dart
// Active filters:
- Search by name (_searchQuery)
- Genre filter (_selectedGenre) 
- Region filter (_selectedRegion)
- Fame range (_minFame, _maxFame: 0-500)
```

#### 2. **Filter UI Components** ✅
- ✅ Search bar with query input
- ✅ Filter button opens full filter dialog
- ✅ Active filter chips displayed (removable)
- ✅ Genre dropdown (all genres from Genres.all)
- ✅ Region dropdown (usa, europe, asia, africa, latin_america)
- ✅ Fame range slider (0-500 with 50 divisions)
- ✅ "Clear All" button resets filters
- ✅ "Apply Filters" triggers search

#### 3. **Filter Logic Working** ✅
```dart
// _searchPlayers() method correctly passes all filters to service:
await _collabService.searchPlayers(
  query: _searchQuery,
  genre: _selectedGenre,
  region: _selectedRegion,
  minFame: _minFame.toInt(),
  maxFame: _maxFame.toInt(),
);
```

#### 4. **Service Layer Integration** ✅
**File**: `lib/services/collaboration_service.dart`

```dart
// Filters correctly applied in searchPlayers():
- Name matching (case-insensitive)
- Genre matching (exact match if specified)
- Region matching (exact match if specified)
- Fame range (minFame <= fame <= maxFame)
```

### ✅ **Verdict: All Filters Working Correctly**

No issues found. The collaboration screen filters are:
- Properly implemented
- Correctly wired to service layer
- Using appropriate UI components
- Handling state correctly

### Potential Enhancements (Optional):
1. **Multi-genre filter** - Allow selecting multiple genres
2. **Online status filter** - Filter for only online players
3. **Sort options** - Sort by fame, last active, name
4. **Save filter presets** - Remember common filter combinations
5. **Advanced filters** - Filter by number of songs, skill level, etc.

---

## 🔍 Cloud Functions Deployment Analysis

### Existing Functions (from `functions/index.js`):

#### Current Deployed Functions:
1. **Scheduled Functions**:
   - `dailyGameUpdate` - Daily game world progression
   - `triggerDailyUpdate` - Manual daily update trigger

2. **Firestore Triggers**:
   - Various onDocumentWritten triggers for game events

3. **Callable Functions**:
   - Game state management functions
   - Player update functions

### ⚠️ New Cloud Functions Needed for Crew System

Based on Phase 1-3 implementation, the following cloud functions should be added:

---

### 1. **Crew Challenge Auto-Complete Function** 🎯

**Purpose**: Check and end expired challenges, distribute rewards

**Trigger**: Scheduled (runs hourly)

**Function**:
```javascript
// functions/index.js - ADD THIS

/**
 * Crew Challenge Auto-Complete
 * Runs every hour to check for expired challenges
 * Distributes rewards to winning crews
 */
exports.checkExpiredCrewChallenges = onSchedule({
  schedule: 'every 1 hours',
  timeZone: 'America/New_York',
  memory: '512MiB',
}, async (event) => {
  console.log('🎯 Checking expired crew challenges...');
  
  const now = admin.firestore.Timestamp.now();
  const challengesSnapshot = await db.collection('crew_challenges')
    .where('isActive', '==', true)
    .where('endDate', '<', now)
    .get();
  
  let processedCount = 0;
  
  for (const doc of challengesSnapshot.docs) {
    const challenge = doc.data();
    const challengeId = doc.id;
    
    try {
      // Find crew with highest progress
      let maxProgress = 0;
      let winnerId = null;
      
      if (challenge.crewProgress) {
        for (const [crewId, progress] of Object.entries(challenge.crewProgress)) {
          if (progress > maxProgress) {
            maxProgress = progress;
            winnerId = crewId;
          }
        }
      }
      
      if (winnerId && maxProgress > 0) {
        // Award rewards
        await db.collection('crews').doc(winnerId).update({
          sharedBank: admin.firestore.FieldValue.increment(challenge.rewardMoney),
          challengesWon: admin.firestore.FieldValue.increment(1),
        });
        
        // Get crew members and award XP
        const crewDoc = await db.collection('crews').doc(winnerId).get();
        if (crewDoc.exists) {
          const members = crewDoc.data().members || [];
          const batch = db.batch();
          
          for (const member of members) {
            const playerRef = db.collection('players').doc(member.userId);
            batch.update(playerRef, {
              experience: admin.firestore.FieldValue.increment(challenge.rewardXP),
            });
          }
          
          await batch.commit();
        }
        
        // Mark challenge as complete
        await db.collection('crew_challenges').doc(challengeId).update({
          winnerId: winnerId,
          isActive: false,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log(`✅ Challenge ${challengeId} completed. Winner: ${winnerId}`);
      } else {
        // No winner, just deactivate
        await db.collection('crew_challenges').doc(challengeId).update({
          isActive: false,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log(`❌ Challenge ${challengeId} ended with no winner`);
      }
      
      processedCount++;
    } catch (error) {
      console.error(`❌ Error processing challenge ${challengeId}:`, error);
    }
  }
  
  console.log(`✅ Processed ${processedCount} expired challenges`);
  return { processed: processedCount };
});
```

---

### 2. **Crew Song Stream Update Function** 🎵

**Purpose**: Update crew song stream counts and check challenge progress

**Trigger**: onDocumentWritten on `crew_songs` collection

**Function**:
```javascript
// functions/index.js - ADD THIS

/**
 * Crew Song Stream Update
 * Triggered when crew song streams update
 * Updates crew totals and challenge progress
 */
exports.updateCrewSongStreams = onDocumentWritten({
  document: 'crew_songs/{songId}',
  memory: '512MiB',
}, async (event) => {
  const beforeData = event.data?.before?.data();
  const afterData = event.data?.after?.data();
  
  if (!afterData) return; // Document deleted
  
  const crewId = afterData.crewId;
  const songId = event.params.songId;
  
  // Calculate stream increase
  const oldStreams = beforeData?.totalStreams || 0;
  const newStreams = afterData.totalStreams || 0;
  const streamIncrease = newStreams - oldStreams;
  
  if (streamIncrease <= 0) return; // No increase
  
  console.log(`🎵 Crew song ${songId} gained ${streamIncrease} streams`);
  
  try {
    // Update crew totals
    await db.collection('crews').doc(crewId).update({
      totalStreams: admin.firestore.FieldValue.increment(streamIncrease),
    });
    
    // Check active challenges
    const challengesSnapshot = await db.collection('crew_challenges')
      .where('participatingCrews', 'array-contains', crewId)
      .where('isActive', '==', true)
      .where('type', '==', 'streams')
      .get();
    
    for (const challengeDoc of challengesSnapshot.docs) {
      const challenge = challengeDoc.data();
      const currentProgress = challenge.crewProgress?.[crewId] || 0;
      const newProgress = currentProgress + streamIncrease;
      
      await db.collection('crew_challenges').doc(challengeDoc.id).update({
        [`crewProgress.${crewId}`]: newProgress,
      });
      
      // Check if challenge target reached
      if (newProgress >= challenge.targetValue && !challenge.winnerId) {
        console.log(`🏆 Crew ${crewId} completed challenge ${challengeDoc.id}!`);
        // Winner will be set by checkExpiredCrewChallenges
      }
    }
    
    console.log(`✅ Updated crew ${crewId} totals and challenge progress`);
  } catch (error) {
    console.error('❌ Error updating crew song streams:', error);
  }
});
```

---

### 3. **Crew Revenue Update Function** 💰

**Purpose**: Update crew earnings and check revenue challenges

**Trigger**: onDocumentWritten on `crews` collection when totalEarnings changes

**Function**:
```javascript
// functions/index.js - ADD THIS

/**
 * Crew Revenue Update
 * Triggered when crew earnings change
 * Updates challenge progress for revenue challenges
 */
exports.updateCrewRevenue = onDocumentWritten({
  document: 'crews/{crewId}',
  memory: '512MiB',
}, async (event) => {
  const beforeData = event.data?.before?.data();
  const afterData = event.data?.after?.data();
  
  if (!afterData) return; // Document deleted
  
  const crewId = event.params.crewId;
  
  // Calculate revenue increase
  const oldEarnings = beforeData?.totalEarnings || 0;
  const newEarnings = afterData.totalEarnings || 0;
  const earningsIncrease = newEarnings - oldEarnings;
  
  if (earningsIncrease <= 0) return; // No increase
  
  console.log(`💰 Crew ${crewId} earned ${earningsIncrease} more`);
  
  try {
    // Check active revenue challenges
    const challengesSnapshot = await db.collection('crew_challenges')
      .where('participatingCrews', 'array-contains', crewId)
      .where('isActive', '==', true)
      .where('type', '==', 'revenue')
      .get();
    
    for (const challengeDoc of challengesSnapshot.docs) {
      const challenge = challengeDoc.data();
      const currentProgress = challenge.crewProgress?.[crewId] || 0;
      const newProgress = currentProgress + earningsIncrease;
      
      await db.collection('crew_challenges').doc(challengeDoc.id).update({
        [`crewProgress.${crewId}`]: newProgress,
      });
      
      if (newProgress >= challenge.targetValue && !challenge.winnerId) {
        console.log(`🏆 Crew ${crewId} completed revenue challenge ${challengeDoc.id}!`);
      }
    }
    
    console.log(`✅ Updated crew ${crewId} revenue challenge progress`);
  } catch (error) {
    console.error('❌ Error updating crew revenue:', error);
  }
});
```

---

### 4. **Crew Songs Released Counter** 📀

**Purpose**: Update crew song count when songs are released

**Trigger**: onDocumentWritten on `crew_songs` when status changes to 'released'

**Function**:
```javascript
// functions/index.js - ADD THIS

/**
 * Crew Songs Released Counter
 * Triggered when crew song is released
 * Updates crew totals and song challenges
 */
exports.updateCrewSongsReleased = onDocumentWritten({
  document: 'crew_songs/{songId}',
  memory: '512MiB',
}, async (event) => {
  const beforeData = event.data?.before?.data();
  const afterData = event.data?.after?.data();
  
  if (!afterData) return; // Document deleted
  
  const wasReleased = beforeData?.status === 'released';
  const isReleased = afterData.status === 'released';
  
  // Only trigger when song transitions to released
  if (wasReleased || !isReleased) return;
  
  const crewId = afterData.crewId;
  const songId = event.params.songId;
  
  console.log(`📀 Crew song ${songId} released for crew ${crewId}`);
  
  try {
    // Increment crew song count
    await db.collection('crews').doc(crewId).update({
      totalSongsReleased: admin.firestore.FieldValue.increment(1),
    });
    
    // Check active song challenges
    const challengesSnapshot = await db.collection('crew_challenges')
      .where('participatingCrews', 'array-contains', crewId)
      .where('isActive', '==', true)
      .where('type', '==', 'songs')
      .get();
    
    for (const challengeDoc of challengesSnapshot.docs) {
      const challenge = challengeDoc.data();
      const currentProgress = challenge.crewProgress?.[crewId] || 0;
      const newProgress = currentProgress + 1;
      
      await db.collection('crew_challenges').doc(challengeDoc.id).update({
        [`crewProgress.${crewId}`]: newProgress,
      });
      
      if (newProgress >= challenge.targetValue && !challenge.winnerId) {
        console.log(`🏆 Crew ${crewId} completed song challenge ${challengeDoc.id}!`);
      }
    }
    
    console.log(`✅ Updated crew ${crewId} song count and challenge progress`);
  } catch (error) {
    console.error('❌ Error updating crew songs released:', error);
  }
});
```

---

### 5. **Crew Leaderboard Cache Update** (Optional) 📊

**Purpose**: Pre-compute and cache leaderboard data for fast queries

**Trigger**: Scheduled (runs every 15 minutes)

**Function**:
```javascript
// functions/index.js - ADD THIS (OPTIONAL for performance)

/**
 * Crew Leaderboard Cache Update
 * Pre-computes top crews for fast leaderboard queries
 * Runs every 15 minutes
 */
exports.updateCrewLeaderboardCache = onSchedule({
  schedule: 'every 15 minutes',
  timeZone: 'America/New_York',
  memory: '512MiB',
}, async (event) => {
  console.log('📊 Updating crew leaderboard cache...');
  
  try {
    // Get top 100 crews by streams
    const topByStreams = await db.collection('crews')
      .where('status', '==', 'active')
      .orderBy('totalStreams', 'desc')
      .limit(100)
      .get();
    
    // Get top 100 crews by earnings
    const topByEarnings = await db.collection('crews')
      .where('status', '==', 'active')
      .orderBy('totalEarnings', 'desc')
      .limit(100)
      .get();
    
    // Get top 100 crews by songs
    const topBySongs = await db.collection('crews')
      .where('status', '==', 'active')
      .orderBy('totalSongsReleased', 'desc')
      .limit(100)
      .get();
    
    // Store in cache collection
    await db.collection('crew_leaderboard_cache').doc('streams').set({
      crews: topByStreams.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name,
        totalStreams: doc.data().totalStreams,
        members: doc.data().members?.length || 0,
      })),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    await db.collection('crew_leaderboard_cache').doc('earnings').set({
      crews: topByEarnings.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name,
        totalEarnings: doc.data().totalEarnings,
        members: doc.data().members?.length || 0,
      })),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    await db.collection('crew_leaderboard_cache').doc('songs').set({
      crews: topBySongs.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name,
        totalSongsReleased: doc.data().totalSongsReleased,
        members: doc.data().members?.length || 0,
      })),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log('✅ Crew leaderboard cache updated');
  } catch (error) {
    console.error('❌ Error updating leaderboard cache:', error);
  }
});
```

---

## 📋 Deployment Checklist

### Before Deploying:

1. **Update `functions/index.js`**:
   ```bash
   # Add all 5 functions above to functions/index.js
   # After the existing exports
   ```

2. **Update Firestore Indexes**:
   ```bash
   # Add to firestore.indexes.json
   ```
   ```json
   {
     "indexes": [
       {
         "collectionGroup": "crew_challenges",
         "queryScope": "COLLECTION",
         "fields": [
           { "fieldPath": "isActive", "order": "ASCENDING" },
           { "fieldPath": "endDate", "order": "ASCENDING" }
         ]
       },
       {
         "collectionGroup": "crew_challenges",
         "queryScope": "COLLECTION",
         "fields": [
           { "fieldPath": "participatingCrews", "arrayConfig": "CONTAINS" },
           { "fieldPath": "isActive", "order": "ASCENDING" },
           { "fieldPath": "type", "order": "ASCENDING" }
         ]
       },
       {
         "collectionGroup": "crews",
         "queryScope": "COLLECTION",
         "fields": [
           { "fieldPath": "status", "order": "ASCENDING" },
           { "fieldPath": "totalStreams", "order": "DESCENDING" }
         ]
       },
       {
         "collectionGroup": "crews",
         "queryScope": "COLLECTION",
         "fields": [
           { "fieldPath": "status", "order": "ASCENDING" },
           { "fieldPath": "totalEarnings", "order": "DESCENDING" }
         ]
       },
       {
         "collectionGroup": "crews",
         "queryScope": "COLLECTION",
         "fields": [
           { "fieldPath": "status", "order": "ASCENDING" },
           { "fieldPath": "totalSongsReleased", "order": "DESCENDING" }
         ]
       }
     ]
   }
   ```

3. **Deploy Firestore Indexes**:
   ```bash
   cd functions
   firebase deploy --only firestore:indexes
   ```

4. **Deploy Cloud Functions**:
   ```bash
   # Deploy all functions
   firebase deploy --only functions
   
   # Or deploy individually
   firebase deploy --only functions:checkExpiredCrewChallenges
   firebase deploy --only functions:updateCrewSongStreams
   firebase deploy --only functions:updateCrewRevenue
   firebase deploy --only functions:updateCrewSongsReleased
   firebase deploy --only functions:updateCrewLeaderboardCache
   ```

### Deployment Commands:

```bash
# Full deployment (recommended first time)
cd c:\Users\Manuel\Documents\GitHub\NextWave\nextwave
cd functions
npm install  # Ensure dependencies are installed
firebase deploy --only functions,firestore:indexes

# Monitor function logs
firebase functions:log --only checkExpiredCrewChallenges
firebase functions:log --only updateCrewSongStreams
```

---

## 🧪 Testing Cloud Functions

### Test Expired Challenges:
```javascript
// In Firebase Console > Firestore
// Create a test challenge with endDate in the past
// Wait 1 hour or trigger manually:

const functions = require('firebase-functions-test')();
const myFunctions = require('./index');

// Trigger the function
myFunctions.checkExpiredCrewChallenges();
```

### Test Stream Updates:
```javascript
// Update a crew_song document with increased totalStreams
// Function should auto-trigger
```

---

## 📊 Monitoring & Maintenance

### Function Health Checks:
1. **Challenge completion rate**: Should process all expired challenges
2. **Stream update latency**: Should trigger within seconds of stream updates
3. **Revenue tracking accuracy**: All earnings should update challenges
4. **Error rates**: Monitor for any failures

### Expected Function Call Volumes:
- `checkExpiredCrewChallenges`: 24 calls/day (hourly)
- `updateCrewSongStreams`: Variable (depends on game activity)
- `updateCrewRevenue`: Variable (depends on game activity)
- `updateCrewSongsReleased`: Low (only on song releases)
- `updateCrewLeaderboardCache`: 96 calls/day (every 15 min) - OPTIONAL

---

## 💰 Cost Estimates

### Firebase Functions Pricing (per month):
- **Invocations**: Free for first 2M, then $0.40/M
- **Compute time**: Free for first 400,000 GB-seconds
- **Expected cost**: **$0-5/month** for typical usage

### Firestore Operations:
- **Reads**: Challenge queries + leaderboard queries
- **Writes**: Progress updates + crew totals
- **Expected cost**: **$0-10/month** for moderate usage

---

## Summary

### ✅ Completed:
1. **Phase 4 fully documented** for future implementation
2. **Collaboration filters verified working** correctly
3. **5 new cloud functions designed** for crew system

### 🚀 Ready to Deploy:
- Cloud functions code ready to add to `index.js`
- Firestore indexes defined
- Deployment commands provided
- Testing procedures documented

### Next Steps:
1. Add cloud functions to `functions/index.js`
2. Update `firestore.indexes.json`
3. Deploy with `firebase deploy --only functions,firestore:indexes`
4. Monitor function logs for first 24 hours
5. Verify challenge auto-completion working

