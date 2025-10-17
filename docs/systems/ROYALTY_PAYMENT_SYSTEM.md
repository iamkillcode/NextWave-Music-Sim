# Royalty Payment System 💰

## Overview

Artists in NextWave receive **daily royalty payments** based on their songs' streaming performance. This creates a realistic, sustainable income model rather than lump-sum payments at release.

---

## When Do Artists Get Paid?

### Daily Payment Schedule

**Trigger:** Every time a game day changes (midnight in-game time)

**Process:**
1. ⏰ Game detects day change (e.g., Day 5 → Day 6)
2. 📈 `_applyDailyStreamGrowth()` is called
3. 🎵 For each released song:
   - Calculate new daily streams
   - Distribute streams across regions
   - **Calculate royalties per platform**
   - Add income to artist's money
4. 💵 Total income displayed: "💰 Today's earnings: $X from Y streams"

**Location:** `lib/screens/dashboard_screen_new.dart`, lines 552-700

---

## Royalty Rates by Platform

### Tunify 🎵
- **Royalty Rate:** $0.003 per stream
- **Platform Reach:** 85% (global mainstream platform)
- **Formula:** `income = newStreams × 0.85 × 0.003`
- **Example:** 10,000 streams = $25.50

### Maple Music 🍁
- **Royalty Rate:** $0.01 per stream
- **Platform Reach:** 65% (premium platform, smaller audience)
- **Formula:** `income = newStreams × 0.65 × 0.01`
- **Example:** 10,000 streams = $65.00

### Multi-Platform Release
If a song is on **both platforms**, royalties are paid from each:
- **10,000 streams on both:**
  - Tunify: $25.50
  - Maple Music: $65.00
  - **Total: $90.50**

---

## Payment Calculation Code

```dart
// From dashboard_screen_new.dart, lines 620-633
// Calculate income from new streams (pay artists daily royalties)
int songIncome = 0;
for (final platform in song.streamingPlatforms) {
  if (platform == 'tunify') {
    // Tunify: 85% reach, $0.003 per stream royalty
    songIncome += (newStreams * 0.85 * 0.003).round();
  } else if (platform == 'maple_music') {
    // Maple Music: 65% reach, $0.01 per stream royalty
    songIncome += (newStreams * 0.65 * 0.01).round();
  }
}

totalNewIncome += songIncome;
```

---

## Daily Growth Cycle

### 1. Day Change Detection
```dart
// Triggered when game time ticks to a new day
if (newGameDate.day != currentGameDate!.day || 
    newGameDate.month != currentGameDate!.month || 
    newGameDate.year != currentGameDate!.year) {
  _applyDailyStreamGrowth(newGameDate);
}
```

### 2. Stream Growth Calculation
For each released song:
```dart
// Calculate how many days since last update
final daysSinceLastUpdate = currentGameDate
    .difference(song.lastStreamUpdateDate ?? song.releaseDate!)
    .inDays;

// Skip if already updated today
if (daysSinceLastUpdate <= 0) continue;

// Calculate new streams using StreamGrowthService
final newStreams = _streamGrowthService.calculateDailyStreamGrowth(
  song: song,
  artistStats: artistStats,
  daysActive: daysSinceRelease,
);
```

### 3. Regional Distribution
```dart
// Distribute streams across regions (50% current, 30% fanbase, 20% genre)
final updatedRegionalStreams = _streamGrowthService
    .calculateRegionalStreamDistribution(
  totalDailyStreams: newStreams,
  currentRegion: artistStats.currentRegion,
  regionalFanbase: artistStats.regionalFanbase,
  genre: song.genre,
);
```

### 4. Royalty Payment
```dart
// Calculate income per platform
int songIncome = 0;
for (final platform in song.streamingPlatforms) {
  if (platform == 'tunify') {
    songIncome += (newStreams * 0.85 * 0.003).round();
  } else if (platform == 'maple_music') {
    songIncome += (newStreams * 0.65 * 0.01).round();
  }
}
totalNewIncome += songIncome;
```

### 5. Update Artist Stats
```dart
// Add money to artist's balance
final updatedStats = artistStats.copyWith(
  money: artistStats.money + totalNewIncome,
  fanbase: artistStats.fanbase + fanbaseGrowth,
  fame: artistStats.fame + fameGrowth,
  loyalFanbase: artistStats.loyalFanbase + loyalFanGrowth,
);
```

---

## Example Payment Scenarios

### Scenario 1: Single Song, Single Platform
**Setup:**
- 1 song released on Tunify
- Song gets 5,000 streams today

**Payment:**
```
Income = 5,000 × 0.85 × 0.003
       = 5,000 × 0.00255
       = $12.75
```

### Scenario 2: Single Song, Both Platforms
**Setup:**
- 1 song released on both platforms
- Song gets 8,000 streams today

**Payment:**
```
Tunify:      8,000 × 0.85 × 0.003 = $20.40
Maple Music: 8,000 × 0.65 × 0.01  = $52.00
Total:                              = $72.40
```

### Scenario 3: Multiple Songs, Mixed Platforms
**Setup:**
- Song A (Tunify only): 10,000 streams
- Song B (Both platforms): 5,000 streams
- Song C (Maple Music only): 2,000 streams

**Payment:**
```
Song A (Tunify):
  10,000 × 0.85 × 0.003 = $25.50

Song B (Both):
  Tunify:      5,000 × 0.85 × 0.003 = $12.75
  Maple Music: 5,000 × 0.65 × 0.01  = $32.50
  Subtotal:                          = $45.25

Song C (Maple):
  2,000 × 0.65 × 0.01 = $13.00

Total Daily Income = $25.50 + $45.25 + $13.00 = $83.75
```

---

## What Artists DON'T Get on Release Day

### ❌ Removed Features (Old System)
Previously, artists received:
- Immediate lump-sum payment based on estimated revenue
- 10% of projected total earnings upfront

### Why This Changed
1. **Unrealistic:** Real streaming platforms pay monthly/quarterly, not instantly
2. **Unbalanced:** Huge upfront payments made game progression too easy
3. **No Long-term Value:** Artists didn't benefit from long-term song performance
4. **Exploit-prone:** Players could release low-quality songs for quick cash

### ✅ What Artists Get on Release (Current System)
- **Fame increase:** +1 to +5 (based on song quality)
- **Fanbase growth:** +5 to +50 new fans (based on song quality)
- **Regional fanbase distribution:** Fans spread across regions based on location
- **Initial streams:** Small realistic number (10-200 for new artists)
- **Chart eligibility:** Song appears on regional/global charts

**First payment arrives the next game day** when streams start accumulating.

---

## Payment Timing in Real-Time

### Game Time vs Real Time
- **Game Time:** 1 game day = configurable (e.g., 10 real minutes)
- **Real Time:** Payments calculated when game day changes

**Example Timeline:**
```
Day 1 (10:00 AM real time):
  - Release song
  - Initial streams: 50
  - Income: $0 (no payment yet)

Day 2 (10:10 AM real time):
  - New streams: 150
  - Income: $0.38 (first payment!)
  - Notification: "💰 Today's earnings: $0.38 from 150 streams"

Day 3 (10:20 AM real time):
  - New streams: 280
  - Income: $0.71
  - Total earned so far: $1.09

Day 7 (11:00 AM real time):
  - New streams: 1,200
  - Income: $3.06
  - Total earned so far: $15.43
```

---

## Factors Affecting Daily Income

### 1. Stream Count (Primary Factor)
More streams = more money. Simple.

**Growth Factors:**
- Song quality (higher = more streams)
- Virality score (trending songs get viral boosts)
- Artist fanbase (loyal fans stream regularly)
- Days since release (gradual growth curve)
- Genre popularity in regions

### 2. Platform Selection (Critical Decision)
**Tunify Only:** Lower per-stream rate but 85% reach
- Better for **mainstream/pop** artists
- Better for **high-volume** streams
- Lower income per stream but more total streams

**Maple Music Only:** Higher per-stream rate but 65% reach
- Better for **niche/quality** artists
- Better when streams are **limited**
- Higher income per stream but fewer total streams

**Both Platforms:** Maximum income potential
- Requires paying for both platform fees on release
- Best strategy for **established artists**
- Combines high volume (Tunify) + high rate (Maple)

### 3. Regional Distribution
Streams are distributed based on:
- **50%** → Current region (where artist is located)
- **30%** → Regional fanbase size (fans in each region)
- **20%** → Genre preferences (e.g., Hip Hop popular in USA)

**Strategy Tip:** Travel to regions with large fanbases to boost streams!

### 4. Song Age Decay
Songs don't maintain peak streams forever:
- **Days 1-7:** Peak growth period (viral potential)
- **Days 8-30:** Steady streams (loyal fans)
- **Days 31-90:** Gradual decline (aging song)
- **Days 90+:** Legacy streams (occasional plays)

---

## Income Display to Player

### In-Game Notifications
```
💰 Today's earnings: $127.45 from 3,642 streams across 2 songs
```

### Console Logs (Debug)
```
📈 Summer Vibes: +2.5K streams (Total: 15.2K)
💰 Summer Vibes earned: $21.25 today
📈 Night Drive: +1.1K streams (Total: 8.7K)  
💰 Night Drive earned: $9.35 today
✅ Total daily income: $30.60 from 3,600 new streams
```

### Dashboard Stats (Future Enhancement)
Could add:
- "Weekly Earnings: $215.40"
- "Top Earning Song: 'Summer Vibes' ($87.50 this week)"
- "Earnings by Platform: Tunify $140.20 | Maple Music $75.20"

---

## Testing Daily Payments

### Quick Test (10-minute cycles)
1. Set game time to 10 real minutes = 1 game day
2. Release a song on both platforms
3. Wait 10 real minutes
4. Check money increased by ~$0.50-$5.00 (depending on streams)
5. Check notification shows "Today's earnings"

### Proper Test (1-hour cycles)
1. Set game time to 1 real hour = 1 game day
2. Release high-quality song (80+)
3. Wait 1 hour
4. Should get $5-$50 depending on fanbase
5. Wait another hour
6. Should get more (streams growing)

### Multi-Day Test
1. Release song and let it run for 24 real hours
2. Check daily payments:
   - Day 1-3: Growing income
   - Day 4-7: Peak income period
   - Day 8+: Steady/declining

---

## Common Questions

### Q: Why didn't I get paid when I released my song?
**A:** Payments are daily, not immediate. You'll get your first payment the next game day when streams accumulate.

### Q: How long until my song makes $1,000?
**A:** Depends on streams. At peak (10K/day on both platforms), ~11 days. For new artists (100/day), ~120 days.

### Q: Which platform pays better?
**A:** Maple Music pays 3.3x more per stream ($0.01 vs $0.003), but Tunify has 30% more reach. Both platforms = best income.

### Q: Do old songs still make money?
**A:** Yes! All released songs generate daily streams (though they decay over time). A catalog of 10 songs can provide steady passive income.

### Q: Can I see my total lifetime earnings?
**A:** Currently tracked in `artistStats.money`. Could add a separate "Total Earnings" stat in future.

---

## Related Systems

- **Stream Growth Service:** `lib/services/stream_growth_service.dart`
  - Calculates daily stream growth per song
  - Handles virality, decay, regional distribution

- **Regional Charts:** `lib/screens/regional_charts_screen.dart`
  - Shows which songs are earning well per region
  - Helps plan where to travel for maximum income

- **Game Time Service:** `lib/services/game_time_service.dart`
  - Manages game time progression
  - Triggers daily payment cycle

---

## Future Enhancements

### Potential Additions
1. **Weekly Payouts:** Bundle 7 days into one larger payment (more realistic)
2. **Platform Statements:** "Tunify paid you $127.45 this week for 5,000 streams"
3. **Tax System:** Government takes 15-30% (adds realism + money sink)
4. **Royalty Splits:** If you collaborate, split payments with featured artists
5. **Advance Payments:** Borrow against future royalties (debt mechanic)
6. **Payment History:** View past 30 days of earnings with graphs
7. **Merchandising Income:** Additional revenue streams beyond streaming

---

## Summary

✅ **Payment Frequency:** Daily (every game day change)  
✅ **Payment Trigger:** Automatic when day ticks over  
✅ **Calculation:** `newStreams × platformReach × royaltyRate`  
✅ **Platforms:** Tunify ($0.003/stream) + Maple Music ($0.01/stream)  
✅ **Display:** Console logs + notification showing daily earnings  
✅ **Strategy:** Both platforms + high quality + large fanbase = maximum income  

**No more instant payouts on release! Build your catalog, grow your fanbase, and earn daily royalties like a real artist.** 🎵💰
