import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a crew
enum CrewStatus {
  active,
  disbanded,
  onHiatus,
}

/// Role of a crew member
enum CrewRole {
  leader, // Founder, can invite/kick, manage settings
  member, // Regular member
  manager, // Can manage finances, but not kick members
}

/// Represents a music crew (group/band)
class Crew {
  final String id;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdDate;
  final CrewStatus status;

  // Members
  final String leaderId;
  final List<CrewMember> members;
  final int maxMembers; // Default 5, can upgrade

  // Financial
  final int sharedBank; // Pooled money
  final int totalEarnings; // Lifetime earnings
  final Map<String, int> revenueSplit; // userId -> percentage

  // Stats
  final int totalSongsReleased;
  final int totalStreams;
  final int crewFame; // Combined fame score
  final String primaryGenre;

  // Settings
  final bool autoDistributeRevenue; // Split earnings automatically
  final int minimumReleaseVotes; // How many must approve a release
  final bool allowSoloProjects; // Can members release solo while in crew

  final Map<String, dynamic> metadata;

  const Crew({
    required this.id,
    required this.name,
    this.bio,
    this.avatarUrl,
    required this.createdDate,
    this.status = CrewStatus.active,
    required this.leaderId,
    required this.members,
    this.maxMembers = 5,
    this.sharedBank = 0,
    this.totalEarnings = 0,
    this.revenueSplit = const {},
    this.totalSongsReleased = 0,
    this.totalStreams = 0,
    this.crewFame = 0,
    this.primaryGenre = 'Hip Hop',
    this.autoDistributeRevenue = true,
    this.minimumReleaseVotes = 1,
    this.allowSoloProjects = true,
    this.metadata = const {},
  });

  Crew copyWith({
    String? id,
    String? name,
    String? bio,
    String? avatarUrl,
    DateTime? createdDate,
    CrewStatus? status,
    String? leaderId,
    List<CrewMember>? members,
    int? maxMembers,
    int? sharedBank,
    int? totalEarnings,
    Map<String, int>? revenueSplit,
    int? totalSongsReleased,
    int? totalStreams,
    int? crewFame,
    String? primaryGenre,
    bool? autoDistributeRevenue,
    int? minimumReleaseVotes,
    bool? allowSoloProjects,
    Map<String, dynamic>? metadata,
  }) {
    return Crew(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      leaderId: leaderId ?? this.leaderId,
      members: members ?? this.members,
      maxMembers: maxMembers ?? this.maxMembers,
      sharedBank: sharedBank ?? this.sharedBank,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      revenueSplit: revenueSplit ?? this.revenueSplit,
      totalSongsReleased: totalSongsReleased ?? this.totalSongsReleased,
      totalStreams: totalStreams ?? this.totalStreams,
      crewFame: crewFame ?? this.crewFame,
      primaryGenre: primaryGenre ?? this.primaryGenre,
      autoDistributeRevenue:
          autoDistributeRevenue ?? this.autoDistributeRevenue,
      minimumReleaseVotes: minimumReleaseVotes ?? this.minimumReleaseVotes,
      allowSoloProjects: allowSoloProjects ?? this.allowSoloProjects,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'createdDate': Timestamp.fromDate(createdDate),
      'status': status.toString().split('.').last,
      'leaderId': leaderId,
      'members': members.map((m) => m.toJson()).toList(),
      'maxMembers': maxMembers,
      'sharedBank': sharedBank,
      'totalEarnings': totalEarnings,
      'revenueSplit': revenueSplit,
      'totalSongsReleased': totalSongsReleased,
      'totalStreams': totalStreams,
      'crewFame': crewFame,
      'primaryGenre': primaryGenre,
      'autoDistributeRevenue': autoDistributeRevenue,
      'minimumReleaseVotes': minimumReleaseVotes,
      'allowSoloProjects': allowSoloProjects,
      'metadata': metadata,
    };
  }

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      id: json['id'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdDate: (json['createdDate'] as Timestamp).toDate(),
      status: CrewStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => CrewStatus.active,
      ),
      leaderId: json['leaderId'] as String,
      members: (json['members'] as List?)
              ?.map((m) => CrewMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      maxMembers: json['maxMembers'] as int? ?? 5,
      sharedBank: json['sharedBank'] as int? ?? 0,
      totalEarnings: json['totalEarnings'] as int? ?? 0,
      revenueSplit: Map<String, int>.from(json['revenueSplit'] as Map? ?? {}),
      totalSongsReleased: json['totalSongsReleased'] as int? ?? 0,
      totalStreams: json['totalStreams'] as int? ?? 0,
      crewFame: json['crewFame'] as int? ?? 0,
      primaryGenre: json['primaryGenre'] as String? ?? 'Hip Hop',
      autoDistributeRevenue: json['autoDistributeRevenue'] as bool? ?? true,
      minimumReleaseVotes: json['minimumReleaseVotes'] as int? ?? 1,
      allowSoloProjects: json['allowSoloProjects'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Member of a crew
class CrewMember {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final CrewRole role;
  final DateTime joinedDate;
  final int contributedSongs; // Songs they've worked on
  final int contributedMoney; // Money they've added to bank
  final bool isActive; // Online status

  const CrewMember({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedDate,
    this.contributedSongs = 0,
    this.contributedMoney = 0,
    this.isActive = false,
  });

  CrewMember copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    CrewRole? role,
    DateTime? joinedDate,
    int? contributedSongs,
    int? contributedMoney,
    bool? isActive,
  }) {
    return CrewMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedDate: joinedDate ?? this.joinedDate,
      contributedSongs: contributedSongs ?? this.contributedSongs,
      contributedMoney: contributedMoney ?? this.contributedMoney,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role.toString().split('.').last,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'contributedSongs': contributedSongs,
      'contributedMoney': contributedMoney,
      'isActive': isActive,
    };
  }

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: CrewRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => CrewRole.member,
      ),
      joinedDate: (json['joinedDate'] as Timestamp).toDate(),
      contributedSongs: json['contributedSongs'] as int? ?? 0,
      contributedMoney: json['contributedMoney'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

/// Crew song project
class CrewSong {
  final String id;
  final String songId; // Links to regular song
  final String crewId;
  final List<String> contributingMembers; // User IDs
  final Map<String, int> creditSplit; // userId -> contribution %
  final DateTime createdDate;
  final String status; // 'writing', 'recording', 'released'
  final int votesNeeded;
  final List<String> approvedBy; // Member IDs who approved release

  const CrewSong({
    required this.id,
    required this.songId,
    required this.crewId,
    required this.contributingMembers,
    required this.creditSplit,
    required this.createdDate,
    this.status = 'writing',
    this.votesNeeded = 1,
    this.approvedBy = const [],
  });

  CrewSong copyWith({
    String? id,
    String? songId,
    String? crewId,
    List<String>? contributingMembers,
    Map<String, int>? creditSplit,
    DateTime? createdDate,
    String? status,
    int? votesNeeded,
    List<String>? approvedBy,
  }) {
    return CrewSong(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      crewId: crewId ?? this.crewId,
      contributingMembers: contributingMembers ?? this.contributingMembers,
      creditSplit: creditSplit ?? this.creditSplit,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      votesNeeded: votesNeeded ?? this.votesNeeded,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songId': songId,
      'crewId': crewId,
      'contributingMembers': contributingMembers,
      'creditSplit': creditSplit,
      'createdDate': Timestamp.fromDate(createdDate),
      'status': status,
      'votesNeeded': votesNeeded,
      'approvedBy': approvedBy,
    };
  }

  factory CrewSong.fromJson(Map<String, dynamic> json) {
    return CrewSong(
      id: json['id'] as String,
      songId: json['songId'] as String,
      crewId: json['crewId'] as String,
      contributingMembers:
          List<String>.from(json['contributingMembers'] as List? ?? []),
      creditSplit: Map<String, int>.from(json['creditSplit'] as Map? ?? {}),
      createdDate: (json['createdDate'] as Timestamp).toDate(),
      status: json['status'] as String? ?? 'writing',
      votesNeeded: json['votesNeeded'] as int? ?? 1,
      approvedBy: List<String>.from(json['approvedBy'] as List? ?? []),
    );
  }

  bool get hasEnoughVotes => approvedBy.length >= votesNeeded;
}

/// Crew invitation
class CrewInvite {
  final String id;
  final String crewId;
  final String crewName;
  final String? crewAvatar;
  final String invitedUserId;
  final String invitedBy;
  final String invitedByName;
  final DateTime sentDate;
  final DateTime? expiresDate;
  final String status; // 'pending', 'accepted', 'declined', 'expired'

  const CrewInvite({
    required this.id,
    required this.crewId,
    required this.crewName,
    this.crewAvatar,
    required this.invitedUserId,
    required this.invitedBy,
    required this.invitedByName,
    required this.sentDate,
    this.expiresDate,
    this.status = 'pending',
  });

  CrewInvite copyWith({
    String? id,
    String? crewId,
    String? crewName,
    String? crewAvatar,
    String? invitedUserId,
    String? invitedBy,
    String? invitedByName,
    DateTime? sentDate,
    DateTime? expiresDate,
    String? status,
  }) {
    return CrewInvite(
      id: id ?? this.id,
      crewId: crewId ?? this.crewId,
      crewName: crewName ?? this.crewName,
      crewAvatar: crewAvatar ?? this.crewAvatar,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedByName: invitedByName ?? this.invitedByName,
      sentDate: sentDate ?? this.sentDate,
      expiresDate: expiresDate ?? this.expiresDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crewId': crewId,
      'crewName': crewName,
      'crewAvatar': crewAvatar,
      'invitedUserId': invitedUserId,
      'invitedBy': invitedBy,
      'invitedByName': invitedByName,
      'sentDate': Timestamp.fromDate(sentDate),
      'expiresDate':
          expiresDate != null ? Timestamp.fromDate(expiresDate!) : null,
      'status': status,
    };
  }

  factory CrewInvite.fromJson(Map<String, dynamic> json) {
    return CrewInvite(
      id: json['id'] as String,
      crewId: json['crewId'] as String,
      crewName: json['crewName'] as String,
      crewAvatar: json['crewAvatar'] as String?,
      invitedUserId: json['invitedUserId'] as String,
      invitedBy: json['invitedBy'] as String,
      invitedByName: json['invitedByName'] as String,
      sentDate: (json['sentDate'] as Timestamp).toDate(),
      expiresDate: json['expiresDate'] != null
          ? (json['expiresDate'] as Timestamp).toDate()
          : null,
      status: json['status'] as String? ?? 'pending',
    );
  }

  bool get isExpired {
    if (expiresDate == null) return false;
    return DateTime.now().isAfter(expiresDate!);
  }

  bool get isPending => status == 'pending' && !isExpired;
}
