# 🚀 QUICK DEPLOYMENT - Energy Restore Fix

## ⚡ 5-Minute Firebase Console Setup

### 1️⃣ Open Firebase Console
```
https://console.firebase.google.com
→ Select "NextWave" project
→ Click "Remote Config" in left sidebar (under "Engage")
```

### 2️⃣ Add First Parameter
```
Click "Add parameter" button
```

**Parameter Details:**
```
Parameter key:     enable_energy_restore_fix
Data type:         Boolean
Default value:     true
Description:       Enable the energy restoration fix for daily resets
```

Click **"Save"**

### 3️⃣ Add Second Parameter
```
Click "Add parameter" button again
```

**Parameter Details:**
```
Parameter key:     energy_restore_amount
Data type:         Number
Default value:     100
Description:       Amount of energy to restore each day (default: 100)
```

Click **"Save"**

### 4️⃣ Publish Changes
```
Click "Publish changes" button at the top right
Click "Publish" in confirmation dialog
```

## ✅ Verification

After publishing, you should see:
- Status: **"Published"**
- Last published: **[Current timestamp]**
- Two new parameters in the list:
  - ✓ `enable_energy_restore_fix` = `true`
  - ✓ `energy_restore_amount` = `100`

## 📱 Player Impact

**Timeline:**
- ⏰ Fix goes live: **Within 1 hour** for active players
- 🔄 For inactive players: **On next app open**
- 📊 No app update required!

**User Experience:**
```
Old behavior: Energy stuck, not restoring
New behavior: Energy restores to 100 every in-game day
Message shown: "☀️ New day! Energy restored to 100"
```

## 🎛️ Quick Adjustments

### To Change Energy Amount:
1. Firebase Console > Remote Config
2. Edit `energy_restore_amount`
3. Change value (e.g., `150` for more energy)
4. Click "Publish changes"

### To Disable Fix (Rollback):
1. Firebase Console > Remote Config
2. Edit `enable_energy_restore_fix`
3. Change to `false`
4. Click "Publish changes"

### To Re-enable Fix:
1. Firebase Console > Remote Config
2. Edit `enable_energy_restore_fix`
3. Change to `true`
4. Click "Publish changes"

## 🧪 Optional: Beta Test First

**Test with 10% of users before full rollout:**

1. In Remote Config, click **"Add condition"**
2. Configure:
   ```
   Condition name: Beta Testers
   Applies to:     User in random percentile
   Rule:           <= 10
   ```
3. Save condition

4. For `enable_energy_restore_fix`:
   - Click parameter
   - Add conditional value
   - Select "Beta Testers" condition
   - Set value: `true`
   - Default value: `false` (everyone else waits)

5. Publish and monitor for 24 hours
6. If successful, change default to `true` for everyone

## 📊 Monitoring

**Check these metrics:**
1. Firebase Analytics > Events > Look for:
   - `remote_config_fetch_success`
   - User engagement (should increase)

2. Player Feedback:
   - Monitor support tickets
   - Check app reviews
   - Discord/community channels

3. Firebase Console > Remote Config:
   - View fetch success rate
   - Check active users getting config

## 🚨 Emergency Rollback

**If anything goes wrong:**

```
Firebase Console
→ Remote Config
→ enable_energy_restore_fix
→ Set to: false
→ Publish changes
```

**Effect:** Reverts to old behavior within 1 hour

## 📋 Checklist

Before publishing:
- [ ] Firebase Console open
- [ ] Project selected: NextWave
- [ ] Remote Config section open
- [ ] Both parameters added correctly
- [ ] Values verified (true, 100)
- [ ] Ready to click "Publish changes"

After publishing:
- [ ] Status shows "Published"
- [ ] Parameters visible in list
- [ ] Team notified
- [ ] Monitoring dashboard open
- [ ] Support team informed

## 🎯 Expected Results

**Within 24 hours:**
- ✅ Player complaints about energy restoration should stop
- ✅ Players see "Energy restored to 100" message daily
- ✅ Energy system working as designed
- ✅ No negative side effects

**If issues persist:**
1. Check Firebase Console > Remote Config > Fetch success rate
2. Verify parameters are published (not in draft)
3. Test in your own app by restarting
4. Contact development team with logs

## 💡 Pro Tips

- **Fetch Interval:** Config updates every 1 hour minimum
- **Restart App:** Players get update faster if they restart
- **Multiple Environments:** Can have different values for dev/prod
- **Version Targeting:** Can target specific app versions if needed

---

**Status:** ✅ Ready to deploy  
**Risk:** 🟢 Low (easy rollback)  
**Duration:** ⏱️ 5 minutes  
**Impact:** 📈 High (fixes major player complaint)
