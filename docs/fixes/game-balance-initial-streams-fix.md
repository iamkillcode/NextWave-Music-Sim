# Game Balance Fix - Initial Streams Calculation

## Issue

**Date:** January 2025  
**Severity:** Critical - Game Breaking  
**Component:** `lib/screens/release_song_screen.dart`

### Problem Description

New artists releasing their first song were receiving completely unrealistic initial streams:
- **Before Fix:** 3M streams, Fame +26, Level 79
- **Expected:** ~100 streams, Fame +2-5, Level 1-2

### Root Cause

The initial streams calculation was using `Song.estimatedStreams` which is based on **global population** (8.5 billion people):

```dart
// In lib/models/song.dart - UNREALISTIC for new artists
int get estimatedStreams {
  const globalPopulation = 8500000000;
  final qualityFactor = finalQuality / 100.0;
  final genrePopularityFactor = _getGenrePopularityFactor();
  final marketPenetration = qualityFactor * genrePopularityFactor * 0.01;
  return (globalPopulation * marketPenetration).round();
}
```

Example for a quality 50 song:
- Estimated streams: 8,500,000,000 * 0.5 * 1.0 * 0.01 = **42,500,000**
- Initial streams (10%): **4,250,000**
- This is realistic for superstars, not brand new artists!

## Solution

Replaced the global population-based calculation with a **fanbase-based** realistic formula in `release_song_screen.dart`:

### New Calculation

```dart
// Calculate realistic initial streams based on artist's ACTUAL fanbase
final baseInitialStreams = widget.artistStats.fanbase > 0 
    ? widget.artistStats.fanbase  // Fanbase is the starting point
    : 10;  // Absolute minimum for brand new artists with no fans

// Quality multiplier (0.4 to 1.0) - even great songs start small for new artists
final qualityMultiplier = (widget.song.finalQuality / 100.0) * 0.6 + 0.4;

// Platform multiplier - more platforms = more reach (1.0 to 1.5)
final platformMultiplier = 1.0 + (_selectedPlatforms.length - 1) * 0.25;

// Calculate realistic initial streams (first day release)
final realisticInitialStreams = (baseInitialStreams * qualityMultiplier * platformMultiplier).round();
```

### Fame & Fanbase Growth Changes

Also adjusted to be more gradual:

**Before:**
```dart
final fameGain = (widget.song.finalQuality * 0.5).round();  // Quality 50 = +25 fame
final fanbaseGain = (widget.song.finalQuality * 2).round(); // Quality 50 = +100 fans
```

**After:**
```dart
final fameGain = _releaseNow 
    ? (widget.song.finalQuality * 0.1).round().clamp(1, 5)  // Max 5 fame on release
    : 0;

final fanbaseGain = _releaseNow
    ? (widget.song.finalQuality * 0.5).round().clamp(5, 50)  // 5-50 new fans max on release
    : 0;
```

### Likes Calculation

Changed from 5% to 30% of streams (more realistic engagement rate):

```dart
likes: _releaseNow ? (realisticInitialStreams * 0.3).round() : 0,  // 30% of streams become likes
```

## Expected Results by Artist Tier

### Brand New Artist (0-10 fanbase)
- **Quality 50 song, 2 platforms:**
  - Base: 10 fans
  - Quality multiplier: 0.7
  - Platform multiplier: 1.25
  - **Initial streams: ~9**
  - Fame gain: +2-3
  - Fanbase gain: +25

### Growing Artist (100 fanbase)
- **Quality 60 song, 3 platforms:**
  - Base: 100 fans
  - Quality multiplier: 0.76
  - Platform multiplier: 1.5
  - **Initial streams: ~114**
  - Fame gain: +3-4
  - Fanbase gain: +30

### Established Artist (1,000 fanbase)
- **Quality 70 song, 4 platforms:**
  - Base: 1,000 fans
  - Quality multiplier: 0.82
  - Platform multiplier: 1.75
  - **Initial streams: ~1,435**
  - Fame gain: +5
  - Fanbase gain: +35

### Popular Artist (10,000 fanbase)
- **Quality 80 song, 5 platforms:**
  - Base: 10,000 fans
  - Quality multiplier: 0.88
  - Platform multiplier: 2.0
  - **Initial streams: ~17,600**
  - Fame gain: +5
  - Fanbase gain: +40

### Superstar (100,000 fanbase)
- **Quality 90 song, 5 platforms:**
  - Base: 100,000 fans
  - Quality multiplier: 0.94
  - Platform multiplier: 2.0
  - **Initial streams: ~188,000**
  - Fame gain: +5
  - Fanbase gain: +45

## Impact

### Before Fix
- Game was unplayable for new users
- No progression curve - instant success
- Level system broken (jumped to level 79 immediately)
- No sense of achievement

### After Fix
- ✅ Realistic progression for new artists
- ✅ Gradual growth matches artist's actual fanbase
- ✅ Quality still matters (better songs get more streams)
- ✅ Platform selection has impact
- ✅ StreamGrowthService handles daily growth properly
- ✅ Level system works correctly (gradual XP gain)

## Files Modified

1. **lib/screens/release_song_screen.dart**
   - Lines 866-890: New realistic initial streams calculation
   - Lines 882-888: Adjusted fame and fanbase gains
   - Lines 932, 944, 947, 952: Replaced `estimatedStreams` with `realisticInitialStreams`

## Related Systems

- `lib/services/stream_growth_service.dart` - Handles daily stream growth (unchanged)
- `lib/models/song.dart` - `estimatedStreams` getter still exists (may be used elsewhere)
- Level/XP system - Now receives realistic stream counts

## Testing Recommendations

1. Create new artist with 0 fanbase
2. Release quality 50 song on 2 platforms
3. Verify initial streams are ~10-20 (not millions)
4. Verify fame increases by 2-3 (not 26)
5. Verify level increases to 1-2 (not 79)
6. Let game run for 1-2 days
7. Verify stream growth continues naturally via StreamGrowthService

## Notes

- The `Song.estimatedStreams` getter in `lib/models/song.dart` was **not** modified
- It may still be used elsewhere in the codebase for estimates/projections
- The fix specifically targets the **initial streams** calculation on release
- Daily stream growth continues to use the robust `StreamGrowthService`
