# 🎵 NextWave - Music Artist Life Simulation Game

**Platform:** Flutter (Web, Mobile, Desktop)  
**Genre:** Music Industry Simulation / Life Sim  
**Status:** Active Development  
**Firebase:** Real-time Multiplayer & Cloud Save

---

## 🎮 Game Overview

NextWave is a music artist life simulation where players start as an unknown artist and work their way to global stardom. The game simulates the real music industry experience - from writing your first song in a bedroom to performing on world stages and dominating streaming charts.

### Core Concept
- **Start:** Unknown artist with $1,000 and a dream
- **Goal:** Build fanbase, release hit songs, earn money, gain fame
- **Progression:** Skills improve through practice, songs get better, streams increase
- **Multiplayer:** Compete on global leaderboards, see other players' songs

---

## 🎯 Key Features

### 1. **Song Creation System**
Players write songs by choosing:
- **Genre:** Hip Hop, R&B, Rap, Trap, Drill, Afrobeat, Country, Jazz, Reggae (9 genres)
- **Effort Level:** 1-3 (affects energy cost, quality potential, skill gains)
- **Quality:** Dynamically calculated based on:
  - Songwriting skill
  - Lyrics skill  
  - Composition skill
  - Experience points
  - Inspiration level
  - Randomness (±15%)

**Song Lifecycle:**
```
Written → Recorded (at studio) → Released (on platforms) → Earning Streams
```

### 2. **Recording Studios**
15+ real-world inspired studios across different regions:
- **Quality Tiers:** Basic (70-75%) → Professional (80-85%) → Legendary (90-95%)
- **Costs:** $500 (basic) → $5,000 (legendary)
- **Regional Studios:** Each world region has unique studios
- **Recording Boost:** Studio quality affects final song quality

### 3. **Streaming Platforms**

**Tunify** (Spotify-inspired):
- Release songs for $5,000
- Earn streams based on quality
- Track likes and engagement
- Green & black theme

**Maple Music** (Apple Music-inspired):
- Alternative platform
- Different audience demographics
- Red & white theme
- Cross-platform releases possible

**Media Hub:**
- View all platforms as mobile-style app icons
- Shows total streams per platform
- Unified streaming dashboard

### 4. **Dynamic Stream Growth System** ⭐ NEW
Realistic stream growth that factors in:
- **Song Quality:** Higher quality = more streams
- **Days Since Release:** Decay curve (peaks early, tapers off)
- **Virality Score:** Random events can make songs go viral
- **Loyal Fanbase:** Dedicated fans stream consistently
- **Platform Popularity:** Different platforms have different reach
- **Fame Multiplier:** More famous = more discovery

**Daily Updates:**
- Streams grow every in-game day
- Virality creates random spikes (2-7x normal streams)
- Loyal fans provide steady baseline streams
- Discovery factor brings new listeners

### 5. **Skills System**
Four main skills that improve through actions:
- **Songwriting Skill:** Improves song quality
- **Lyrics Skill:** Better lyric quality
- **Composition Skill:** Better music composition
- **Experience Points:** Overall career progression

**Skill Gains Based On:**
- Song genre (focus areas)
- Effort level (1-3)
- Current song quality
- Repetition and practice

### 6. **World Travel System**
Travel between 7 global regions:
- 🇺🇸 **USA:** Hip Hop central, high income (1.0x)
- 🇪🇺 **Europe:** Electronic music hub, very high income (1.15x)
- 🇬🇧 **UK:** Grime & Drill origin, high income (1.05x)
- 🇯🇵 **Asia:** K-Pop & J-Pop markets, high income (1.1x)
- 🇳🇬 **Africa:** Afrobeat homeland, moderate income (0.8x)
- 🇧🇷 **Latin America:** Reggaeton & Latin vibes, low income (0.5x)
- 🇦🇺 **Oceania:** Indie & alternative scene, moderate income (0.65x)

**Travel Costs:**
- Based on distance between regions
- Wealth multiplier (rich artists pay less relatively)
- Unlock requirement (need 10+ fame to travel)

### 7. **Game Time System**
- **Real Time to Game Time:** 1 real hour = 1 game day
- **Synchronized Globally:** All players experience the same date
- **Firebase Server Timestamps:** Ensures no time manipulation
- **Date Display:** Shows current in-game date (starts January 1, 2020)
- **Energy Regeneration:** Tied to time passage

### 8. **Economy System**

**Earning Money:**
- Writing songs: $50-300 per song
- Releasing songs: $5,000+ from streams
- Album releases: $2,000-8,000 advance
- Passive income from active streams

**Spending Money:**
- Recording: $500-5,000 per song
- Releasing: $5,000 per song
- Traveling: $1,000-5,000 per trip
- Studios: Varies by quality

**Starting Money:** $1,000

### 9. **Stats & Progression**

**Core Stats:**
- **Money:** Cash for investments
- **Fame:** 0-100, unlocks features
- **Energy:** 0-100, regenerates over time
- **Fanbase:** Total fans (Level display)
- **Loyal Fanbase:** Dedicated streaming fans
- **Inspiration:** Creativity/hype meter
- **Age:** Player age, advances with game time

**Progression Metrics:**
- Songs Written
- Albums Released
- Concerts Performed (planned)
- Total Streams
- Career Level (based on achievements)

### 10. **Multiplayer Features**

**Leaderboards:**
- Top Songs (by streams)
- Top Artists (by total streams)
- Net Worth Rankings
- Fame Rankings
- Recent Releases

**Social Features:**
- EchoX (Twitter-inspired social media)
- Post updates, gain followers
- Like and echo other posts
- Build social presence

**Firebase Integration:**
- Real-time data sync
- Cloud save (all progress saved)
- Authentication (email or guest)
- Global competition

---

## 🎨 UI/UX Design

### Design Philosophy
- **Dark Theme:** GitHub-inspired dark interface
- **Modern Gradients:** Vibrant accent colors
- **Card-Based Layout:** Clean, organized information
- **Mobile App Icons:** Platforms displayed as app icons
- **Animated Progress Bars:** Visual feedback on stats
- **Color-Coded Stats:**
  - Green: Money
  - Pink/Red: Energy
  - Blue: Skills
  - Purple: Creativity
  - Gold: Fame

### Key Screens
1. **Dashboard:** Main hub with stats, actions, date display
2. **Music Hub:** Write, record, manage songs
3. **Media Hub:** Streaming platforms overview
4. **Tunify/Maple Music:** Platform-specific interfaces
5. **World Map:** Interactive travel system
6. **Leaderboards:** Global rankings
7. **Settings:** Profile management, logout
8. **Studios List:** Browse and select recording studios
9. **Release Flow:** Multi-step song release process

---

## 🔥 Recent Updates & Fixes

### October 14-15, 2025

**✅ Song Persistence System**
- Added JSON serialization to Song model
- Songs now save to Firebase
- Songs persist across login sessions
- Fixed money/songs disappearing bug

**✅ Starting Money Standardization**
- Unified to $1,000 starting money
- Consistent across all code paths
- Fair gameplay for all players

**✅ Dynamic Stream Growth**
- Realistic stream increase over time
- Virality system for hit songs
- Loyal fanbase mechanics
- Multi-factor growth algorithm

**✅ Media Hub Enhancement**
- Mobile app-style interface
- Grid layout with icons
- Badge notifications for streams
- Beautiful gradients and animations

**✅ Date Synchronization**
- Firebase server timestamps
- Global date sync across players
- "Syncing..." loading state
- Proper null handling

---

## 🎯 Current Game Loop

### Early Game (Starting Out)
```
1. Start with $1,000, 100 energy, 0 fame
2. Write songs (costs 20 energy, earns $50-300)
3. Improve skills through repetition
4. Build up money to $5,000+
5. Record best songs at studio
6. Release on streaming platforms
7. Start earning passive income from streams
```

### Mid Game (Rising Artist)
```
1. Multiple songs earning streams daily
2. Travel to new regions for inspiration
3. Build loyal fanbase (100-1000 fans)
4. Record at better studios
5. Release albums (3+ songs)
6. Gain fame (10-50)
7. Compete on leaderboards
```

### Late Game (Superstar)
```
1. Viral hits with millions of streams
2. Large loyal fanbase (10,000+)
3. High fame (50-100)
4. Record at legendary studios
5. Multi-platform releases
6. Top of global leaderboards
7. Massive passive income
```

---

## 💻 Technical Architecture

### Frontend
- **Framework:** Flutter (Dart)
- **State Management:** setState (simple & effective)
- **Navigation:** MaterialPageRoute
- **UI:** Material Design with custom theming

### Backend
- **Firebase Authentication:** Email/Password + Guest accounts
- **Cloud Firestore:** Player profiles, songs, leaderboards
- **Server Timestamps:** Global time synchronization
- **Collections:**
  - `players`: User profiles and stats
  - `songs`: Published songs (planned)
  - `leaderboards`: Rankings (planned)

### Data Models
- **ArtistStats:** Player statistics and progress
- **Song:** Song data with quality, state, streams
- **Studio:** Recording studio properties
- **WorldRegion:** Region data with bonuses
- **StreamingPlatform:** Platform configurations

### Services
- **GameTimeService:** Manages global game time
- **StreamGrowthService:** Calculates daily stream increases
- **FirebaseService:** Cloud data operations
- **DemoFirebaseService:** Offline/demo mode

---

## 🎮 Gameplay Mechanics

### Song Quality Calculation
```dart
Quality = (
  (Songwriting Skill × 0.35) +
  (Lyrics Skill × 0.25) +
  (Composition Skill × 0.25) +
  (Experience / 50) +
  (Inspiration / 5) +
  Genre Bonus
) × Effort × Random(0.85-1.15)
```

### Stream Growth Formula
```dart
Daily Streams = 
  Loyal Fan Streams (0.5-2 per fan) +
  Discovery Streams (decay curve) +
  Viral Streams (2-7x spikes) +
  Casual Fan Streams (quality-based)
```

### Fame Gain
```dart
Fame += (Song Quality / 100) × Streams × Platform Multiplier
```

### Skill Progression
```dart
Skill Gain = Base Gain × Effort × Genre Match × Quality Bonus
```

---

## 🎯 Design Goals & Philosophy

### Core Pillars
1. **Realistic Progression:** Slow start, rewarding growth
2. **Strategic Decisions:** When to spend, what to focus on
3. **Skill-Based:** Better skills = better songs = more success
4. **Time Investment:** Passive growth rewards consistent play
5. **Competitive:** Leaderboards create engagement
6. **Creative Freedom:** Multiple paths to success

### Player Agency
- Choose genres and style
- Decide when to record vs. release
- Pick regions to travel to
- Manage energy and money
- Build social media presence

### Balanced Economy
- Can't spam actions (energy system)
- Investments needed (recording, releasing)
- Risk vs. reward (spend $5K to potentially earn $50K+)
- Multiple income streams

---

## 🚀 Future Potential Features

### Planned/Suggested Additions

**1. Concerts & Live Performances**
- Book venues
- Sell tickets
- Build local fanbase
- Energy-intensive but profitable

**2. Collaborations**
- Feature other players
- Cross-promote songs
- Split earnings
- Unlock bonus fans

**3. Music Videos**
- Create videos for songs
- Cost money but boost streams
- Different styles and budgets
- Unlock achievements

**4. Record Label Contracts**
- Sign with labels for advances
- Trade creative control for marketing
- Long-term deals with pros/cons
- Or stay independent

**5. Awards & Achievements**
- Grammy-style awards
- Platinum records
- Hall of fame
- Special badges

**6. Song Charts**
- Daily/Weekly top 100
- Genre-specific charts
- Regional charts
- Historical tracking

**7. Radio Play**
- Earn money from radio spins
- Different from streams
- Regional radio stations
- Payola system (controversial choice)

**8. Merchandise**
- Sell t-shirts, albums
- Passive income source
- Requires fame threshold
- Design customization

**9. Social Media Growth**
- Followers impact discovery
- Posting strategy
- Viral moments
- Influencer partnerships

**10. Producer/Writer Hiring**
- Hire talent for quality boost
- Cost money but improve songs
- Build team relationships
- Unlock legendary producers

---

## ❓ Questions for Review

### Gameplay Balance
1. Is $1,000 starting money appropriate?
2. Should recording costs be lower/higher?
3. Is the stream growth rate realistic?
4. Are skill progression speeds good?
5. Should there be more ways to earn early game?

### Features
1. What features would make the game more engaging?
2. Are the 9 genres sufficient or too limited?
3. Should concerts be prioritized?
4. Would music videos add value?
5. Is social media (EchoX) worth expanding?

### Monetization (Future)
1. Should there be premium features?
2. Cosmetic purchases (studio themes, profile customization)?
3. Time skips or energy boosts?
4. Ad-supported free version?

### User Experience
1. Is the onboarding clear enough?
2. Are there too many stats to track?
3. Should there be a tutorial?
4. Is the progression visible enough?
5. Are actions intuitive?

### Technical
1. Should songs be stored differently (separate collection)?
2. Is the stream growth calculation server-side or client-side?
3. How to prevent cheating/exploits?
4. Should there be more real-time features?

---

## 🐛 Known Issues & Limitations

### Current Limitations
- No actual audio (visual/text-based only)
- Limited concert features
- Basic social media system
- Single-player focused (limited multiplayer)
- No music video creation

### Minor Issues
- Some documentation outdated
- Unused helper methods in code
- Could use more tooltips/help text
- Energy regeneration could be clearer

---

## 📊 Current State

### What Works Well
✅ Song creation and quality system  
✅ Skills progression  
✅ World travel mechanics  
✅ Streaming platform simulation  
✅ Firebase integration & cloud save  
✅ Dynamic stream growth  
✅ Leaderboard competition  
✅ Time synchronization  
✅ Economy balance  

### What Needs Work
⚠️ Tutorial/onboarding could be better  
⚠️ More mid-game content needed  
⚠️ Social features are basic  
⚠️ Concert system incomplete  
⚠️ Achievement system needed  
⚠️ More visual feedback wanted  

---

## 💡 Suggestions Welcome

We're looking for feedback on:

1. **Game Balance:** Too easy? Too hard? Progression speed?
2. **Features:** What would make you play longer?
3. **UI/UX:** Is it intuitive? Confusing parts?
4. **Content:** More genres? More regions? More platforms?
5. **Engagement:** What would keep you coming back?
6. **Monetization:** Fair pricing model ideas?
7. **Bugs:** Any issues you notice?
8. **Polish:** What feels unfinished?

---

## 📞 Project Info

**Repository:** NextWave-Music-Sim  
**Developer:** iamkillcode  
**Technology:** Flutter + Firebase  
**Development Stage:** Beta / Active Development  
**Target Platforms:** Web, iOS, Android, Desktop

---

**We'd love to hear your thoughts, suggestions, and ideas to make NextWave the best music simulation game possible!** 🎵🚀

What features would excite you? What would you change? What's missing?
