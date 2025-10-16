import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified Chart Service - Handles ALL chart types
///
/// Supports:
/// - Time Periods: Daily, Weekly
/// - Content Types: Singles, Albums, Artists
/// - Scope: Global or Per-Region
///
/// Chart Combinations:
/// - Daily Singles (Global/Regional)
/// - Daily Albums (Global/Regional)
/// - Daily Artists (Global/Regional)
/// - Weekly Singles (Global/Regional)
/// - Weekly Albums (Global/Regional)
/// - Weekly Artists (Global/Regional)
class UnifiedChartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Region display names
  static const Map<String, String> regionNames = {
    'usa': 'United States',
    'europe': 'Europe',
    'uk': 'United Kingdom',
    'asia': 'Asia',
    'africa': 'Africa',
    'latin_america': 'Latin America',
    'oceania': 'Oceania',
  };

  /// Region emoji flags
  static const Map<String, String> regionFlags = {
    'usa': '🇺🇸',
    'europe': '🇪🇺',
    'uk': '🇬🇧',
    'asia': '🇯🇵',
    'africa': '🇳🇬',
    'latin_america': '🇧🇷',
    'oceania': '🇦🇺',
  };

  UnifiedChartService();

  /// Get songs chart with flexible filtering
  ///
  /// [period] - 'daily' or 'weekly'
  /// [type] - 'singles' or 'albums'
  /// [region] - Region code or 'global'
  /// [limit] - Number of results (default: 100)
  Future<List<Map<String, dynamic>>> getSongsChart({
    required String period,
    required String type,
    required String region,
    int limit = 100,
  }) async {
    try {
      print('📊 Fetching $period $type chart for $region (limit: $limit)');

      final playersSnapshot = await _firestore
          .collection('players')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Chart query timeout');
            },
          );

      List<Map<String, dynamic>> allSongs = [];

      // Extract all songs from all players
      for (var doc in playersSnapshot.docs) {
        final data = doc.data();
        final artistName = data['displayName'] ?? 'Unknown Artist';
        final songs = data['songs'] as List<dynamic>?;

        if (songs != null) {
          for (var songData in songs) {
            final songMap = Map<String, dynamic>.from(songData);
            final songState = songMap['state'] ?? 'unknown';
            final isAlbum = songMap['isAlbum'] as bool? ?? false;

            // Only include released songs
            if (songState != 'released') continue;

            // Filter by type (singles vs albums)
            if (type == 'singles' && isAlbum) continue;
            if (type == 'albums' && !isAlbum) continue;

            // Get appropriate stream count based on period
            int streamCount = 0;
            if (period == 'daily') {
              streamCount = songMap['lastDayStreams'] as int? ?? 0;
            } else if (period == 'weekly') {
              streamCount = songMap['last7DaysStreams'] as int? ?? 0;
            }

            // Handle regional vs global
            if (region != 'global') {
              // Regional chart - use regional streams
              final regionalStreams =
                  songMap['regionalStreams'] as Map<dynamic, dynamic>?;
              if (regionalStreams != null &&
                  regionalStreams.containsKey(region)) {
                // For regional charts, we need to calculate regional daily/weekly streams
                // For now, use a proportional estimate based on total
                final totalStreams = songMap['totalStreams'] ?? 0;
                final regionStreams =
                    (regionalStreams[region] as num?)?.toInt() ?? 0;

                if (regionStreams > 0 && totalStreams > 0) {
                  // Calculate regional proportion of recent streams
                  final regionProportion = regionStreams / totalStreams;
                  streamCount = (streamCount * regionProportion).round();
                }
              } else {
                streamCount = 0; // No streams in this region
              }
            }

            // Only include songs with streams in the period
            if (streamCount > 0) {
              allSongs.add({
                'title': songMap['title'] ?? 'Untitled',
                'artist': artistName,
                'artistId': doc.id,
                'genre': songMap['genre'] ?? 'Unknown',
                'quality': songMap['quality'] ?? 0,
                'periodStreams': streamCount,
                'totalStreams': songMap['totalStreams'] ?? 0,
                'likes': songMap['likes'] ?? 0,
                'releaseDate': songMap['releaseDate'],
                'state': songState,
                'isAlbum': isAlbum,
                'coverArtUrl': songMap['coverArtUrl'],
              });
            }
          }
        }
      }

      // Sort by period streams (descending)
      allSongs.sort(
        (a, b) =>
            (b['periodStreams'] as int).compareTo(a['periodStreams'] as int),
      );

      final topSongs = allSongs.take(limit).toList();
      print('✅ Found ${topSongs.length} songs on $period $type $region chart');

      return topSongs;
    } catch (e) {
      print('❌ Error fetching songs chart: $e');
      return [];
    }
  }

  /// Get artists chart - ranks artists by various metrics
  ///
  /// [period] - 'daily' or 'weekly' (affects stream calculation)
  /// [region] - Region code or 'global'
  /// [limit] - Number of results (default: 100)
  /// [sortBy] - 'streams', 'songs', or 'fanbase' (default: 'streams')
  Future<List<Map<String, dynamic>>> getArtistsChart({
    required String period,
    required String region,
    int limit = 100,
    String sortBy = 'streams',
  }) async {
    try {
      print(
        '📊 Fetching $period artists chart for $region (sort: $sortBy, limit: $limit)',
      );

      final playersSnapshot = await _firestore
          .collection('players')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Artists chart query timeout');
            },
          );

      List<Map<String, dynamic>> allArtists = [];

      for (var doc in playersSnapshot.docs) {
        final data = doc.data();
        final artistName = data['displayName'] ?? 'Unknown Artist';
        final songs = data['songs'] as List<dynamic>?;
        final fanbase = data['fanbase'] ?? 0;
        final fame = data['fame'] ?? 0;
        final avatarUrl = data['avatarUrl'];

        if (songs == null || songs.isEmpty) continue;

        int totalPeriodStreams = 0;
        int releasedSongsCount = 0;
        int chartingSongsCount = 0;

        // Calculate artist metrics
        for (var songData in songs) {
          final songMap = Map<String, dynamic>.from(songData);
          final songState = songMap['state'] ?? 'unknown';

          if (songState == 'released') {
            releasedSongsCount++;

            // Get period streams
            int songPeriodStreams = 0;
            if (period == 'daily') {
              songPeriodStreams = songMap['lastDayStreams'] as int? ?? 0;
            } else if (period == 'weekly') {
              songPeriodStreams = songMap['last7DaysStreams'] as int? ?? 0;
            }

            // Handle regional filtering
            if (region != 'global') {
              final regionalStreams =
                  songMap['regionalStreams'] as Map<dynamic, dynamic>?;
              if (regionalStreams != null &&
                  regionalStreams.containsKey(region)) {
                final totalStreams = songMap['totalStreams'] ?? 0;
                final regionStreams =
                    (regionalStreams[region] as num?)?.toInt() ?? 0;

                if (regionStreams > 0 && totalStreams > 0) {
                  final regionProportion = regionStreams / totalStreams;
                  songPeriodStreams = (songPeriodStreams * regionProportion)
                      .round();
                }
              } else {
                songPeriodStreams = 0;
              }
            }

            totalPeriodStreams += songPeriodStreams;

            if (songPeriodStreams > 0) {
              chartingSongsCount++;
            }
          }
        }

        // Only include artists with activity in the period
        if (totalPeriodStreams > 0 || releasedSongsCount > 0) {
          allArtists.add({
            'artistName': artistName,
            'artistId': doc.id,
            'periodStreams': totalPeriodStreams,
            'fanbase': fanbase,
            'fame': fame,
            'releasedSongs': releasedSongsCount,
            'chartingSongs': chartingSongsCount,
            'avatarUrl': avatarUrl,
          });
        }
      }

      // Sort by selected metric
      switch (sortBy) {
        case 'songs':
          allArtists.sort(
            (a, b) => (b['releasedSongs'] as int).compareTo(
              a['releasedSongs'] as int,
            ),
          );
          break;
        case 'fanbase':
          allArtists.sort(
            (a, b) => (b['fanbase'] as int).compareTo(a['fanbase'] as int),
          );
          break;
        case 'streams':
        default:
          allArtists.sort(
            (a, b) => (b['periodStreams'] as int).compareTo(
              a['periodStreams'] as int,
            ),
          );
      }

      final topArtists = allArtists.take(limit).toList();
      print('✅ Found ${topArtists.length} artists on $period $region chart');

      return topArtists;
    } catch (e) {
      print('❌ Error fetching artists chart: $e');
      return [];
    }
  }

  /// Get chart position for a specific song
  Future<int?> getSongChartPosition({
    required String songTitle,
    required String artistId,
    required String period,
    required String type,
    required String region,
  }) async {
    try {
      final chart = await getSongsChart(
        period: period,
        type: type,
        region: region,
        limit: 200,
      );

      for (int i = 0; i < chart.length; i++) {
        if (chart[i]['title'] == songTitle &&
            chart[i]['artistId'] == artistId) {
          return i + 1;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting song chart position: $e');
      return null;
    }
  }

  /// Get chart position for a specific artist
  Future<int?> getArtistChartPosition({
    required String artistId,
    required String period,
    required String region,
    String sortBy = 'streams',
  }) async {
    try {
      final chart = await getArtistsChart(
        period: period,
        region: region,
        limit: 200,
        sortBy: sortBy,
      );

      for (int i = 0; i < chart.length; i++) {
        if (chart[i]['artistId'] == artistId) {
          return i + 1;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting artist chart position: $e');
      return null;
    }
  }

  /// Get all chart positions for a song across different regions
  Future<Map<String, int>> getSongRegionalPositions({
    required String songTitle,
    required String artistId,
    required String period,
    required String type,
  }) async {
    final positions = <String, int>{};

    for (var region in regions) {
      final position = await getSongChartPosition(
        songTitle: songTitle,
        artistId: artistId,
        period: period,
        type: type,
        region: region,
      );

      if (position != null && position <= 100) {
        positions[region] = position;
      }
    }

    return positions;
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

  /// Get genre emoji
  String getGenreEmoji(String genre) {
    switch (genre.toLowerCase()) {
      case 'pop':
        return '⭐';
      case 'ballad':
        return '💕';
      case 'edm':
        return '⚡';
      case 'rock':
        return '🤘';
      case 'alternative':
        return '🎸';
      case 'r&b':
        return '🎤';
      case 'hip hop':
        return '🎧';
      case 'rap':
        return '🎯';
      case 'trap':
        return '🔥';
      case 'drill':
        return '💀';
      case 'afrobeat':
        return '🌍';
      case 'country':
        return '🤠';
      case 'jazz':
        return '🎺';
      case 'reggae':
        return '🌴';
      default:
        return '🎵';
    }
  }
}
