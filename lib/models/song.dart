class Song {
  final String id;
  final String title;
  final String genre;
  final int quality;
  final DateTime createdDate;
  final SongState state;
  final int? recordingQuality;
  final DateTime? recordedDate;
  final DateTime? releasedDate;
  final int streams;
  final int likes;
  final Map<String, dynamic> metadata;
  final String?
  coverArtStyle; // e.g., 'minimalist', 'abstract', 'photo', 'illustration'
  final String? coverArtColor; // Primary color theme
  final List<String>
  streamingPlatforms; // List of platform IDs like ['tunify', 'maple_music']
  final String? coverArtUrl; // Uploaded cover art image URL

  // Stream growth tracking
  final double
  viralityScore; // 0.0 to 1.0 - how viral/popular this specific song is
  final int peakDailyStreams; // Track the song's peak performance
  final int daysOnChart; // How many days since release
  final int
  lastDayStreams; // Streams gained in the last game day (for Daily charts)
  final int
  last7DaysStreams; // Streams gained in the last 7 game days (for Weekly charts)

  // Regional tracking - streams per region
  final Map<String, int>
  regionalStreams; // e.g., {'usa': 10000, 'europe': 5000}

  // Track whether this is an album or single (for Spotlight charts)
  final bool isAlbum; // true = album (Spotlight 200), false = single (Hot 100)

  const Song({
    required this.id,
    required this.title,
    required this.genre,
    required this.quality,
    required this.createdDate,
    this.state = SongState.written,
    this.recordingQuality,
    this.recordedDate,
    this.releasedDate,
    this.streams = 0,
    this.likes = 0,
    this.metadata = const {},
    this.coverArtStyle,
    this.coverArtColor,
    this.streamingPlatforms = const [],
    this.coverArtUrl,
    this.viralityScore = 0.5, // Default mid-range virality
    this.peakDailyStreams = 0,
    this.daysOnChart = 0,
    this.lastDayStreams = 0,
    this.last7DaysStreams = 0,
    this.regionalStreams = const {},
    this.isAlbum = false, // Default to single
  });

  Song copyWith({
    String? id,
    String? title,
    String? genre,
    int? quality,
    DateTime? createdDate,
    SongState? state,
    int? recordingQuality,
    DateTime? recordedDate,
    DateTime? releasedDate,
    int? streams,
    int? likes,
    Map<String, dynamic>? metadata,
    String? coverArtStyle,
    String? coverArtColor,
    List<String>? streamingPlatforms,
    String? coverArtUrl,
    double? viralityScore,
    int? peakDailyStreams,
    int? daysOnChart,
    int? lastDayStreams,
    int? last7DaysStreams,
    Map<String, int>? regionalStreams,
    bool? isAlbum,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      quality: quality ?? this.quality,
      createdDate: createdDate ?? this.createdDate,
      state: state ?? this.state,
      recordingQuality: recordingQuality ?? this.recordingQuality,
      recordedDate: recordedDate ?? this.recordedDate,
      releasedDate: releasedDate ?? this.releasedDate,
      streams: streams ?? this.streams,
      likes: likes ?? this.likes,
      metadata: metadata ?? this.metadata,
      coverArtStyle: coverArtStyle ?? this.coverArtStyle,
      coverArtColor: coverArtColor ?? this.coverArtColor,
      streamingPlatforms: streamingPlatforms ?? this.streamingPlatforms,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      viralityScore: viralityScore ?? this.viralityScore,
      peakDailyStreams: peakDailyStreams ?? this.peakDailyStreams,
      daysOnChart: daysOnChart ?? this.daysOnChart,
      lastDayStreams: lastDayStreams ?? this.lastDayStreams,
      last7DaysStreams: last7DaysStreams ?? this.last7DaysStreams,
      regionalStreams: regionalStreams ?? this.regionalStreams,
      isAlbum: isAlbum ?? this.isAlbum,
    );
  }

  // Convert Song to JSON for Firebase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'genre': genre,
      'quality': quality,
      'createdDate': createdDate.toIso8601String(),
      'state': state.name,
      'recordingQuality': recordingQuality,
      'recordedDate': recordedDate?.toIso8601String(),
      'releasedDate': releasedDate?.toIso8601String(),
      'streams': streams,
      'likes': likes,
      'metadata': metadata,
      'coverArtStyle': coverArtStyle,
      'coverArtColor': coverArtColor,
      'streamingPlatforms': streamingPlatforms,
      'coverArtUrl': coverArtUrl,
      'viralityScore': viralityScore,
      'peakDailyStreams': peakDailyStreams,
      'daysOnChart': daysOnChart,
      'lastDayStreams': lastDayStreams,
      'last7DaysStreams': last7DaysStreams,
      'regionalStreams': regionalStreams,
      'isAlbum': isAlbum,
    };
  }

  // Create Song from JSON (Firebase load)
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      genre: json['genre'] as String,
      quality: (json['quality'] as num).toInt(),
      createdDate: DateTime.parse(json['createdDate'] as String),
      state: SongState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => SongState.written,
      ),
      recordingQuality: json['recordingQuality'] as int?,
      recordedDate: json['recordedDate'] != null
          ? DateTime.parse(json['recordedDate'] as String)
          : null,
      releasedDate: json['releasedDate'] != null
          ? DateTime.parse(json['releasedDate'] as String)
          : null,
      streams: (json['streams'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      coverArtStyle: json['coverArtStyle'] as String?,
      coverArtColor: json['coverArtColor'] as String?,
      streamingPlatforms: List<String>.from(
        json['streamingPlatforms'] as List? ?? [],
      ),
      coverArtUrl: json['coverArtUrl'] as String?,
      viralityScore: (json['viralityScore'] as num?)?.toDouble() ?? 0.5,
      peakDailyStreams: (json['peakDailyStreams'] as num?)?.toInt() ?? 0,
      daysOnChart: (json['daysOnChart'] as num?)?.toInt() ?? 0,
      lastDayStreams: (json['lastDayStreams'] as num?)?.toInt() ?? 0,
      last7DaysStreams: (json['last7DaysStreams'] as num?)?.toInt() ?? 0,
      regionalStreams: Map<String, int>.from(
        json['regionalStreams'] as Map? ?? {},
      ),
      isAlbum: json['isAlbum'] as bool? ?? false,
    );
  }

  // Calculate final quality after recording
  int get finalQuality {
    if (state == SongState.written) return quality;
    if (recordingQuality == null) return quality;
    return ((quality + recordingQuality!) / 2).round();
  }

  // Get genre emoji
  String get genreEmoji {
    switch (genre.toLowerCase()) {
      case 'pop':
        return '⭐';
      case 'ballad':
        return '💕';
      case 'edm':
        return '⚡';
      case 'rock':
        return '🤘';
      case 'alternative':
        return '🎸';
      case 'r&b':
        return '🎤';
      case 'hip hop':
        return '🎧';
      case 'rap':
        return '🎯';
      case 'trap':
        return '🔥';
      case 'drill':
        return '💀';
      case 'afrobeat':
        return '🌍';
      case 'country':
        return '🤠';
      case 'jazz':
        return '🎺';
      case 'reggae':
        return '🌴';
      default:
        return '🎵';
    }
  }

  // Get state display text
  String get stateDisplay {
    switch (state) {
      case SongState.written:
        return 'Written';
      case SongState.recorded:
        return 'Recorded';
      case SongState.released:
        return 'Released';
    }
  }

  // Get quality rating
  String get qualityRating {
    final q = finalQuality;
    if (q >= 90) return "Legendary";
    if (q >= 80) return "Masterpiece";
    if (q >= 70) return "Excellent";
    if (q >= 60) return "Great";
    if (q >= 50) return "Good";
    if (q >= 40) return "Decent";
    if (q >= 30) return "Average";
    if (q >= 20) return "Poor";
    return "Terrible";
  }

  // Calculate estimated streams based on quality and global population
  int get estimatedStreams {
    const globalPopulation = 8500000000;
    final qualityFactor = finalQuality / 100.0;
    final genrePopularityFactor = _getGenrePopularityFactor();
    final marketPenetration =
        qualityFactor * genrePopularityFactor * 0.01; // 1% max penetration

    return (globalPopulation * marketPenetration).round();
  }

  double _getGenrePopularityFactor() {
    switch (genre.toLowerCase()) {
      case 'r&b':
        return 1.0;
      case 'hip hop':
        return 0.95;
      case 'rap':
        return 0.9;
      case 'trap':
        return 0.85;
      case 'drill':
        return 0.8;
      case 'afrobeat':
        return 0.75;
      case 'country':
        return 0.7;
      case 'jazz':
        return 0.65;
      case 'reggae':
        return 0.6;
      case 'pop':
        return 0.55;
      case 'edm':
        return 0.5;
      case 'rock':
        return 0.45;
      case 'ballad':
        return 0.4;
      case 'alternative':
        return 0.35;
      default:
        return 0.5;
    }
  }
}

enum SongState { written, recorded, released }
