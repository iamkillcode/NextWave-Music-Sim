import 'dart:math';
import '../models/song.dart';
import '../models/artist_stats.dart';

/// Dynamic stream growth system that calculates realistic, varied stream increases
/// for each song based on multiple factors including quality, virality, artist stats, and time
///
/// **NEW:** Now supports regional distribution of streams based on:
/// - Current region (where artist is located)
/// - Regional fanbase (fans per region)
/// - Genre preferences per region
/// - Global vs regional appeal
class StreamGrowthService {
  final Random _random = Random();
  // Safety cap for any stream/fan calculations to avoid Infinity -> toInt() errors
  static const double _maxStreamBound = 1e12; // 1 trillion streams is effectively unlimited

  /// All supported regions
  static const List<String> regions = [
    'usa',
    'europe',
    'uk',
    'asia',
    'africa',
    'latin_america',
    'oceania',
  ];

  /// Genre preferences per region (multiplier: 0.5 to 1.5)
  static const Map<String, Map<String, double>> regionalGenrePreferences = {
    'usa': {
      'Hip Hop': 1.5,
      'Rap': 1.4,
      'R&B': 1.3,
      'Trap': 1.2,
      'Country': 1.3,
      'Jazz': 1.1,
    },
    'europe': {'Hip Hop': 1.0, 'R&B': 1.1, 'Jazz': 1.2, 'Reggae': 0.9},
    'uk': {'Drill': 1.5, 'Hip Hop': 1.2, 'Rap': 1.3, 'R&B': 1.1},
    'asia': {'Hip Hop': 0.9, 'R&B': 1.0, 'Jazz': 1.1},
    'africa': {'Afrobeat': 1.5, 'Hip Hop': 1.1, 'R&B': 1.2, 'Reggae': 1.3},
    'latin_america': {'Hip Hop': 1.0, 'R&B': 0.9, 'Reggae': 1.3},
    'oceania': {'Hip Hop': 1.0, 'Country': 1.1, 'R&B': 0.9},
  };

  /// Calculate stream growth for a single song for one game day
  /// Returns the number of new streams to add
  int calculateDailyStreamGrowth({
    required Song song,
    required ArtistStats artistStats,
    required DateTime currentGameDate,
  }) {
    if (song.state != SongState.released || song.releasedDate == null) {
      return 0;
    }

    // Calculate days since release
    final daysSinceRelease =
        currentGameDate.difference(song.releasedDate!).inDays;

    // Base streams from loyal fanbase (they always stream)
    final loyalStreams = _calculateLoyalFanStreams(artistStats.loyalFanbase);

    // Discovery streams (new listeners finding the song)
    final discoveryStreams = _calculateDiscoveryStreams(
      song: song,
      artistStats: artistStats,
      daysSinceRelease: daysSinceRelease,
    );

    // Viral streams (random spikes based on virality)
    final viralStreams = _calculateViralStreams(
      song: song,
      daysSinceRelease: daysSinceRelease,
    );

    // Casual listener streams (from general fanbase)
    final casualStreams = _calculateCasualFanStreams(
      artistStats: artistStats,
      songQuality: song.finalQuality,
    );

    // Apply platform multipliers
    final tunifyStreams =
        (loyalStreams + discoveryStreams + viralStreams + casualStreams) * 0.85;
    final mapleStreams =
        (loyalStreams + discoveryStreams + viralStreams + casualStreams) * 0.65;

    // Total streams (some users are on both platforms)
    var totalDailyStreams = (tunifyStreams + mapleStreams * 0.4).round();

    // 🎸 GENRE MASTERY BONUS - Higher mastery = More streams!
    // Mastered genres get recommended more by algorithms
    // 0% mastery = 1.0x (no bonus)
    // 50% mastery = 1.2x (+20% streams)
    // 100% mastery = 1.5x (+50% streams boost!)
    final genreMastery = artistStats.genreMastery[song.genre] ?? 0;
    final masteryStreamBonus = 1.0 + (genreMastery / 100.0 * 0.5);
    totalDailyStreams = (totalDailyStreams * masteryStreamBonus).round();

    // Add randomness (±20% variance)
    final variance = 0.8 + (_random.nextDouble() * 0.4);
    var finalStreams = (totalDailyStreams * variance).round();

    // 🔥 FIX: Guarantee minimum streams for released songs
    // Even with 0 fans, songs should get SOME organic discovery
    // Quality-based minimum: 50-500 streams per day for new artists
    if (finalStreams < 50) {
      final qualityBonus =
          (song.finalQuality / 100 * 450).round(); // 0-450 based on quality
      final minimumStreams = 50 + qualityBonus; // 50-500 range
      finalStreams = minimumStreams;
    }

  // Safely clamp to a very large finite upper bound before converting to int
  return finalStreams.clamp(0, _maxStreamBound).toInt();
  }

  /// Calculate regional stream distribution
  ///
  /// Distributes total daily streams across regions based on:
  /// - Current region (50% weight)
  /// - Regional fanbase size (30% weight)
  /// - Genre preference per region (20% weight)
  ///
  /// Returns Map<String, int> of streams per region
  Map<String, int> calculateRegionalStreamDistribution({
    required int totalDailyStreams,
    required String currentRegion,
    required Map<String, int> regionalFanbase,
    required String genre,
    String? originRegion,
  }) {
    if (totalDailyStreams == 0) {
      return {};
    }

    final distribution = <String, int>{};
    final regionWeights = <String, double>{};

    // Calculate total fanbase
    final totalFanbase = regionalFanbase.values.fold(
      0,
      (sum, fans) => sum + fans,
    );

    // If no regional fanbase yet, use simple distribution
    if (totalFanbase == 0) {
      // 70% current region, 30% global
      distribution[currentRegion] = (totalDailyStreams * 0.7).round();
      final globalStreams = (totalDailyStreams * 0.3).round();
      final perRegion = (globalStreams / (regions.length - 1)).round();

      for (var region in regions) {
        if (region != currentRegion) {
          distribution[region] = perRegion;
        }
      }

      return distribution;
    }

    // Calculate weights for each region
    for (var region in regions) {
      double weight = 0.0;

      // 1. Current region bonus (50% weight)
      if (region == currentRegion) {
        weight += 0.5;
      }

      // 2. Origin region bonus (20% weight) - where artist started
      if (originRegion != null && region == originRegion) {
        weight += 0.2;
      }

      // 3. Regional fanbase size (30% weight)
      final regionFans = regionalFanbase[region] ?? 0;
      if (totalFanbase > 0) {
        final fanbaseRatio = regionFans / totalFanbase;
        weight += fanbaseRatio * 0.3;
      }

      // 4. Genre preference multiplier (20% weight)
      final genreMultiplier = _getGenreMultiplierForRegion(genre, region);
      weight *= genreMultiplier;

      regionWeights[region] = weight;
    }

    // Normalize weights to sum to 1.0
    final totalWeight = regionWeights.values.fold(0.0, (sum, w) => sum + w);

    if (totalWeight == 0) {
      // Fallback: equal distribution
      final perRegion = (totalDailyStreams / regions.length).round();
      for (var region in regions) {
        distribution[region] = perRegion;
      }
      return distribution;
    }

    // Distribute streams based on normalized weights
    int remainingStreams = totalDailyStreams;

    for (var region in regions) {
      final normalizedWeight = regionWeights[region]! / totalWeight;
      final regionStreams = (totalDailyStreams * normalizedWeight).round();
      distribution[region] = regionStreams;
      remainingStreams -= regionStreams;
    }

    // Distribute any remaining streams to current region (rounding errors)
    if (remainingStreams > 0) {
      distribution[currentRegion] =
          (distribution[currentRegion] ?? 0) + remainingStreams;
    }

    return distribution;
  }

  /// Get genre preference multiplier for a region (0.8 to 1.5)
  double _getGenreMultiplierForRegion(String genre, String region) {
    final preferences = regionalGenrePreferences[region];
    if (preferences == null) {
      return 1.0; // Neutral
    }

    return preferences[genre] ?? 1.0; // Default to neutral if genre not listed
  }

  /// Calculate regional fanbase growth when releasing a song
  ///
  /// Returns Map<String, int> of new fans per region
  Map<String, int> calculateRegionalFanbaseGrowth({
    required String currentRegion,
    required String genre,
    required int songQuality,
    required int currentGlobalFanbase,
    required Map<String, int> currentRegionalFanbase,
    String? originRegion,
  }) {
    final growth = <String, int>{};

    // Base fan gain from quality (10-100 fans per quality point above 50)
    int baseFanGrowth = 0;
    if (songQuality >= 80) {
      baseFanGrowth = 100 + (songQuality - 80) * 10; // 100-300 fans
    } else if (songQuality >= 60) {
      baseFanGrowth = 50 + (songQuality - 60) * 2; // 50-90 fans
    } else if (songQuality >= 40) {
      baseFanGrowth = 20 + (songQuality - 40) * 1; // 20-40 fans
    } else {
      baseFanGrowth = 10; // Minimal growth for poor quality
    }

    // Distribute fan growth across regions

    // 1. Current region gets 60% of fan growth
    final currentRegionGrowth = (baseFanGrowth * 0.6).round();
    growth[currentRegion] = currentRegionGrowth;

    // 2. Origin region gets 20% (if different from current)
    if (originRegion != null && originRegion != currentRegion) {
      final originGrowth = (baseFanGrowth * 0.2).round();
      growth[originRegion] = originGrowth;
    }

    // 3. Neighboring/related regions get 15% (spillover effect)
    final spilloverGrowth = (baseFanGrowth * 0.15).round();
    final neighboringRegions = _getNeighboringRegions(currentRegion);
    final perNeighbor = neighboringRegions.isNotEmpty
        ? (spilloverGrowth / neighboringRegions.length).round()
        : 0;

    for (var neighbor in neighboringRegions) {
      growth[neighbor] = (growth[neighbor] ?? 0) + perNeighbor;
    }

    // 4. Global distribution (5%) - viral potential
    if (songQuality >= 70) {
      final globalGrowth = (baseFanGrowth * 0.05).round();
      for (var region in regions) {
        if (region != currentRegion &&
            (originRegion == null || region != originRegion) &&
            !neighboringRegions.contains(region)) {
          growth[region] = (growth[region] ?? 0) + (globalGrowth / 3).round();
        }
      }
    }

    return growth;
  }

  /// Get neighboring/related regions for spillover effect
  List<String> _getNeighboringRegions(String region) {
    const neighbors = {
      'usa': ['latin_america'],
      'europe': ['uk', 'africa'],
      'uk': ['europe'],
      'asia': ['oceania'],
      'africa': ['europe'],
      'latin_america': ['usa'],
      'oceania': ['asia'],
    };

    return neighbors[region] ?? [];
  }

  /// Loyal fans stream consistently regardless of song age
  int _calculateLoyalFanStreams(int loyalFanbase) {
    // Each loyal fan streams 0.5-2 times per day
    final streamsPerFan = 0.5 + (_random.nextDouble() * 1.5);
    return (loyalFanbase * streamsPerFan).round();
  }

  /// Discovery streams decrease over time but spike initially
  int _calculateDiscoveryStreams({
    required Song song,
    required ArtistStats artistStats,
    required int daysSinceRelease,
  }) {
    // Release day spike
    if (daysSinceRelease == 0) {
      final releaseHype =
          (artistStats.fanbase * 0.3 * song.finalQuality / 100).round();
      return (releaseHype * (1.5 + _random.nextDouble())).round();
    }

    // Week 1: High discovery (algorithm boost)
    if (daysSinceRelease <= 7) {
      final weekOneDiscovery =
          (artistStats.fanbase * 0.2 * song.viralityScore).round();
      final dayDecay =
          1.0 - (daysSinceRelease / 7.0 * 0.4); // 40% decay over week
      return (weekOneDiscovery * dayDecay).round();
    }

    // Week 2-4: Medium discovery
    if (daysSinceRelease <= 30) {
      final monthOneDiscovery =
          (artistStats.fanbase * 0.1 * song.viralityScore).round();
      final weekDecay =
          1.0 - ((daysSinceRelease - 7) / 23.0 * 0.5); // Further 50% decay
      return (monthOneDiscovery * weekDecay).round();
    }

    // Month 2-3: Low but consistent discovery
    if (daysSinceRelease <= 90) {
      final lateDiscovery =
          (artistStats.fanbase * 0.05 * song.viralityScore).round();
      return (lateDiscovery * (0.5 + _random.nextDouble() * 0.5)).round();
    }

    // After 3 months: Long tail (very low, quality matters more)
    final longTail =
        (artistStats.fanbase * 0.02 * (song.finalQuality / 100)).round();
    return (longTail * (0.3 + _random.nextDouble() * 0.4)).round();
  }

  /// Viral streams - random spikes based on virality score
  int _calculateViralStreams({
    required Song song,
    required int daysSinceRelease,
  }) {
    // Higher virality = higher chance of spikes
    final viralChance = song.viralityScore;

    // Random check for viral moment
    if (_random.nextDouble() < viralChance * 0.1) {
      // Viral spike! (can happen anytime but more likely for high virality)
      final spikeMultiplier =
          2.0 + (_random.nextDouble() * 5.0); // 2x to 7x spike
      final baseViralStreams =
          (song.streams * 0.05).round(); // 5% of current streams
      return (baseViralStreams * spikeMultiplier).round();
    }

    // Most days have no viral spike
    return 0;
  }

  /// Casual fans stream based on song quality and current fame
  int _calculateCasualFanStreams({
    required ArtistStats artistStats,
    required int songQuality,
  }) {
    // Casual fanbase (total - loyal)
  final casualFans = (artistStats.fanbase - artistStats.loyalFanbase)
    .clamp(0, _maxStreamBound)
    .toInt();

    // Only a fraction of casual fans stream on any given day
    final engagementRate =
        (songQuality / 100.0) * 0.2; // Max 20% of casual fans
    final activeListeners = (casualFans * engagementRate).round();

    // Each active listener streams 0.1-0.8 times (less than loyal)
    final streamsPerListener = 0.1 + (_random.nextDouble() * 0.7);

    return (activeListeners * streamsPerListener).round();
  }

  /// Calculate virality score for a new song (0.0 to 1.0)
  /// This is random but influenced by song quality and artist stats
  double calculateViralityScore({
    required int songQuality,
    required int artistFame,
    required int artistFanbase,
  }) {
    // Base virality from quality (0.2 to 0.8 range)
    final qualityFactor = (songQuality / 100.0) * 0.6 + 0.2;

    // Fame influence (0.9 to 1.1 multiplier)
    final fameMultiplier = 0.9 + (artistFame / 1000.0 * 0.2).clamp(0.0, 0.2);

    // Fanbase influence (0.9 to 1.1 multiplier)
    final fanbaseMultiplier =
        0.9 + (artistFanbase / 10000.0 * 0.2).clamp(0.0, 0.2);

    // Random luck factor (0.7 to 1.3 - some songs just hit different!)
    final luckFactor = 0.7 + (_random.nextDouble() * 0.6);

    // Calculate final virality
    final virality =
        qualityFactor * fameMultiplier * fanbaseMultiplier * luckFactor;

    return virality.clamp(0.0, 1.0);
  }

  /// Calculate loyal fanbase growth when releasing quality music
  int calculateLoyalFanbaseGrowth({
    required int currentLoyalFanbase,
    required int songQuality,
    required int totalFanbase,
  }) {
    // High quality songs convert casual fans to loyal fans
    if (songQuality >= 70) {
      // Excellent songs convert 5-10% of the gap
      final gap = totalFanbase - currentLoyalFanbase;
      final conversionRate =
          0.05 + ((songQuality - 70) / 30.0 * 0.05); // 5% to 10%
      final newLoyal = (gap * conversionRate).round();
      return newLoyal;
    } else if (songQuality >= 50) {
      // Good songs convert 2-5%
      final gap = totalFanbase - currentLoyalFanbase;
      final conversionRate =
          0.02 + ((songQuality - 50) / 20.0 * 0.03); // 2% to 5%
      final newLoyal = (gap * conversionRate).round();
      return newLoyal;
    }

    // Poor quality songs don't increase loyalty (might even decrease it)
    if (songQuality < 30) {
      // Lose 1-3% of loyal fanbase due to disappointment
      final lossRate = 0.01 + ((30 - songQuality) / 30.0 * 0.02); // 1% to 3%
      return -(currentLoyalFanbase * lossRate).round();
    }

    return 0; // Average songs don't change loyalty much
  }

  /// Update peak daily streams if current day exceeds it
  int updatePeakDailyStreams(int currentPeak, int todayStreams) {
    return todayStreams > currentPeak ? todayStreams : currentPeak;
  }

  /// Get stream growth multiplier based on platform
  double getPlatformMultiplier(String platform) {
    switch (platform.toLowerCase()) {
      case 'tunify':
        return 0.85; // 85% of potential streams
      case 'maple_music':
      case 'maple music':
        return 0.65; // 65% of potential streams
      default:
        return 0.5;
    }
  }

  /// Calculate if a song should chart based on recent performance
  bool shouldChart({required int dailyStreams, required int artistFanbase}) {
    // Need at least 1% of fanbase streaming daily to chart
    final chartThreshold = (artistFanbase * 0.01).round();
    return dailyStreams >= chartThreshold;
  }

  /// Format stream count for display
  String formatStreams(int streams) {
    if (streams >= 1000000000) {
      return '${(streams / 1000000000).toStringAsFixed(1)}B';
    } else if (streams >= 1000000) {
      return '${(streams / 1000000).toStringAsFixed(1)}M';
    } else if (streams >= 1000) {
      return '${(streams / 1000).toStringAsFixed(1)}K';
    }
    return streams.toString();
  }

  /// Update last 7 days streams by adding today's new streams
  /// Call this whenever you add daily streams to a song
  ///
  /// Returns the updated last7DaysStreams value
  int updateLast7DaysStreams({
    required int currentLast7DaysStreams,
    required int newStreamsToday,
  }) {
    return currentLast7DaysStreams + newStreamsToday;
  }

  /// Decay last 7 days streams - removes approximately 1/7th of the streams
  /// This simulates one day dropping off the 7-day rolling window
  ///
  /// Should be called once per game day for ALL songs
  ///
  /// Returns the decayed last7DaysStreams value
  int decayLast7DaysStreams(int currentLast7DaysStreams) {
    // Keep 6/7ths (85.7%) of the streams - one day drops off
    final decayed = (currentLast7DaysStreams * 0.857).round();
  return decayed.clamp(0, _maxStreamBound).toInt();
  }

  /// Reset daily streams to new value - replaces yesterday's streams
  /// Call this once per game day BEFORE adding new streams
  ///
  /// Returns the reset lastDayStreams value (always 0 at start of new day)
  int resetLastDayStreams() {
    return 0;
  }

  /// Apply stream updates to a song - updates total, daily, and weekly streams
  /// This is the main method you should call when distributing daily streams
  ///
  /// Returns a copyWith map that you can use to update the song
  Map<String, dynamic> applyDailyStreams({
    required Song song,
    required int dailyStreams,
  }) {
    return {
      'streams': song.streams + dailyStreams,
      'lastDayStreams': dailyStreams, // Reset to today's streams only
      'last7DaysStreams': song.last7DaysStreams + dailyStreams,
      'peakDailyStreams': updatePeakDailyStreams(
        song.peakDailyStreams,
        dailyStreams,
      ),
      'daysOnChart': song.daysOnChart +
          (shouldChart(dailyStreams: dailyStreams, artistFanbase: 1000)
              ? 1
              : 0),
    };
  }
}
