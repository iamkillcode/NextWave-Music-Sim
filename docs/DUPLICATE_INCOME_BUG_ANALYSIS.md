# Duplicate Income Bug - Analysis & Fix

## Date
October 20, 2025

## Issue Report
**User Report**: "I think players get money from somewhere aside the royalties after each turn or royalties are being duplicated."

## Investigation

### Money Sources Discovered

I found **THREE** separate systems calculating and adding streaming income:

#### 1. ✅ Cloud Function - `dailyGameUpdate` (LEGITIMATE)
**File**: `functions/index.js` (Lines 26-480)  
**Trigger**: Scheduled every hour (`0 * * * *`)  
**Purpose**: Server-side authoritative game progression

**What it does:**
```javascript
// For each player's released songs:
const dailyStreams = calculateDailyStreamGrowth(song, playerData, currentGameDate);
const songIncome = calculateSongIncome(song, dailyStreams);
totalNewIncome += songIncome;

// Then updates player money:
currentMoney: (playerData.currentMoney || 0) + totalNewIncome,
```

**This is CORRECT** - Server should be the source of truth.

---

#### 2. ⚠️ Client Passive Income - `_calculatePassiveIncome` (DUPLICATE?)
**File**: `lib/screens/dashboard_screen_new.dart` (Lines 1040-1138)  
**Trigger**: Called every 60+ seconds while dashboard is active  
**Purpose**: Real-time passive income display

**What it does:**
```dart
// Calculates streams per second based on quality/fame/fanbase
final scaledStreams = baseStreamsPerSecond * fameFactor * fanbaseFactor;
final streamsGained = (scaledStreams * realSecondsPassed).round();

// Calculates income from those streams
incomeForThisSong += streamsGained * 0.003; // Tunify
incomeForThisSong += streamsGained * 0.01;  // Maple Music

// Updates local money
artistStats = artistStats.copyWith(
  money: artistStats.money + totalIncome.round(),
);
```

**Problem**: This adds money locally BUT doesn't seem to save to Firebase directly. However, if the dashboard calls `_debouncedSave()` or `_immediateSave()` after this, **the inflated money gets saved**, duplicating the Cloud Function's income.

---

#### 3. ❌ Client Daily Growth - `_applyDailyStreamGrowth` (DEFINITE DUPLICATE!)
**File**: `lib/screens/dashboard_screen_new.dart` (Lines 1140-1386)  
**Trigger**: When game day changes (detected by `_updateGameTimer()`)  
**Purpose**: Client-side calculation of daily stream growth

**What it does:**
```dart
// For each released song:
final newStreams = _streamGrowthService.calculateDailyStreamGrowth(
  song: song,
  artistStats: artistStats,
  currentGameDate: currentGameDate,
);

// Calculates income AGAIN
int songIncome = 0;
for (final platform in song.streamingPlatforms) {
  if (platform == 'tunify') {
    songIncome += (newStreams * 0.85 * 0.003).round();
  } else if (platform == 'maple_music') {
    songIncome += (newStreams * 0.65 * 0.01).round();
  }
}
totalNewIncome += songIncome;

// Updates money AGAIN
artistStats = artistStats.copyWith(
  money: artistStats.money + totalNewIncome,
);

// And SAVES it to Firebase!
_debouncedSave(); // Line 1368
```

**This is 100% a DUPLICATE!** The Cloud Function already calculated this daily income and saved it. The client is:
1. Re-calculating the same daily streams
2. Re-calculating the same income
3. Adding it to the money again
4. Saving it to Firebase

**Result**: Players get DOUBLE the streaming income!

---

### The Flow (Showing the Bug)

**Hour 0** (Game starts):
- Player has $1000
- 1 released song

**Hour 1** (Cloud Function runs):
- Cloud Function calculates: +100 streams, +$3 income
- Saves to Firebase: `currentMoney: 1003`
- Player dashboard reloads, shows $1003 ✅

**Hour 1** (Player opens dashboard):
- Game timer detects day changed
- `_applyDailyStreamGrowth()` runs
- Client calculates: +100 streams (SAME calculation!), +$3 income (DUPLICATE!)
- Updates local state: `money: 1003 + 3 = 1006`
- Calls `_debouncedSave()`
- Saves to Firebase: `currentMoney: 1006` ❌

**Result**: Player got $6 instead of $3! (200% income)

---

### Additional Issue: Passive Income

The `_calculatePassiveIncome()` function runs continuously (every 60 seconds) and adds money locally. If this local money is saved before the Cloud Function runs, it creates **additional** duplicate income.

**Example**:
- Hour starts: $1000
- Passive income (30 sec): +$1 → $1001 (saved)
- Passive income (30 sec): +$1 → $1002 (saved)
- Cloud Function (hour end): +$3 → $1005 (should be $1003)
- Daily growth (client): +$3 → $1008 (DUPLICATE!)

**Total**: $1008 instead of $1003 (5x too much!)

---

## Root Cause

**Architecture Confusion**: The game has BOTH server-authoritative (Cloud Function) AND client-calculated income systems running simultaneously.

**Original Intent** (probably):
- Cloud Function: Calculate income every hour
- Client Passive Income: Show **estimated** income in real-time for UX
- Client Daily Growth: Show **growth summary** when day changes

**What Actually Happens**:
- Cloud Function: Calculates and SAVES income ✅
- Client Passive Income: Calculates and SAVES income ❌ (should be display-only)
- Client Daily Growth: Calculates and SAVES income ❌ (should read from Cloud Function)

---

## Impact

### Severity: CRITICAL
- **Affects**: All players with released songs
- **Magnitude**: 200%-500% more income than intended
- **Economy**: Game balance completely broken
- **Progression**: Players advance way too fast
- **Motivation**: Reduces sense of accomplishment

### Who is Affected
- ✅ Players with 0 released songs: Not affected
- ❌ Players with 1+ released songs: Getting 2-5x income
- ❌ Players who idle: Getting passive income + cloud income
- ❌ Active players: Getting triple income (passive + daily + cloud)

### Example Impact
**Intended**: 1 hit song → $100/day → $3000/month  
**Actual**: 1 hit song → $300-500/day → $9,000-15,000/month

---

## Solution

### Option 1: Server-Only Income (RECOMMENDED)
**Remove all client-side income calculations**

#### Changes Required:

**1. Remove `_applyDailyStreamGrowth()` income calculation**
```dart
// DELETE lines 1195-1209 (income calculation)
// DELETE line 1322 (money update)
// KEEP stream/fanbase/fame updates (non-financial stats)

void _applyDailyStreamGrowth(DateTime currentGameDate) {
  // Keep: Stream growth calculations
  // Keep: Fanbase/fame growth
  // Keep: Regional distribution
  // DELETE: Income calculation
  // DELETE: Money update
  
  // Instead: Show notification about streams gained
  // Money will be updated by Cloud Function
}
```

**2. Make `_calculatePassiveIncome()` display-only**
```dart
// Change to NOT update artistStats.money
// Instead: Calculate and show estimated income in UI
// The actual money comes from Cloud Function

void _calculatePassiveIncome(int realSecondsPassed) {
  // Calculate estimated income for UI display
  final estimatedIncome = /* calculation */;
  
  // DON'T update money:
  // artistStats = artistStats.copyWith(money: ...) ❌
  
  // Instead: Show in UI only
  setState(() {
    _estimatedPassiveIncome = estimatedIncome;
  });
}
```

**3. Add income display widget**
```dart
// Show estimated passive income without actually adding it
Text('Estimated: +\$${_estimatedPassiveIncome.toStringAsFixed(2)}/min')
```

**4. Reload from Firebase after day change**
```dart
// After detecting day change, reload stats from Firebase
if (newGameDate.day != currentGameDate!.day) {
  // Cloud Function has already run, reload fresh data
  await _loadPlayerStats();
  setState(() {
    currentGameDate = newGameDate;
  });
}
```

---

### Option 2: Client-Only Income (NOT RECOMMENDED)
**Remove Cloud Function income, keep client calculations**

**Why NOT recommended:**
- Client can be manipulated (cheating)
- Multiple tabs/devices cause conflicts
- No server validation
- Offline players miss income

---

### Option 3: Hybrid (COMPLEX)
**Keep both but prevent duplicates**

**Approach:**
- Cloud Function calculates income
- Client checks `lastStreamUpdateDate` before calculating
- Client only fills gaps between Cloud Function runs

**Why COMPLEX:**
- Requires perfect synchronization
- Race conditions possible
- More bug-prone
- Not worth the complexity

---

## Recommended Fix: Option 1

### Step 1: Remove Client Income Calculation

**File**: `lib/screens/dashboard_screen_new.dart`

**Change 1**: Remove income calculation from `_applyDailyStreamGrowth()`
```dart
// DELETE this section (lines ~1195-1209):
// Calculate income from new streams (pay artists daily royalties)
int songIncome = 0;
for (final platform in song.streamingPlatforms) {
  if (platform == 'tunify') {
    songIncome += (newStreams * 0.85 * 0.003).round();
  } else if (platform == 'maple_music') {
    songIncome += (newStreams * 0.65 * 0.01).round();
  }
}
totalNewIncome += songIncome;
```

**Change 2**: Remove money update from `_applyDailyStreamGrowth()`
```dart
// CHANGE this (line ~1322):
artistStats = artistStats.copyWith(
  songs: updatedSongs,
  money: artistStats.money + totalNewIncome, // ❌ DELETE THIS LINE
  energy: ...,
  fanbase: ...,
);

// TO this:
artistStats = artistStats.copyWith(
  songs: updatedSongs, // Keep song updates
  energy: ..., // Keep energy updates
  fanbase: ..., // Keep fanbase updates
  fame: ..., // Keep fame updates
  loyalFanbase: ..., // Keep loyal fans
  // Money is handled by Cloud Function
);
```

**Change 3**: Reload stats from Firebase after day change
```dart
// ADD after detecting day change (line ~995):
if (newGameDate.day != currentGameDate!.day) {
  print('🌅 Day changed! Reloading stats from server...');
  
  // Cloud Function has already updated streams and money
  await _loadPlayerStats();
  
  // Update passive income display
  _calculatePassiveIncome(realSecondsSinceLastUpdate);
  
  // Continue with energy replenishment...
}
```

**Change 4**: Make passive income display-only
```dart
// CHANGE _calculatePassiveIncome() to NOT update money
void _calculatePassiveIncome(int realSecondsPassed) {
  // ... existing calculation logic ...
  
  // DON'T update artistStats.money:
  // setState(() {
  //   artistStats = artistStats.copyWith(
  //     money: artistStats.money + totalIncome.round(), // ❌ DELETE
  //   );
  // });
  
  // Instead: Just show the estimated income
  setState(() {
    _estimatedPassiveIncome = totalIncomePerSecond;
  });
  
  // Show notification (optional)
  if (totalIncome >= 100 && ...) {
    _addNotification(
      'Streaming Activity',
      'Estimated earnings: \$${totalIncome.toStringAsFixed(0)} from $totalStreamsGained streams!',
      icon: Icons.music_note,
    );
  }
}
```

---

### Step 2: Add State Variable

```dart
// Add to _DashboardScreenNewState:
double _estimatedPassiveIncome = 0.0;
```

---

### Step 3: Update UI to Show Estimated Income

```dart
// Add widget to show estimated passive income:
Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.green.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(Icons.trending_up, color: Colors.green, size: 16),
      SizedBox(width: 8),
      Text(
        'Streaming: ~\$${_estimatedPassiveIncome.toStringAsFixed(2)}/min',
        style: TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  ),
)
```

---

### Step 4: Test the Fix

**Test Scenario 1: Single Session**
1. Start with $1000
2. Release a song
3. Wait for Cloud Function to run (1 hour)
4. Check money: Should be $1000 + income (e.g., $1003)
5. Verify no duplication

**Test Scenario 2: Day Change**
1. Note starting money
2. Wait for day to change
3. Verify money updated ONCE (by Cloud Function)
4. Verify streams updated
5. Verify no client-side money addition

**Test Scenario 3: Passive Income Display**
1. Open dashboard
2. Watch passive income estimate update
3. Verify it's just a display
4. Reload page
5. Verify money didn't change from estimate

---

## Prevention

### Code Review Checklist
When adding new income sources:
- [ ] Is this income also calculated server-side?
- [ ] Does this create a duplicate with Cloud Functions?
- [ ] Should this be display-only?
- [ ] Is the save operation necessary?

### Architecture Guidelines
1. **Server is Source of Truth**: All financial transactions must go through Cloud Functions
2. **Client is Display Only**: UI can show estimates, but shouldn't modify money
3. **Reload After Major Events**: After day changes, reload from server
4. **Debounce Saves**: Don't save after every calculation
5. **Log Everything**: Print statements for debugging income sources

---

## Testing Checklist

After implementing fix:
- [ ] Cloud Function income works
- [ ] Client doesn't duplicate income
- [ ] Passive income is display-only
- [ ] Day change reloads from server
- [ ] Multiple tabs don't cause conflicts
- [ ] Money balance makes sense
- [ ] No negative money
- [ ] No excessive money gains

---

## Migration Plan

### For Existing Players

**Option A: No Retroactive Action** (RECOMMENDED)
- Deploy fix silently
- Players keep existing inflated money
- Future income will be correct
- Economy balances out over time

**Option B: Money Reset**
- Calculate "expected" money based on song history
- Reset all players to expected amount
- Risks: Data loss, player backlash
- NOT RECOMMENDED

**Option C: Partial Correction**
- Reduce money by 50% for players with >$100k
- Announce as "economy rebalance"
- Give compensation (e.g., free items)
- Moderate approach

---

## Estimated Impact of Fix

### Before Fix (Current State)
- Player with 1 hit song: $300-500/day
- Player with 5 songs: $1500-2500/day
- Player with 10 songs: $3000-5000/day
- Mega star: $10,000-50,000/day

### After Fix (Correct State)
- Player with 1 hit song: $100-150/day
- Player with 5 songs: $500-750/day
- Player with 10 songs: $1000-1500/day
- Mega star: $3,000-10,000/day

**Income Reduction**: 60-70% (back to intended values)

---

## Related Issues

- Anti-cheat system should flag rapid money growth
- Consider adding income logging for debugging
- Review all other stat updates for similar duplicates
- Document client vs server responsibilities

---

## Deployment Plan

1. ✅ Document the bug (this file)
2. ⏳ Implement client-side changes (remove duplicate calculations)
3. ⏳ Test in development
4. ⏳ Deploy to production
5. ⏳ Monitor player money growth for 24-48 hours
6. ⏳ Adjust if needed

---

## Status

**Discovery Date**: October 20, 2025  
**Status**: Documented, awaiting implementation  
**Priority**: HIGH (game economy broken)  
**Complexity**: Medium (requires careful state management)  
**Risk**: Low (fix is mostly removal of code)

