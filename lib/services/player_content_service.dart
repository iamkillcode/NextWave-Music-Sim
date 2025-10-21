import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../utils/firestore_sanitizer.dart';

class PlayerContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get songs for a player. Prefer the songs subcollection; fall back to the
  /// top-level 'songs' array on the player document for backward compatibility.
  Future<List<Song>> getSongsForPlayer(String playerId) async {
    final songsCol = _firestore.collection('players').doc(playerId).collection('songs');
    try {
      final first = await songsCol.limit(1).get();
      if (first.docs.isNotEmpty) {
        final all = await songsCol.get();
        return all.docs
            .map((d) => Song.fromJson(Map<String, dynamic>.from(d.data() as Map)))
            .toList();
      }
    } catch (e) {
      // Fall back to reading from player doc below
      print('PlayerContentService: subcollection read failed: $e');
    }

    // Fallback: read from player doc
    try {
      final doc = await _firestore.collection('players').doc(playerId).get();
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return [];
      if (data['songs'] != null && data['songs'] is List) {
        final list = List<dynamic>.from(data['songs'] as List);
        return list.map((s) => Song.fromJson(Map<String, dynamic>.from(s as Map))).toList();
      }
    } catch (e) {
      print('PlayerContentService: fallback songs read failed: $e');
    }
    return [];
  }

  /// Get albums for a player. Prefer subcollection, fall back to doc array.
  Future<List<Album>> getAlbumsForPlayer(String playerId) async {
    final albumsCol = _firestore.collection('players').doc(playerId).collection('albums');
    try {
      final first = await albumsCol.limit(1).get();
      if (first.docs.isNotEmpty) {
        final all = await albumsCol.get();
        return all.docs
            .map((d) => Album.fromJson(Map<String, dynamic>.from(d.data() as Map)))
            .toList();
      }
    } catch (e) {
      print('PlayerContentService: subcollection albums read failed: $e');
    }

    // Fallback
    try {
      final doc = await _firestore.collection('players').doc(playerId).get();
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return [];
      if (data['albums'] != null && data['albums'] is List) {
        final list = List<dynamic>.from(data['albums'] as List);
        return list.map((a) => Album.fromJson(Map<String, dynamic>.from(a as Map))).toList();
      }
    } catch (e) {
      print('PlayerContentService: fallback albums read failed: $e');
    }
    return [];
  }

  /// Write a single song document to the player's songs subcollection.
  Future<void> writeSongToSubcollection(String playerId, Song song) async {
    final docRef = _firestore.collection('players').doc(playerId).collection('songs').doc(song.id);
    final payload = sanitizeForFirestore(song.toJson());
    await docRef.set(payload);
  }

  /// Write a single album document to the player's albums subcollection.
  Future<void> writeAlbumToSubcollection(String playerId, Album album) async {
    final docRef = _firestore.collection('players').doc(playerId).collection('albums').doc(album.id);
    final payload = sanitizeForFirestore(album.toJson());
    await docRef.set(payload);
  }
}
