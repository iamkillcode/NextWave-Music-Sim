import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/beef.dart';

/// Service for managing beefs/rivalries between artists
class BeefService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Start a beef with another artist
  Future<Map<String, dynamic>> startBeef({
    required String targetId,
    required String dissTrackId,
    required String dissTrackTitle,
  }) async {
    try {
      final callable = _functions.httpsCallable('startBeef');
      final result = await callable.call({
        'targetId': targetId,
        'dissTrackId': dissTrackId,
        'dissTrackTitle': dissTrackTitle,
      });

      return {
        'success': true,
        'beefId': result.data['beefId'],
        'message': result.data['message'],
        'targetName': result.data['targetName'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Respond to a beef with a diss track
  Future<Map<String, dynamic>> respondToBeef({
    required String beefId,
    required String responseDissTrackId,
    required String responseDissTrackTitle,
  }) async {
    try {
      final callable = _functions.httpsCallable('respondToBeef');
      final result = await callable.call({
        'beefId': beefId,
        'responseDissTrackId': responseDissTrackId,
        'responseDissTrackTitle': responseDissTrackTitle,
      });

      return {
        'success': true,
        'beefId': result.data['beefId'],
        'message': result.data['message'],
        'instigatorName': result.data['instigatorName'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get all active beefs for a user (as instigator or target)
  Stream<List<Beef>> getActiveBeefs(String userId) {
    return _firestore
        .collection('beefs')
        .where('status', isEqualTo: 'active')
        .where('instigatorId', isEqualTo: userId)
        .snapshots()
        .asyncExpand((instigatorSnapshot) {
      return _firestore
          .collection('beefs')
          .where('status', isEqualTo: 'active')
          .where('targetId', isEqualTo: userId)
          .snapshots()
          .map((targetSnapshot) {
        final allBeefs = <Beef>[];

        for (final doc in instigatorSnapshot.docs) {
          try {
            allBeefs.add(Beef.fromJson(doc.data()));
          } catch (e) {
            print('Error parsing beef: $e');
          }
        }

        for (final doc in targetSnapshot.docs) {
          try {
            allBeefs.add(Beef.fromJson(doc.data()));
          } catch (e) {
            print('Error parsing beef: $e');
          }
        }

        // Sort by start date (newest first)
        allBeefs.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        return allBeefs;
      });
    });
  }

  /// Get beef history for a user (resolved beefs only)
  Stream<List<Beef>> getBeefHistory(String userId, {int limit = 20}) {
    return _firestore
        .collection('beefs')
        .where('status', isEqualTo: 'resolved')
        .where('instigatorId', isEqualTo: userId)
        .orderBy('resolvedAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncExpand((instigatorSnapshot) {
      return _firestore
          .collection('beefs')
          .where('status', isEqualTo: 'resolved')
          .where('targetId', isEqualTo: userId)
          .orderBy('resolvedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((targetSnapshot) {
        final allBeefs = <Beef>[];

        for (final doc in instigatorSnapshot.docs) {
          try {
            allBeefs.add(Beef.fromJson(doc.data()));
          } catch (e) {
            print('Error parsing beef: $e');
          }
        }

        for (final doc in targetSnapshot.docs) {
          try {
            allBeefs.add(Beef.fromJson(doc.data()));
          } catch (e) {
            print('Error parsing beef: $e');
          }
        }

        // Sort by resolved date (newest first)
        allBeefs.sort((a, b) {
          if (a.resolvedAt == null && b.resolvedAt == null) return 0;
          if (a.resolvedAt == null) return 1;
          if (b.resolvedAt == null) return -1;
          return b.resolvedAt!.compareTo(a.resolvedAt!);
        });

        return allBeefs.take(limit).toList();
      });
    });
  }

  /// Get a specific beef by ID
  Future<Beef?> getBeef(String beefId) async {
    try {
      final doc = await _firestore.collection('beefs').doc(beefId).get();
      if (!doc.exists) return null;
      return Beef.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting beef: $e');
      return null;
    }
  }

  /// Stream a specific beef for real-time updates
  Stream<Beef?> streamBeef(String beefId) {
    return _firestore.collection('beefs').doc(beefId).snapshots().map((doc) {
      if (!doc.exists) return null;
      try {
        return Beef.fromJson(doc.data()!);
      } catch (e) {
        print('Error parsing beef: $e');
        return null;
      }
    });
  }

  /// Check if user has an active beef with target
  Future<bool> hasActiveBeefWith(String userId, String targetId) async {
    try {
      final query1 = await _firestore
          .collection('beefs')
          .where('instigatorId', isEqualTo: userId)
          .where('targetId', isEqualTo: targetId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (query1.docs.isNotEmpty) return true;

      final query2 = await _firestore
          .collection('beefs')
          .where('instigatorId', isEqualTo: targetId)
          .where('targetId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      return query2.docs.isNotEmpty;
    } catch (e) {
      print('Error checking active beef: $e');
      return false;
    }
  }

  /// Get count of active beefs for a user
  Future<int> getActiveBeefCount(String userId) async {
    try {
      final instigatorQuery = await _firestore
          .collection('beefs')
          .where('instigatorId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      final targetQuery = await _firestore
          .collection('beefs')
          .where('targetId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      return instigatorQuery.docs.length + targetQuery.docs.length;
    } catch (e) {
      print('Error getting beef count: $e');
      return 0;
    }
  }

  /// Get total fame gained/lost from beefs
  Future<Map<String, int>> getBeefStats(String userId) async {
    try {
      final instigatorQuery = await _firestore
          .collection('beefs')
          .where('instigatorId', isEqualTo: userId)
          .where('status', isEqualTo: 'resolved')
          .get();

      final targetQuery = await _firestore
          .collection('beefs')
          .where('targetId', isEqualTo: userId)
          .where('status', isEqualTo: 'resolved')
          .get();

      int totalFameGained = 0;
      int wins = 0;
      int losses = 0;
      int draws = 0;

      for (final doc in instigatorQuery.docs) {
        final beef = Beef.fromJson(doc.data());
        totalFameGained += beef.instigatorFameGain;

        final winType = beef.metadata['winType'] as String?;
        if (winType == 'draw') {
          draws++;
        } else if (beef.metadata['winnerId'] == userId) {
          wins++;
        } else {
          losses++;
        }
      }

      for (final doc in targetQuery.docs) {
        final beef = Beef.fromJson(doc.data());
        totalFameGained += beef.targetFameGain;

        final winType = beef.metadata['winType'] as String?;
        if (winType == 'draw') {
          draws++;
        } else if (beef.metadata['winnerId'] == userId) {
          wins++;
        } else {
          losses++;
        }
      }

      return {
        'totalFameGained': totalFameGained,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'total': wins + losses + draws,
      };
    } catch (e) {
      print('Error getting beef stats: $e');
      return {
        'totalFameGained': 0,
        'wins': 0,
        'losses': 0,
        'draws': 0,
        'total': 0,
      };
    }
  }
}
