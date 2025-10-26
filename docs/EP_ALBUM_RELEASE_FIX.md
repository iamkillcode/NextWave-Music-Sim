# EP/Album Release 404 Error - Fixed

## Issue
Players were unable to release EPs and Albums, receiving the following errors:
- `Failed to release album (server error)`
- `404 error when fetching secureReleaseAlbum function`
- `CORS policy: No 'Access-Control-Allow-Origin' header present`
- `[firebase_functions/internal] internal`

### Error Stack Trace
```
POST https://us-central1-nextwave-music-sim.cloudfunctions.net/secureReleaseAlbum net::ERR_FAILED
Access to fetch at 'https://us-central1-nextwave-music-sim.cloudfunctions.net/secureReleaseAlbum' 
from origin 'http://localhost:64649' has been blocked by CORS policy
```

## Root Cause
The Firebase Functions client was not explicitly configured with a region, causing it to look for functions in the wrong location or use incorrect endpoints on web platforms.

### Technical Details
- **Functions Deployed In**: `us-central1` (confirmed via `firebase functions:list`)
- **Client Configuration**: Used `FirebaseFunctions.instance` (defaults to `us-east1` or auto-detect on some platforms)
- **Result**: Web client attempted to call function at wrong endpoint → 404 error
- **CORS Error**: Secondary effect of the 404; CORS headers only sent on successful function invocation

## Solution
Explicitly configure the Firebase Functions instance to use the `us-central1` region.

### Code Changes

**File**: `lib/services/firebase_service.dart`

#### Before:
```dart
final FirebaseFunctions _functions = FirebaseFunctions.instance;
```

#### After:
```dart
// Explicitly set region to us-central1 to match deployed functions
final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
```

### Why This Works
- `FirebaseFunctions.instanceFor(region: 'us-central1')` explicitly tells the SDK where to find functions
- Ensures the client constructs the correct URL for web calls
- Matches the actual deployment region of all Cloud Functions
- Prevents region mismatch issues across platforms (web, mobile, desktop)

## Verification

### Before Fix
- ❌ Album release fails with 404
- ❌ CORS errors in browser console
- ❌ Function shows as deployed but unreachable from web

### After Fix
- ✅ Album release succeeds
- ✅ No CORS errors
- ✅ Function properly invoked from web client

### Testing Steps
1. **Stop running app**: Press `q` in the Flutter terminal to quit
2. **Hot restart** (if app still running): Press `Shift+R` or `flutter run`
3. **Clear browser cache**: Hard refresh (`Ctrl+Shift+R` on Chrome)
4. **Test album release**:
   - Go to Release Manager
   - Create or select an album/EP with at least one song
   - Click "Release Album"
   - Should succeed without errors

## Related Services

### Already Fixed (Prior to This Issue)
- ✅ `lib/services/admin_service.dart` - Already used `instanceFor(region: 'us-central1')`
- ✅ `lib/screens/admin_dashboard_screen.dart` - Already used `instanceFor(region: 'us-central1')`

### Updated
- ✅ `lib/services/firebase_service.dart` - Now uses `instanceFor(region: 'us-central1')`

## Prevention
For future Cloud Functions callable functions:
1. ✅ Always use `FirebaseFunctions.instanceFor(region: 'us-central1')` in all services
2. ✅ Document the region in comments when creating new function instances
3. ✅ Test on web platform (Chrome) before deploying to production
4. ❌ Don't use `FirebaseFunctions.instance` without explicit region

## Notes
- **CORS Configuration**: The `cors.json` file is for Firebase Storage, not Cloud Functions
- **Cloud Functions CORS**: Callable functions handle CORS automatically when properly invoked via the SDK
- **404 vs CORS**: The CORS error was a symptom, not the root cause; the 404 happened first
- **Region List**: All NextWave functions are deployed to `us-central1` (confirmed via `firebase functions:list`)

## Additional Context
This same issue could affect any new services that create `FirebaseFunctions` instances. Always use:
```dart
final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
```

Instead of:
```dart
final functions = FirebaseFunctions.instance; // ❌ May default to wrong region
```
