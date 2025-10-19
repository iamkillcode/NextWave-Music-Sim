# Regional Charts Testing Guide

## Overview
This guide provides step-by-step instructions to test the new regional chart system and verify it's working correctly.

## Prerequisites
- App running in Chrome (or other device)
- At least one player with released songs
- Weekly Cloud Function has run at least once to generate snapshots

## Test Checklist

### 1. Navigate to Regional Charts
**Steps:**
1. Open the app
2. Navigate to the main dashboard/home screen
3. Look for "Regional Charts" or "Charts" button
4. Tap/Click to open regional charts screen

**Expected Result:**
- Regional charts screen opens successfully
- Shows tabs for: Global, USA, Europe, UK, Asia, Africa, Latin America, Oceania

---

### 2. Test Global Chart
**Steps:**
1. Select the "Global" tab (🌍)
2. Observe the chart rankings

**What to Check:**
- ✅ Chart loads within 1-2 seconds (fast!)
- ✅ Songs are displayed in ranked order (#1, #2, #3, etc.)
- ✅ Stream counts are shown and NOT "0 total"
- ✅ Artist names are displayed
- ✅ Genre tags are shown
- ✅ Chart position medals/badges appear for top 3

**Expected Behavior:**
- Global chart shows songs ranked by **total streams across all regions**
- Stream counts should be large numbers (sum of all regional streams)

---

### 3. Test Regional Charts (USA)
**Steps:**
1. Select the "USA" tab (🇺🇸)
2. Observe the chart rankings

**What to Check:**
- ✅ Chart loads quickly
- ✅ Rankings may be DIFFERENT from Global chart
- ✅ Stream counts shown are USA-specific (likely smaller than global totals)
- ✅ Songs popular in USA should rank higher than globally popular songs with low USA streams

**Expected Behavior:**
- USA chart shows songs ranked by **USA streams only**
- A song with high USA streams but low global streams should rank high on USA chart

---

### 4. Compare Regional Charts
**Steps:**
1. View USA chart, note top 3 songs
2. Switch to Europe tab (🇪🇺), note top 3 songs
3. Switch to UK tab (🇬🇧), note top 3 songs
4. Compare the rankings

**What to Check:**
- ✅ Rankings are DIFFERENT across regions (not identical)
- ✅ Stream counts differ per region
- ✅ Same song may have different positions in different regions

**Example Expected Difference:**
```
Global:  #1 Song A (1M total), #2 Song B (800K total)
USA:     #1 Song B (500K USA),  #2 Song A (300K USA)
Europe:  #1 Song A (600K EUR),  #2 Song C (400K EUR)
```

---

### 5. Test Chart Metadata
**Steps:**
1. Look at individual chart entries
2. Check for additional information

**What to Check:**
- ✅ Chart movement indicators (↑ up, ↓ down, — no change) if available
- ✅ "Weeks on chart" information if displayed
- ✅ Previous position if shown
- ✅ All metadata loads without errors

---

### 6. Test "Your Songs" Section
**Steps:**
1. If you have released songs, check bottom of chart screen
2. Look for "Your Charting Songs" section

**What to Check:**
- ✅ Shows number of your songs on the chart
- ✅ Shows your highest charting song and position
- ✅ Position matches what you see in the main chart

---

### 7. Test Chart Performance
**Steps:**
1. Switch between different region tabs quickly
2. Observe loading times

**What to Check:**
- ✅ Charts load in <1 second (should be very fast)
- ✅ No long loading spinners
- ✅ No timeout errors
- ✅ Smooth tab switching

**Performance Comparison:**
- **Old system**: 3-5 seconds per chart load
- **New system**: 200-500ms per chart load

---

### 8. Test Error Handling
**Steps:**
1. Check console/logs for errors
2. Verify no Firebase query errors

**What to Check:**
- ✅ No console errors related to chart loading
- ✅ No "Collection not found" errors
- ✅ No "Query timeout" errors
- ✅ Graceful handling if no snapshots exist yet

**If Snapshots Don't Exist Yet:**
- Charts may show empty or fall back to real-time queries
- Wait for next weekly Cloud Function run (every 7 hours)
- Or manually trigger `weeklyLeaderboardUpdate` function

---

## Common Issues & Solutions

### Issue: Charts Show "0 total" Streams
**Cause:** Weekly snapshots haven't been generated yet, or old service is still being used

**Solution:**
1. Check Firebase Console → Functions → Logs
2. Verify `weeklyLeaderboardUpdate` has run successfully
3. Check `leaderboard_history` collection for snapshot documents
4. If empty, manually trigger the function or wait for next scheduled run

---

### Issue: All Regional Charts Show Same Rankings
**Cause:** Using old service that queries players in real-time

**Solution:**
1. Verify `LeaderboardSnapshotService` is being used
2. Check that snapshots exist in `leaderboard_history` collection
3. Verify snapshot documents have correct `region` field

---

### Issue: Charts Not Loading / Timeout
**Cause:** Query index missing or snapshot query failing

**Solution:**
1. Check browser console for specific error
2. Verify Firestore indexes are deployed
3. Check network tab for failed requests
4. Verify `leaderboard_history` collection exists

---

### Issue: Chart Loads Slowly
**Cause:** Falling back to real-time queries instead of snapshots

**Solution:**
1. Verify weekly function has created snapshots
2. Check that service is querying `leaderboard_history` not `players`
3. Check console logs for "Using snapshot-based weekly chart" message

---

## Verification Commands

### Check if Snapshots Exist (Firebase Console)
1. Go to Firestore Database
2. Navigate to `leaderboard_history` collection
3. Look for documents like:
   - `songs_global_202542`
   - `songs_usa_202542`
   - `artists_global_202542`

### Check Cloud Function Logs
```bash
firebase functions:log --only weeklyLeaderboardUpdate --limit 50
```

Look for:
- "📊 Creating weekly leaderboard snapshots"
- "✅ Created 8 song chart snapshots"
- "✅ Created 8 artist chart snapshots"

### Manually Trigger Weekly Function (Testing)
```bash
# In Firebase Console → Functions → weeklyLeaderboardUpdate → Testing
# Or use Cloud Functions shell:
firebase functions:shell
> weeklyLeaderboardUpdate()
```

---

## Expected Console Output (Flutter App)

When viewing charts, you should see:
```
📊 Fetching latest global song chart from snapshots
✅ Loaded 10 songs from global snapshot (week 202542)
```

When switching to USA:
```
📊 Fetching latest usa song chart from snapshots
✅ Loaded 10 songs from usa snapshot (week 202542)
```

**NOT** this (old system):
```
📊 Fetching top 10 songs for region: usa
Querying players collection...
```

---

## Success Criteria

The regional charts feature is working correctly if:

- [x] Charts load quickly (<1 second)
- [x] Regional charts show DIFFERENT rankings
- [x] Stream counts are accurate and region-specific
- [x] No "0 total" display bugs
- [x] Chart movement indicators appear (if week > 1)
- [x] Console shows "Using snapshot-based weekly chart" messages
- [x] No timeout or query errors
- [x] All 8 regions (global + 7 regional) display correctly

---

## Next Steps After Testing

### If Tests Pass ✅
1. Mark "Test regional charts in app" as complete in todo list
2. Monitor Cloud Function runs to ensure consistent snapshot generation
3. Consider adding chart history viewer in future update

### If Tests Fail ❌
1. Note which specific test failed
2. Check console/logs for error messages
3. Verify snapshots exist in Firestore
4. Review service code to ensure snapshot queries are being used
5. Report specific error for debugging

---

## Additional Testing Scenarios

### Test with NPC Artists
- Verify NPC artists appear in charts
- Check that NPC songs are ranked correctly
- Confirm `isNPC` flag is set correctly

### Test Chart Movement
- Wait for second weekly run
- Verify movement indicators (↑↓—) appear
- Check that `lastWeekPosition` is accurate
- Confirm new entries are marked appropriately

### Test Edge Cases
- Chart with no songs (empty)
- Region with very few songs
- Artist with songs in only one region
- Song that just entered chart this week

---

**Testing Date**: _______________  
**Tester**: _______________  
**App Version**: _______________  
**Result**: ☐ Pass  ☐ Fail  

**Notes:**
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
