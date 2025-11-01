import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a beef/feud between two artists
class Beef {
  final String id;
  final String instigatorId;
  final String targetId;
  final String instigatorName;
  final String targetName;
  final DateTime startedAt;
  final DateTime? resolvedAt;
  final BeefStatus status;
  final BeefType type;
  final String? dissTrackId; // Song ID of the diss track
  final String? dissTrackTitle;
  final String? responseDissTrackId; // Target's response track
  final String? responseDissTrackTitle;
  final int instigatorStreams; // Diss track streams
  final int targetStreams; // Response track streams
  final int instigatorFameGain;
  final int targetFameGain;
  final bool targetResponded; // True if target dropped a response
  final int instigatorFame; // Fame at time of beef start
  final int targetFame; // Fame at time of beef start
  final List<BeefResponse> responses;
  final Map<String, dynamic> metadata;

  Beef({
    required this.id,
    required this.instigatorId,
    required this.targetId,
    required this.instigatorName,
    required this.targetName,
    required this.startedAt,
    this.resolvedAt,
    required this.status,
    required this.type,
    this.dissTrackId,
    this.dissTrackTitle,
    this.responseDissTrackId,
    this.responseDissTrackTitle,
    this.instigatorStreams = 0,
    this.targetStreams = 0,
    this.instigatorFameGain = 0,
    this.targetFameGain = 0,
    this.targetResponded = false,
    this.instigatorFame = 0,
    this.targetFame = 0,
    this.responses = const [],
    this.metadata = const {},
  });

  factory Beef.fromJson(Map<String, dynamic> json) {
    return Beef(
      id: json['id'] as String,
      instigatorId: json['instigatorId'] as String,
      targetId: json['targetId'] as String,
      instigatorName: json['instigatorName'] as String,
      targetName: json['targetName'] as String,
      startedAt: (json['startedAt'] as Timestamp).toDate(),
      resolvedAt: json['resolvedAt'] != null
          ? (json['resolvedAt'] as Timestamp).toDate()
          : null,
      status: BeefStatus.values.firstWhere(
        (e) => e.toString() == 'BeefStatus.${json['status']}',
        orElse: () => BeefStatus.active,
      ),
      type: BeefType.values.firstWhere(
        (e) => e.toString() == 'BeefType.${json['type']}',
        orElse: () => BeefType.dissTrack,
      ),
      dissTrackId: json['dissTrackId'] as String?,
      dissTrackTitle: json['dissTrackTitle'] as String?,
      responseDissTrackId: json['responseDissTrackId'] as String?,
      responseDissTrackTitle: json['responseDissTrackTitle'] as String?,
      instigatorStreams: json['instigatorStreams'] as int? ?? 0,
      targetStreams: json['targetStreams'] as int? ?? 0,
      instigatorFameGain: json['instigatorFameGain'] as int? ?? 0,
      targetFameGain: json['targetFameGain'] as int? ?? 0,
      targetResponded: json['targetResponded'] as bool? ?? false,
      instigatorFame: json['instigatorFame'] as int? ?? 0,
      targetFame: json['targetFame'] as int? ?? 0,
      responses: (json['responses'] as List<dynamic>?)
              ?.map((r) => BeefResponse.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instigatorId': instigatorId,
      'targetId': targetId,
      'instigatorName': instigatorName,
      'targetName': targetName,
      'startedAt': Timestamp.fromDate(startedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'status': status.name,
      'type': type.name,
      'dissTrackId': dissTrackId,
      'dissTrackTitle': dissTrackTitle,
      'responseDissTrackId': responseDissTrackId,
      'responseDissTrackTitle': responseDissTrackTitle,
      'instigatorStreams': instigatorStreams,
      'targetStreams': targetStreams,
      'instigatorFameGain': instigatorFameGain,
      'targetFameGain': targetFameGain,
      'targetResponded': targetResponded,
      'instigatorFame': instigatorFame,
      'targetFame': targetFame,
      'responses': responses.map((r) => r.toJson()).toList(),
      'metadata': metadata,
    };
  }

  Beef copyWith({
    String? id,
    String? instigatorId,
    String? targetId,
    String? instigatorName,
    String? targetName,
    DateTime? startedAt,
    DateTime? resolvedAt,
    BeefStatus? status,
    BeefType? type,
    String? dissTrackId,
    String? dissTrackTitle,
    String? responseDissTrackId,
    String? responseDissTrackTitle,
    int? instigatorStreams,
    int? targetStreams,
    int? instigatorFameGain,
    int? targetFameGain,
    bool? targetResponded,
    int? instigatorFame,
    int? targetFame,
    List<BeefResponse>? responses,
    Map<String, dynamic>? metadata,
  }) {
    return Beef(
      id: id ?? this.id,
      instigatorId: instigatorId ?? this.instigatorId,
      targetId: targetId ?? this.targetId,
      instigatorName: instigatorName ?? this.instigatorName,
      targetName: targetName ?? this.targetName,
      startedAt: startedAt ?? this.startedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      status: status ?? this.status,
      type: type ?? this.type,
      dissTrackId: dissTrackId ?? this.dissTrackId,
      dissTrackTitle: dissTrackTitle ?? this.dissTrackTitle,
      responseDissTrackId: responseDissTrackId ?? this.responseDissTrackId,
      responseDissTrackTitle:
          responseDissTrackTitle ?? this.responseDissTrackTitle,
      instigatorStreams: instigatorStreams ?? this.instigatorStreams,
      targetStreams: targetStreams ?? this.targetStreams,
      instigatorFameGain: instigatorFameGain ?? this.instigatorFameGain,
      targetFameGain: targetFameGain ?? this.targetFameGain,
      targetResponded: targetResponded ?? this.targetResponded,
      instigatorFame: instigatorFame ?? this.instigatorFame,
      targetFame: targetFame ?? this.targetFame,
      responses: responses ?? this.responses,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Calculate potential fame gain for instigator
  /// High multiplier only if target has MORE fame and responds
  int calculateInstigatorFameBonus() {
    const baseBoost = 50;

    // If target hasn't responded, minimal fame
    if (!targetResponded) {
      return baseBoost ~/ 2; // 25 fame only
    }

    // Target responded - check if they have more fame
    if (targetFame <= instigatorFame) {
      // Target has less/equal fame - moderate boost
      return baseBoost;
    }

    // Target has MORE fame AND responded - HIGH multiplier!
    final fameDifferenceMultiplier =
        1 + ((targetFame - instigatorFame) / 500).clamp(0, 3);
    final streamMultiplier = instigatorStreams > 0
        ? (1 + (instigatorStreams / 10000)).clamp(1, 2)
        : 1.0;

    return (baseBoost * fameDifferenceMultiplier * streamMultiplier).toInt();
  }

  /// Calculate fame gain for target
  int calculateTargetFameBonus() {
    if (!targetResponded) return 0;

    const baseBoost = 50;
    final streamMultiplier =
        targetStreams > 0 ? (1 + (targetStreams / 10000)).clamp(1, 2) : 1.0;

    // Target always gets decent fame for responding to beef
    return (baseBoost * 1.5 * streamMultiplier).toInt();
  }

  /// Check if beef is ready for auto-resolution (42 in-game days)
  /// 42 in-game days = 42 * 2 real hours = 84 hours
  bool isReadyForResolution() {
    if (status != BeefStatus.active) return false;

    const resolutionPeriod = Duration(hours: 84); // 42 in-game days
    final timeSinceStart = DateTime.now().difference(startedAt);

    return timeSinceStart >= resolutionPeriod;
  }

  /// Get remaining time until beef auto-resolves
  Duration? getTimeUntilResolution() {
    if (status != BeefStatus.active) return null;

    const resolutionPeriod = Duration(hours: 84); // 42 in-game days
    final timeSinceStart = DateTime.now().difference(startedAt);
    final remaining = resolutionPeriod - timeSinceStart;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Format remaining time as "X days Y hours"
  String getFormattedTimeRemaining() {
    final remaining = getTimeUntilResolution();
    if (remaining == null) return 'Resolved';
    if (remaining == Duration.zero) return 'Ready to resolve';

    final days = remaining.inHours ~/ 2; // Convert real hours to in-game days
    final hours = remaining.inHours % 2;

    if (days > 0) {
      return '$days days ${hours > 0 ? "$hours hours" : ""}';
    } else {
      return '${remaining.inHours} hours';
    }
  }
}

/// Response to a beef (social media, track, etc)
class BeefResponse {
  final String id;
  final String authorId;
  final String authorName;
  final ResponseType type;
  final String? trackId;
  final String? trackTitle;
  final String? content; // For social media responses
  final DateTime timestamp;
  final int streams;
  final int fameGain;

  BeefResponse({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.type,
    this.trackId,
    this.trackTitle,
    this.content,
    required this.timestamp,
    this.streams = 0,
    this.fameGain = 0,
  });

  factory BeefResponse.fromJson(Map<String, dynamic> json) {
    return BeefResponse(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      type: ResponseType.values.firstWhere(
        (e) => e.toString() == 'ResponseType.${json['type']}',
        orElse: () => ResponseType.dissTrack,
      ),
      trackId: json['trackId'] as String?,
      trackTitle: json['trackTitle'] as String?,
      content: json['content'] as String?,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      streams: json['streams'] as int? ?? 0,
      fameGain: json['fameGain'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'type': type.name,
      'trackId': trackId,
      'trackTitle': trackTitle,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'streams': streams,
      'fameGain': fameGain,
    };
  }
}

/// Status of the beef
enum BeefStatus {
  active, // Beef is ongoing
  resolved, // Beef has been settled (winner determined)
  escalated, // Beef has intensified (multiple responses)
  ignored, // Target never responded
}

/// Type of beef
enum BeefType {
  dissTrack, // Started with a diss track
  socialMedia, // Started on social media
  charts, // Started from chart rivalry
  studio, // Studio drama
}

/// Type of response
enum ResponseType {
  dissTrack, // Diss track response
  socialMedia, // Social media clap back
  interview, // Interview response
  ignore, // No response
}
