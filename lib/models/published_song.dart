import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_sanitizer.dart';

class PublishedSong {
  final String id;
  final String playerId;
  final String playerName;
  final String title;
  final String genre;
  final int quality;
  final int streams;
  final int likes;
  final DateTime releaseDate;
  final Map<String, int> weeklyStreams;
  final bool isActive;

  const PublishedSong({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.title,
    required this.genre,
    required this.quality,
    this.streams = 0,
    this.likes = 0,
    required this.releaseDate,
    this.weeklyStreams = const {},
    this.isActive = true,
  });

  // Convert from Firestore document
  factory PublishedSong.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PublishedSong(
      id: doc.id,
      playerId: data['playerId'] ?? '',
      playerName: data['playerName'] ?? '',
      title: data['title'] ?? '',
      genre: data['genre'] ?? '',
  quality: safeParseInt(data['quality'], fallback: 0),
  streams: safeParseInt(data['streams'], fallback: 0),
  likes: safeParseInt(data['likes'], fallback: 0),
      releaseDate: (data['releaseDate'] as Timestamp).toDate(),
    weeklyStreams: safeParseIntMap(
      Map<String, dynamic>.from(data['weeklyStreams'] ?? {})),
    isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'title': title,
      'genre': genre,
      'quality': quality,
      'streams': streams,
      'likes': likes,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'weeklyStreams': weeklyStreams,
      'isActive': isActive,
    };
  }

  PublishedSong copyWith({
    String? id,
    String? playerId,
    String? playerName,
    String? title,
    String? genre,
    int? quality,
    int? streams,
    int? likes,
    DateTime? releaseDate,
    Map<String, int>? weeklyStreams,
    bool? isActive,
  }) {
    return PublishedSong(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      quality: quality ?? this.quality,
      streams: streams ?? this.streams,
      likes: likes ?? this.likes,
      releaseDate: releaseDate ?? this.releaseDate,
      weeklyStreams: weeklyStreams ?? this.weeklyStreams,
      isActive: isActive ?? this.isActive,
    );
  }

  // Calculate performance score
  double get performanceScore {
    final ageInDays = DateTime.now().difference(releaseDate).inDays;
    final ageFactor = ageInDays < 7 ? 1.5 : ageInDays < 30 ? 1.0 : 0.7;
    final qualityFactor = quality / 100.0;
    final popularityFactor = (streams + likes * 10) / 1000.0;
    
    return (qualityFactor * ageFactor * popularityFactor).clamp(0.0, 100.0);
  }

  // Get genre emoji
  String get genreEmoji {
    switch (genre.toLowerCase()) {
      case 'pop': return '⭐';
      case 'ballad': return '💕';
      case 'edm': return '⚡';
      case 'rock': return '🤘';
      case 'alternative': return '🎸';
      default: return '🎵';
    }
  }
}
