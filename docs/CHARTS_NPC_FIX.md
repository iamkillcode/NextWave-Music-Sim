# Charts System - NPC Integration Fix

## Problem
Singles, albums, and artists weren't appearing on charts. NPCs weren't showing up on charts despite having songs and stream data.

## Root Cause
The `UnifiedChartService` was **only querying the `players` collection** and completely ignoring the `npcs` collection. This meant:
- NPC songs never appeared on singles/albums charts
- NPC artists never appeared on artist charts
- Charts appeared empty or only showed player content

## Solution Implemented

### 1. **Updated `getSongsChart()` Method**
**File**: `lib/services/unified_chart_service.dart`

**Changes**:
- Added query to `npcs` collection alongside `players` collection
- Process NPC songs and add them to the chart data
- Added `isNPC: true/false` flag to distinguish NPCs from players
- Handle daily streams for NPCs (use `lastDayStreams` or estimate from `last7DaysStreams / 7`)
- Maintain all existing filtering (period, type, region)

**Code Flow**:
```dart
// Fetch BOTH collections
final playersSnapshot = await _firestore.collection('players').get();
final npcsSnapshot = await _firestore.collection('npcs').get();

// Process players (isNPC: false)
for (var doc in playersSnapshot.docs) {
  // Extract songs, add to allSongs with isNPC: false
}

// Process NPCs (isNPC: true)
for (var doc in npcsSnapshot.docs) {
  // Extract songs, add to allSongs with isNPC: true
}

// Sort combined list by streams
allSongs.sort((a, b) => b['periodStreams'] - a['periodStreams']);
```

### 2. **Updated `getArtistsChart()` Method**
**File**: `lib/services/unified_chart_service.dart`

**Changes**:
- Added query to `npcs` collection
- Process NPC artist stats (streams, fanbase, song count)
- Added `isNPC: true/false` flag
- Calculate NPC period streams from their songs
- Sort combined player + NPC list

**NPC Artist Data**:
- `artistName`: From `name` field
- `periodStreams`: Sum of all song streams in period
- `fanbase`: From NPC data
- `fame`: From NPC data
- `releasedSongs`: All NPC songs count as released
- `isNPC`: true

### 3. **Enhanced Logging**
Added debug logs to show NPC count in results:
```
✅ Found 45 songs on weekly singles global chart (12 NPCs)
✅ Found 28 artists on weekly global chart (8 NPCs)
```

## Data Structure Alignment

### Player Songs
```dart
{
  'title': 'Song Title',
  'artist': 'Player Name',
  'state': 'released', // checked
  'lastDayStreams': 5000,
  'last7DaysStreams': 35000,
  'isAlbum': false,
  'regionalStreams': {...}
}
```

### NPC Songs
```dart
{
  'title': 'NPC Song',
  'artist': 'NPC Name',  // from 'name' field
  // No 'state' field - all songs are released
  'lastDayStreams': 3000,
  'last7DaysStreams': 21000,
  'isAlbum': false,
  'regionalStreams': {...}
}
```

## Chart Types Now Working

### Singles Charts ✅
- **Daily Singles (Global)** - All player + NPC singles by lastDayStreams
- **Weekly Singles (Global)** - All player + NPC singles by last7DaysStreams
- **Daily Singles (Regional)** - Filtered by region
- **Weekly Singles (Regional)** - Filtered by region

### Albums Charts ✅
- **Daily Albums (Global)** - All player + NPC albums by lastDayStreams
- **Weekly Albums (Global)** - All player + NPC albums by last7DaysStreams
- **Daily Albums (Regional)** - Filtered by region
- **Weekly Albums (Regional)** - Filtered by region

### Artist Charts ✅
- **Daily Artists (Global)** - All players + NPCs by combined daily song streams
- **Weekly Artists (Global)** - All players + NPCs by combined weekly song streams
- **Daily Artists (Regional)** - Regional stream totals
- **Weekly Artists (Regional)** - Regional stream totals

## Testing Checklist

### Before Testing
1. ✅ Ensure NPCs exist in Firestore (`npcs` collection)
2. ✅ Ensure NPCs have songs with `last7DaysStreams` > 0
3. ✅ Ensure daily update has run (to populate `lastDayStreams`)
4. ✅ Ensure some player songs are released

### Test Steps
1. **Open Charts Screen**
   - Navigate to Charts from dashboard

2. **Test Weekly Singles Chart**
   - Should see mix of player and NPC songs
   - Sorted by `last7DaysStreams` (highest first)
   - Check console: "✅ Found X songs on weekly singles global chart (Y NPCs)"

3. **Test Daily Singles Chart**
   - Switch to "Daily" filter
   - Should see songs with `lastDayStreams` > 0
   - Mix of players and NPCs

4. **Test Albums Charts**
   - Switch to "Albums" type
   - Should see albums from players and NPCs
   - Verify album filtering works

5. **Test Artist Charts**
   - Switch to "Artists" type
   - Should see player and NPC artists ranked by total streams
   - Verify stream totals match song streams

6. **Test Regional Charts**
   - Select a region (e.g., "USA", "Europe")
   - Charts should filter to only regional streams
   - NPCs and players with activity in that region should appear

### Expected Results
- **100+ songs** on global charts (players + NPCs)
- **20+ artists** on artist charts (players + NPCs)
- **NPCs mixed with players** based on stream performance
- **No errors** in console
- **Fast loading** (< 3 seconds for charts)

## Performance Notes

### Query Efficiency
- **2 Firestore queries** per chart load (players + npcs)
- **No indexes required** - simple collection queries
- **Client-side sorting** - all data fetched, then sorted
- **Cached on client** - subsequent loads are instant

### Optimization Opportunities
1. **Server-side chart snapshots** (already implemented in Cloud Functions)
   - `song_leaderboard` snapshot updated hourly
   - `artist_leaderboard` snapshot updated hourly
   - Could query snapshots instead of raw collections

2. **Pagination** - Only fetch top 100, not all songs

3. **Lazy loading** - Load charts on demand, not all at once

## Cloud Function Alignment

The Cloud Functions (`functions/index.js`) already create chart snapshots that include NPCs:

**Song Leaderboard Snapshot** (Line 717-785):
```javascript
// Query BOTH players and NPCs
const playersSnapshot = await db.collection('players').get();
const npcsSnapshot = await db.collection('npcs').get();

// Combine and sort by last7DaysStreams
allSongs.sort((a, b) => b.last7DaysStreams - a.last7DaysStreams);
```

**Artist Leaderboard Snapshot** (Line 789-850):
```javascript
// Query players
const playersSnapshot = await db.collection('players').get();

// Query NPCs
const npcsSnapshot = await db.collection('npcs').get();

// Combine and sort by weekly streams
allArtists.sort((a, b) => b.weeklyStreams - a.weeklyStreams);
```

### Future Enhancement
Instead of querying raw collections, query the snapshots:
```dart
// Instead of:
final playersSnapshot = await _firestore.collection('players').get();
final npcsSnapshot = await _firestore.collection('npcs').get();

// Use:
final snapshotDoc = await _firestore
  .collection('game_state')
  .doc('song_leaderboard')
  .get();
final rankings = snapshotDoc.data()['rankings'];
```

**Benefits**:
- 1 query instead of 2
- Pre-sorted server-side
- Faster load times
- Lower Firestore read costs

## Summary

✅ **Fixed**: Charts now include NPCs alongside players
✅ **Working**: All chart types (singles, albums, artists)
✅ **Working**: All filters (daily/weekly, global/regional)
✅ **Performance**: Acceptable for current scale
⏳ **Future**: Can optimize with server-side snapshots

## Files Modified

1. **lib/services/unified_chart_service.dart**
   - `getSongsChart()` - Added NPC query and processing
   - `getArtistsChart()` - Added NPC query and processing
   - Added `isNPC` field to distinguish NPCs from players

## Related Documentation

- `docs/NPC_GLOBAL_SUMMARY.md` - NPC system overview
- `docs/features/LAST_7_DAYS_STREAMS_COMPLETE.md` - Stream tracking system
- `functions/index.js` lines 717-850 - Server-side chart generation
