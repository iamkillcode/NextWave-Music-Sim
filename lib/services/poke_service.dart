import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing pokes (mutual connection system for StarChat)
/// Players must poke each other before they can DM
class PokeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Send a poke to another user
  Future<bool> pokeUser(String targetUserId) async {
    if (currentUserId == null || currentUserId == targetUserId) return false;

    try {
      // Add to current user's sentPokes
      await _firestore.collection('players').doc(currentUserId).update({
        'sentPokes': FieldValue.arrayUnion([targetUserId]),
      });

      // Add to target user's receivedPokes
      await _firestore.collection('players').doc(targetUserId).update({
        'receivedPokes': FieldValue.arrayUnion([currentUserId]),
      });

      return true;
    } catch (e) {
      print('Error poking user: $e');
      return false;
    }
  }

  /// Remove a poke (unpoke)
  Future<bool> unpokeUser(String targetUserId) async {
    if (currentUserId == null || currentUserId == targetUserId) return false;

    try {
      // Remove from current user's sentPokes
      await _firestore.collection('players').doc(currentUserId).update({
        'sentPokes': FieldValue.arrayRemove([targetUserId]),
      });

      // Remove from target user's receivedPokes
      await _firestore.collection('players').doc(targetUserId).update({
        'receivedPokes': FieldValue.arrayRemove([currentUserId]),
      });

      return true;
    } catch (e) {
      print('Error unpoking user: $e');
      return false;
    }
  }

  /// Check if two users have mutual pokes (can DM each other)
  Future<bool> haveMutualPokes(String userId1, String userId2) async {
    try {
      final user1Doc = await _firestore.collection('players').doc(userId1).get();
      final user2Doc = await _firestore.collection('players').doc(userId2).get();

      if (!user1Doc.exists || !user2Doc.exists) return false;

      final user1SentPokes = List<String>.from(user1Doc.data()?['sentPokes'] ?? []);
      final user2SentPokes = List<String>.from(user2Doc.data()?['sentPokes'] ?? []);

      // Mutual pokes = user1 poked user2 AND user2 poked user1
      return user1SentPokes.contains(userId2) && user2SentPokes.contains(userId1);
    } catch (e) {
      print('Error checking mutual pokes: $e');
      return false;
    }
  }

  /// Check if current user has poked target user
  Future<bool> hasPokedUser(String targetUserId) async {
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore.collection('players').doc(currentUserId).get();
      if (!doc.exists) return false;

      final sentPokes = List<String>.from(doc.data()?['sentPokes'] ?? []);
      return sentPokes.contains(targetUserId);
    } catch (e) {
      print('Error checking poke status: $e');
      return false;
    }
  }

  /// Check if target user has poked current user (waiting for poke back)
  Future<bool> hasUserPokedMe(String targetUserId) async {
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore.collection('players').doc(currentUserId).get();
      if (!doc.exists) return false;

      final receivedPokes = List<String>.from(doc.data()?['receivedPokes'] ?? []);
      return receivedPokes.contains(targetUserId);
    } catch (e) {
      print('Error checking received pokes: $e');
      return false;
    }
  }

  /// Get poke status between current user and target
  /// Returns: 'none', 'sent', 'received', 'mutual'
  Future<String> getPokeStatus(String targetUserId) async {
    if (currentUserId == null) return 'none';

    try {
      final myDoc = await _firestore.collection('players').doc(currentUserId).get();
      final theirDoc = await _firestore.collection('players').doc(targetUserId).get();

      if (!myDoc.exists || !theirDoc.exists) return 'none';

      final mySentPokes = List<String>.from(myDoc.data()?['sentPokes'] ?? []);
      final myReceivedPokes = List<String>.from(myDoc.data()?['receivedPokes'] ?? []);

      final iPokedThem = mySentPokes.contains(targetUserId);
      final theyPokedMe = myReceivedPokes.contains(targetUserId);

      if (iPokedThem && theyPokedMe) return 'mutual';
      if (iPokedThem) return 'sent';
      if (theyPokedMe) return 'received';
      return 'none';
    } catch (e) {
      print('Error getting poke status: $e');
      return 'none';
    }
  }

  /// Get list of users who have poked current user (poke requests)
  Stream<List<String>> streamPokeRequests() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('players')
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      
      final receivedPokes = List<String>.from(doc.data()?['receivedPokes'] ?? []);
      final sentPokes = List<String>.from(doc.data()?['sentPokes'] ?? []);
      
      // Only return pokes we haven't poked back (requests)
      return receivedPokes.where((userId) => !sentPokes.contains(userId)).toList();
    });
  }

  /// Get count of pending poke requests
  Stream<int> streamPokeRequestCount() {
    return streamPokeRequests().map((requests) => requests.length);
  }
}
