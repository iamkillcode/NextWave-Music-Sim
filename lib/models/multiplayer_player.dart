import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_sanitizer.dart';

class MultiplayerPlayer {
  final String id;
  final String displayName;
  final String email;
  final String? gender; // 'male', 'female', 'other', or null
  final int totalStreams;
  final int totalLikes;
  final int songsPublished;
  final int currentMoney;
  final int currentFame;
  final int level;
  final DateTime joinDate;
  final DateTime lastActive;
  final Map<String, int> achievements;
  final bool isOnline;

  const MultiplayerPlayer({
    required this.id,
    required this.displayName,
    required this.email,
    this.gender,
    this.totalStreams = 0,
    this.totalLikes = 0,
    this.songsPublished = 0,
    this.currentMoney = 5000,
    this.currentFame = 0,
    this.level = 1,
    required this.joinDate,
    required this.lastActive,
    this.achievements = const {},
    this.isOnline = false,
  });

  // Convert from Firestore document
  factory MultiplayerPlayer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MultiplayerPlayer(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] as String?,
  totalStreams: safeParseInt(data['totalStreams'], fallback: 0),
  totalLikes: safeParseInt(data['totalLikes'], fallback: 0),
  songsPublished: safeParseInt(data['songsPublished'], fallback: 0),
  currentMoney: safeParseInt(data['currentMoney'], fallback: 5000),
  currentFame: safeParseInt(data['currentFame'], fallback: 0),
  level: safeParseInt(data['level'], fallback: 1),
      joinDate: (data['joinDate'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
    achievements: Map<String, int>.from((data['achievements'] ?? {})
      .map((k, v) => MapEntry(k.toString(), safeParseInt(v)))),
      isOnline: data['isOnline'] ?? false,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'gender': gender,
      'totalStreams': totalStreams,
      'totalLikes': totalLikes,
      'songsPublished': songsPublished,
      'currentMoney': currentMoney,
      'currentFame': currentFame,
      'level': level,
      'joinDate': Timestamp.fromDate(joinDate),
      'lastActive': Timestamp.fromDate(lastActive),
      'achievements': achievements,
      'isOnline': isOnline,
    };
  }

  MultiplayerPlayer copyWith({
    String? id,
    String? displayName,
    String? email,
    String? gender,
    int? totalStreams,
    int? totalLikes,
    int? songsPublished,
    int? currentMoney,
    int? currentFame,
    int? level,
    DateTime? joinDate,
    DateTime? lastActive,
    Map<String, int>? achievements,
    bool? isOnline,
  }) {
    return MultiplayerPlayer(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      totalStreams: totalStreams ?? this.totalStreams,
      totalLikes: totalLikes ?? this.totalLikes,
      songsPublished: songsPublished ?? this.songsPublished,
      currentMoney: currentMoney ?? this.currentMoney,
      currentFame: currentFame ?? this.currentFame,
      level: level ?? this.level,
      joinDate: joinDate ?? this.joinDate,
      lastActive: lastActive ?? this.lastActive,
      achievements: achievements ?? this.achievements,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  // Calculate net worth for ranking
  int get netWorth {
    return currentMoney + (currentFame * 1000) + (totalStreams * 10);
  }

  // Get player rank based on performance
  String get rankTitle {
    if (totalStreams > 1000000) return "Platinum Artist";
    if (totalStreams > 500000) return "Gold Artist";
    if (totalStreams > 100000) return "Rising Star";
    if (totalStreams > 50000) return "Popular Artist";
    if (totalStreams > 10000) return "Local Artist";
    return "New Artist";
  }

  // Format money display
  String get formattedMoney {
    if (currentMoney >= 1000000) {
      return '\$${(currentMoney / 1000000).toStringAsFixed(1)}M';
    } else if (currentMoney >= 1000) {
      return '\$${(currentMoney / 1000).toStringAsFixed(1)}K';
    }
    return '\$$currentMoney';
  }

  // Check if player is active (logged in within last 7 days)
  bool get isActive {
    return DateTime.now().difference(lastActive).inDays < 7;
  }
}
