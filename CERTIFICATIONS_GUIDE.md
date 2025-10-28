# Certifications (RIAN) System

This document describes how song and album certifications work in NextWave.

## Overview
- Units = sales + floor(streams / certStreamsPerUnit)
- Tiers (tunable via Remote Config): Silver, Gold, Platinum, Multi-Platinum (levels), Diamond
- Songs: awarded automatically during the daily update when thresholds are crossed
- Albums: manual submit flow (player triggers), validated and awarded on submit
- NPC artists are included (they run via the same daily update)
- Rewards: small money + fame per tier; values tunable via Remote Config

## Remote Config Keys
- certEnabled (bool)
- certStreamsPerUnit (number; default 150)
- certSilverUnits, certGoldUnits, certPlatinumUnits, certMultiPlatinumStepUnits, certDiamondUnits
- certSongRewardMoney, certSongRewardFame
- certAlbumRewardMoney, certAlbumRewardFame
- certNexViewsBoostPerTier, certNexRpmBoostPerTier (small boosts to NexTube)

See `nextwave/remote_config_template.json` and `nextwave/add_rc_params.json` for defaults.

## Data Model Fields
On Song and Album models:
- eligibleUnits: number
- highestCertification: string (none|silver|gold|platinum|multi_platinum|diamond)
- certificationLevel: number (0 if none; >1 for multi-platinum levels)
- lastCertifiedAt: timestamp
- totalSales: number (default 0)

## Firestore Writes
- players/{playerId}.songs[]: updated fields included above
- players/{playerId}/certifications: documents created for each award
- players/{playerId}/notifications: 'certification_awarded' entries on award

## Cloud Functions

### Deployed Endpoints (Gen 2, us-central1)

**listAlbumCertificationEligibility** (callable)
- URL: `https://us-central1-nextwave-music-sim.cloudfunctions.net/listAlbumCertificationEligibility`
- Returns albums eligible for the next tier
- Response: `{ albums: [{ id, title, units, currentTier, currentLevel, nextTier, nextLevel, eligibleNow }] }`
- Auth: Requires authenticated user; reads from caller's player document

**submitAlbumForCertification** (callable)
- URL: `https://us-central1-nextwave-music-sim.cloudfunctions.net/submitAlbumForCertification`
- Validates and awards album certification + rewards
- Request: `{ albumId: string }`
- Response: `{ awarded: bool, tier?: string, level?: number, units?: number, message?: string }`
- Auth: Requires authenticated user; validates caller owns the album

**runCertificationsMigrationAdmin** (callable, admin-only)
- URL: `https://us-central1-nextwave-music-sim.cloudfunctions.net/runCertificationsMigrationAdmin`
- Retroactively awards certifications for existing catalog
- Request: `{ playerId: string, dryRun?: bool }`
- Response: `{ migrated: bool, changed: number, awarded: number }`
- Auth: Requires admin role (validated server-side)

### Other Functions (Scheduled/Triggered)
- dailyGameUpdate (scheduled): computes song units and awards song certifications
- updateNextTubeDaily / runNextTubeNow: apply small boosts for certified songs

## Admin / Testing
- Use `runCertificationsMigrationAdmin` with a playerId to migrate existing catalogs
- Use `listAlbumCertificationEligibility` to surface album candidates for submit
- Song awards happen automatically in `dailyGameUpdate`

## Client Integration

### Flutter/Dart Usage

**Service Layer:** `lib/services/certifications_service.dart`

```dart
import 'package:cloud_functions/cloud_functions.dart';

final _functions = FirebaseFunctions.instance;

// List eligible albums for the current user
Future<List<AlbumEligibility>> listAlbumEligibility() async {
  final res = await _functions
      .httpsCallable('listAlbumCertificationEligibility')
      .call();
  final data = Map<String, dynamic>.from((res.data as Map?) ?? {});
  final albums = ((data['albums'] as List?) ?? [])
      .map((e) => Map<String, dynamic>.from((e as Map?) ?? {}))
      .toList();
  return albums.map((m) => AlbumEligibility.fromJson(m)).toList();
}

// Submit an album for certification
Future<SubmitResult> submitAlbum(String albumId) async {
  final res = await _functions
      .httpsCallable('submitAlbumForCertification')
      .call({'albumId': albumId});
  final data = Map<String, dynamic>.from((res.data as Map?) ?? {});
  return SubmitResult.fromJson(data);
}

// Run migration (admin only)
Future<MigrationResult> runMigrationForPlayer(String playerId) async {
  final res = await _functions
      .httpsCallable('runCertificationsMigrationAdmin')
      .call({'playerId': playerId});
  final data = Map<String, dynamic>.from((res.data as Map?) ?? {});
  return MigrationResult.fromJson(data);
}
```

**Auth Context:** All callables automatically receive Firebase Auth context. Ensure the user is signed in before calling.

**Models:**
- Song and Album models updated in `lib/models/song.dart` and `lib/models/album.dart`
- Service models: `AlbumEligibility`, `SubmitResult`, `MigrationResult` in `certifications_service.dart`

**UI:**
- Add badges on song/album cards showing certification tier
- Add submit button for eligible albums (call `submitAlbum`)
- Add admin button to run migration (call `runMigrationForPlayer`)

## Notes
- All thresholds and rewards are RC-driven and can be tuned without redeploy
- Awarding is idempotent by comparing previous tier/level to computed tier/level
- Security: server re-validates album release state and thresholds on submit
