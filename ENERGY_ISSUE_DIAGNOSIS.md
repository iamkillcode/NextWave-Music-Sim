# 🔋 Energy Not Restoring - Complete Diagnosis & Fix

## 🔴 Issue Summary

**Problem:** Players report energy is not restoring after each in-game day (1 real hour)

**Expected:** Energy should restore to 100 every game day  
**Actual:** Energy remains low/stuck  
**Impact:** Players cannot perform actions, gameplay blocked

---

## 🔍 Root Cause Analysis

### What We Know

1. ✅ **Code is deployed and correct**
   - Energy restoration logic exists in `dashboard_screen_new.dart`
   - Uses Remote Config for flexibility (`enable_energy_restore_fix`, `energy_restore_amount`)
   - Falls back to hardcoded 100 if Remote Config disabled
   - Called every 5 minutes via `gameTimer`

2. ❌ **Firebase Remote Config NOT set up**
   - Parameters missing from Firebase Console
   - Code tries to fetch values but gets defaults
   - Default behavior may not be applying correctly

3. ✅ **Cloud Functions upgraded**
   - Now using Node.js 20 (was Node.js 18)
   - All functions deployed successfully
   - No deprecation warnings

### Code Flow

```
Every 5 minutes:
  _updateGameDate() 
    → getCurrentGameDate() from Firebase
    → Compare with currentGameDate
    → If day changed:
        - Reload player stats from server
        - Get Remote Config values
        - Restore energy based on config
        - Update UI
```

### Why Remote Config Matters

```dart
// Current code (dashboard_screen_new.dart ~line 1213)
final int energyRestoreAmount = _remoteConfig.energyRestoreAmount;
final bool enableFix = _remoteConfig.enableEnergyRestoreFix;

final restoredEnergy = enableFix
    ? (artistStats.energy < energyRestoreAmount
        ? energyRestoreAmount
        : artistStats.energy)
    : 100; // Always restore to 100 minimum
```

**Problem:** If `enableFix` is false or `energyRestoreAmount` is 0 due to missing config, energy won't restore properly.

---

## 🎯 Solution (Choose One)

### Option 1: Setup Remote Config (RECOMMENDED) ⭐

**Time:** 2 minutes  
**Impact:** Allows dynamic control without app updates  
**Steps:** See `URGENT_ENERGY_FIX_SETUP.md`

1. Open Firebase Console → Remote Config
2. Add parameter: `enable_energy_restore_fix` = `true` (Boolean)
3. Add parameter: `energy_restore_amount` = `100` (Number)
4. Publish changes
5. Wait 5-10 minutes for players to fetch

**Pros:**
- ✅ Can adjust energy amount without code changes
- ✅ Can A/B test different values
- ✅ Can disable if issues arise
- ✅ No app store review needed

**Cons:**
- ⏰ Takes 5-10 minutes to propagate
- 📱 Requires active internet connection

---

### Option 2: Simplify Code (Remove Remote Config Dependency)

**Time:** 5 minutes + deployment  
**Impact:** Guaranteed to work, loses flexibility  

**Change Required:**

```dart
// dashboard_screen_new.dart ~line 1213
// REPLACE THIS:
final int energyRestoreAmount = _remoteConfig.energyRestoreAmount;
final bool enableFix = _remoteConfig.enableEnergyRestoreFix;

final restoredEnergy = enableFix
    ? (artistStats.energy < energyRestoreAmount
        ? energyRestoreAmount
        : artistStats.energy)
    : 100;

// WITH THIS:
final restoredEnergy = artistStats.energy < 100 ? 100 : artistStats.energy;
```

**Pros:**
- ✅ Guaranteed to work
- ✅ No external dependencies
- ✅ Simpler code

**Cons:**
- ❌ Requires app update
- ❌ App store review (1-7 days)
- ❌ Can't adjust values remotely

---

### Option 3: Fix Remote Config Service Defaults

**Time:** 3 minutes + deployment  
**Impact:** Ensures fallback works correctly  

**Change Required:**

```dart
// lib/services/remote_config_service.dart
bool get enableEnergyRestoreFix =>
      _getBool('enable_energy_restore_fix', defaultValue: true); // ADD defaultValue

int get energyRestoreAmount =>
      _getInt('energy_restore_amount', defaultValue: 100); // ADD defaultValue
```

Check if these already have `defaultValue` parameters. If not, add them.

**Pros:**
- ✅ Works even if Remote Config fetch fails
- ✅ Keeps flexibility
- ✅ Quick fix

**Cons:**
- ❌ Still requires app update
- ❌ App store review needed

---

## 🚀 Recommended Action Plan

### Phase 1: Immediate (Today) - Setup Remote Config ⏰ 2 min

1. Go to Firebase Console
2. Setup Remote Config parameters (see `URGENT_ENERGY_FIX_SETUP.md`)
3. Publish
4. Monitor player feedback over next hour

**Expected Result:** Energy restoration starts working within 1 hour for active players

---

### Phase 2: Long-term (Next Update) - Code Improvements

If Option 1 fixes the issue:
1. ✅ Keep Remote Config (it's working!)
2. Add better error logging
3. Add analytics to track energy restoration events
4. Consider showing debug info in settings for testing

If Option 1 doesn't fix it:
1. Implement Option 2 or 3
2. Remove Remote Config dependency
3. Submit app update

---

## 📊 Monitoring

After deploying Remote Config:

### Firebase Console
- Check Remote Config fetch events in Analytics
- Look for `remote_config_fetch_success` events
- Monitor active users (should stay stable or increase)

### Player Feedback Channels
- Discord/Support: Watch for energy complaints
- App reviews: Monitor for "energy bug" mentions
- In-game analytics: Track daily active users

### Debug Logs (if you have test build)
Look for this output in console:
```
🌅 Day changed! Old: 15 → New: 16
🔄 Reloading player stats from server...
🔋 Energy restoration: 30 → 100 (fix: true, amount: 100)
✅ Energy restored - Game Date: Oct 16, 2025
```

If you see:
- `fix: false` → Remote Config not fetching correctly
- `amount: 0` → Parameter not set in Firebase
- `30 → 30` → Logic not applying (code bug)

---

## 🧪 Testing Checklist

### Before Fix
- [ ] Player energy stuck at low value (e.g., 15)
- [ ] Wait 1 real hour (1 game day)
- [ ] Energy still at 15 (not restored)

### After Remote Config Setup
- [ ] Wait 10 minutes (config propagation)
- [ ] Close and reopen app (force config fetch)
- [ ] Wait 1 real hour (1 game day)
- [ ] Energy should restore to 100
- [ ] Notification: "☀️ New day! Energy restored to 100"

### Edge Cases
- [ ] Player has > 100 energy (shouldn't decrease)
- [ ] Player has side hustle (energy should still restore)
- [ ] Player offline for 3 days (should restore on login)

---

## 🔄 Related Files

- `lib/screens/dashboard_screen_new.dart` - Main energy restoration logic
- `lib/services/remote_config_service.dart` - Remote Config getters
- `lib/services/game_time_service.dart` - Game date calculation
- `functions/index.js` - Server-side daily updates
- `URGENT_ENERGY_FIX_SETUP.md` - Quick setup guide
- `QUICK_DEPLOY_ENERGY_FIX.md` - Original deployment guide

---

## 📝 Timeline

**Oct 14, 2025:** Energy restoration confirmed working (see `docs/archive/DASHBOARD_UPDATES.md`)  
**Oct 23, 2025:** Players report energy not restoring  
**Oct 23, 2025:** Diagnosed as missing Remote Config parameters  
**Oct 23, 2025:** Created comprehensive fix guide  
**Oct 23, 2025:** Upgraded Cloud Functions to Node.js 20  

---

## ✅ Success Criteria

1. **No more player complaints** about energy not restoring
2. **Debug logs show** energy restoration working
3. **Analytics show** normal player engagement (1 hour sessions)
4. **Player retention** remains stable or improves

---

**Next Step:** Setup Remote Config parameters in Firebase Console (2 minutes)  
**See:** `URGENT_ENERGY_FIX_SETUP.md` for step-by-step instructions

