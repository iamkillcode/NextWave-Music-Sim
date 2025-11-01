import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a collaboration between two players
class Collaboration {
  final String id;
  final String songId; // ID of the collaborative song
  final String primaryArtistId; // Player who initiated/owns the song
  final String primaryArtistName;
  final String featuringArtistId; // Collaborating player
  final String featuringArtistName;
  final String? featuringArtistAvatar; // Avatar URL of featuring artist
  final CollaborationStatus status;
  final CollaborationType type; // written, remote, in_person
  final DateTime createdDate;
  final DateTime? acceptedDate;
  final DateTime? recordedDate; // When recording was completed
  final DateTime? releasedDate;
  final int? splitPercentage; // How much the featuring artist gets (20-50%)
  final int totalEarnings; // Total money earned from this collab
  final int primaryArtistEarnings; // What primary artist earned
  final int featuringArtistEarnings; // What featuring artist earned
  final String? primaryRegion; // Region of primary artist
  final String? featuringRegion; // Region of featuring artist
  final bool recordedTogether; // True if recorded in person (travel boost)
  final Map<String, dynamic> metadata;

  const Collaboration({
    required this.id,
    required this.songId,
    required this.primaryArtistId,
    required this.primaryArtistName,
    required this.featuringArtistId,
    required this.featuringArtistName,
    this.featuringArtistAvatar,
    this.status = CollaborationStatus.pending,
    this.type = CollaborationType.remote,
    required this.createdDate,
    this.acceptedDate,
    this.recordedDate,
    this.releasedDate,
    this.splitPercentage = 30,
    this.totalEarnings = 0,
    this.primaryArtistEarnings = 0,
    this.featuringArtistEarnings = 0,
    this.primaryRegion,
    this.featuringRegion,
    this.recordedTogether = false,
    this.metadata = const {},
  });

  Collaboration copyWith({
    String? id,
    String? songId,
    String? primaryArtistId,
    String? primaryArtistName,
    String? featuringArtistId,
    String? featuringArtistName,
    String? featuringArtistAvatar,
    CollaborationStatus? status,
    CollaborationType? type,
    DateTime? createdDate,
    DateTime? acceptedDate,
    DateTime? recordedDate,
    DateTime? releasedDate,
    int? splitPercentage,
    int? totalEarnings,
    int? primaryArtistEarnings,
    int? featuringArtistEarnings,
    String? primaryRegion,
    String? featuringRegion,
    bool? recordedTogether,
    Map<String, dynamic>? metadata,
  }) {
    return Collaboration(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      primaryArtistId: primaryArtistId ?? this.primaryArtistId,
      primaryArtistName: primaryArtistName ?? this.primaryArtistName,
      featuringArtistId: featuringArtistId ?? this.featuringArtistId,
      featuringArtistName: featuringArtistName ?? this.featuringArtistName,
      featuringArtistAvatar:
          featuringArtistAvatar ?? this.featuringArtistAvatar,
      status: status ?? this.status,
      type: type ?? this.type,
      createdDate: createdDate ?? this.createdDate,
      acceptedDate: acceptedDate ?? this.acceptedDate,
      recordedDate: recordedDate ?? this.recordedDate,
      releasedDate: releasedDate ?? this.releasedDate,
      splitPercentage: splitPercentage ?? this.splitPercentage,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      primaryArtistEarnings:
          primaryArtistEarnings ?? this.primaryArtistEarnings,
      featuringArtistEarnings:
          featuringArtistEarnings ?? this.featuringArtistEarnings,
      primaryRegion: primaryRegion ?? this.primaryRegion,
      featuringRegion: featuringRegion ?? this.featuringRegion,
      recordedTogether: recordedTogether ?? this.recordedTogether,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songId': songId,
      'primaryArtistId': primaryArtistId,
      'primaryArtistName': primaryArtistName,
      'featuringArtistId': featuringArtistId,
      'featuringArtistName': featuringArtistName,
      'featuringArtistAvatar': featuringArtistAvatar,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'createdDate': Timestamp.fromDate(createdDate),
      'acceptedDate':
          acceptedDate != null ? Timestamp.fromDate(acceptedDate!) : null,
      'recordedDate':
          recordedDate != null ? Timestamp.fromDate(recordedDate!) : null,
      'releasedDate':
          releasedDate != null ? Timestamp.fromDate(releasedDate!) : null,
      'splitPercentage': splitPercentage,
      'totalEarnings': totalEarnings,
      'primaryArtistEarnings': primaryArtistEarnings,
      'featuringArtistEarnings': featuringArtistEarnings,
      'primaryRegion': primaryRegion,
      'featuringRegion': featuringRegion,
      'recordedTogether': recordedTogether,
      'metadata': metadata,
    };
  }

  factory Collaboration.fromJson(Map<String, dynamic> json) {
    return Collaboration(
      id: json['id'] as String,
      songId: json['songId'] as String,
      primaryArtistId: json['primaryArtistId'] as String,
      primaryArtistName: json['primaryArtistName'] as String,
      featuringArtistId: json['featuringArtistId'] as String,
      featuringArtistName: json['featuringArtistName'] as String,
      featuringArtistAvatar: json['featuringArtistAvatar'] as String?,
      status: CollaborationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => CollaborationStatus.pending,
      ),
      type: CollaborationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => CollaborationType.remote,
      ),
      createdDate: (json['createdDate'] as Timestamp).toDate(),
      acceptedDate: json['acceptedDate'] != null
          ? (json['acceptedDate'] as Timestamp).toDate()
          : null,
      recordedDate: json['recordedDate'] != null
          ? (json['recordedDate'] as Timestamp).toDate()
          : null,
      releasedDate: json['releasedDate'] != null
          ? (json['releasedDate'] as Timestamp).toDate()
          : null,
      splitPercentage: json['splitPercentage'] as int? ?? 30,
      totalEarnings: json['totalEarnings'] as int? ?? 0,
      primaryArtistEarnings: json['primaryArtistEarnings'] as int? ?? 0,
      featuringArtistEarnings: json['featuringArtistEarnings'] as int? ?? 0,
      primaryRegion: json['primaryRegion'] as String?,
      featuringRegion: json['featuringRegion'] as String?,
      recordedTogether: json['recordedTogether'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Status of a collaboration
enum CollaborationStatus {
  pending, // Invitation sent via StarChat, awaiting response
  accepted, // Accepted, ready to record
  recording, // Currently recording (remote or together)
  recorded, // Recording complete, ready to release
  released, // Song released to public
  rejected, // Invitation declined
  cancelled, // Cancelled by primary artist
}

/// Type of collaboration
enum CollaborationType {
  written, // Collaborating on written song (not yet recorded)
  remote, // Recording separately, send via StarChat
  in_person, // Travel together to record (bonus boost)
}

/// Player artist data for displaying in collaboration search
class PlayerArtist {
  final String id;
  final String name;
  final String primaryGenre;
  final int fame;
  final int fanbase;
  final String currentRegion;
  final String? avatarUrl;
  final int songwritingSkill;
  final int compositionSkill;
  final bool isOnline; // Real-time online status
  final DateTime? lastActive;

  const PlayerArtist({
    required this.id,
    required this.name,
    required this.primaryGenre,
    required this.fame,
    required this.fanbase,
    required this.currentRegion,
    this.avatarUrl,
    this.songwritingSkill = 10,
    this.compositionSkill = 10,
    this.isOnline = false,
    this.lastActive,
  });

  factory PlayerArtist.fromJson(Map<String, dynamic> json) {
    return PlayerArtist(
      id: json['id'] as String,
      name: json['name'] as String? ??
          json['displayName'] as String? ??
          'Unknown',
      primaryGenre: json['primaryGenre'] as String? ?? 'Hip Hop',
      fame: json['currentFame'] as int? ?? json['fame'] as int? ?? 0,
      fanbase: json['fanbase'] as int? ?? 0,
      currentRegion: json['currentRegion'] as String? ?? 'usa',
      avatarUrl: json['avatarUrl'] as String?,
      songwritingSkill: json['songwritingSkill'] as int? ?? 10,
      compositionSkill: json['compositionSkill'] as int? ?? 10,
      isOnline: json['isOnline'] as bool? ?? false,
      lastActive: json['lastActive'] != null
          ? (json['lastActive'] is Timestamp
              ? (json['lastActive'] as Timestamp).toDate()
              : DateTime.tryParse(json['lastActive'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryGenre': primaryGenre,
      'fame': fame,
      'fanbase': fanbase,
      'currentRegion': currentRegion,
      'avatarUrl': avatarUrl,
      'songwritingSkill': songwritingSkill,
      'compositionSkill': compositionSkill,
      'isOnline': isOnline,
      'lastActive': lastActive?.toIso8601String(),
    };
  }
}
