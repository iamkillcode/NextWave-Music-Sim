# Chart Issues - Resolution Status

## Problem Identified ✅

**Issue 1: Weekly Charts Empty**
- **Cause**: Missing Firestore composite index for `leaderboard_history` collection
- **Error**: `[cloud_firestore/failed-precondition] The query requires an index`
- **Status**: ✅ **FIXED** - Index deployed and building

**Issue 2: "0 total" Display**
- **Cause**: Weekly charts failed to load snapshots and returned empty arrays
- **Status**: ✅ **FIXED** - Added fallback to real-time queries

---

## Solutions Implemented

### 1. Firestore Index (Deployed)
Added composite index to `firestore.indexes.json`:
```json
{
  "collectionGroup": "leaderboard_history",
  "fields": [
    { "fieldPath": "region", "order": "ASCENDING" },
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
}
```

**Status**: Deployed via `firebase deploy --only firestore:indexes`  
**Build Time**: 5-10 minutes (indexes build in background)

### 2. Graceful Fallback
Updated chart services to:
- Try snapshot-based queries first
- Fall back to real-time queries if snapshots unavailable
- Show helpful messages in console when indexes are building

### 3. Better Error Messages
Console now shows:
```
⚠️ Firestore index is still building. Charts will be available once index is ready.
   This usually takes 5-10 minutes after deployment.
   Chart will fall back to daily/real-time data in the meantime.
```

---

## Current Status

### What's Working Now ✅
- **Daily Charts**: Working perfectly (using real-time queries)
  - Daily Singles Global: ✅ 6 songs
  - Daily Singles USA: ✅ 4 songs
  - Daily Artists: ✅ 4 artists

- **Weekly Charts**: Using fallback (real-time data)
  - Will switch to snapshots automatically once indexes finish building
  - Shows same data as daily charts for now

### What's Building ⏳
- **Firestore Indexes**: 5-10 minutes (started at deployment time)
- **Weekly Snapshots**: Will be created by next Cloud Function run (every 7 hours)

---

## Next Steps

### Immediate (Next 10 Minutes)
1. **Wait for indexes to build** (~5-10 min from deployment)
2. **Hot reload app** (press 'R' in Flutter terminal)
3. **Check browser console** for success messages:
   ```
   ✅ Loaded X songs from global snapshot (week 202542)
   ```

### Short Term (Next 7 Hours)
1. **Manually trigger** `weeklyLeaderboardUpdate` function OR
2. **Wait for automatic run** (scheduled every 7 hours)
3. Snapshots will be created in `leaderboard_history` collection
4. Weekly charts will show snapshot-based regional rankings

---

## How to Test Right Now

### Option 1: Use Daily Charts (Working Now)
1. In the app, select **"Daily"** instead of "Weekly"
2. Daily charts work perfectly and show accurate data
3. Stream counts are correct (no "0 total")

### Option 2: Wait for Indexes (5-10 min)
1. Wait ~10 minutes for Firestore indexes to finish building
2. Hot reload the app (press 'R' in terminal)
3. Weekly charts will load from real-time queries (fallback)
4. No more "0 total" errors

### Option 3: Trigger Function Manually
1. Go to [Firebase Console → Functions](https://console.firebase.google.com/project/nextwave-music-sim/functions)
2. Find `weeklyLeaderboardUpdate` function
3. Click "..." → "Test function"
4. Run it to create snapshots immediately
5. Refresh charts in app

---

## Verification Commands

### Check if Indexes are Ready
```bash
# In Firebase Console
https://console.firebase.google.com/project/nextwave-music-sim/firestore/indexes
```

Look for:
- `leaderboard_history` index
- Status: "Enabled" (ready) or "Building" (still processing)

### Check if Snapshots Exist
```bash
# In Firebase Console → Firestore Database
leaderboard_history/
  - songs_global_202542 (should exist after function runs)
  - songs_usa_202542
  - artists_global_202542
  etc.
```

### View Function Logs
```bash
firebase functions:log --only weeklyLeaderboardUpdate --limit 20
```

Look for:
- "📊 Creating weekly leaderboard snapshots"
- "✅ Created 8 song chart snapshots"

---

## Expected Timeline

| Time | Event | Status |
|------|-------|--------|
| T+0 min | Index deployment | ✅ Complete |
| T+0 min | Code changes deployed | ✅ Complete |
| T+5-10 min | Indexes finish building | ⏳ In Progress |
| T+10 min | Weekly charts use fallback | ✅ Working |
| Next 7-hour mark | Function creates snapshots | ⏳ Waiting |
| After snapshots | Regional rankings accurate | ⏳ Pending |

---

## What You Should See Now

### Browser Console (Current)
```
📊 Fetching weekly singles chart for global
✅ Using snapshot-based weekly chart for accurate regional rankings
📊 Fetching latest global song chart from snapshots
⚠️ Firestore index is still building. Charts will be available once index is ready.
   This usually takes 5-10 minutes after deployment.
   Chart will fall back to daily/real-time data in the meantime.
📊 Fetching daily singles chart for global
✅ Found 6 songs on daily singles global chart (2 NPCs)
```

### Browser Console (After Indexes Build)
```
📊 Fetching weekly singles chart for global
✅ Using snapshot-based weekly chart for accurate regional rankings
📊 Fetching latest global song chart from snapshots
⚠️ No chart snapshots found for global
⚠️ No snapshot data available, falling back to real-time query
📊 Fetching daily singles chart for global
✅ Found 6 songs on daily singles global chart (2 NPCs)
```

### Browser Console (After Function Runs)
```
📊 Fetching weekly singles chart for global
✅ Using snapshot-based weekly chart for accurate regional rankings
📊 Fetching latest global song chart from snapshots
✅ Loaded 10 songs from global snapshot (week 202542)
```

---

## Troubleshooting

### If Daily Charts Still Show "0 total"
- This shouldn't happen anymore with fallback
- Check browser console for errors
- Verify songs exist in Firebase with `regionalStreams` field

### If Weekly Charts Stay Empty After 10 Minutes
1. Check that indexes show "Enabled" in Firebase Console
2. Manually trigger `weeklyLeaderboardUpdate` function
3. Verify `leaderboard_history` collection exists

### If Regional Rankings Still Look Wrong
- This is expected until snapshots are created
- Fallback uses real-time queries (same as old system)
- Regional accuracy requires snapshots from Cloud Function

---

## Summary

✅ **Root causes identified and fixed**  
✅ **Indexes deployed (building in background)**  
✅ **Fallback implemented (charts work now)**  
⏳ **Waiting for indexes to finish (~5-10 min)**  
⏳ **Waiting for snapshots to be created (next function run)**

**Action Required**: 
1. Wait 10 minutes for indexes
2. Hot reload app (press 'R')
3. Charts should work with real-time data
4. Regional accuracy comes after function creates snapshots

---

**Updated**: Just now  
**Status**: ✅ Fixes deployed, waiting for infrastructure  
**ETA**: Charts working in 10 minutes, regional accuracy in <7 hours
