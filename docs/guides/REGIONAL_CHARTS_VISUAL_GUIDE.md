# Regional Charts UI - Visual Guide 🎨

## 📱 Screen Layout

```
┌─────────────────────────────────────────────┐
│ ← Regional Charts                           │
├─────────────────────────────────────────────┤
│ 🌍 Global │ 🇺🇸 USA │ 🇪🇺 Europe │ ... →  │ ← Tabs (scrollable)
├─────────────────────────────────────────────┤
│                                             │
│  🇺🇸                USA Top 10              │
│       10 songs charting                     │
│                                             │
│  ┌────────────────────────────────────┐    │
│  │ 🥇  Summer Vibes            5.2M ▲ │    │ ← #1 (Gold medal + glow)
│  │     👤 You (Pop)                   │    │
│  └────────────────────────────────────┘    │
│                                             │
│  ┌────────────────────────────────────┐    │
│  │ 🥈  Midnight Dreams         3.8M ▲ │    │ ← #2 (Silver medal)
│  │     Artist Name (R&B)              │    │
│  └────────────────────────────────────┘    │
│                                             │
│  ┌────────────────────────────────────┐    │
│  │ 🥉  Electric Nights         2.1M ▲ │    │ ← #3 (Bronze medal)
│  │     Another Artist (EDM)           │    │
│  └────────────────────────────────────┘    │
│                                             │
│  ┌────────────────────────────────────┐    │
│  │ #4  Sunset Groove           1.5M   │    │ ← #4-10 (Gray circle)
│  │     Some Artist (Reggae)           │    │
│  └────────────────────────────────────┘    │
│                                             │
│  ... (#5-10) ...                            │
│                                             │
├─────────────────────────────────────────────┤
│ ⭐ Your Charting Songs                      │ ← Footer section
│ 1 song on the chart                         │
│ Highest: "Summer Vibes" at #1               │
└─────────────────────────────────────────────┘
```

---

## 🎨 Color Scheme

### Tab Colors (per region)
- 🌍 **Global:** Purple `#9C27B0`
- 🇺🇸 **USA:** Blue `#2196F3`
- 🇪🇺 **Europe:** Green `#4CAF50`
- 🇬🇧 **UK:** Red `#F44336`
- 🇯🇵 **Asia:** Orange `#FF9800`
- 🇳🇬 **Africa:** Cyan `#00BCD4`
- 🇧🇷 **Latin America:** Light Green `#8BC34A`
- 🇦🇺 **Oceania:** Pink `#E91E63`

### Medal Colors
- 🥇 **#1:** Gold `#FFD700` with glow
- 🥈 **#2:** Silver `#C0C0C0` with glow
- 🥉 **#3:** Bronze `#CD7F32` with glow

### Genre Badge Colors
- **Pop:** Pink `#E91E63`
- **Hip Hop/Rap:** Purple `#9C27B0`
- **Rock:** Red `#F44336`
- **EDM/Electronic:** Cyan `#00BCD4`
- **R&B:** Orange `#FF9800`
- **Country:** Green `#8BC34A`
- **Jazz:** Yellow `#FFEB3B`
- **Ballad:** Blue `#2196F3`
- **Trap/Drill:** Deep Purple `#673AB7`
- **Afrobeat:** Deep Orange `#FF5722`
- **Reggae:** Green `#4CAF50`

---

## 🏆 Chart Entry States

### Your Song (Charting)
```
┌──────────────────────────────────────────┐
│ ● Colored Border (matches region color)  │
│ ● Background: region color @ 15% opacity │
│ ● Artist name: Cyan #00D9FF               │
│ ● 👤 Icon before artist name              │
│ ● Tap: Shows snackbar "Your song..."     │
└──────────────────────────────────────────┘
```

### Other Artist's Song
```
┌──────────────────────────────────────────┐
│ ● No border                               │
│ ● Background: Dark #1D1E33                │
│ ● Artist name: White 70% opacity          │
│ ● No tap action                           │
└──────────────────────────────────────────┘
```

### Top 3 Songs (Additional Effects)
```
● Box Shadow: Medal color @ 30% opacity, 8px blur
● Trending Icon: Green arrow ↑
● Glow effect around medal icon
```

---

## 📊 Chart Entry Anatomy

```
┌────────────────────────────────────────────────────┐
│  ┌──────┐                                    ┌───┐ │
│  │  🥇  │  Song Title                        │ ↑ │ │
│  │      │  👤 Artist Name (Genre) 🎵 2.5M    │   │ │
│  └──────┘                                    └───┘ │
│   Medal    Song Info                        Trend  │
└────────────────────────────────────────────────────┘

Components:
1. Medal/Position (50×50px circle)
   - Top 3: Medal icon
   - Others: #Position text

2. Song Info (Flexible width)
   - Line 1: Song Title (bold, white, 16px)
   - Line 2: Artist Name (white70, 14px) + Person icon if yours
   - Line 3: Genre Badge + 🎵 Stream Count (white54, 12px)

3. Trend Indicator (40px circle, only Top 3)
   - Green arrow ↑ (20px)
   - Green background @ 20% opacity
```

---

## 🎭 States & Loading

### Loading State
```
┌─────────────────────────┐
│                         │
│    ⏳ Circular          │
│    Progress             │
│    (region color)       │
│                         │
└─────────────────────────┘
```

### Empty State
```
┌─────────────────────────┐
│                         │
│        🇺🇸              │
│     (80px flag)         │
│                         │
│  No songs charting yet  │
│  (white, bold, 20px)    │
│                         │
│  Release songs to see   │
│  them chart!            │
│  (white54, 14px)        │
│                         │
└─────────────────────────┘
```

### Error State
```
┌─────────────────────────┐
│                         │
│       ⚠️ (60px)         │
│                         │
│  Error loading charts   │
│  (white, 18px)          │
│                         │
│  [Error message]        │
│  (white54, 14px)        │
│                         │
└─────────────────────────┘
```

---

## 🎯 Dashboard Integration

### Quick Actions Grid (3 columns)
```
┌──────────────────────────────────────────┐
│ ⚡ Quick Actions                         │
├──────────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐           │
│  │ 📝   │  │ 💿   │  │ 🎵   │           │
│  │Write │  │Studio│  │Pract │           │
│  │15-40 │  │Record│  │ 15   │           │
│  └──────┘  └──────┘  └──────┘           │
│                                          │
│  ┌──────┐  ┌──────┐                     │
│  │ 📢   │  │ 📊   │  ← NEW! Charts     │
│  │Promot│  │Charts│                     │
│  │ 10   │  │ View │                     │
│  └──────┘  └──────┘                     │
└──────────────────────────────────────────┘
```

**Charts Button:**
- Icon: `Icons.bar_chart_rounded`
- Color: Green `#4CAF50`
- Text: "Charts"
- Cost: "View" (no energy)
- Tap: Navigate to `RegionalChartsScreen`

---

## 💰 Royalty Payment Flow

### Daily Tick (Automatic)
```
┌─────────────────────────────────────────────┐
│ Game Time: Day 5 → Day 6                    │
├─────────────────────────────────────────────┤
│                                             │
│ For each released song:                     │
│   1. Calculate daily streams (10,000)       │
│   2. Distribute across regions:             │
│      - USA: 5,500                           │
│      - Europe: 2,000                        │
│      - Others: 2,500                        │
│   3. Calculate royalties per platform:      │
│      - Tunify: 10,000 × 0.85 × $0.003       │
│                = $25.50                     │
│      - Maple Music: 10,000 × 0.65 × $0.01   │
│                    = $65.00                 │
│   4. Total: $90.50 added to money          │
│                                             │
│ 📈 Summer Vibes: +10.0K streams             │
│    (Total: 150.5K)                          │
│ 💰 Daily Royalties: $90.50                  │
└─────────────────────────────────────────────┘
```

### Console Output (Dashboard)
```
📈 Summer Vibes: +10.0K streams (Total: 150.5K)
📈 Midnight Dreams: +5.2K streams (Total: 87.3K)
💰 Daily Royalties: $157.20
```

---

## 🎪 User Journey

### Step 1: Release a Song
```
🎤 Write Song
  ↓
🎨 Choose Cover Art
  ↓
📱 Select Platforms (Tunify, Maple Music)
  ↓
🚀 Release Now!
  ↓
✅ Success!
   - +50 fame
   - +170 fanbase
   - +90 USA fans (regional)
   - No money yet (royalties come daily)
```

### Step 2: Wait for Daily Tick
```
⏰ 1 game day passes (1 real-time hour)
  ↓
📊 Automatic stream growth
  ↓
💵 Royalty payment calculated
  ↓
💰 Money += $35.70
  ↓
🔔 Notification: "Daily Royalties: $35.70"
```

### Step 3: Check Charts
```
🏠 Dashboard → Quick Actions
  ↓
📊 Tap "Charts" button
  ↓
🌍 Regional Charts Screen opens
  ↓
🇺🇸 See "Summer Vibes" at #3 in USA!
  ↓
🇪🇺 Check Europe tab → Not charting yet
  ↓
🇳🇬 Check Africa tab → #7!
```

### Step 4: Track Progress
```
Day 2: #3 in USA, $42.30 royalties
Day 3: #2 in USA, $58.90 royalties
Day 4: #1 in USA! 🥇 $112.50 royalties
Day 5: Still #1, $145.20 royalties
  ↓
⭐ Achievement: "First #1 Hit!"
💰 Total Earned: $394.60
```

---

## 🧩 Component Hierarchy

```
RegionalChartsScreen (StatefulWidget)
├─ Scaffold
│  ├─ AppBar
│  │  ├─ Back Button
│  │  ├─ Title: "Regional Charts"
│  │  └─ TabBar (8 tabs)
│  │     ├─ Global 🌍
│  │     ├─ USA 🇺🇸
│  │     ├─ Europe 🇪🇺
│  │     └─ ... (5 more)
│  │
│  └─ TabBarView (8 views)
│     └─ _buildChartTab(region)
│        ├─ FutureBuilder<List<ChartEntry>>
│        │  ├─ Loading: CircularProgressIndicator
│        │  ├─ Error: Error message + icon
│        │  ├─ Empty: Flag + "No songs yet"
│        │  └─ Data: Chart list
│        │
│        ├─ Chart Header
│        │  ├─ Flag emoji (40px)
│        │  ├─ Region name (24px bold)
│        │  └─ Song count (14px)
│        │
│        ├─ ListView.builder
│        │  └─ _buildChartEntry() × 10
│        │     ├─ Medal/Position Circle
│        │     ├─ Song Info Column
│        │     │  ├─ Title
│        │     │  ├─ Artist + Icon
│        │     │  └─ Genre Badge + Streams
│        │     └─ Trend Indicator (Top 3)
│        │
│        └─ _buildYourSongsSection()
│           ├─ FutureBuilder<Map<Song, Position>>
│           ├─ Section Title + Icon
│           ├─ Song count
│           └─ Highest position
```

---

## 🎨 Design Principles

### 1. **Visual Hierarchy**
- Medals draw attention to top performers
- Your songs highlighted with borders
- Genre badges for quick identification

### 2. **Responsive Design**
- Scrollable tabs for 8 regions
- List view handles any number of songs
- Flexible sizing for song titles

### 3. **Feedback & Affordances**
- Tap animation on your songs
- Snackbar confirmation
- Loading states for async operations

### 4. **Color Psychology**
- Gold/Silver/Bronze = Achievement
- Green = Positive (trending up)
- Cyan = "You" (personal)
- Genre colors = Quick recognition

### 5. **Information Density**
- 3 lines per entry = Scannable
- Essential info only (no clutter)
- Footer section = Additional context

---

## 📐 Layout Measurements

### AppBar
- Height: 56px (standard) + 48px (TabBar) = 104px
- Tab width: Auto (scrollable)
- Tab padding: 12px horizontal

### Chart Header
- Height: ~120px
- Flag size: 40px
- Padding: 16px all sides

### Chart Entry
- Height: ~90px
- Margin bottom: 12px
- Border radius: 12px
- Padding: 16px all sides

### Medal/Position Circle
- Size: 50×50px
- Border radius: 25px (circle)
- Icon size: 28px (Top 3)

### Footer Section
- Height: Auto (~100px)
- Border top: 1px white12
- Padding: 16px all sides

---

## 🚦 Interaction States

### Chart Button (Dashboard)
```
Idle:
  - Green gradient background
  - White icon & text
  - Subtle shadow

Hover: (Web/Desktop)
  - Brighter gradient
  - Larger shadow

Tap:
  - Ink ripple animation
  - Navigate to charts

Disabled: (N/A - always enabled)
```

### Chart Entry (Your Song)
```
Idle:
  - Colored border
  - Accent background

Tap:
  - Ink ripple animation
  - Show snackbar with position

Hold: (Future enhancement)
  - Show song details modal
```

### Tab Selection
```
Selected:
  - White text
  - Bold font
  - 3px cyan underline

Unselected:
  - White54 text
  - Regular font
  - No underline
```

---

**End of Visual Guide** 🎨✨

For implementation details, see: `REGIONAL_CHARTS_AND_ROYALTIES_COMPLETE.md`
