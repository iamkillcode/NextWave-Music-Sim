# 🤝 Collaboration System - Implementation Guide

## Overview
The Collaboration System allows players to feature NPC artists on their songs, gaining stream boosts, quality bonuses, fame, and new fans. The system includes 30 unique NPC artists across 4 tiers unlocked by fame.

---

## 📂 Files Created

### 1. **Models**
- `lib/models/collaboration.dart` - Collaboration, NPCArtist, CollaborationStatus classes

### 2. **Services**
- `lib/services/collaboration_service.dart` - Collaboration logic, NPC data, boost calculations

### 3. **Screens**
- `lib/screens/collaboration_screen.dart` - Full collaboration UI with 3 tabs

---

## 🎯 How It Works

### Player Flow:
1. **Write a song** in the studio
2. **Record the song** (Self Produce or Studio Producer)
3. Navigate to **Collaborations** screen
4. **Browse NPC artists** (filtered by fame tier)
5. **Select an NPC** and choose a recorded song
6. **Pay collaboration cost**
7. **Song gets upgraded** with:
   - Featured artist name in metadata
   - Quality bonus applied
   - Stream multiplier stored
   - Fame and fanbase bonuses

### NPC Tiers & Fame Requirements:
| Tier | Fame Required | # of NPCs | Example Artists |
|------|---------------|-----------|----------------|
| **Rising** | 25 | 10 | Jaylen Sky, Luna Grey |
| **Established** | 50 | 10 | Phoenix Rise, Nova Star |
| **Star** | 100 | 6 | Titan Supreme, Elektra Vibe |
| **Legend** | 200 | 4 | King Legacy, Crystal Divine |

---

## 🎨 Collaboration Bonuses

### Tier-Based Boosts:
```
Rising:
- 1.2x stream multiplier
- +5 quality bonus
- +5 fame
- Gain 10% of NPC's fanbase

Established:
- 1.5x stream multiplier
- +10 quality bonus
- +10 fame
- Gain 12.5% of NPC's fanbase

Star:
- 2.0x stream multiplier
- +15 quality bonus
- +20 fame
- Gain 20% of NPC's fanbase

Legend:
- 3.0x stream multiplier
- +25 quality bonus
- +35 fame
- Gain 33% of NPC's fanbase
```

### Genre Synergy:
- **Perfect Match** (NPC primary = song genre): +20% stream boost, +5 quality
- **Good Match** (NPC specialty = song genre): +10% stream boost, +3 quality

---

## 💰 Collaboration Costs

Base costs with fame discount:

| Tier | Base Cost | With 100 Fame | With 250 Fame |
|------|-----------|---------------|---------------|
| Rising | $5,000 | $4,000 | $2,500 |
| Established | $15,000 | $12,000 | $7,500 |
| Star | $50,000 | $40,000 | $25,000 |
| Legend | $150,000 | $120,000 | $75,000 |

**Formula:** `baseCost * (1.0 - min(0.5, playerFame / 500))`

---

## 🎤 30 NPC Artists

### Rising Tier (Fame 25+)
1. **Jaylen Sky** - Hip Hop (Atlanta rapper, viral freestyles)
2. **Luna Grey** - Indie (Hauntingly beautiful voice)
3. **Knox Beats** - Electronic (Coffee shop sounds producer)
4. **Rosa Flame** - Latin (Miami reggaeton heat)
5. **Kai Storm** - Rock (Garage band raw energy)
6. **Maya Soul** - R&B (Smooth vocals)
7. **Dante Blaze** - Trap (Chicago hard-hitting 808s)
8. **Vera Echo** - Pop (Bubbly pop princess)
9. **Jax Wild** - Country (Texas outlaw attitude)
10. **Sakura Beats** - J-Pop (Tokyo traditional-modern blend)

### Established Tier (Fame 50+)
11. **Phoenix Rise** - Hip Hop (Grammy-nominated, 3 platinum singles)
12. **Nova Star** - Pop (Chart-topping icon, sold-out tours)
13. **Zion Pulse** - Electronic (Festival headliner)
14. **Carmen Luna** - Latin (Latin Grammy winner)
15. **Axel Voltage** - Rock (Arena rocker, legendary solos)
16. **Sienna Jazz** - Jazz (Sophisticated vocalist, 5 albums)
17. **Rex Country** - Country (Nashville sensation, multiple #1s)
18. **Yuki Harmony** - K-Pop (International fanbase)
19. **Theo Rhodes** - Indie (Critically acclaimed albums)
20. **Isla Rhythm** - R&B (Timeless vocals)

### Star Tier (Fame 100+)
21. **Titan Supreme** - Hip Hop (Multi-platinum, 10+ chart-toppers)
22. **Elektra Vibe** - Pop (Global superstar, world tours)
23. **Blaze Master** - Electronic (World-renowned DJ)
24. **Aurora Steel** - Rock (Rock icon, stadium tours)
25. **Diego Fuego** - Latin (Latin superstar, global charts)
26. **Harmony Grace** - Country (Country legend, multiple Grammys)

### Legend Tier (Fame 200+)
27. **King Legacy** - Hip Hop (20+ years of dominance, 2M fans)
28. **Crystal Divine** - Pop (50M+ records sold, 3M fans)
29. **Magnus Thunder** - Rock (Rock god, 1.5M fans)
30. **Soul Empress** - R&B (Legendary voice, 1.8M fans)

---

## 🔧 Integration Steps

### 1. Add to Activity Hub
```dart
// In lib/screens/activity_hub_screen.dart
import 'collaboration_screen.dart';

// Add card in Activity Hub:
_buildActivityCard(
  context: context,
  title: 'Collaborations',
  icon: Icons.people_alt,
  color: Colors.purple,
  description: 'Feature artists on your songs',
  isUnlocked: artistStats.fame >= 25,
  lockMessage: 'Requires 25 Fame',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollaborationScreen(
          artistStats: artistStats,
          onStatsUpdated: onStatsUpdated,
        ),
      ),
    );
  },
),
```

### 2. Display Featuring Artists
Update song display widgets to show "feat. Artist Name":

```dart
// In song card widgets:
String getSongTitle(Song song) {
  final featuring = song.metadata['featuringArtist'] as String?;
  if (featuring != null) {
    return '${song.title} (feat. $featuring)';
  }
  return song.title;
}
```

### 3. Apply Stream Boosts
When calculating streams for collaborative songs:

```dart
// In stream calculation logic:
final collaborationBoost = song.metadata['collaborationBoost'] as double? ?? 1.0;
final baseStreams = calculateBaseStreams(song);
final finalStreams = (baseStreams * collaborationBoost).round();
```

### 4. Update Release Screen
Show collaboration indicator when releasing:

```dart
// In release_song_screen.dart:
if (song.metadata.containsKey('featuringArtist')) {
  ListTile(
    leading: Icon(Icons.people, color: Colors.purple),
    title: Text('Featuring: ${song.metadata['featuringArtist']}'),
    subtitle: Text('${song.metadata['collaborationBoost']}x stream boost'),
  ),
}
```

---

## 📊 Song Metadata Structure

When a collaboration is created, the song's metadata is updated:

```dart
{
  'featuringArtist': 'Jaylen Sky',
  'featuringArtistId': 'npc_jaylen_sky',
  'collaborationBoost': 1.2, // Stream multiplier
  'emoji': '🎵', // Original emoji
  // ... other metadata
}
```

---

## 🎮 UI Features

### Tab 1: Find Artists
- **Filters**: Genre and Tier dropdowns
- **Fame Requirement Info**: Shows locked/unlocked tiers
- **NPC Cards**: Display avatar, name, tier badge, cost, bio, and bonuses
- **Tap to Collab**: Opens song selection dialog

### Tab 2: Recommended
- **Smart Recommendations**: Based on player's primary genre and fame
- **Sorted by Match**: Genre-matching NPCs appear first
- **Top 10**: Shows best collaboration opportunities

### Tab 3: Active
- **Future Feature**: Track ongoing collaborations
- **Currently**: Shows empty state encouraging first collaboration

---

## 🎨 Visual Design

### Tier Colors:
- **Rising**: Green
- **Established**: Blue
- **Star**: Amber/Gold
- **Legend**: Purple

### Tier Icons:
- **Rising**: 📈 trending_up
- **Established**: ✓ verified
- **Star**: ⭐ star
- **Legend**: 💎 diamond

### Boost Chips:
- Stream boost: Cyan
- Quality bonus: Amber
- Fame bonus: Orange
- Fanbase gain: Purple

---

## 🚀 Testing Checklist

- [ ] Access Collaborations screen from Activity Hub
- [ ] Verify fame requirements lock/unlock tiers
- [ ] Filter NPCs by genre and tier
- [ ] Select NPC and choose recorded song
- [ ] Confirm collaboration cost deduction
- [ ] Verify quality bonus applied to song
- [ ] Verify fame and fanbase increases
- [ ] Check song shows "feat. Artist Name"
- [ ] Verify stream boost is stored in metadata
- [ ] Test with different tiers and genres
- [ ] Verify genre synergy bonuses apply
- [ ] Check recommended tab shows relevant NPCs
- [ ] Test empty states (no recorded songs, low fame)

---

## 🎯 Future Enhancements

### Phase 2 Ideas:
1. **Player-to-Player Collabs**: Collaborate with real players
2. **Collab Revenue Sharing**: Split streaming earnings
3. **Collab Chart Tracking**: See collaborative songs on charts
4. **NPC Storylines**: Unlock special collabs through quests
5. **Multi-Artist Collabs**: Feature 2-3 artists on one track
6. **Collab Albums**: Full collaborative EP/albums
7. **Remixes**: Remix other artists' songs
8. **Collab Badges**: Achievements for collaborating with legends
9. **NPC Requests**: NPCs can request to feature on your songs
10. **Collab Events**: Seasonal collaboration challenges

---

## 📝 Notes

- Collaborations are **permanent** - once applied to a song, it's final
- Each song can only have **one featuring artist**
- Collaboration boosts apply on **release** when calculating streams
- Fame requirement is checked at collaboration time, not release time
- NPC availability is **dynamic** based on player's current fame level
- Genre synergy encourages players to work with matching artists
- Cost decreases with fame to reward progression

---

## 🐛 Known Limitations

- No Firebase persistence for collaborations (local state only)
- No collaboration history tracking
- Can't remove or change collaborations
- No collaboration earnings split (future feature)
- Active Collabs tab not fully implemented

---

## 🎉 Success Metrics

Track these to measure feature success:
- % of players who use collaborations (target: 60%+)
- Average number of collaborations per player
- Most popular NPC artists
- Fame threshold when players start collaborating
- Correlation between collaborations and chart performance

---

**Created:** November 1, 2025  
**Version:** 1.0  
**Status:** ✅ Core Implementation Complete
