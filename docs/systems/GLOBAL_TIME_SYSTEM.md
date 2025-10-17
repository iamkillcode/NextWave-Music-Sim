# 🕐 Global Game Time System

## Overview

NextWave uses a **synchronized global time system** that ensures all players experience the same in-game date and time, regardless of when they joined the game. This creates a fair multiplayer environment where:

- 🌍 All players are on the same timeline
- 📅 Scheduled events happen simultaneously for everyone
- 🚫 Device time manipulation is prevented
- ⏰ Time flows even when players are offline

---

## ⚡ Time Conversion Formula

### **1 Real Hour = 1 In-Game Day**

The game uses an accelerated time system where:
- **1 real-world hour** = **1 in-game day** (24 game hours)
- **24 real-world hours** (1 day) = **24 in-game days**
- **7 real-world days** (1 week) = **168 in-game days** (~5.5 months)
- **30 real-world days** (1 month) = **720 in-game days** (~2 years)

This rapid progression allows players to experience years of career growth in weeks of real-time gameplay.

---

## 📊 How It Works

### **Initialization (First Launch)**

When the first player launches the game, the system creates a Firestore document:

```javascript
gameSettings/globalTime {
  realWorldStartDate: October 1, 2025 00:00 (Timestamp),
  gameWorldStartDate: January 1, 2020 (Timestamp),
  hoursPerDay: 1,  // 1 real hour = 1 game day
  description: "1 real world hour equals 1 in-game day"
}
```

This acts as the **anchor point** for all time calculations across all players.

---

### **Time Calculation Algorithm**

Every time the app updates (every minute), it calculates the current game date:

```dart
// 1. Get elapsed real-world time
Real hours elapsed = (Current time) - (Real world start date)

// 2. Convert to game days (1 hour = 1 day)
Game days elapsed = Real hours elapsed ÷ 1

// 3. Calculate current game date
Current game date = (Game world start date) + Game days elapsed
```

**Example:**
- **Real start**: Oct 1, 2025 00:00
- **Game start**: Jan 1, 2020
- **Current real time**: Oct 1, 2025 14:30 (14.5 hours later)
- **Game days elapsed**: 14.5 ÷ 1 = **14.5 days**
- **Current game date**: Jan 1, 2020 + 14.5 days = **Jan 15, 2020** ✅

---

## 🎮 Features Powered by Global Time

### **1. Age Progression**

Players age based on the global game time:

```dart
int currentAge = startingAge + (years elapsed in game);

// Example:
// Started at age 22 on Jan 1, 2020
// Current date: Jan 1, 2022 (2 years later in-game)
// Current age: 22 + 2 = 24 years old
```

### **2. Song Release Scheduling**

Songs can be scheduled for future release:
- **Release Now**: Song goes live immediately
- **Schedule Release**: Pick a future in-game date
- All players see the release at the same moment

### **3. Chart Rankings**

Leaderboards use global time for:
- "NEW" badges (songs < 7 days old)
- "HOT" indicators (songs < 6 hours old)
- Weekly chart resets
- Historical peak positions

### **4. Energy Regeneration**

Energy regenerates based on game time passage:
- Even if you're offline for 5 real hours
- You return to find 5 game days have passed
- Energy has regenerated accordingly

---

## 📱 User Interface Display

### **Top Status Bar**

The dashboard shows the synchronized time:

```
🌍 15:42              SYNCED
   January 15, 2020     ✓
```

- **Globe icon (🌍)**: Indicates global synchronized time
- **Time**: Current in-game time (calculated from real time)
- **Date**: Current in-game date
- **"SYNCED" badge**: Confirms connection to Firestore

---

## 🔄 Time Flow Examples

### **Scenario 1: Active Player**

**You play for 3 real hours:**
- Real time: 10:00 AM → 1:00 PM (3 hours)
- Game time: Jan 1 → Jan 4 (3 days)
- Your character ages by 3 days
- You experience 3 full in-game days of activities

### **Scenario 2: Offline Player**

**You're offline for 24 real hours:**
- Real time: Monday 9:00 AM → Tuesday 9:00 AM (24 hours)
- Game time: Jan 1 → Jan 25 (24 days)
- When you return:
  - Your age has increased by 24 days
  - Energy has fully regenerated
  - Your scheduled song releases may have gone live
  - Leaderboards have updated with new rankings

### **Scenario 3: Two Players Join at Different Times**

**Player A joins:** Oct 1, 2025 (real) → Jan 1, 2020 (game), age 22  
**Player B joins:** Oct 10, 2025 (real) → Jan 11, 2020 (game), age 25

**Both play on Oct 15, 2025 (real):**
- Game date for everyone: **Jan 15, 2020**
- Player A: 22 years old (14 game days since joining)
- Player B: 25 years old (4 game days since joining)

Both see the same leaderboards, the same global date, and can compete fairly! 🎵

---

## 🛠️ Technical Implementation

### **Files Modified:**

1. **`lib/services/game_time_service.dart`**
   - `hoursPerGameDay = 1` (time conversion constant)
   - `getCurrentGameDate()` - Calculates synchronized date
   - `formatGameDate()` - Formats display strings

2. **`lib/screens/dashboard_screen_new.dart`**
   - `_initializeGameTime()` - Initializes on app start
   - `_updateGameTime()` - Updates every minute
   - Timer updates UI with current game date

3. **`lib/models/artist_stats.dart`**
   - `getCurrentAge(DateTime gameDate)` - Calculates age based on game time
   - `careerStartDate` - Tracks when player started career

---

## 🔥 Benefits

✅ **Fair Competition** - Everyone on same timeline  
✅ **No Cheating** - Can't manipulate device clock  
✅ **Persistent World** - Time continues offline  
✅ **Realistic Aging** - Characters age with career progression  
✅ **Synchronized Events** - Songs release simultaneously  
✅ **Accurate Rankings** - Leaderboards reflect true performance  

---

## 🎯 Summary

The **1 hour = 1 day** time system creates an accelerated but fair multiplayer experience where:
- Players can experience years of career growth in weeks
- All players compete on the same timeline
- Time-based features (aging, releases, charts) work consistently
- The game world feels alive and dynamic

**Next time you play, watch the date tick forward as real hours pass, and your character's career progresses through the years!** 🌟⏰

---

*Last updated: October 12, 2025*
