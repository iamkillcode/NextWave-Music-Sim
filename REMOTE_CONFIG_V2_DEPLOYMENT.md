# NextWave Remote Config v2.0 - Deployment Guide

## Overview
This guide covers deploying the comprehensive game balance Remote Config parameters to your Firebase project.

## New Parameters Added (v2.0)

### Economy & Costs
- `min_song_cost`, `max_song_cost` - Song creation cost range
- `album_release_cost_multiplier` - Album cost scaling
- `practice_cost_per_session` - Practice session pricing
- `collaboration_cost_multiplier` - Collaboration cost scaling
- `marketing_campaign_base_cost`, `marketing_cost_per_fan_reach` - Marketing system

### Streaming & Charts
- `base_daily_streams` - Initial streams for new releases
- `viral_threshold` - Streams needed to go viral
- `chart_position_multiplier` - Chart ranking impact
- `streams_decay_rate` - Daily stream decay
- `chart_bonus_top10/50/100` - Position-based multipliers
- `regional_streaming_multiplier` - Regional market adjustments

### Fame System
- `fame_per_stream/chart_entry/certification` - Fame gain rates
- `fame_decay_rate` - Fame loss over time
- `loyal_fan_conversion_rate` - Fan loyalty mechanics
- `viral_fame_multiplier` - Viral content fame boost

### NPC Competition
- `npc_competition_multiplier` - Overall NPC difficulty
- `npc_max_daily_releases` - NPC release frequency cap
- `npc_quality_min/max` - NPC content quality range
- `npc_fanbase_growth_rate` - NPC fan acquisition
- `npc_chart_advantage` - NPC chart competitiveness
- `npc_streaming_multiplier` - NPC streaming performance
- `npc_release_frequency_days` - Days between NPC releases

### Side Hustles
- `sideHustle_enabled` - Feature toggle
- `sideHustle_daily_generation_count` - Daily opportunities
- `sideHustle_min/max_reward` - Reward ranges
- `sideHustle_energy_cost_min/max` - Energy requirements
- `sideHustle_fame_reward_min/max` - Fame rewards
- `sideHustle_cooldown_hours` - Cooldown period

### Quality & Skills
- `quality_practice_improvement_rate` - Practice effectiveness
- `quality_decay_rate` - Quality loss over time
- `skill_level_up_threshold_multiplier` - Skill progression curve
- `recording/production/writing_quality_impact` - Skill weights

### Special Events
- `specialEvents_enabled` - Feature toggle
- `specialEvent_frequency_hours` - How often events occur
- `specialEvent_duration_hours` - Event duration
- `specialEvent_reward_multiplier` - Event reward scaling
- `specialEvent_chart_boost` - Event chart impact

### Leaderboards
- `leaderboard_enabled` - Feature toggle
- `leaderboard_top_reward_money/fame` - Winner rewards
- `leaderboard_update_frequency_hours` - Update schedule
- `rival_system_enabled` - Rival notifications
- `rival_notification_threshold` - Rival proximity alert

### EchoX Social
- `echoX_enabled` - Feature toggle
- `echoX_post_fame_reward` - Fame per post
- `echoX_viral_threshold` - Engagement for viral status
- `echoX_viral_multiplier` - Viral content boost
- `echoX_engagement_rate_base` - Base engagement rate

### Difficulty Presets
- `difficulty_preset` - Currently active preset (balanced/easy/hard)
- `easy_mode_multipliers` - Easy mode resource multipliers
- `hard_mode_multipliers` - Hard mode resource multipliers

## Pre-Deployment Checklist

1. **Backup Current Config**
   ```powershell
   firebase remoteconfig:get -o remote_config_backup.json --project nextwave-music-sim
   ```

2. **Review Parameter Defaults**
   - Check all new parameters have sensible default values
   - Verify multipliers are balanced (1.0 = neutral)
   - Ensure feature flags match your deployment status

3. **Test Locally** (if possible)
   - Use Firebase Local Emulator to test config
   - Verify app handles all new parameters

## Deployment Steps

### Method 1: Firebase Console (Recommended for First Deployment)

1. Go to Firebase Console → Remote Config
2. Click "Add parameter" for each new parameter
3. Set default values from `remote_config_v2.json`
4. Add parameter descriptions for maintainability
5. Click "Publish changes"

### Method 2: Firebase CLI (Automated)

```powershell
# Deploy all parameters at once
firebase remoteconfig:set remote_config_v2.json --project nextwave-music-sim

# Verify deployment
firebase remoteconfig:get --project nextwave-music-sim
```

### Method 3: Gradual Rollout (Safest)

Deploy parameters in stages:

**Stage 1: Economy & Streaming** (Low Risk)
```json
{
  "min_song_cost": 50,
  "max_song_cost": 500,
  "base_streaming_rate": 0.005,
  "base_daily_streams": 100,
  "viral_threshold": 10000
}
```

**Stage 2: NPC & Competition** (Medium Risk)
```json
{
  "npc_competition_multiplier": 1.0,
  "npc_max_daily_releases": 3,
  "npc_quality_min": 40,
  "npc_quality_max": 85
}
```

**Stage 3: New Features** (High Risk - Test First)
```json
{
  "sideHustle_enabled": true,
  "specialEvents_enabled": true,
  "echoX_enabled": true
}
```

## Post-Deployment Validation

1. **Check Firebase Console**
   - Verify all parameters published
   - Check for any validation errors

2. **Monitor App Behavior**
   ```powershell
   # Watch for errors
   firebase functions:log --project nextwave-music-sim
   ```

3. **Test Key Flows**
   - Create a song → verify costs and energy
   - Check streaming → verify rates and multipliers
   - Test NPC behavior → verify competition levels

4. **Monitor Analytics**
   - Track user progression rates
   - Monitor economy inflation/deflation
   - Check for balance issues

## Rollback Procedure

If issues detected:

```powershell
# Restore backup
firebase remoteconfig:set remote_config_backup.json --project nextwave-music-sim
```

Or adjust specific parameters in Firebase Console.

## Parameter Tuning Guide

### Making the Game Easier
- Increase: `daily_starting_money`, `daily_energy`, `base_streaming_rate`
- Decrease: `min_song_cost`, `energy_per_song`, `npc_competition_multiplier`
- Set `difficulty_preset`: "easy"

### Making the Game Harder
- Decrease: `daily_starting_money`, `base_streaming_rate`, `fame_per_stream`
- Increase: `energy_per_song`, `npc_competition_multiplier`, `streams_decay_rate`
- Set `difficulty_preset`: "hard"

### Balancing NPC Competition
- Too Easy? Increase: `npc_quality_max`, `npc_chart_advantage`, `npc_fanbase_growth_rate`
- Too Hard? Decrease: `npc_max_daily_releases`, `npc_competition_multiplier`

### Economy Balancing
- Inflation? Decrease: `base_streaming_rate`, `marketing_campaign_base_cost`
- Deflation? Increase: `daily_starting_money`, rewards across all systems

## A/B Testing Strategy

Use Remote Config conditions for testing:

1. **Test Group**: 10% of users
   - `npc_competition_multiplier`: 1.2 (harder)
   
2. **Control Group**: 90% of users
   - `npc_competition_multiplier`: 1.0 (baseline)

Monitor retention and engagement metrics.

## Maintenance Schedule

- **Weekly**: Review analytics, adjust economic parameters
- **Monthly**: Evaluate feature flags, enable new systems gradually
- **Quarterly**: Major balance passes based on player data

## Support

If you encounter issues:
1. Check Firebase Console for parameter validation errors
2. Review Cloud Functions logs for runtime issues
3. Test with Firebase Local Emulator before production changes
4. Document all parameter changes for rollback reference

---

**Version**: 2.0.0  
**Last Updated**: 2025-10-27  
**Status**: Ready for deployment
