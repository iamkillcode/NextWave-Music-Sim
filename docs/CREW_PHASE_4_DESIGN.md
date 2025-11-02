# Crew System - Phase 4 Design Document 📋

**Date**: November 1, 2025  
**Status**: Design phase - ready for future implementation  
**Prerequisites**: Phases 1-3 must be complete

---

## Overview

Phase 4 focuses on **long-term engagement and crew identity** through perks, achievements, and advanced social features. This phase transforms crews from functional groups into communities with unique identities and progression paths.

---

## 1. Crew Perks System 🎁

### Concept
Unlock permanent bonuses as crew reaches milestones. Perks stack and provide competitive advantages.

### Perk Categories

**Economic Perks**:
```dart
// Unlock at 100K total earnings
StreamBoost: +5% revenue from all crew songs

// Unlock at 500K total earnings  
BulkDiscount: -10% on all studio costs

// Unlock at 1M total earnings
RevenueMultiplier: +10% revenue from all sources

// Unlock at 5M total earnings
GoldenTouch: +15% revenue, -15% costs
```

**Performance Perks**:
```dart
// Unlock at 1M total streams
ViralBoost: +10% chance songs go viral

// Unlock at 5M total streams
AlgorithmFavorite: +20% playlist placement chance

// Unlock at 10M total streams
SuperstarStatus: +25% all streams
```

**Creative Perks**:
```dart
// Unlock at 10 songs released
RapidWriter: -20% writing time

// Unlock at 25 songs released
StudioVeterans: -15% recording time

// Unlock at 50 songs released
LegendaryProducers: +15% song quality
```

**Social Perks**:
```dart
// Unlock at 10 total members (including past)
NetworkEffect: +5% streams per active member

// Unlock at 5 collaborations with other crews
CollabMasters: +20% collab revenue

// Unlock at 100 crew challenges joined
CompetitiveEdge: +10% to all challenge progress
```

### Data Structure

```dart
class CrewPerk {
  final String id;
  final String name;
  final String description;
  final String category; // 'economic', 'performance', 'creative', 'social'
  final Map<String, dynamic> requirements; // What unlocks it
  final Map<String, dynamic> bonuses; // What it provides
  final String iconUrl;
  final int tier; // 1-5, higher = rarer
  
  bool isUnlocked(Crew crew); // Check if crew qualifies
  String getProgressText(Crew crew); // "80% of way there"
}
```

### Implementation

```dart
// crew_perk_service.dart
class CrewPerkService {
  // Get all perks available
  Future<List<CrewPerk>> getAllPerks();
  
  // Get perks unlocked by crew
  Future<List<CrewPerk>> getUnlockedPerks(String crewId);
  
  // Get next perks to unlock (closest to achieving)
  Future<List<CrewPerk>> getUpcomingPerks(String crewId, {int limit = 5});
  
  // Check and auto-unlock perks when milestones hit
  Future<void> checkAndUnlockPerks(String crewId);
  
  // Calculate total bonuses from all perks
  Future<Map<String, double>> calculateTotalBonuses(String crewId);
  
  // Apply perk bonuses to an action
  int applyPerks(String crewId, String action, int baseValue);
}
```

### UI Components

**Perks Screen**:
```dart
- Grid of all perks
- Unlocked perks: full color + "ACTIVE" badge
- Locked perks: greyed out + progress bar
- Tap perk to see details + requirements
- Filter by category
- Sort by progress (closest to unlock first)
```

**Perk Notification**:
```dart
// When perk unlocks
showDialog(
  title: '🎉 Perk Unlocked!',
  content: '$perkName - $perkDescription',
  actions: ['View All Perks', 'Dismiss'],
);
```

---

## 2. Crew Achievements System 🏅

### Concept
Collectible badges that showcase crew accomplishments. Unlike perks, achievements are cosmetic but provide crew identity and bragging rights.

### Achievement Categories

**Founding Achievements**:
```
🌟 Pioneer - Be in top 100 crews created
💎 Diamond Founders - Keep original 5 members for 90 days
🔥 Hot Start - Earn 100K in first week
🚀 Rapid Rise - Reach top 10 leaderboard in any category within 30 days
```

**Performance Achievements**:
```
👑 Chart Topper - Have #1 song on charts
💿 Platinum - Single song reaches 1M streams
💎 Diamond - Single song reaches 10M streams
🌎 Global - Songs streamed in 50+ countries
📻 Radio Hit - Song added to 100+ user playlists
```

**Collaboration Achievements**:
```
🤝 Networking - Collaborate with 10 different artists
🌐 Crew Alliance - Collaborate with 5 other crews
🎭 Genre Fusion - Release songs in 5+ genres
🎨 Creative Director - Have 10 artists featured on crew songs
```

**Challenge Achievements**:
```
🏆 Challenge Victor - Win 1 crew challenge
🥇 Challenge Dominator - Win 10 crew challenges
👊 Underdog Victory - Win challenge while lowest ranked
⚡ Perfect Run - Complete challenge at 100% in record time
🎯 Sharpshooter - Join 50 challenges
```

**Longevity Achievements**:
```
📆 One Year Strong - Crew active for 365 days
🌟 Veteran - Crew active for 2 years
👴 Legacy - Crew active for 5 years
💪 Unbreakable - Never disbanded or went on hiatus
🏰 Institution - 500+ songs released
```

**Financial Achievements**:
```
💰 Millionaire Crew - 1M total earnings
💸 Ten Million Club - 10M total earnings
🏦 Banker - 1M in shared bank
💎 Treasure Hoard - 5M in shared bank
```

**Special Achievements**:
```
🎤 World Tour - Have crew members from 5+ countries
🌈 Diverse - Have members of all skill levels
🎓 Mentors - Help 10 new artists get their first song
🔊 Loud - Be mentioned in 100+ chat messages
🎪 Event Winners - Win special limited-time event
```

### Data Structure

```dart
class CrewAchievement {
  final String id;
  final String name;
  final String description;
  final String category;
  final String iconUrl;
  final int rarity; // 1-5: Common, Rare, Epic, Legendary, Mythic
  final Map<String, dynamic> requirements;
  final DateTime? unlockedAt; // null if not unlocked
  final double progress; // 0.0 - 1.0
  
  bool get isUnlocked => unlockedAt != null;
  String get rarityText; // "Legendary Achievement"
  Color get rarityColor; // Gold for legendary, etc.
}
```

### Implementation

```dart
// crew_achievement_service.dart
class CrewAchievementService {
  // Get all achievements
  Future<List<CrewAchievement>> getAllAchievements();
  
  // Get crew's unlocked achievements
  Future<List<CrewAchievement>> getCrewAchievements(String crewId);
  
  // Get achievement progress
  Future<double> getAchievementProgress(String crewId, String achievementId);
  
  // Check and unlock achievements
  Future<void> checkAchievements(String crewId);
  
  // Get rarest achievements globally
  Future<List<CrewAchievement>> getRarestAchievements({int limit = 10});
  
  // Get achievement leaderboard (who has most)
  Future<List<Map<String, dynamic>>> getAchievementLeaderboard();
}
```

### UI Components

**Achievement Wall**:
```dart
- Display all achievements in grid
- Show rarity with colored borders
- Unlocked: full display + unlock date
- Locked: silhouette + progress bar
- Filter by category/rarity
- Display count: "42/150 Achievements"
```

**Achievement Showcase**:
```dart
// Featured on crew profile
- Top 3 rarest achievements displayed prominently
- "Achievement Points" total
- Progress toward next achievement
```

---

## 3. Crew Customization 🎨

### Crew Colors & Themes
```dart
class CrewCustomization {
  final String crewId;
  final Color primaryColor;
  final Color secondaryColor;
  final String theme; // 'neon', 'classic', 'minimalist', 'grunge'
  final String bannerUrl;
  final String logoUrl;
  final List<String> customEmojis; // Crew-specific emojis
}
```

### Unlockable Items
- **Colors**: Unlock new color schemes through achievements
- **Banners**: Special backgrounds for crew profile
- **Logos**: Custom crew logos
- **Emojis**: Crew-specific emoji reactions

---

## 4. Crew Events 🎪

### Concept
Limited-time special modes that change gameplay rules and offer unique rewards.

### Event Types

**Double XP Weekend**:
```dart
- All crew activities give 2x XP
- Runs Friday-Sunday
- Happens monthly
```

**Mega Challenge**:
```dart
- Special challenge with huge rewards
- Multiple phases (qualify → semifinal → final)
- Top 3 crews get prizes
- Runs for 2 weeks
```

**Collaboration Festival**:
```dart
- Bonuses for crew collaborations
- +50% revenue from collab songs
- Special "Festival" badge
- Runs for 1 week
```

**Battle Royale**:
```dart
- 100 crews enter, 1 crew wins
- Daily eliminations based on performance
- Survivor-style gameplay
- Grand prize for winner
```

### Implementation

```dart
// crew_event_service.dart
class CrewEventService {
  // Get active event
  Future<CrewEvent?> getActiveEvent();
  
  // Join event
  Future<bool> joinEvent(String eventId, String crewId);
  
  // Get event leaderboard
  Stream<List<Map<String, dynamic>>> streamEventLeaderboard(String eventId);
  
  // Check event rewards
  Future<void> distributeEventRewards(String eventId);
}
```

---

## 5. Advanced Social Features 💬

### Crew Feed
```dart
// Activity feed for crew members
- Member joined/left
- Song released
- Challenge completed
- Achievement unlocked
- Perk unlocked
- Milestone reached
```

### Crew Announcements
```dart
// Leader can post announcements
- Pin important messages
- Notify all members
- Schedule announcements
```

### Crew Polls
```dart
// Democratic decisions
- Which song to release next
- How to spend shared bank
- Who to invite
- Results visible to all
```

### Crew Calendar
```dart
// Schedule crew activities
- Recording sessions
- Challenge deadlines
- Release dates
- Special events
```

---

## 6. Crew Reputation System ⭐

### Concept
Aggregate score representing crew's standing in community.

### Reputation Sources
```dart
reputation = (
  totalStreams * 0.001 +
  totalEarnings * 0.0001 +
  songsReleased * 100 +
  challengesWon * 500 +
  collaborations * 200 +
  achievementsUnlocked * 50 +
  daysActive * 10
)
```

### Reputation Tiers
```
0-999: Newcomer
1,000-9,999: Rising Star
10,000-49,999: Established
50,000-99,999: Renowned
100,000-499,999: Legendary
500,000+: Icon
```

### Benefits by Tier
- **Newcomer**: Basic features
- **Rising Star**: Custom colors unlocked
- **Established**: Can host challenges
- **Renowned**: Featured on homepage
- **Legendary**: Custom emoji pack
- **Icon**: Special "Icon" badge, priority support

---

## 7. Crew Alliances (Advanced) 🤝

### Concept
Temporary partnerships between crews for mutual benefit.

### Alliance Features
```dart
class CrewAlliance {
  final List<String> crewIds;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> terms; // Shared revenue %, etc.
  
  // Alliance benefits:
  - Shared challenge entries (count for all crews)
  - Cross-promotion (appear on each other's profiles)
  - Alliance-exclusive challenges
  - Pooled resources (optional)
}
```

---

## 8. Crew Broadcasting 📺

### Concept
Live streaming of crew activities.

### Features
```dart
class CrewBroadcast {
  final String crewId;
  final String title;
  final String type; // 'recording', 'writing', 'general'
  final int viewerCount;
  final List<String> chatMessages;
  
  // Viewers can:
  - Watch in real-time
  - Send chat messages
  - Send tips (money to crew)
  - React with emojis
}
```

---

## Database Schema Updates

### crews collection additions:
```javascript
{
  // Existing fields...
  
  // Phase 4 additions:
  unlockedPerks: string[], // Perk IDs
  achievements: {
    [achievementId]: {
      unlockedAt: timestamp,
      progress: number
    }
  },
  customization: {
    primaryColor: string,
    secondaryColor: string,
    theme: string,
    bannerUrl: string,
    logoUrl: string
  },
  reputation: number,
  reputationTier: string,
  eventParticipation: {
    [eventId]: {
      joinedAt: timestamp,
      rank: number,
      rewards: object
    }
  },
  allianceIds: string[],
  feedItems: array // Recent activity
}
```

### New Collections:
```javascript
crew_perks: {
  id: string,
  name: string,
  description: string,
  category: string,
  requirements: object,
  bonuses: object,
  tier: number
}

crew_achievements: {
  id: string,
  name: string,
  description: string,
  category: string,
  rarity: number,
  requirements: object,
  globalUnlockCount: number // How many crews have it
}

crew_events: {
  id: string,
  title: string,
  description: string,
  type: string,
  startDate: timestamp,
  endDate: timestamp,
  participatingCrews: string[],
  leaderboard: object,
  rewards: object,
  isActive: boolean
}

crew_alliances: {
  id: string,
  crewIds: string[],
  name: string,
  startDate: timestamp,
  endDate: timestamp,
  terms: object,
  status: string
}
```

---

## Implementation Priority

### High Priority (Implement First):
1. ✅ **Crew Perks** - Significant gameplay impact
2. ✅ **Achievements** - High engagement value
3. ✅ **Reputation System** - Ties everything together

### Medium Priority:
4. **Crew Events** - Episodic content keeps game fresh
5. **Crew Feed** - Social engagement within crew
6. **Crew Customization** - Identity building

### Low Priority (Polish):
7. **Crew Alliances** - Complex feature for advanced players
8. **Crew Broadcasting** - Technical complexity, niche feature

---

## Estimated Implementation Time

- **Perks System**: 2-3 days
- **Achievement System**: 2-3 days
- **Reputation System**: 1 day
- **Crew Events**: 2-3 days
- **Social Features**: 2-3 days
- **Customization**: 1-2 days
- **Alliances**: 2-3 days
- **Broadcasting**: 3-5 days

**Total**: ~15-25 days for complete Phase 4

---

## Success Metrics

### Engagement:
- % of crews with at least 1 perk unlocked
- Average achievements per crew
- Event participation rate
- Crew retention after 30/60/90 days

### Social:
- Messages per crew per day
- Collaboration rate increase
- Alliance formation rate

### Monetization:
- Premium perk purchases (if applicable)
- Custom logo/banner sales
- Event entry fees (optional)

---

## Future Phases Beyond Phase 4

### Phase 5: Crew Economy
- Crew marketplace
- Crew merchandise
- Crew investments

### Phase 6: Crew Competition
- Crew tournaments
- Seasonal rankings
- Hall of fame

### Phase 7: Crew Legacy
- Crew history timeline
- Member hall of fame
- Legendary crew status

---

## Conclusion

Phase 4 transforms crews from functional groups into **living communities** with:
- ✅ **Perks** providing tangible progression
- ✅ **Achievements** showcasing accomplishments
- ✅ **Events** creating episodic excitement
- ✅ **Social features** deepening connections
- ✅ **Reputation** establishing hierarchy
- ✅ **Customization** building identity

This creates a **complete crew ecosystem** that drives long-term engagement and player investment in their crew's success! 🎯🏆👥

