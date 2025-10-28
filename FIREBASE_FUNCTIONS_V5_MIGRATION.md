# Firebase Functions v5 Migration Guide

## Overview
This guide helps migrate from firebase-functions v4 to v5, which resolves deployment timeout issues and provides better performance.

## Changes Made

### 1. Package.json
- ✅ Updated `firebase-functions` from `^4.9.0` to `^5.1.1`
- ✅ Kept `firebase-admin` at `^12.0.0`
- ✅ Kept Node.js at version `20`

### 2. Import Statements (index.js)
```javascript
// OLD (v4):
const functions = require('firebase-functions');

// NEW (v5):
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onDocumentWritten} = require('firebase-functions/v2/firestore');
const {setGlobalOptions} = require('firebase-functions/v2');
```

### 3. Global Options
Added global configuration to avoid repeating options:
```javascript
setGlobalOptions({
  region: 'us-central1',
  maxInstances: 100,
  timeoutSeconds: 540,
  memory: '512MiB',
});
```

## Migration Pattern Reference

### Scheduled Functions (PubSub)
```javascript
// OLD:
exports.myScheduledFunc = functions.pubsub
  .schedule('0 * * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    // ...
  });

// NEW:
exports.myScheduledFunc = onSchedule({
  schedule: '0 * * * *',
  timeZone: 'UTC',
  timeoutSeconds: 540,
  memory: '1GiB', // optional override
}, async (event) => {
  // ...
});
```

### Callable Functions (HTTPS)
```javascript
// OLD:
exports.myCallable = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  // use data and context.auth
});

// NEW:
exports.myCallable = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }
  const data = request.data;
  // use data and request.auth
});
```

### Firestore Triggers
```javascript
// OLD:
exports.onUpdate = functions.firestore
  .document('collection/{docId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const docId = context.params.docId;
  });

// NEW:
exports.onUpdate = onDocumentWritten('collection/{docId}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  const docId = event.params.docId;
  
  if (!before || !after) return null; // handle creates/deletes
});
```

## Functions to Migrate

### ✅ Completed
1. `dailyGameUpdate` - Scheduled (onSchedule)
2. `weeklyLeaderboardUpdate` - Scheduled (onSchedule)
3. `checkAchievements` - Firestore trigger (onDocumentWritten)
4. `validateSongRelease` - Callable (onCall)

### 🔄 Remaining Scheduled Functions
- `triggerSpecialEvent` (line ~397)
- `simulateNPCActivity` (line ~3415)
- `gandalfTheBlackPosts` (line ~4283)
- `dailySideHustleGeneration` (line ~4341)
- `checkRivalChartPositions` (line ~4968)
- `updateNextTubeDaily` (line ~5327)
- `runNextTubeNow` (line ~5535)
- `runNextTubeForAllAdmin` (line ~6004)

### 🔄 Remaining Callable Functions
- `secureSongCreation` (line ~1906)
- `secureStatUpdate` (line ~2037)
- `secureSideHustleReward` (line ~2503)
- `secureReleaseAlbum` (line ~2594)
- `migratePlayerContentToSubcollections` (line ~2888)
- `triggerDailyUpdate` (line ~3017)
- `catchUpMissedDays` (line ~3094)
- `initializeNPCArtists` (line ~3320)
- `forceNPCRelease` (line ~3803)
- `checkAdminStatus` (line ~4000)
- `sendGiftToPlayer` (line ~4012)
- `triggerWeeklyLeaderboardUpdate` (line ~4150)
- `sendGlobalNotificationToPlayers` (line ~4205)
- `triggerGandalfPost` (line ~4315)
- `triggerSideHustleGeneration` (line ~4358)
- `syncAllPlayerStreams` (line ~5067)
- `validateNexTubeUpload` (line ~5154)
- `listAlbumCertificationEligibility` (line ~5742)
- `submitAlbumForCertification` (line ~5817)
- `runCertificationsMigrationAdmin` (line ~5910)

### 🔄 Remaining Firestore Triggers
- `onPostEngagement` (line ~4778)
- `onChartUpdate` (line ~4886)

## Installation Steps

1. Install updated dependencies:
```powershell
cd functions
npm install
```

2. Complete the migration (use find & replace carefully):
   - Search for: `functions.https.onCall(async (data, context)`
   - Replace with: `onCall(async (request)`
   - Then update function bodies to use `request.data` and `request.auth`

3. Test locally:
```powershell
firebase emulators:start --only functions
```

4. Deploy incrementally:
```powershell
# Deploy one function first to test
firebase deploy --only functions:listAlbumCertificationEligibility

# If successful, deploy all
firebase deploy --only functions
```

## Key Benefits

1. **Faster cold starts**: v5 uses improved initialization
2. **Better timeout handling**: More reliable deployments
3. **Improved error messages**: Easier debugging
4. **Future-proof**: Latest API with ongoing support
5. **Better memory management**: Configurable per-function

## Troubleshooting

### If deployment still times out:
1. Ensure no top-level `await` or heavy initialization
2. Lazy-load Remote Config inside function handlers
3. Deploy functions in smaller batches
4. Increase prepare timeout:
```powershell
$env:FIREBASE_FUNCTIONS_PREPARE_TIMEOUT=180000
firebase deploy --only functions
```

### If functions fail after deployment:
1. Check logs: `firebase functions:log`
2. Verify auth context changes: `context.auth` → `request.auth`
3. Verify data access: `data` → `request.data`
4. Check parameter extraction: `context.params` → `event.params`

## Rollback Plan

If needed, revert package.json:
```json
"firebase-functions": "^4.9.0"
```

Then restore old import:
```javascript
const functions = require('firebase-functions');
```

And redeploy.
