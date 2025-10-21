/// Represents an Album or EP - a collection of songs released together
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
  final AlbumState state; // planned, scheduled, released
  final List<String> streamingPlatforms; // Where it's available

  const Album({
    required this.id,
    required this.title,
    required this.type,
    required this.songIds,
    this.releasedDate,
    this.scheduledDate,
    this.coverArtUrl,
    this.totalStreams = 0,
    this.state = AlbumState.planned,
    this.streamingPlatforms = const [],
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
    AlbumState? state,
    List<String>? streamingPlatforms,
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
      state: state ?? this.state,
      streamingPlatforms: streamingPlatforms ?? this.streamingPlatforms,
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
      'state': state.name,
      'streamingPlatforms': streamingPlatforms,
    };
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
      releasedDate: json['releasedDate'] != null
          ? DateTime.parse(json['releasedDate'] as String)
          : null,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      coverArtUrl: json['coverArtUrl'] as String?,
  totalStreams: safeParseInt(json['totalStreams'], fallback: 0),
      state: AlbumState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => AlbumState.planned,
      ),
      streamingPlatforms: List<String>.from(
        json['streamingPlatforms'] as List? ?? [],
      ),
    );
  }

  /// Check if this album can be released (has required number of songs)
  bool get canBeReleased {
    if (type == AlbumType.ep) {
      return songIds.length >= 3 && songIds.length <= 6;
    } else {
      return songIds.length >= 7;
    }
  }

  /// Get the minimum songs required for this album type
  int get minimumSongs => type == AlbumType.ep ? 3 : 7;

  /// Get the emoji for the album type
  String get typeEmoji => type == AlbumType.ep ? '💿' : '💽';

  /// Get display name for album type
  String get typeDisplay => type == AlbumType.ep ? 'EP' : 'Album';
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
