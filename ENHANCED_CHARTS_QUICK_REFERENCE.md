# Enhanced Charts System - Quick Reference

**Version:** 1.3.0  
**Date:** October 16, 2025

---

## 🎯 Chart Types Available

### ⏱️ Time Periods
- **Daily** - Rankings by last in-game day's streams
- **Weekly** - Rankings by last 7 in-game days' streams (rolling window)

### 🎵 Content Types
- **Singles** - Solo tracks only
- **Albums** - Full albums only
- **Artists** - Ranked by combined performance

### 🌍 Scope
- **Global** - Worldwide rankings
- **Regional** - 7 regions (USA, Europe, UK, Asia, Africa, Latin America, Oceania)

---

## 📊 Total Chart Combinations: 18

| Daily | Weekly |
|-------|--------|
| Daily Singles Global | Weekly Singles Global |
| Daily Singles Regional (×7) | Weekly Singles Regional (×7) |
| Daily Albums Global | Weekly Albums Global |
| Daily Albums Regional (×7) | Weekly Albums Regional (×7) |
| Daily Artists Global | Weekly Artists Global |
| Daily Artists Regional (×7) | Weekly Artists Regional (×7) |

---

## 🚀 Quick Start

### Access Charts
```dart
Dashboard → Charts Button → Unified Charts Screen
```

### Filter Chart
1. Select **Period**: Daily or Weekly
2. Select **Type**: Singles, Albums, or Artists
3. Select **Region**: Global or specific region

### View Results
- Pull down to refresh
- Tap your entries to see details
- Look for ⭐ to find your content

---

## 💡 Key Differences

### Daily vs Regional vs Spotlight (Old System)

| Feature | Regional Charts | Spotlight Charts | **Enhanced Charts (NEW)** |
|---------|----------------|------------------|--------------------------|
| Time Window | All-time | All-time (200) / 7-day (Hot 100) | **Daily OR Weekly** |
| Content | Songs only | Albums OR Singles | **Singles OR Albums OR Artists** |
| Scope | Per-region + Global | Global only | **Global OR Per-region** |
| Filters | Fixed | Fixed (2 charts) | **Fully customizable** |
| Artist Rankings | ❌ | ❌ | **✅ NEW!** |

---

## 🎨 UI Elements

### Position Badges
- 🥇 **#1** - Gold
- 🥈 **#2** - Silver  
- 🥉 **#3** - Bronze
- **#4+** - Grey

### User Content
- **Green border** around your entries
- ⭐ **Star icon** next to your name
- **Green background** tint

---

## 📈 Chart Mechanics

### Daily Charts
- **Updates:** Every in-game day
- **Metric:** `lastDayStreams`
- **Example:** Yesterday's viral hits

### Weekly Charts
- **Updates:** Every in-game day
- **Metric:** `last7DaysStreams`
- **Rolling Window:** Oldest day drops off each day
- **Example:** This week's trending songs

---

## 🔍 How to Use Strategically

### For New Artists
✅ **Daily Singles Global** - Best chance to chart quickly  
✅ **Regional Daily** - Dominate your home region  

### For Established Artists
✅ **Weekly Charts** - Show consistent performance  
✅ **Artist Charts** - Overall recognition  

### For Albums
✅ **Daily Albums** - Launch day impact  
✅ **Weekly Albums** - Sustained success  

---

## 🛠️ Technical Details

### New Song Fields
```dart
lastDayStreams: 0      // Yesterday's streams
last7DaysStreams: 0    // Last 7 days' streams
```

### Update Frequency
- **Daily streams:** Reset each game day
- **Weekly streams:** Rolling decay + addition
- **Charts:** Real-time from Firebase

---

## 📱 Navigation

### From Dashboard
```
Dashboard → Charts → Unified Charts
```

### Direct Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const UnifiedChartsScreen(),
  ),
);
```

---

## 🔗 Related Documentation

- **Full Guide:** `ENHANCED_CHARTS_SYSTEM.md`
- **Old System:** `RELEASE_NOTES_v1.2.0.md`
- **Implementation:** See service & screen files

---

## ⚡ Quick Tips

1. **Check daily charts** for instant feedback
2. **Use weekly charts** for trend analysis
3. **Filter by region** to focus growth
4. **Track artist ranking** for overall progress
5. **Pull to refresh** for latest data

---

## 🎯 Most Popular Chart Combinations

1. **Weekly Singles Global** - Overall trending singles
2. **Daily Singles Regional** - Local viral hits
3. **Weekly Artists Global** - Top artists worldwide
4. **Daily Albums Global** - New album releases
5. **Weekly Singles USA** - US market leaders

---

**Quick Start:** Dashboard → Charts → Select filters → View!

*For detailed documentation, see ENHANCED_CHARTS_SYSTEM.md*
