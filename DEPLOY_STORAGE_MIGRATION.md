# Quick Deployment Guide - Storage Migration

## Prerequisites
- Firebase CLI installed (`npm install -g firebase-tools`)
- Logged in (`firebase login`)
- Project selected (`firebase use nextwave-music-sim`)

## Step-by-Step Deployment

### 1. Install Flutter Dependencies
```powershell
flutter pub get
```

### 2. Deploy Storage Rules (Optional but Recommended)
```powershell
firebase deploy --only storage
```

This will deploy the security rules in `storage.rules` to protect your Storage buckets.

### 3. Run Migration Script (Dry-Run First)
```powershell
cd functions

# Preview what will be migrated
node migrate_base64_covers.js --dry-run

# Review the output, then run the actual migration
node migrate_base64_covers.js
```

**Expected Output**:
```
🔄 Starting base64 to Storage migration...
✅ Processing players...
  📤 Migrating song 'Song Title' (62KB)
  ✓ Uploaded to: https://firebasestorage.googleapis.com/...
  ✓ Updated coverArtUrl in Firestore

📊 Migration Summary:
  Songs migrated: 18
  Songs skipped: 0
  Errors: 0
  Total time: ~30 seconds
```

### 4. Regenerate Weekly Snapshots
```powershell
cd functions
node trigger_weekly_update.js --project nextwave-music-sim
```

This will regenerate the snapshots with the new Storage URLs.

### 5. Verify in App
1. Open the app
2. Navigate to Spotlight → Weekly → Singles
3. Pull to refresh
4. Verify cover art displays correctly

## Troubleshooting

### Migration Script Errors

**Error: "Permission denied"**
- Solution: Make sure you're authenticated (`gcloud auth application-default login`)

**Error: "Project not found"**
- Solution: Set project ID with `export GOOGLE_CLOUD_PROJECT=nextwave-music-sim` (PowerShell: `$env:GOOGLE_CLOUD_PROJECT="nextwave-music-sim"`)

**Error: "Storage bucket not found"**
- Solution: Ensure Firebase Storage is enabled in Firebase Console

### Storage Rules Not Deploying

**Error: "Missing permissions"**
- Solution: Ensure you have Owner/Editor role in Firebase project
- Alternative: Use Firebase Console to manually copy rules from `storage.rules`

### App Not Showing Images

**Issue: Cover art not displaying**
- Check: Firebase Storage CORS settings
- Check: Storage rules allow public read
- Check: Network tab in browser DevTools for 403/404 errors

**Issue: Old base64 images still showing**
- Check: Clear app cache
- Check: Migration script completed successfully
- Check: Firestore documents have HTTP URLs (not data: URLs)

## Rollback

If you need to revert:

1. The migration script only updates `coverArtUrl` field
2. Original base64 data is NOT deleted from memory
3. Can revert by re-running snapshot script without the base64 filter

## Monitoring

Check migration status:
```powershell
cd functions
node -e "
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function count() {
  const players = await db.collection('players').get();
  let base64Count = 0, storageCount = 0;
  
  players.forEach(doc => {
    const songs = doc.data().songs || [];
    songs.forEach(song => {
      if (song.coverArtUrl) {
        if (song.coverArtUrl.startsWith('data:')) base64Count++;
        else if (song.coverArtUrl.startsWith('https://')) storageCount++;
      }
    });
  });
  
  console.log('Base64 URLs:', base64Count);
  console.log('Storage URLs:', storageCount);
}

count().then(() => process.exit());
"
```

## Success Criteria

- ✅ `flutter pub get` completes without errors
- ✅ Storage rules deployed successfully
- ✅ Migration script shows 0 errors
- ✅ Snapshots regenerate successfully (< 100KB)
- ✅ Cover art displays in app charts
- ✅ New uploads use Storage URLs

## Estimated Time
- Flutter dependencies: ~30 seconds
- Storage rules deployment: ~10 seconds
- Migration script: ~1-2 minutes (depends on # of songs)
- Snapshot regeneration: ~30 seconds
- Total: **~3-4 minutes**

## Questions?

Check the full documentation: `STORAGE_MIGRATION_COMPLETE.md`

---

**Quick Commands Summary**:
```powershell
# 1. Install dependencies
flutter pub get

# 2. Deploy Storage rules (optional)
firebase deploy --only storage

# 3. Run migration (preview first)
cd functions
node migrate_base64_covers.js --dry-run
node migrate_base64_covers.js

# 4. Regenerate snapshots
node trigger_weekly_update.js --project nextwave-music-sim

# 5. Verify
# Open app → Spotlight → Weekly → Pull to refresh
```
