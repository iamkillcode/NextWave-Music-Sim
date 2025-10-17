# Quick Reference: When to Save

## Developer Guide for Firebase Saves

### 🔴 Use `_immediateSave()` for:
Critical multiplayer events that affect other players immediately.

```dart
// Publishing content visible to others
onStatsUpdated: (updatedStats) {
  setState(() => artistStats = updatedStats);
  _immediateSave(); // Other players need to see this now
}
```

**Examples:**
- 🎵 Publishing/releasing songs
- 💿 Releasing albums
- 🌍 Changing regions/locations
- 🏆 Major achievements/milestones
- 🎤 Starting/ending concerts
- 📻 Radio/streaming platform changes
- 👥 Joining/leaving collaborations

---

### 🟡 Use `_debouncedSave()` for:
Frequent UI interactions that can wait 500ms without impact.

```dart
// Rapid stat changes from gameplay
onStatsUpdated: (updatedStats) {
  setState(() => artistStats = updatedStats);
  _debouncedSave(); // Will batch if multiple changes happen quickly
}
```

**Examples:**
- 💰 Money earned/spent
- ⚡ Energy consumed/restored
- 📊 Skill XP gained
- 🎯 Fame/reputation changes
- 📱 Social media posts/interactions
- 💡 Creativity/inspiration changes
- 🎮 General gameplay stats

---

### 🟢 Auto-Save Handles:
Background sync happens automatically every 30 seconds.

**No code needed - just make sure to call either `_immediateSave()` or `_debouncedSave()`!**

**Handles:**
- 🎧 Passive streaming income
- 📈 Automated fan growth
- ⏰ Time-based progression
- 🔄 Catching any missed saves

---

## Code Examples

### Example 1: Music Hub (Immediate Save)
```dart
// Music Hub - songs are critical multiplayer content
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MusicHubScreen(
      artistStats: artistStats,
      onStatsUpdated: (updatedStats) {
        setState(() {
          artistStats = updatedStats;
        });
        _immediateSave(); // ← Songs need instant sync
      },
    ),
  ),
);
```

### Example 2: Activity Hub (Debounced Save)
```dart
// Activity Hub - side hustles can wait 500ms
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ActivityHubScreen(
      artistStats: artistStats,
      onStatsUpdated: (updatedStats) {
        setState(() {
          artistStats = updatedStats;
        });
        _debouncedSave(); // ← Batches rapid energy/money changes
      },
      currentGameDate: currentGameDate ?? DateTime.now(),
    ),
  ),
);
```

### Example 3: Settings (Immediate Save)
```dart
// Settings - important changes should save immediately
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SettingsScreen(
      artistStats: artistStats,
      onStatsUpdated: (updatedStats) {
        setState(() {
          artistStats = updatedStats;
        });
        _immediateSave(); // ← Settings changes are important
      },
    ),
  ),
);
```

---

## Decision Tree

```
Is this visible to other players?
│
├── YES → Will they notice a 30-second delay?
│   │
│   ├── YES (songs, achievements, regions)
│   │   └── Use _immediateSave()
│   │
│   └── NO (social posts, profile updates)
│       └── Use _debouncedSave()
│
└── NO → Is it a rapid/repeated action?
    │
    ├── YES (clicking buttons, grinding)
    │   └── Use _debouncedSave()
    │
    └── NO (one-time important change)
        └── Use _immediateSave()
```

---

## Common Patterns

### Pattern 1: Navigation with Callback
```dart
onStatsUpdated: (updatedStats) {
  setState(() {
    artistStats = updatedStats;
  });
  _immediateSave(); // or _debouncedSave()
}
```

### Pattern 2: Direct State Update
```dart
setState(() {
  artistStats = artistStats.copyWith(
    money: artistStats.money - cost,
  );
});
_debouncedSave(); // Money changes can be batched
```

### Pattern 3: After Async Operation
```dart
await someLongOperation();
setState(() {
  artistStats = updatedStats;
});
_immediateSave(); // Save important result immediately
```

---

## Performance Impact

| Save Type | Delay | Multiplayer Sync | Cost Impact | Use Cases |
|-----------|-------|------------------|-------------|-----------|
| **Immediate** | 0ms | Instant | Low (rare events) | Critical content |
| **Debounced** | 500ms | Very fast | Low (batched) | UI interactions |
| **Auto-save** | 0-30s | Background | Medium (regular) | Passive progress |

---

## Tips & Best Practices

### ✅ DO:
- Use `_immediateSave()` for player-visible content
- Use `_debouncedSave()` for stat changes
- Let auto-save handle passive income
- Check console logs to verify save frequency
- Test multi-device sync for critical features

### ❌ DON'T:
- Mix immediate and debounced for the same stat type
- Call `_saveUserProfile()` directly (use helpers)
- Forget to save after important operations
- Over-use immediate saves (increases costs)
- Save on every tiny UI update

---

## Monitoring

### Console Logs to Watch:
```
💾 Saving user profile for: [uid]
✅ Profile saved successfully
🔄 Auto-save: Syncing with Firebase for multiplayer...
```

### Firebase Console:
1. Go to Firebase Console → Firestore → Usage
2. Monitor "Document Writes" metric
3. Aim for: 100-200 writes/hour during active play
4. Alert if: >500 writes/hour (over-saving)

---

## Troubleshooting

### Problem: Changes not syncing to other devices
**Solution:** Check if you're using `_immediateSave()` for critical events

### Problem: Too many Firebase writes
**Solution:** Replace `_immediateSave()` with `_debouncedSave()` for non-critical stats

### Problem: Data loss on app close
**Solution:** The dispose() method already flushes pending saves - no action needed

### Problem: Multiplayer feels laggy
**Solution:** Increase auto-save frequency (reduce from 30s to 15s)

---

## Related Files
- Implementation: `lib/screens/dashboard_screen_new.dart`
- Full strategy: `docs/features/MULTIPLAYER_SYNC_STRATEGY.md`
- Summary: `docs/fixes/FEATURES_AND_FIXES_SUMMARY.md`
