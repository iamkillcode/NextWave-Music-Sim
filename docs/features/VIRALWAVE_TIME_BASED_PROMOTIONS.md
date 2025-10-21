# ViralWave Time-Based Marketing System

## Overview
ViralWave has been completely overhauled to provide a realistic, time-based marketing system for promoting singles, EPs, and Albums. Players can now customize campaign duration and budget to match their strategy.

## Implementation Date
2025-01-XX

## Key Features

### 1. **Promotion Types** (Reduced from 4 to 3)
- **Song (Single Track)** - Promote one released song
- **EP** - Promote an entire EP (requires 1+ released EP)
- **Album (LP)** - Promote a full album (requires 1+ released Album)

**Removed:**
- ❌ "Single (1-2 songs)" option (redundant and confusing)

---

### 2. **Time-Based Campaigns**
Promotions are no longer instant - they take **in-game time** to show results.

#### Campaign Duration
- **User-selectable**: 1 to 30 in-game days
- Controlled via slider in UI
- Default: 7 days

#### Stream Accumulation
- Streams are distributed evenly across campaign duration
- Formula: `dailyStreams = totalStreams / campaignDays`
- Players see gradual, realistic growth instead of instant spikes

#### Technical Implementation
```dart
// Songs store promotion buffer and end date
Song {
  int promoBuffer;          // Streams added per day
  DateTime? promoEndDate;   // When promotion ends
}

// Example: 7-day campaign generating 14,000 streams
// → 2,000 streams added per day for 7 days
```

---

### 3. **Custom Budget System**

#### Base Costs
- **Song**: $500 base cost
- **EP**: $2,000 base cost
- **Album (LP)**: $5,000 base cost

#### Budget Multiplier
- **Range**: 0.5x to 3.0x (controlled via slider)
- **0.5x** - Minimal budget (50% cost, 50% effectiveness)
- **1.0x** - Standard budget (base cost, normal results)
- **3.0x** - Premium budget (300% cost, 300% effectiveness)

#### Total Cost Formula
```dart
totalCost = baseCost × days × budgetMultiplier
```

#### Examples
| Type | Days | Multiplier | Calculation | Total Cost |
|------|------|------------|-------------|------------|
| Song | 7 | 1.0x | $500 × 7 × 1.0 | **$3,500** |
| Song | 14 | 2.0x | $500 × 14 × 2.0 | **$14,000** |
| EP | 10 | 1.5x | $2,000 × 10 × 1.5 | **$30,000** |
| Album | 30 | 3.0x | $5,000 × 30 × 3.0 | **$450,000** |

---

### 4. **Cover Art Display**

All promotion selectors now show **cover art thumbnails** for visual recognition.

#### Song Selector
```dart
// Shows cover art if available
if (song.coverArtUrl != null) {
  CachedNetworkImage(
    imageUrl: song.coverArtUrl,
    width: 50,
    height: 50,
    fit: BoxFit.cover,
  );
} else {
  // Fallback: Music note icon
  Icon(Icons.music_note);
}
```

#### EP/Album Selector
- Displays album cover art from `Album.coverArtUrl`
- Shows EP/Album title and song count
- Fallback icon if no cover art uploaded

---

### 5. **Number Formatting**

All large numbers now use **comma separators** for readability.

#### Applied To:
- Fanbase count: `1,234,567`
- Money amounts: `$45,000`
- Stream counts: `2,500 streams/day`
- Total cost: `$3,500`

#### Implementation
```dart
import 'package:intl/intl.dart';

final formatter = NumberFormat('#,###');
Text(formatter.format(widget.artistStats.fanbase));
```

---

### 6. **Campaign Summary Display**

When configuring a campaign, players see **detailed projections**:

| Metric | Description | Example |
|--------|-------------|---------|
| **Total Cost** | Final cost with duration & budget | $14,000 |
| **Duration** | Campaign length | 14 in-game days |
| **Budget Level** | Multiplier applied | 2.0x |
| **Potential Reach** | Estimated audience size | 25,000 people |
| **Estimated Fans** | New fanbase gain | +3,750 fans |
| **Daily Streams** | Streams added per day | +1,000 streams/day |
| **Total Streams** | Cumulative streams | +14,000 streams |
| **Fame Boost** | Immediate fame gain | +6 fame |

---

### 7. **Launch Dialog Updates**

After launching a campaign, the dialog shows:

```
🎉 Campaign Launched!

Your campaign for "Neon Nights" is now active!

📅 Duration: 14 in-game days
👥 Expected Fans: +3,750
▶️ Daily Streams: +1,000/day
▶️ Total Streams: +14,000
⭐ Fame Boost: +6

ℹ️ Streams will accumulate gradually over 14 days
```

**Key Changes:**
- Shows campaign is **active** (not instant)
- Displays **daily stream rate** (not just total)
- Informs player streams are **gradual**

---

## Technical Changes

### File: `lib/screens/viralwave_screen.dart`

#### New Imports
```dart
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/album.dart';
```

#### New State Variables
```dart
Album? _selectedAlbum;           // Selected EP/Album
int _promoDays = 7;              // Campaign duration (1-30 days)
double _budgetMultiplier = 1.0;  // Budget multiplier (0.5x-3.0x)
```

#### Updated Data Structure
```dart
final _promotionTypes = {
  'song': {
    'name': 'Single Song',
    'baseCost': 500,  // Changed from fixed 'moneyCost'
    // ... other properties
  },
  'ep': {
    'name': 'EP',
    'baseCost': 2000,
    // ...
  },
  'lp': {
    'name': 'Album',
    'baseCost': 5000,
    // ...
  },
};
```

#### New Calculated Property
```dart
int get _totalCost {
  final baseCost = _promotionTypes[_selectedPromotionType]!['baseCost'] as int;
  return (baseCost * _promoDays * _budgetMultiplier).round();
}
```

#### New UI Methods
1. **`_buildEPSelector()`**
   - Lists all released EPs
   - Shows cover art thumbnails
   - Displays song count

2. **`_buildAlbumSelector()`**
   - Lists all released Albums
   - Shows cover art thumbnails
   - Displays song count

3. **`_buildPromotionControls()`**
   - Duration slider (1-30 days)
   - Budget multiplier slider (0.5x-3.0x)
   - Real-time cost updates

#### Updated Methods

**`_buildSongSelector()`**
- Added cover art display with `CachedNetworkImage`
- Fallback to music note icon if no cover art

**`_buildCampaignDetails()`**
- Shows total cost (not energy + money)
- Displays duration and budget level
- Shows daily stream rate (new)
- Uses comma formatting for all numbers

**`_launchCampaign()`**
- Uses `_promoDays` instead of hardcoded 5 days
- Applies `_budgetMultiplier` to results
- Handles EP/Album promotions separately
- Only deducts money (no energy cost)
- Promotes specific EP/Album songs (not all released songs)

**`_calculateFameGain()`**
- Scales with budget multiplier
- Removed 'single' case

**`_isPromotionTypeAvailable()`**
- Checks `artistStats.albums` for EP/Album availability
- No longer checks song counts

---

## Game Balance

### Cost Scaling
- **Song**: $500/day base → Great for early game
- **EP**: $2,000/day base → Mid-game investment
- **Album**: $5,000/day base → Late-game strategy

### Budget Strategy
- **0.5x**: Cost-effective for tight budgets
- **1.0x**: Standard return on investment
- **2.0x**: Aggressive growth for established artists
- **3.0x**: Maximum impact for chart domination

### Duration Strategy
| Duration | Use Case | Total Cost (Song @ 1.0x) |
|----------|----------|--------------------------|
| 1-3 days | Quick boost | $500 - $1,500 |
| 7 days | Standard campaign | $3,500 |
| 14 days | Major promotion | $7,000 |
| 30 days | Long-term strategy | $15,000 |

---

## Player-Facing Changes

### What Players See

#### Before (Old System)
- 4 promotion types (confusing)
- Instant results (unrealistic)
- Fixed costs ($5,000 flat)
- No customization
- Energy + money required
- No cover art shown

#### After (New System)
- 3 clear promotion types
- Time-based results (realistic)
- Customizable costs (flexible)
- Duration slider (1-30 days)
- Budget slider (0.5x-3.0x)
- Money only (no energy)
- Cover art thumbnails
- Comma-separated numbers

---

## Testing Checklist

- [x] Song promotion with cover art display
- [x] EP promotion with album art
- [x] Album promotion with album art
- [x] Duration slider (1-30 days)
- [x] Budget slider (0.5x-3.0x)
- [x] Cost calculation accuracy
- [x] Stream distribution over time
- [x] Fanbase gain scaling
- [x] Fame boost with multiplier
- [x] Comma formatting on all numbers
- [x] Cover art fallbacks
- [x] Campaign summary accuracy
- [x] Launch dialog information
- [x] EP/Album availability checking
- [x] No energy cost deduction
- [x] Clear unused state after launch

---

## Future Enhancements

### Potential Additions
1. **Campaign Analytics**
   - Track daily performance
   - Show ROI charts
   - Compare campaign effectiveness

2. **Targeted Promotions**
   - Select specific demographics
   - Regional targeting
   - Genre-specific boosts

3. **Campaign Scheduling**
   - Schedule campaigns in advance
   - Coordinate with releases
   - Multiple simultaneous campaigns

4. **A/B Testing**
   - Test different budgets
   - Compare durations
   - Optimize spending

5. **Social Media Integration**
   - Boost on specific platforms
   - Platform-specific bonuses
   - Cross-platform synergy

---

## Related Systems

### Integration Points
- **Song Model**: `promoBuffer` and `promoEndDate` fields
- **Album Model**: `coverArtUrl` for display
- **Time System**: In-game days for campaign duration
- **Economy**: Money-only cost structure
- **Fame System**: Immediate fame boost on launch
- **Fanbase**: Gradual growth over campaign

### Dependencies
- `intl` package for number formatting
- `cached_network_image` for cover art display
- `Album` model for EP/Album data

---

## Summary

The new ViralWave system provides:
✅ **Realistic time-based promotions** (1-30 days)
✅ **Flexible budget control** (0.5x-3.0x multiplier)
✅ **Visual cover art display** for all items
✅ **Clear number formatting** with commas
✅ **Streamlined promotion types** (removed confusion)
✅ **Detailed campaign projections** before launching
✅ **Gradual stream accumulation** over time

This creates a more strategic, realistic marketing system that gives players meaningful choices and clearer feedback on their promotional investments.
