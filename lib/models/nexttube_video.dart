import 'package:cloud_firestore/cloud_firestore.dart';

enum NextTubeVideoType { official, lyrics, live }

class NextTubeVideo {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatarUrl;
  final String songId;
  final String songTitle;
  final NextTubeVideoType type;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime? releaseDate; // Scheduled in-game release date
  final String status; // 'scheduled', 'published', 'processing'
  final int totalViews;
  final int dailyViews;
  final int earningsTotal; // cents
  final int rpmCents; // revenue per 1000 views in cents
  final bool isMonetized;

  const NextTubeVideo({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatarUrl,
    required this.songId,
    required this.songTitle,
    required this.type,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.createdAt,
    this.releaseDate,
    this.status = 'published',
    this.totalViews = 0,
    this.dailyViews = 0,
    this.earningsTotal = 0,
    this.rpmCents = 200, // default $2.00 RPM
    this.isMonetized = false,
  });

  String get typeId => switch (type) {
        NextTubeVideoType.official => 'official',
        NextTubeVideoType.lyrics => 'lyrics',
        NextTubeVideoType.live => 'live',
      };

  NextTubeVideo copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerAvatarUrl,
    String? songId,
    String? songTitle,
    NextTubeVideoType? type,
    String? title,
    String? description,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? releaseDate,
    String? status,
    int? totalViews,
    int? dailyViews,
    int? earningsTotal,
    int? rpmCents,
    bool? isMonetized,
  }) {
    return NextTubeVideo(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      songId: songId ?? this.songId,
      songTitle: songTitle ?? this.songTitle,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      releaseDate: releaseDate ?? this.releaseDate,
      status: status ?? this.status,
      totalViews: totalViews ?? this.totalViews,
      dailyViews: dailyViews ?? this.dailyViews,
      earningsTotal: earningsTotal ?? this.earningsTotal,
      rpmCents: rpmCents ?? this.rpmCents,
      isMonetized: isMonetized ?? this.isMonetized,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerAvatarUrl': ownerAvatarUrl,
      'songId': songId,
      'songTitle': songTitle,
      'type': typeId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'releaseDate':
          releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
      'status': status,
      'totalViews': totalViews,
      'dailyViews': dailyViews,
      'earningsTotal': earningsTotal,
      'rpmCents': rpmCents,
      'isMonetized': isMonetized,
    };
  }

  factory NextTubeVideo.fromJson(Map<String, dynamic> json) {
    final String typeStr = (json['type'] ?? 'official').toString();
    final NextTubeVideoType parsedType = switch (typeStr) {
      'lyrics' => NextTubeVideoType.lyrics,
      'live' => NextTubeVideoType.live,
      _ => NextTubeVideoType.official,
    };

    return NextTubeVideo(
      id: (json['id'] ?? '').toString(),
      ownerId: (json['ownerId'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
      ownerAvatarUrl: json['ownerAvatarUrl'] as String?,
      songId: (json['songId'] ?? '').toString(),
      songTitle: (json['songTitle'] ?? '').toString(),
      type: parsedType,
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
              DateTime.now(),
      releaseDate: json['releaseDate'] != null
          ? (json['releaseDate'] is Timestamp
              ? (json['releaseDate'] as Timestamp).toDate()
              : DateTime.tryParse((json['releaseDate'] ?? '').toString()))
          : null,
      status: (json['status'] ?? 'published').toString(),
      totalViews: (json['totalViews'] ?? 0) is int
          ? json['totalViews'] as int
          : int.tryParse(json['totalViews'].toString()) ?? 0,
      dailyViews: (json['dailyViews'] ?? 0) is int
          ? json['dailyViews'] as int
          : int.tryParse(json['dailyViews'].toString()) ?? 0,
      earningsTotal: (json['earningsTotal'] ?? 0) is int
          ? json['earningsTotal'] as int
          : int.tryParse(json['earningsTotal'].toString()) ?? 0,
      rpmCents: (json['rpmCents'] ?? 200) is int
          ? json['rpmCents'] as int
          : int.tryParse(json['rpmCents'].toString()) ?? 200,
      isMonetized: (json['isMonetized'] ?? false) == true,
    );
  }
}
