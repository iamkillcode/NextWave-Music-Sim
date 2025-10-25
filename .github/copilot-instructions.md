# NextWave Music Sim - AI Coding Agent Instructions

## Project Overview
NextWave is a **multiplayer Flutter/Firebase music artist life simulation game** where players create songs, build fanbases, and compete on global charts. 1 real-world hour = 1 in-game day. The game uses a hybrid client/server architecture with Firebase Cloud Functions handling critical multiplayer updates.

## Critical Architecture Patterns

### 1. Global Time System (Server-Authoritative)
**All game time calculations MUST use Firebase server time, never device time.**

```dart
// ✅ CORRECT - Use GameTimeService
final gameDate = await _gameTimeService.getCurrentGameDate();

// ❌ WRONG - Never use device time for game logic
final now = DateTime.now(); // Only for UI timers
```

**Why:** Prevents time manipulation and ensures multiplayer fairness. See `lib/services/game_time_service.dart` and `docs/systems/GLOBAL_TIME_SYSTEM.md`.

**Formula:** `gameDaysElapsed = realHoursElapsed ÷ 1`
- Reference date: Jan 1, 2020 (game start)
- Real start: Configured in `gameSettings/globalTime` Firestore doc

### 2. Firebase Sync Strategy (Three-Tier)
**Use the appropriate save method based on multiplayer impact:**

```dart
// IMMEDIATE - Critical multiplayer events (songs, regions, achievements)
_immediateSave(); // 0ms delay

// DEBOUNCED - Rapid UI interactions (energy, money, skills)
_debouncedSave(); // 500ms delay, batches rapid changes

// AUTO-SAVE - Runs every 30s automatically for passive progress
// (No manual call needed - just ensure _hasPendingSave flag is set)
```

**Decision tree:** Publishing content → Immediate. Stat changes → Debounced.
See `docs/guides/SAVE_STRATEGY_QUICK_REFERENCE.md` and `docs/features/MULTIPLAYER_SYNC_STRATEGY.md`.

### 3. Immutable State with copyWith Pattern
**All models (ArtistStats, Song, Album, etc.) are immutable. Always use copyWith():**

```dart
// ✅ CORRECT
artistStats = artistStats.copyWith(
  money: artistStats.money - cost,
  energy: artistStats.energy - 10,
);

// ❌ WRONG - Models are const, fields are final
artistStats.money -= cost; // Compile error
```

Models location: `lib/models/` - All include `.copyWith()` and `.toJson()`/`.fromJson()` methods.

### 4. Firestore Sanitization (Mandatory)
**Always sanitize data before writing to Firestore to prevent NaN/Infinity errors:**

```dart
import '../utils/firestore_sanitizer.dart';

// Before any .set() or .update()
await docRef.update(sanitizeForFirestore({
  'money': artistStats.money,
  'skills': skillsMap, // Handles nested maps/lists
}));
```

**Why:** Firebase rejects non-finite numbers. The sanitizer recursively replaces NaN/Infinity with 0.
See `lib/utils/firestore_sanitizer.dart`.

### 5. Screen Communication Pattern
**Screens use callbacks to propagate state changes up to DashboardScreen:**

```dart
// In child screen (e.g., MusicHubScreen)
final Function(ArtistStats) onStatsUpdated;

// When stats change
widget.onStatsUpdated(updatedStats);

// In DashboardScreen
Navigator.push(context, MaterialPageRoute(
  builder: (context) => MusicHubScreen(
    artistStats: artistStats,
    onStatsUpdated: (updatedStats) {
      setState(() => artistStats = updatedStats);
      _immediateSave(); // Choose appropriate save method
    },
  ),
));
```

**Key files:** `lib/screens/dashboard_screen_new.dart` (main hub), all screens accept `onStatsUpdated` callback.

## Service Layer Architecture

### Core Services (Singleton Pattern)
All services use factory constructors for single instances:

- **FirebaseService** - Main multiplayer sync (auth, Firestore, Functions)
- **GameTimeService** - Server-synchronized time calculations
- **StreamGrowthService** - Song stream progression with decay/virality
- **SideHustleService** - Passive income contracts
- **NotificationService** - In-game news/achievements
- **AdminService** - Admin panel operations (player management, gifts)

```dart
final _gameTimeService = GameTimeService(); // Gets singleton instance
```

### Firebase vs DemoFirebaseService
Two implementations with identical interfaces:
- **FirebaseService** - Real Firebase (multiplayer mode)
- **DemoFirebaseService** - In-memory fake (offline demo mode)

Switch based on `FirebaseStatus.isConfigured()` check in `lib/utils/firebase_status.dart`.

## Firebase Cloud Functions

**Location:** `functions/index.js` (Node.js 20)

**Critical scheduled functions:**
- `dailyGameUpdate` - Runs every hour (1 in-game day). Processes ALL players:
  - Stream growth with decay algorithm
  - Daily income from royalties
  - Energy replenishment (daily reset to 100)
  - Side hustle income/expiration
  - Song aging and catalog transitions
  
- `weeklyChartUpdate` - Weekly leaderboard snapshots

**Anti-Pattern:** Never calculate stream growth or passive income client-side for multiplayer fairness. Cloud Functions are the source of truth.

**Deployment:** 
```powershell
cd functions
firebase deploy --only functions
```

See `functions/package.json` for Node 20 requirement and `DEPLOY_CLOUD_FUNCTIONS.md`.

## Data Models & Collections

### Firestore Structure
```
players/
  {userId}/
    displayName, primaryGenre, totalStreams, money, energy, skills, etc.
    songs: [] (embedded array of Song objects)
    albums: [] (embedded array of Album objects)
    pendingPractices: [] (ongoing skill training)

gameSettings/
  globalTime: {realWorldStartDate, gameWorldStartDate, hoursPerDay}

notifications/
  {userId}/
    notifications: [] (in-game news/achievements)
```

### Key Models
- **ArtistStats** (`lib/models/artist_stats.dart`) - Main player state (money, energy, skills, songs, albums)
- **Song** (`lib/models/song.dart`) - Song lifecycle (Written → Recorded → Released), includes streams, regionalStreams, viralityScore
- **Album** (`lib/models/album.dart`) - Multi-song releases (EP: 3-6 songs, Album: 7+)
- **SideHustle** (`lib/models/side_hustle.dart`) - Passive income contracts with real-time duration

**Important:** Songs array is embedded in player docs, NOT a separate collection. Cloud Functions update song streams directly in player documents.

## Development Workflows

### Running the App
```powershell
# Web (primary platform)
flutter run -d chrome

# Build for production
flutter build web

# Deploy to GitHub Pages
npx gh-pages -d build/web
```

### Firebase Setup
```powershell
# Windows PowerShell script
.\setup_firebase.ps1

# Or manual
flutterfire configure
```

### Testing
```powershell
# Cloud Functions tests
cd functions
npm test

# Flutter tests
flutter test
```

### Common Debug Commands
```powershell
# Check Firebase config
flutter pub run firebase_core:version

# Clear build cache (if hot reload fails)
flutter clean ; flutter pub get
```

## Project-Specific Conventions

### File Organization
- `lib/screens/` - Full-page UI screens (all StatefulWidget)
- `lib/widgets/` - Reusable components (e.g., `glassmorphic_bottom_nav.dart`)
- `lib/services/` - Business logic and Firebase interactions
- `lib/models/` - Data classes (immutable, use `@immutable` annotation where applicable)
- `lib/utils/` - Helpers (e.g., `firestore_sanitizer.dart`, `firebase_status.dart`)
- `docs/` - Extensive documentation (systems, features, fixes, guides)

### Naming Patterns
- Screens: `*_screen.dart` (e.g., `dashboard_screen_new.dart`)
- Services: `*_service.dart` (singleton pattern)
- Models: Entity name (e.g., `song.dart`, `artist_stats.dart`)
- Utils: Descriptive function name (e.g., `firestore_sanitizer.dart`)

### Code Style
- Follow `analysis_options.yaml` lints
- Use `const` constructors where possible for performance
- Prefer `late` over nullable fields for initialization in `initState()`
- Always dispose Timers and StreamSubscriptions in `dispose()`

### Documentation References
When implementing features, check:
1. `docs/DOCUMENTATION_INDEX.md` - Master index of all documentation
2. `docs/systems/` - Core game mechanics (time, charts, NPCs)
3. `docs/guides/SAVE_STRATEGY_QUICK_REFERENCE.md` - When to save to Firebase
4. `docs/features/MULTIPLAYER_SYNC_STRATEGY.md` - Sync patterns and cost analysis
5. `README.md` - Player-facing game overview and setup

## Genre System & Gameplay Calculations

### Genre Architecture
**11 supported genres:** R&B, Hip Hop, Rap, Pop, Trap, Drill, Afrobeat, Country, Jazz, Reggae, Gospel
- Canonical list in `lib/utils/genres.dart`
- Each genre has themed icon/color for UI

### Genre Mastery System
Players progress in genres (0-100 scale) by writing songs:

```dart
// Mastery gain formula (in artist_stats.dart)
int baseGain = effortLevel * 5;  // 1-4 effort = 5-20 base points
int qualityBonus = (songQuality / 100 * 15).round();  // 0-15 bonus
int totalGain = (baseGain + qualityBonus).clamp(5, 35);  // 5-35 per song
```

**Mastery levels:** Beginner (0) → Novice (10+) → Learning (20+) → Intermediate (30+) → Competent (40+) → Skilled (50+) → Proficient (60+) → Advanced (70+) → Expert (80+) → Master (90+)

### Genre Impact on Gameplay

**1. Song Quality Bonus**
```dart
// Genre mastery multiplies song quality (artist_stats.dart)
double masteryBonus = 1.0 + (genreMasteryLevel / 100.0 * 0.3);
// Examples:
// 0% mastery = 1.0x (no bonus)
// 50% mastery = 1.15x (+15% quality)
// 100% mastery = 1.3x (+30% quality boost!)
```

**2. Stream Growth Bonus**
```dart
// From stream_growth_service.dart
final genreMastery = artistStats.genreMastery[song.genre] ?? 0;
final masteryStreamBonus = 1.0 + (genreMastery / 100.0 * 0.5);
// 100% mastery = +50% streams
```

**3. Regional Popularity Multipliers**
Genres perform differently in each region (see `lib/models/world_region.dart`):

```dart
// Regional popularity affects stream potential
double getStreamingPotential(String genre) {
  final genrePop = genrePopularity[genre.toLowerCase()] ?? 0.5;
  return marketSize * avgIncomeLevel * genrePop;
}
```

**Example regional modifiers:**
- **Drill:** UK (0.95), USA (0.7), Europe (0.7), Canada (0.75)
- **Afrobeat:** Africa (1.0), UK (0.85), USA (0.6), Asia (0.55)
- **Country:** USA (0.8), Oceania (0.55), Canada (0.5), UK (0.3)
- **Reggae:** Latin America (0.95), Africa (0.75), UK (0.65), USA (0.55)

**Strategic implications:** 
- Travel to regions where your genre is popular (higher streams)
- Master multiple genres to succeed in different markets
- Primary genre unlocked at start, others unlock through gameplay

**Key files:**
- `lib/models/artist_stats.dart` - Mastery calculation methods
- `lib/models/world_region.dart` - Regional popularity data
- `lib/utils/genres.dart` - Genre definitions and UI
- `lib/services/stream_growth_service.dart` - Mastery stream bonus

## Common Pitfalls to Avoid

1. **❌ Using DateTime.now() for game logic** - Always use GameTimeService
2. **❌ Direct Firestore writes without sanitization** - Use sanitizeForFirestore()
3. **❌ Mutating state directly** - Use copyWith() for immutability
4. **❌ Client-side stream/income calculations in multiplayer** - Cloud Functions handle this
5. **❌ Forgetting to call save methods after state changes** - Use _immediateSave() or _debouncedSave()
6. **❌ Not handling null currentGameDate** - Dashboard initializes to null, check before use
7. **❌ Mixing save strategies** - Be consistent per feature (see SAVE_STRATEGY_QUICK_REFERENCE.md)
8. **❌ Long catch-up calculations on client** - Deprecated pattern, server handles missed days
9. **❌ Ignoring genre mastery in calculations** - Always check genreMastery map when calculating quality/streams
10. **❌ Hardcoding genre popularity values** - Use WorldRegion.getRegionalMultiplier()

## Quick Reference

**Start exploring from:**
- Main entry: `lib/main.dart` → `lib/screens/dashboard_screen_new.dart`
- Firebase integration: `lib/services/firebase_service.dart`
- Time system: `lib/services/game_time_service.dart`
- Stream growth: `lib/services/stream_growth_service.dart`
- Cloud Functions: `functions/index.js`

**When adding new features:**
1. Determine if multiplayer-visible → Choose save strategy
2. Check if time-dependent → Use GameTimeService
3. Add model changes → Include copyWith() method
4. Update Cloud Functions if server-side logic needed
5. Sanitize before Firestore writes
6. Document in `docs/features/` with completion status

**Key External Dependencies:**
- Flutter SDK 3.35.6+, Dart 3.5+
- Firebase (Auth, Firestore, Functions, Analytics, Remote Config)
- Node.js 20 for Cloud Functions
- Google Sign-In, Image Picker, Cached Network Image

**Platform Targets:** Web (primary), Android, iOS, Windows (desktop). Web runs on GitHub Pages.
