import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Service for managing admin privileges and admin-only operations
class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Cache admin status to avoid repeated queries
  bool? _isAdminCached;
  String? _cachedUserId;

  /// List of admin user IDs (update this with your actual Firebase User ID)
  /// You can find your user ID in Firebase Console > Authentication
  static const List<String> ADMIN_USER_IDS = [
    // Add your Firebase User IDs here
    'DQZOCI1WUxYNxX3QBm36qUDcYvj2',
    // Example: 'abc123xyz456',
  ];

  /// Check if current user is an admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Return cached value if available for same user
    if (_cachedUserId == user.uid && _isAdminCached != null) {
      return _isAdminCached!;
    }

    try {
      // Check hardcoded list first (fastest)
      if (ADMIN_USER_IDS.contains(user.uid)) {
        _isAdminCached = true;
        _cachedUserId = user.uid;
        return true;
      }

      // Check Firestore admin flag
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      final isAdmin = doc.exists && (doc.data()?['isAdmin'] == true);

      // Cache result
      _isAdminCached = isAdmin;
      _cachedUserId = user.uid;

      return isAdmin;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Clear admin cache (call after logout or role changes)
  void clearCache() {
    _isAdminCached = null;
    _cachedUserId = null;
  }

  /// Grant admin privileges to a user
  Future<bool> grantAdminAccess(String userId) async {
    try {
      // Only existing admins can grant admin access
      if (!await isAdmin()) {
        throw Exception('Only admins can grant admin access');
      }

      await _firestore.collection('admins').doc(userId).set({
        'isAdmin': true,
        'grantedBy': _auth.currentUser?.uid,
        'grantedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error granting admin access: $e');
      return false;
    }
  }

  /// Revoke admin privileges from a user
  Future<bool> revokeAdminAccess(String userId) async {
    try {
      // Only existing admins can revoke admin access
      if (!await isAdmin()) {
        throw Exception('Only admins can revoke admin access');
      }

      // Prevent revoking your own admin access
      if (userId == _auth.currentUser?.uid) {
        throw Exception('Cannot revoke your own admin access');
      }

      await _firestore.collection('admins').doc(userId).delete();

      return true;
    } catch (e) {
      print('Error revoking admin access: $e');
      return false;
    }
  }

  /// Get list of all admins
  Future<List<Map<String, dynamic>>> getAdminList() async {
    try {
      if (!await isAdmin()) {
        throw Exception('Only admins can view admin list');
      }

      final snapshot = await _firestore.collection('admins').get();
      final admins = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final adminData = doc.data();

        // Try to get player info
        final playerDoc =
            await _firestore.collection('players').doc(doc.id).get();

        admins.add({
          'userId': doc.id,
          'name': playerDoc.data()?['name'] ?? 'Unknown',
          'isAdmin': adminData['isAdmin'] ?? false,
          'grantedBy': adminData['grantedBy'],
          'grantedAt': adminData['grantedAt'],
        });
      }

      return admins;
    } catch (e) {
      print('Error getting admin list: $e');
      return [];
    }
  }

  // ============================================================================
  // ADMIN-ONLY OPERATIONS
  // ============================================================================

  /// Initialize NPC Artists (Admin Only)
  Future<Map<String, dynamic>> initializeNPCs() async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      final callable = _functions.httpsCallable('initializeNPCArtists');
      final result = await callable.call();
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to initialize NPCs: $e');
    }
  }

  /// Trigger manual daily update (Admin Only)
  Future<Map<String, dynamic>> triggerDailyUpdate() async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      final callable = _functions.httpsCallable('triggerDailyUpdate');
      final result = await callable.call();
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to trigger daily update: $e');
    }
  }

  /// Get game statistics (Admin Only)
  Future<Map<String, dynamic>> getGameStats() async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      // Get total players
      final playersSnapshot = await _firestore.collection('players').get();
      final totalPlayers = playersSnapshot.size;

      // Get total songs
      int totalSongs = 0;
      for (var player in playersSnapshot.docs) {
        final songs = player.data()['songs'] as List?;
        totalSongs += songs?.length ?? 0;
      }

      // Get total EchoX posts
      final echoxSnapshot = await _firestore.collection('echox_posts').get();
      final totalPosts = echoxSnapshot.size;

      // Get NPC count
      final npcSnapshot = await _firestore
          .collection('npc_artists')
          .where('isNPC', isEqualTo: true)
          .get();
      final totalNPCs = npcSnapshot.size;

      // Get active side hustles (count players with activeSideHustle)
      int activeHustles = 0;
      for (var player in playersSnapshot.docs) {
        final playerData = player.data();
        // Check if activeSideHustle field exists and is not null
        if (playerData.containsKey('activeSideHustle') &&
            playerData['activeSideHustle'] != null) {
          activeHustles++;
        }
      }

      return {
        'totalPlayers': totalPlayers,
        'totalSongs': totalSongs,
        'totalEchoXPosts': totalPosts,
        'totalNPCs': totalNPCs,
        'activeHustles': activeHustles,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get game stats: $e');
    }
  }

  /// Delete all player data (Admin Only - DANGEROUS)
  Future<bool> resetAllPlayerData() async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      // This is a dangerous operation - require confirmation
      final batch = _firestore.batch();

      final playersSnapshot = await _firestore.collection('players').get();
      for (var doc in playersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error resetting player data: $e');
      return false;
    }
  }

  /// Send system notification to all players (Admin Only)
  Future<bool> sendGlobalNotification(String title, String message) async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      await _firestore.collection('system_notifications').add({
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
        'type': 'global',
      });

      return true;
    } catch (e) {
      print('Error sending global notification: $e');
      return false;
    }
  }

  /// Adjust player stats (Admin Only - for testing/debugging)
  Future<bool> adjustPlayerStats(
    String playerId,
    Map<String, dynamic> adjustments,
  ) async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      await _firestore.collection('players').doc(playerId).update(adjustments);
      return true;
    } catch (e) {
      print('Error adjusting player stats: $e');
      return false;
    }
  }

  /// Get error logs (Admin Only)
  Future<List<Map<String, dynamic>>> getErrorLogs({int limit = 50}) async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      final snapshot = await _firestore
          .collection('error_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting error logs: $e');
      return [];
    }
  }

  /// Force an NPC to release a new song (Admin Only - for testing)
  Future<Map<String, dynamic>> forceNPCRelease(String npcId) async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      final result = await _functions
          .httpsCallable('forceNPCRelease')
          .call({'npcId': npcId});

      return {
        'success': true,
        'data': result.data,
      };
    } catch (e) {
      print('Error forcing NPC release: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get list of available NPCs
  static const List<Map<String, String>> AVAILABLE_NPCS = [
    {'id': 'npc_jaylen_sky', 'name': 'Jaylen Sky', 'genre': 'Hip Hop'},
    {'id': 'npc_luna_grey', 'name': 'Luna Grey', 'genre': 'Pop'},
    {'id': 'npc_elodie_rain', 'name': 'Élodie Rain', 'genre': 'Electronic'},
    {'id': 'npc_santiago_vega', 'name': 'Santiago Vega', 'genre': 'Latin'},
    {'id': 'npc_zyrah', 'name': 'Zyrah', 'genre': 'Afrobeat'},
    {'id': 'npc_kazuya_rin', 'name': 'Kazuya Rin', 'genre': 'Electronic'},
    {'id': 'npc_maya_cross', 'name': 'Maya Cross', 'genre': 'Rock'},
    {'id': 'npc_dante_noir', 'name': 'Dante Noir', 'genre': 'R&B'},
    {'id': 'npc_kira_blaze', 'name': 'Kira Blaze', 'genre': 'Indie'},
    {'id': 'npc_phoenix_reid', 'name': 'Phoenix Reid', 'genre': 'Country'},
  ];
}
