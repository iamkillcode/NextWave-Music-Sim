import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collaboration.dart';

/// Service for managing player-to-player collaborations
class CollaborationService {
  static final CollaborationService _instance =
      CollaborationService._internal();
  factory CollaborationService() => _instance;
  CollaborationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Search for players to collaborate with
  Future<List<PlayerArtist>> searchPlayers({
    String? query,
    String? genre,
    String? region,
    int? minFame,
    int? maxFame,
    int limit = 20,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;

      // Fetch all players without ordering to avoid missing index errors
      final snapshot = await _firestore.collection('players').limit(500).get();

      final filtered = snapshot.docs.where((doc) {
        if (doc.id == currentUserId) return false;
        final data = doc.data();

        final fame = (data['fame'] as num?)?.toInt() ?? 0;
        if (minFame != null && fame < minFame) return false;
        if (maxFame != null && fame > maxFame) return false;

        if (genre != null && genre != 'All') {
          final docGenre = (data['primaryGenre'] as String?) ?? '';
          if (docGenre.toLowerCase() != genre.toLowerCase()) {
            return false;
          }
        }

        if (region != null && region != 'All') {
          final docRegion = (data['homeRegion'] as String?) ?? '';
          if (docRegion.toLowerCase() != region.toLowerCase()) {
            return false;
          }
        }

        if (query != null && query.trim().isNotEmpty) {
          final name = (data['displayName'] as String?) ??
              (data['name'] as String?) ??
              '';
          if (!name.toLowerCase().contains(query.toLowerCase())) {
            return false;
          }
        }

        return true;
      }).take(limit);

      return filtered
          .map((doc) => PlayerArtist.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error searching players: $e');
      return [];
    }
  }

  /// Get recommended collaborators based on genre and region
  Future<List<PlayerArtist>> getRecommendedPlayers(
    String playerGenre,
    String playerRegion,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;

      // Fetch all players and filter client-side to avoid index requirements
      final snapshot = await _firestore.collection('players').limit(100).get();

      final results = <PlayerArtist>[];
      final seenIds = <String>{};

      // Add same genre players first
      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId || seenIds.contains(doc.id)) continue;

        final data = doc.data();
        final docGenre = (data['primaryGenre'] as String?) ?? '';

        if (docGenre.toLowerCase() == playerGenre.toLowerCase()) {
          results.add(PlayerArtist.fromJson({
            ...data,
            'id': doc.id,
          }));
          seenIds.add(doc.id);
          if (results.length >= 15) break;
        }
      }

      // Then add same region players
      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId || seenIds.contains(doc.id)) continue;
        if (results.length >= 15) break;

        final data = doc.data();
        final docRegion = (data['homeRegion'] as String?) ?? '';

        if (docRegion.toLowerCase() == playerRegion.toLowerCase()) {
          results.add(PlayerArtist.fromJson({
            ...data,
            'id': doc.id,
          }));
          seenIds.add(doc.id);
        }
      }

      return results.take(15).toList();
    } catch (e) {
      print('Error getting recommended players: $e');
      return [];
    }
  }

  /// Send collaboration request via StarChat
  Future<bool> sendCollaborationRequest({
    required String songId,
    required String featuringArtistId,
    required String featuringArtistName,
    required String songTitle,
    required String genre,
    required CollaborationType type,
    int splitPercentage = 30,
    int? featureFee,
    String? message,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get current user's data
      final userDoc =
          await _firestore.collection('players').doc(currentUser.uid).get();
      final userData = userDoc.data();
      if (userData == null) return false;

      final collabId = _firestore.collection('collaborations').doc().id;

      final collaboration = Collaboration(
        id: collabId,
        songId: songId,
        primaryArtistId: currentUser.uid,
        primaryArtistName: userData['displayName'] ?? 'Unknown',
        featuringArtistId: featuringArtistId,
        featuringArtistName: featuringArtistName,
        status: CollaborationStatus.pending,
        type: type,
        createdDate: DateTime.now(),
        splitPercentage: splitPercentage,
        featureFee: featureFee,
        feePaid: false,
        primaryRegion: userData['homeRegion'] as String?,
        metadata: {
          'songTitle': songTitle,
          'genre': genre,
          'message': message,
        },
      );

      // Save collaboration to Firestore
      await _firestore
          .collection('collaborations')
          .doc(collabId)
          .set(collaboration.toJson());

      // Send notification via StarChat
      await _firestore.collection('starchat_messages').add({
        'type': 'collaboration_request',
        'fromUserId': currentUser.uid,
        'fromUserName': userData['displayName'] ?? 'Unknown',
        'toUserId': featuringArtistId,
        'collaborationId': collabId,
        'songTitle': songTitle,
        'featureFee': featureFee,
        'splitPercentage': splitPercentage,
        'message': message ?? 'wants to collaborate with you on "$songTitle"',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      return true;
    } catch (e) {
      print('Error sending collaboration request: $e');
      return false;
    }
  }

  /// Get pending collaboration requests
  Stream<List<Collaboration>> getPendingRequests(String userId) {
    return _firestore
        .collection('collaborations')
        .where('featuringArtistId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Collaboration.fromJson(doc.data()))
            .toList());
  }

  /// Get active collaborations (accepted or recording)
  Stream<List<Collaboration>> getActiveCollaborations(String userId) {
    return _firestore
        .collection('collaborations')
        .where('status', whereIn: ['accepted', 'recording', 'recorded'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Collaboration.fromJson(doc.data()))
            .where((collab) =>
                collab.primaryArtistId == userId ||
                collab.featuringArtistId == userId)
            .toList());
  }

  /// Accept collaboration request
  Future<bool> acceptCollaboration(String collaborationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get collaboration details
      final collabDoc = await _firestore
          .collection('collaborations')
          .doc(collaborationId)
          .get();

      if (!collabDoc.exists) return false;

      final collabData = Collaboration.fromJson(collabDoc.data()!);

      // Get featuring artist's region
      final userDoc =
          await _firestore.collection('players').doc(currentUser.uid).get();
      final featuringRegion = userDoc.data()?['homeRegion'] as String?;

      // Update song metadata to include featuring artist info
      await _firestore.collection('songs').doc(collabData.songId).update({
        'metadata.featuringArtist': collabData.featuringArtistName,
        'metadata.featuringArtistId': collabData.featuringArtistId,
        'metadata.isCollaboration': true,
      });

      // If there's a feature fee, handle payment
      if (collabData.featureFee != null && collabData.featureFee! > 0) {
        // Get primary artist's money
        final primaryDoc = await _firestore
            .collection('players')
            .doc(collabData.primaryArtistId)
            .get();

        final primaryMoney = primaryDoc.data()?['currentMoney'] ?? 0;

        // Check if primary artist can afford the fee
        if (primaryMoney < collabData.featureFee!) {
          throw Exception('Primary artist cannot afford feature fee');
        }

        // Deduct from primary artist
        await _firestore
            .collection('players')
            .doc(collabData.primaryArtistId)
            .update({
          'currentMoney': primaryMoney - collabData.featureFee!,
        });

        // Pay featuring artist
        final featuringMoney = userDoc.data()?['currentMoney'] ?? 0;
        await _firestore.collection('players').doc(currentUser.uid).update({
          'currentMoney': featuringMoney + collabData.featureFee!,
        });

        // Mark fee as paid
        await _firestore
            .collection('collaborations')
            .doc(collaborationId)
            .update({
          'status': 'accepted',
          'acceptedDate': FieldValue.serverTimestamp(),
          'featuringRegion': featuringRegion,
          'feePaid': true,
        });
      } else {
        // No fee, just accept
        await _firestore
            .collection('collaborations')
            .doc(collaborationId)
            .update({
          'status': 'accepted',
          'acceptedDate': FieldValue.serverTimestamp(),
          'featuringRegion': featuringRegion,
        });
      }

      return true;
    } catch (e) {
      print('Error accepting collaboration: $e');
      return false;
    }
  }

  /// Reject collaboration request
  Future<bool> rejectCollaboration(String collaborationId) async {
    try {
      await _firestore
          .collection('collaborations')
          .doc(collaborationId)
          .update({
        'status': 'rejected',
      });
      return true;
    } catch (e) {
      print('Error rejecting collaboration: $e');
      return false;
    }
  }

  /// Record together (travel bonus)
  Future<bool> recordTogether(String collaborationId) async {
    try {
      await _firestore
          .collection('collaborations')
          .doc(collaborationId)
          .update({
        'status': 'recorded',
        'recordedDate': FieldValue.serverTimestamp(),
        'recordedTogether': true,
      });
      return true;
    } catch (e) {
      print('Error recording together: $e');
      return false;
    }
  }

  /// Send recording remotely via StarChat
  Future<bool> sendRecordingRemotely(
    String collaborationId,
    String recordingUrl,
  ) async {
    try {
      final collab = await _firestore
          .collection('collaborations')
          .doc(collaborationId)
          .get();

      if (!collab.exists) return false;

      final collabData = Collaboration.fromJson(collab.data()!);

      // Update collaboration
      await _firestore
          .collection('collaborations')
          .doc(collaborationId)
          .update({
        'status': 'recording',
        'metadata.recordingUrl': recordingUrl,
      });

      // Notify primary artist via StarChat
      await _firestore.collection('starchat_messages').add({
        'type': 'recording_received',
        'fromUserId': collabData.featuringArtistId,
        'fromUserName': collabData.featuringArtistName,
        'toUserId': collabData.primaryArtistId,
        'collaborationId': collaborationId,
        'message':
            'sent their recording for "${collabData.metadata['songTitle']}"',
        'recordingUrl': recordingUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      return true;
    } catch (e) {
      print('Error sending recording: $e');
      return false;
    }
  }

  /// Accept received recording and complete collaboration
  Future<bool> acceptRecording(String collaborationId) async {
    try {
      await _firestore
          .collection('collaborations')
          .doc(collaborationId)
          .update({
        'status': 'recorded',
        'recordedDate': FieldValue.serverTimestamp(),
        'recordedTogether': false,
      });
      return true;
    } catch (e) {
      print('Error accepting recording: $e');
      return false;
    }
  }

  /// Calculate collaboration boost based on type and regions
  CollaborationBoost calculateCollaborationBoost({
    required bool recordedTogether,
    required bool sameRegion,
    required bool sameGenre,
    required int primaryFame,
    required int featuringFame,
  }) {
    double streamMultiplier = 1.0;
    int qualityBonus = 0;
    int fameBonus = 0;

    // Base boost from featuring artist's fame
    if (featuringFame >= 200) {
      streamMultiplier = 1.8;
      qualityBonus = 15;
      fameBonus = 25;
    } else if (featuringFame >= 100) {
      streamMultiplier = 1.5;
      qualityBonus = 10;
      fameBonus = 15;
    } else if (featuringFame >= 50) {
      streamMultiplier = 1.3;
      qualityBonus = 7;
      fameBonus = 10;
    } else {
      streamMultiplier = 1.2;
      qualityBonus = 5;
      fameBonus = 5;
    }

    // Recording together bonus (travel)
    if (recordedTogether) {
      streamMultiplier *= 1.3; // 30% bonus
      qualityBonus += 10;
      fameBonus += 10;
    }

    // Same region bonus (easier to collab)
    if (sameRegion && !recordedTogether) {
      streamMultiplier *= 1.1;
      qualityBonus += 3;
    }

    // Genre synergy bonus
    if (sameGenre) {
      streamMultiplier *= 1.15;
      qualityBonus += 5;
      fameBonus += 5;
    }

    // Cross-promotion fanbase gain (10% of featuring artist's fanbase)
    final fanbaseGain = (featuringFame * 100).round();

    return CollaborationBoost(
      streamMultiplier: streamMultiplier,
      qualityBonus: qualityBonus,
      fameBonus: fameBonus,
      fanbaseGain: fanbaseGain,
    );
  }

  /// Get player by ID
  Future<PlayerArtist?> getPlayerById(String playerId) async {
    try {
      final doc = await _firestore.collection('players').doc(playerId).get();
      if (!doc.exists) return null;

      return PlayerArtist.fromJson({
        ...doc.data()!,
        'id': doc.id,
      });
    } catch (e) {
      print('Error getting player: $e');
      return null;
    }
  }

  /// Calculate travel cost to another region
  int calculateTravelCost(String fromRegion, String toRegion) {
    if (fromRegion == toRegion) return 0;

    // Base travel costs between regions
    const travelCosts = {
      'usa': {
        'europe': 5000,
        'asia': 7000,
        'africa': 6000,
        'latin_america': 4000
      },
      'europe': {
        'usa': 5000,
        'asia': 6000,
        'africa': 4000,
        'latin_america': 6000
      },
      'asia': {
        'usa': 7000,
        'europe': 6000,
        'africa': 5000,
        'latin_america': 8000
      },
      'africa': {
        'usa': 6000,
        'europe': 4000,
        'asia': 5000,
        'latin_america': 7000
      },
      'latin_america': {
        'usa': 4000,
        'europe': 6000,
        'asia': 8000,
        'africa': 7000
      },
    };

    return travelCosts[fromRegion]?[toRegion] ?? 5000;
  }

  /// Check if regions match
  bool areRegionsCompatible(String? region1, String? region2) {
    if (region1 == null || region2 == null) return false;
    return region1 == region2;
  }
}

/// Collaboration bonuses applied to a song
class CollaborationBoost {
  final double streamMultiplier; // Multiplies base streams
  final int qualityBonus; // Adds to recording quality
  final int fameBonus; // Fame points gained
  final int fanbaseGain; // New fans from cross-promotion

  const CollaborationBoost({
    required this.streamMultiplier,
    required this.qualityBonus,
    required this.fameBonus,
    required this.fanbaseGain,
  });
}
