# Quick Deployment Guide - Balance Fixes

## Files Modified ✅

1. **lib/models/artist_stats.dart** - Fame bonuses reduced, hype system added
2. **lib/screens/studio_screen.dart** - Hype gain from releases
3. **lib/screens/echox_screen.dart** - Hype gain from posts
4. **lib/services/stream_growth_service.dart** - Hype bonuses, minimum streams fix, quality curve
5. **functions/index.js** - Hype decay, loyal fan conversion improvements

## Deployment Steps

### 1. Test Locally (Required)
```bash
# Run Flutter tests
flutter test

# Check for compilation errors
flutter analyze

# Test in Chrome
flutter run -d chrome
```

### 2. Deploy Cloud Functions (Critical)
```bash
cd functions

# Install dependencies if needed
npm install

# Deploy to Firebase
firebase deploy --only functions

# Monitor deployment
# Should see: ✔ functions[dailyGameUpdate] deployed successfully
```

### 3. Verify Firestore Rules (No changes needed)
The fixes don't change security rules, but verify `inspirationLevel` field is writable:
```javascript
// firestore.rules - Already allows this
allow write: if request.auth != null && request.auth.uid == userId;
```

### 4. Test in Production

**Test Case 1: Hype System**
- Release a quality 80+ song
- Check stats: `inspirationLevel` should increase by +40
- UI should show "Hype" increasing
- Wait 1 real hour (1 game day)
- Cloud Functions should decay hype by -5 to -8

**Test Case 2: Minimum Streams**
- Create new account (0 fans)
- Release quality 40 song
- Should get ~10 streams/day (not 230!)

**Test Case 3: Quality Spam**
- Release quality 25 song
- Should get 0 fans (not 10!)

**Test Case 4: Fame Bonuses**
- Artist with 500+ fame
- Check stream multiplier: Should be 1.8x (not 2.0x)
- Check fan conversion: Should be 2.0x (not 2.5x)

### 5. Monitor Logs

```bash
# Watch Cloud Function logs
firebase functions:log --only dailyGameUpdate

# Look for:
# ✅ "📉 [Player]: -5 hype (40 → 35)"
# ✅ "💎 [Player]: +10 loyal fans"
# ❌ No NaN or Infinity errors
```

## Rollback Plan (If Needed)

If issues occur, revert these commits:
```bash
git log --oneline -5  # Find commit hashes
git revert <commit-hash>
git push origin main
```

Then redeploy:
```bash
cd functions
firebase deploy --only functions
```

## Success Criteria ✅

- [ ] Cloud Functions deploy without errors
- [ ] Hype decays daily (-5 to -8)
- [ ] 0-fan artists get <50 streams/day
- [ ] Quality <30 songs give 0 fans
- [ ] 500+ fame gives 1.8x streams (not 2.0x)
- [ ] No Firestore NaN/Infinity errors
- [ ] Players report balanced progression

## Emergency Contacts

If critical issues found:
1. Check Firebase Console → Functions → Logs
2. Check Firestore Console → Check `inspirationLevel` values
3. Revert deployment if necessary

## Estimated Downtime
- Cloud Functions deployment: ~2 minutes
- No player-facing downtime expected
- Changes take effect on next `dailyGameUpdate` run (every 1 hour)
