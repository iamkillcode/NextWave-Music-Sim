# Firebase Remote Config Setup

## Quick Setup (5 minutes)

### Step 1: Enable Remote Config in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/nextwave-music-sim/)
2. Click **Remote Config** in the left sidebar
3. Click **Create configuration** (if first time)

### Step 2: Add Your First Parameters

Click **Add parameter** and create these for immediate testing:

#### Test Parameter (to verify it's working):
```
Key: maintenance_mode
Default value: false
Description: Enable/disable maintenance mode
```

#### Feature Flag Example:
```
Key: feature_collaboration_enabled
Default value: false
Description: Enable collaboration feature
```

#### Game Balance Example:
```
Key: min_song_cost
Default value: 50
Description: Minimum cost to create a song
```

### Step 3: Publish Changes

1. Click **Publish changes** button (top right)
2. Add description: "Initial Remote Config setup"
3. Click **Publish**

## Available Parameters

The app supports these parameters (see `lib/services/remote_config_service.dart` for full list):

### 🔐 App Control
- `maintenance_mode` (boolean) - Enable maintenance screen
- `maintenance_message` (string) - Custom maintenance message
- `force_update` (boolean) - Require update before using app
- `min_required_version` (string) - Minimum app version allowed
- `recommended_version` (string) - Recommended app version

### 🎮 Feature Flags
- `feature_collaboration_enabled` (boolean)
- `feature_producers_enabled` (boolean)
- `feature_labels_enabled` (boolean)
- `feature_concerts_enabled` (boolean)
- `feature_merchandise_enabled` (boolean)

### 💰 Economy
- `min_song_cost` (number) - Min cost to create song
- `max_song_cost` (number) - Max cost to create song
- `daily_starting_money` (number) - Starting money for new players
- `daily_energy` (number) - Daily energy limit
- `energy_per_song` (number) - Energy cost per song
- `base_streaming_rate` (number) - Base $ per stream

### ⭐ Fame & Growth
- `fame_unlock_threshold` (number) - Fame needed for platform unlock
- `base_daily_streams` (number) - Minimum daily streams
- `viral_threshold` (number) - Streams needed for viral boost
- `chart_position_multiplier` (number) - Bonus multiplier for chart positions

### 📱 Platforms
- `tunify_royalty_rate` (number) - $ per stream on Tunify
- `maple_royalty_rate` (number) - $ per stream on Maple Music
- `tunify_unlock_fame` (number) - Fame to unlock Tunify
- `maple_unlock_fame` (number) - Fame to unlock Maple Music

### 🤖 NPC Difficulty
- `npc_competition_multiplier` (number) - AI difficulty multiplier
- `npc_max_daily_releases` (number) - Max NPC releases per day

### 🐛 Debug
- `enable_debug_mode` (boolean)
- `enable_analytics` (boolean)
- `show_beta_features` (boolean)

## Usage Examples

### Example 1: Enable Maintenance Mode

1. In Firebase Console → Remote Config
2. Find parameter: `maintenance_mode`
3. Change value to: `true`
4. (Optional) Update `maintenance_message`
5. Click **Publish changes**
6. App will show maintenance screen within 1 hour (or after refresh)

### Example 2: Balance Game Economy

Adjust song costs for better progression:

1. Change `min_song_cost` to `25` (was 50)
2. Change `max_song_cost` to `750` (was 500)
3. Change `base_streaming_rate` to `0.01` (was 0.005) - 2x earnings!
4. Publish changes

Players will see new values within 1 hour without app update!

### Example 3: Enable Beta Feature

1. Set `feature_collaboration_enabled` to `true`
2. Publish
3. Collaboration feature becomes available instantly

### Example 4: Force Update

1. Set `min_required_version` to `1.0.1`
2. Set `force_update` to `true`
3. Publish
4. Users on version 1.0.0 will see force update dialog

## Testing Changes

### In-App Debug Screen

Access Remote Config values in app:
1. Go to Settings (or Admin Dashboard if admin)
2. Look for "Remote Config" option
3. See all current values
4. Click refresh icon to manually fetch latest

### Manual Refresh
```dart
import 'package:nextwave/services/remote_config_service.dart';

await RemoteConfigService().refresh();
```

## Best Practices

### ✅ DO:
- Test changes with small user groups first (use conditions in Firebase)
- Document your changes in Firebase Console descriptions
- Keep default values in code matching production values
- Use feature flags for gradual rollouts

### ❌ DON'T:
- Change values too frequently (rate limits apply)
- Use for sensitive data (use Firestore or Cloud Functions)
- Rely solely on Remote Config (always have default values)
- Change critical parameters during peak hours

## Advanced: Conditional Targeting

Firebase Remote Config supports conditions based on:
- App version
- User properties
- Device language
- Random percentile (A/B testing)

**Example: Gradual rollout**
1. Create condition: "10% of users"
2. Set parameter value for condition
3. Monitor impact
4. Increase to 50%, then 100%

## Monitoring

### Check Fetch Status
1. Firebase Console → Remote Config
2. Click **Analytics** tab
3. View:
   - Fetch success rate
   - Active users with config
   - Parameter value distribution

### Debug Logs
In terminal while app running:
```
✅ Remote Config initialized successfully
✅ Remote Config refreshed
```

## Troubleshooting

**Config not updating?**
- Wait full 1 hour (minimum fetch interval)
- Force refresh in debug screen
- Check Firebase Console that changes are published

**App using default values?**
- Check internet connection
- Verify Firebase is initialized
- Look for error logs in console

**Maintenance mode not working?**
- Refresh app or wait for auto-fetch
- Check parameter name is exactly: `maintenance_mode`
- Ensure value is boolean `true` not string `"true"`

## Next Steps

1. ✅ Enable Remote Config in Firebase Console
2. ✅ Add test parameters
3. 🔄 Test maintenance mode toggle
4. 🔄 Try adjusting game balance
5. 🔄 Monitor player response to changes
6. 🚀 Use for beta feature rollouts

---

**Pro Tip:** Use Remote Config for your beta testing! Toggle features on/off instantly based on feedback without rebuilding the app! 🎮
