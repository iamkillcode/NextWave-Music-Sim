import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/nexttube_video.dart';
import '../utils/firestore_sanitizer.dart';

class NextTubeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _videosCol =>
      _firestore.collection('nexttube_videos');

  /// Creates a NexTube video document for the current user.
  /// Returns the created NextTubeVideo with its generated id.
  Future<NextTubeVideo> createVideo({
    required ArtistStats stats,
    required Song song,
    required NextTubeVideoType type,
    required String title,
    String? description,
    String? thumbnailUrl,
    int rpmCents = 200,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final docRef = _videosCol.doc();
    final video = NextTubeVideo(
      id: docRef.id,
      ownerId: userId,
      ownerName: stats.name,
      songId: song.id,
      songTitle: song.title,
      type: type,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      createdAt: DateTime.now(),
      status: 'published',
      totalViews: 0,
      dailyViews: 0,
      earningsTotal: 0,
      rpmCents: rpmCents,
      isMonetized: false,
    );

    await docRef.set(sanitizeForFirestore(video.toJson()));
    return video;
  }

  /// Fetch recent videos across the platform (basic feed placeholder)
  Future<List<NextTubeVideo>> fetchRecent({int limit = 20}) async {
    final snap = await _videosCol
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => NextTubeVideo.fromJson(d.data()..['id'] = d.id))
        .toList();
  }

  /// Fetch videos for the current user
  Future<List<NextTubeVideo>> fetchMyVideos({int limit = 50}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    final snap = await _videosCol
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => NextTubeVideo.fromJson(d.data()..['id'] = d.id))
        .toList();
  }
}
