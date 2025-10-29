/// Represents an Album or EP - a collection of songs released together
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_sanitizer.dart';

class Album {
  final String id;
  final String title;
  final AlbumType type; // EP or Album
  final List<String> songIds; // IDs of songs in this album
  final DateTime? releasedDate; // null if scheduled/unreleased
  final DateTime? scheduledDate; // Future release date
  final String? coverArtUrl;
  final int totalStreams; // Combined streams of all songs
  // Certifications tracking
  final int totalSales; // Albums sold (units)
  final int eligibleUnits; // streams/RC_streams_per_unit + totalSales
  final String
      highestCertification; // none, silver, gold, platinum, multi_platinum, diamond
  final int certificationLevel; // 0 if none
  final DateTime? lastCertifiedAt;
  final AlbumState state; // planned, scheduled, released
  final List<String> streamingPlatforms; // Where it's available
  final bool isDeluxe; // True if this is a deluxe edition
  final String? originalAlbumId; // ID of the original album if this is deluxe

  const Album({
    required this.id,
    required this.title,
    required this.type,
    required this.songIds,
    this.releasedDate,
    this.scheduledDate,
    this.coverArtUrl,
    this.totalStreams = 0,
    this.totalSales = 0,
    this.eligibleUnits = 0,
    this.highestCertification = 'none',
    this.certificationLevel = 0,
    this.lastCertifiedAt,
    this.state = AlbumState.planned,
    this.streamingPlatforms = const [],
    this.isDeluxe = false,
    this.originalAlbumId,
  });

  Album copyWith({
    String? id,
    String? title,
    AlbumType? type,
    List<String>? songIds,
    DateTime? releasedDate,
    DateTime? scheduledDate,
    String? coverArtUrl,
    int? totalStreams,
    int? totalSales,
    int? eligibleUnits,
    String? highestCertification,
    int? certificationLevel,
    DateTime? lastCertifiedAt,
    AlbumState? state,
    List<String>? streamingPlatforms,
    bool? isDeluxe,
    String? originalAlbumId,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      songIds: songIds ?? this.songIds,
      releasedDate: releasedDate ?? this.releasedDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      totalStreams: totalStreams ?? this.totalStreams,
      totalSales: totalSales ?? this.totalSales,
      eligibleUnits: eligibleUnits ?? this.eligibleUnits,
      highestCertification: highestCertification ?? this.highestCertification,
      certificationLevel: certificationLevel ?? this.certificationLevel,
      lastCertifiedAt: lastCertifiedAt ?? this.lastCertifiedAt,
      state: state ?? this.state,
      streamingPlatforms: streamingPlatforms ?? this.streamingPlatforms,
      isDeluxe: isDeluxe ?? this.isDeluxe,
      originalAlbumId: originalAlbumId ?? this.originalAlbumId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'songIds': songIds,
      'releasedDate': releasedDate?.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'coverArtUrl': coverArtUrl,
      'totalStreams': totalStreams,
      'totalSales': totalSales,
      'eligibleUnits': eligibleUnits,
      'highestCertification': highestCertification,
      'certificationLevel': certificationLevel,
      'lastCertifiedAt': lastCertifiedAt?.toIso8601String(),
      'state': state.name,
      'streamingPlatforms': streamingPlatforms,
      'isDeluxe': isDeluxe,
      'originalAlbumId': originalAlbumId,
    };
  }

  /// Helper to parse date fields that may be Timestamp or String
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String,
      title: json['title'] as String,
      type: AlbumType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlbumType.album,
      ),
      songIds: List<String>.from(json['songIds'] as List? ?? []),
      releasedDate: _parseDate(json['releasedDate']),
      scheduledDate: _parseDate(json['scheduledDate']),
      coverArtUrl: json['coverArtUrl'] as String?,
      totalStreams: safeParseInt(json['totalStreams'], fallback: 0),
      totalSales: safeParseInt(json['totalSales'], fallback: 0),
      eligibleUnits: safeParseInt(json['eligibleUnits'], fallback: 0),
      highestCertification: json['highestCertification'] as String? ?? 'none',
      certificationLevel: safeParseInt(json['certificationLevel'], fallback: 0),
      lastCertifiedAt: _parseDate(json['lastCertifiedAt']),
      state: AlbumState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => AlbumState.planned,
      ),
      streamingPlatforms: List<String>.from(
        json['streamingPlatforms'] as List? ?? [],
      ),
      isDeluxe: json['isDeluxe'] as bool? ?? false,
      originalAlbumId: json['originalAlbumId'] as String?,
    );
  }

  /// Check if this album can be released (has required number of songs)
  bool get canBeReleased {
    if (type == AlbumType.ep) {
      return songIds.length >= 3 && songIds.length <= 6;
    } else {
      // Standard albums: 7-15 tracks
      // Deluxe albums: 10-20 tracks (must have at least 10)
      if (isDeluxe) {
        return songIds.length >= 10 && songIds.length <= 20;
      } else {
        return songIds.length >= 7 && songIds.length <= 15;
      }
    }
  }

  /// Get the minimum songs required for this album type
  int get minimumSongs {
    if (type == AlbumType.ep) return 3;
    if (isDeluxe) return 10;
    return 7;
  }

  /// Get the maximum songs allowed for this album type
  int get maximumSongs {
    if (type == AlbumType.ep) return 6;
    if (isDeluxe) return 20;
    return 15;
  }

  /// Get the emoji for the album type
  String get typeEmoji {
    if (isDeluxe) return '💎';
    return type == AlbumType.ep ? '💿' : '💽';
  }

  /// Get display name for album type
  String get typeDisplay {
    if (isDeluxe) return 'Deluxe Album';
    return type == AlbumType.ep ? 'EP' : 'Album';
  }
}

enum AlbumType {
  ep, // 3-6 songs
  album, // 7+ songs
}

enum AlbumState {
  planned, // Not yet scheduled
  scheduled, // Has a future release date
  released, // Already released
}
