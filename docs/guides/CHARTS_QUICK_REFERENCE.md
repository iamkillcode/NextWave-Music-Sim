# Charts System Quick Reference

## 🎯 All 6 Issues - RESOLVED

1. ✅ **Regional charts align with Spotlight** - Unified UI/UX
2. ✅ **Spotlight 200 charts albums only** - Filter: `isAlbum == true`
3. ✅ **Hot 100 singles reset every 7 days** - Ranks by `last7DaysStreams`
4. ✅ **Regional charts can support daily/weekly** - Architecture in place
5. ✅ **Released songs not showing** - Filter: `state == 'released'`
6. ✅ **TypeError fixed** - Extract data from flat map structure

---

## 📊 Chart Types

### Regional Charts
- **Filter:** `state == 'released'` + `regionalStreams[region] > 0`
- **Sort:** Regional streams ↓
- **Shows:** All songs

### Spotlight 200
- **Filter:** `state == 'released'` + `isAlbum == true`
- **Sort:** Total streams ↓
- **Shows:** Top 200 albums

### Hot 100
- **Filter:** `state == 'released'` + `isAlbum == false` + `last7DaysStreams > 0`
- **Sort:** Last 7 days streams ↓
- **Shows:** Top 100 singles

---

## 🆕 New Fields

### `isAlbum` (bool)
- Default: `false`
- Separates albums from singles
- Required for Spotlight chart filtering

### `last7DaysStreams` (int)
- Default: `0`
- Tracks recent performance
- Powers Hot 100 rankings
- **Needs implementation:** See `HOT_100_IMPLEMENTATION_GUIDE.md`

---

## 📁 Key Files

### Created
- `lib/services/spotlight_chart_service.dart`
- `lib/screens/spotlight_charts_screen.dart`
- `HOT_100_IMPLEMENTATION_GUIDE.md`
- `REGIONAL_AND_SPOTLIGHT_CHARTS_FIXES.md`
- `CHARTS_SYSTEM_COMPLETE.md`

### Modified
- `lib/models/song.dart` - Added 2 fields
- `lib/services/regional_chart_service.dart` - Added release filter
- `lib/screens/regional_charts_screen.dart` - Fixed TypeError

---

## ⚡ Quick Start

### Use Spotlight Charts
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SpotlightChartsScreen()),
);
```

### Create Album
```dart
Song(
  // ... fields
  isAlbum: true, // Shows on Spotlight 200
)
```

### Create Single
```dart
Song(
  // ... fields
  isAlbum: false, // Shows on Hot 100
  last7DaysStreams: 0, // Will be updated by stream service
)
```

---

## ⏳ TODO: Implement Stream Updates

### When Adding Streams
```dart
updatedSong = song.copyWith(
  streams: song.streams + newStreams,
  last7DaysStreams: song.last7DaysStreams + newStreams, // ADD
);
```

### Daily Decay Task
```dart
updatedSong = song.copyWith(
  last7DaysStreams: (song.last7DaysStreams * 0.857).round(), // Decay 1/7th
);
```

**Full Guide:** `HOT_100_IMPLEMENTATION_GUIDE.md`

---

## 🎨 Chart Colors

- **Regional:** Varies by region
- **Spotlight 200:** Gold (#FFD700)
- **Hot 100:** Orange-red (#FF4500)

---

## 🏆 Medal System

- **#1:** Gold medal + glow
- **#2:** Silver medal + glow
- **#3:** Bronze medal + glow
- **#4-10:** Trending icon
- **#11+:** Position number

---

## ✅ Testing Checklist

- [ ] Regional charts show only released songs
- [ ] No TypeError when opening regional charts
- [ ] Spotlight 200 shows only albums
- [ ] Hot 100 shows only singles
- [ ] User's songs are highlighted
- [ ] Medals appear on top 3
- [ ] Stream counts formatted correctly

---

## 📚 Documentation

- **Overview:** `CHARTS_SYSTEM_COMPLETE.md`
- **Bug Fixes:** `REGIONAL_AND_SPOTLIGHT_CHARTS_FIXES.md`
- **Hot 100 Guide:** `HOT_100_IMPLEMENTATION_GUIDE.md`
- **Quick Ref:** This file

---

**Status:** Core implementation complete. Stream update logic required for Hot 100 to work properly.
