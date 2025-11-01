import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for EchoX follower and engagement system
class EchoXService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Update player's EchoX followers based on current fanbase
  Future<Map<String, dynamic>> updateFollowers() async {
    try {
      final callable = _functions.httpsCallable('updateEchoXFollowers');
      final result = await callable.call();

      return {
        'success': true,
        'newFollowers': result.data['newFollowers'],
        'message': result.data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Simulate realistic engagement on a post (likes, echoes, comments)
  Future<Map<String, dynamic>> simulatePostEngagement(String postId) async {
    try {
      final callable = _functions.httpsCallable('simulateEchoXEngagement');
      final result = await callable.call({'postId': postId});

      return {
        'success': true,
        'likes': result.data['likes'],
        'echoes': result.data['echoes'],
        'comments': result.data['comments'],
        'reach': result.data['reach'],
        'fameGain': result.data['fameGain'],
        'message': result.data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Follow or unfollow another artist
  Future<Map<String, dynamic>> toggleFollow(String targetUserId) async {
    try {
      final callable = _functions.httpsCallable('toggleEchoXFollow');
      final result = await callable.call({'targetUserId': targetUserId});

      return {
        'success': true,
        'action': result.data['action'], // 'followed' or 'unfollowed'
        'targetName': result.data['targetName'],
        'message': result.data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if current user is following target user
  Future<bool> isFollowing(String targetUserId) async {
    if (currentUserId == null) return false;

    try {
      final doc =
          await _firestore.collection('players').doc(currentUserId).get();
      if (!doc.exists) return false;

      final following = List<String>.from(doc.data()?['echoXFollowing'] ?? []);
      return following.contains(targetUserId);
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId) async {
    try {
      final doc = await _firestore.collection('players').doc(userId).get();
      if (!doc.exists) return 0;

      return doc.data()?['echoXFollowers'] ?? 0;
    } catch (e) {
      print('Error getting follower count: $e');
      return 0;
    }
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final doc = await _firestore.collection('players').doc(userId).get();
      if (!doc.exists) return 0;

      final following = List<String>.from(doc.data()?['echoXFollowing'] ?? []);
      return following.length;
    } catch (e) {
      print('Error getting following count: $e');
      return 0;
    }
  }

  /// Stream user's follower/following stats
  Stream<Map<String, int>> streamFollowerStats(String userId) {
    return _firestore.collection('players').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return {'followers': 0, 'following': 0};
      }

      final data = doc.data()!;
      final followers = data['echoXFollowers'] ?? 0;
      final following = List<String>.from(data['echoXFollowing'] ?? []).length;

      return {
        'followers': followers as int,
        'following': following,
      };
    });
  }

  /// Get list of users that current user follows
  Future<List<String>> getFollowingList() async {
    if (currentUserId == null) return [];

    try {
      final doc =
          await _firestore.collection('players').doc(currentUserId).get();
      if (!doc.exists) return [];

      return List<String>.from(doc.data()?['echoXFollowing'] ?? []);
    } catch (e) {
      print('Error getting following list: $e');
      return [];
    }
  }

  /// Get list of users following current user
  Future<List<String>> getFollowersList() async {
    if (currentUserId == null) return [];

    try {
      final doc =
          await _firestore.collection('players').doc(currentUserId).get();
      if (!doc.exists) return [];

      return List<String>.from(doc.data()?['echoXFollowedBy'] ?? []);
    } catch (e) {
      print('Error getting followers list: $e');
      return [];
    }
  }

  /// Calculate expected follower growth based on fanbase
  /// Formula: 30-60% of fanbase converts to followers
  int calculateExpectedFollowers(int fanbase, int loyalFanbase) {
    final baseConversionRate = 0.45; // Average of 30-60%
    final baseFollowers = (fanbase * baseConversionRate).floor();
    final loyalFollowers = (loyalFanbase * 0.8).floor();

    return baseFollowers + loyalFollowers;
  }
}
