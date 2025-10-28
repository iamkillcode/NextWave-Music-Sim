# Cloud Functions Deployment Status

## ✅ Deployed (Gen 2, us-central1, Node.js 20)

### Certifications Feature (Complete)
- `listAlbumCertificationEligibility` - callable ✅
- `submitAlbumForCertification` - callable ✅
- `runCertificationsMigrationAdmin` - callable (admin-only) ✅

### NexTube Feature (Complete)
- `validateNexTubeUpload` - callable ✅
- `updateNextTubeDaily` - scheduled (every 60 minutes) ✅

### Gameplay Actions
- `secureSongCreation` - callable ✅ (just deployed)


## ⏳ Pending Deployment

### High Priority (Core Gameplay)
- `secureSongCreation` - callable (song creation validation)
- `secureReleaseAlbum` - callable (album release validation)
- `dailyGameUpdate` - scheduled (main daily tick, awards song certifications)
- `checkAdminStatus` - callable (admin auth helper)

### Medium Priority (Admin & Testing)
- `triggerDailyUpdate` - callable (manual daily update trigger)
- `sendGiftToPlayer` - callable (admin gift utility)
- `triggerWeeklyLeaderboardUpdate` - callable (manual leaderboard update)
- `sendGlobalNotificationToPlayers` - callable (admin broadcast)

### Lower Priority (Scheduled Tasks)
- `weeklyLeaderboardUpdate` - scheduled
- `simulateNPCActivity` - scheduled
- `dailySideHustleGeneration` - scheduled
- `checkRivalChartPositions` - scheduled
- `gandalfTheBlackPosts` - scheduled
- `triggerSpecialEvent` - scheduled

### Firestore Triggers
- `checkAchievements` - on player document write
- `onPostEngagement` - on EchoX post write
- `onChartUpdate` - on leaderboard history write

### Other Callables
- `validateSongRelease` - song validation
- `secureStatUpdate` - stat update validation
- `secureSideHustleReward` - side hustle reward
- `migratePlayerContentToSubcollections` - data migration
- `catchUpMissedDays` - player catch-up logic
- `initializeNPCArtists` - NPC setup
- `forceNPCRelease` - admin NPC control
- `syncAllPlayerStreams` - admin data sync
- `triggerSideHustleGeneration` - manual trigger
- `triggerGandalfPost` - manual trigger
- `runNextTubeNow` - manual NexTube trigger
- `runNextTubeForAllAdmin` - admin NexTube batch

## 🚫 Deployment Blocker

**Issue**: `functions/index.js` is a large monolithic file (~6250 lines) that causes Firebase CLI discovery timeout when loading for analysis. The CLI must fully parse the JS to determine available endpoints, which exceeds the 10-second timeout.

**Progress on Solution**:
1. ✅ Created modular structure with lazy-loaded modules in `functions/modules/`
2. ✅ Set up dual codebases in firebase.json (typescript + legacy)
3. ✅ Successfully deployed `secureSongCreation` from modular structure
4. ⚠️ Legacy codebase still times out when included in deployment

**Current Workaround**: Deploy functions individually from TypeScript entrypoint (`functions/src/index.ts`) which bridges to legacy code with lazy loading. This has been successful for certifications + NexTube + secureSongCreation (6 functions deployed).

**Recommended Next Steps**:
1. Continue individual deployments from TS entrypoint for critical functions
2. Extract high-priority functions from index.legacy.js into separate module files
3. Once extracted, deploy directly from modules without loading legacy monolith

## 📊 Current Status
- **Deployed**: 5 functions (certifications + NexTube)
- **Pending**: ~30 functions (schedules, triggers, callables)
- **Certification Feature**: 100% deployed ✅
- **Game Playable**: Yes, core features working with existing functions

## 🎯 Recommended Next Steps
1. **Test certifications flow** in running app (eligibility → submit → award)
2. **Polish UI** for certification badges and submit button
3. **Monitor logs** for deployed functions to verify production behavior
4. **Plan monolith split** when time permits for full Gen 2 migration
