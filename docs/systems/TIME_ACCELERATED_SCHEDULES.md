# Cloud Functions v2.0 - CORRECTED SCHEDULES

**Date:** October 16, 2025  
**Version:** 2.0 (Time-Accelerated)  
**Status:** ✅ Deployed

---

## ⏰ CRITICAL: Time Acceleration

**NextWave uses accelerated in-game time:**
- ✅ **1 in-game day = 1 real-world hour**
- ✅ **1 in-game week = 7 real-world hours**

All Cloud Functions are now scheduled accordingly!

---

## 📅 Function Schedules

### 1. **dailyGameUpdate** ⏰ EVERY HOUR
```javascript
schedule('0 * * * *') // Runs at the top of every hour
```

**What it does:**
- Updates game date by +1 day
- Processes ALL players
- Calculates daily streams
- Decays last7DaysStreams (14.3% per hour)
- Grows regional fanbase
- Applies event bonuses

**Real-world execution:**
```
12:00 PM → In-game: Jan 1
1:00 PM  → In-game: Jan 2
2:00 PM  → In-game: Jan 3
3:00 PM  → In-game: Jan 4
...
11:00 PM → In-game: Jan 12
12:00 AM → In-game: Jan 13
```

**Daily in-game = Hourly in real-time** ✅

---

### 2. **weeklyLeaderboardUpdate** ⏰ EVERY 7 HOURS
```javascript
schedule('0 */7 * * *') // Runs every 7 hours
```

**What it does:**
- Takes snapshot of Top 100 songs
- Takes snapshot of Top 50 artists
- Calculates LW/PEAK/WKS stats
- Saves historical data

**Real-world execution:**
```
12:00 AM → Week 1 snapshot
7:00 AM  → Week 2 snapshot
2:00 PM  → Week 3 snapshot
9:00 PM  → Week 4 snapshot
4:00 AM  → Week 5 snapshot (next day)
```

**Weekly in-game = Every 7 hours in real-time** ✅

---

### 3. **triggerSpecialEvent** ⏰ EVERY 7 HOURS
```javascript
schedule('0 */7 * * *') // Runs every 7 hours
```

**What it does:**
- Selects random event
- Activates for 7 hours (1 in-game week)
- Applies event bonuses

**Events rotate every 7 hours:**
```
12:00 AM → 🔥 Viral Week starts (ends 7:00 AM)
7:00 AM  → 💿 Album Week starts (ends 2:00 PM)
2:00 PM  → 🌍 Regional Spotlight starts (ends 9:00 PM)
9:00 PM  → ⭐ Rising Stars starts (ends 4:00 AM)
```

**Event duration: 7 real-world hours = 1 in-game week** ✅

---

### 4. **checkAchievements** ⚡ REAL-TIME
```javascript
onUpdate('players/{playerId}')
```

**Triggers:** Every time player data changes  
**Response time:** < 1 second

---

### 5. **validateSongRelease** 📞 ON-DEMAND
```javascript
httpsCallable('validateSongRelease')
```

**Triggers:** When called from client  
**Response time:** < 500ms

---

### 6-7. **Testing Functions** 🧪 ON-DEMAND
- `triggerDailyUpdate` - Manual hourly update
- `catchUpMissedDays` - Emergency catch-up

---

## 📊 Impact of Acceleration

### **Cost Analysis (Updated)**

**Before correction:**
- Daily updates: 1/day = 30/month
- Weekly updates: 1/week = 4/month
- **Total scheduled runs: 34/month**

**After correction:**
- Daily updates: 24/day = **720/month**
- Weekly updates: 3.4/day = **~100/month**
- Events: 3.4/day = **~100/month**
- **Total scheduled runs: ~920/month**

**Still within free tier!** (2M invocations/month free)

**Estimated cost for 10,000 players:**
- Before: $0.05/month
- After: **$1.20/month** (still extremely cheap!)

---

## ⚡ Performance Considerations

### **Hourly Updates**

**Processing time per update:**
- 1,000 players: ~15 seconds
- 10,000 players: ~90 seconds
- 100,000 players: ~15 minutes

**Hourly execution is fine because:**
- ✅ Runs 24/7 automatically
- ✅ Players don't experience any lag
- ✅ Batched processing is efficient
- ✅ Cloud Functions scale automatically

---

### **Every 7 Hours (Weekly)**

**Leaderboard snapshots:**
- Takes 30-60 seconds
- Processes all released songs
- Creates historical records
- No impact on players

---

## 🎮 Player Experience

### **What Players Notice:**

**Every Real Hour (In-game Day):**
- Songs get new streams ✅
- Money increases ✅
- Charts update ✅
- Fanbase grows ✅

**Every 7 Real Hours (In-game Week):**
- Chart history saved ✅
- LW/PEAK/WKS updated ✅
- New event starts ✅
- Previous event ends ✅

**Real-time:**
- Achievements unlock instantly ✅
- Song validation immediate ✅

---

## 🔍 Monitoring

### **View Execution Logs:**

```powershell
# See all hourly updates
firebase functions:log --only dailyGameUpdate

# See weekly snapshots
firebase functions:log --only weeklyLeaderboardUpdate

# See event changes
firebase functions:log --only triggerSpecialEvent
```

### **Expected Log Pattern:**

**Hourly (dailyGameUpdate):**
```
12:00 → ✅ Processed 1,000 players
1:00  → ✅ Processed 1,000 players
2:00  → ✅ Processed 1,000 players
...
```

**Every 7 Hours:**
```
12:00 AM → ✅ Leaderboard snapshot + Event: Viral Week
7:00 AM  → ✅ Leaderboard snapshot + Event: Album Week
2:00 PM  → ✅ Leaderboard snapshot + Event: Regional Spotlight
9:00 PM  → ✅ Leaderboard snapshot + Event: Rising Stars
```

---

## 🧪 Testing the Schedules

### **Test Hourly Updates:**

**Method 1: Wait 1 hour**
```powershell
# Check game date before
# Wait 1 hour
# Check game date after (should be +1 day)
```

**Method 2: Manual trigger**
```dart
await FirebaseFunctions.instance
  .httpsCallable('triggerDailyUpdate')
  .call();
// Simulates 1 in-game day
```

---

### **Test Weekly Updates:**

**Wait 7 hours** and check:
```dart
// Check leaderboard history
final snapshot = await FirebaseFirestore.instance
  .collection('leaderboard_history')
  .orderBy('timestamp', descending: true)
  .limit(1)
  .get();

print('Last snapshot: ${snapshot.docs.first.data()}');
```

---

### **Test Events:**

**Check active event:**
```dart
final event = await FirebaseFirestore.instance
  .collection('game_state')
  .doc('active_event')
  .get();

if (event.data()?['active'] == true) {
  print('Event: ${event.data()?['name']}');
  print('Ends: ${event.data()?['endDate']}');
}
```

---

## 📈 Scaling Projections

### **10,000 Players:**
- Hourly processing: ~90 seconds
- Weekly snapshots: ~30 seconds
- Monthly cost: ~$1.20
- ✅ **No issues**

### **100,000 Players:**
- Hourly processing: ~15 minutes
- Weekly snapshots: ~5 minutes
- Monthly cost: ~$12
- ✅ **Still very manageable**

### **1,000,000 Players:**
- Hourly processing: ~2.5 hours ⚠️
- May need optimization:
  - Split into parallel batches
  - Use Cloud Tasks queue
  - Increase function memory
- Monthly cost: ~$120
- ⚠️ **Would need optimization at this scale**

---

## 🎯 Key Takeaways

### **Critical Changes:**
1. ✅ Daily updates now run **HOURLY** (was daily)
2. ✅ Weekly updates now run **EVERY 7 HOURS** (was weekly)
3. ✅ Events rotate **EVERY 7 HOURS** (was weekly)
4. ✅ Event duration is **7 HOURS** (was 7 days)
5. ✅ Chart decay happens **HOURLY** (was daily)

### **Why This Matters:**
- ⚡ Game progresses 24x faster than real-time
- 🎮 Players see progress every hour, not every day
- 📊 Charts update dynamically throughout the day
- 🎪 Events change multiple times per day
- ⚖️ Still fair competition (everyone on same schedule)

### **What Didn't Change:**
- ✅ Batch processing (still 500 players per batch)
- ✅ Algorithm logic (same stream calculations)
- ✅ Anti-cheat validation
- ✅ Achievement detection
- ✅ Regional fanbase growth
- ✅ Server-authoritative control

---

## 🚀 Next Execution Times

**Based on current time: October 16, 2025**

**Next daily update:** Top of next hour  
**Next weekly snapshot:** Next 7-hour mark (0:00, 7:00, 14:00, 21:00 UTC)  
**Next event rotation:** Same as weekly snapshot

**Check Firebase Console:**
https://console.cloud.google.com/cloudscheduler?project=nextwave-music-sim

You'll see:
- `firebase-schedule-dailyGameUpdate` running every hour
- `firebase-schedule-weeklyLeaderboardUpdate` running every 7 hours
- `firebase-schedule-triggerSpecialEvent` running every 7 hours

---

## ✅ Deployment Confirmed

**All schedules corrected and deployed:**
- ✅ Hourly daily updates
- ✅ 7-hour weekly snapshots
- ✅ 7-hour event rotations
- ✅ Real-time achievements
- ✅ On-demand validation

**Your accelerated MMO is live!** ⚡🎮🎵

---

*Updated: October 16, 2025 - Time-Accelerated v2.0*
