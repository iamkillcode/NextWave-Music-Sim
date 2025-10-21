# 🎵 Monthly Listeners Verification & Fix

**Date**: October 21, 2025  
**Status**: ⚠️ ISSUE IDENTIFIED - Fix Pending  
**Priority**: HIGH (Affects player experience across both streaming platforms)

---

## 📋 Executive Summary

Verification of monthly listeners calculation for **Tunify** and **Maple Music** revealed **critical discrepancies**:

1. **Tunify**: Uses incorrect formula based on lifetime streams instead of recent activity
2. **Maple Music**: Doesn't display monthly listeners at all (shows followers instead)
3. **Inconsistency**: Two platforms use completely different metrics

---

## 🔍 Current Implementation Analysis

### 1. Tunify Screen (`lib/screens/tunify_screen.dart`)

**Current Formula:**
```dart
final monthlyListeners = (totalStreams * 0.3).round();
```

**Location**: Lines 49-50

**Problems:**
- ❌ Uses **lifetime total streams**, not last 30 days
- ❌ Formula assumes 30% of all streams happened in last month
- ❌ Becomes increasingly inaccurate as artist's career progresses
- ❌ Doesn't reflect current popularity/activity

**Example Issue:**
```
Artist with 10M lifetime streams:
- Current calculation: 3M monthly listeners (10M * 0.3)
- Reality: If streams are old, actual monthly might be only 100K
- Discrepancy: Shows 30x higher than actual!
```

---

### 2. Maple Music Screen (`lib/screens/maple_music_screen.dart`)

**Current Formula:**
```dart
final followers = (_currentStats.fanbase * 0.4).round();
```

**Location**: Lines 51-52

**Problems:**
- ❌ Shows **"followers"** (40% of fanbase), NOT monthly listeners
- ❌ Completely different metric than Tunify
- ❌ No monthly listeners metric at all
- ❌ Inconsistent user experience between platforms

**Example Issue:**
```
Artist with 5,000 fanbase:
- Current display: 2,000 followers
- Missing: Monthly listeners metric entirely
- Inconsistency: Tunify shows "monthly listeners", Maple shows "followers"
```

---

## 📊 Available Data in Song Model

The `Song` model (`lib/models/song.dart`) tracks:

| Field | Description | Availability |
|-------|-------------|--------------|
| `streams` | Lifetime total streams | ✅ Available |
| `lastDayStreams` | Streams in last 1 game day | ✅ Available |
| `last7DaysStreams` | Streams in last 7 game days | ✅ Available |
| `last30DaysStreams` | Streams in last 30 game days | ❌ **NOT TRACKED** |

**Root Cause:**
- Song model does NOT track `last30DaysStreams` field
- No daily stream history array exists
- Cannot calculate true 30-day rolling window

---

## 💡 Proposed Solution

### Approach: Use `last7DaysStreams` as Proxy

Since true 30-day tracking doesn't exist, use the available `last7DaysStreams` field as a proxy:

**Formula:**
```dart
monthlyListeners = (last7DaysStreams * 4.3).round()
```

**Rationale:**
- 30 days ≈ 4.3 weeks (30 / 7 = 4.286)
- Assumes relatively consistent weekly streaming patterns
- Uses RECENT activity instead of lifetime totals
- Works with existing data (no schema changes needed)

**Accuracy:**
- ✅ More accurate than current `totalStreams * 0.3` approach
- ✅ Reflects recent popularity/activity
- ✅ Updates naturally as `last7DaysStreams` decays
- ⚠️ Assumes consistent weekly patterns (good enough approximation)

---

## 🔧 Implementation Plan

### Phase 1: Fix Tunify Screen

**File**: `lib/screens/tunify_screen.dart`

**Current Code (Lines 45-50):**
```dart
final totalStreams = releasedSongs.fold<int>(
  0,
  (sum, song) => sum + song.streams,
);
final monthlyListeners = (totalStreams * 0.3).round();
```

**Proposed Fix:**
```dart
final last7DaysStreams = releasedSongs.fold<int>(
  0,
  (sum, song) => sum + song.last7DaysStreams,
);
// Monthly ≈ 4.3 weeks of activity (30 days / 7 days per week)
final monthlyListeners = (last7DaysStreams * 4.3).round();
```

**Impact:**
- ✅ Shows recent activity (last ~30 days)
- ✅ Automatically updates with new streams
- ✅ Decays naturally as songs age

---

### Phase 2: Fix Maple Music Screen

**File**: `lib/screens/maple_music_screen.dart`

**Current Code (Lines 51-52):**
```dart
final followers = (_currentStats.fanbase * 0.4).round();
```

**Proposed Fix:**
```dart
// Calculate monthly listeners (same as Tunify for consistency)
final releasedSongs = _currentStats.songs
    .where(
      (s) => s.state == SongState.released && 
             s.streamingPlatforms.contains('maple_music'),
    )
    .toList();

final last7DaysStreams = releasedSongs.fold<int>(
  0,
  (sum, song) => sum + song.last7DaysStreams,
);
final monthlyListeners = (last7DaysStreams * 4.3).round();

// Keep followers as separate metric if needed
final followers = (_currentStats.fanbase * 0.4).round();
```

**Impact:**
- ✅ Adds monthly listeners metric (was missing)
- ✅ Consistent with Tunify calculation
- ✅ Can show BOTH followers AND monthly listeners
- ✅ Better reflects actual listening activity

---

## 🧪 Verification Tool

Created debug tool: `lib/debug/verify_monthly_listeners.dart`

**Usage:**
```dart
import 'package:nextwave/debug/verify_monthly_listeners.dart';

// Print detailed report to console
MonthlyListenersVerification.printVerificationReport(artistStats);

// Or get raw data
final report = MonthlyListenersVerification.verifyMonthlyListeners(artistStats);
```

**Output Example:**
```
================================================================================
🎵 MONTHLY LISTENERS VERIFICATION REPORT
================================================================================

📊 Artist: Your Artist Name
📀 Released Songs: 5
🌍 Total Lifetime Streams: 2.5M
📈 Last 7 Days Streams: 50.0K
📉 Last Day Streams: 8.5K

--------------------------------------------------------------------------------
🎵 TUNIFY (Spotify-like)
--------------------------------------------------------------------------------

❌ Current Implementation:
   Monthly Listeners (Current): 750.0K
   Formula: totalStreams * 0.3
   Problem: Uses lifetime streams, not actual monthly activity...

✅ Proposed Fix:
   Monthly Listeners (Proposed): 215.0K
   Formula: last7DaysStreams * 4.3
   Benefit: Uses recent activity (last 7 days) as proxy...

📊 Discrepancy:
   Change: -71.3%
   Absolute Difference: -535.0K

--------------------------------------------------------------------------------
🍎 MAPLE MUSIC (Apple Music-like)
--------------------------------------------------------------------------------

❌ Current Implementation:
   Followers (Current): 2.0K
   Formula: fanbase * 0.4
   Problem: Shows follower count, NOT monthly listeners...

✅ Proposed Fix:
   Monthly Listeners (Proposed): 215.0K
   Formula: last7DaysStreams * 4.3
   Benefit: Consistent with Tunify...

📊 Discrepancy:
   Note: Cannot compare followers to monthly listeners - different metrics
   Currently Missing: Monthly listeners metric entirely

--------------------------------------------------------------------------------
💡 RECOMMENDATIONS
--------------------------------------------------------------------------------
   ✅ Use last7DaysStreams * 4.3 as proxy for monthly listeners
   ✅ Apply same calculation to both Tunify and Maple Music for consistency
   ✅ Keep followers as separate metric (can show both)
   ⚠️ Future enhancement: Track daily streams for accurate 30-day rolling window

================================================================================
```

---

## 🎯 Benefits of Fix

### For Tunify:
1. ✅ **Accurate Representation**: Shows actual recent activity, not inflated lifetime stats
2. ✅ **Dynamic Updates**: Increases with new releases, decreases as songs age
3. ✅ **Player Feedback**: Players see realistic impact of their releases

### For Maple Music:
1. ✅ **Consistency**: Uses same calculation as Tunify
2. ✅ **New Metric**: Adds missing monthly listeners display
3. ✅ **Complete Info**: Can show both followers AND monthly listeners

### For Game Balance:
1. ✅ **Fair Comparison**: Both platforms use consistent metrics
2. ✅ **Realistic Progression**: Monthly listeners reflect current popularity
3. ✅ **Player Understanding**: Clear correlation between releases and listeners

---

## 🚀 Future Enhancements

### Option A: Add `last30DaysStreams` Field

**Implementation:**
1. Add `last30DaysStreams` to `Song` model
2. Update daily cycle to decay and add streams
3. Use exact 30-day value instead of 4.3x approximation

**Pros:**
- 100% accurate 30-day rolling window
- No approximation needed

**Cons:**
- Requires schema migration
- More storage per song
- Increased calculation overhead

---

### Option B: Track Daily Stream History

**Implementation:**
1. Add `dailyStreamHistory: List<int>` to Song model
2. Keep last 30 values (rolling window)
3. Sum array for exact monthly listeners

**Pros:**
- Perfectly accurate
- Can visualize stream trends over time
- Supports any time window (7-day, 14-day, 30-day, etc.)

**Cons:**
- Significant storage increase
- Complex migration for existing songs
- Higher computational cost

---

## 📝 Testing Checklist

After implementing fix:

- [ ] Run verification tool on test artist with old songs
- [ ] Verify Tunify shows lower monthly listeners for aged catalog
- [ ] Verify Maple Music shows monthly listeners (not just followers)
- [ ] Check that new releases increase monthly listeners
- [ ] Confirm daily decay reduces monthly listeners correctly
- [ ] Test with artist with no releases (should show 0 monthly listeners)
- [ ] Verify both platforms show same monthly listeners value
- [ ] Check UI displays formatted numbers correctly (K, M, B)

---

## 📚 Related Files

| File | Purpose | Changes Needed |
|------|---------|----------------|
| `lib/screens/tunify_screen.dart` | Tunify platform UI | Update calculation lines 45-50 |
| `lib/screens/maple_music_screen.dart` | Maple Music platform UI | Add monthly listeners lines 51-52 |
| `lib/models/song.dart` | Song data model | No changes needed (uses existing fields) |
| `lib/debug/verify_monthly_listeners.dart` | Verification tool | ✅ Created |
| `docs/fixes/MONTHLY_LISTENERS_VERIFICATION.md` | This document | ✅ Created |

---

## 🎬 Next Steps

1. ✅ **Completed**: Created verification tool
2. ✅ **Completed**: Documented current issues
3. ⏳ **Pending**: Implement fix for Tunify screen
4. ⏳ **Pending**: Implement fix for Maple Music screen
5. ⏳ **Pending**: Run verification tool to confirm fix
6. ⏳ **Pending**: Update tests to use new calculation
7. ⏳ **Pending**: Deploy and monitor player feedback

---

## 👥 Impact Assessment

**Affected Systems:**
- Tunify screen (primary fix)
- Maple Music screen (primary fix)
- Player perception of success metrics
- Game balance and progression

**User-Facing Changes:**
- Monthly listeners may show lower values initially (more accurate)
- Maple Music gains new monthly listeners display
- Both platforms now consistent

**Migration:**
- No database migration needed
- No breaking changes to Song model
- Purely UI calculation changes

---

**Author**: GitHub Copilot  
**Review**: Pending  
**Status**: Ready for Implementation
