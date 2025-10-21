# 🚨 CRITICAL BUG: Songs Not Persisting to Firestore

**Date**: October 20, 2025  
**Severity**: CRITICAL - Data Loss  
**Status**: ❌ IDENTIFIED - Needs immediate fix

---

## 🔍 Problem Summary

When users record or release songs:
1. ✅ Money is deducted (transaction completes)
2. ✅ Song state updates locally (in memory)
3. ✅ UI shows success message
4. ❌ **Songs array is NEVER saved to Firestore**
5. ❌ Songs disappear on app refresh/reload

**Result**: Complete data loss for all song creation/recording/release operations.

---

## 🐛 Root Cause

### The Bug Location
**File**: `lib/services/firebase_service.dart`  
**Function**: `updatePlayerStats()`  
**Lines**: ~108-150

### What's Wrong

The `updatePlayerStats()` function sends stats to the `secureStatUpdate` Cloud Function, but **it only includes basic stats and completely omits the `songs` array**:

```dart
Future<void> updatePlayerStats(ArtistStats stats) async {
  if (!isSignedIn) return;

  try {
    final callable = _functions.httpsCallable('secureStatUpdate');
    final result = await callable.call({
      'updates': {
        'currentMoney': stats.money,
        'currentFame': stats.fame,
        'fanbase': stats.fanbase,
        'energy': stats.energy,
        'songwritingSkill': stats.songwritingSkill,
        'lyricsSkill': stats.lyricsSkill,
        'compositionSkill': stats.compositionSkill,
        'experience': stats.experience,
        'inspirationLevel': stats.inspirationLevel,
        // ❌ MISSING: songs array!
        // ❌ MISSING: albums, regional fanbase, loyal fanbase, etc.
      },
      //...
    });
  }
}
```

---

## 📊 Impact Analysis

### Data Loss Scenarios
1. **Writing Songs** → Songs created but lost on refresh
2. **Recording Songs** → Money deducted, song state changes to "recorded", but disappears
3. **Releasing Songs** → Money deducted, song goes "live", then vanishes
4. **Creating Albums** → Album data never persisted

### User Experience
- User creates/records/releases songs
- Success messages appear
- Money is deducted
- User closes app or refreshes
- **All songs gone** ⚠️
- Money still deducted (frustrating!)

---

## 🔧 Solution Required

### Option 1: Update secureStatUpdate to Accept Songs (RECOMMENDED)

Modify the Cloud Function to accept and validate the songs array:

```javascript
// functions/index.js - secureStatUpdate
exports.secureStatUpdate = functions.https.onCall(async (data, context) => {
  const { updates, action, context: actionContext, playerId } = data;
  
  // ... existing validation ...
  
  // Build update object
  const updateData = {
    energy: updates.energy,
    currentMoney: updates.currentMoney,
    currentFame: updates.currentFame,
    fanbase: updates.fanbase,
    // ... other stats ...
    
    // ADD: Songs array with validation
    ...(updates.songs && {
      songs: updates.songs  // Validate structure if needed
    }),
    
    // ADD: Other missing fields
    ...(updates.albums && { albums: updates.albums }),
    ...(updates.loyalFanbase !== undefined && { loyalFanbase: updates.loyalFanbase }),
    ...(updates.regionalFanbase && { regionalFanbase: updates.regionalFanbase }),
    
    lastActivity: admin.firestore.FieldValue.serverTimestamp(),
  };
  
  transaction.update(playerRef, updateData);
  // ...
});
```

Then update `firebase_service.dart` to send the full stats:

```dart
Future<void> updatePlayerStats(ArtistStats stats) async {
  if (!isSignedIn) return;

  try {
    final callable = _functions.httpsCallable('secureStatUpdate');
    final result = await callable.call({
      'updates': {
        // Basic stats
        'currentMoney': stats.money,
        'currentFame': stats.fame,
        'fanbase': stats.fanbase,
        'energy': stats.energy,
        'songwritingSkill': stats.songwritingSkill,
        'lyricsSkill': stats.lyricsSkill,
        'compositionSkill': stats.compositionSkill,
        'experience': stats.experience,
        'inspirationLevel': stats.inspirationLevel,
        
        // ADD: Songs and albums
        'songs': stats.songs.map((s) => s.toJson()).toList(),
        'albums': stats.albums.map((a) => a.toJson()).toList(),
        
        // ADD: Fanbase data
        'loyalFanbase': stats.loyalFanbase,
        'regionalFanbase': stats.regionalFanbase,
      },
      'action': 'stat_update',
      'context': {
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
    //...
  }
}
```

### Option 2: Bypass secureStatUpdate for Song Operations

Create a separate direct Firestore write for song-related operations:

```dart
Future<void> updatePlayerStats(ArtistStats stats) async {
  if (!isSignedIn) return;

  try {
    // 1. Update basic stats through secure Cloud Function
    final callable = _functions.httpsCallable('secureStatUpdate');
    await callable.call({...existing code...});
    
    // 2. Directly update songs/albums (bypass validation)
    await _playersCollection.doc(currentUser!.uid).update({
      'songs': stats.songs.map((s) => s.toJson()).toList(),
      'albums': stats.albums.map((a) => a.toJson()).toList(),
      'loyalFanbase': stats.loyalFanbase,
      'regionalFanbase': stats.regionalFanbase,
    });
  }
}
```

---

## ⚠️ Why This Happened

### Design Flaw
The `secureStatUpdate` function was designed for **anti-cheat validation** of numeric stats (money, fame, skills). It was never designed to handle complex objects like songs and albums.

### Flow Breakdown
1. User records song → Local state updates
2. Dashboard calls `_immediateSave()`
3. `_saveUserProfile()` calls `FirebaseService().updatePlayerStats()`
4. `updatePlayerStats()` sends **only** basic stats to Cloud Function
5. Songs array never included in payload
6. Firestore never receives song data

---

## ✅ Testing After Fix

### Test Scenarios
1. **Write a song** → Refresh → Song still in "Written" tab
2. **Record a song** → Refresh → Song still in "Recorded" tab
3. **Release a song** → Refresh → Song appears in "Released" tab AND streaming platforms
4. **Create an album** → Refresh → Album still exists
5. **Check money** → Deduction persists correctly

### Verification Queries
```javascript
// Check in Firebase Console
db.collection('players').doc(userId).get()
  .then(doc => {
    console.log('Songs:', doc.data().songs);
    console.log('Albums:', doc.data().albums);
  });
```

---

## 🚀 Deployment Priority

**CRITICAL**: This must be deployed IMMEDIATELY as it's causing:
- Complete data loss for core game feature
- Frustration (money deducted but songs gone)
- Progress loss for all players

**Estimated Fix Time**: 30 minutes  
**Testing Time**: 15 minutes  
**Total**: 45 minutes to production

---

## 📝 Prevention Measures

### Going Forward
1. ✅ Include songs/albums in `secureStatUpdate` payload
2. ✅ Add validation for song data structure
3. ✅ Log all save operations with full payload for debugging
4. ✅ Add integration tests for song persistence
5. ✅ Monitor Cloud Function logs for missing data errors

---

**Next Steps**: Implement Option 1 (preferred) and deploy immediately.
