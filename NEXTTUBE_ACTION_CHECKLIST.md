# 🚀 NexTube Upload Limits - Your Action Checklist

## ✅ What I Need To Do

This is your personal checklist for activating the NexTube upload rate limiting system. Check off each item as you complete it.

---

## 📦 STEP 1: Deploy Cloud Functions (5 min)

```bash
cd functions
npm install
npm run build
firebase deploy --only functions:validateNexTubeUpload
```

**Verification**:
- [ ] See "✔ functions[validateNexTubeUpload(us-central1)]: Successful" in console
- [ ] Check Firebase Console → Functions → `validateNexTubeUpload` appears in list

---

## 🔐 STEP 2: Deploy Firestore Rules (2 min)

```bash
firebase deploy --only firestore:rules
```

**Verification**:
- [ ] See "✔ firestore: released rules" in console
- [ ] Open Firebase Console → Firestore → Rules tab and verify new rules

---

## ⚙️ STEP 3: Configure Remote Config (10 min)

### Open Firebase Console → Remote Config

**Add these 4 required parameters**:

- [ ] `nexttube_cooldown_minutes` = `10` (Number)
- [ ] `nexttube_daily_upload_limit` = `5` (Number)
- [ ] `nexttube_duplicate_window_days` = `60` (Number)
- [ ] `nexttube_similarity_threshold` = `0.92` (Number)

**Add these 10 optional parameters** (for display in Admin Dashboard):

- [ ] `nexRPMMinCents` = `60` (Number)
- [ ] `nexRPMMaxCents` = `240` (Number)
- [ ] `nexFameMultCap` = `2.0` (Number)
- [ ] `nexDailyViewCap` = `200000` (Number)
- [ ] `nexSubsGainCap` = `10000` (Number)
- [ ] `nexSubsMonetize` = `1000` (Number)
- [ ] `nexWeightOfficial` = `1.0` (Number)
- [ ] `nexWeightLyrics` = `0.7` (Number)
- [ ] `nexWeightLive` = `0.5` (Number)
- [ ] `nexNoveltyHalfLifeDays` = `14` (Number)

**IMPORTANT**: Click **"Publish changes"** button at top right!

**Verification**:
- [ ] All 14 parameters show in Remote Config dashboard
- [ ] Status shows "Published"

---

## 🔧 STEP 4: Set Environment Variables (Optional but Recommended) (5 min)

**Option A - Using Firebase CLI**:
```bash
firebase functions:config:set \
  nexttube.cooldown_minutes=10 \
  nexttube.daily_limit=5 \
  nexttube.duplicate_window_days=60 \
  nexttube.similarity_threshold=0.92

# Redeploy to apply
firebase deploy --only functions:validateNexTubeUpload
```

**Option B - Using Firebase Console**:
1. Go to: Functions → `validateNexTubeUpload` → Configuration tab
2. Add these environment variables:
   - [ ] `NEXTTUBE_COOLDOWN_MINUTES` = `10`
   - [ ] `NEXTTUBE_DAILY_LIMIT` = `5`
   - [ ] `NEXTTUBE_DUPLICATE_WINDOW_DAYS` = `60`
   - [ ] `NEXTTUBE_SIMILARITY_THRESHOLD` = `0.92`

**Verification**:
```bash
firebase functions:config:get
```
- [ ] Should show nexttube.* configuration

---

## 📱 STEP 5: Rebuild & Deploy Flutter App (5 min)

```bash
# Get dependencies
flutter pub get

# Build for your platform
flutter build apk      # Android
# OR
flutter build ios      # iOS
# OR
flutter build web      # Web
```

**Verification**:
- [ ] Build completes without errors
- [ ] No missing dependencies

---

## 🧪 STEP 6: Test The System (15 min)

### Test 1: Upload Cooldown
- [ ] Upload a video successfully
- [ ] Immediately try to upload another
- [ ] Should see: "Please wait 10 minutes between uploads"
- [ ] Wait 10+ minutes
- [ ] Upload should succeed

### Test 2: Daily Limit
- [ ] Upload 5 videos (slowly, respecting cooldown)
- [ ] Try to upload 6th video
- [ ] Should see: "Daily upload limit reached (5 per day)"

### Test 3: Duplicate Title
- [ ] Upload video titled "Test Video Official"
- [ ] Try to upload another with title "Test Video Official"
- [ ] Should see: "You already used a very similar title recently"

### Test 4: Near-Duplicate Title
- [ ] Upload video titled "My Awesome Song"
- [ ] Try to upload "My Awesome Song Video"
- [ ] Should see: "Title looks like a near-duplicate" (if >92% similar)

### Test 5: Official Video Uniqueness
- [ ] Upload official video for a song
- [ ] Try to upload another official video for same song
- [ ] Should see: "Song already has an official video"
- [ ] Upload lyrics or live video for same song
- [ ] Should succeed

### Test 6: Admin Dashboard
- [ ] Open Admin Dashboard (must be admin user)
- [ ] Scroll to "NexTube Configuration" section
- [ ] Should see all configured values displayed
- [ ] Click "Refresh Config" button
- [ ] Should see success message

### Test 7: Server Validation
- [ ] Check Firebase Console → Functions → Logs
- [ ] Should see entries for `validateNexTubeUpload`
- [ ] Look for your uploads and validation results

---

## 🔍 STEP 7: Verify Everything Works (5 min)

**Checklist**:
- [ ] Cloud Function shows in Firebase Console → Functions
- [ ] Firestore Rules tab shows updated rules with nexttube_videos validation
- [ ] Remote Config shows all 14 parameters published
- [ ] Flutter app uploads successfully (respecting limits)
- [ ] Cooldown blocks rapid uploads
- [ ] Daily limit blocks spam
- [ ] Duplicates are detected
- [ ] Admin Dashboard displays configuration
- [ ] Error messages are clear and helpful
- [ ] No console errors or crashes

---

## 📊 STEP 8: Monitor After Deployment (Ongoing)

### Daily (Week 1)
- [ ] Check Cloud Functions logs for errors
- [ ] Monitor upload rejection rates
- [ ] Review player feedback on limits
- [ ] Adjust Remote Config if needed

### Weekly
- [ ] Check Firestore usage (document reads from validation queries)
- [ ] Review Cloud Functions costs
- [ ] Analyze duplicate detection accuracy
- [ ] Update limits based on player behavior

### Monthly
- [ ] Review full analytics on upload patterns
- [ ] Document any edge cases discovered
- [ ] Optimize queries if performance issues
- [ ] Update documentation with learnings

---

## 🛠️ Troubleshooting

### Problem: Function deployment fails
```bash
# Check logs
firebase functions:log --only validateNexTubeUpload

# Redeploy with verbose
firebase deploy --only functions:validateNexTubeUpload --debug
```

### Problem: Remote Config not showing in app
```dart
// In Admin Dashboard or debug console
final config = RemoteConfigService();
await config.initialize();
await config.refresh();
print('Cooldown: ${config.nexTubeCooldownMinutes}');
```

### Problem: Server validation always fails
```bash
# Check environment variables
firebase functions:config:get

# Test function directly
firebase functions:shell
> validateNexTubeUpload({data: {title: 'Test', songId: '123', videoType: 'official'}, auth: {uid: 'YOUR_USER_ID'}})
```

### Problem: Firestore rules reject upload
- Open Firebase Console → Firestore → Rules
- Use Rules Playground to test with your data
- Ensure `normalizedTitle` field is included in upload

---

## 📖 Documentation Reference

If you need more details:

- **Full Technical Documentation**: `NEXTTUBE_UPLOAD_LIMITS.md`
- **Setup Guide**: `NEXTTUBE_SETUP_QUICK_START.md`
- **Implementation Summary**: `NEXTTUBE_IMPLEMENTATION_SUMMARY.md`
- **This Checklist**: `NEXTTUBE_ACTION_CHECKLIST.md` (you are here)

---

## ✅ Done!

Once all items above are checked:

- [ ] System is deployed and active
- [ ] All tests pass
- [ ] Documentation reviewed
- [ ] Monitoring in place

**Congratulations!** 🎉 The NexTube upload rate limiting system is now protecting your platform from abuse while ensuring a great experience for legitimate creators.

---

## 🎯 Quick Commands Reference

```bash
# Deploy everything
firebase deploy --only functions:validateNexTubeUpload,firestore:rules

# View logs
firebase functions:log --only validateNexTubeUpload --limit 50

# Test function
firebase functions:shell

# Get config
firebase functions:config:get

# Set config
firebase functions:config:set key=value

# Flutter rebuild
flutter clean && flutter pub get && flutter build apk
```

---

**Need Help?** Check the troubleshooting section in `NEXTTUBE_UPLOAD_LIMITS.md`

**Questions?** Review the implementation summary in `NEXTTUBE_IMPLEMENTATION_SUMMARY.md`

**Last Updated**: October 27, 2025
