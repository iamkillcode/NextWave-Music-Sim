# Beef Resolution Mechanics

## Overview
The Beef/Banter system allows artists to start feuds with diss tracks and compete for fame. Beefs automatically resolve after **42 in-game days** (84 real hours) with clear winner determination rules.

## Resolution Timeline
- **42 in-game days** = **84 real hours** (since 1 in-game day = 2 real hours)
- Auto-resolve runs daily at **2 AM** via scheduled Cloud Function
- Timer counts from `lastActivityAt` timestamp

## Resolution Scenarios

### ✅ 1. Natural Resolution (Both Responded)
**Condition:** 42 days pass after both artists dropped diss tracks

**Winner Calculation:**
```javascript
Performance Score = (streams × 50%) + (engagement × 30%) + (quality × 20%)
```

**Outcomes:**
- **Clear Winner** (>10% score difference):
  - Winner: 75-200+ fame (based on fame multiplier)
  - Loser: 40-75 fame (participation bonus)
  
- **Draw** (<10% score difference):
  - Both: 60 fame (mutual respect)

**Fame Multiplier Logic:**
```dart
if (target.fame > instigator.fame && targetResponded) {
  multiplier = 1 + ((targetFame - instigatorFame) / 500).clamp(0, 3);
  instigatorFame = 50 * multiplier * (win ? 1.5 : 1.0);
}
```

### ✅ 2. No Response Victory
**Condition:** 42 days pass with no response from target

**Outcome:**
- Instigator: **+25 fame** (minimal/hollow victory)
- Target: **-10 fame** (penalty for ignoring)
- Status: `resolved` with `winType: 'no_response'`

**News Post:** "X wins by default - Y never responded"

### ✅ 3. Knockout Victory
**Condition:** One diss track gets **3x more streams** than opponent

**Triggers:** Immediate win (doesn't wait 42 days)

**Outcome:**
- Winner: **150-450 fame** (with fame multiplier)
- Loser: **40 fame** (participation)
- Status: `resolved` with `winType: 'knockout'`

**Fame Formula:**
```javascript
if (instigatorStreams / targetStreams >= 3.0) {
  fameDiff = Math.abs(targetFame - instigatorFame);
  multiplier = 1 + Math.min(fameDiff / 500, 3.0);
  fameGain = Math.floor(150 * multiplier);
}
```

**News Post:** "🏆 KNOCKOUT! X DESTROYS Y with 3x the streams!"

### ✅ 4. Admin Intervention
**Condition:** Manual moderation ends beef early

**Outcome:**
- Custom fame awards based on admin decision
- Status: `resolved` with `winType: 'admin_intervention'`
- Can be used for policy violations or community guidelines

## Fame Gain Summary

| Scenario | Instigator Fame | Target Fame | Notes |
|----------|----------------|-------------|-------|
| **No Response** | +25 | -10 | Hollow victory |
| **Draw** | +60 | +60 | Mutual respect |
| **Win (Equal Fame)** | +75 | +75 | Base rewards |
| **Win (Higher Fame Target)** | +150-300 | +75 | 2-4x multiplier |
| **Knockout** | +150-450 | +40 | Dominant victory |
| **Loss** | +40-50 | +110 | Participation |

## Key Mechanics

### Fame Multiplier Triggers
The instigator only gets high fame multipliers if:
1. Target **has MORE fame** than instigator at beef start
2. Target **responds** with a diss track
3. Instigator **wins** the beef

Example:
- Instigator (500 fame) vs Target (2000 fame)
- If target responds and instigator wins:
  - Fame diff = 1500
  - Multiplier = 1 + (1500/500) = 4.0 (capped at 3.0)
  - Fame gain = 50 × 3.0 × 1.5 = **225 fame**

### Knockout Detection
```javascript
if (instigatorStreams / targetStreams >= 3.0) {
  // Instigator knockout
} else if (targetStreams / instigatorStreams >= 3.0) {
  // Target knockout
}
```

### Resolution Check
```dart
bool isReadyForResolution() {
  const resolutionPeriod = Duration(hours: 84); // 42 in-game days
  final timeSinceStart = DateTime.now().difference(startedAt);
  return status == BeefStatus.active && timeSinceStart >= resolutionPeriod;
}
```

## Cloud Functions

### `startBeef` (Callable)
**Parameters:**
- `targetId`: Artist to beef with
- `dissTrackId`: Diss track song ID
- `dissTrackTitle`: Track title

**Creates:**
- Beef document in `beefs` collection
- Notification to target
- News post by Gandalf The Black

**Records:**
- Both players' current fame (for multiplier calculation)
- Start timestamp (`lastActivityAt`)

### `respondToBeef` (Callable)
**Parameters:**
- `beefId`: Beef to respond to
- `responseDissTrackId`: Response track ID
- `responseDissTrackTitle`: Track title

**Updates:**
- Sets `targetResponded = true`
- Updates `lastActivityAt` (resets 42-day timer)
- Creates response record
- Sends notification to instigator
- Creates news post

### `autoResolveBeefs` (Scheduled)
**Schedule:** Daily at 2 AM (`'0 2 * * *'`)

**Process:**
1. Query active beefs with `lastActivityAt <= 84 hours ago`
2. For each beef:
   - Get both diss tracks
   - Calculate winner with `calculateBeefWinner()`
   - Update beef status to `resolved`
   - Award fame to both players
   - Send notifications
   - Create news post

## UI Integration

### Banter Screen
- Display active beefs with 42-day countdown timer
- Show beef history with outcomes
- "Start Beef" button with target selection
- Real-time updates via StreamBuilder

### Studio Integration
- "Write Diss Track" option
- Select target from artists list
- Calls `startBeef` Cloud Function on release
- Marks song as `isDissTrack: true`

### Media Hub
- Add "Banter" app to Misc section
- Icon: 🔥 or 💥
- Badge for active beefs count

## Security Rules

```javascript
match /beefs/{beefId} {
  // Only Cloud Functions can create/update beefs
  allow create, update: if false;
  
  // Users can read their own beefs
  allow read: if request.auth.uid == resource.data.instigatorId
           || request.auth.uid == resource.data.targetId;
}
```

## Firestore Indexes

```json
{
  "collectionGroup": "beefs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "lastActivityAt", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "beefs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "instigatorId", "order": "ASCENDING" },
    { "fieldPath": "startedAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "beefs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "targetId", "order": "ASCENDING" },
    { "fieldPath": "startedAt", "order": "DESCENDING" }
  ]
}
```

## Testing Scenarios

### Test 1: No Response
1. Player A starts beef with Player B (500 fame vs 1000 fame)
2. Wait 84 hours
3. Verify: A gets +25 fame, B gets -10 fame

### Test 2: Knockout
1. Player A starts beef (1000 streams on diss track)
2. Player B responds (200 streams)
3. Verify: Immediate resolution, A wins with 5x fame multiplier

### Test 3: Close Match
1. Both respond with similar streams/quality
2. Wait 42 days
3. Verify: Draw declared, both get +60 fame

### Test 4: Fame Multiplier
1. Low-fame artist (200) beefs high-fame artist (2000)
2. High-fame artist responds
3. Low-fame artist wins
4. Verify: Gets 200+ fame (10x multiplier)

## Next Steps
1. ✅ Cloud Functions implemented
2. ⏳ Create BeefService for client-side calls
3. ⏳ Build Banter UI screen
4. ⏳ Integrate into Studio
5. ⏳ Deploy Firestore rules and indexes
6. ⏳ Test resolution scenarios
