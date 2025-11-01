# Beef/Banter System Deployment Guide

## ✅ Implementation Status

### Completed Components
1. **✅ Data Models** (`lib/models/beef.dart`)
   - Beef class with all fields
   - BeefStatus, BeefType, ResponseType enums
   - Fame calculation methods
   - 42-day resolution helpers

2. **✅ Cloud Functions** (`functions/index.js`)
   - `startBeef` - Create beef with diss track
   - `respondToBeef` - Target responds
   - `autoResolveBeefs` - Scheduled daily at 2 AM

3. **✅ Service Layer** (`lib/services/beef_service.dart`)
   - getActiveBeefs() - Stream active beefs
   - getBeefHistory() - Stream resolved beefs
   - startBeef() - Call Cloud Function
   - respondToBeef() - Call Cloud Function
   - hasActiveBeefWith() - Check for existing beef
   - getBeefStats() - Win/loss/draw stats

4. **✅ UI Screen** (`lib/screens/banter_screen.dart`)
   - Active beefs tab with countdown timers
   - Beef history tab with outcomes
   - Fame gain display
   - Respond to beef dialog

5. **✅ Media Hub Integration** (`lib/screens/media_hub_screen.dart`)
   - Banter app added to Misc section
   - Red/orange fire gradient icon

6. **✅ Security Rules** (`firestore.rules`)
   - Beefs collection: Read for participants, write only by Cloud Functions
   - Prevents client-side fame manipulation

7. **✅ Firestore Indexes** (`firestore.indexes.json`)
   - (status, lastActivityAt) - For auto-resolve
   - (instigatorId, startedAt) - User's beefs
   - (targetId, startedAt) - Beefs targeting user
   - (status, instigatorId, startedAt) - Active beefs
   - (status, targetId, startedAt) - Active target beefs
   - (status, resolvedAt) - History queries

### Pending Implementation
⏳ **Studio Integration** - Add "Write Diss Track" option (requires finding song creation screen)

## 🚀 Deployment Steps

### 1. Deploy Cloud Functions
```powershell
cd c:\Users\Manuel\Documents\GitHub\NextWave\nextwave
firebase deploy --only functions:startBeef,functions:respondToBeef,functions:autoResolveBeefs
```

### 2. Deploy Firestore Rules
```powershell
firebase deploy --only firestore:rules
```

### 3. Deploy Firestore Indexes
```powershell
firebase deploy --only firestore:indexes
```

This will create 8 composite indexes for the beefs collection. Index creation can take 5-30 minutes depending on existing data.

### 4. Verify Deployment
```powershell
# Check functions
firebase functions:list

# Should see:
# - startBeef (callable)
# - respondToBeef (callable)
# - autoResolveBeefs (scheduled, 0 2 * * *)
```

### 5. Test the System

#### Test 1: Start a Beef
1. Open app in Chrome
2. Go to Media Hub → Banter
3. Create a diss track song (in Studio or elsewhere)
4. Use Cloud Function directly via Firestore Console or wait for Studio integration

#### Test 2: Respond to Beef
1. Sign in as target player
2. Go to Media Hub → Banter
3. Click on active beef
4. Click "Respond with Diss Track"
5. Select response track

#### Test 3: Auto-Resolution
1. Create test beef
2. Set `lastActivityAt` timestamp to 85 hours ago (manually in Firestore)
3. Wait for 2 AM or manually trigger scheduled function
4. Verify beef resolves with correct winner/fame

## 📊 Monitoring

### Cloud Function Logs
```powershell
firebase functions:log --only autoResolveBeefs
```

Check for:
- Number of beefs resolved each run
- Any errors in winner calculation
- Fame award confirmations

### Firestore Queries

**Check Active Beefs:**
```javascript
db.collection('beefs')
  .where('status', '==', 'active')
  .get()
```

**Check Recent Resolutions:**
```javascript
db.collection('beefs')
  .where('status', '==', 'resolved')
  .orderBy('resolvedAt', 'desc')
  .limit(10)
  .get()
```

## 🐛 Troubleshooting

### Issue: Function Not Found
**Error:** `Function startBeef not found`
**Solution:** Deploy functions again, ensure no syntax errors in index.js

### Issue: Permission Denied Reading Beefs
**Error:** `Missing or insufficient permissions`
**Solution:** 
- Check user is authenticated
- Verify user is instigatorId or targetId in beef document
- Redeploy firestore rules

### Issue: Index Not Found
**Error:** `The query requires an index`
**Solution:**
- Click the link in error message to auto-create index
- Or deploy firestore indexes again
- Wait for indexes to build (check Firebase Console)

### Issue: Auto-Resolve Not Running
**Symptoms:** Beefs past 84 hours still active
**Solution:**
- Check Cloud Scheduler in Google Cloud Console
- Verify timezone (schedule is UTC: '0 2 * * *' = 2 AM UTC)
- Check function logs for errors
- Manually trigger: `firebase functions:shell` → `autoResolveBeefs({})`

## 🔧 Configuration

### Adjust Resolution Period
Currently: 42 in-game days = 84 real hours

To change, update:
1. `functions/index.js` line ~7105:
   ```javascript
   const resolutionPeriodMs = 42 * 2 * 60 * 60 * 1000; // Change 42
   ```

2. `lib/models/beef.dart` line ~215:
   ```dart
   const resolutionPeriod = Duration(hours: 84); // Change 84
   ```

### Adjust Fame Multipliers
Edit `functions/index.js` line ~7000 in `calculateBeefWinner()`:
```javascript
// No response fame
return { instigatorFameGain: 25 }; // Change 25

// Knockout multiplier
return { instigatorFameGain: Math.floor(150 * multiplier) }; // Change 150

// Draw fame
return { instigatorFameGain: 60, targetFameGain: 60 }; // Change 60
```

### Adjust Knockout Threshold
Currently: 3x stream difference

Change in `functions/index.js` line ~7040:
```javascript
if (instigatorStreams / targetStreams >= 3.0) { // Change 3.0
```

## 📱 Future Enhancements

### Studio Integration (Priority)
- Find song creation/writing screen
- Add "Write Diss Track" checkbox
- Add target player selector
- Call `startBeef` Cloud Function on song creation
- Mark song with `isDissTrack: true, beefId: beefId`

### Gameplay Enhancements
- **Beef Notifications**: Push notifications when called out or beef resolves
- **Public Beef Feed**: Show trending beefs on EchoX or News
- **Beef Challenges**: Allow any player to challenge for beef
- **Beef Stats Screen**: Dedicated leaderboard for beef wins
- **Multiple Rounds**: Allow 2nd diss track to escalate beef
- **Collaboration Beefs**: Team beefs (2v2)
- **Label Beefs**: Entire label vs label feuds

### Analytics
- Track most successful beef artists
- Track average streams per beef
- Track fame gained from beefs vs regular songs
- Identify "beef meta" strategies

## 📋 Checklist Before Going Live

- [ ] All Cloud Functions deployed and showing in `firebase functions:list`
- [ ] Firestore rules deployed and tested
- [ ] All 8 indexes created and status = "Ready"
- [ ] Test beef creation as two different players
- [ ] Test beef response flow
- [ ] Test auto-resolution by manipulating timestamp
- [ ] Verify fame calculations match design doc
- [ ] Test knockout detection with 3x streams
- [ ] Verify notifications sent correctly
- [ ] Check Gandalf news posts appear
- [ ] Mobile UI tested (responsive design)
- [ ] Error handling tested (invalid inputs, missing players)
- [ ] Studio integration completed (or documented as future work)

## 🎯 Success Metrics

Track these metrics after launch:
- Total beefs started per day
- % of beefs that get responses
- Average time to response
- Knockout vs regular resolution ratio
- Average fame gained per beef
- User retention impact (do beef participants play more?)
- Most common beef initiators (top 10 artists)

## 📞 Support

If issues arise:
1. Check Firebase Console → Functions logs
2. Check Firebase Console → Firestore → beefs collection
3. Review `BEEF_RESOLUTION_MECHANICS.md` for game rules
4. Check Discord/community for player reports

## 🎉 Launch Announcement Template

```
🔥 NEW FEATURE: BANTER (Beef System) 🔥

Start rivalries with other artists by dropping DISS TRACKS!

How it works:
✅ Write a diss track targeting another artist
✅ If they respond, battle for 42 in-game days
✅ Winner determined by streams, engagement, and quality
✅ High fame multipliers if you beef UP (target higher fame artists)
✅ Knockout possible with 3x stream difference!

Fame Rewards:
• Win vs higher fame: +150-300 fame
• Win vs equal fame: +75 fame  
• Draw: +60 fame both
• Knockout: +150-450 fame!
• No response: +25 fame (but less respect)

Find it in: Media Hub → Misc → 🔥 Banter

Start your first beef today! 🎤💥
```
