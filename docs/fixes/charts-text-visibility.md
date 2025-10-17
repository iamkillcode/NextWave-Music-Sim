# Charts Screen Text Visibility Fix

## Issue
In the Unified Charts Screen (Spotlight Charts), the text labels for filter buttons like "Daily", "Weekly", "Singles", "Albums", and "Artists" were not readable when not selected. The text appeared in a dark/black color against a dark background, making it invisible.

## Root Cause
The `SegmentedButton` widgets didn't have explicit styling for text colors in selected and unselected states. Flutter's default styling caused the text to be dark when unselected, which is invisible against the dark app background.

## Solution
Added explicit `ButtonStyle` to both SegmentedButton widgets with:
- **foregroundColor** property that sets text color:
  - **Selected**: Theme color (colored highlight)
  - **Unselected**: White (visible on dark background)
- **backgroundColor** property for visual feedback:
  - **Selected**: Theme color with 30% opacity
  - **Unselected**: Grey[800]
- Made text **bold** for better readability

## Changes Made

### File: `lib/screens/unified_charts_screen.dart`

#### Period Filter (Daily/Weekly)
- Added `ButtonStyle` with MaterialStateProperty resolvers
- Set foreground color to white when unselected
- Set foreground color to theme color when selected
- Added bold font weight to text
- Background changes based on selection state

#### Type Filter (Singles/Albums/Artists)
- Same styling as period filter
- Added 13px font size for better fit with 3 options
- Bold text for readability
- Color transitions on selection

## Visual Changes

### Before:
- Unselected buttons: Text invisible (dark on dark)
- Selected buttons: Text visible (colored)
- Hard to see available options

### After:
- Unselected buttons: White bold text (clearly visible)
- Selected buttons: Colored bold text + colored background
- All options clearly readable at all times
- Better visual hierarchy with color coding

## Theme Integration
The buttons now use `_getThemeColor()` which returns different colors based on chart type:
- Singles: Pink/Purple
- Albums: Gold/Yellow
- Artists: Blue/Cyan

This creates a cohesive visual experience where selected filters match the chart's theme color.

## Testing Recommendations
1. Open Spotlight Charts from Activity Hub
2. Verify "Daily" and "Weekly" text is white and readable
3. Click between options - selected should be highlighted in theme color
4. Check "Singles", "Albums", "Artists" buttons - all text readable
5. Switch between different combinations - colors should update appropriately

## Impact
- **Improved UX**: Users can now see all filter options
- **Better accessibility**: High contrast white text on dark background
- **Visual consistency**: Theme colors reinforce current selection
- **Professional appearance**: Proper UI styling throughout
