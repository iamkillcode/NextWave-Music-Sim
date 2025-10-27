# NexTube Upload Limits - Quick Start Guide

## 🚀 What You Need to Do

This guide provides step-by-step instructions to activate the NexTube upload rate limiting and anti-abuse system.

---

## ✅ Prerequisites

- Firebase project configured
- Cloud Functions enabled
- Remote Config enabled
- Flutter app deployed

---

## 📋 Setup Steps

### Step 1: Deploy Cloud Functions (5 minutes)

```bash
# Navigate to functions directory
cd functions

# Install dependencies (if not already done)
npm install

# Build TypeScript
npm run build

# Deploy the new validation function
firebase deploy --only functions:validateNexTubeUpload

# Verify deployment
firebase functions:list | grep validateNexTubeUpload
```

**Expected Output**:
```
✔ functions: Finished running predeploy script.
✔ functions[validateNexTubeUpload(us-central1)]: Successful create operation.
```

---

### Step 2: Update Firestore Rules (2 minutes)

```bash
# Deploy updated security rules
firebase deploy --only firestore:rules

# Verify in Firebase Console
# Go to: Firestore Database → Rules tab
```

**Verification**:
- Open Firebase Console → Firestore → Rules
- Should see rules for `nexttube_videos` with validation

---

### Step 3: Configure Remote Config (5 minutes)

1. **Open Firebase Console** → Remote Config
2. **Add parameters** (click "Add parameter" for each):

#### Upload Limits (Required)
| Parameter Key | Type | Default Value |
|--------------|------|---------------|
| `nexttube_cooldown_minutes` | Number | `10` |
| `nexttube_daily_upload_limit` | Number | `5` |
| `nexttube_duplicate_window_days` | Number | `60` |
| `nexttube_similarity_threshold` | Number | `0.92` |

#### Backend Simulation (Optional - for display only)
| Parameter Key | Type | Default Value |
|--------------|------|---------------|
| `nexRPMMinCents` | Number | `60` |
| `nexRPMMaxCents` | Number | `240` |
| `nexFameMultCap` | Number | `2.0` |
| `nexDailyViewCap` | Number | `200000` |
| `nexSubsGainCap` | Number | `10000` |
| `nexSubsMonetize` | Number | `1000` |
| `nexWeightOfficial` | Number | `1.0` |
| `nexWeightLyrics` | Number | `0.7` |
| `nexWeightLive` | Number | `0.5` |
| `nexNoveltyHalfLifeDays` | Number | `14` |

3. **Publish changes** (top right button)

**Screenshot**: Should look like this:
```
Parameter                          Type    Default Value
nexttube_cooldown_minutes          Number  10
nexttube_daily_upload_limit        Number  5
nexttube_duplicate_window_days     Number  60
nexttube_similarity_threshold      Number  0.92
```

---

### Step 4: Set Cloud Function Environment Variables (Optional)

The function uses these env vars as fallback if Remote Config isn't available.

**Option A: Firebase CLI**
```bash
firebase functions:config:set \
  nexttube.cooldown_minutes=10 \
  nexttube.daily_limit=5 \
  nexttube.duplicate_window_days=60 \
  nexttube.similarity_threshold=0.92

# Redeploy to apply
firebase deploy --only functions:validateNexTubeUpload
```

**Option B: Firebase Console**
1. Go to: Functions → Select `validateNexTubeUpload` → Configuration tab
2. Add environment variables:
   - `NEXTTUBE_COOLDOWN_MINUTES` = `10`
   - `NEXTTUBE_DAILY_LIMIT` = `5`
   - `NEXTTUBE_DUPLICATE_WINDOW_DAYS` = `60`
   - `NEXTTUBE_SIMILARITY_THRESHOLD` = `0.92`

---

### Step 5: Update Flutter App (3 minutes)

```bash
# Get dependencies (cloud_functions added)
flutter pub get

# Build for your platform
flutter build apk      # Android
# OR
flutter build ios      # iOS
# OR
flutter build web      # Web
```

---

### Step 6: Test the System (10 minutes)

#### Test 1: Cooldown
1. Open app and navigate to NexTube → Upload
2. Upload a video successfully
3. **Immediately** try to upload another video
4. **Expected**: "Please wait 10 minutes between uploads"

#### Test 2: Daily Limit
1. Upload 5 videos throughout the day
2. Try to upload a 6th video
3. **Expected**: "Daily upload limit reached (5 per day)"

#### Test 3: Duplicate Title
1. Upload video with title "Test Video"
2. Try to upload with same title "Test Video"
3. **Expected**: "You already used a very similar title recently"

#### Test 4: Official Video Uniqueness
1. Upload official video for a song
2. Try to upload another official video for same song
3. **Expected**: "Song already has an official video"

#### Test 5: Admin Dashboard
1. Open Admin Dashboard
2. Scroll to "NexTube Configuration" section
3. **Expected**: See all configured values displayed

---

## 🔍 Verification Checklist

- [ ] Cloud Function deployed and shows in Firebase Console
- [ ] Firestore rules updated (check Rules tab)
- [ ] Remote Config parameters added and published
- [ ] Flutter app rebuilt and installed
- [ ] Cooldown test passes
- [ ] Daily limit test passes
- [ ] Duplicate detection test passes
- [ ] Admin Dashboard shows configuration

---

## 🛠️ Troubleshooting

### Issue: "Upload blocked" but should be allowed

**Check**:
```bash
# View Cloud Function logs
firebase functions:log --only validateNexTubeUpload --limit 50

# Look for your user ID in the logs
```

**Common causes**:
- Clock skew (device time incorrect)
- Previous uploads not showing in query
- Firestore indexes not ready

**Fix**:
- Wait 1-2 minutes for Firestore to sync
- Clear app cache and restart
- Check Firestore Console for your uploads

---

### Issue: Server validation unavailable

**Check**:
```bash
# Test function directly
firebase functions:call validateNexTubeUpload \
  --data='{"title":"Test","songId":"test123","videoType":"official"}'
```

**Common causes**:
- Function not deployed
- Region mismatch (should be us-central1)
- Authentication issue

**Fix**:
- Redeploy: `firebase deploy --only functions`
- Check Firebase Console → Functions for errors
- Ensure user is logged in

---

### Issue: Admin Dashboard doesn't show config

**Check**:
- Open browser dev console (F12)
- Look for Remote Config errors

**Fix**:
```dart
// In app, trigger refresh
final config = RemoteConfigService();
await config.initialize();
await config.refresh();
```

---

### Issue: Firestore rules reject upload

**Check Firebase Console → Firestore → Rules**

**Common causes**:
- Missing `normalizedTitle` field
- Incorrect data types
- User not authenticated

**Fix**:
- Check `NextTubeService.createVideo` includes all required fields
- Verify auth state: `FirebaseAuth.instance.currentUser`
- Test rules in Firebase Console → Rules playground

---

## 📊 Monitoring

### View Recent Uploads
```
Firebase Console → Firestore → nexttube_videos
Filter by: createdAt (descending)
```

### Check Function Logs
```bash
# Real-time logs
firebase functions:log --only validateNexTubeUpload

# Search for specific user
firebase functions:log | grep "USER_ID_HERE"
```

### Remote Config Status
```
Firebase Console → Remote Config
Check: Last fetch time, Active parameters
```

---

## 🎛️ Adjusting Limits

### Make Limits Stricter
```
nexttube_cooldown_minutes: 30 (was 10)
nexttube_daily_upload_limit: 3 (was 5)
nexttube_similarity_threshold: 0.95 (was 0.92)
```

### Make Limits Lenient
```
nexttube_cooldown_minutes: 5 (was 10)
nexttube_daily_upload_limit: 10 (was 5)
nexttube_similarity_threshold: 0.85 (was 0.92)
```

### Disable Limits (Testing Only)
```
nexttube_cooldown_minutes: 0
nexttube_daily_upload_limit: 999
nexttube_similarity_threshold: 1.0
```

**After changes**:
1. Publish Remote Config
2. Users will get new values on next app launch (up to 1 hour cache)
3. Or force refresh in Admin Dashboard

---

## 🎯 Success Criteria

✅ **System is working when**:
1. Users see cooldown messages between uploads
2. Daily limit prevents spam
3. Duplicate titles are blocked
4. Official video uniqueness enforced
5. Admin Dashboard shows current config
6. No Firestore permission errors
7. Cloud Function logs show validations

---

## 📞 Need Help?

1. Check full documentation: `NEXTTUBE_UPLOAD_LIMITS.md`
2. Review Cloud Functions logs: `firebase functions:log`
3. Test in Firebase Emulator: `firebase emulators:start`
4. Check Firestore Console for data integrity

---

## 🎉 You're Done!

The NexTube upload rate limiting system is now active. Players will see:
- Clear error messages when limits are hit
- Fair upload quotas preventing spam
- Duplicate detection ensuring quality

Monitor the system and adjust limits based on player behavior!

---

**Setup Time**: ~25 minutes  
**Last Updated**: October 27, 2025
