import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Crew challenge model
class CrewChallenge {
  final String id;
  final String title;
  final String description;
  final String type; // 'streams', 'songs', 'revenue', 'collaboration'
  final int targetValue;
  final int rewardMoney;
  final int rewardXP;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participatingCrews; // Crew IDs
  final Map<String, int> crewProgress; // crewId -> current value
  final String? winnerId; // Crew ID of winner
  final bool isActive;

  const CrewChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.rewardMoney,
    required this.rewardXP,
    required this.startDate,
    required this.endDate,
    this.participatingCrews = const [],
    this.crewProgress = const {},
    this.winnerId,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'rewardMoney': rewardMoney,
      'rewardXP': rewardXP,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'participatingCrews': participatingCrews,
      'crewProgress': crewProgress,
      'winnerId': winnerId,
      'isActive': isActive,
    };
  }

  factory CrewChallenge.fromJson(Map<String, dynamic> json) {
    return CrewChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      targetValue: json['targetValue'] as int,
      rewardMoney: json['rewardMoney'] as int,
      rewardXP: json['rewardXP'] as int? ?? 0,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      participatingCrews:
          List<String>.from(json['participatingCrews'] as List? ?? []),
      crewProgress: Map<String, int>.from(json['crewProgress'] as Map? ?? {}),
      winnerId: json['winnerId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  CrewChallenge copyWith({
    String? winnerId,
    bool? isActive,
    Map<String, int>? crewProgress,
    List<String>? participatingCrews,
  }) {
    return CrewChallenge(
      id: id,
      title: title,
      description: description,
      type: type,
      targetValue: targetValue,
      rewardMoney: rewardMoney,
      rewardXP: rewardXP,
      startDate: startDate,
      endDate: endDate,
      participatingCrews: participatingCrews ?? this.participatingCrews,
      crewProgress: crewProgress ?? this.crewProgress,
      winnerId: winnerId ?? this.winnerId,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if challenge is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get time remaining
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  /// Get progress percentage for a crew
  int getProgressPercentage(String crewId) {
    final progress = crewProgress[crewId] ?? 0;
    return ((progress / targetValue) * 100).round().clamp(0, 100);
  }

  /// Get leading crew
  String? get leadingCrewId {
    if (crewProgress.isEmpty) return null;
    var maxProgress = 0;
    String? leader;
    for (var entry in crewProgress.entries) {
      if (entry.value > maxProgress) {
        maxProgress = entry.value;
        leader = entry.key;
      }
    }
    return leader;
  }
}

/// Service for crew challenges
class CrewChallengeService {
  static final CrewChallengeService _instance =
      CrewChallengeService._internal();
  factory CrewChallengeService() => _instance;
  CrewChallengeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new challenge
  Future<String?> createChallenge({
    required String title,
    required String description,
    required String type,
    required int targetValue,
    required int rewardMoney,
    required int rewardXP,
    required Duration duration,
  }) async {
    try {
      final challengeId = _firestore.collection('crew_challenges').doc().id;
      final now = DateTime.now();
      final challenge = CrewChallenge(
        id: challengeId,
        title: title,
        description: description,
        type: type,
        targetValue: targetValue,
        rewardMoney: rewardMoney,
        rewardXP: rewardXP,
        startDate: now,
        endDate: now.add(duration),
      );

      await _firestore
          .collection('crew_challenges')
          .doc(challengeId)
          .set(challenge.toJson());

      return challengeId;
    } catch (e) {
      print('Error creating challenge: $e');
      return null;
    }
  }

  /// Join a challenge
  Future<bool> joinChallenge(String challengeId, String crewId) async {
    try {
      final challengeDoc =
          await _firestore.collection('crew_challenges').doc(challengeId).get();
      if (!challengeDoc.exists) return false;

      final challenge = CrewChallenge.fromJson(challengeDoc.data()!);

      if (!challenge.isCurrentlyActive) {
        throw Exception('Challenge is not active');
      }

      if (challenge.participatingCrews.contains(crewId)) {
        throw Exception('Already joined this challenge');
      }

      await _firestore.collection('crew_challenges').doc(challengeId).update({
        'participatingCrews': FieldValue.arrayUnion([crewId]),
        'crewProgress.$crewId': 0,
      });

      return true;
    } catch (e) {
      print('Error joining challenge: $e');
      return false;
    }
  }

  /// Update crew progress in a challenge
  Future<bool> updateChallengeProgress({
    required String challengeId,
    required String crewId,
    required int newValue,
  }) async {
    try {
      final challengeDoc =
          await _firestore.collection('crew_challenges').doc(challengeId).get();
      if (!challengeDoc.exists) return false;

      final challenge = CrewChallenge.fromJson(challengeDoc.data()!);

      if (!challenge.participatingCrews.contains(crewId)) {
        throw Exception('Crew not participating in this challenge');
      }

      await _firestore.collection('crew_challenges').doc(challengeId).update({
        'crewProgress.$crewId': newValue,
      });

      // Check if challenge is complete
      if (newValue >= challenge.targetValue) {
        await _completeChallenge(challengeId, crewId);
      }

      return true;
    } catch (e) {
      print('Error updating challenge progress: $e');
      return false;
    }
  }

  /// Complete challenge and award rewards
  Future<void> _completeChallenge(
    String challengeId,
    String winningCrewId,
  ) async {
    try {
      final challengeDoc =
          await _firestore.collection('crew_challenges').doc(challengeId).get();
      if (!challengeDoc.exists) return;

      final challenge = CrewChallenge.fromJson(challengeDoc.data()!);

      if (challenge.winnerId != null) {
        // Challenge already has a winner
        return;
      }

      // Mark challenge as complete
      await _firestore.collection('crew_challenges').doc(challengeId).update({
        'winnerId': winningCrewId,
        'isActive': false,
      });

      // Award rewards to crew's shared bank
      await _firestore.collection('crews').doc(winningCrewId).update({
        'sharedBank': FieldValue.increment(challenge.rewardMoney),
        'challengesWon': FieldValue.increment(1),
      });

      // Award XP to all members
      final crewDoc =
          await _firestore.collection('crews').doc(winningCrewId).get();
      if (crewDoc.exists) {
        final memberIds = (crewDoc.data()!['members'] as List)
            .map((m) => m['userId'] as String)
            .toList();

        for (var memberId in memberIds) {
          await _firestore.collection('players').doc(memberId).update({
            'experience': FieldValue.increment(challenge.rewardXP),
          });
        }
      }
    } catch (e) {
      print('Error completing challenge: $e');
    }
  }

  /// Get active challenges
  Stream<List<CrewChallenge>> streamActiveChallenges() {
    try {
      final now = DateTime.now();
      return _firestore
          .collection('crew_challenges')
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CrewChallenge.fromJson(doc.data()))
              .toList());
    } catch (e) {
      print('Error streaming challenges: $e');
      return Stream.value([]);
    }
  }

  /// Get challenges for a specific crew
  Stream<List<CrewChallenge>> streamCrewChallenges(String crewId) {
    try {
      return _firestore
          .collection('crew_challenges')
          .where('participatingCrews', arrayContains: crewId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CrewChallenge.fromJson(doc.data()))
              .toList());
    } catch (e) {
      print('Error streaming crew challenges: $e');
      return Stream.value([]);
    }
  }

  /// Get completed challenges won by a crew
  Future<List<CrewChallenge>> getCrewWins(String crewId) async {
    try {
      final snapshot = await _firestore
          .collection('crew_challenges')
          .where('winnerId', isEqualTo: crewId)
          .orderBy('endDate', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => CrewChallenge.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting crew wins: $e');
      return [];
    }
  }

  /// Check and end expired challenges
  Future<void> checkExpiredChallenges() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('crew_challenges')
          .where('isActive', isEqualTo: true)
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .get();

      for (var doc in snapshot.docs) {
        final challenge = CrewChallenge.fromJson(doc.data());

        // Find the crew with highest progress
        if (challenge.crewProgress.isNotEmpty) {
          var maxProgress = 0;
          String? winnerId;

          for (var entry in challenge.crewProgress.entries) {
            if (entry.value > maxProgress) {
              maxProgress = entry.value;
              winnerId = entry.key;
            }
          }

          if (winnerId != null && maxProgress > 0) {
            await _completeChallenge(challenge.id, winnerId);
          } else {
            // No winner, just deactivate
            await _firestore
                .collection('crew_challenges')
                .doc(challenge.id)
                .update({'isActive': false});
          }
        }
      }
    } catch (e) {
      print('Error checking expired challenges: $e');
    }
  }
}
