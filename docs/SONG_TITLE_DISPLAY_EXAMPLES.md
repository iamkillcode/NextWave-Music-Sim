# Song Title Display Examples

## Scenario: Dr. Dre collaborates with Snoop Dogg on "Still Dre"

### Original Song
- **Title**: "Still Dre"
- **Owner**: Dr. Dre (Primary Artist)
- **State**: Written (not yet recorded)

---

## Step 1: Dr. Dre Sends Collab Request

**In Collaboration Screen:**
- Dr. Dre selects song: "Still Dre"
- Sends request to Snoop Dogg
- Offers $500 feature fee
- 70/30 split

---

## Step 2: Snoop Dogg Sees Request in StarChat

**StarChat Message Card Shows:**
```
┌─────────────────────────────────────┐
│ 🎵 Collab Request                   │
│ 2m ago                              │
├─────────────────────────────────────┤
│ 🎵 "Still Dre"                      │
│                                     │
│ wants to collaborate with you on    │
│ "Still Dre"                         │
│                                     │
│ ┌─────────────────────────────┐    │
│ │ Split:         70% / 30%    │    │
│ │ Feature Fee:   $500         │    │
│ └─────────────────────────────┘    │
│                                     │
│  [   Accept   ]  [  Decline  ]     │
└─────────────────────────────────────┘
```

---

## Step 3: After Acceptance

### Song Metadata Updated:
```json
{
  "id": "song_123",
  "title": "Still Dre",
  "genre": "Hip Hop",
  "state": "written",
  "metadata": {
    "featuringArtist": "Snoop Dogg",
    "featuringArtistId": "snoop_id",
    "isCollaboration": true
  }
}
```

---

## Step 4: How Song Title Displays Everywhere

### For Dr. Dre (Primary Artist):
```
Your Songs:
  📝 Still Dre (feat. Snoop Dogg)
  
Active Collaborations:
  🎵 Still Dre (feat. Snoop Dogg) - Recording
  
Charts (if released):
  #1 Still Dre - Dr. Dre feat. Snoop Dogg
```

### For Snoop Dogg (Featuring Artist):
```
Your Songs:
  📝 Still Dre (feat. Dr. Dre)
  
Active Collaborations:
  🎵 Still Dre (feat. Dr. Dre) - Recording
  
Charts (if released):
  #1 Still Dre - Dr. Dre feat. Snoop Dogg
```

### For Other Players (Public View):
```
Charts:
  #1 Still Dre - Dr. Dre feat. Snoop Dogg
  
Search Results:
  🎵 Still Dre
     Dr. Dre feat. Snoop Dogg
     Hip Hop • 1.2M streams
```

---

## Code Implementation

### Displaying Song Titles Correctly:

```dart
import '../utils/song_display_helper.dart';

// Method 1: Simple formatting (shows featuring artist)
Widget buildSongTitle(Song song) {
  return Text(
    SongDisplayHelper.getFormattedTitle(song),
    // Output: "Still Dre (feat. Snoop Dogg)"
  );
}

// Method 2: Check if it's a collab first
Widget buildSongCard(Song song) {
  final isCollab = SongDisplayHelper.isCollaboration(song);
  final title = SongDisplayHelper.getFormattedTitle(song);
  
  return ListTile(
    leading: Icon(isCollab ? Icons.people : Icons.music_note),
    title: Text(title),
    subtitle: isCollab 
      ? Text('Collaboration')
      : null,
  );
}

// Method 3: Get featuring artist info
Widget buildDetailedSongInfo(Song song) {
  if (SongDisplayHelper.isCollaboration(song)) {
    final featuring = SongDisplayHelper.getFeaturingArtist(song);
    return Column(
      children: [
        Text(song.title, style: TextStyle(fontSize: 20)),
        Text('feat. $featuring', style: TextStyle(fontSize: 16)),
      ],
    );
  }
  return Text(song.title, style: TextStyle(fontSize: 20));
}
```

---

## Important Notes

### ✅ Automatic Updates
- Song metadata is updated automatically when collaboration is accepted
- No manual updates needed in your UI code
- Just use `SongDisplayHelper.getFormattedTitle(song)` everywhere

### ✅ Backwards Compatible
- Songs without collaborations show normal titles
- No errors if `metadata` field doesn't exist
- Safe to use on all songs (collab or not)

### ✅ Consistent Display
- Same song shows differently to primary vs featuring artist
- Public views show "Artist A feat. Artist B"
- Private views show "Song Title (feat. Other Artist)"

---

## Edge Cases Handled

1. **Song Title Already Has "feat."**
   - Original: "Still Dre (feat. Snoop Dogg)"
   - Won't double-add featuring info
   - Check title before adding to metadata

2. **Multiple Collaborations**
   - Currently supports 1 featuring artist
   - Future: Can extend to support multiple features

3. **Collaboration Cancelled/Rejected**
   - Metadata not added to song
   - Song remains solo track
   - Can send new request later

4. **Song Deleted**
   - Collaboration reference remains
   - Handle gracefully in UI
   - Show "Song Unavailable"
