# NexTube Upload Limits & Anti-Abuse System

## 📋 Overview

This document describes the comprehensive upload restriction and anti-abuse system for NexTube, NextWave's in-app video platform. The system uses a **three-layer defense strategy**:

1. **Client-side validation** (fast user feedback)
2. **Server-side callable function** (enforces rules even if client is bypassed)
3. **Firestore security rules** (final database-level enforcement)

---

## 🎯 Features Implemented

### ✅ Upload Rate Limiting
- **Cooldown Period**: Configurable minutes between consecutive uploads (default: 10 minutes)
- **Daily Upload Cap**: Maximum videos per player per 24-hour period (default: 5 uploads)
- Prevents spam and ensures quality content

### ✅ Duplicate Detection
- **Exact Title Matching**: Blocks identical normalized titles within a configurable window (default: 60 days)
- **Near-Duplicate Detection**: Uses Jaccard similarity to catch titles that are too similar (default: 92% threshold)
- **Song/Type Uniqueness**: Only one official video allowed per song

### ✅ Remote Config Integration
- All limits are configurable via Firebase Remote Config
- No app redeployment needed to tune restrictions
- Admin dashboard displays current values

### ✅ Admin Controls
- View current upload limits in Admin Dashboard
- Refresh Remote Config on-demand
- Monitor backend simulation parameters

---

## 🏗️ Architecture

### Layer 1: Client-Side Validation (Flutter)
**File**: `lib/screens/nexttube_upload_screen.dart`

**Purpose**: Provide instant feedback to users

**Checks Performed**:
- Cooldown timer check
- Daily upload count
- Song/type duplicate check
- Title exact duplicate check
- Title near-duplicate check (Jaccard similarity)

**Configuration Source**: `RemoteConfigService`

```dart
final config = RemoteConfigService();
final cooldownMinutes = config.nexTubeCooldownMinutes; // 10
final dailyLimit = config.nexTubeDailyUploadLimit;     // 5
final duplicateWindowDays = config.nexTubeDuplicateWindowDays; // 60
final similarityThreshold = config.nexTubeSimilarityThreshold; // 0.92
```

**User Experience**:
- Shows specific error messages (e.g., "Please wait 10 minutes between uploads")
- Prevents unnecessary network calls
- Can be bypassed by determined attackers (hence server-side enforcement)

---

### Layer 2: Server-Side Callable Function (Cloud Functions)
**File**: `functions/src/index.ts`

**Function**: `validateNexTubeUpload`

**Purpose**: Enforce rules server-side, independent of client

**Authentication**: Requires Firebase Auth

**Parameters**:
```typescript
{
  title: string,      // Video title
  songId: string,     // Associated song ID
  videoType: string   // 'official' | 'lyrics' | 'live'
}
```

**Returns**:
```typescript
{
  allowed: boolean,
  reason?: string  // Error message if not allowed
}
```

**Configuration Source**: Environment variables with fallbacks
- `NEXTTUBE_COOLDOWN_MINUTES` (default: 10)
- `NEXTTUBE_DAILY_LIMIT` (default: 5)
- `NEXTTUBE_DUPLICATE_WINDOW_DAYS` (default: 60)
- `NEXTTUBE_SIMILARITY_THRESHOLD` (default: 0.92)

**Checks Performed**:
1. **Cooldown Check**: Query recent uploads within cooldown window
2. **Daily Limit Check**: Count uploads in last 24 hours
3. **Official Video Uniqueness**: Ensure only one official video per song
4. **Song/Type Duplicate**: Prevent duplicate song+type combos
5. **Exact Title Duplicate**: Check normalized title matches
6. **Near-Duplicate Titles**: Calculate Jaccard similarity against recent titles

**Error Handling**:
- Returns specific error message for each violation
- Throws `HttpsError` for auth/validation failures
- Logs errors for monitoring

---

### Layer 3: Firestore Security Rules
**File**: `firestore.rules`

**Purpose**: Database-level enforcement, prevents direct database writes

**Rules**:
```javascript
match /nexttube_videos/{videoId} {
  // Only authenticated users can create videos for themselves
  allow create: if isSignedIn() 
    && request.resource.data.ownerId == request.auth.uid
    && request.resource.data.title.size() > 0
    && request.resource.data.title.size() <= 200
    && request.resource.data.type in ['official', 'lyrics', 'live']
    && request.resource.data.keys().hasAll(['normalizedTitle'])
    // Note: Rate limiting enforced by Cloud Function
    
  // Only owner can update (limited fields)
  allow update: if isOwner(resource.data.ownerId)
    && !request.resource.data.diff(resource.data).affectedKeys()
       .hasAny(['ownerId', 'songId', 'type', 'createdAt', 'title', 'normalizedTitle']);
}
```

**Limitations**:
- Firestore rules cannot efficiently query for rate limits (requires complex indexes)
- Cooldown/daily cap primarily enforced by callable function
- Rules focus on data structure validation and ownership

---

## ⚙️ Configuration

### Remote Config Parameters

Add these parameters in **Firebase Console → Remote Config**:

#### Upload Limits
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `nexttube_cooldown_minutes` | Number | 10 | Minutes between uploads |
| `nexttube_daily_upload_limit` | Number | 5 | Max uploads per 24 hours |
| `nexttube_duplicate_window_days` | Number | 60 | Days to check for duplicates |
| `nexttube_similarity_threshold` | Number | 0.92 | Near-duplicate threshold (0-1) |

#### Backend Simulation (Display Only)
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `nexRPMMinCents` | Number | 60 | Minimum RPM in cents |
| `nexRPMMaxCents` | Number | 240 | Maximum RPM in cents |
| `nexFameMultCap` | Number | 2.0 | Fame multiplier cap |
| `nexDailyViewCap` | Number | 200000 | Daily view cap per video |
| `nexSubsGainCap` | Number | 10000 | Daily subscriber gain cap |
| `nexSubsMonetize` | Number | 1000 | Subs required for monetization |
| `nexWeightOfficial` | Number | 1.0 | Official video weight |
| `nexWeightLyrics` | Number | 0.7 | Lyrics video weight |
| `nexWeightLive` | Number | 0.5 | Live video weight |
| `nexNoveltyHalfLifeDays` | Number | 14 | Novelty decay half-life |

### Environment Variables (Cloud Functions)

Set these in **Firebase Console → Functions → Configuration**:

```bash
firebase functions:config:set \
  nexttube.cooldown_minutes=10 \
  nexttube.daily_limit=5 \
  nexttube.duplicate_window_days=60 \
  nexttube.similarity_threshold=0.92
```

Or use environment variables in `functions/.env`:
```
NEXTTUBE_COOLDOWN_MINUTES=10
NEXTTUBE_DAILY_LIMIT=5
NEXTTUBE_DUPLICATE_WINDOW_DAYS=60
NEXTTUBE_SIMILARITY_THRESHOLD=0.92
```

---

## 🚀 Deployment Steps

### 1. Deploy Cloud Functions
```bash
cd functions
npm install
npm run build
firebase deploy --only functions:validateNexTubeUpload
```

### 2. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 3. Configure Remote Config
1. Open Firebase Console → Remote Config
2. Add the parameters listed above
3. Publish changes

### 4. Update Flutter App
```bash
flutter pub get
flutter build apk  # or flutter build ios
```

### 5. Verify Deployment
- Test upload flow in app
- Check Cloud Functions logs: `firebase functions:log --only validateNexTubeUpload`
- Monitor Admin Dashboard config display

---

## 📊 Admin Dashboard Usage

### View Current Limits
1. Navigate to Admin Dashboard
2. Scroll to "NexTube Configuration" section
3. See current values from Remote Config

### Refresh Configuration
1. Update values in Firebase Console → Remote Config
2. In Admin Dashboard, click **"Refresh Config"**
3. New values take effect immediately (for new uploads)

### Monitor Uploads
- Use Firebase Console → Firestore to view `nexttube_videos` collection
- Check `createdAt` timestamps for rate limit effectiveness
- Query by `ownerId` to see per-player upload patterns

---

## 🔍 How It Works: Upload Flow

```
┌─────────────────────────────────────────────────────────────┐
│  User Initiates Upload in NextTube Upload Screen            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  ❶ CLIENT VALIDATION (nexttube_upload_screen.dart)          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ • Check song selected & title entered                │   │
│  │ • Cost check (money >= production cost)              │   │
│  │ • Official video uniqueness (local Song model)       │   │
│  │ • Cooldown: Query recent uploads < X minutes ago     │   │
│  │ • Daily limit: Count uploads in last 24h             │   │
│  │ • Song/type duplicate: Query same song+type          │   │
│  │ • Exact title duplicate: Check normalized title      │   │
│  │ • Near-duplicate: Jaccard similarity > threshold     │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │ Pass ✓
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  ❷ SERVER VALIDATION (validateNexTubeUpload function)       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ • Authenticate user (Firebase Auth)                  │   │
│  │ • Load config from env vars                          │   │
│  │ • Cooldown: Query nexttube_videos (createdAt filter)│   │
│  │ • Daily limit: Count documents (last 24h)            │   │
│  │ • Official uniqueness: Query song+type='official'    │   │
│  │ • Song/type duplicate: Query song+type combo         │   │
│  │ • Exact title: Query normalizedTitle field           │   │
│  │ • Near-duplicate: Fetch recent, calculate Jaccard    │   │
│  └──────────────────────────────────────────────────────┘   │
│  Returns: { allowed: true } OR { allowed: false, reason }   │
└────────────────────┬────────────────────────────────────────┘
                     │ Allowed ✓
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  ❸ CREATE VIDEO (NextTubeService.createVideo)               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ • Generate video document ID                         │   │
│  │ • Build NextTubeVideo model                          │   │
│  │ • Add normalizedTitle field for duplicate checking   │   │
│  │ • Write to nexttube_videos collection                │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │ Write request
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  ❹ FIRESTORE RULES VALIDATION (firestore.rules)             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ • User authenticated? (isSignedIn)                   │   │
│  │ • ownerId == request.auth.uid?                       │   │
│  │ • Required fields present?                           │   │
│  │ • Title length 1-200 chars?                          │   │
│  │ • Type in ['official','lyrics','live']?              │   │
│  │ • normalizedTitle field present?                     │   │
│  │ • createdAt is valid timestamp?                      │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │ Rules pass ✓
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  ✅ VIDEO CREATED IN FIRESTORE                              │
│  • Update artist stats (deduct money)                       │
│  • Link official video to Song if type='official'           │
│  • Show success message & return to NexTube home            │
└─────────────────────────────────────────────────────────────┘
```

**Fail Points**:
- ❌ Client validation fails → User sees error, no network call
- ❌ Server validation fails → User sees "Upload blocked: [reason]"
- ❌ Firestore rules reject → Permission denied error
- ❌ Any exception → "Failed to upload: [error]"

---

## 🛡️ Security Considerations

### Why Three Layers?

1. **Client-side**: Fast UX, immediate feedback, but can be bypassed
2. **Server-side**: Authoritative enforcement, protects against modified clients
3. **Database rules**: Final defense, prevents direct Firestore writes

### Attack Vectors Prevented

✅ **Modified Client Code**
- Attacker modifies Flutter app to skip client checks
- **Mitigation**: Server function enforces same rules

✅ **Direct API Calls**
- Attacker bypasses app, calls Firestore directly
- **Mitigation**: Firestore rules require authentication and validate structure

✅ **Concurrent Uploads**
- Attacker opens multiple tabs/devices to upload simultaneously
- **Mitigation**: Server function queries current state at validation time

✅ **Clock Manipulation**
- Attacker changes device time to bypass cooldown
- **Mitigation**: Server uses `request.time` (server timestamp)

✅ **Title Obfuscation**
- Attacker uses special chars, spacing, etc. to bypass duplicate check
- **Mitigation**: Title normalization (lowercase, alphanumeric only, single spaces)

### Remaining Vulnerabilities

⚠️ **Race Conditions**
- Multiple uploads triggered within milliseconds might pass cooldown check
- **Impact**: Low (requires precise timing)
- **Mitigation**: Consider pessimistic locking or distributed counters if critical

⚠️ **Firestore Query Limits**
- If player has >500 videos, duplicate check might miss old duplicates
- **Impact**: Very low (rare edge case)
- **Mitigation**: Limit query to most recent N videos (currently 100)

---

## 🧪 Testing

### Manual Testing Checklist

#### Cooldown Test
1. Upload a video
2. Immediately try to upload another
3. Should see: "Please wait X minutes between uploads"
4. Wait cooldown period
5. Should succeed

#### Daily Limit Test
1. Upload 5 videos (or configured limit) in a day
2. Try to upload 6th video
3. Should see: "Daily upload limit reached (5 per day)"
4. Wait 24 hours or adjust date
5. Should succeed

#### Duplicate Title Test
1. Upload video with title "Test Video Official"
2. Try to upload with identical title
3. Should see: "You already used a very similar title recently"
4. Try with slightly different title "Test Video Official 2"
5. Should succeed if similarity < threshold

#### Near-Duplicate Test
1. Upload video "My Song Official Video"
2. Try to upload "My Song Official Music Video"
3. Should see: "Title looks like a near-duplicate" (if similarity > 92%)

#### Official Video Uniqueness Test
1. Upload official video for Song A
2. Try to upload another official video for Song A
3. Should see: "Song already has an official video"
4. Upload lyrics or live video for Song A
5. Should succeed

### Automated Testing

Create integration tests using Firebase Emulator:

```bash
# Start emulators
firebase emulators:start

# Run tests
flutter test integration_test/nexttube_upload_test.dart
```

---

## 📈 Monitoring & Analytics

### Key Metrics to Track

1. **Upload Success Rate**: % of uploads that pass validation
2. **Rejection Reasons**: Which rules are triggering most often
3. **Daily Upload Distribution**: Peak hours, player patterns
4. **Duplicate Detection Accuracy**: False positives vs. true duplicates

### Firebase Console Queries

**Recent Uploads**:
```javascript
nexttube_videos
  .orderBy('createdAt', 'desc')
  .limit(50)
```

**Uploads by Player**:
```javascript
nexttube_videos
  .where('ownerId', '==', 'USER_ID')
  .orderBy('createdAt', 'desc')
```

**Videos in Last 24h**:
```javascript
nexttube_videos
  .where('createdAt', '>=', new Date(Date.now() - 86400000))
  .orderBy('createdAt', 'desc')
```

### Cloud Functions Logs

```bash
# View validation logs
firebase functions:log --only validateNexTubeUpload

# Filter by user
firebase functions:log --only validateNexTubeUpload | grep "USER_ID"
```

---

## 🔧 Troubleshooting

### Issue: Client shows limit but server allows upload
**Cause**: Remote Config not synced with server env vars
**Fix**: Ensure both are set to same values

### Issue: Server validation always fails
**Cause**: Environment variables not set
**Fix**: Run `firebase functions:config:get` and verify values

### Issue: Firestore rules reject valid upload
**Cause**: Missing required fields or incorrect data types
**Fix**: Check rules match actual data structure in `createVideo`

### Issue: Duplicate check doesn't catch similar titles
**Cause**: Threshold too high or normalization not working
**Fix**: Lower `nexttube_similarity_threshold` or improve normalization

### Issue: Admin dashboard shows wrong values
**Cause**: Remote Config not refreshed
**Fix**: Click "Refresh Config" button or restart app

---

## 🎓 Best Practices

### For Developers

1. **Always test both client and server** - Don't assume client validation is enough
2. **Log rejections** - Track why uploads fail to improve UX
3. **Use specific error messages** - Help users understand what went wrong
4. **Monitor performance** - Firestore queries can be expensive at scale
5. **Keep rules simple** - Complex Firestore rules are hard to debug

### For Admins

1. **Start conservative** - Stricter limits are easier to loosen than tighten
2. **Monitor abuse patterns** - Adjust limits based on player behavior
3. **Communicate changes** - Notify players when limits change significantly
4. **Test in staging** - Validate config changes before production
5. **Document decisions** - Record why limits were set at specific values

### Recommended Configurations

**Lenient (Early Access)**:
- Cooldown: 5 minutes
- Daily limit: 10 uploads
- Similarity: 0.85

**Balanced (Production)**:
- Cooldown: 10 minutes
- Daily limit: 5 uploads
- Similarity: 0.92

**Strict (High Abuse)**:
- Cooldown: 30 minutes
- Daily limit: 3 uploads
- Similarity: 0.95

---

## 📚 Related Documentation

- [NexTube Feature Overview](./NEXTTUBE_FEATURE.md)
- [Remote Config Guide](./REMOTE_CONFIG_GUIDE.md)
- [Cloud Functions Development](./FUNCTIONS_DEVELOPMENT.md)
- [Firestore Security Rules](./FIRESTORE_RULES.md)

---

## 🆘 Support

### Getting Help

1. Check Firebase Functions logs for errors
2. Review Admin Dashboard for current config
3. Test upload flow in Firebase Emulator locally
4. Verify Firestore rules in Firebase Console → Firestore → Rules

### Common Questions

**Q: Can I change limits without redeploying?**
A: Yes! Update Remote Config values. Cloud Function env vars require redeployment.

**Q: How do I disable upload limits temporarily?**
A: Set very high values (e.g., cooldown: 0, daily limit: 999)

**Q: Can users see why they're blocked?**
A: Yes, both client and server return specific error messages

**Q: What happens if Remote Config fails?**
A: App uses default fallback values defined in `RemoteConfigService`

---

## 📝 Changelog

### v1.0.0 (2025-10-27)
- ✅ Initial implementation
- ✅ Client-side validation with Remote Config
- ✅ Server-side callable function
- ✅ Enhanced Firestore rules
- ✅ Admin dashboard integration
- ✅ Comprehensive documentation

---

**Last Updated**: October 27, 2025  
**Maintained By**: NextWave Development Team  
**Version**: 1.0.0
