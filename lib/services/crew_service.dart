import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crew.dart';

/// Service for managing music crews
class CrewService {
  static final CrewService _instance = CrewService._internal();
  factory CrewService() => _instance;
  CrewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Cost to create a crew
  static const int CREW_CREATION_COST = 5000000; // $5M

  /// Get current user's crew (if they're in one)
  Future<Crew?> getCurrentUserCrew() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Check if user has a crew
      final userDoc =
          await _firestore.collection('players').doc(currentUser.uid).get();
      final crewId = userDoc.data()?['crewId'] as String?;

      if (crewId == null) return null;

      // Get crew details
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return null;

      return Crew.fromJson(crewDoc.data()!);
    } catch (e) {
      print('Error getting current user crew: $e');
      return null;
    }
  }

  /// Stream current user's crew
  Stream<Crew?> streamCurrentUserCrew() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(null);

    return _firestore
        .collection('players')
        .doc(currentUser.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      final crewId = userDoc.data()?['crewId'] as String?;
      if (crewId == null) return null;

      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return null;

      return Crew.fromJson(crewDoc.data()!);
    });
  }

  /// Create a new crew ($5M cost)
  Future<Map<String, dynamic>> createCrew({
    required String name,
    String? bio,
    int maxMembers = 5,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      // Check if user already in a crew
      final userDoc =
          await _firestore.collection('players').doc(currentUser.uid).get();
      final userData = userDoc.data();

      if (userData?['crewId'] != null) {
        return {'success': false, 'error': 'Already in a crew'};
      }

      // Check if user has enough money
      final currentMoney = userData?['currentMoney'] as int? ?? 0;
      if (currentMoney < CREW_CREATION_COST) {
        return {
          'success': false,
          'error': 'Need \$5,000,000 to create a crew',
          'required': CREW_CREATION_COST,
          'current': currentMoney,
        };
      }

      // Deduct money
      await _firestore.collection('players').doc(currentUser.uid).update({
        'currentMoney': currentMoney - CREW_CREATION_COST,
      });

      // Create crew
      final crewId = _firestore.collection('crews').doc().id;

      final crew = Crew(
        id: crewId,
        name: name,
        bio: bio,
        createdDate: DateTime.now(),
        status: CrewStatus.active,
        leaderId: currentUser.uid,
        members: [
          CrewMember(
            userId: currentUser.uid,
            displayName: userData?['displayName'] ?? 'Leader',
            avatarUrl: userData?['avatarUrl'] as String?,
            role: CrewRole.leader,
            joinedDate: DateTime.now(),
            contributedMoney: CREW_CREATION_COST,
            isActive: true,
          ),
        ],
        maxMembers: maxMembers,
        revenueSplit: {currentUser.uid: 100},
        primaryGenre:
            userData?['primaryGenre'] ?? userData?['genre'] ?? 'Hip Hop',
      );

      await _firestore.collection('crews').doc(crewId).set(crew.toJson());

      // Update player's crew affiliation
      await _firestore.collection('players').doc(currentUser.uid).update({
        'crewId': crewId,
        'crewRole': 'leader',
      });

      return {
        'success': true,
        'crewId': crewId,
        'crew': crew,
      };
    } catch (e) {
      print('Error creating crew: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Invite a player to join the crew
  Future<bool> inviteToCrew({
    required String crewId,
    required String invitedUserId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get crew details
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if user has permission to invite (leader or manager)
      final userMember = crew.members.firstWhere(
        (m) => m.userId == currentUser.uid,
        orElse: () => throw Exception('Not a crew member'),
      );

      if (userMember.role != CrewRole.leader &&
          userMember.role != CrewRole.manager) {
        throw Exception('No permission to invite');
      }

      // Check if crew has space
      if (crew.members.length >= crew.maxMembers) {
        throw Exception('Crew is full');
      }

      // Check if invited user is already in a crew
      final invitedUserDoc =
          await _firestore.collection('players').doc(invitedUserId).get();
      if (invitedUserDoc.data()?['crewId'] != null) {
        throw Exception('User is already in a crew');
      }

      // Check if there's already a pending invite
      final existingInvites = await _firestore
          .collection('crew_invites')
          .where('crewId', isEqualTo: crewId)
          .where('invitedUserId', isEqualTo: invitedUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingInvites.docs.isNotEmpty) {
        throw Exception('Invite already sent');
      }

      // Create invite
      final inviteId = _firestore.collection('crew_invites').doc().id;
      final invite = CrewInvite(
        id: inviteId,
        crewId: crewId,
        crewName: crew.name,
        crewAvatar: crew.avatarUrl,
        invitedUserId: invitedUserId,
        invitedBy: currentUser.uid,
        invitedByName: userMember.displayName,
        sentDate: DateTime.now(),
        expiresDate: DateTime.now().add(const Duration(days: 7)),
        status: 'pending',
      );

      await _firestore
          .collection('crew_invites')
          .doc(inviteId)
          .set(invite.toJson());

      // Send StarChat notification
      await _firestore.collection('starchat_messages').add({
        'type': 'crew_invite',
        'fromUserId': currentUser.uid,
        'fromUserName': userMember.displayName,
        'toUserId': invitedUserId,
        'crewId': crewId,
        'crewName': crew.name,
        'crewAvatar': crew.avatarUrl,
        'inviteId': inviteId,
        'message': 'invited you to join ${crew.name}',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      return true;
    } catch (e) {
      print('Error inviting to crew: $e');
      return false;
    }
  }

  /// Accept crew invitation
  Future<bool> acceptCrewInvite(String inviteId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get invite
      final inviteDoc =
          await _firestore.collection('crew_invites').doc(inviteId).get();
      if (!inviteDoc.exists) return false;

      final invite = CrewInvite.fromJson(inviteDoc.data()!);

      // Check if invite is valid
      if (invite.status != 'pending') {
        throw Exception('Invite already processed');
      }
      if (invite.isExpired) {
        throw Exception('Invite expired');
      }
      if (invite.invitedUserId != currentUser.uid) {
        throw Exception('Not your invite');
      }

      // Check if user already in a crew
      final userDoc =
          await _firestore.collection('players').doc(currentUser.uid).get();
      if (userDoc.data()?['crewId'] != null) {
        throw Exception('Already in a crew');
      }

      // Get crew
      final crewDoc =
          await _firestore.collection('crews').doc(invite.crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if crew still has space
      if (crew.members.length >= crew.maxMembers) {
        throw Exception('Crew is now full');
      }

      // Add member to crew
      final newMember = CrewMember(
        userId: currentUser.uid,
        displayName: userDoc.data()?['displayName'] ?? 'Member',
        avatarUrl: userDoc.data()?['avatarUrl'] as String?,
        role: CrewRole.member,
        joinedDate: DateTime.now(),
        isActive: true,
      );

      final updatedMembers = [...crew.members, newMember];

      // Calculate equal revenue split
      final splitPercentage = (100 / updatedMembers.length).floor();
      final newRevenueSplit = <String, int>{};
      for (var member in updatedMembers) {
        newRevenueSplit[member.userId] = splitPercentage;
      }

      // Update crew
      await _firestore.collection('crews').doc(invite.crewId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'revenueSplit': newRevenueSplit,
        'crewFame': FieldValue.increment(userDoc.data()?['fame'] ?? 0),
      });

      // Update player
      await _firestore.collection('players').doc(currentUser.uid).update({
        'crewId': invite.crewId,
        'crewRole': 'member',
      });

      // Update invite status
      await _firestore.collection('crew_invites').doc(inviteId).update({
        'status': 'accepted',
      });

      return true;
    } catch (e) {
      print('Error accepting crew invite: $e');
      return false;
    }
  }

  /// Decline crew invitation
  Future<bool> declineCrewInvite(String inviteId) async {
    try {
      await _firestore.collection('crew_invites').doc(inviteId).update({
        'status': 'declined',
      });
      return true;
    } catch (e) {
      print('Error declining crew invite: $e');
      return false;
    }
  }

  /// Get pending invites for current user
  Stream<List<CrewInvite>> streamPendingInvites() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('crew_invites')
        .where('invitedUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('sentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CrewInvite.fromJson(doc.data()))
            .where((invite) => !invite.isExpired)
            .toList());
  }

  /// Leave crew
  Future<bool> leaveCrew(String crewId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get crew
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Can't leave if you're the leader and there are other members
      if (crew.leaderId == currentUser.uid && crew.members.length > 1) {
        throw Exception(
            'Leader must transfer leadership or kick all members before leaving');
      }

      // Remove member from crew
      final updatedMembers =
          crew.members.where((m) => m.userId != currentUser.uid).toList();

      if (updatedMembers.isEmpty) {
        // Last member leaving, disband crew
        await _firestore.collection('crews').doc(crewId).update({
          'status': 'disbanded',
        });
      } else {
        // Recalculate revenue split
        final splitPercentage = (100 / updatedMembers.length).floor();
        final newRevenueSplit = <String, int>{};
        for (var member in updatedMembers) {
          newRevenueSplit[member.userId] = splitPercentage;
        }

        await _firestore.collection('crews').doc(crewId).update({
          'members': updatedMembers.map((m) => m.toJson()).toList(),
          'revenueSplit': newRevenueSplit,
        });
      }

      // Update player
      await _firestore.collection('players').doc(currentUser.uid).update({
        'crewId': FieldValue.delete(),
        'crewRole': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      print('Error leaving crew: $e');
      return false;
    }
  }

  /// Kick member from crew (leader only)
  Future<bool> kickMember({
    required String crewId,
    required String memberUserId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get crew
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if current user is the leader
      if (crew.leaderId != currentUser.uid) {
        throw Exception('Only the leader can kick members');
      }

      // Can't kick yourself
      if (memberUserId == currentUser.uid) {
        throw Exception('Cannot kick yourself');
      }

      // Remove member
      final updatedMembers =
          crew.members.where((m) => m.userId != memberUserId).toList();

      // Recalculate revenue split
      final splitPercentage = (100 / updatedMembers.length).floor();
      final newRevenueSplit = <String, int>{};
      for (var member in updatedMembers) {
        newRevenueSplit[member.userId] = splitPercentage;
      }

      await _firestore.collection('crews').doc(crewId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'revenueSplit': newRevenueSplit,
      });

      // Update kicked player
      await _firestore.collection('players').doc(memberUserId).update({
        'crewId': FieldValue.delete(),
        'crewRole': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      print('Error kicking member: $e');
      return false;
    }
  }

  /// Get crew by ID
  Future<Crew?> getCrewById(String crewId) async {
    try {
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return null;
      return Crew.fromJson(crewDoc.data()!);
    } catch (e) {
      print('Error getting crew: $e');
      return null;
    }
  }

  /// Search for crews
  Future<List<Crew>> searchCrews({
    String? query,
    String? genre,
    int limit = 20,
  }) async {
    try {
      Query crewQuery = _firestore
          .collection('crews')
          .where('status', isEqualTo: 'active')
          .limit(limit);

      if (genre != null && genre != 'All') {
        crewQuery = crewQuery.where('primaryGenre', isEqualTo: genre);
      }

      final snapshot = await crewQuery.get();

      var crews = snapshot.docs
          .map((doc) => Crew.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by name if query provided
      if (query != null && query.trim().isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        crews = crews
            .where((crew) => crew.name.toLowerCase().contains(lowerQuery))
            .toList();
      }

      return crews;
    } catch (e) {
      print('Error searching crews: $e');
      return [];
    }
  }

  /// Contribute money to crew's shared bank
  Future<bool> contributeToBank({
    required String crewId,
    required int amount,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      if (amount <= 0) {
        throw Exception('Amount must be positive');
      }

      // Check if user has enough money
      final userDoc =
          await _firestore.collection('players').doc(currentUser.uid).get();
      final currentMoney = userDoc.data()?['currentMoney'] as int? ?? 0;

      if (currentMoney < amount) {
        throw Exception('Insufficient funds');
      }

      // Get crew to find member
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if user is a member
      final memberIndex =
          crew.members.indexWhere((m) => m.userId == currentUser.uid);
      if (memberIndex == -1) {
        throw Exception('Not a crew member');
      }

      // Update member's contributed amount
      final updatedMembers = [...crew.members];
      updatedMembers[memberIndex] = updatedMembers[memberIndex].copyWith(
        contributedMoney: updatedMembers[memberIndex].contributedMoney + amount,
      );

      // Deduct from user
      await _firestore.collection('players').doc(currentUser.uid).update({
        'currentMoney': currentMoney - amount,
      });

      // Add to crew bank
      await _firestore.collection('crews').doc(crewId).update({
        'sharedBank': FieldValue.increment(amount),
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      });

      return true;
    } catch (e) {
      print('Error contributing to bank: $e');
      return false;
    }
  }

  /// Withdraw money from crew's shared bank
  Future<bool> withdrawFromBank({
    required String crewId,
    required int amount,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      if (amount <= 0) {
        throw Exception('Amount must be positive');
      }

      // Get crew
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if user has permission (leader or manager)
      final member = crew.members.firstWhere(
        (m) => m.userId == currentUser.uid,
        orElse: () => throw Exception('Not a crew member'),
      );

      if (member.role != CrewRole.leader && member.role != CrewRole.manager) {
        throw Exception('Only leaders and managers can withdraw');
      }

      // Check if crew has enough money
      if (crew.sharedBank < amount) {
        throw Exception('Insufficient funds in shared bank');
      }

      // Get user's current money
      final userDoc =
          await _firestore.collection('players').doc(currentUser.uid).get();
      final currentMoney = userDoc.data()?['currentMoney'] as int? ?? 0;

      // Deduct from crew bank
      await _firestore.collection('crews').doc(crewId).update({
        'sharedBank': crew.sharedBank - amount,
      });

      // Add to user
      await _firestore.collection('players').doc(currentUser.uid).update({
        'currentMoney': currentMoney + amount,
      });

      return true;
    } catch (e) {
      print('Error withdrawing from bank: $e');
      return false;
    }
  }

  /// Update crew settings (leader only)
  Future<bool> updateCrewSettings({
    required String crewId,
    bool? autoDistributeRevenue,
    int? minimumReleaseVotes,
    bool? allowSoloProjects,
    String? bio,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get crew
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if user is the leader
      if (crew.leaderId != currentUser.uid) {
        throw Exception('Only the leader can update settings');
      }

      final updates = <String, dynamic>{};

      if (autoDistributeRevenue != null) {
        updates['autoDistributeRevenue'] = autoDistributeRevenue;
      }

      if (minimumReleaseVotes != null) {
        if (minimumReleaseVotes < 1 || minimumReleaseVotes > 5) {
          throw Exception('Minimum votes must be between 1 and 5');
        }
        updates['minimumReleaseVotes'] = minimumReleaseVotes;
      }

      if (allowSoloProjects != null) {
        updates['allowSoloProjects'] = allowSoloProjects;
      }

      if (bio != null) {
        updates['bio'] = bio;
      }

      if (updates.isEmpty) return true;

      await _firestore.collection('crews').doc(crewId).update(updates);
      return true;
    } catch (e) {
      print('Error updating crew settings: $e');
      return false;
    }
  }

  /// Upload crew symbol/logo (leader only)
  /// Returns true if successful, false otherwise
  Future<bool> uploadCrewSymbol({
    required String crewId,
    required String symbolUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get crew
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if user is the leader
      if (crew.leaderId != currentUser.uid) {
        throw Exception('Only the leader can update the crew symbol');
      }

      // Update the avatarUrl field
      await _firestore.collection('crews').doc(crewId).update({
        'avatarUrl': symbolUrl,
      });

      print('✅ Crew symbol updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating crew symbol: $e');
      return false;
    }
  }

  /// Update custom revenue split (leader only)
  Future<bool> updateRevenueSplit({
    required String crewId,
    required Map<String, int> newSplit,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Validate split adds up to 100
      final totalSplit = newSplit.values.fold(0, (sum, val) => sum + val);
      if (totalSplit != 100) {
        throw Exception(
            'Revenue split must total 100% (currently $totalSplit%)');
      }

      // Get crew
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if user is the leader
      if (crew.leaderId != currentUser.uid) {
        throw Exception('Only the leader can update revenue split');
      }

      // Verify all members are in the split
      for (var member in crew.members) {
        if (!newSplit.containsKey(member.userId)) {
          throw Exception('All members must have a split percentage');
        }
      }

      await _firestore.collection('crews').doc(crewId).update({
        'revenueSplit': newSplit,
      });

      return true;
    } catch (e) {
      print('Error updating revenue split: $e');
      return false;
    }
  }

  /// Transfer leadership to another member
  Future<bool> transferLeadership({
    required String crewId,
    required String newLeaderId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get crew
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if current user is the leader
      if (crew.leaderId != currentUser.uid) {
        throw Exception('Only the leader can transfer leadership');
      }

      // Check if new leader is a member
      final newLeaderIndex =
          crew.members.indexWhere((m) => m.userId == newLeaderId);
      if (newLeaderIndex == -1) {
        throw Exception('New leader must be a crew member');
      }

      final currentLeaderIndex =
          crew.members.indexWhere((m) => m.userId == currentUser.uid);

      // Update roles
      final updatedMembers = [...crew.members];
      updatedMembers[newLeaderIndex] =
          updatedMembers[newLeaderIndex].copyWith(role: CrewRole.leader);
      updatedMembers[currentLeaderIndex] =
          updatedMembers[currentLeaderIndex].copyWith(role: CrewRole.member);

      // Update crew
      await _firestore.collection('crews').doc(crewId).update({
        'leaderId': newLeaderId,
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      });

      // Update player documents
      await _firestore.collection('players').doc(newLeaderId).update({
        'crewRole': 'leader',
      });

      await _firestore.collection('players').doc(currentUser.uid).update({
        'crewRole': 'member',
      });

      return true;
    } catch (e) {
      print('Error transferring leadership: $e');
      return false;
    }
  }

  /// Promote member to manager (leader only)
  Future<bool> promoteMember({
    required String crewId,
    required String memberId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get crew
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if current user is the leader
      if (crew.leaderId != currentUser.uid) {
        throw Exception('Only the leader can promote members');
      }

      // Find member
      final memberIndex = crew.members.indexWhere((m) => m.userId == memberId);
      if (memberIndex == -1) {
        throw Exception('Member not found');
      }

      // Update role
      final updatedMembers = [...crew.members];
      updatedMembers[memberIndex] =
          updatedMembers[memberIndex].copyWith(role: CrewRole.manager);

      await _firestore.collection('crews').doc(crewId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      });

      await _firestore.collection('players').doc(memberId).update({
        'crewRole': 'manager',
      });

      return true;
    } catch (e) {
      print('Error promoting member: $e');
      return false;
    }
  }

  /// Demote manager to member (leader only)
  Future<bool> demoteMember({
    required String crewId,
    required String memberId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get crew
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crew = Crew.fromJson(crewDoc.data()!);

      // Check if current user is the leader
      if (crew.leaderId != currentUser.uid) {
        throw Exception('Only the leader can demote members');
      }

      // Find member
      final memberIndex = crew.members.indexWhere((m) => m.userId == memberId);
      if (memberIndex == -1) {
        throw Exception('Member not found');
      }

      // Update role
      final updatedMembers = [...crew.members];
      updatedMembers[memberIndex] =
          updatedMembers[memberIndex].copyWith(role: CrewRole.member);

      await _firestore.collection('crews').doc(crewId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
      });

      await _firestore.collection('players').doc(memberId).update({
        'crewRole': 'member',
      });

      return true;
    } catch (e) {
      print('Error demoting member: $e');
      return false;
    }
  }
}
