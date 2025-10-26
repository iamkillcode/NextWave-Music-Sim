# Artists Daily Chart - Removed

## Issue
The Artists Daily chart was displaying 0 songs/artists because it relies on the `lastDayStreams` field for each song, which isn't consistently populated during daily updates. This field is primarily used for individual song tracking but not systematically maintained across all songs.

## Root Cause
- **Artists Daily Chart Logic**: Aggregates `lastDayStreams` across all songs per artist
- **Data Availability**: The `lastDayStreams` field is either:
  - Not populated for many songs (defaults to 0)
  - Only tracked for actively charting songs
  - Reset inconsistently during game day transitions

## Solution
Disabled the "Daily" period option specifically for the Artists chart type in the UI:

**Changes made** (`lib/screens/unified_charts_screen.dart`):
1. ✅ Disabled the Daily button segment when Artists chart type is selected
2. ✅ Auto-switch from Daily to Weekly when user selects Artists
3. ✅ Updated info banner to explain that Artists use 7-day aggregation
4. ✅ Visual feedback (greyed out Daily button) when disabled

## User Experience
- **Singles Charts**: Daily and Weekly both work ✅
- **Albums Charts**: Daily and Weekly both work ✅
- **Artists Charts**: Weekly only (Daily is disabled) ✅

When a user selects "Artists" as the chart type:
- The Daily button becomes disabled (greyed out)
- If Daily was selected, it automatically switches to Weekly
- Info banner explains: "Artist rankings based on combined streams from all songs over the last 7 game days"

## Technical Details

### Why Weekly Works
- Uses `last7DaysStreams` field which is:
  - Consistently tracked for all released songs
  - Updated during each weekly chart snapshot
  - Reliable data source for aggregation

### Why Daily Doesn't Work
- Uses `lastDayStreams` field which is:
  - Not consistently populated
  - Primarily for real-time song tracking
  - Results in 0 or near-0 aggregate streams per artist

## Alternative Solution (Not Implemented)
We could systematically populate `lastDayStreams` for all songs during the daily update cycle, but:
- Would require additional Firestore writes (cost concern)
- Weekly aggregation is more meaningful for artist performance
- Daily artist rankings would be too volatile/noisy

## Future Considerations
If daily artist tracking becomes a priority:
1. Add `lastDayStreams` to daily update function for ALL released songs
2. Store artist-level daily aggregate in a separate field
3. Create daily artist snapshots (similar to weekly)

For now, weekly artist charts provide sufficient insight into artist performance trends.
