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
  final String? coverArtStyle; // e.g., 'minimalist', 'abstract', 'photo', 'illustration'
  final String? coverArtColor; // Primary color theme

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
      case 'pop': return '⭐';
      case 'ballad': return '💕';
      case 'edm': return '⚡';
      case 'rock': return '🤘';
      case 'alternative': return '🎸';
      case 'r&b': return '🎤';
      case 'hip hop': return '🎧';
      case 'rap': return '🎯';
      case 'trap': return '🔥';
      case 'drill': return '💀';
      case 'afrobeat': return '🌍';
      case 'country': return '🤠';
      case 'jazz': return '🎺';
      case 'reggae': return '🌴';
      default: return '🎵';
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
    final marketPenetration = qualityFactor * genrePopularityFactor * 0.01; // 1% max penetration
    
    return (globalPopulation * marketPenetration).round();
  }
  double _getGenrePopularityFactor() {
    switch (genre.toLowerCase()) {
      case 'r&b': return 1.0;
      case 'hip hop': return 0.95;
      case 'rap': return 0.9;
      case 'trap': return 0.85;
      case 'drill': return 0.8;
      case 'afrobeat': return 0.75;
      case 'country': return 0.7;
      case 'jazz': return 0.65;
      case 'reggae': return 0.6;
      case 'pop': return 0.55;
      case 'edm': return 0.5;
      case 'rock': return 0.45;
      case 'ballad': return 0.4;
      case 'alternative': return 0.35;
      default: return 0.5;
    }
  }
}

enum SongState {
  written,
  recorded,
  released,
}
