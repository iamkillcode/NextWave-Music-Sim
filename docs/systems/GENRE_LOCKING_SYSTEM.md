# 🎸 Genre Locking System - Complete Implementation

## Overview

The Genre Locking System restricts players to their chosen genre during onboarding, preventing them from creating songs in other genres until they unlock them through mastery progression.

**Status:** ✅ **COMPLETE**  
**Date:** October 17, 2025

---

## How It Works

### 1. Player Onboarding

When a player creates their account:
1. They select their **Primary Genre** (e.g., "Hip Hop")
2. This genre is saved to Firebase as `primaryGenre`
3. `unlockedGenres` array is initialized with just that one genre: `['Hip Hop']`
4. `genreMastery` map is initialized with 0 mastery: `{'Hip Hop': 0}`

### 2. Creating Songs

When writing a song:
1. Genre dropdown displays ALL genres
2. **Unlocked genres** show normally with full color
3. **Locked genres** show:
   - 🔒 Lock icon
   - Grayed out text
   - "(Locked)" label
   - Disabled (can't be selected)

### 3. Genre Display

```
Dropdown Menu:
┌─────────────────────────┐
│ 🎤 Hip Hop             │ ← Unlocked (white text)
│ 🎵 R&B (Locked)    🔒  │ ← Locked (gray, disabled)
│ 🎸 Rock (Locked)   🔒  │ ← Locked (gray, disabled)
│ 🎹 Jazz (Locked)   🔒  │ ← Locked (gray, disabled)
└─────────────────────────┘
```

---

## Database Schema

### Firebase Structure

```json
{
  "players": {
    "userId123": {
      "displayName": "Artist Name",
      "primaryGenre": "Hip Hop",
      "unlockedGenres": ["Hip Hop"],
      "genreMastery": {
        "Hip Hop": 0
      },
      
      // Other fields...
      "currentMoney": 5000,
      "currentFame": 0,
      "level": 1
    }
  }
}
```

### After Playing for a While

```json
{
  "players": {
    "userId123": {
      "primaryGenre": "Hip Hop",
      "unlockedGenres": ["Hip Hop", "R&B"],
      "genreMastery": {
        "Hip Hop": 85,
        "R&B": 20
      }
    }
  }
}
```

---

## Code Implementation

### Model (`artist_stats.dart`)

```dart
class ArtistStats {
  final String primaryGenre;           // Chosen during onboarding
  final Map<String, int> genreMastery; // Genre name → mastery (0-100)
  final List<String> unlockedGenres;   // Genres player can use
  
  const ArtistStats({
    this.primaryGenre = 'Hip Hop',
    this.genreMastery = const {},
    this.unlockedGenres = const [],
    // ... other fields
  });
}
```

### Loading from Firebase (`dashboard_screen_new.dart`)

```dart
// Load primary genre
final String primaryGenre = data['primaryGenre'] ?? 'Hip Hop';

// Load genre mastery
Map<String, int> loadedGenreMastery = {};
if (data['genreMastery'] != null) {
  final masteryData = data['genreMastery'] as Map<dynamic, dynamic>;
  loadedGenreMastery = masteryData.map(
    (key, value) => MapEntry(key.toString(), (value as num).toInt()),
  );
}

// Load or initialize unlocked genres
List<String> loadedUnlockedGenres = [];
if (data['unlockedGenres'] != null) {
  loadedUnlockedGenres = List<String>.from(data['unlockedGenres']);
} else {
  // First time: unlock only the primary genre
  loadedUnlockedGenres = [primaryGenre];
  loadedGenreMastery[primaryGenre] = 0;
}
```

### Saving to Firebase (`dashboard_screen_new.dart`)

```dart
await FirebaseFirestore.instance
  .collection('players')
  .doc(user.uid)
  .update({
    'primaryGenre': artistStats.primaryGenre,
    'genreMastery': artistStats.genreMastery,
    'unlockedGenres': artistStats.unlockedGenres,
    // ... other fields
  });
```

### Genre Dropdown with Locking (`write_song_screen.dart` & `dashboard_screen_new.dart`)

```dart
DropdownButton<String>(
  value: selectedGenre,
  items: [
    'R&B', 'Hip Hop', 'Rap', 'Trap', 'Drill',
    'Afrobeat', 'Country', 'Jazz', 'Reggae',
  ].map((genre) {
    // Check if genre is unlocked
    final bool isUnlocked = artistStats.unlockedGenres.contains(genre);
    
    return DropdownMenuItem(
      value: genre,
      enabled: isUnlocked, // Disable locked genres
      child: Row(
        children: [
          // Show lock icon for locked genres
          if (!isUnlocked)
            const Icon(Icons.lock, size: 16, color: Colors.grey),
          if (!isUnlocked)
            const SizedBox(width: 4),
          _getGenreIcon(genre),
          const SizedBox(width: 8),
          Text(
            genre,
            style: TextStyle(
              color: isUnlocked ? Colors.white : Colors.grey,
            ),
          ),
          if (!isUnlocked)
            const Text(
              ' (Locked)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
        ],
      ),
    );
  }).toList(),
  onChanged: (value) {
    // Only allow changing to unlocked genres
    if (value != null && artistStats.unlockedGenres.contains(value)) {
      setState(() {
        selectedGenre = value;
      });
    }
  },
)
```

---

## User Experience Flow

### New Player Journey

**Day 1: Account Creation**
```
1. Choose artist name
2. Select age
3. 👉 SELECT PRIMARY GENRE: "Hip Hop"
4. Choose starting region
5. Enter the game

Result:
- Can ONLY write Hip Hop songs
- All other genres show 🔒
```

**Day 2-30: Building Mastery**
```
1. Write Hip Hop songs (gain mastery)
2. High quality = more mastery gain
3. Low quality = less mastery gain
4. Mastery increases: 0 → 10 → 25 → 50 → 75...
```

**Day 31+: First Unlock**
```
When Hip Hop mastery reaches 80+:
1. Unlock notification appears
2. Choose a new genre to unlock
3. R&B becomes available
4. Can now write Hip Hop OR R&B songs
5. Start building R&B mastery from 0
```

### Visual Feedback

**Before Unlock:**
```
Write Song Screen
┌─────────────────────────────┐
│ Genre:                      │
│ ┌─────────────────────────┐ │
│ │ 🎤 Hip Hop             │ │ ← Can select
│ │ 🔒 R&B (Locked)        │ │ ← Grayed out
│ │ 🔒 Rap (Locked)        │ │ ← Grayed out
│ └─────────────────────────┘ │
│                             │
│ Effort Level: [1] [2] [3] [4] │
└─────────────────────────────┘
```

**After Unlock:**
```
Write Song Screen
┌─────────────────────────────┐
│ Genre:                      │
│ ┌─────────────────────────┐ │
│ │ 🎤 Hip Hop             │ │ ← Can select
│ │ 🎵 R&B                 │ │ ← Can select (NEW!)
│ │ 🔒 Rap (Locked)        │ │ ← Still locked
│ │ 🔒 Jazz (Locked)       │ │ ← Still locked
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## Integration Points

### Files Modified

1. **`lib/models/artist_stats.dart`**
   - Added `primaryGenre` field
   - Added `genreMastery` map
   - Added `unlockedGenres` list
   - Updated `copyWith()` method

2. **`lib/screens/dashboard_screen_new.dart`**
   - Load genre data from Firebase (lines 264-284)
   - Save genre data to Firebase (lines 418-420)
   - Filter genre dropdown in quick song dialog (lines 2560-2595)
   - Initialize selected genre to primary (line 2380)

3. **`lib/screens/write_song_screen.dart`**
   - Filter genre dropdown (lines 603-645)
   - Initialize selected genre to primary (line 405)

### Backwards Compatibility

**Old Players (No Genre Data):**
```dart
// Dashboard checks for missing fields
if (data['unlockedGenres'] == null) {
  // First time loading new system
  // Default to Hip Hop
  loadedUnlockedGenres = [primaryGenre];
  loadedGenreMastery[primaryGenre] = 0;
}
```

**Result:** Old players get Hip Hop unlocked by default, can continue playing normally.

---

## Benefits

### For Players

1. **Focused Learning Curve**
   - Start with one genre
   - Master it before expanding
   - Prevents overwhelm for new players

2. **Progression System**
   - Clear goal: "Master Hip Hop to unlock more"
   - Sense of achievement when unlocking
   - Long-term engagement

3. **Genre Identity**
   - Builds player's unique style
   - Encourages specialization
   - More realistic music career simulation

### For Game Design

1. **Retention**
   - Players have long-term goals
   - Unlocking genres is exciting milestone
   - Natural progression curve

2. **Balance**
   - Prevents genre-hopping exploits
   - Forces investment in skills
   - More meaningful genre bonuses

3. **Tutorial Flow**
   - Simpler onboarding (fewer options)
   - Gradual feature introduction
   - Better new player experience

---

## Future Enhancements (Not Yet Implemented)

### Genre Mastery Display

Show mastery progress in UI:
```
Skills Screen:
┌─────────────────────────────┐
│ 🎸 GENRE MASTERY            │
├─────────────────────────────┤
│ 🎤 Hip Hop: [████████░░] 85% │
│    "Expert" - Can unlock next│
│                             │
│ 🎵 R&B:     [███░░░░░░░] 30% │
│    "Beginner"               │
│                             │
│ 🔒 Rap: LOCKED              │
│    Master Hip Hop to unlock │
└─────────────────────────────┘
```

### Unlock Animations

Celebration when unlocking:
```
🎉 GENRE UNLOCKED! 🎉
═══════════════════════
    🎸 ROCK 🎸
═══════════════════════
You've mastered Hip Hop!
You can now write Rock songs.
```

### Genre Mastery Calculation

```dart
int calculateMasteryGain(String genre, double songQuality, int effort) {
  // Base gain from effort
  int baseGain = effort * 5; // 5, 10, 15, 20
  
  // Quality bonus (0-15 extra)
  int qualityBonus = (songQuality / 100 * 15).round();
  
  // Total gain
  int totalGain = baseGain + qualityBonus;
  
  return totalGain.clamp(5, 35); // Min 5, Max 35 per song
}
```

**Example:**
- Low effort (1), poor quality (40): +5 mastery
- Medium effort (2), good quality (70): +20 mastery  
- High effort (4), excellent quality (95): +35 mastery

### Unlock Thresholds

```dart
bool canUnlockNewGenre(String currentGenre) {
  int mastery = genreMastery[currentGenre] ?? 0;
  return mastery >= 80; // 80% mastery required
}

List<String> getUnlockableGenres() {
  // Can unlock genres similar to your mastered ones
  // e.g., Hip Hop → Rap, Trap, Drill
  // e.g., R&B → Soul, Jazz
}
```

---

## Testing Checklist

### ✅ New Player Flow
- [x] Create account, select Hip Hop
- [x] Verify only Hip Hop is unlocked
- [x] Try to write song → Hip Hop works
- [x] Check dropdown → Other genres locked
- [x] Verify Firebase has correct data

### ✅ Genre Locking UI
- [x] Locked genres show 🔒 icon
- [x] Locked genres grayed out
- [x] Locked genres say "(Locked)"
- [x] Can't select locked genres
- [x] Dropdown looks good

### ✅ Data Persistence
- [x] Logout and login → Genre still locked
- [x] Create song → Save works
- [x] Reload page → Genres stay locked
- [x] Firebase updates correctly

### ✅ Backwards Compatibility
- [x] Old player logs in → Gets Hip Hop unlocked
- [x] No errors for missing fields
- [x] Can continue playing normally

### 🔄 Future Tests (When Mastery Implemented)
- [ ] Gain mastery from writing songs
- [ ] Reach 80% mastery → Unlock new genre
- [ ] New genre appears in dropdown
- [ ] Can write songs in new genre
- [ ] Mastery progress displays correctly

---

## Known Limitations

1. **No Mastery Gain Yet**
   - Genre mastery doesn't increase from writing songs
   - Need to implement mastery calculation
   - Need to add UI to show progress

2. **No Unlock Mechanism**
   - Can't unlock new genres through gameplay
   - Players stuck with primary genre until manual unlock
   - Need to add unlock UI and logic

3. **No Visual Feedback**
   - No mastery bars or progress indicators
   - No celebration when unlocking
   - Need to add mastery display screen

---

## Summary

✅ **What Works Now:**
- Genre locking at onboarding
- Only primary genre unlocked initially
- Locked genres show in dropdown with 🔒
- Can't select locked genres
- Data saves and loads from Firebase
- Backwards compatible with old players

🔄 **What's Next:**
- Calculate mastery gains from writing songs
- Display mastery progress in UI
- Allow unlocking new genres at 80% mastery
- Add unlock celebration animations
- Genre progression system

---

**Status:** Core locking system is **COMPLETE** and ready for testing!  
**Next Step:** Implement genre mastery gain calculation.

*Created: October 17, 2025*  
*System: Genre Locking & Mastery*
