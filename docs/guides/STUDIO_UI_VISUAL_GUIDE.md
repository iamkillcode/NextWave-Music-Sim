# Studio UI Visual Guide

## Quick Reference for UI Elements

### Studio Card - Locked State
```
┌─────────────────────────────────────────────────────┐
│ 🏆🔒  Abbey Road Studios          LEGENDARY  CLOSED │
│       London, UK                                    │
│                                                     │
│ World's most famous recording studio.              │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ 🔒 REQUIREMENTS                              │   │
│ │ ❌ 👤 Fame: 5/90                             │   │
│ │ ❌ 💿 Albums: 0/3                            │   │
│ │ ❌ 🎵 Released Songs: 0/8                    │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ 🚫 Studios are closed. You don't have the   │   │
│ │    credentials yet.                          │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ ℹ️ World's most prestigious. Reserved for   │   │
│ │    true icons only.                          │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Quality: 98% | Rep: 100% | Fame: +5               │
│                                                     │
│ [Self Produce: $18,000] 🔒 [Studio Producer] 🔒   │
└─────────────────────────────────────────────────────┘
```

### Studio Card - Unlocked & Welcoming
```
┌─────────────────────────────────────────────────────┐
│ 🎙️  Atlantic Records Studio    PROFESSIONAL  FRIENDLY│
│      New York, USA                                  │
│                                                     │
│ Major label recording facility.                    │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ ✅ ACCESS GRANTED                            │   │
│ │ ✅ 👤 Fame: 45/40                            │   │
│ │ ✅ 💿 Albums: 1/1                            │   │
│ │ ✅ 🎵 Released Songs: 4/3                    │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ 😊 Happy to have you here! We appreciate    │   │
│ │    your work.                                │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ ℹ️ Major label facility. Seeks artists with │   │
│ │    commercial potential.                     │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ ⭐ 10% viral chance - Industry connections   │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Quality: 85% | Rep: 87% | Fame: +3                │
│                                                     │
│ 🎤 Hip Hop  🎵 R&B  🎸 Jazz                        │
│                                                     │
│ [Self Produce: $7,600] [Studio Producer: $14,250] │
└─────────────────────────────────────────────────────┘
```

### Studio Card - Budget (Always Welcome)
```
┌─────────────────────────────────────────────────────┐
│ 🏠  Home Studio Pro               BUDGET   WELCOMING│
│      Los Angeles, USA                               │
│                                                     │
│ Affordable home recording setup.                   │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ 🎉 Eager to work with you! Everyone starts  │   │
│ │    somewhere.                                │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ Quality: 62% | Rep: 55% | Fame: +1                │
│                                                     │
│ 🎤 Hip Hop  🎵 Trap  🎸 R&B                        │
│                                                     │
│ [Self Produce: $450]                               │
└─────────────────────────────────────────────────────┘
```

## Attitude Color Guide

### Welcoming 🎉
```
┌─────────────────────────────────────┐
│ 🎉 Eager to work with you!          │ ← GREEN background
│    We love your music.               │
└─────────────────────────────────────┘
Effects: -10% price, +15% quality
```

### Friendly 😊
```
┌─────────────────────────────────────┐
│ 😊 Happy to have you here!          │ ← LIGHT GREEN background
│    We appreciate your work.          │
└─────────────────────────────────────┘
Effects: -5% price, +8% quality
```

### Neutral 😐
```
┌─────────────────────────────────────┐
│ 😐 Professional studio service.     │ ← GREY background
│    Let's get to work.                │
└─────────────────────────────────────┘
Effects: No price or quality change
```

### Skeptical 🤔
```
┌─────────────────────────────────────┐
│ 🤔 You're in, but we're not sure    │ ← ORANGE background
│    about this yet.                   │
└─────────────────────────────────────┘
Effects: +10% price, -5% quality
```

### Dismissive 😒
```
┌─────────────────────────────────────┐
│ 😒 We'll work with you, but don't   │ ← DEEP ORANGE background
│    expect special treatment.         │
└─────────────────────────────────────┘
Effects: +25% price, -10% quality
```

### Closed 🚫
```
┌─────────────────────────────────────┐
│ 🚫 Studios are closed. You don't    │ ← RED background
│    have the credentials yet.         │
└─────────────────────────────────────┘
Effects: 10x price (effectively locked)
```

## Requirements Display

### All Requirements Met
```
┌─────────────────────────────────────┐
│ ✅ ACCESS GRANTED                    │ ← GREEN border & background
│ ✅ 👤 Fame: 85/80                    │
│ ✅ 💿 Albums: 3/2                    │
│ ✅ 🎵 Released Songs: 7/5            │
└─────────────────────────────────────┘
```

### Some Requirements Not Met
```
┌─────────────────────────────────────┐
│ 🔒 REQUIREMENTS                      │ ← RED border & background
│ ✅ 👤 Fame: 45/40                    │ ← GREEN (met)
│ ❌ 💿 Albums: 0/1                    │ ← RED (not met)
│ ❌ 🎵 Released Songs: 2/3            │ ← RED (not met)
└─────────────────────────────────────┘
```

## Tier Badges

```
LEGENDARY    → Purple background, white text
PROFESSIONAL → Blue background, white text  
PREMIUM      → Cyan background, white text
STANDARD     → Green background, white text
BUDGET       → Grey background, white text
```

## Icon Legend

| Icon | Meaning |
|------|---------|
| 🔒 | Studio locked (requirements not met) |
| ✅ | Requirement met |
| ❌ | Requirement not met |
| ⭐ | Connection benefits available |
| ℹ️ | Exclusive information |
| 👤 | Fame requirement |
| 💿 | Albums requirement |
| 🎵 | Released songs requirement |
| 🎉 | Welcoming attitude |
| 😊 | Friendly attitude |
| 😐 | Neutral attitude |
| 🤔 | Skeptical attitude |
| 😒 | Dismissive attitude |
| 🚫 | Closed/Blocked |

## Button States

### Enabled (Can Afford + Meets Requirements)
```
┌──────────────────────┐
│   Self Produce       │ ← CYAN background
│      $7,600          │   WHITE text
└──────────────────────┘   Clickable
```

### Disabled (Can't Afford OR Doesn't Meet Requirements)
```
┌──────────────────────┐
│   Self Produce       │ ← GREY background
│      $18,000         │   DARK GREY text
└──────────────────────┘   Not clickable
```

### With Producer Option
```
┌──────────────────────┐  ┌──────────────────────┐
│   Self Produce       │  │  Studio Producer     │
│      $7,600          │  │     $14,250          │
└──────────────────────┘  └──────────────────────┘
     CYAN                      PURPLE
```

## Success Message Examples

### Recording at Welcoming Studio
```
┌─────────────────────────────────────────────────┐
│ 🎤 Recorded "My New Song" at Atlantic Records!  │
│ Recording Quality: 92%                          │
│ 🎛️ With studio producer!                       │
│ 🎉 Studio Attitude: welcoming                   │
│ +3 Fame                                         │
└─────────────────────────────────────────────────┘
```

### Recording at Neutral Studio
```
┌─────────────────────────────────────────────────┐
│ 🎤 Recorded "Another Hit" at Premium Studios!   │
│ Recording Quality: 78%                          │
│ +2 Fame                                         │
└─────────────────────────────────────────────────┘
```

## Progression Visual

```
START (0 fame)
│
├─ 🏠 Budget Studios (WELCOMING)
│   Price: $500-$2,000
│   Quality: 60-68%
│
├─ 🎵 Standard Studios (20 fame)
│   Price: $1,500-$3,500
│   Quality: 69-75%
│
├─ 💎 Premium Studios (40 fame)
│   Price: $3,000-$6,000
│   Quality: 78-87%
│
├─ 🎯 Professional Studios (40-60 fame, 1+ album)
│   Price: $4,000-$8,500
│   Quality: 82-90%
│   ⭐ Connection Benefits: 10%
│
└─ 🏆 Legendary Studios (70-90 fame, 2-3+ albums)
    Price: $13,000-$18,000
    Quality: 92-98%
    ⭐ Connection Benefits: 15%
    
    └─ 👑 Abbey Road (90 fame, 3 albums, 8 songs)
        Price: $18,000 (or $16,200 if welcoming)
        Quality: 98% (or 113% with +15% bonus)
        ⭐ 15% viral chance
```

## Mobile/Responsive Notes

- Requirements boxes stack vertically on small screens
- Attitude badges may move below name on mobile
- Button text may shrink on narrow screens
- All icons remain visible and clickable
- Color contrast maintained for accessibility

---

**This visual guide shows how the studio system appears to players in-game.**
