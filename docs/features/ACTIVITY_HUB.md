# Activity Hub System

## Overview
The Activity Hub is a centralized navigation system that provides access to four core gameplay activities: **Practice**, **Spotlight Charts**, **Side Hustle**, and **ViralWave**. It serves as the main hub for player progression and music career management.

## Access
- **Location**: Bottom navigation bar, tab 1 (Activity icon)
- **Replaces**: Previous Leaderboards tab
- **Icon**: Flash/lightning bolt symbol

## Hub Applications

### 1. 📚 Practice
**Purpose**: Improve artist skills through focused training sessions

**Features**:
- 4 practice types with different skill focuses
- Energy cost: 15 per session
- XP gain varies by practice type (10-18 XP)

**Practice Types**:
1. **Songwriting** (🎼)
   - Primary: Songwriting skill +2-5
   - Secondary: Creativity +3
   - XP gain: +15

2. **Lyrics** (✍️)
   - Primary: Lyrics skill +2-5
   - Secondary: Creativity +3
   - XP gain: +12

3. **Composition** (🎹)
   - Primary: Composition skill +2-5
   - Secondary: Creativity +3
   - XP gain: +18

4. **Inspiration** (💡)
   - Primary: Inspiration +10
   - Secondary: Creativity +5
   - XP gain: +10

**Mechanics**:
- Better gains when energy > 50
- All sessions add +1 fan
- Shows success dialog with all improvements

**File**: `lib/screens/practice_screen.dart`

---

### 2. 📊 Spotlight Charts
**Purpose**: View real-time player rankings and chart performance

**Features**:
- Global player rankings
- Song performance charts
- Weekly top songs
- Community leaderboards

**File**: `lib/screens/unified_charts_screen.dart`

---

### 3. 💼 Side Hustle
**Purpose**: Earn money through part-time jobs while building music career

**Features**:
- 10 different job types
- Shared contract pool (first-come, first-served)
- Daily energy costs and pay
- Contract lengths: 3-7 days

**Job Types**:
- Security Guard (🛡️)
- Dog Walker (🐕)
- Babysitter (👶)
- Food Delivery (🍕)
- Rideshare Driver (🚗)
- Retail Associate (🛍️)
- Tutor (📚)
- Bartender (🍹)
- Cleaner (🧹)
- Waiter (🍽️)

**Economy**:
- Daily pay: $40-200
- Energy cost: 8-30 per day
- Quality ratings help choose best contracts

**File**: `lib/screens/side_hustle_screen.dart`  
**Documentation**: `docs/features/SIDE_HUSTLE_SYSTEM.md`

---

### 4. 📱 ViralWave
**Purpose**: Promote songs and albums to gain fans and streams

**Features**:
- 4 campaign types
- Variable costs and effectiveness
- Results based on fame, quality, and investment

**Campaign Types**:

1. **Single Song** (🎵)
   - Cost: 10 ⚡ + $100
   - Base reach: 5,000 people
   - Promotes one selected song

2. **Single Release** (💿)
   - Cost: 15 ⚡ + $300
   - Base reach: 12,000 people
   - Broader reach than individual song

3. **EP Campaign** (📀)
   - Cost: 20 ⚡ + $800
   - Base reach: 25,000 people
   - Promotes all released songs

4. **LP/Album Campaign** (💽)
   - Cost: 30 ⚡ + $2,000
   - Base reach: 50,000 people
   - Major promotional push

**Effectiveness**:
- Base reach + (fame × 100) + (fanbase × 50)
- Conversion rates:
  - Fans: ~12-18% of reach
  - Streams: ~25-35% of reach
- Randomness factor: 80-120% of estimate

**Fame Gains**:
- Song: +3 fame
- Single: +5 fame
- EP: +10 fame
- LP/Album: +20 fame

**File**: `lib/screens/viralwave_screen.dart`

---

## Navigation Changes

### Dashboard Updates
**Before**:
- Tab 1: Leaderboards (online mode required)
- Quick Actions: 6 buttons including Practice, Charts, Side Hustle, Promote

**After**:
- Tab 1: Activity Hub (always accessible)
- Quick Actions: 2 buttons (Write Song, Studio only)

**Rationale**:
- Consolidates related activities
- Reduces dashboard clutter
- Improves navigation flow
- Separates creation (Quick Actions) from progression (Activity Hub)

### Modified Files
- `lib/screens/dashboard_screen_new.dart`:
  - Removed: Practice, Promote, Charts, Side Hustle from Quick Actions
  - Changed tab 1 navigation to ActivityHubScreen
  - Removed unused imports (leaderboard_screen, side_hustle_screen, unified_charts_screen)

---

## UI/UX Design

### Hub Screen
- **Layout**: 2×2 grid of app cards
- **Quick Stats**: Energy, Money, Songs count
- **Theme**: Dark mode with gradient backgrounds
- **Icons**: Large emoji + icon combinations

### App Cards
- Gradient backgrounds per app
- Color coding:
  - Practice: Orange/yellow (#F39C12)
  - Spotlight Charts: Green (#4CAF50)
  - Side Hustle: Yellow (#FFD60A)
  - ViralWave: Pink/red (#FF6B9D → #FF1744)
- Badge system for active states
- Descriptive subtitles

### Responsive Design
- Adapts to screen size
- Maintains 2×2 grid on mobile
- Scales appropriately on tablet/desktop

---

## Technical Implementation

### State Management
- Each hub app receives:
  - `artistStats`: Current player stats
  - `onStatsUpdated`: Callback for stat changes
  - `currentGameDate`: Game time context

### Data Flow
```
Dashboard → Activity Hub → Individual App
                ↓
         Stats Updated
                ↓
         Callback Chain
                ↓
     Save to Firestore
```

### Integration Points
1. **Practice**: Updates skills, XP, energy
2. **Charts**: Read-only, no stat changes
3. **Side Hustle**: Updates money, energy, manages contracts
4. **ViralWave**: Updates fans, streams, fame, money

---

## Economy Balance

### Energy Management
- Practice: -15 energy, +skills/XP
- Side Hustle: -8 to -30 energy/day, +money
- ViralWave: -10 to -30 energy, +fans/streams/fame
- Write Song: -15 to -40 energy (still in Quick Actions)

**Strategy**: Players must balance:
- Skill improvement (Practice)
- Money earning (Side Hustle)
- Audience growth (ViralWave)
- Content creation (Quick Actions)

### Money Flow
**Income**:
- Side Hustle: $40-200/day
- Streams: Passive income
- Starting: $5,000

**Expenses**:
- ViralWave: $100-2,000 per campaign
- Studio time: Various costs
- Future features: Equipment, etc.

---

## Future Enhancements

### Potential Additions
1. **Collaboration Hub**: Find other artists for features
2. **Contest Center**: Enter music competitions
3. **Merch Store**: Design and sell merchandise
4. **Tour Planning**: Book and manage concert tours
5. **Social Media**: Advanced engagement mechanics

### Analytics Dashboard
- Track promotion ROI
- Practice effectiveness over time
- Side hustle earnings history
- Chart position trends

### Notifications
- New contracts available
- Chart position changes
- Campaign results
- Practice milestones

---

## Player Benefits

### Organization
- One tap to all progression features
- Clear separation of concerns
- Less cluttered interface

### Strategy
- Easy comparison of options
- Quick switching between activities
- Visual feedback on active states

### Progression
- Clear skill improvement path (Practice)
- Reliable income source (Side Hustle)
- Effective promotion tools (ViralWave)
- Performance tracking (Charts)

---

## Development Notes

### File Structure
```
lib/screens/
├── activity_hub_screen.dart      # Main hub container
├── practice_screen.dart           # Skill training
├── side_hustle_screen.dart        # Part-time jobs
├── viralwave_screen.dart          # Music promotion
└── unified_charts_screen.dart     # Rankings/charts
```

### Dependencies
- All screens depend on `ArtistStats` model
- State updates propagate through callbacks
- Game time synced via `GameTimeService`
- Firestore used for persistent data

### Testing Checklist
- [ ] All 4 apps accessible from hub
- [ ] Stat updates save correctly
- [ ] Energy/money costs apply
- [ ] Success dialogs show correct values
- [ ] Navigation back to hub works
- [ ] Quick stats update in real-time
- [ ] Responsive layout on all devices

---

## Conclusion

The Activity Hub successfully consolidates four major gameplay systems into a unified, accessible interface. It improves navigation, reduces dashboard clutter, and provides players with clear progression paths. The system is extensible for future features while maintaining a clean, intuitive design.
