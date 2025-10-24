# Money & Energy Real-Time Update Fix

## Issues Reported

1. **Money balance doesn't update in real-time** when paying for skills or completing jobs
2. **Energy consumption not clearly visible** when using skills
3. **Side hustle waiting times feel too long** for earning money
4. **Money doesn't decrease properly** when spent (only promotions update correctly)

## Root Cause Analysis

### The Real-Time Sync Race Condition

```
User spends $500 on practice
↓
Local state: $5000 → $4500 ✅ (UI updates immediately)
↓
Calls _debouncedSave() → waits 500ms
↓
Real-time listener receives Firebase snapshot (still shows $5000)
↓
Overwrites local state: $4500 → $5000 ❌ (UI reverts!)
↓
500ms later: Save completes, Firebase now has $4500
↓
Real-time listener receives new snapshot: $5000 → $4500
↓
UI finally shows correct value (but appeared to not work)
```

### Why This Happens

1. **Debounced Saves**: The `_debouncedSave()` function waits 500ms before saving
2. **Real-Time Listener**: Firebase snapshots listener receives old data during the delay
3. **No Optimistic Locking**: Listener blindly overwrites local state
4. **Cloud Function Delays**: `secureStatUpdate` adds network latency

## Solution Strategy

### Option A: Immediate Saves for Critical Actions ✅ RECOMMENDED
Make money/energy changes save immediately instead of debounced.

**Pros**:
- Simple implementation
- No race conditions
- Real-time updates guaranteed
- Works with existing real-time sync

**Cons**:
- More Firebase writes (but only for important actions)

### Option B: Optimistic UI with Timestamps
Track local changes with timestamps and ignore stale Firebase updates.

**Pros**:
- Fewer Firebase writes
- Better offline support

**Cons**:
- Complex implementation
- Can cause sync issues
- Harder to debug

### Option C: Disable Real-Time Sync During Local Changes
Pause the listener when making local changes.

**Pros**:
- Prevents overwrites

**Cons**:
- Can miss important server updates
- Complex state management
- Synchronization bugs

## Implementation Plan - Option A

### 1. Create Immediate Save Helper
Add direct Firebase update for critical stats:

```dart
Future<void> _immediateStatUpdate({
  int? money,
  int? energy,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (money != null) updates['currentMoney'] = money;
    if (energy != null) updates['energy'] = energy;

    if (updates.isEmpty) return;

    print('💾 Immediate stat update: $updates');

    await FirebaseFirestore.instance
        .collection('players')
        .doc(user.uid)
        .update(updates);

    print('✅ Stats saved immediately');
  } catch (e) {
    print('❌ Error saving stats immediately: $e');
  }
}
```

### 2. Update Practice Screen Callback
Make practice enrollment save immediately:

```dart
// In dashboard_screen_new.dart - Activity Hub navigation
onStatsUpdated: (updatedStats) {
  setState(() {
    artistStats = updatedStats;
  });
  // OLD: _debouncedSave();
  // NEW: Immediate save for money/energy changes
  _immediateStatUpdate(
    money: updatedStats.money,
    energy: updatedStats.energy,
  );
},
```

### 3. Add Real-Time Listener Guard
Prevent listener from overwriting recent local changes:

```dart
DateTime? _lastLocalUpdate;

// In real-time listener:
if (_lastLocalUpdate != null &&
    DateTime.now().difference(_lastLocalUpdate!) < Duration(seconds: 2)) {
  print('⏸️ Ignoring stale Firebase update (local change pending)');
  return;
}

// When making local changes:
setState(() {
  _lastLocalUpdate = DateTime.now();
  artistStats = updatedStats;
});
```

### 4. Update Side Hustle Completion
Make job completion money updates immediate:

```dart
// When side hustle completes
setState(() {
  artistStats = artistStats.copyWith(
    money: artistStats.money + payment,
  );
});

// Save immediately instead of debounced
_immediateStatUpdate(money: artistStats.money);
```

### 5. Add Visual Feedback
Show money/energy changes clearly:

```dart
void _showStatChange({
  int? moneyChange,
  int? energyChange,
}) {
  String message = '';
  IconData icon = Icons.info;
  Color color = Colors.white;

  if (moneyChange != null) {
    if (moneyChange > 0) {
      message = '+\$${moneyChange.abs()}';
      icon = Icons.attach_money;
      color = Colors.green;
    } else {
      message = '-\$${moneyChange.abs()}';
      icon = Icons.money_off;
      color = Colors.red;
    }
  }

  if (energyChange != null) {
    if (message.isNotEmpty) message += ' ';
    if (energyChange > 0) {
      message += '+${energyChange} ⚡';
      icon = Icons.battery_charging_full;
      color = Colors.green;
    } else {
      message += '${energyChange} ⚡';
      icon = Icons.battery_alert;
      color = Colors.orange;
    }
  }

  if (message.isNotEmpty) {
    _showMessage(message);
  }
}
```

## Energy System Clarification

### Current Energy Consumption
Based on code analysis:

| Action | Energy Cost |
|--------|-------------|
| Write Song | -15 to -40 (based on effort) |
| Practice - Songwriting Workshop | -10 ⚡ |
| Practice - Lyrics Masterclass | -15 ⚡ |
| Practice - Music Theory | -25 ⚡ |
| Practice - Creative Retreat | -20 ⚡ |
| Side Hustle (daily) | -8 to -30 ⚡/day |
| ViralWave Post | -10 to -30 ⚡ |
| Daily Restoration | +100 (if below 100) |

### Energy Display Improvements
1. Show energy cost before action
2. Flash energy indicator when consumed
3. Add animation for energy bar decrease
4. Show "Low Energy" warning at < 20

## Side Hustle Economy Rebalancing

### Current System
- Daily pay: $40-200
- Duration: 3-7 days
- Energy cost: 8-30/day
- Total earnings: $120-1,400 per contract

### Issues
- Waiting 3-7 in-game days feels slow
- Players need money for $500-$1000 practice courses
- Not enough active income sources

### Proposed Changes

#### Option 1: Reduce Waiting Times
- Shorten contracts to 1-3 days instead of 3-7 days
- Increase daily pay to compensate

#### Option 2: Add Quick Gigs
- New "Quick Gig" section with 1-day jobs
- Lower pay ($50-150) but instant
- Lower energy cost (5-10)
- Available daily

#### Option 3: Passive Income Boost
- Increase stream royalties
- Add merchandise sales
- Concert ticket sales (when implemented)

## Testing Checklist

### Money Updates
- [ ] Enroll in practice → money decreases immediately
- [ ] Complete side hustle → money increases immediately
- [ ] Spend on promotion → money decreases immediately
- [ ] Money display never reverts to old value
- [ ] Firebase console shows correct value within 1 second

### Energy Updates
- [ ] Practice enrollment → energy decreases immediately
- [ ] Write song → energy decreases based on effort
- [ ] Daily update → energy restores to 100
- [ ] Energy bar animates smoothly
- [ ] Low energy warning shows at < 20

### Real-Time Sync
- [ ] Local changes not overwritten by Firebase listener
- [ ] Changes visible immediately (no 500ms delay)
- [ ] Console shows "Immediate stat update" logs
- [ ] No race conditions between local and remote state

### Side Hustle System
- [ ] Job completion shows money earned
- [ ] Daily energy deduction visible
- [ ] Contract expiration shows notification
- [ ] Available jobs refresh daily

## Files to Modify

1. **lib/screens/dashboard_screen_new.dart**
   - Add `_immediateStatUpdate()` method
   - Add `_lastLocalUpdate` guard
   - Update Activity Hub navigation callback
   - Add stat change feedback

2. **lib/screens/practice_screen.dart**
   - Already deducts money/energy locally ✅
   - Already calls callback ✅
   - Add visual feedback for costs

3. **lib/services/firebase_service.dart**
   - Optional: Add direct stat update method
   - Skip Cloud Function for simple money/energy changes

## Priority Order

1. **HIGH**: Implement immediate saves for money/energy (fixes main issue)
2. **HIGH**: Add listener guard to prevent overwrites
3. **MEDIUM**: Add visual feedback for stat changes
4. **MEDIUM**: Improve energy cost visibility
5. **LOW**: Rebalance side hustle economy
6. **LOW**: Add quick gig system

## Notes

- The Cloud Function `secureStatUpdate` adds ~200-500ms latency
- For simple money/energy changes, direct Firestore update is faster
- Keep Cloud Function for complex operations (skills, songs, etc.)
- Real-time listener is essential for multiplayer, can't disable it
- Optimistic UI updates are the key to smooth UX

## Expected Outcome

After implementing immediate saves:
- ✅ Money updates instantly when spent/earned
- ✅ Energy updates instantly when consumed/restored
- ✅ No visual glitches or value reversions
- ✅ Real-time sync continues to work correctly
- ✅ Multiplayer compatibility maintained
