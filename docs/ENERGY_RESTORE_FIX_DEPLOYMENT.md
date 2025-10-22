# Energy Restoration Fix - Remote Config Deployment Guide

## 🔧 Issue Description
**Problem:** Players report that energy is not restoring after one in-game day passes.

**Root Cause:** The energy restoration logic was working, but there may be edge cases where:
1. The day change detection isn't triggering properly
2. Energy restoration is being overridden by other operations
3. Timezone differences causing sync issues

**Solution:** Implemented a Remote Config-based fix that allows us to:
- Toggle the energy restoration behavior without app updates
- Adjust the energy restore amount dynamically
- Monitor and fix the issue in real-time

## 📋 Changes Made

### 1. Remote Config Service (`lib/services/remote_config_service.dart`)
Added two new parameters:
- `enable_energy_restore_fix` (boolean, default: `true`) - Toggle the fix on/off
- `energy_restore_amount` (integer, default: `100`) - Amount to restore daily

### 2. Dashboard Screen (`lib/screens/dashboard_screen_new.dart`)
Updated `_updateGameDate()` method to:
- Use Remote Config values for energy restoration
- Apply conditional logic based on `enable_energy_restore_fix`
- Use `energy_restore_amount` from Remote Config instead of hardcoded 100

### 3. Configuration Template
Created `remote_config_template.json` with all current Remote Config parameters.

## 🚀 Deployment Steps

### Step 1: Upload Remote Config to Firebase Console

1. **Navigate to Firebase Console:**
   - Go to https://console.firebase.google.com
   - Select your NextWave project

2. **Open Remote Config:**
   - In left sidebar, click **"Remote Config"** under "Engage"

3. **Add New Parameters (if not already exists):**

   **Parameter 1: `enable_energy_restore_fix`**
   - Click **"Add parameter"**
   - Parameter key: `enable_energy_restore_fix`
   - Data type: **Boolean**
   - Default value: `true`
   - Description: "Enable the energy restoration fix for daily resets"
   - Click **"Save"**

   **Parameter 2: `energy_restore_amount`**
   - Click **"Add parameter"**
   - Parameter key: `energy_restore_amount`
   - Data type: **Number**
   - Default value: `100`
   - Description: "Amount of energy to restore each day (default: 100)"
   - Click **"Save"**

4. **Publish Changes:**
   - Click **"Publish changes"** button at the top
   - Confirm the publication

### Step 2: Test the Fix (Optional Before Full Rollout)

**Create a Condition for Beta Testers:**
1. In Remote Config, click **"Add condition"**
2. Name: "Beta Testers"
3. Rule: `User in random percentile <= 10%` (10% of users)
4. For `enable_energy_restore_fix`, set condition value to `true`
5. For `energy_restore_amount`, set condition value to `100`
6. Publish and monitor for 24-48 hours

### Step 3: Verify Deployment

**Check that config is live:**
1. In Firebase Console Remote Config, verify status shows "Published"
2. Check "Last published" timestamp

**Test in app (if you have test build):**
1. Open the app
2. Remote Config should fetch new values within 1 hour (or on app restart)
3. Verify energy restores properly after in-game day change

### Step 4: Monitor & Adjust

**If fix works:**
- Leave `enable_energy_restore_fix = true`
- Keep `energy_restore_amount = 100`

**If you need to adjust:**
- Change `energy_restore_amount` to different value (e.g., 150 for testing)
- Or disable temporarily with `enable_energy_restore_fix = false`

**If you need to rollback:**
- Set `enable_energy_restore_fix = false` (reverts to legacy behavior)
- Investigate further and re-enable when ready

## 🎯 How It Works

### Before (Hardcoded):
```dart
final restoredEnergy = artistStats.energy < 100 ? 100 : artistStats.energy;
```

### After (Remote Config):
```dart
final int energyRestoreAmount = _remoteConfig.energyRestoreAmount; // Can be changed remotely
final bool enableFix = _remoteConfig.enableEnergyRestoreFix; // Can toggle fix on/off

final restoredEnergy = enableFix
    ? (artistStats.energy < energyRestoreAmount
        ? energyRestoreAmount
        : artistStats.energy)
    : 100; // Legacy behavior if fix is disabled
```

## 🔍 Troubleshooting

### Issue: Config not updating in app
**Solution:**
- Remote Config has 1-hour minimum fetch interval
- Users need to restart app or wait for automatic refresh
- You can lower `minimumFetchInterval` in code for faster testing (not recommended for production)

### Issue: Need immediate fix
**Solution:**
- Set `enable_energy_restore_fix = true` and `energy_restore_amount = 100` in Firebase
- Users will get fix within 1 hour or on next app restart
- No app update required!

### Issue: Want to test different energy amounts
**Solution:**
- Change `energy_restore_amount` to 150, 200, etc. in Firebase Console
- Monitor player feedback
- Adjust back to 100 if needed

## 📊 Monitoring

After deployment, monitor:
1. **Player Complaints:** Should decrease about energy not restoring
2. **Remote Config Fetch Success:** Check Firebase Analytics for config fetch events
3. **User Retention:** Verify fix doesn't negatively impact retention

## 🎉 Benefits of This Approach

✅ **Instant Fix:** No app store review needed (fix goes live within 1 hour)
✅ **Rollback Safety:** Can disable fix instantly if issues arise
✅ **A/B Testing:** Can test different energy amounts with different user groups
✅ **Flexibility:** Adjust energy economy without code changes
✅ **Backward Compatible:** Existing users automatically get the fix

## 📝 Future Enhancements

Consider adding these Remote Config parameters in the future:
- `energy_restore_time_utc` - Specific time when energy restores (e.g., "00:00")
- `energy_restore_on_login` - Also restore energy on first login of the day
- `max_energy_cap` - Maximum energy a player can have (for balancing gifts)
- `energy_restore_notification` - Send notification when energy is restored

## 🚨 Emergency Procedures

**If the fix causes issues:**

1. **Immediate Disable:**
   ```
   Firebase Console > Remote Config > enable_energy_restore_fix > Set to false > Publish
   ```

2. **Reset to Default:**
   ```
   Firebase Console > Remote Config > energy_restore_amount > Set to 100 > Publish
   ```

3. **Communication:**
   - Use `maintenance_message` parameter to inform users
   - Set `maintenance_mode = true` if critical issues arise

## ✅ Checklist Before Going Live

- [ ] Firebase Remote Config parameters created
- [ ] Parameters published in Firebase Console
- [ ] Test build verified (optional)
- [ ] Rollback plan documented
- [ ] Team notified of deployment
- [ ] Monitoring dashboard ready (Firebase Console)
- [ ] Player support team informed about fix

## 📞 Support

If you encounter any issues:
1. Check Firebase Console > Remote Config for current values
2. Review Firebase Console > Analytics > Events for `remote_config_fetch` events
3. Check app logs for "✅ Remote Config initialized successfully"
4. Contact development team with error logs

---

**Deployed by:** [Your Name]  
**Deployment Date:** [Current Date]  
**Status:** Ready for deployment  
**Risk Level:** Low (easy rollback, no breaking changes)
