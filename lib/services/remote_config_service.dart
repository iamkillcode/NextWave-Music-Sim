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
  // APP VERSION & MAINTENANCE
  // =============================================================================

  String get minRequiredVersion =>
      _remoteConfig.getString('min_required_version');
  String get recommendedVersion =>
      _remoteConfig.getString('recommended_version');
  bool get forceUpdate => _remoteConfig.getBool('force_update');
  bool get isMaintenanceMode => _remoteConfig.getBool('maintenance_mode');
  String get maintenanceMessage =>
      _remoteConfig.getString('maintenance_message');

  // =============================================================================
  // FEATURE FLAGS
  // =============================================================================

  bool get isCollaborationEnabled =>
      _remoteConfig.getBool('feature_collaboration_enabled');
  bool get isProducersEnabled =>
      _remoteConfig.getBool('feature_producers_enabled');
  bool get isLabelsEnabled => _remoteConfig.getBool('feature_labels_enabled');
  bool get isConcertsEnabled =>
      _remoteConfig.getBool('feature_concerts_enabled');
  bool get isMerchandiseEnabled =>
      _remoteConfig.getBool('feature_merchandise_enabled');

  // =============================================================================
  // GAME BALANCE - ECONOMY
  // =============================================================================

  int get minSongCost => _remoteConfig.getInt('min_song_cost');
  int get maxSongCost => _remoteConfig.getInt('max_song_cost');
  int get dailyStartingMoney => _remoteConfig.getInt('daily_starting_money');
  int get dailyEnergy => _remoteConfig.getInt('daily_energy');
  int get energyPerSong => _remoteConfig.getInt('energy_per_song');
  double get baseStreamingRate =>
      _remoteConfig.getDouble('base_streaming_rate');

  // =============================================================================
  // GAME BALANCE - FAME & GROWTH
  // =============================================================================

  int get fameUnlockThreshold => _remoteConfig.getInt('fame_unlock_threshold');
  int get baseDailyStreams => _remoteConfig.getInt('base_daily_streams');
  int get viralThreshold => _remoteConfig.getInt('viral_threshold');
  double get chartPositionMultiplier =>
      _remoteConfig.getDouble('chart_position_multiplier');

  // =============================================================================
  // PLATFORM SETTINGS
  // =============================================================================

  double get tunifyRoyaltyRate =>
      _remoteConfig.getDouble('tunify_royalty_rate');
  double get mapleRoyaltyRate => _remoteConfig.getDouble('maple_royalty_rate');
  int get tunifyUnlockFame => _remoteConfig.getInt('tunify_unlock_fame');
  int get mapleUnlockFame => _remoteConfig.getInt('maple_unlock_fame');

  // =============================================================================
  // CHART SETTINGS
  // =============================================================================

  int get dailyChartUpdateHours =>
      _remoteConfig.getInt('daily_chart_update_hours');
  int get weeklyChartUpdateHours =>
      _remoteConfig.getInt('weekly_chart_update_hours');

  // =============================================================================
  // NPC DIFFICULTY
  // =============================================================================

  double get npcCompetitionMultiplier =>
      _remoteConfig.getDouble('npc_competition_multiplier');
  int get npcMaxDailyReleases => _remoteConfig.getInt('npc_max_daily_releases');

  // =============================================================================
  // DEBUG & TESTING
  // =============================================================================

  bool get enableDebugMode => _remoteConfig.getBool('enable_debug_mode');
  bool get enableAnalytics => _remoteConfig.getBool('enable_analytics');
  bool get showBetaFeatures => _remoteConfig.getBool('show_beta_features');

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
    return {for (var key in keys)