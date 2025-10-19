import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Service for managing Firebase Remote Config
/// Allows real-time configuration changes without app updates
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  /// Initialize Remote Config with default values
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configure settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            const Duration(hours: 1), // Fetch at most once per hour
      ));

      // Set default values (used if remote fetch fails)
      await _remoteConfig.setDefaults({
        // App version control
        'min_required_version': '1.0.0',
        'recommended_version': '1.0.0',
        'force_update': false,
        'maintenance_mode': false,
        'maintenance_message':
            'NextWave is currently under maintenance. Please check back soon!',

        // Feature flags
        'feature_collaboration_enabled': false,
        'feature_producers_enabled': false,
        'feature_labels_enabled': false,
        'feature_concerts_enabled': false,
        'feature_merchandise_enabled': false,

        // Game balance - Economy
        'min_song_cost': 50,
        'max_song_cost': 500,
        'daily_starting_money': 100,
        'daily_energy': 100,
        'energy_per_song': 10,
        'base_streaming_rate': 0.005, // $ per stream

        // Game balance - Fame & Growth
        'fame_unlock_threshold': 50,
        'base_daily_streams': 100,
        'viral_threshold': 10000, // Streams for viral boost
        'chart_position_multiplier': 1.5,

        // Platform settings
        'tunify_royalty_rate': 0.004,
        'maple_royalty_rate': 0.006,
        'tunify_unlock_fame': 0,
        'maple_unlock_fame': 50,

        // Chart update intervals (hours)
        'daily_chart_update_hours': 24,
        'weekly_chart_update_hours': 168,

        // NPC difficulty
        'npc_competition_multiplier': 1.0,
        'npc_max_daily_releases': 3,

        // Debug & Testing
        'enable_debug_mode': false,
        'enable_analytics': true,
        'show_beta_features': false,
      });

      // Fetch and activate config
      await _remoteConfig.fetchAndActivate();
      _initialized = true;

      print('✅ Remote Config initialized successfully');
    } catch (e) {
      print('❌ Remote Config initialization failed: $e');
      // App will use default values
    }
  }

  /// Manually refresh config (call sparingly due to rate limits)
  Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      print('✅ Remote Config refreshed');
    } catch (e) {
      print('❌ Remote Config refresh failed: $e');
    }
  }

  // =============================================================================
  // SAFE GETTERS (with fallbacks)
  // =============================================================================

  /// Safe get boolean with fallback
  bool _getBool(String key, {bool defaultValue = false}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Safe get int with fallback
  int _getInt(String key, {int defaultValue = 0}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Safe get double with fallback
  double _getDouble(String key, {double defaultValue = 0.0}) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      return defaultValue;
    }
  }

  /// Safe get string with fallback
  String _getString(String key, {String defaultValue = ''}) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      return defaultValue;
    }
  }

  // =============================================================================
  // APP VERSION & MAINTENANCE
  // =============================================================================

  String get minRequiredVersion =>
      _getString('min_required_version', defaultValue: '1.0.0');
  String get recommendedVersion =>
      _getString('recommended_version', defaultValue: '1.0.0');
  bool get forceUpdate => _getBool('force_update');
  bool get isMaintenanceMode => _getBool('maintenance_mode');
  String get maintenanceMessage => _getString('maintenance_message',
      defaultValue:
          'NextWave is currently under maintenance. Please check back soon!');

  // =============================================================================
  // FEATURE FLAGS
  // =============================================================================

  bool get isCollaborationEnabled => _getBool('feature_collaboration_enabled');
  bool get isProducersEnabled => _getBool('feature_producers_enabled');
  bool get isLabelsEnabled => _getBool('feature_labels_enabled');
  bool get isConcertsEnabled => _getBool('feature_concerts_enabled');
  bool get isMerchandiseEnabled => _getBool('feature_merchandise_enabled');

  // =============================================================================
  // GAME BALANCE - ECONOMY
  // =============================================================================

  int get minSongCost => _getInt('min_song_cost', defaultValue: 50);
  int get maxSongCost => _getInt('max_song_cost', defaultValue: 500);
  int get dailyStartingMoney =>
      _getInt('daily_starting_money', defaultValue: 100);
  int get dailyEnergy => _getInt('daily_energy', defaultValue: 100);
  int get energyPerSong => _getInt('energy_per_song', defaultValue: 10);
  double get baseStreamingRate =>
      _getDouble('base_streaming_rate', defaultValue: 0.005);

  // =============================================================================
  // GAME BALANCE - FAME & GROWTH
  // =============================================================================

  int get fameUnlockThreshold =>
      _getInt('fame_unlock_threshold', defaultValue: 50);
  int get baseDailyStreams => _getInt('base_daily_streams', defaultValue: 100);
  int get viralThreshold => _getInt('viral_threshold', defaultValue: 10000);
  double get chartPositionMultiplier =>
      _getDouble('chart_position_multiplier', defaultValue: 1.5);

  // =============================================================================
  // PLATFORM SETTINGS
  // =============================================================================

  double get tunifyRoyaltyRate =>
      _getDouble('tunify_royalty_rate', defaultValue: 0.004);
  double get mapleRoyaltyRate =>
      _getDouble('maple_royalty_rate', defaultValue: 0.006);
  int get tunifyUnlockFame => _getInt('tunify_unlock_fame');
  int get mapleUnlockFame => _getInt('maple_unlock_fame', defaultValue: 50);

  // =============================================================================
  // CHART SETTINGS
  // =============================================================================

  int get dailyChartUpdateHours =>
      _getInt('daily_chart_update_hours', defaultValue: 24);
  int get weeklyChartUpdateHours =>
      _getInt('weekly_chart_update_hours', defaultValue: 168);

  // =============================================================================
  // NPC DIFFICULTY
  // =============================================================================

  double get npcCompetitionMultiplier =>
      _getDouble('npc_competition_multiplier', defaultValue: 1.0);
  int get npcMaxDailyReleases =>
      _getInt('npc_max_daily_releases', defaultValue: 3);

  // =============================================================================
  // DEBUG & TESTING
  // =============================================================================

  bool get enableDebugMode => _getBool('enable_debug_mode');
  bool get enableAnalytics => _getBool('enable_analytics', defaultValue: true);
  bool get showBetaFeatures => _getBool('show_beta_features');

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Check if current app version meets minimum requirement
  bool isVersionSupported(String currentVersion) {
    return _compareVersions(currentVersion, minRequiredVersion) >= 0;
  }

  /// Check if update is recommended
  bool isUpdateRecommended(String currentVersion) {
    return _compareVersions(currentVersion, recommendedVersion) < 0;
  }

  /// Compare two version strings (e.g., "1.2.3")
  /// Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map(int.parse).toList();
    final v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }
    return 0;
  }

  /// Get all config values as a map (for debug screen)
  Map<String, dynamic> getAllValues() {
    final keys = _remoteConfig.getAll().keys;
    return {for (var key in keys) key: _remoteConfig.getValue(key).asString()};
  }
}
