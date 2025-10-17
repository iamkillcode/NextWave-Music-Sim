# 🌍 NPC Architecture - Visual Guide

## Database Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    FIRESTORE DATABASE                            │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     players/                               │  │
│  │                (Individual Player Data)                    │  │
│  │                                                            │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                │  │
│  │  │  player_abc123  │  │  player_def456  │  ← Per User    │  │
│  │  │                 │  │                 │                 │  │
│  │  │  name: "Alice"  │  │  name: "Bob"    │                │  │
│  │  │  fame: 35       │  │  fame: 52       │                │  │
│  │  │  streams: 5k    │  │  streams: 12k   │                │  │
│  │  └─────────────────┘  └─────────────────┘                │  │
│  │                                                            │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   npc_artists/                             │  │
│  │               🌍 GLOBAL (SHARED BY ALL)                    │  │
│  │                                                            │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                │  │
│  │  │ npc_jaylen_sky  │  │  npc_luna_grey  │  ← Shared!    │  │
│  │  │                 │  │                 │                 │  │
│  │  │  name: "Jaylen" │  │  name: "Luna"   │                │  │
│  │  │  fame: 45       │  │  fame: 68       │                │  │
│  │  │  streams: 150k  │  │  streams: 300k  │                │  │
│  │  │  isNPC: true    │  │  isNPC: true    │                │  │
│  │  └─────────────────┘  └─────────────────┘                │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────┐                 │  │
│  │  │      _initialized                    │  ← Guard       │  │
│  │  │                                      │                 │  │
│  │  │  initialized: true                   │                 │  │
│  │  │  count: 10                           │                 │  │
│  │  │  initializedAt: timestamp            │                 │  │
│  │  └──────────────────────────────────────┘                 │  │
│  │                                                            │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Initialization Flow

```
┌──────────────┐
│   Player A   │
│   (Alice)    │
└──────┬───────┘
       │
       │ 1. Clicks "Initialize NPCs"
       │
       ▼
┌─────────────────────────────────────┐
│   Firebase Cloud Function           │
│   "initializeNPCArtists"            │
│                                     │
│  1. Check if already initialized    │
│  2. Create 10 NPCs globally         │
│  3. Set _initialized flag           │
└─────────────┬───────────────────────┘
              │
              │ 2. NPCs Created in Global Collection
              │
              ▼
┌─────────────────────────────────────┐
│      Firestore: npc_artists/        │
│                                     │
│   • npc_jaylen_sky                  │
│   • npc_luna_grey                   │
│   • npc_elodie_rain                 │
│   • npc_santiago_vega               │
│   • npc_zyrah                       │
│   • npc_kazuya_rin                  │
│   • npc_nova_reign                  │
│   • npc_jax_carter                  │
│   • npc_kofi_dray                   │
│   • npc_hana_seo                    │
│   • _initialized ✅                 │
└─────────────┬───────────────────────┘
              │
              │ 3. ALL Players Can Now See NPCs
              │
    ┌─────────┴─────────┬─────────────┐
    │                   │             │
    ▼                   ▼             ▼
┌─────────┐      ┌──────────┐   ┌─────────┐
│ Alice   │      │   Bob    │   │ Charlie │
│ Charts: │      │ Charts:  │   │ Charts: │
│         │      │          │   │         │
│ • Hana  │      │ • Hana   │   │ • Hana  │
│ • Luna  │      │ • Luna   │   │ • Luna  │
│ • Jaylen│      │ • Jaylen │   │ • Jaylen│
└─────────┘      └──────────┘   └─────────┘
    ↑                 ↑               ↑
    └─────────────────┴───────────────┘
          Same NPCs for Everyone!
```

---

## What Happens When Player B Tries to Initialize Again?

```
┌──────────────┐
│   Player B   │
│    (Bob)     │
└──────┬───────┘
       │
       │ 1. Clicks "Initialize NPCs"
       │
       ▼
┌─────────────────────────────────────┐
│   Firebase Cloud Function           │
│   "initializeNPCArtists"            │
│                                     │
│  1. Check _initialized flag         │
│  2. Already TRUE ✅                 │
│  3. Return error message            │
└─────────────┬───────────────────────┘
              │
              │ 2. "Already initialized" message
              │
              ▼
┌──────────────────────────────────────┐
│   Player B's Screen                  │
│                                      │
│   ⚠️ Already Initialized             │
│   NPC artists already initialized    │
│   Count: 10                          │
│                                      │
│   [OK]                               │
└──────────────────────────────────────┘

Result: No duplicates created! ✅
```

---

## Hourly NPC Updates (Global)

```
Every Hour:

┌────────────────────────────────────────┐
│   Firebase Scheduled Function          │
│   "simulateNPCActivity"                │
│   Runs: 0 * * * * (every hour)         │
└────────────────┬───────────────────────┘
                 │
                 │ 1. Fetch all NPCs
                 │
                 ▼
┌────────────────────────────────────────┐
│      npc_artists/ (Global)             │
│                                        │
│  For each NPC:                         │
│   • Update stream counts               │
│   • Check if time to release song      │
│   • Check if time to post on EchoX     │
│   • Save updates                       │
└────────────────┬───────────────────────┘
                 │
                 │ 2. Updates Saved
                 │
                 ▼
┌────────────────────────────────────────┐
│   ALL Players See Updated NPCs         │
│                                        │
│   Alice's App → Refresh → New data ✅   │
│   Bob's App → Refresh → New data ✅     │
│   Charlie's App → Refresh → New data ✅ │
└────────────────────────────────────────┘
```

---

## Player Chart Query (How Charts See NPCs)

```
When a player opens charts:

┌─────────────────────┐
│   Player's Device   │
│   (Any Player)      │
└──────────┬──────────┘
           │
           │ 1. Query for chart data
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌─────────┐  ┌──────────────┐
│ players/│  │ npc_artists/ │
│         │  │  (Global)    │
└────┬────┘  └──────┬───────┘
     │              │
     │              │
     └──────┬───────┘
            │ 2. Merge results
            │
            ▼
┌────────────────────────────┐
│   Combined Chart Data      │
│                            │
│   #1 Hana Seo (NPC)        │
│   #2 Luna Grey (NPC)       │
│   #3 Jaylen Sky (NPC)      │
│   #4 Bob (Player)          │
│   #5 Alice (Player)        │
│   #6 Charlie (Player)      │
└────────────────────────────┘
```

---

## Multi-Player View (Same NPCs, Different Rankings)

```
┌─────────────────────────────────────────────────────────────────┐
│                      GLOBAL NPC DATA                             │
│                                                                  │
│   npc_hana_seo:    streams: 600,000  (Star Tier)               │
│   npc_luna_grey:   streams: 300,000  (Established Tier)        │
│   npc_jaylen_sky:  streams: 150,000  (Rising Tier)             │
└─────────────────────────────────────────────────────────────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
      ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
      │   Alice     │ │     Bob     │ │   Charlie   │
      │  5k streams │ │ 12k streams │ │  3.5k streams│
      └─────────────┘ └─────────────┘ └─────────────┘
              │             │             │
              ▼             ▼             ▼
      ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
      │ Alice's     │ │  Bob's      │ │ Charlie's   │
      │ Chart:      │ │  Chart:     │ │ Chart:      │
      │             │ │             │ │             │
      │ #1 Hana ⭐  │ │ #1 Hana ⭐  │ │ #1 Hana ⭐  │
      │ #2 Luna 👤  │ │ #2 Luna 👤  │ │ #2 Luna 👤  │
      │ #3 Jaylen🤖 │ │ #3 Jaylen🤖 │ │ #3 Jaylen🤖 │
      │ #4 Bob 🎵   │ │ #4 Bob 🎵   │ │ #4 Bob 🎵   │
      │    (12k)    │ │    (YOU!)   │ │    (12k)    │
      │ #5 Alice 🎵 │ │ #5 Alice 🎵 │ │ #5 Alice 🎵 │
      │    (YOU!)   │ │    (5k)     │ │    (5k)     │
      │ #6 Charlie🎵│ │ #6 Charlie🎵│ │ #6 Charlie🎵│
      │    (3.5k)   │ │    (3.5k)   │ │    (YOU!)   │
      └─────────────┘ └─────────────┘ └─────────────┘

Same NPCs, Different "YOU" Position ✅
```

---

## Cost Breakdown (Why Global Is Efficient)

### **If NPCs Were Per-Player:**
```
1,000 players × 10 NPCs each = 10,000 NPC documents
Hourly updates: 10,000 writes × 720 hours/month = 7.2M writes
Cost: ~$140/month 💸
```

### **With Global NPCs (Current):**
```
1 global collection × 10 NPCs = 10 NPC documents
Hourly updates: 10 writes × 720 hours/month = 7,200 writes
Cost: ~$0.02/month 💰
```

### **Savings: 99.99% less cost!** 🎉

---

## Key Takeaways

```
✅ ONE collection for all players
✅ Initialize ONCE, benefits ALL
✅ Same NPCs, same competition
✅ Cost scales with NPCs, not players
✅ Foundation for multiplayer features
✅ Living, breathing music industry

❌ NOT per-player (by design)
❌ Can't customize NPCs per player
❌ All players see same NPC stats
```

---

## Summary Diagram

```
                    ┌──────────────────┐
                    │  Initialize NPCs │
                    │   (One Time)     │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Global NPCs     │
                    │  in Firestore    │
                    └────────┬─────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼
    ┌──────────┐      ┌──────────┐      ┌──────────┐
    │ Player 1 │      │ Player 2 │      │ Player 3 │
    │  Charts  │      │  Charts  │      │  Charts  │
    └──────────┘      └──────────┘      └──────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Same NPCs for   │
                    │   EVERYONE! 🌍   │
                    └──────────────────┘
```

---

*Created: October 17, 2025*  
*Visualizes global NPC architecture*
