import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crew.dart';

/// Service for crew leaderboards and rankings
class CrewLeaderboardService {
  static final CrewLeaderboardService _instance =
      CrewLeaderboardService._internal();
  factory CrewLeaderboardService() => _instance;
  CrewLeaderboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get top crews by total streams
  Future<List<Crew>> getTopCrewsByStreams({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('crews')
          .where('status', isEqualTo: 'active')
          .orderBy('totalStreams', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Crew.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting top crews by streams: $e');
      return [];
    }
  }

  /// Get top crews by total revenue
  Future<List<Crew>> getTopCrewsByRevenue({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('crews')
          .where('status', isEqualTo: 'active')
          .orderBy('totalEarnings', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Crew.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting top crews by revenue: $e');
      return [];
    }
  }

  /// Get top crews by total songs released
  Future<List<Crew>> getTopCrewsBySongs({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('crews')
          .where('status', isEqualTo: 'active')
          .orderBy('totalSongsReleased', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Crew.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting top crews by songs: $e');
      return [];
    }
  }

  /// Get crew rank by specific metric
  Future<int> getCrewRank({
    required String crewId,
    required String metric, // 'totalStreams', 'totalRevenue', 'totalSongs'
  }) async {
    try {
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return 0;

      final crew = Crew.fromJson(crewDoc.data()!);
      int crewValue;

      switch (metric) {
        case 'totalStreams':
          crewValue = crew.totalStreams;
          break;
        case 'totalEarnings':
          crewValue = crew.totalEarnings;
          break;
        case 'totalSongsReleased':
          crewValue = crew.totalSongsReleased;
          break;
        default:
          return 0;
      }

      // Count crews with higher value
      final snapshot = await _firestore
          .collection('crews')
          .where('status', isEqualTo: 'active')
          .where(metric, isGreaterThan: crewValue)
          .get();

      return snapshot.docs.length + 1; // Rank is count + 1
    } catch (e) {
      print('Error getting crew rank: $e');
      return 0;
    }
  }

  /// Get total active crews count
  Future<int> getTotalActiveCrews() async {
    try {
      final snapshot = await _firestore
          .collection('crews')
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting total crews: $e');
      return 0;
    }
  }

  /// Calculate crew growth percentage (last 7 days)
  Future<Map<String, double>> getCrewGrowth(String crewId) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Get crew songs released in last 7 days
      final recentSongsSnapshot = await _firestore
          .collection('crew_songs')
          .where('crewId', isEqualTo: crewId)
          .where('status', isEqualTo: 'released')
          .where('releasedAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      // Get all crew songs
      final allSongsSnapshot = await _firestore
          .collection('crew_songs')
          .where('crewId', isEqualTo: crewId)
          .where('status', isEqualTo: 'released')
          .get();

      final recentCount = recentSongsSnapshot.docs.length;
      final totalCount = allSongsSnapshot.docs.length;
      final oldCount = totalCount - recentCount;

      final growthPercentage = oldCount > 0
          ? ((recentCount / oldCount) * 100)
          : (recentCount > 0 ? 100.0 : 0.0);

      return {
        'songGrowth': growthPercentage,
        'recentSongs': recentCount.toDouble(),
        'totalSongs': totalCount.toDouble(),
      };
    } catch (e) {
      print('Error calculating crew growth: $e');
      return {'songGrowth': 0.0, 'recentSongs': 0.0, 'totalSongs': 0.0};
    }
  }

  /// Get crew analytics summary
  Future<Map<String, dynamic>> getCrewAnalytics(String crewId) async {
    try {
      final crew = await _firestore.collection('crews').doc(crewId).get();
      if (!crew.exists) return {};

      final crewData = Crew.fromJson(crew.data()!);

      // Get ranks
      final streamRank = await getCrewRank(
        crewId: crewId,
        metric: 'totalStreams',
      );
      final revenueRank = await getCrewRank(
        crewId: crewId,
        metric: 'totalEarnings',
      );
      final songsRank = await getCrewRank(
        crewId: crewId,
        metric: 'totalSongsReleased',
      );

      // Get growth
      final growth = await getCrewGrowth(crewId);

      // Get total crews for percentile calculation
      final totalCrews = await getTotalActiveCrews();

      return {
        'crew': crewData,
        'ranks': {
          'streams': streamRank,
          'revenue': revenueRank,
          'songs': songsRank,
        },
        'percentiles': {
          'streams': totalCrews > 0
              ? ((totalCrews - streamRank) / totalCrews * 100).round()
              : 0,
          'revenue': totalCrews > 0
              ? ((totalCrews - revenueRank) / totalCrews * 100).round()
              : 0,
          'songs': totalCrews > 0
              ? ((totalCrews - songsRank) / totalCrews * 100).round()
              : 0,
        },
        'growth': growth,
        'totalCrews': totalCrews,
      };
    } catch (e) {
      print('Error getting crew analytics: $e');
      return {};
    }
  }

  /// Stream top crews by metric with real-time updates
  Stream<List<Crew>> streamTopCrews({
    required String metric,
    int limit = 10,
  }) {
    try {
      return _firestore
          .collection('crews')
          .where('status', isEqualTo: 'active')
          .orderBy(metric, descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Crew.fromJson(doc.data())).toList());
    } catch (e) {
      print('Error streaming top crews: $e');
      return Stream.value([]);
    }
  }

  /// Get crew comparison data
  Future<Map<String, dynamic>> compareCrews(
    String crewId1,
    String crewId2,
  ) async {
    try {
      final crew1Doc = await _firestore.collection('crews').doc(crewId1).get();
      final crew2Doc = await _firestore.collection('crews').doc(crewId2).get();

      if (!crew1Doc.exists || !crew2Doc.exists) {
        return {'error': 'One or both crews not found'};
      }

      final crew1 = Crew.fromJson(crew1Doc.data()!);
      final crew2 = Crew.fromJson(crew2Doc.data()!);

      return {
        'crew1': {
          'name': crew1.name,
          'totalStreams': crew1.totalStreams,
          'totalEarnings': crew1.totalEarnings,
          'totalSongs': crew1.totalSongsReleased,
          'memberCount': crew1.members.length,
        },
        'crew2': {
          'name': crew2.name,
          'totalStreams': crew2.totalStreams,
          'totalEarnings': crew2.totalEarnings,
          'totalSongs': crew2.totalSongsReleased,
          'memberCount': crew2.members.length,
        },
        'winner': {
          'streams':
              crew1.totalStreams > crew2.totalStreams ? crew1.name : crew2.name,
          'earnings': crew1.totalEarnings > crew2.totalEarnings
              ? crew1.name
              : crew2.name,
          'songs': crew1.totalSongsReleased > crew2.totalSongsReleased
              ? crew1.name
              : crew2.name,
        },
      };
    } catch (e) {
      print('Error comparing crews: $e');
      return {'error': e.toString()};
    }
  }

  /// Get nearby crews (crews with similar stats)
  Future<List<Crew>> getNearbyCrews({
    required String crewId,
    int limit = 5,
  }) async {
    try {
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return [];

      final crew = Crew.fromJson(crewDoc.data()!);
      final targetStreams = crew.totalStreams;

      // Get crews with similar stream counts (±20%)
      final lowerBound = (targetStreams * 0.8).round();
      final upperBound = (targetStreams * 1.2).round();

      final snapshot = await _firestore
          .collection('crews')
          .where('status', isEqualTo: 'active')
          .where('totalStreams', isGreaterThanOrEqualTo: lowerBound)
          .where('totalStreams', isLessThanOrEqualTo: upperBound)
          .limit(limit + 1) // +1 to exclude self
          .get();

      return snapshot.docs
          .map((doc) => Crew.fromJson(doc.data()))
          .where((c) => c.id != crewId) // Exclude self
          .take(limit)
          .toList();
    } catch (e) {
      print('Error getting nearby crews: $e');
      return [];
    }
  }
}
