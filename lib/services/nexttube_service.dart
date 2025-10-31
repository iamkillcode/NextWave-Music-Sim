import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/nexttube_video.dart';
import '../models/nexttube_channel.dart';
import '../utils/firestore_sanitizer.dart';

class NextTubeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _videosCol =>
      _firestore.collection('nexttube_videos');
  DocumentReference<Map<String, dynamic>> _channelDoc(String ownerId) =>
      _firestore
          .collection('players')
          .doc(ownerId)
          .collection('nexTubeChannel')
          .doc('main');

  /// Creates a NexTube video document for the current user.
  /// Returns the created NextTubeVideo with its generated id.
  Future<NextTubeVideo> createVideo({
    required ArtistStats stats,
    required Song song,
    required NextTubeVideoType type,
    required String title,
    String? description,
    String? thumbnailUrl,
    DateTime? releaseDate, // Scheduled in-game release date
    int rpmCents = 200,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final docRef = _videosCol.doc();

    // Determine status based on release date
    String status;
    if (releaseDate != null) {
      status = 'scheduled';
    } else {
      status = 'published';
    }

    final video = NextTubeVideo(
      id: docRef.id,
      ownerId: userId,
      ownerName: stats.name,
      ownerAvatarUrl: stats.avatarUrl,
      songId: song.id,
      songTitle: song.title,
      type: type,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      createdAt: DateTime.now(),
      releaseDate: releaseDate,
      status: status,
      totalViews: 0,
      dailyViews: 0,
      earningsTotal: 0,
      rpmCents: rpmCents,
      isMonetized: false,
    );

    final payload = video.toJson();
    payload['normalizedTitle'] = _normalizeTitle(title);
    await docRef.set(sanitizeForFirestore(payload));
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

  /// Get or create the current user's NexTube channel
  Future<NextTubeChannel?> getOrCreateMyChannel() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    final ref = _channelDoc(userId);
    final snap = await ref.get();
    if (!snap.exists) {
      final ch = NextTubeChannel(ownerId: userId, updatedAt: DateTime.now());
      await ref.set(sanitizeForFirestore(ch.toJson()));
      return ch;
    }
    return NextTubeChannel.fromJson(snap.data()!);
  }

  Future<NextTubeChannel?> getChannel(String ownerId) async {
    final ref = _channelDoc(ownerId);
    final snap = await ref.get();
    if (!snap.exists) return null;
    return NextTubeChannel.fromJson(snap.data()!);
  }

  /// Fetch "New" videos: order by createdAt desc
  Future<List<NextTubeVideo>> fetchNew({int limit = 20}) async {
    final snap = await _videosCol
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => NextTubeVideo.fromJson(d.data()..['id'] = d.id))
        .toList();
  }

  /// Fetch "Trending" videos: order by totalViews desc then recent
  Future<List<NextTubeVideo>> fetchTrending({int limit = 20}) async {
    final snap = await _videosCol
        .orderBy('totalViews', descending: true)
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

  /// Get a video by id
  Future<NextTubeVideo?> getVideoById(String id) async {
    final doc = await _videosCol.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    data['id'] = doc.id;
    return NextTubeVideo.fromJson(data);
  }

  /// Check if current user uploaded a video in the last [hours]
  Future<bool> hasRecentUpload({int hours = 24}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;
    final since = DateTime.now().subtract(Duration(hours: hours));
    final snap = await _videosCol
        .where('ownerId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Count my uploads since [since]. Uses a capped limit for efficiency.
  Future<int> countMyUploadsSince(DateTime since, {int limitCap = 20}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;
    final snap = await _videosCol
        .where('ownerId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(limitCap)
        .get();
    return snap.docs.length;
  }

  /// Check if a video for the same song and type already exists by current user
  /// Returns true if ANY video (published or scheduled) exists for that song+type combo
  Future<bool> hasVideoForSongAndType({
    required String songId,
    required NextTubeVideoType type,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final snap = await _videosCol
        .where('ownerId', isEqualTo: userId)
        .where('songId', isEqualTo: songId)
        .where('type', isEqualTo: _typeId(type))
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Check duplicate/near-duplicate by normalized title within recent window
  Future<bool> hasRecentDuplicateTitle(String title,
      {int withinDays = 30}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;
    final since = DateTime.now().subtract(Duration(days: withinDays));
    final normalized = _normalizeTitle(title);
    final snap = await _videosCol
        .where('ownerId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .where('normalizedTitle', isEqualTo: normalized)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Fetch my recent uploads since [since]
  Future<List<NextTubeVideo>> fetchMyRecentUploadsSince(DateTime since,
      {int limit = 100}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    final snap = await _videosCol
        .where('ownerId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => NextTubeVideo.fromJson(d.data()..['id'] = d.id))
        .toList();
  }

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s]"), '')
        .replaceAll(RegExp(r"\s+"), ' ')
        .trim();
  }

  String _typeId(NextTubeVideoType type) {
    switch (type) {
      case NextTubeVideoType.official:
        return 'official';
      case NextTubeVideoType.lyrics:
        return 'lyrics';
      case NextTubeVideoType.live:
        return 'live';
    }
  }
}
