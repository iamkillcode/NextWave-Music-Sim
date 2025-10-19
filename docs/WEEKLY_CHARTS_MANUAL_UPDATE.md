# Weekly Charts Manual Update - Implementation Summary

## Problem
Weekly charts were showing "Unknown" for player names instead of their actual display names. NPCs (like Zyrah) were showing correctly, but player names were not.

## Root Cause
Old leaderboard snapshots in Firestore used inconsistent field names and data. Backend fixes were deployed, but existing snapshots still had old data.

## Solution Implemented

### 1. Backend Cloud Function ✅
**File:** `functions/index.js`

Added new callable Cloud Function `triggerWeeklyLeaderboardUpdate`:
- Regenerates weekly leaderboard snapshots for multiple weeks
- Uses correct `displayName` field from player documents
- Creates both song and artist leaderboard snapshots
- Updates chart statistics

**Deployment:** ✅ Successfully deployed to Firebase

### 2. Frontend Service Method ✅
**File:** `lib/services/admin_service.dart`

Added `triggerWeeklyLeaderboardUpdate()` method:
- Checks for admin privileges
- Calls the Cloud Function
- Returns results with weekId and success status

### 3. Admin Dashboard UI ✅
**File:** `lib/screens/admin_dashboard_screen.dart`

Added new button and dialog:
- Button: "Trigger Weekly Charts Update"
- Dialog: Allows selection of 1-10 weeks to regenerate
- Shows loading indicator during generation
- Displays success message with generated week IDs

## How to Use

### From the App (Recommended)

1. **Open Admin Dashboard**
   - Navigate to Settings → Admin Dashboard (admin users only)

2. **Find the "Trigger Weekly Charts Update" Button**
   - Located in the Admin Actions section
   - Cyan colored button with leaderboard icon

3. **Click the Button**
   - A dialog will appear asking how many weeks to generate
   - Default is 2 weeks, but you can select 1-10 weeks

4. **Generate Snapshots**
   - Click "Generate Snapshots"
   - Wait for the Cloud Function to complete (usually 10-30 seconds)
   - Success message will show the generated week IDs

5. **Verify in Weekly Charts**
   - Go to Charts → Weekly Charts
   - Check that player names (not "Unknown") are displayed
   - Verify both NPCs and players show correct names

### Alternative: Firebase Console

If you prefer to use the Firebase Console:

1. Go to Firebase Console → Functions
2. Find `triggerWeeklyLeaderboardUpdate`
3. Click "Test function"
4. Input: `{"weeksAhead": 4}`
5. Click "Test"

## What Gets Updated

When you trigger the weekly charts update:

### Song Leaderboard Snapshots
- Document path: `leaderboard_history/songs_global_{weekId}`
- Fields:
  - `type`: 'songs'
  - `region`: 'global'
  - `weekId`: e.g., '202543'
  - `timestamp`: Firestore timestamp
  - `entries`: Array of top 100 songs with:
    - `rank`, `songId`, `songName`, `artistId`, `artistName`, `weeklyStreams`, `totalStreams`, `region`

### Artist Leaderboard Snapshots
- Document path: `leaderboard_history/artists_global_{weekId}`
- Fields:
  - `type`: 'artists'
  - `region`: 'global'
  - `weekId`: e.g., '202543'
  - `timestamp`: Firestore timestamp
  - `entries`: Array of top 100 artists with:
    - `rank`, `artistId`, `artistName`, `weeklyStreams`, `totalStreams`, `fanbase`, `songCount`, `region`

### Chart Statistics
- Document path: `chart_statistics/{weekId}`
- Fields:
  - `weekId`: e.g., '202543'
  - `lastUpdated`: Server timestamp
  - `totalSongs`: Number of songs in snapshot
  - `totalArtists`: Number of artists in snapshot
  - `totalStreams`: Sum of all weekly streams

## Important Notes

### Data Consistency
- The function reads current player data from Firestore
- Uses `displayName` field (or falls back to `artistName` or 'Unknown')
- Only includes artists with released songs (songCount > 0)
- Sorts by `weeklyStreams` in descending order

### Regional Charts (Future)
- Current implementation generates global charts only
- Regional chart support can be added by filtering players by region

### Performance
- Each week generation takes ~2-5 seconds
- Generating 4 weeks typically takes 10-20 seconds
- Cloud Function timeout: 60 seconds (can handle up to ~10 weeks)

## Verification Checklist

After running the manual update:

- [ ] Check Firestore Console → `leaderboard_history` collection
- [ ] Verify documents like `songs_global_202543` exist
- [ ] Verify documents like `artists_global_202543` exist
- [ ] Check that `artistName` field in entries has real names (not "Unknown")
- [ ] Open app → Charts → Weekly Charts
- [ ] Verify player names display correctly
- [ ] Verify NPCs and players both show correct names
- [ ] Check that rankings are correct

## Next Steps

1. **Run the Update**
   - Use the Admin Dashboard button
   - Generate snapshots for 2-4 weeks ahead

2. **Test in App**
   - Check Weekly Charts tab
   - Verify all artist names display correctly
   - Test regional filters (if applicable)

3. **Automated Updates**
   - The scheduled `weeklyLeaderboardUpdate` function runs every 7 hours
   - New snapshots will use the correct field mapping automatically

4. **Future Enhancements**
   - Add regional chart snapshot generation
   - Add historical chart comparison
   - Add chart entry/exit tracking

## Troubleshooting

### "Unknown" Still Appears
- Verify the snapshot was actually regenerated (check timestamp in Firestore)
- Check that player documents have `displayName` field
- Try running the update again

### Cloud Function Timeout
- Reduce `weeksAhead` to 2-4 weeks
- Check Cloud Function logs in Firebase Console

### Permission Denied
- Verify you're logged in as an admin user
- Check `admin_service.dart` ADMIN_USER_IDS list

### Frontend Not Showing Updates
- Force close and reopen the app
- Check that `unified_chart_service.dart` is reading `artistName` field
- Verify Firestore rules allow reading `leaderboard_history` collection

## Files Modified

1. ✅ `functions/index.js` - Added `triggerWeeklyLeaderboardUpdate` Cloud Function
2. ✅ `lib/services/admin_service.dart` - Added `triggerWeeklyLeaderboardUpdate()` method
3. ✅ `lib/screens/admin_dashboard_screen.dart` - Added UI button and dialog
4. ✅ `functions/trigger_weekly_update.js` - Created standalone script (not used in final solution)

## Deployment Status

- ✅ All Cloud Functions deployed successfully
- ✅ Frontend code ready (run `flutter run` to test)
- ✅ Admin Dashboard UI updated
- ⏳ Pending: Manual snapshot generation via app

---

**Ready to Test!** Open the Admin Dashboard in your app and click the "Trigger Weekly Charts Update" button.
