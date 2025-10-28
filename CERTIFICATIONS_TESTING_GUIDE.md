# Certifications Feature Testing Guide

## Setup Requirements
- Firebase project: nextwave-music-sim
- Flutter app running with authenticated user
- At least one released album with some sales/streams

## Test Scenarios

### 1. Album Eligibility Check
**Location**: Album Detail Screen

**Steps**:
1. Navigate to an album you own
2. Check if eligibility info appears below the album art
3. Expected display:
   - Current tier badge (if any)
   - Eligibility text showing next tier and required units
   - Submit button (if eligible now)

**Expected Behavior**:
- If eligible: Green "Submit for Certification" button appears
- If not eligible: Gray text showing units needed
- Units calculation: `totalSales + floor(totalStreams / certStreamsPerUnit)`

### 2. Submit for Certification
**Location**: Album Detail Screen

**Prerequisites**: Album must be eligible for next tier

**Steps**:
1. Click "Submit for Certification (TierName)" button
2. Button should show loading spinner
3. Wait for response

**Expected Results**:
- **Success**: Green snackbar "Awarded [tier] [level]", badge appears, button disappears
- **Failure**: Orange/red snackbar with reason
- Album UI updates immediately to show new certification

**Validation**:
- Check Firestore: `players/{uid}/certifications` collection should have new doc
- Album document should update: `highestCertification`, `certificationLevel`, `lastCertifiedAt`
- Player should receive money + fame reward

### 3. Admin Migration (Admin Only)
**Location**: Dashboard > Admin Panel > Certifications

**Prerequisites**: User must have admin role

**Steps**:
1. Open admin panel
2. Find "Admin: Certifications" section
3. Enter a player ID (or leave blank for self)
4. Click "Run Migration"
5. Check the result dialog

**Expected Results**:
- Shows count of albums migrated and certifications awarded
- Can see "migrated: true, changed: X, awarded: Y"
- Check player's songs and albums for retroactively awarded certifications

**Validation**:
- Songs with sufficient units should have `highestCertification` != 'none'
- Albums with sufficient units should be certified
- All awards should have corresponding docs in `/certifications` subcollection

## Common Issues

### "Not eligible yet"
- Verify album has enough units for next tier
- Check Remote Config: `certSilverUnits`, `certGoldUnits`, etc.
- Formula: `eligibleUnits = totalSales + floor(totalStreams / certStreamsPerUnit)`

### Submit button not appearing
- Ensure album has `eligibleUnits` field populated
- Check that backend function is deployed: `firebase functions:list` should show `submitAlbumForCertification`
- Verify user is authenticated

### "User code failed to load" during submit
- This is a backend error - check Cloud Functions logs
- Verify function is in ACTIVE state
- Check IAM permissions (run.invoker should include allUsers)

## Firestore Data Structure

### Player Document
```
players/{playerId}/
  - currentMoney: number (incremented on award)
  - currentFame: number (incremented on award)
  - songs: array
    - eligibleUnits: number
    - highestCertification: string
    - certificationLevel: number
    - lastCertifiedAt: timestamp
```

### Album Document  
```
players/{playerId}/albums/{albumId}
  - eligibleUnits: number
  - highestCertification: string
  - certificationLevel: number
  - lastCertifiedAt: timestamp
  - totalSales: number
  - totalStreams: number
```

### Certification Records
```
players/{playerId}/certifications/{docId}
  - type: 'song' | 'album'
  - contentId: string
  - tier: string
  - level: number
  - units: number
  - awardedAt: timestamp
```

## Remote Config Parameters

Key configuration values (see `remote_config_template.json`):

- `certEnabled`: boolean (feature flag)
- `certStreamsPerUnit`: 150 (streams needed per unit)
- `certSilverUnits`: 500
- `certGoldUnits`: 1000
- `certPlatinumUnits`: 2000
- `certMultiPlatinumStepUnits`: 2000 (increment per multi-platinum level)
- `certDiamondUnits`: 10000
- `certSongRewardMoney`: 5000 (dollars per song certification)
- `certSongRewardFame`: 100 (fame per song certification)
- `certAlbumRewardMoney`: 10000 (dollars per album certification)
- `certAlbumRewardFame`: 200 (fame per album certification)

## Cloud Functions URLs

All deployed to us-central1:

- `https://us-central1-nextwave-music-sim.cloudfunctions.net/listAlbumCertificationEligibility`
- `https://us-central1-nextwave-music-sim.cloudfunctions.net/submitAlbumForCertification`
- `https://us-central1-nextwave-music-sim.cloudfunctions.net/runCertificationsMigrationAdmin`

## Success Criteria

✅ Feature is working if:
1. Album detail screen shows eligibility status
2. Submit button appears when eligible
3. Clicking submit awards certification and shows success message
4. Badge appears on album after award
5. Player receives money + fame rewards
6. Firestore documents update correctly
7. Admin migration successfully processes existing content
