# 🔧 Fix "Invalid Skill Change" Error - Deployment Guide

## 🐛 Issue
Players experiencing error when game tries to save:
```
Error updating player stats: [firebase_functions/invalid-argument] Invalid skill change
Error saving profile: [firebase_functions/invalid-argument] Invalid skill change
```

## ✅ Fix Applied
Increased maximum allowed skill gain per save from **10 points** to **30 points** in the Cloud Function validation.

## 🚀 Deploy the Fix

### Option 1: Deploy via Terminal (PowerShell)

```powershell
# Navigate to project root
cd C:\Users\Manuel\Documents\GitHub\NextWave\nextwave

# Deploy only the updated function
firebase deploy --only functions
```

### Option 2: Deploy Specific Function Only (Faster)

```powershell
# Deploy only the updatePlayerStats function
firebase deploy --only functions:updatePlayerStats
```

### Option 3: Full Deployment

```powershell
# If you want to deploy everything
firebase deploy
```

## ⏱️ Deployment Time
- **Single function**: ~2-3 minutes
- **All functions**: ~5-10 minutes

## ✅ Verification

After deployment, check:

1. **Firebase Console Logs:**
   ```
   Firebase Console > Functions > Logs
   ```
   - Should see deployment success
   - No more "Invalid skill change" errors

2. **Test in Game:**
   - Write a song (gains skills)
   - Complete practice session (gains 15-20 skill points)
   - Energy restore (may trigger skill updates)
   - Should save without errors

3. **Expected Behavior:**
   - Skills can now gain up to 30 points per save
   - Still validates against cheating
   - Normal gameplay no longer triggers validation errors

## 📊 What Changed

### Before:
```javascript
// Max 10 points per save - TOO STRICT
if (!validateStatChange(oldValue, newValue, stat, 10)) {
  throw new functions.https.HttpsError('invalid-argument', `Invalid skill change`);
}
```

### After:
```javascript
// Max 30 points per save - ALLOWS NORMAL GAMEPLAY
// Accounts for practice sessions, multiple songs, daily progression
if (!validateStatChange(oldValue, newValue, stat, 30)) {
  throw new functions.https.HttpsError('invalid-argument', `Invalid skill change`);
}
```

## 🎯 Why 30 Points?

**Legitimate scenarios that can gain >10 points:**

1. **Practice Session:** 15-20 points in one skill
2. **Multiple Songs:** 5 points × 3 songs = 15 points
3. **Daily Progression:** Multiple activities accumulate
4. **Energy Restore:** Triggers multiple updates at once

**Still protects against cheating:**
- 30 points is reasonable for normal gameplay
- Prevents instant maxing (would need 100+ per save)
- Skills still capped at 0-100 range

## 🔍 Troubleshooting

### If deployment fails:
```powershell
# Check you're logged in
firebase login

# Check project is set
firebase use --list

# Check functions dependencies
cd functions
npm install
cd ..

# Try again
firebase deploy --only functions
```

### If error persists after deployment:
1. Wait 2-3 minutes for propagation
2. Check Firebase Console > Functions > updatePlayerStats is deployed
3. Look at Cloud Function logs for other errors
4. Clear app cache and restart game

### If you see "Function not found":
```powershell
# Redeploy all functions
firebase deploy --only functions
```

## 📝 Notes

- This fix is backward compatible
- Players won't notice any change (just fewer errors)
- Existing player data is not affected
- No client app update needed (Cloud Function only)

## 🎉 Expected Result

After deployment:
- ✅ "Invalid skill change" errors disappear
- ✅ Players can save normally after:
  - Writing songs
  - Practice sessions
  - Daily energy restore
  - Multiple activities
- ✅ Anti-cheat still active (30 point cap prevents abuse)

---

**Deployment Status:** ⏳ Pending  
**Fix Applied:** ✅ Code committed and pushed  
**Deploy Command:** `firebase deploy --only functions`
