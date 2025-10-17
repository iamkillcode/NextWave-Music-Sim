# Passive Streaming Income & Album Recording Fix

## Overview
Two major improvements to the game's music career mechanics:
1. **Album Recording Fix**: Albums now require RECORDED songs, not just written ones
2. **Passive Streaming Income**: Released songs automatically earn money over time based on streams

---

## 1. Album Recording Fix

### Previous Issue
- Albums could be created from written songs that weren't recorded
- This skipped the recording process entirely
- Songs would go from written → album (skipping the recorded state)

### Fixed Implementation

**Requirements:**
- ✅ Need **3 RECORDED songs** (not written songs)
- ✅ Need 40 energy
- ✅ Songs must be in `SongState.recorded` state

**What Happens:**
1. System checks for recorded songs: `artistStats.songs.where((s) => s.state == SongState.recorded)`
2. Takes the first 3 recorded songs
3. Changes their state to `SongState.released`
4. Sets `releasedDate` to current game date
5. Awards album bonuses: +15 Fame, +$200K

**Error Messages:**
- If not enough recorded songs: "❌ Need at least 3 RECORDED songs to release an album\nGo to the Studio to record your written songs!"
- If not enough energy: Standard energy check applies

**Proper Song Pipeline:**
```
Write Song → Record in Studio → Release as Album → Earn Passive Income
   (Written)      (Recorded)         (Released)        (Streaming)
```

---

## 2. Passive Streaming Income

### How It Works

**Automatic Calculation:**
- Runs every game time update (every real second)
- Calculates income from ALL released songs
- Updates in background without player action

**Income Formula:**
```dart
Quality Multiplier = song.finalQuality / 10  // Range: 0-10
Streams Per Second = qualityMultiplier * 0.5  // Range: 0-5 streams/sec
Streams Gained = streamsPerSecond * realSecondsPassed

Income per Stream:
- Tunify: $0.003 per stream
- Maple Music: $0.01 per stream
```

**Example Calculation:**
- Song Quality: 80 (Excellent)
- Quality Multiplier: 80 / 10 = 8
- Streams/Second: 8 * 0.5 = 4 streams per real second
- In 60 real seconds: 240 streams
- On Tunify only: 240 * $0.003 = $0.72
- On Maple Music only: 240 * $0.01 = $2.40

### Income Scaling

**Quality Impact:**
| Quality | Rating | Streams/Sec | Income/Min (Tunify) | Income/Min (Maple) |
|---------|--------|-------------|---------------------|-------------------|
| 90-100  | Legendary | 4.5-5.0 | $0.81-$0.90 | $2.70-$3.00 |
| 80-89   | Masterpiece | 4.0-4.4 | $0.72-$0.79 | $2.40-$2.64 |
| 70-79   | Excellent | 3.5-3.9 | $0.63-$0.70 | $2.10-$2.34 |
| 60-69   | Great | 3.0-3.4 | $0.54-$0.61 | $1.80-$2.04 |
| 50-59   | Good | 2.5-2.9 | $0.45-$0.52 | $1.50-$1.74 |

**Multiple Songs:**
- Each released song earns independently
- Total income = sum of all song incomes
- 10 high-quality songs can earn $20-30 per real minute

### Notifications

**When You Get Notified:**
- Income reaches $100 or more
- At least 60 seconds since last notification
- Shows: Total earnings + stream count + number of songs

**Notification Example:**
```
💰 Streaming Income
Your 5 songs earned $127 from 12,450 streams!
```

### Console Logging
```
💰 Passive income: $127.50 from 12450 streams
```

### Stream Count Tracking
- Each song's `streams` field updates in real-time
- Visible in song details and Tunify screen
- Persists to Firebase with player data

---

## Implementation Details

### State Variables Added
```dart
DateTime? _lastPassiveIncomeTime; // Track notification timing
```

### Methods Added

**`_calculatePassiveIncome(int realSecondsPassed)`**
- Called every game update tick
- Iterates through all released songs
- Calculates streams based on quality
- Applies platform-specific rates
- Updates song stream counts
- Awards money to player
- Triggers notifications when appropriate

### Integration Points

**In `_updateGameTime()`:**
```dart
// Calculate passive streaming income from released songs
_calculatePassiveIncome(realSecondsSinceSync);
```

**In `record_album` action:**
```dart
// Updates songs to released state
return song.copyWith(
  state: SongState.released,
  releasedDate: currentGameDate,
);
```

---

## Player Experience

### Before Fix
1. Write 3 songs
2. Click "Album" from Quick Actions
3. ❌ Skips recording process
4. ❌ No streaming income

### After Fix
1. Write songs
2. Go to Studio and record songs
3. Release album (uses recorded songs)
4. ✅ Songs automatically earn streaming income
5. ✅ Watch money grow passively!

### Strategy Tips

**For Players:**
- Record high-quality songs for better passive income
- Release songs on multiple platforms (Tunify + Maple Music)
- More released songs = more passive income streams
- Quality matters! 90+ songs earn 5x more than 50 quality

**Income Progression:**
- Early game (3 songs, 60 quality): ~$3-5/real minute
- Mid game (10 songs, 70 quality): ~$20-25/real minute
- Late game (30 songs, 85 quality): ~$100+/real minute

---

## Technical Considerations

### Performance
- Calculations run every second
- O(n) complexity where n = released songs
- Efficient for typical song counts (< 100)
- No database queries in calculation loop

### Data Persistence
- Stream counts saved with song data
- Money updates saved during regular sync (every 30 seconds)
- No additional Firebase writes needed

### Balance
**Current rates are conservative:**
- Real artists: $0.003-0.005 per stream (Spotify)
- Game rate: Matches real-world Spotify rates
- Time compression: 1 real second = 24 game seconds
- This makes income feel meaningful but not exploitable

**Tuning Options:**
If income feels too slow/fast, adjust:
```dart
const streamsPerSecond = qualityMultiplier * 0.5; // Increase/decrease multiplier
```

---

## Testing

### Test Album Recording Fix
1. Write 3 songs
2. Try to release album → Should fail
3. Record songs in studio
4. Release album → Should succeed
5. Verify songs are now in "Released" state

### Test Passive Income
1. Release an album (3 songs)
2. Wait 60 real seconds
3. Check money - should increase
4. Check notifications - should show streaming income
5. Check song details - stream counts should increase

### Debug Commands (in console)
```dart
// Check released songs
print(artistStats.songs.where((s) => s.state == SongState.released));

// Check current money
print(artistStats.money);

// Force passive income calculation
_calculatePassiveIncome(60); // Simulate 60 seconds
```

---

## Future Enhancements

### Potential Additions
- **Viral Songs**: Random chance for exponential stream growth
- **Trending Bonus**: Newer songs earn more initially
- **Fan Growth**: Streams increase fanbase over time
- **Platform Bonuses**: Special events with 2x streaming income
- **Song Lifecycle**: Streams decay over time (old songs earn less)
- **Genre Trends**: Popular genres earn more during trend periods

### Balance Adjustments
Monitor player feedback on:
- Income rate (too fast/slow?)
- Quality scaling (linear vs exponential?)
- Platform differences (Maple Music premium worth it?)
- Notification frequency (annoying vs helpful?)

---

## Summary

✅ **Album Recording**: Now properly requires recorded songs
✅ **Passive Income**: Songs earn money automatically based on quality and time
✅ **Streaming Mechanics**: Realistic rates matching real-world platforms
✅ **Player Progression**: Rewards building a catalog of quality songs
✅ **Notifications**: Keep players informed of their earnings

This creates a more realistic music career simulation where:
- Recording quality matters
- Building a catalog provides long-term value
- Income scales with success
- Players are rewarded for strategic song development
