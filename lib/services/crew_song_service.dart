import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crew.dart';
import '../models/song.dart';

/// Service for managing crew songs and projects
class CrewSongService {
  static final CrewSongService _instance = CrewSongService._internal();
  factory CrewSongService() => _instance;
  CrewSongService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Start a new crew song project
  Future<Map<String, dynamic>> startCrewSong({
    required String crewId,
    required String songId,
    required List<String> contributingMembers,
    required Map<String, int> creditSplit,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      // Validate credit split adds up to 100
      final totalSplit = creditSplit.values.fold(0, (sum, val) => sum + val);
      if (totalSplit != 100) {
        return {
          'success': false,
          'error': 'Credit split must total 100% (currently $totalSplit%)'
        };
      }

      // Get crew to calculate votes needed
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) {
        return {'success': false, 'error': 'Crew not found'};
      }

      final crew = Crew.fromJson(crewDoc.data()!);
      final votesNeeded = crew.minimumReleaseVotes;

      // Create crew song
      final crewSongId = _firestore.collection('crew_songs').doc().id;
      final crewSong = CrewSong(
        id: crewSongId,
        songId: songId,
        crewId: crewId,
        contributingMembers: contributingMembers,
        creditSplit: creditSplit,
        createdDate: DateTime.now(),
        status: 'writing',
        votesNeeded: votesNeeded,
      );

      await _firestore
          .collection('crew_songs')
          .doc(crewSongId)
          .set(crewSong.toJson());

      // Update song metadata
      await _firestore.collection('songs').doc(songId).update({
        'metadata.isCrewSong': true,
        'metadata.crewId': crewId,
        'metadata.crewSongId': crewSongId,
        'metadata.contributingMembers': contributingMembers,
      });

      return {
        'success': true,
        'crewSongId': crewSongId,
        'crewSong': crewSong,
      };
    } catch (e) {
      print('Error starting crew song: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Vote to approve a crew song for release
  Future<bool> voteForRelease({
    required String crewSongId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final crewSongDoc =
          await _firestore.collection('crew_songs').doc(crewSongId).get();
      if (!crewSongDoc.exists) return false;

      final crewSong = CrewSong.fromJson(crewSongDoc.data()!);

      // Check if user is a contributing member
      if (!crewSong.contributingMembers.contains(currentUser.uid)) {
        throw Exception('Only contributing members can vote');
      }

      // Check if already voted
      if (crewSong.approvedBy.contains(currentUser.uid)) {
        throw Exception('Already voted');
      }

      // Add vote
      final updatedApprovals = [...crewSong.approvedBy, currentUser.uid];

      await _firestore.collection('crew_songs').doc(crewSongId).update({
        'approvedBy': updatedApprovals,
      });

      // Check if enough votes to auto-approve
      if (updatedApprovals.length >= crewSong.votesNeeded) {
        await _firestore.collection('crew_songs').doc(crewSongId).update({
          'status': 'approved',
        });
      }

      return true;
    } catch (e) {
      print('Error voting for release: $e');
      return false;
    }
  }

  /// Mark crew song as recording
  Future<bool> startRecording(String crewSongId) async {
    try {
      await _firestore.collection('crew_songs').doc(crewSongId).update({
        'status': 'recording',
      });
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Mark crew song as recorded
  Future<bool> completeRecording(String crewSongId) async {
    try {
      await _firestore.collection('crew_songs').doc(crewSongId).update({
        'status': 'recorded',
      });
      return true;
    } catch (e) {
      print('Error completing recording: $e');
      return false;
    }
  }

  /// Release crew song (after recording and approval)
  Future<bool> releaseCrewSong(String crewSongId) async {
    try {
      final crewSongDoc =
          await _firestore.collection('crew_songs').doc(crewSongId).get();
      if (!crewSongDoc.exists) return false;

      final crewSong = CrewSong.fromJson(crewSongDoc.data()!);

      // Check if approved and recorded
      if (crewSong.status != 'recorded' && crewSong.status != 'approved') {
        throw Exception('Song must be recorded and approved first');
      }

      if (!crewSong.hasEnoughVotes) {
        throw Exception('Not enough votes to release');
      }

      // Update crew song status
      await _firestore.collection('crew_songs').doc(crewSongId).update({
        'status': 'released',
      });

      // Update crew stats
      await _firestore.collection('crews').doc(crewSong.crewId).update({
        'totalSongsReleased': FieldValue.increment(1),
      });

      // Update song state to released
      await _firestore.collection('songs').doc(crewSong.songId).update({
        'state': 'released',
        'releasedDate': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error releasing crew song: $e');
      return false;
    }
  }

  /// Stream crew songs for a crew
  Stream<List<CrewSong>> streamCrewSongs(String crewId) {
    return _firestore
        .collection('crew_songs')
        .where('crewId', isEqualTo: crewId)
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CrewSong.fromJson(doc.data())).toList());
  }

  /// Get crew songs by status
  Stream<List<CrewSong>> streamCrewSongsByStatus(
    String crewId,
    String status,
  ) {
    return _firestore
        .collection('crew_songs')
        .where('crewId', isEqualTo: crewId)
        .where('status', isEqualTo: status)
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CrewSong.fromJson(doc.data())).toList());
  }

  /// Get crew song by ID
  Future<CrewSong?> getCrewSongById(String crewSongId) async {
    try {
      final doc =
          await _firestore.collection('crew_songs').doc(crewSongId).get();
      if (!doc.exists) return null;
      return CrewSong.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting crew song: $e');
      return null;
    }
  }

  /// Calculate crew bonuses for a song
  CrewSongBonus calculateCrewBonus({
    required int numMembers,
    required bool allRecordedTogether,
    required bool sameGenre,
    required int combinedFame,
  }) {
    double streamMultiplier = 1.0;
    int qualityBonus = 0;
    int fameBonus = 0;

    // Base bonus from having multiple members
    if (numMembers >= 5) {
      streamMultiplier += 0.60; // +60% for full crew
      qualityBonus += 25;
      fameBonus += 30;
    } else if (numMembers >= 3) {
      streamMultiplier += 0.40; // +40% for 3+ members
      qualityBonus += 15;
      fameBonus += 20;
    } else if (numMembers >= 2) {
      streamMultiplier += 0.20; // +20% for duo
      qualityBonus += 10;
      fameBonus += 10;
    }

    // Bonus for recording together
    if (allRecordedTogether) {
      streamMultiplier += 0.20;
      qualityBonus += 10;
    }

    // Same genre synergy
    if (sameGenre) {
      streamMultiplier += 0.20;
      qualityBonus += 10;
    }

    // Combined fame boost
    final fameMultiplier = (combinedFame / 1000).clamp(0.0, 0.5);
    streamMultiplier += fameMultiplier;

    return CrewSongBonus(
      streamMultiplier: streamMultiplier,
      qualityBonus: qualityBonus,
      fameBonus: fameBonus,
      combinedFameBoost: (fameMultiplier * 100).round(),
    );
  }

  /// Distribute crew song revenue
  Future<void> distributeCrewSongRevenue({
    required String crewSongId,
    required int totalRevenue,
  }) async {
    try {
      final crewSongDoc =
          await _firestore.collection('crew_songs').doc(crewSongId).get();
      if (!crewSongDoc.exists) return;

      final crewSong = CrewSong.fromJson(crewSongDoc.data()!);

      // Get crew settings
      final crewDoc =
          await _firestore.collection('crews').doc(crewSong.crewId).get();
      if (!crewDoc.exists) return;

      final crew = Crew.fromJson(crewDoc.data()!);

      final batch = _firestore.batch();

      if (crew.autoDistributeRevenue) {
        // Distribute according to credit split
        for (var entry in crewSong.creditSplit.entries) {
          final userId = entry.key;
          final percentage = entry.value;
          final share = (totalRevenue * percentage / 100).round();

          final userRef = _firestore.collection('players').doc(userId);
          batch.update(userRef, {
            'currentMoney': FieldValue.increment(share),
          });
        }
      } else {
        // Add to crew shared bank
        final crewRef = _firestore.collection('crews').doc(crewSong.crewId);
        batch.update(crewRef, {
          'sharedBank': FieldValue.increment(totalRevenue),
        });
      }

      // Update crew total earnings
      final crewRef = _firestore.collection('crews').doc(crewSong.crewId);
      batch.update(crewRef, {
        'totalEarnings': FieldValue.increment(totalRevenue),
      });

      await batch.commit();
    } catch (e) {
      print('Error distributing crew song revenue: $e');
    }
  }
}

/// Bonuses applied to crew songs
class CrewSongBonus {
  final double streamMultiplier;
  final int qualityBonus;
  final int fameBonus;
  final int combinedFameBoost;

  const CrewSongBonus({
    required this.streamMultiplier,
    required this.qualityBonus,
    required this.fameBonus,
    required this.combinedFameBoost,
  });
}
