# NextWave Music Sim - New UI Layout Visual Guide

## Desktop Layout (≥1024px)
```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│  ┌────────────┬─────────────────────────────────────────┬─────────────────┐ │
│  │            │                                         │                 │ │
│  │ ┌────────┐ │  ┌─────────────────────────────────┐   │ 📊 Analytics   │ │
│  │ │  🎵    │ │  │  👤 ARTIST NAME ✓               │   │                 │ │
│  │ │NextWave│ │  │  👥 1.2M followers              │   │ ┌─────────────┐ │ │
│  │ └────────┘ │  │  🎧 400K monthly listeners      │   │ │ Streams     │ │ │
│  │            │  │  ▶️  5.2M total streams         │   │ │ [Chart]     │ │ │
│  │ ─────────  │  └─────────────────────────────────┘   │ └─────────────┘ │ │
│  │            │                                         │                 │ │
│  │ 🏠 Home    │  ┌──────────────────────────────────┐  │ 🎵 Top Tracks  │ │
│  │ 🎵 Music   │  │   📈 Current Progress            │  │                 │ │
│  │ 👥 Collab  │  └──────────────────────────────────┘  │ 1. Song A      │ │
│  │ 💰 Revenue │                                         │    2.1M streams│ │
│  │ 📊 Charts  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐      │ 2. Song B      │ │
│  │ ⚙️  Settings│  │📈120K│ │👥+2%│ │💵$4K│ │🏆#8 │      │    1.8M streams│ │
│  │            │  │Today │ │Growth│ │Week │ │Chart│      │ 3. Song C      │ │
│  │            │  │  📊  │ │  📊 │ │  📊 │ │ 📊  │      │    1.5M streams│ │
│  │            │  └─────┘ └─────┘ └─────┘ └─────┘      │                 │ │
│  │  [◀]      │                                         │ 👤 Demographics│ │
│  │ Collapse   │  ┌──────────────────────────────────┐  │                 │ │
│  │            │  │  📅 Upcoming Events              │  │ [Pie Chart]    │ │
│  │            │  │                                  │  │                 │ │
│  │            │  │  🎤 Studio Session               │  │                 │ │
│  └────────────┘  │     Tomorrow • 2:00 PM           │  └─────────────────┘ │
│   240px width    │                                  │     320px width     │ │
│                  │  🎉 Release Party                │                       │
│                  │     Next Week • 8:00 PM          │                       │
│                  └──────────────────────────────────┘                       │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Collapsed Sidebar (Desktop)
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ┌──┬───────────────────────────────────────────────┬─────────────────┐      │
│ │🎵│  ARTIST NAME ✓                                │ 📊 Analytics    │      │
│ │──│  Stats: 1.2M followers • 400K monthly         │                 │      │
│ │🏠│                                               │ Streams Chart    │      │
│ │🎵│  ┌──────────────────────────────────────────┐ │                 │      │
│ │👥│  │  Current Progress (4 cards)              │ │ Top Tracks      │      │
│ │💰│  └──────────────────────────────────────────┘ │                 │      │
│ │📊│                                               │ Demographics     │      │
│ │⚙️ │  Upcoming Events...                          │                 │      │
│ │  │                                               └─────────────────┘      │
│ │[▶]│                                                                        │
│ └──┘                                                                         │
│ 72px                                                                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Tablet Layout (600px - 1024px)
```
┌──────────────────────────────────────────────────────────────────┐
│ ┌────────────┬─────────────────────────────────────────────────┐ │
│ │            │  ┌─────────────────────────────────────────┐    │ │
│ │ NextWave   │  │  👤 ARTIST NAME ✓                      │    │ │
│ │            │  │  Stats row                             │    │ │
│ │ 🏠 Home    │  └─────────────────────────────────────────┘    │ │
│ │ 🎵 Music   │                                                 │ │
│ │ 👥 Collab  │  Current Progress (2x2 grid)                    │ │
│ │ 💰 Revenue │  ┌──────────┐  ┌──────────┐                     │ │
│ │ 📊 Charts  │  │ Streams  │  │ Growth   │                     │ │
│ │ ⚙️  Settings│  └──────────┘  └──────────┘                     │ │
│ │            │  ┌──────────┐  ┌──────────┐                     │ │
│ │            │  │ Revenue  │  │ Chart    │                     │ │
│ │            │  └──────────┘  └──────────┘                     │ │
│ │            │                                                 │ │
│ │            │  Upcoming Events                                │ │
│ │            │  ┌─────────────────────────────────────────┐    │ │
│ │            │  │ Events list                             │    │ │
│ │            │  └─────────────────────────────────────────┘    │ │
│ │            │                                                 │ │
│ │            │  📊 Analytics & Insights                        │ │
│ │            │  ┌─────────────────────────────────────────┐    │ │
│ │            │  │ Streams Chart                           │    │ │
│ │            │  │ Top Tracks                              │    │ │
│ │            │  │ Demographics                            │    │ │
│ └────────────┘  └─────────────────────────────────────────┘    │ │
│   240px         (Insights panel moved below)                   │ │
└──────────────────────────────────────────────────────────────────┘
```

## Mobile Layout (<600px)
```
┌────────────────────────────────────┐
│ ┌────────────────────────────────┐ │
│ │ [☰]  Home              [👤]    │ │  ← App Bar
│ └────────────────────────────────┘ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │   👤 ARTIST NAME ✓             │ │  ← Profile Banner
│ │   Stats (vertical layout)      │ │
│ └────────────────────────────────┘ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 📈 Streams Today               │ │  ← Current Progress
│ │    120.3K    📊 +15%           │ │  (1 column)
│ └────────────────────────────────┘ │
│ ┌────────────────────────────────┐ │
│ │ 👥 Fanbase Growth              │ │
│ │    +2.3%     📊 vs last week   │ │
│ └────────────────────────────────┘ │
│ ┌────────────────────────────────┐ │
│ │ 💰 Revenue This Week           │ │
│ │    $4,210    📊 +$337          │ │
│ └────────────────────────────────┘ │
│ ┌────────────────────────────────┐ │
│ │ 🏆 Chart Position              │ │
│ │    #8        📊 +2             │ │
│ └────────────────────────────────┘ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 📅 Upcoming Events             │ │
│ │                                │ │
│ │ 🎤 Studio Session              │ │
│ │    Tomorrow • 2:00 PM          │ │
│ │                                │ │
│ │ 🎉 Release Party               │ │
│ │    Next Week • 8:00 PM         │ │
│ └────────────────────────────────┘ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ 📊 Analytics & Insights        │ │
│ │                                │ │
│ │ Monthly Streams                │ │
│ │ [Chart placeholder]            │ │
│ │                                │ │
│ │ Top Tracks                     │ │
│ │ 1. Song A - 2.1M               │ │
│ │ 2. Song B - 1.8M               │ │
│ │                                │ │
│ │ Fan Demographics               │ │
│ │ [Pie chart placeholder]        │ │
│ └────────────────────────────────┘ │
│                                    │
└────────────────────────────────────┘

Mobile Drawer (when [☰] tapped):
┌────────────────┐
│ 🎵 NextWave    │
│ Music Sim      │
│ ─────────────  │
│ 🏠 Home        │
│ 🎵 Music Hub   │
│ 👥 Collab      │
│ 💰 Revenue     │
│ 📊 Charts      │
│ ⚙️  Settings    │
└────────────────┘
```

## Component Breakdown

### Stat Card Component
```
┌─────────────────────────┐
│ [🎵]  Title             │  ← Icon + Title
│                         │
│ 120.3K                  │  ← Large value
│                         │
│ ↑ +15%                  │  ← Optional change indicator
└─────────────────────────┘
   (Hover: shadow grows)
```

### Profile Banner (Desktop)
```
┌────────────────────────────────────────────────┐
│  ┌────┐                                        │
│  │ 👤 │  ARTIST NAME ✓                         │
│  │    │  👥 1.2M • 🎧 400K • ▶️ 5.2M          │
│  └────┘                                        │
└────────────────────────────────────────────────┘
    100px                                        
   avatar
```

### Sidebar Navigation Item
```
Not Selected:          Selected:
┌──────────────┐       ┌──────────────┐
│ 🏠  Home     │       │ 🏠  Home     │ ← Cyan accent
└──────────────┘       └──────────────┘
  (Hover: light bg)     (Cyan border + bg)
```

### App Button (Primary)
```
┌─────────────────────┐
│    Continue    →    │  ← Gradient (Cyan→Blue)
└─────────────────────┘
  (Hover: shadow appears)
  (Press: shadow disappears)
```

### Shimmer Loading
```
┌─────────────────────┐
│ ░░▓▓▓░░             │  ← Animated shimmer
│ ░░░░▓▓▓░░           │     moves left→right
│ ░░░░░░▓▓▓░░         │     1.5s loop
└─────────────────────┘
```

## Color Reference (Hover States)

**Background Layers:**
```
#0D1117 ━━━━━━━━━━━━ Base (darkest)
#161B22 ━━━━━━━━━━━━ Elevated +1
#21262D ━━━━━━━━━━━━ Cards/Surfaces +2
#2D333B ━━━━━━━━━━━━ Hover states +3
```

**Accent Colors:**
```
Primary:   #00D9FF ███ Cyan (buttons, highlights)
Secondary: #1E90FF ███ Blue (gradients)
Success:   #32D74B ███ Green (positive changes)
Warning:   #FF9500 ███ Orange (alerts)
Error:     #FF6B9D ███ Red (negative changes)
```

## Interactions

### Hover Effects
- **Stat Cards:** Shadow elevation increases
- **Buttons:** Background darkens, shadow appears
- **Sidebar Items:** Light overlay appears
- **Links:** Color shifts to primary cyan

### Press Effects
- **Buttons:** Shadow disappears, slight scale down
- **Cards:** Border color intensifies

### Loading States
- **Initial Load:** Shimmer skeleton matching layout
- **Button Loading:** Spinner replaces text
- **Data Refresh:** Shimmer overlay on content

## Typography Hierarchy

```
Display (64px) ▮▮▮▮▮▮ Hero text
Heading (32px) ▮▮▮▮▮  Section titles
Title (20px)   ▮▮▮▮   Card titles
Body (16px)    ▮▮▮    Paragraph text
Label (12px)   ▮▮     Metadata, captions
```

## Spacing Examples

```
4px   ▪       Tiny gap (icon spacing)
8px   ▪▪      Small gap (text line height)
12px  ▪▪▪     Medium gap (card padding)
16px  ▪▪▪▪    Default padding
24px  ▪▪▪▪▪▪  Section spacing
32px  ▪▪▪▪▪▪▪▪ Large section breaks
```

This visual guide shows exactly how the new UI looks at different screen sizes and demonstrates the polished, professional design system implementation.
