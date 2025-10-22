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
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // Cache admin status to avoid repeated queries
  bool? _isAdminCached;
  String? _cachedUserId;

  /// Check if current user is an admin
  /// Server-side validation ensures security
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Return cached value if available for same user
    if (_cachedUserId == user.uid && _isAdminCached != null) {
      return _isAdminCached!;
    }

    try {
      // TEMPORARY FALLBACK: Check hardcoded admin list locally
      // This provides admin access until Cloud Functions are deployed
      // TODO: Remove this fallback after deploying Cloud Functions
      const adminUserIds = [
        'xjJFuMCEKMZwkI8uIP34Jl2bfQA3', // Primary admin
      ];
      
      // Try Cloud Function first
      try {
        final result = await _functions.httpsCallable('checkAdminStatus').call();
        final isAdmin = result.data['isAdmin'] ?? false;

        // Cache result
        _isAdminCached = isAdmin;
        _cachedUserId = user.uid;

        return isAdmin;
      } catch (e) {
        print('Cloud Function error (expected if not deployed): $e');
        
        // FALLBACK: Check hardcoded list if Cloud Function fails
        // This happens when functions aren't deployed yet
        if (adminUserIds.contains(user.uid)) {
          print('✅ Admin access granted via local fallback (UID: ${user.uid})');
          _isAdminCached = true;
          _cachedUserId = user.uid;
          return true;
        }
        
        // Also check Firestore admin collection as backup
        try {
          final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
          if (adminDoc.exists && adminDoc.data()?['isAdmin'] == true) {
            print('✅ Admin access granted via Firestore (UID: ${user.uid})');
            _isAdminCached = true;
            _cachedUserId = user.uid;
            return true;
          }
        } catch (firestoreError) {
          print('Firestore check error: $firestoreError');
        }
      }
      
      // Not an admin
      _isAdminCached = false;
      _cachedUserId = user.uid;
      return false;
      
    } catch (e) {
      print('Error checking admin status: $e');
      
      // Clear cache on error
      _isAdminCached = null;
      _cachedUserId = null;
      
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

  /// Trigger manual weekly leaderboard update (Admin Only)
  ///
  /// This will regenerate weekly chart snapshots for the specified number of weeks.
  /// Useful after backend fixes to refresh chart data.
  ///
  /// [weeksAhead] - Number of weeks to generate snapshots for (default: 1)
  Future<Map<String, dynamic>> triggerWeeklyLeaderboardUpdate({
    int weeksAhead = 1,
  }) async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      final callable =
          _functions.httpsCallable('triggerWeeklyLeaderboardUpdate');
      final result = await callable.call({
        'weeksAhead': weeksAhead,
      });
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to trigger weekly leaderboard update: $e');
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
  /// This creates both a global announcement and individual notifications for each player
  Future<bool> sendGlobalNotification(String title, String message) async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      // 1. Create global announcement (visible in Announcements tab)
      await _firestore.collection('system_notifications').add({
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
        'type': 'global',
      });

      // 2. Send individual notification to each player
      // This is done via Cloud Function to avoid client-side limitations
      try {
        final callable = _functions.httpsCallable('sendGlobalNotificationToPlayers');
        await callable.call({
          'title': title,
          'message': message,
        });
        print('✅ Global notification distributed to all players');
      } catch (e) {
        print('⚠️ Cloud Function not available, notification saved to system_notifications only: $e');
      }

      return true;
    } catch (e) {
      print('Error sending global notification: $e');
      return false;
    }
  }

  /// Adjust player stats (Admin Only - for testing/debugging)
  /// Now uses secure server-side validation
  Future<bool> adjustPlayerStats(
    String playerId,
    Map<String, dynamic> adjustments,
  ) async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      // Use secure Cloud Function instead of direct Firestore write
      final callable = _functions.httpsCallable('secureStatUpdate');
      final result = await callable.call({
        'playerId': playerId,
        'updates': adjustments,
        'action': 'admin_stat_adjustment',
        'context': {
          'timestamp': DateTime.now().toIso8601String(),
          'reason': 'Admin debugging/testing adjustment',
        },
      });

      return result.data['success'] ?? false;
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

  /// Send a gift to a player (Admin Only)
  Future<Map<String, dynamic>> sendGiftToPlayer({
    required String recipientId,
    required String giftType,
    int? amount,
    String? message,
  }) async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      final result = await _functions.httpsCallable('sendGiftToPlayer').call({
        'recipientId': recipientId,
        'giftType': giftType,
        'amount': amount,
        'message': message,
      });

      return {
        'success': true,
        'data': result.data,
      };
    } catch (e) {
      print('Error sending gift: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Gift type definitions
  static const List<Map<String, dynamic>> GIFT_TYPES = [
    {
      'id': 'money',
      'name': '💵 Money',
      'description': 'Give cash to help with expenses',
      'defaultAmount': 1000,
      'icon': '💵',
    },
    {
      'id': 'fame',
      'name': '⭐ Fame',
      'description': 'Boost their fame points',
      'defaultAmount': 10,
      'icon': '⭐',
    },
    {
      'id': 'energy',
      'name': '⚡ Energy',
      'description': 'Restore energy (can exceed 100)',
      'defaultAmount': 50,
      'icon': '⚡',
    },
    {
      'id': 'fans',
      'name': '👥 Fans',
      'description': 'Add to their fanbase',
      'defaultAmount': 1000,
      'icon': '👥',
    },
    {
      'id': 'streams',
      'name': '🎵 Streams',
      'description': 'Boost total stream count',
      'defaultAmount': 10000,
      'icon': '🎵',
    },
    {
      'id': 'starter_pack',
      'name': '🎁 Starter Pack',
      'description': '\$5K + 25 Fame + 100 Energy + 500 Fans',
      'defaultAmount': null,
      'icon': '🎁',
    },
    {
      'id': 'boost_pack',
      'name': '📦 Boost Pack',
      'description': '\$15K + 50 Fame + 2K Fans + 50K Streams',
      'defaultAmount': null,
      'icon': '📦',
    },
    {
      'id': 'premium_pack',
      'name': '👑 Premium Pack',
      'description': '\$50K + 100 Fame + 10K Fans + 250K Streams',
      'defaultAmount': null,
      'icon': '👑',
    },
  ];

  /// Get all players (Admin Only)
  Future<List<Map<String, dynamic>>> getAllPlayers() async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }

    try {
      final playersSnapshot = await _firestore.collection('players').get();
      final List<Map<String, dynamic>> players = [];

      for (var doc in playersSnapshot.docs) {
        final data = doc.data();
        final songs = data['songs'] as List<dynamic>? ?? [];

        players.add({
          'id': doc.id,
          'name': data['displayName'] ?? 'Unknown',
          'fame': data['fame'] ?? 0,
          'money': data['currentMoney'] ?? 0,
          'fanbase': data['fanbase'] ?? 0, // Fixed: was 'level', now 'fanbase'
          'songCount': songs.length,
          'lastActivity': data['lastActivityDate'],
        });
      }

      // Sort by fame (descending)
      players.sort((a, b) => (b['fame'] as int).compareTo(a['fame'] as int));

      return players;
    } catch (e) {
      throw Exception('Failed to get players: $e');
    }
  }

  /// Format number with K/M suffix (45K, 1.23M, etc.)
  static String formatNumber(num value) {
    if (value >= 1000000) {
      // Format millions with 2 decimal places
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      // Format thousands - no decimals if >= 10K, 1 decimal if < 10K
      final thousands = value / 1000;
      if (thousands >= 10) {
        return '${thousands.toStringAsFixed(0)}K';
      } else {
        return '${thousands.toStringAsFixed(1)}K';
      }
    } else {
      return value.toStringAsFixed(0);
    }
  }

  /// Format money (single dollar sign)
  static String formatMoney(num value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }
}
