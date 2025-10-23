# 🚨 URGENT: Energy Not Restoring - Firebase Setup Required

## ⚠️ Problem

Players are complaining that energy is not restoring after each in-game day. The code is already deployed and ready, but **Firebase Remote Config parameters are missing**.

## 🔧 The Fix (2 Minutes)

### Step 1: Open Firebase Console
1. Go to: https://console.firebase.google.com
2. Select your **NextWave** project (`nextwave-music-sim`)
3. Click **Remote Config** in left sidebar (under "Engage" section)

### Step 2: Add Energy Fix Parameters

#### Parameter 1: Enable the Fix
```
Click "Add parameter"

Parameter key:     enable_energy_restore_fix
Data type:         Boolean
Default value:     ✓ true  (check the box)
Description:       Enable automatic energy restoration each game day
```

Click **Save**

#### Parameter 2: Energy Amount
```
Click "Add parameter"

Parameter key:     energy_restore_amount  
Data type:         Number
Default value:     100
Description:       Amount of energy to restore daily
```

Click **Save**

### Step 3: Publish Changes
```
Click big orange "Publish changes" button at top
Confirm publish
```

## ✅ Verification

After publishing, you should see:
- Status: "Published" (green checkmark)
- Last published: [Current timestamp]
- Two parameters in the list with correct values

## 📱 Player Impact

**Timeline:**
- ✓ Fix goes live: Within 1 hour for active players
- ✓ Next app open: All other players get the fix
- ✓ No app update required!

**What Players Will See:**
```
Old: "Energy stuck at low value"
New: "☀️ New day! Energy restored to 100"
```

## 🔍 Why This Happened

The code for the energy fix was deployed in earlier updates:
- ✓ `RemoteConfigService` has the getters
- ✓ `DashboardScreen` uses Remote Config values
- ✓ Energy restoration logic is implemented

But the **actual Remote Config values were never set in Firebase Console**, so the fix couldn't activate.

## 🎯 Technical Details

### Current Code (Already Deployed)
```dart
// dashboard_screen_new.dart - Line ~1213
final int energyRestoreAmount = _remoteConfig.energyRestoreAmount;
final bool enableFix = _remoteConfig.enableEnergyRestoreFix;

final restoredEnergy = enableFix
    ? (artistStats.energy < energyRestoreAmount
        ? energyRestoreAmount
        : artistStats.energy)
    : 100;

artistStats = artistStats.copyWith(
  energy: restoredEnergy,
);
```

### Remote Config Default (Code-Side)
```dart
// remote_config_service.dart - Line ~48
'enable_energy_restore_fix': true,
'energy_restore_amount': 100,
```

However, **code-side defaults may not apply** if Remote Config fetch fails or is blocked. Setting values in Firebase Console ensures they're always available.

## 🚀 Alternative: Quick Test

To test if Remote Config is the issue, you can check the Firebase Console:
1. Go to Remote Config
2. If you see 0 parameters → **This is the problem**
3. Add the two parameters above
4. Publish
5. Wait 5-10 minutes
6. Players' energy should start restoring

## 📊 Monitoring After Fix

Check Firebase Analytics for:
- `remote_config_fetch_success` events
- Player retention improvement
- Energy-related support tickets (should decrease)

---

**Status**: 🔴 URGENT - Players Affected  
**Fix Time**: 2 minutes  
**Impact**: Immediate relief for all active players  

