# Weekly Charts Fix

**Date:** October 19, 2025
**Issue:** Weekly charts showing "Unknown Artist", 0 songs, 0 fans, and 0 streams

## Root Causes

### 1. Backend Field Mismatches
- **Problem:** Backend was using `playerData.artistName` but frontend expects `playerData.displayName`
- **Problem:** Backend was using `playerData.level` for fanbase instead of `playerData.fanbase`
- **Problem:** Backend wrote `rank` but frontend expected `position`
- **Problem:** Backend wrote `weeklyStreams` but frontend expected `streams`

### 2. Missing Data in Snapshots
- **Problem:** Backend didn't include `songCount` in artist snapshots
- **Problem:** Backend didn't include `fanbase` in artist snapshots
- **Problem:** Backend didn't include `songId` in song snapshots

### 3. Frontend Field Name Inconsistencies
- **Problem:** Frontend used different field names for snapshot vs real-time data
- **Problem:** No backward compatibility for field name changes

## Fixes Applied

### Backend (`functions/index.js`)

#### Artist Aggregation (Line ~930)
- ✅ Changed `playerData.artistName` → `playerData.displayName`
- ✅ Changed `playerData.level` → `playerData.fanbase`
- ✅ Added validation: Skip artists with 0 released songs
- ✅ Added `songCount` field to track number of released songs

#### Snapshot Field Mapping (Lines ~1000-1050)
- ✅ Added `position: index + 1` (frontend expects this)
- ✅ Added `streams: artist.weeklyStreams` (frontend expects this)
- ✅ Added `songCount: artist.songCount` (frontend expects this)
- ✅ Kept `rank`, `weeklyStreams` for backward compatibility

#### Song Snapshots (Lines ~860-920)
- ✅ Changed `playerData.artistName` → `playerData.displayName`
- ✅ Added `position: index + 1`
- ✅ Added `artist: song.artistName` (frontend alias)
- ✅ Added `songId: song.id || ''`

### Frontend

#### `unified_chart_service.dart` (Line ~315-340)
- ✅ Updated snapshot transformation to use `streams` directly
- ✅ Added `fanbase: entry['fanbase'] ?? 0` (now stored in snapshots)
- ✅ Added backward compatibility: both `streams` and `periodStreams`
- ✅ Added backward compatibility: both `songCount` and `releasedSongs`

#### `unified_charts_screen.dart` (Line ~690-705)
- ✅ Updated artist subtitle to accept both `songCount` and `releasedSongs`
- ✅ Updated stream display to accept both `streams` and `periodStreams`
- ✅ Ensures charts display correctly regardless of data source

## Data Model Changes

### Before
```javascript
// Backend snapshot
{
  rank: 1,
  artistName: playerData.artistName || 'Unknown',
  weeklyStreams: 12345,
  fanbase: playerData.level || 0,
  // songCount missing
}
```

### After
```javascript
// Backend snapshot
{
  position: 1,              // NEW: Frontend expects this
  rank: 1,                  // Kept for compatibility
  artistName: playerData.displayName || 'Unknown',  // CHANGED
  streams: 12345,           // NEW: Frontend expects this
  weeklyStreams: 12345,     // Kept for compatibility
  songCount: 5,             // NEW: Number of released songs
  fanbase: playerData.fanbase || 0,  // CHANGED: Was using level
  totalStreams: 67890,
  isNPC: false,
}
```

## Testing Steps

1. **Deploy Updated Functions:**
   ```bash
   cd nextwave/functions
   npm run deploy
   ```

2. **Trigger Weekly Leaderboard Update:**
   - Use Firebase console or callable function to trigger `weeklyLeaderboardUpdate`
   - This regenerates snapshots with correct field names and data

3. **Verify Weekly Singles Chart:**
   - Check that artist names are displayed (not "Unknown Artist")
   - Check that weekly streams are displayed correctly
   - Check that regional charts work

4. **Verify Weekly Artists Chart:**
   - Check that artist names are displayed
   - Check that song count is displayed (not 0)
   - Check that fan count is displayed (not 0)
   - Check that weekly streams are displayed (not 0)

5. **Verify Regional Charts:**
   - Switch to different regions
   - Ensure regional streams are calculated correctly
   - Ensure artists/songs with 0 regional streams are excluded

## Migration Notes

- ✅ All field changes include backward compatibility
- ✅ Old snapshots will still work (fallback to old field names)
- ✅ New snapshots use new field names
- ✅ No database migration required
- ✅ Charts will automatically update after next weekly snapshot

## Related Issues

- "Unknown Artist" in charts → Fixed by using `displayName`
- "0 songs, 0 fans" → Fixed by using `fanbase` and adding `songCount`
- "0 streams (weekly)" → Fixed by mapping `weeklyStreams` to `streams`
- Regional charts not working → Fixed by ensuring `regionalStreams` calculation

## Status

- ✅ Backend fixes applied
- ✅ Frontend fixes applied
- 🔄 Cloud Functions deployment in progress
- ⏳ Waiting for weekly snapshot regeneration
- ⏳ Testing required after deployment
