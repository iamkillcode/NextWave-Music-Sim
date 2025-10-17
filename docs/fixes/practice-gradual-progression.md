# Practice System - Gradual Progression Update

## Changes Made

### Resource Consumption
Practice now requires:
- **Energy**: 15 points (unchanged)
- **Money**: $50 (NEW - for practice materials/studio time)
- **Time**: 3 hours per session (displayed, not yet integrated into game time system)

### Skill Gains - Now Gradual!
All skill gains have been significantly reduced for more realistic progression:

| Practice Type | Skill Gain | XP Gain | Special |
|--------------|------------|---------|---------|
| Songwriting  | 2-4 points | 8 XP    | -       |
| Lyrics       | 2-4 points | 6 XP    | -       |
| Composition  | 3-5 points | 10 XP   | -       |
| Inspiration  | 4-6 points | 5 XP    | Higher gain |

**Previous system**: 10-20+ points per session
**New system**: 1-6 points per session (with small random variance)

### Additional Changes

#### Fame Gains - Now Rare!
- **Before**: Always +1 fan per practice
- **After**: 33% chance to gain 1 fan (random)
- This makes fame growth much more gradual and realistic

#### Creativity Gains - Minimal
- **Before**: +3 creativity per session
- **After**: +1 creativity per session
- Tiny incremental improvements

#### UI Improvements
1. **Cost Display**: Now shows all three costs (Energy, Money, Time) in a single badge
2. **Better Warnings**: Specific messages for insufficient energy vs money
3. **Realistic Results**: Practice completion dialog shows:
   - Narrative message about what you practiced
   - Time invested (3 hours)
   - Detailed gains breakdown
   - Resources consumed breakdown

#### Message Improvements
- Changed from enthusiastic ("Practiced songwriting techniques!")
- To realistic ("You refined your songwriting techniques through focused practice.")
- Emphasizes that gains come "little by little" in the UI text

## Game Balance Impact

### Before Update
- Players could max out skills very quickly
- No monetary investment needed
- Practice was essentially "free" except for energy

### After Update
- **Slower progression**: Takes many more sessions to improve
- **Resource management**: Players must balance money and energy
- **Strategic decisions**: Is it worth $50 to practice right now?
- **More realistic**: Small, consistent gains over time
- **Fame is earned**: Can't just practice to become famous

## Example Progression

### To go from Skill 10 → 50:
- **Before**: ~4-5 practice sessions
- **After**: ~15-20 practice sessions
- **Cost**: ~$1,000 and 300+ energy total

This makes the journey to mastery much more meaningful!

## Future Enhancements
- Integrate time system (3 hours advances game clock)
- Add quality bonuses based on current skill level
- Practice type combos (e.g., songwriting + lyrics bonus)
- Practice fatigue system (diminishing returns)
- Master classes (expensive but higher gains)

## Testing Recommendations
1. Start new game, practice several times
2. Verify money decreases by $50 each time
3. Check skill gains are 1-6 points
4. Confirm creativity only goes up by 1
5. Watch for occasional fan gains (not every time)
