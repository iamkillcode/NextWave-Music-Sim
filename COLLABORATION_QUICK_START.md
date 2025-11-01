# 🚀 Quick Integration Steps for Collaboration System

## Add Collaboration to Activity Hub

### Step 1: Import the Screen
Add this import at the top of `lib/screens/activity_hub_screen.dart`:

```dart
import 'collaboration_screen.dart';
```

### Step 2: Add the Card
In the `_buildActivityCards()` method, add this card:

```dart
_buildActivityCard(
  context: context,
  title: '🤝 Collaborations',
  icon: Icons.people_alt,
  color: const Color(0xFF9B59B6), // Purple
  description: 'Feature artists on your songs',
  subtitle: artistStats.fame >= 25
      ? 'Available • Tap to explore'
      : '🔒 Requires 25 Fame',
  isUnlocked: artistStats.fame >= 25,
  lockMessage: 'Gain 25 Fame to unlock collaborations',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollaborationScreen(
          artistStats: artistStats,
          onStatsUpdated: onStatsUpdated,
        ),
      ),
    );
  },
),
```

---

## Display Featuring Artists on Songs

### In Release Song Screen
Update the song display to show featuring artist:

```dart
// In lib/screens/release_song_screen.dart or any song display widget

String getDisplayTitle(Song song) {
  final featuring = song.metadata['featuringArtist'] as String?;
  if (featuring != null) {
    return '${song.title} (feat. $featuring)';
  }
  return song.title;
}
```

### In Charts
```dart
// When displaying song titles in charts:
Text(
  getDisplayTitle(song),
  style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
  ),
),
```

### Show Collaboration Badge
```dart
// Add a badge next to collaborative songs:
if (song.metadata.containsKey('featuringArtist')) {
  Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.purple.withOpacity(0.2),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.purple),
    ),
    child: Text(
      'COLLAB',
      style: TextStyle(
        color: Colors.purple,
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
}
```

---

## Apply Stream Boosts

### When Releasing a Song
In the release logic, apply the collaboration boost:

```dart
// In _releaseSong() or similar method:

final collaborationBoost = song.metadata['collaborationBoost'] as double? ?? 1.0;

// When calculating initial streams:
final baseStreams = calculateBaseStreams(song); // Your existing calculation
final boostedStreams = (baseStreams * collaborationBoost).round();

// Create released song with boosted streams
final releasedSong = song.copyWith(
  state: SongState.released,
  streams: boostedStreams,
  releasedDate: DateTime.now(),
);
```

### Daily Stream Updates
Apply boost when updating daily streams:

```dart
// In stream calculation logic:
int calculateDailyStreams(Song song, ArtistStats stats) {
  final collaborationBoost = song.metadata['collaborationBoost'] as double? ?? 1.0;
  
  final baseDaily = _calculateBaseDaily(song, stats);
  final boostedDaily = (baseDaily * collaborationBoost).round();
  
  return boostedDaily;
}
```

---

## Show Collaboration Details

### In Song Details View
```dart
// Show collaboration info:
if (song.metadata.containsKey('featuringArtist')) {
  Container(
    margin: EdgeInsets.symmetric(vertical: 8),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.purple.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.purple.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.people, color: Colors.purple, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Featuring: ${song.metadata['featuringArtist']}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${song.metadata['collaborationBoost']}x stream boost',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

---

## Code Snippets Reference

### Complete Song Title Helper
```dart
class SongHelper {
  static String getDisplayTitle(Song song) {
    final featuring = song.metadata['featuringArtist'] as String?;
    if (featuring != null) {
      return '${song.title} (feat. $featuring)';
    }
    return song.title;
  }

  static bool isCollaboration(Song song) {
    return song.metadata.containsKey('featuringArtist');
  }

  static double getCollaborationBoost(Song song) {
    return song.metadata['collaborationBoost'] as double? ?? 1.0;
  }

  static String? getFeaturingArtist(Song song) {
    return song.metadata['featuringArtist'] as String?;
  }
}
```

### Usage Example
```dart
// Display song title with featuring artist
Text(SongHelper.getDisplayTitle(song));

// Check if collaboration
if (SongHelper.isCollaboration(song)) {
  // Show collaboration badge
}

// Apply boost to streams
final boost = SongHelper.getCollaborationBoost(song);
final boostedStreams = (baseStreams * boost).round();
```

---

## Testing Checklist

1. **Integration:**
   - [ ] Added import to activity_hub_screen.dart
   - [ ] Added collaboration card to Activity Hub
   - [ ] Card is locked when fame < 25
   - [ ] Card opens collaboration screen when tapped

2. **Display:**
   - [ ] Song titles show "feat. Artist Name"
   - [ ] Collaboration badge appears on collab songs
   - [ ] Collaboration details shown in song info

3. **Functionality:**
   - [ ] Can browse NPC artists
   - [ ] Can filter by genre and tier
   - [ ] Can select recorded song
   - [ ] Collaboration cost deducted
   - [ ] Quality bonus applied
   - [ ] Fame and fanbase increased
   - [ ] Stream boost stored in metadata

4. **Streams:**
   - [ ] Initial streams use collaboration boost
   - [ ] Daily updates apply boost
   - [ ] Charts show boosted streams

---

## Quick Demo Flow

1. **Setup:**
   - Start new game or use existing profile
   - Gain 25+ fame (release songs, concerts, etc.)

2. **Create Song:**
   - Write a song in Studio
   - Record the song (Self Produce or Studio Producer)

3. **Collaborate:**
   - Open Activity Hub
   - Tap "🤝 Collaborations"
   - Browse NPC artists
   - Select an artist (Rising tier for affordable test)
   - Choose your recorded song
   - Confirm collaboration (costs $5K for Rising)

4. **Verify:**
   - Song quality increased
   - Fame and fanbase increased
   - Money deducted
   - Song metadata contains featuring info

5. **Release:**
   - Go to Release Manager
   - Release the collaborative song
   - Verify title shows "feat. Artist Name"
   - Check streams are boosted

---

## 💡 Pro Tips

1. **Genre Matching**: Collaborate with artists in the same genre for bonus effects
2. **Fame Progression**: Higher fame = cheaper collaborations
3. **Strategic Collabs**: Use legends on your best songs for maximum boost
4. **Quality Boost**: Collaboration quality bonus can push songs from 80% to 100%+
5. **Fanbase Growth**: Legend collabs can instantly add 500K+ fans

---

## 🐛 Troubleshooting

**Q: Collaboration screen is empty**  
A: Make sure your fame is at least 25. Check `artistStats.fame` value.

**Q: Can't select any songs**  
A: Only recorded songs (not written or released) can have collaborations added.

**Q: Song title doesn't show featuring artist**  
A: Make sure to use `SongHelper.getDisplayTitle(song)` in your display widgets.

**Q: Streams not boosted**  
A: Apply the boost when calculating streams: `baseStreams * song.metadata['collaborationBoost']`

**Q: Changes don't persist**  
A: Make sure to call `onStatsUpdated(_currentStats)` after collaboration.

---

**Quick Start:** Add collaboration card to Activity Hub → Record a song → Tap Collaborations → Select artist → Profit! 🚀
