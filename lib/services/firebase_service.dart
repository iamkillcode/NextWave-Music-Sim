import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/published_song.dart';
import '../utils/firestore_sanitizer.dart';
import '../models/multiplayer_player.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/album.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Explicitly set region to us-central1 to match deployed functions
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile'
    ], // Minimal scopes to avoid People API dependency
  );

  // Lightweight in-memory cache for cross-player ArtistStats lookups
  final Map<String, ArtistStats> _artistStatsCache = {};
  final Map<String, DateTime> _artistStatsCacheTime = {};
  final Duration _artistStatsCacheTTL = const Duration(minutes: 5);

  // Collections
  CollectionReference get _songsCollection => _firestore.collection('songs');
  CollectionReference get _playersCollection =>
      _firestore.collection('players');

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

  /// Sign in with Google account
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        print('Google sign-in cancelled by user');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _createOrUpdatePlayer(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    // Clear caches on sign out to avoid stale data bleed between sessions
    _artistStatsCache.clear();
    _artistStatsCacheTime.clear();
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
      // Sanitize before writing to Firestore
      await playerDoc.set(sanitizeForFirestore(newPlayer.toFirestore()));
    } else {
      // Update last active
      await playerDoc.update(sanitizeForFirestore({
        'lastActive': Timestamp.fromDate(DateTime.now()),
        'isOnline': true,
      }));
    }
  }

  Future<void> updatePlayerStats(ArtistStats stats) async {
    if (!isSignedIn) return;

    // Calculate total streams from all songs
    final totalStreams = stats.songs.fold<int>(
      0,
      (sum, song) => sum + song.streams,
    );

    // Use secure server-side validation for all stat updates
    try {
      final callable = _functions.httpsCallable('secureStatUpdate');
      final rawPayload = {
        'updates': {
          'currentMoney': stats.money,
          'currentFame': stats.fame,
          'fanbase': stats.fanbase,
          'energy': stats.energy,
          'creativity': stats.creativity, // 🎨 FIX: Save Hype stat!
          'songwritingSkill': stats.songwritingSkill,
          'lyricsSkill': stats.lyricsSkill,
          'compositionSkill': stats.compositionSkill,
          'experience': stats.experience,
          'inspirationLevel': stats.inspirationLevel,
          // ✅ CRITICAL Fix: Include songs array to persist song data
          'songs': stats.songs.map((s) => s.toJson()).toList(),
          'albums': stats.albums.map((a) => a.toJson()).toList(),
          'loyalFanbase': stats.loyalFanbase,
          'regionalFanbase': stats.regionalFanbase,
          'currentRegion': stats.currentRegion,
          'avatarUrl': stats.avatarUrl, // Sync avatar URL to players collection
          'totalStreams': totalStreams, // ✅ Sync total streams from songs
          'songsPublished':
              stats.songs.where((s) => s.state == SongState.released).length,
        },
        'action': 'stat_update',
        'context': {
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      // Sanitize everything to avoid NaN/Infinity being sent upstream
      final sanitizedPayload =
          sanitizeForFirestore(Map<String, dynamic>.from(rawPayload));
      final result = await callable.call(sanitizedPayload);

      if (!result.data['success']) {
        throw Exception('Server rejected stat update: ${result.data['error']}');
      }

      // Log any flags returned by server
      if (result.data['flags'] != null) {
        print('⚠️ Server flagged suspicious activity: ${result.data['flags']}');
      }
    } catch (e) {
      print('Error updating player stats: $e');
      rethrow;
    }
  }

  /// Secure song creation using server-side validation
  Future<Map<String, dynamic>?> createSongSecurely({
    required String title,
    required String genre,
    required int effort,
  }) async {
    if (!isSignedIn) return null;

    try {
      final callable = _functions.httpsCallable('secureSongCreation');
      final result = await callable.call({
        'title': title,
        'genre': genre,
        'effort': effort,
      });

      if (result.data['success']) {
        return result.data;
      } else {
        throw Exception(
            'Server rejected song creation: ${result.data['error']}');
      }
    } catch (e) {
      print('Error creating song: $e');
      return null;
    }
  }

  /// Secure side hustle reward processing
  Future<Map<String, dynamic>?> processSideHustleReward({
    required String sideHustleId,
    required DateTime currentGameDate,
  }) async {
    if (!isSignedIn) return null;

    try {
      final callable = _functions.httpsCallable('secureSideHustleReward');
      final result = await callable.call({
        'sideHustleId': sideHustleId,
        'currentGameDate': currentGameDate.toIso8601String(),
      });

      if (result.data['success']) {
        return result.data;
      } else {
        throw Exception(
            'Server rejected side hustle reward: ${result.data['error']}');
      }
    } catch (e) {
      print('Error processing side hustle reward: $e');
      return null;
    }
  }

  /// Secure album/EP release handled server-side (atomic)
  Future<Map<String, dynamic>?> releaseAlbumSecurely({
    required String albumId,
    List<String>? overridePlatforms,
  }) async {
    if (!isSignedIn) return null;

    try {
      final callable = _functions.httpsCallable('secureReleaseAlbum');
      final result = await callable.call({
        'albumId': albumId,
        'overridePlatforms': overridePlatforms ?? [],
        'action': 'release_album',
        'debug': true,
      });

      return result.data as Map<String, dynamic>?;
    } on FirebaseFunctionsException catch (e) {
      // Surface detailed information from the callable function
      print(
          'Error releasing album securely: code=${e.code}, message=${e.message}, details=${e.details}');
      rethrow;
    } catch (e) {
      print('Error releasing album securely (unknown): $e');
      rethrow;
    }
  }

  /// Trigger server-side migration for a player's songs/albums arrays -> subcollections
  Future<Map<String, dynamic>?> migratePlayerContent(String playerId) async {
    try {
      final callable =
          _functions.httpsCallable('migratePlayerContentToSubcollections');
      final res = await callable.call({'playerId': playerId});
      return res.data as Map<String, dynamic>?;
    } catch (e) {
      print('Error calling migratePlayerContent: $e');
      rethrow;
    }
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

  /// Load another player's ArtistStats, including songs and albums arrays
  /// Returns null if player not found or on failure
  Future<ArtistStats?> getArtistStatsForPlayer(String playerId) async {
    try {
      // Serve from cache if fresh
      final cached = _artistStatsCache[playerId];
      final ts = _artistStatsCacheTime[playerId];
      if (cached != null && ts != null) {
        if (DateTime.now().difference(ts) <= _artistStatsCacheTTL) {
          return cached;
        }
      }

      final doc = await _playersCollection.doc(playerId).get().timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Player load timeout'),
          );

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;

      // Deserialize songs
      List<Song> loadedSongs = [];
      if (data['songs'] != null) {
        try {
          final songsList = data['songs'] as List<dynamic>;
          loadedSongs = songsList
              .map((songData) =>
                  Song.fromJson(Map<String, dynamic>.from(songData as Map)))
              .toList();
        } catch (e) {
          print('⚠️ Error parsing songs for $playerId: $e');
        }
      }

      // If no songs array (migrated), try subcollection fallback
      if (loadedSongs.isEmpty) {
        try {
          final snap =
              await _playersCollection.doc(playerId).collection('songs').get();
          loadedSongs = snap.docs
              .map((d) =>
                  Song.fromJson(Map<String, dynamic>.from(d.data() as Map)))
              .toList();
          if (loadedSongs.isNotEmpty) {
            print(
                'ℹ️ Loaded ${loadedSongs.length} songs from subcollection for $playerId');
          }
        } catch (e) {
          print('⚠️ Error loading songs subcollection for $playerId: $e');
        }
      }

      // Deserialize albums
      List<Album> loadedAlbums = [];
      if (data['albums'] != null) {
        try {
          final albumsList = data['albums'] as List<dynamic>;
          loadedAlbums = albumsList
              .map((albumData) =>
                  Album.fromJson(Map<String, dynamic>.from(albumData as Map)))
              .toList();
        } catch (e) {
          print('⚠️ Error parsing albums for $playerId: $e');
        }
      }

      // If no albums array (migrated), try subcollection fallback
      if (loadedAlbums.isEmpty) {
        try {
          final snap =
              await _playersCollection.doc(playerId).collection('albums').get();
          loadedAlbums = snap.docs
              .map((d) =>
                  Album.fromJson(Map<String, dynamic>.from(d.data() as Map)))
              .toList();
          if (loadedAlbums.isNotEmpty) {
            print(
                'ℹ️ Loaded ${loadedAlbums.length} albums from subcollection for $playerId');
          }
        } catch (e) {
          print('⚠️ Error loading albums subcollection for $playerId: $e');
        }
      }

      // Deserialize regional fanbase
      Map<String, int> loadedRegionalFanbase = {};
      if (data['regionalFanbase'] != null) {
        try {
          final regionalData =
              Map<String, dynamic>.from(data['regionalFanbase'] as Map);
          loadedRegionalFanbase = regionalData.map(
            (key, value) => MapEntry(key.toString(), safeParseInt(value)),
          );
        } catch (e) {
          print('⚠️ Error parsing regionalFanbase for $playerId: $e');
        }
      }

      // Genre system
      final String primaryGenre = data['primaryGenre'] ?? 'Hip Hop';
      Map<String, int> loadedGenreMastery = {};
      if (data['genreMastery'] != null) {
        try {
          final masteryData = Map<String, dynamic>.from(data['genreMastery']);
          loadedGenreMastery = masteryData.map(
            (key, value) => MapEntry(key.toString(), safeParseInt(value)),
          );
        } catch (e) {
          print('⚠️ Error parsing genreMastery for $playerId: $e');
        }
      }

      List<String> loadedUnlockedGenres = [];
      if (data['unlockedGenres'] != null) {
        try {
          loadedUnlockedGenres =
              List<String>.from(data['unlockedGenres'] as List<dynamic>);
        } catch (e) {
          print('⚠️ Error parsing unlockedGenres for $playerId: $e');
        }
      } else {
        loadedUnlockedGenres = [primaryGenre];
        loadedGenreMastery[primaryGenre] =
            loadedGenreMastery[primaryGenre] ?? 0;
      }

      final stats = ArtistStats(
        name: data['displayName'] ?? 'Unknown Artist',
        fame: safeParseInt(data['currentFame'], fallback: 0),
        money: safeParseInt(data['currentMoney'], fallback: 5000),
        energy: safeParseInt(data['energy'], fallback: 100),
        creativity: safeParseInt(data['inspirationLevel'], fallback: 0),
        fanbase: safeParseInt(data['fanbase'], fallback: 100),
        loyalFanbase: safeParseInt(data['loyalFanbase'], fallback: 0),
        albumsSold: safeParseInt(data['albumsReleased'], fallback: 0),
        songsWritten: safeParseInt(data['songsPublished'], fallback: 0),
        concertsPerformed: safeParseInt(data['concertsPerformed'], fallback: 0),
        songwritingSkill: safeParseInt(data['songwritingSkill'], fallback: 10),
        experience: safeParseInt(data['experience'], fallback: 0),
        lyricsSkill: safeParseInt(data['lyricsSkill'], fallback: 10),
        compositionSkill: safeParseInt(data['compositionSkill'], fallback: 10),
        inspirationLevel: safeParseInt(data['inspirationLevel'], fallback: 0),
        songs: loadedSongs,
        albums: loadedAlbums,
        currentRegion: data['homeRegion'] ?? 'usa',
        age: safeParseInt(data['age'], fallback: 18),
        careerStartDate:
            (data['careerStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        regionalFanbase: loadedRegionalFanbase,
        avatarUrl: data['avatarUrl'] as String?,
        activeSideHustle: null, // not needed for read-only profile view
        primaryGenre: primaryGenre,
        genreMastery: loadedGenreMastery,
        unlockedGenres: loadedUnlockedGenres,
      );

      // Store in cache
      _artistStatsCache[playerId] = stats;
      _artistStatsCacheTime[playerId] = DateTime.now();
      return stats;
    } catch (e) {
      print('❌ Error loading ArtistStats for $playerId: $e');
      return null;
    }
  }

  // Password Reset
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
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

      final docRef =
          await _songsCollection.add(sanitizeForFirestore(song.toFirestore()));

      // Update player song count
      await _playersCollection
          .doc(currentUser!.uid)
          .update(sanitizeForFirestore({
            'songsPublished': FieldValue.increment(1),
          }));

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

  Future<List<PublishedSong>> getSongsByGenre(String genre,
      {int limit = 10}) async {
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
  Future<List<MultiplayerPlayer>> getTopPlayersByNetWorth(
      {int limit = 10}) async {
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

  Future<List<MultiplayerPlayer>> getTopPlayersByStreams(
      {int limit = 10}) async {
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
        final randomFactor =
            (DateTime.now().millisecondsSinceEpoch % 100) / 100.0;

        final newStreams =
            ((qualityFactor * randomFactor * 10) * (ageInHours < 24 ? 2 : 1))
                .round();

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
