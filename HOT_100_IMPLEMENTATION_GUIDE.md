# Hot 100 Chart - 7-Day Rolling Streams Implementation Guide

## Overview
The Spotlight Hot 100 chart ranks singles by their streams gained in the **last 7 in-game days**. This creates a dynamic "rolling reset" where older streams naturally drop off, and trending songs rise to the top.

---

## New Field: `last7DaysStreams`

### Added to Song Model
```dart
final int last7DaysStreams; // Streams gained in the last 7 game days
```

**Default Value:** `0`

**Purpose:** Track recent streaming performance to power the Hot 100 chart

**Integration:**
- Fully serialized in `toJson()` and `fromJson()`
- Included in `copyWith()` method
- Compatible with existing songs (defaults to 0 if not present)

---

## How It Works

### Chart Ranking Logic
```dart
// Hot 100 sorts by last7DaysStreams instead of totalStreams
allSingles.sort((a, b) => 
  (b['last7DaysStreams'] as int).compareTo(a['last7DaysStreams'] as int)
);
```

### Automatic "Reset" Effect
- Songs with high recent activity rank higher
- Songs with no recent streams drop off the chart
- Old hits can re-enter if they gain new streams
- Naturally reflects current trends

---

## Implementation Required: Update Stream Growth Service

You'll need to update your stream growth/distribution service to maintain the `last7DaysStreams` field. Here's the recommended approach:

### Option 1: Rolling Window (Recommended)
Track streams with timestamps and calculate on-the-fly:

```dart
// In your stream growth service
class StreamGrowthService {
  Future<void> addStreams(Song song, int newStreams) async {
    final currentGameDate = await _gameTimeService.getCurrentGameDate();
    final cutoffDate = currentGameDate.subtract(Duration(days: 7));
    
    // Add streams to history with timestamp
    // (You'll need to add a streamHistory field)
    final streamHistory = song.metadata['streamHistory'] as List? ?? [];
    streamHistory.add({
      'date': currentGameDate.toIso8601String(),
      'streams': newStreams,
    });
    
    // Calculate last 7 days streams
    int last7DaysTotal = 0;
    for (var entry in streamHistory) {
      final entryDate = DateTime.parse(entry['date']);
      if (entryDate.isAfter(cutoffDate)) {
        last7DaysTotal += entry['streams'] as int;
      }
    }
    
    // Update song
    final updatedSong = song.copyWith(
      streams: song.streams + newStreams,
      last7DaysStreams: last7DaysTotal,
      metadata: {
        ...song.metadata,
        'streamHistory': streamHistory,
      },
    );
    
    // Save to Firebase
    await _saveSong(updatedSong);
  }
}
```

### Option 2: Simple Counter with Daily Reset
Maintain a counter that you reset periodically:

```dart
// In your daily update task
class DailyUpdateService {
  Future<void> runDailyUpdates() async {
    final currentGameDate = await _gameTimeService.getCurrentGameDate();
    
    // Get all songs
    final allSongs = await _getAllSongs();
    
    for (var song in allSongs) {
      // Shift the 7-day window
      final dailyStreams = song.metadata['dailyStreams'] as List? ?? [];
      
      // Add today's streams
      dailyStreams.add({
        'date': currentGameDate.toIso8601String(),
        'streams': song.metadata['todayStreams'] ?? 0,
      });
      
      // Keep only last 7 days
      final cutoffDate = currentGameDate.subtract(Duration(days: 7));
      dailyStreams.removeWhere((entry) {
        final date = DateTime.parse(entry['date']);
        return date.isBefore(cutoffDate);
      });
      
      // Calculate total
      final last7DaysTotal = dailyStreams.fold<int>(
        0, 
        (sum, entry) => sum + (entry['streams'] as int),
      );
      
      // Update song
      final updatedSong = song.copyWith(
        last7DaysStreams: last7DaysTotal,
        metadata: {
          ...song.metadata,
          'dailyStreams': dailyStreams,
          'todayStreams': 0, // Reset for tomorrow
        },
      );
      
      await _saveSong(updatedSong);
    }
  }
}
```

### Option 3: Incremental Update (Simplest)
Update when adding streams:

```dart
// When adding streams to a song
Future<void> addDailyStreams(Song song, int newStreams) async {
  // Simple approach: Add to both total and 7-day counter
  final updatedSong = song.copyWith(
    streams: song.streams + newStreams,
    last7DaysStreams: song.last7DaysStreams + newStreams,
  );
  
  await _saveSong(updatedSong);
}

// Then run a daily decay task
Future<void> decayOldStreams() async {
  // Every game day, reduce last7DaysStreams by ~14% (1/7th)
  // This approximates the rolling window
  final allSongs = await _getAllSongs();
  
  for (var song in allSongs) {
    final decayedStreams = (song.last7DaysStreams * 0.857).round(); // Keep 6/7ths
    final updatedSong = song.copyWith(
      last7DaysStreams: decayedStreams,
    );
    await _saveSong(updatedSong);
  }
}
```

---

## Integration Points

### Where to Update `last7DaysStreams`

1. **StreamGrowthService.distributeStreams()**
   - When calculating daily stream distribution
   - Add streams to both `streams` and `last7DaysStreams`

2. **Daily Update Task**
   - Run once per game day
   - Decay or recalculate 7-day window
   - Remove streams older than 7 days

3. **Song Release**
   - Initialize `last7DaysStreams: 0` on new songs
   - Existing songs default to 0 (handled by model)

---

## Example: Integration with Existing Stream Service

```dart
// Find your existing stream distribution method
// Example location: lib/services/stream_growth_service.dart

Future<void> distributeStreams(Song song, int dailyStreams) async {
  // Your existing code...
  final totalStreams = song.streams + dailyStreams;
  
  // ADD THIS: Update 7-day streams
  final updated7DayStreams = song.last7DaysStreams + dailyStreams;
  
  final updatedSong = song.copyWith(
    streams: totalStreams,
    last7DaysStreams: updated7DayStreams, // NEW
    // ... other fields
  );
  
  await _saveSong(updatedSong);
}

// ADD THIS: Daily decay task (run once per game day)
Future<void> decay7DayStreams() async {
  final allPlayers = await _firestore.collection('players').get();
  
  for (var playerDoc in allPlayers.docs) {
    final songs = playerDoc.data()['songs'] as List?;
    if (songs == null) continue;
    
    bool updated = false;
    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      final last7Days = song['last7DaysStreams'] ?? 0;
      
      if (last7Days > 0) {
        // Reduce by 1/7th (one day drops off)
        songs[i]['last7DaysStreams'] = (last7Days * 0.857).round();
        updated = true;
      }
    }
    
    if (updated) {
      await playerDoc.reference.update({'songs': songs});
    }
  }
}
```

---

## Testing Checklist

### Initial Setup
- [ ] Add `last7DaysStreams` field to all new songs (already done via model default)
- [ ] Existing songs will default to 0 (handled automatically)

### Stream Distribution
- [ ] When a song gains streams, increment both `streams` and `last7DaysStreams`
- [ ] Verify Hot 100 shows songs with recent activity

### Daily Decay
- [ ] Implement decay mechanism (one of the options above)
- [ ] Test that old streams eventually drop off
- [ ] Verify Hot 100 rankings change as streams age

### Edge Cases
- [ ] Song with no recent streams: Should not appear on Hot 100
- [ ] Song released >7 days ago with new streams: Should re-enter chart
- [ ] Very old song: `last7DaysStreams` should decay to near 0

---

## Performance Considerations

### Database Reads
- Hot 100 queries all players (same as other charts)
- No additional database load
- Consider adding index on `last7DaysStreams` if performance issues arise

### Database Writes
- Daily decay task updates all songs once per day
- Batch operations recommended for large player counts
- Can run asynchronously during low-activity periods

### Alternative: Lazy Calculation
If you want to avoid daily tasks:

```dart
// Calculate 7-day streams on-the-fly (slower but no maintenance)
Future<int> calculate7DayStreams(Song song) async {
  final history = song.metadata['streamHistory'] as List? ?? [];
  final cutoff = (await _gameTimeService.getCurrentGameDate())
      .subtract(Duration(days: 7));
  
  return history
      .where((entry) => DateTime.parse(entry['date']).isAfter(cutoff))
      .fold<int>(0, (sum, entry) => sum + (entry['streams'] as int));
}
```

---

## Summary

**Current Status:**
✅ Song model updated with `last7DaysStreams` field
✅ Hot 100 service ranks by 7-day streams
✅ UI displays 7-day stream counts
✅ Automatic handling of missing field (defaults to 0)

**Next Steps:**
⏳ Implement stream distribution updates
⏳ Implement daily decay/recalculation
⏳ Test rolling window behavior

**Key Insight:**
The Hot 100 doesn't filter out old songs—it ranks ALL released singles by their recent performance. A classic hit can re-enter the chart if it gains new streams!
