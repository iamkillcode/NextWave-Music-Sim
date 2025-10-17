# 🔧 Critical Fixes - October 17, 2025

## Issues Identified

### 1. ❌ Artist Pictures Not Displaying Everywhere
**Status:** PARTIAL - Works in some places, missing in others

**Current Implementation:**
- ✅ Settings screen: Upload works
- ✅ Tunify screen: Displays avatarUrl
- ✅ Maple Music screen: Displays avatarUrl  
- ❌ Charts screens: Not displaying artist pictures
- ❌ Dashboard profile card: Using generic icon instead of avatarUrl
- ❌ Song cards: May not show artist avatar

**Root Cause:** 
- avatarUrl is saved to Firebase
- avatarUrl is loaded into ArtistStats
- But some UI components don't use avatarUrl field

**Locations to Fix:**
1. Dashboard profile card (line ~1459)
2. Charts screens (unified_charts_screen.dart, spotlight_charts_screen.dart, regional_charts_screen.dart)
3. Any song card widgets

---

### 2. 🚨 Streams Stuck & Fans Not Increasing
**Status:** CRITICAL - Game-breaking bug

**Symptoms:**
- Player releases song
- Streams show initial value
- Days/weeks pass in-game
- Streams remain stuck at same number
- Fanbase doesn't grow

**Root Causes to Investigate:**
1. **Daily update not triggering** - Check if `_applyDailyStreamGrowth()` is being called
2. **Date comparison issue** - Song's lastStreamUpdateDate may not be updating
3. **Calculation returns 0** - Stream growth formula may be broken for low fanbase
4. **Hourly update check** - 12-hour wait between updates may be too long
5. **Backend function not running** - Cloud Function `simulateNPCActivity` may not be processing player songs

**Debugging Steps:**
1. Check console logs for stream update messages
2. Verify lastStreamUpdateDate is updating
3. Test with high fanbase vs low fanbase
4. Check if backend daily update is running
5. Verify song state is 'released'

---

### 3. ❌ Genres Not Locked to Player's Choice
**Status:** MISSING FEATURE

**Current Behavior:**
- Player selects genre during onboarding (e.g., "Hip Hop")
- Genre saved as `primaryGenre` in Firestore
- BUT: Player can still write songs in ANY genre
- Genre dropdown shows all 9 genres

**Expected Behavior:**
- Player can ONLY write songs in their chosen genre initially
- Other genres should be locked/disabled
- Genre mastery system should unlock additional genres

**Locations to Fix:**
1. `write_song_screen.dart` - Genre dropdown
2. `dashboard_screen_new.dart` - Quick song dialog genre dropdown
3. Add genre mastery logic

---

### 4. ⚠️ Genre Mastering System Missing
**Status:** NOT IMPLEMENTED

**Requirements:**
- Track mastery level per genre (0-100% or similar)
- Gain mastery by writing songs in that genre
- High-quality songs = more mastery
- Unlock new genres after mastering current one
- Display mastery progress in UI

**Proposed Implementation:**
```dart
// Add to ArtistStats model
final Map<String, int> genreMastery; // e.g., {'Hip Hop': 85, 'R&B': 20}
final List<String> unlockedGenres; // e.g., ['Hip Hop', 'R&B']

// Mastery calculation
int calculateMasteryGain(String genre, double songQuality, int effort) {
  // Base gain from writing
  int baseGain = effort * 5;
  
  // Quality bonus (better songs = more mastery)
  int qualityBonus = (songQuality / 10).round();
  
  return baseGain + qualityBonus;
}

// Unlock threshold
bool canUnlockGenre(String genre) {
  return genreMastery[primaryGenre] >= 80; // 80% mastery required
}
```

---

### 5. ⚠️ Fanbase and Level Show Same Values
**Status:** INTENTIONAL but confusing

**Explanation:**
This is NOT a bug - it's by design for backwards compatibility.

**Current System:**
```dart
// When saving to Firebase:
'level': artistStats.fanbase, // Level = fanbase for compatibility
'fanbase': artistStats.fanbase, // Also save fanbase explicitly

// When loading from Firebase:
fanbase: (data['fanbase'] ?? data['level'] ?? 1).toInt()
// Try fanbase first, fallback to level for old saves
```

**Why It Works This Way:**
- Old code used `level` field to store fanbase
- New code uses `fanbase` field
- Both fields saved for compatibility
- They will ALWAYS have the same value

**Is This a Problem?**
- ❌ No - it's working as intended
- ✅ Fanbase grows correctly (quality × 2 per song, album bonuses)
- ✅ Both fields stay in sync
- ✅ Old saves still work

**If User Wants Separate Level:**
Need to decide what "level" means:
- Option A: Keep it tied to fanbase (current system)
- Option B: Create separate XP-based level system
- Option C: Use career milestones as "level"

---

## Fix Priority

### 🔴 CRITICAL (Fix Immediately)
1. **Streams stuck / Fans not increasing** - Game is unplayable if songs don't grow

### 🟡 HIGH (Fix Soon)
2. **Genre locking** - Core gameplay mechanic missing
3. **Artist pictures in charts** - Visual polish issue

### 🟢 MEDIUM (Enhancement)
4. **Genre mastering system** - Adds depth but not critical
5. **Fanbase/Level clarification** - Document behavior or redesign

---

## Files That Need Changes

### For Artist Picture Display:
- `lib/screens/dashboard_screen_new.dart` (profile card)
- `lib/screens/unified_charts_screen.dart`
- `lib/screens/spotlight_charts_screen.dart`
- `lib/screens/regional_charts_screen.dart`

### For Streams Fix:
- `lib/screens/dashboard_screen_new.dart` (daily update logic)
- `lib/services/stream_growth_service.dart` (calculation)
- `functions/index.js` (backend daily update)

### For Genre Locking:
- `lib/screens/write_song_screen.dart`
- `lib/screens/dashboard_screen_new.dart`
- `lib/models/artist_stats.dart` (add genre mastery fields)

### For Genre Mastering:
- `lib/models/artist_stats.dart` (add fields)
- `lib/screens/write_song_screen.dart` (show mastery UI)
- `lib/screens/dashboard_screen_new.dart` (update mastery on song creation)

---

## Next Steps

1. **Investigate streams issue** - Add debug logging
2. **Fix artist pictures** - Update UI components
3. **Implement genre locking** - Disable dropdown options
4. **Design genre mastery** - Plan progression system
5. **Document fanbase/level** - Clarify for users

---

*Created: October 17, 2025*
*Status: Investigation complete, fixes pending*
