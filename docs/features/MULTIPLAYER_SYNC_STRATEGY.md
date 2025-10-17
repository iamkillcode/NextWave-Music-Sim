# Multiplayer Sync Strategy

## Overview
NextWave is a multiplayer music simulation game that requires real-time sync for competitive features like charts, leaderboards, and social interactions. This document outlines the optimized Firebase sync strategy that balances multiplayer responsiveness with cost-effectiveness.

## Sync Strategy

### 1. **Immediate Saves** (Critical Multiplayer Events)
Used for events that affect other players or game state immediately.

**Use Cases:**
- 🎵 Publishing songs (other players see in charts)
- 🌍 Changing regions (affects matchmaking)
- 🏆 Major achievements (leaderboard updates)
- 💿 Album releases (visible to all players)

**Implementation:**
```dart
_immediateSave(); // No delay, saves to Firebase instantly
```

**Firebase Writes:** ~2-5 per active session (low frequency, high impact)

---

### 2. **Debounced Saves** (Rapid UI Interactions)
Used for quick consecutive changes that don't need instant sync.

**Use Cases:**
- 📱 Social media posts (500ms delay acceptable)
- ⚡ Energy consumption (multiple quick actions)
- 💰 Money changes (spending/earning rapidly)
- 📊 Skill improvements (grinding activities)

**Implementation:**
```dart
_debouncedSave(); // 500ms delay, cancels if new change occurs
```

**Debounce Duration:** 500ms (half a second)
- Fast enough for good multiplayer feel
- Prevents spam during rapid button clicks
- Still feels responsive to users

**Firebase Writes:** ~30-60 per hour of active play (medium frequency)

---

### 3. **Auto-Save Timer** (Background Sync)
Ensures progress is synced even if player is idle or making passive progress.

**Use Cases:**
- 🎧 Passive streaming income
- 📈 Automated fan growth
- ⏰ Time-based progression
- 🔄 General state persistence

**Implementation:**
```dart
// Runs every 30 seconds
syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
  if (_hasPendingSave && mounted) {
    _saveUserProfile();
  }
});
```

**Firebase Writes:** ~120 per hour (if active), 0 if no changes

---

## Cost-Effectiveness Analysis

### Write Frequency Breakdown:

| Activity Type | Frequency | Writes/Hour | Cost Impact |
|--------------|-----------|-------------|-------------|
| **Immediate saves** (songs, regions) | Rare | 2-5 | Very Low |
| **Debounced saves** (UI interactions) | Moderate | 30-60 | Low-Medium |
| **Auto-save timer** (background sync) | Regular | 0-120 | Medium |
| **Total** | - | **32-185** | **Acceptable** |

### Comparison to Other Strategies:

| Strategy | Writes/Hour | Pros | Cons |
|----------|-------------|------|------|
| **Every change** (naive) | 500-1000+ | Perfect sync | Very expensive, overkill |
| **3-second debounce** (previous) | 10-20 | Cheap | Too slow for multiplayer |
| **Current strategy** | 32-185 | Balanced | Optimal for multiplayer |
| **Manual save only** | 1-5 | Very cheap | Terrible UX, data loss risk |

### Monthly Cost Estimate (Firebase Free Tier):

**Free Tier Allowance:** 20,000 writes/day, 600,000 writes/month

**Our Usage (per player):**
- Active play: ~100 writes/hour
- 2 hours/day average: ~200 writes/day
- Monthly: ~6,000 writes/player

**Capacity:** ~100 concurrent daily active users on free tier

**Paid Tier:** $0.18 per 100,000 writes
- 1,000 players × 6,000 writes/month = 6M writes
- Cost: ~$10.80/month for database writes
- **Very affordable for a multiplayer game!**

---

## Multiplayer Features Supported

### Real-Time Elements:
1. **Music Charts** - Songs appear in charts within 30 seconds of release
2. **Leaderboards** - Stats update within 30 seconds
3. **EchoX Posts** - Posts visible within 1 second (immediate save)
4. **Player Profiles** - Stats visible to others within 30 seconds
5. **Regional Competition** - Region changes sync immediately
6. **Streaming Counts** - Updated every 30 seconds

### Non-Real-Time Elements (OK to Lag):
1. **Money/Energy** - 500ms delay acceptable
2. **Skill Levels** - 30 second delay acceptable
3. **Passive Income** - Background calculation, syncs every 30s

---

## Implementation Details

### State Management:
```dart
// Track if we have unsaved changes
bool _hasPendingSave = false;

// Debounce timer (500ms)
Timer? _saveDebounceTimer;

// Auto-save timer (30s)
Timer? syncTimer;
```

### Save Methods:

**1. Immediate Save (Critical Events):**
```dart
void _immediateSave() {
  _saveDebounceTimer?.cancel();
  _hasPendingSave = false;
  _saveUserProfile(); // Saves to Firebase immediately
}
```

**2. Debounced Save (UI Interactions):**
```dart
void _debouncedSave() {
  _hasPendingSave = true;
  _saveDebounceTimer?.cancel();
  
  // Wait 500ms - if no new changes, save
  _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
    if (_hasPendingSave && mounted) {
      _saveUserProfile();
    }
  });
}
```

**3. Auto-Save Timer (Background):**
```dart
syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
  if (_hasPendingSave && mounted) {
    print('🔄 Auto-save: Syncing with Firebase for multiplayer...');
    _saveUserProfile();
  }
});
```

### Dispose Handling:
```dart
@override
void dispose() {
  gameTimer?.cancel();
  syncTimer?.cancel();
  _countdownTimer?.cancel();
  _saveDebounceTimer?.cancel();
  
  // Flush any pending saves before exit (no data loss)
  if (_hasPendingSave) {
    _saveUserProfile();
  }
  
  super.dispose();
}
```

---

## Usage Guidelines

### When to use Immediate Save:
✅ Publishing songs, albums
✅ Changing regions/locations
✅ Completing major achievements
✅ Unlocking new content
✅ Purchasing permanent upgrades
✅ Creating/deleting important content

### When to use Debounced Save:
✅ Money earned/spent
✅ Energy consumed
✅ Skill XP gained
✅ Social media interactions
✅ Reputation changes
✅ General stat updates

### What Auto-Save Handles:
✅ Passive streaming income
✅ Time-based progression
✅ Background calculations
✅ Idle progress
✅ Catching any missed saves

---

## Performance Metrics

### Target Metrics:
- **Sync Latency:** <1 second for critical events
- **UI Responsiveness:** No lag during rapid interactions
- **Data Persistence:** 100% (no data loss)
- **Cost Efficiency:** <$20/month for 1000 DAU
- **Scalability:** Supports 10,000+ concurrent players

### Monitoring:
```dart
// Log all saves for debugging
print('💾 Saving user profile for: ${user.uid}');
print('✅ Profile saved successfully');
print('🔄 Auto-save: Syncing with Firebase for multiplayer...');
```

---

## Configuration

### Adjust Debounce Duration:
```dart
// Current: 500ms (good for most cases)
Timer(const Duration(milliseconds: 500), () { ... });

// Options:
// - 250ms: More responsive, higher writes
// - 500ms: Balanced (recommended)
// - 1000ms: More economical, slightly slower
```

### Adjust Auto-Save Frequency:
```dart
// Current: 30 seconds (good balance)
Timer.periodic(const Duration(seconds: 30), (timer) { ... });

// Options:
// - 10s: More real-time, higher cost
// - 30s: Balanced (recommended)
// - 60s: More economical, slower sync
```

---

## Testing Strategy

### Test Scenarios:
1. **Rapid clicks test:** Click buttons quickly, verify only 1 save after 500ms
2. **Multi-device test:** Make changes, verify sync on other device within 30s
3. **Charts test:** Publish song, verify appears in charts within 30s
4. **Idle test:** Leave app open, verify auto-save fires every 30s
5. **Network test:** Offline → online, verify saves queue and sync

### Monitoring Tools:
- Firebase Console: Monitor write counts
- Chrome DevTools: Watch console logs
- Network tab: Verify request frequency
- Firestore Usage: Check daily/monthly metrics

---

## Future Optimizations

### Potential Improvements:
1. **Delta updates:** Only save changed fields, not entire profile
2. **Batch writes:** Group related updates into transactions
3. **Compression:** Compress song data before saving
4. **Offline queue:** Save locally, batch sync when online
5. **Smart timing:** Adjust auto-save based on user activity level
6. **Field-level timestamps:** Track which fields changed when
7. **Conflict resolution:** Handle simultaneous edits from multiple devices

### Advanced Features:
- Real-time listeners for live multiplayer events
- Presence system (online/offline status)
- Live notifications for player interactions
- Shared global events (concerts, competitions)

---

## Conclusion

This strategy provides:
- ✅ **Great multiplayer experience** - Near real-time sync for critical events
- ✅ **Cost-effective** - ~$10-20/month for 1000 players
- ✅ **Responsive UI** - No lag during rapid interactions
- ✅ **No data loss** - All changes persisted safely
- ✅ **Scalable** - Supports thousands of concurrent players

Perfect balance for a multiplayer music simulation game! 🎵🎮

---

## Related Documentation
- [Countdown and Sync Optimization](./COUNTDOWN_AND_SYNC_OPTIMIZATION.md)
- [Firebase Setup](../setup/FIREBASE_SETUP.md)
- [Game Time Service](../systems/GAME_TIME_SYSTEM.md)
