import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/published_song.dart';
import '../models/multiplayer_player.dart';
import '../models/artist_stats.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _songsCollection => _firestore.collection('songs');
  CollectionReference get _playersCollection => _firestore.collection('players');
  CollectionReference get _leaderboardsCollection => _firestore.collection('leaderboards');

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // Auth Methods
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      if (credential.user != null) {
        await _createOrUpdatePlayer(credential.user!);
      }
      return credential;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Player Methods
  Future<void> _createOrUpdatePlayer(User user) async {
    final playerDoc = _playersCollection.doc(user.uid);
    final playerSnapshot = await playerDoc.get();

    if (!playerSnapshot.exists) {
      // Create new player
      final newPlayer = MultiplayerPlayer(
        id: user.uid,
        displayName: 'Artist ${user.uid.substring(0, 6)}',
        email: user.email ?? '',
        joinDate: DateTime.now(),
        lastActive: DateTime.now(),
      );
      await playerDoc.set(newPlayer.toFirestore());
    } else {
      // Update last active
      await playerDoc.update({
        'lastActive': Timestamp.fromDate(DateTime.now()),
        'isOnline': true,
      });
    }
  }

  Future<void> updatePlayerStats(ArtistStats stats) async {
    if (!isSignedIn) return;

    await _playersCollection.doc(currentUser!.uid).update({
      'currentMoney': stats.money,
      'currentFame': stats.fame,
      'level': stats.fanbase,
      'lastActive': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<MultiplayerPlayer?> getPlayer(String playerId) async {
    try {
      final doc = await _playersCollection.doc(playerId).get();
      if (doc.exists) {
        return MultiplayerPlayer.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting player: $e');
    }
    return null;
  }

  // Song Methods
  Future<String?> publishSong({
    required String title,
    required String genre,
    required String playerName,
    required int quality,
  }) async {
    if (!isSignedIn) return null;

    try {
      final song = PublishedSong(
        id: '',
        playerId: currentUser!.uid,
        playerName: playerName,
        title: title,
        genre: genre,
        quality: quality,
        releaseDate: DateTime.now(),
      );

      final docRef = await _songsCollection.add(song.toFirestore());
      
      // Update player song count
      await _playersCollection.doc(currentUser!.uid).update({
        'songsPublished': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      print('Error publishing song: $e');
      return null;
    }
  }

  Future<List<PublishedSong>> getTopSongs({int limit = 10}) async {
    try {
      final snapshot = await _songsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('streams', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PublishedSong.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting top songs: $e');
      return [];
    }
  }

  Future<List<PublishedSong>> getRecentSongs({int limit = 20}) async {
    try {
      final snapshot = await _songsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('releaseDate', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PublishedSong.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting recent songs: $e');
      return [];
    }
  }

  Future<List<PublishedSong>> getSongsByGenre(String genre, {int limit = 10}) async {
    try {
      final snapshot = await _songsCollection
          .where('genre', isEqualTo: genre)
          .where('isActive', isEqualTo: true)
          .orderBy('streams', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PublishedSong.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting songs by genre: $e');
      return [];
    }
  }

  Future<void> likeSong(String songId) async {
    if (!isSignedIn) return;

    try {
      await _songsCollection.doc(songId).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error liking song: $e');
    }
  }

  // Leaderboard Methods
  Future<List<MultiplayerPlayer>> getTopPlayersByNetWorth({int limit = 10}) async {
    try {
      final snapshot = await _playersCollection
          .orderBy('currentMoney', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MultiplayerPlayer.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting top players by net worth: $e');
      return [];
    }
  }

  Future<List<MultiplayerPlayer>> getTopPlayersByFame({int limit = 10}) async {
    try {
      final snapshot = await _playersCollection
          .orderBy('currentFame', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MultiplayerPlayer.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting top players by fame: $e');
      return [];
    }
  }

  Future<List<MultiplayerPlayer>> getTopPlayersByStreams({int limit = 10}) async {
    try {
      final snapshot = await _playersCollection
          .orderBy('totalStreams', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MultiplayerPlayer.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting top players by streams: $e');
      return [];
    }
  }

  // Stream listening methods
  Stream<List<PublishedSong>> streamTopSongs({int limit = 10}) {
    return _songsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('streams', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PublishedSong.fromFirestore(doc))
            .toList());
  }

  Stream<List<MultiplayerPlayer>> streamTopPlayers({int limit = 10}) {
    return _playersCollection
        .orderBy('totalStreams', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MultiplayerPlayer.fromFirestore(doc))
            .toList());
  }

  // Simulate song performance (would normally be done server-side)
  Future<void> simulateSongPerformance() async {
    try {
      final recentSongs = await getRecentSongs(limit: 50);
      
      for (final song in recentSongs) {
        // Simple performance simulation based on quality and age
        final ageInHours = DateTime.now().difference(song.releaseDate).inHours;
        final qualityFactor = song.quality / 100.0;
        final randomFactor = (DateTime.now().millisecondsSinceEpoch % 100) / 100.0;
        
        final newStreams = ((qualityFactor * randomFactor * 10) * (ageInHours < 24 ? 2 : 1)).round();
        
        if (newStreams > 0) {
          await _songsCollection.doc(song.id).update({
            'streams': FieldValue.increment(newStreams),
          });
          
          // Update player total streams
          await _playersCollection.doc(song.playerId).update({
            'totalStreams': FieldValue.increment(newStreams),
          });
        }
      }
    } catch (e) {
      print('Error simulating song performance: $e');
    }
  }
}
