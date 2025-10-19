# Chart Ranking Number Display Fix

## Issue
Songs and artists with cover art/avatars were not showing their chart position numbers, making it difficult to know their ranking at a glance.

## Solution
Added position badge overlays on top of cover art images and artist avatars.

## Changes Made

### Song Cards with Cover Art
**Before:**
- Cover art displayed without position indicator
- Only songs without cover art showed position badges

**After:**
- Position badge appears in **top-left corner** of cover art
- Semi-transparent black background with colored border
- Top 3 positions show medals: 🥇 🥈 🥉
- Positions 4+ show: #4, #5, #6, etc.

### Artist Cards with Avatars
**Before:**
- Avatar displayed without position indicator
- Only artists without avatars showed position badges

**After:**
- Position badge appears in **bottom-right corner** of avatar
- Semi-transparent black background with colored border
- Top 3 positions show medals: 🥇 🥈 🥉
- Positions 4+ show: #4, #5, #6, etc.

## Visual Design

### Badge Styling
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.75),  // Semi-transparent
    borderRadius: BorderRadius.circular(4),
    border: Border.all(
      color: position <= 3 ? medalColor : Colors.white24,
      width: 1,
    ),
  ),
  child: Text(
    position <= 3 ? emoji : '#$position',
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### Border Colors by Position
- **#1**: Gold (`Colors.amber`)
- **#2**: Silver (`Colors.grey[300]`)
- **#3**: Bronze (`Colors.brown`)
- **#4+**: Light gray (`Colors.white24`)

## Implementation Details

### Song Cover Art Stack
```dart
Stack(
  children: [
    // Cover art image (56x56)
    Container(...),
    
    // Position overlay (top-left)
    Positioned(
      top: 2,
      left: 2,
      child: positionBadge,
    ),
  ],
)
```

### Artist Avatar Stack
```dart
Stack(
  children: [
    // Avatar image (56x56 circle)
    Container(...),
    
    // Position overlay (bottom-right)
    Positioned(
      bottom: 0,
      right: 0,
      child: positionBadge,
    ),
  ],
)
```

## User Experience Improvements

### Before Fix
❌ Users couldn't tell chart position from cover art alone  
❌ Had to read surrounding text to find position  
❌ Inconsistent: some had badges, some didn't  

### After Fix
✅ Position immediately visible on all chart entries  
✅ Consistent badge placement across all entries  
✅ Top 3 positions clearly distinguished with medals  
✅ Readable with semi-transparent background  
✅ Color-coded borders for easy scanning  

## Testing

### What to Check
1. **Songs with cover art**: Position badge in top-left corner
2. **Songs without cover art**: Standard position badge (no change)
3. **Artists with avatars**: Position badge in bottom-right corner
4. **Artists without avatars**: Standard position badge (no change)
5. **Top 3 positions**: Show medal emojis instead of numbers
6. **Positions 4+**: Show #4, #5, etc.

### Test Cases
- [ ] Song at #1 with cover art shows 🥇
- [ ] Song at #5 with cover art shows #5
- [ ] Artist at #2 with avatar shows 🥈
- [ ] Artist at #10 with avatar shows #10
- [ ] Badge is readable against dark/light cover art
- [ ] Badge doesn't obscure important parts of image

## Code Changes

**File Modified**: `lib/screens/unified_charts_screen.dart`

**Lines Changed**: 
- Song card leading widget: Added Stack with Positioned overlay
- Artist card leading widget: Added Stack with Positioned overlay

**Lines Added**: +68  
**Lines Removed**: 0  
**Net Change**: More robust and consistent UI

## Related Issues
- Fixes chart readability issue
- Improves consistency across all chart types
- Enhances user experience for cover art display

---

**Status**: ✅ Complete  
**Committed**: Yes (commit 55fdbfc)  
**Hot Reload**: Recommended to see changes immediately
