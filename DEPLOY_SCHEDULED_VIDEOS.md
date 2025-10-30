# Deploy Scheduled Video Release Feature

## Overview
This deployment adds scheduled video release functionality to NextWave, allowing players to schedule NexTube videos to be published on future in-game dates.

## Changes Made

### 1. Data Model Updates
**File**: `lib/models/nexttube_video.dart`
- Added `releaseDate` field (DateTime, nullable) - stores the in-game date when video should publish
- Added `status` field tracking: `'scheduled'`, `'published'`, `'processing'`
- Updated `copyWith()`, `toJson()`, and `fromJson()` methods

### 2. Service Layer Updates
**File**: `lib/services/nexttube_service.dart`
- Modified `createVideo()` to accept optional `releaseDate` parameter
- Auto-sets status to `'scheduled'` when releaseDate is provided, `'published'` otherwise
- Updated `hasVideoForSongAndType()` to check all videos (not just recent 30 days)
  - Prevents duplicate official videos per song (lifetime)
  - Prevents duplicate lyrics videos per song (lifetime)
  - Live videos still allow multiple uploads

### 3. UI Updates
**File**: `lib/screens/nexttube_upload_screen.dart`
- Added in-game date tracking with `GameTimeService`
- New "Release schedule" section with two options:
  - **Publish immediately** (default)
  - **Schedule for later** (with calendar date picker)
- Calendar picker shows in-game dates (current date + 30 days window)
- Duplicate video type validation with clear error messages
- Success messages show scheduled date or immediate publish status

### 4. Cloud Functions
**File**: `functions/index.js`

#### New Function: `processScheduledVideos`
- **Schedule**: Runs at `:50` every hour (10 mins before NexTube daily simulation)
- **Purpose**: Checks for videos with status `'scheduled'` and `releaseDate <= currentGameDate`
- **Action**: Updates status from `'scheduled'` to `'published'`
- **Memory**: 256MB
- **Timeout**: 120 seconds

#### Updated Function: `updateNextTubeDaily`
- Now only processes videos with `status === 'published'`
- Prevents scheduled videos from accumulating views before release

#### Updated Function: `runNextTubeNow`
- Now only processes videos with `status === 'published'`
- Manual test function respects scheduled status

### 5. Firestore Indexes
**File**: `firestore.indexes.json`
Added two new composite indexes:
```json
{
  "collectionGroup": "nexttube_videos",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "nexttube_videos",
  "fields": [
    { "fieldPath": "ownerId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "ASCENDING" }
  ]
}
```

## Deployment Steps

### 1. Deploy Firestore Indexes (First)
```bash
firebase deploy --only firestore:indexes
```
**Wait time**: 5-10 minutes for indexes to build

### 2. Deploy Cloud Functions
```bash
cd functions
npm install  # Ensure dependencies are up to date
firebase deploy --only functions
```

**New function deployed**: `processScheduledVideos`
**Updated functions**: `updateNextTubeDaily`, `runNextTubeNow`

### 3. Deploy Flutter Web App
```bash
flutter build web
npx gh-pages -d build/web
```

## Testing

### Test Scheduled Video Creation
1. Navigate to NexTube Upload screen
2. Select a song
3. Choose "Schedule for later"
4. Pick a future in-game date (1-2 days ahead)
5. Fill in title, description, thumbnail
6. Click "Publish"
7. Verify success message shows scheduled date
8. Check Firestore: video should have `status: 'scheduled'` and `releaseDate` set

### Test Duplicate Prevention
1. Try to create a second official video for the same song
2. Should see error: "You already have a official video for this song. Only one official per song is allowed."
3. Same for lyrics videos
4. Live videos should allow multiple uploads

### Test Scheduled Release Processing
1. Create a scheduled video for "today" (current game date)
2. Wait for next hour (when `processScheduledVideos` runs at :50)
3. Check Firestore: video status should change from `'scheduled'` to `'published'`
4. Video should now appear in feeds and start accumulating views

### Test View Accumulation
1. Verify scheduled videos don't accumulate views while `status === 'scheduled'`
2. After status changes to `'published'`, verify views start accumulating in next daily update

## Rollback Plan

If issues occur:

### Rollback Cloud Functions
```bash
firebase functions:delete processScheduledVideos
# Then redeploy previous version of index.js
```

### Fix Stuck Scheduled Videos
If videos aren't being published, manually update in Firestore Console:
```javascript
db.collection('nexttube_videos')
  .where('status', '==', 'scheduled')
  .get()
  .then(snap => {
    snap.forEach(doc => {
      doc.ref.update({ status: 'published' });
    });
  });
```

## Monitoring

### Cloud Function Logs
```bash
firebase functions:log --only processScheduledVideos
firebase functions:log --only updateNextTubeDaily
```

### Key Metrics to Watch
- Number of scheduled videos processed per hour
- Any videos stuck in `'scheduled'` status past their release date
- Daily update still processing all published videos correctly
- No errors in function execution

## Business Logic Summary

**Video Type Restrictions**:
- **Official videos**: 1 per song (lifetime)
- **Lyrics videos**: 1 per song (lifetime)  
- **Live videos**: Unlimited per song

**Scheduling Rules**:
- Can schedule up to 30 game days in advance
- Money is charged immediately when scheduled (not when published)
- Videos cannot be edited after scheduling
- Status automatically changes to `'published'` on release date
- Views/earnings only start accumulating after status is `'published'`

**Cost Model**:
- Same production costs apply (lyrics < live < official)
- Producer multipliers apply (Indie: 1.0x, Studio: 1.2x, Top-tier: 1.5x)
- Payment is deducted at scheduling time, not release time

## Future Enhancements
- Allow editing scheduled videos before release
- Add cancellation feature for scheduled videos
- Show scheduled videos in a separate "Upcoming" section
- Send notification when scheduled video goes live
- Allow rescheduling to different dates
- Batch scheduling for multiple videos

## Support
If issues arise, check:
1. Firestore indexes are fully built (green status in Firebase Console)
2. Cloud Functions are deployed and not hitting timeout/memory limits
3. GameTimeService is returning correct in-game dates
4. Video documents have proper `status` and `releaseDate` fields
