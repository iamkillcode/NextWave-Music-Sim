import 'dart:math';
import '../models/published_song.dart';
import '../models/multiplayer_player.dart';
import '../models/artist_stats.dart';

class DemoFirebaseService {
  static final DemoFirebaseService _instance = DemoFirebaseService._internal();
  factory DemoFirebaseService() => _instance;
  DemoFirebaseService._internal();

  // Demo data storage
  final List<PublishedSong> _demoSongs = [];
  final List<MultiplayerPlayer> _demoPlayers = [];
  final String _currentPlayerId = 'demo_player_${DateTime.now().millisecondsSinceEpoch}';
  bool _isSignedIn = false;

  // Current user
  bool get isSignedIn => _isSignedIn;

  // Auth Methods
  Future<bool> signInAnonymously() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    _isSignedIn = true;
    
    // Create demo player
    if (!_demoPlayers.any((p) => p.id == _currentPlayerId)) {
      final demoPlayer = MultiplayerPlayer(
        id: _currentPlayerId,
        displayName: 'Demo Artist ${_currentPlayerId.substring(_currentPlayerId.length - 4)}',
        email: '',
        joinDate: DateTime.now(),
        lastActive: DateTime.now(),
      );
      _demoPlayers.add(demoPlayer);
    }
    
    // Add some demo songs and players if first time
    if (_demoSongs.isEmpty) {
      _initializeDemoData();
    }
    
    return true;
  }

  Future<void> signOut() async {
    _isSignedIn = false;
  }

  // Initialize demo data
  void _initializeDemoData() {
    final random = Random();
    final genres = ['Pop', 'Ballad', 'EDM', 'Rock', 'Alternative'];
    final artistNames = ['Alex Thunder', 'Luna Star', 'DJ Phoenix', 'Sarah Echo', 'Mike Storm', 'Nova Dreams'];
    final songTitles = [
      'Midnight Dance', 'Electric Nights', 'Broken Wings', 'City Lights', 'Digital Heart',
      'Neon Dreams', 'Rebel Soul', 'Lost in Time', 'Rising Star', 'Echoes', 'Fire Storm',
      'Ocean Waves', 'Sky High', 'Diamond Dust', 'Thunder Road', 'Silent Moon'
    ];

    // Create demo players
    for (int i = 0; i < artistNames.length; i++) {
      final player = MultiplayerPlayer(
        id: 'demo_$i',
        displayName: artistNames[i],
        email: '',
        totalStreams: random.nextInt(500000) + 10000,
        totalLikes: random.nextInt(50000) + 1000,
        songsPublished: random.nextInt(20) + 5,
        currentMoney: random.nextInt(1000000) + 50000,
        currentFame: random.nextInt(200) + 20,
        level: random.nextInt(10) + 1,
        joinDate: DateTime.now().subtract(Duration(days: random.nextInt(365))),
        lastActive: DateTime.now().subtract(Duration(hours: random.nextInt(48))),
      );
      _demoPlayers.add(player);
    }

    // Create demo songs
    for (int i = 0; i < songTitles.length; i++) {
      final song = PublishedSong(
        id: 'demo_song_$i',
        playerId: 'demo_${random.nextInt(artistNames.length)}',
        playerName: artistNames[random.nextInt(artistNames.length)],
        title: songTitles[i],
        genre: genres[random.nextInt(genres.length)],
        quality: random.nextInt(40) + 60, // Quality between 60-100
        streams: random.nextInt(100000) + 1000,
        likes: random.nextInt(10000) + 100,
        releaseDate: DateTime.now().subtract(Duration(
          hours: random.nextInt(720), // Up to 30 days ago
        )),
      );
      _demoSongs.add(song);
    }

    // Sort songs by streams for realistic leaderboard
    _demoSongs.sort((a, b) => b.streams.compareTo(a.streams));
    _demoPlayers.sort((a, b) => b.totalStreams.compareTo(a.totalStreams));
  }

  // Player Methods
  Future<void> updatePlayerStats(ArtistStats stats) async {
    if (!_isSignedIn) return;
    
    final playerIndex = _demoPlayers.indexWhere((p) => p.id == _currentPlayerId);
    if (playerIndex != -1) {
      _demoPlayers[playerIndex] = _demoPlayers[playerIndex].copyWith(
        currentMoney: stats.money,
        currentFame: stats.fame,
        level: stats.fanbase,
        lastActive: DateTime.now(),
      );
    }
  }

  Future<MultiplayerPlayer?> getPlayer(String playerId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _demoPlayers.firstWhere((p) => p.id == playerId, orElse: () => _demoPlayers.first);
  }

  // Song Methods
  Future<String?> publishSong({
    required String title,
    required String genre,
    required String playerName,
    required int quality,
  }) async {
    if (!_isSignedIn) return null;
    
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    final song = PublishedSong(
      id: 'user_song_${DateTime.now().millisecondsSinceEpoch}',
      playerId: _currentPlayerId,
      playerName: playerName,
      title: title,
      genre: genre,
      quality: quality,
      releaseDate: DateTime.now(),
    );

    _demoSongs.insert(0, song); // Add to beginning
    
    // Update player song count
    final playerIndex = _demoPlayers.indexWhere((p) => p.id == _currentPlayerId);
    if (playerIndex != -1) {
      _demoPlayers[playerIndex] = _demoPlayers[playerIndex].copyWith(
        songsPublished: _demoPlayers[playerIndex].songsPublished + 1,
      );
    }

    return song.id;
  }

  Future<List<PublishedSong>> getTopSongs({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sortedSongs = List<PublishedSong>.from(_demoSongs);
    sortedSongs.sort((a, b) => b.streams.compareTo(a.streams));
    return sortedSongs.take(limit).toList();
  }

  Future<List<PublishedSong>> getRecentSongs({int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sortedSongs = List<PublishedSong>.from(_demoSongs);
    sortedSongs.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    return sortedSongs.take(limit).toList();
  }

  Future<List<PublishedSong>> getSongsByGenre(String genre, {int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final filteredSongs = _demoSongs.where((song) => song.genre == genre).toList();
    filteredSongs.sort((a, b) => b.streams.compareTo(a.streams));
    return filteredSongs.take(limit).toList();
  }

  Future<void> likeSong(String songId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final songIndex = _demoSongs.indexWhere((s) => s.id == songId);
    if (songIndex != -1) {
      _demoSongs[songIndex] = _demoSongs[songIndex].copyWith(
        likes: _demoSongs[songIndex].likes + 1,
      );
    }
  }

  // Leaderboard Methods
  Future<List<MultiplayerPlayer>> getTopPlayersByNetWorth({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sortedPlayers = List<MultiplayerPlayer>.from(_demoPlayers);
    sortedPlayers.sort((a, b) => b.netWorth.compareTo(a.netWorth));
    return sortedPlayers.take(limit).toList();
  }

  Future<List<MultiplayerPlayer>> getTopPlayersByFame({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sortedPlayers = List<MultiplayerPlayer>.from(_demoPlayers);
    sortedPlayers.sort((a, b) => b.currentFame.compareTo(a.currentFame));
    return sortedPlayers.take(limit).toList();
  }

  Future<List<MultiplayerPlayer>> getTopPlayersByStreams({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sortedPlayers = List<MultiplayerPlayer>.from(_demoPlayers);
    sortedPlayers.sort((a, b) => b.totalStreams.compareTo(a.totalStreams));
    return sortedPlayers.take(limit).toList();
  }

  // Stream listening methods (simplified for demo)
  Stream<List<PublishedSong>> streamTopSongs({int limit = 10}) {
    return Stream.periodic(const Duration(seconds: 5), (i) => getTopSongs(limit: limit))
        .asyncMap((future) => future);
  }

  Stream<List<MultiplayerPlayer>> streamTopPlayers({int limit = 10}) {
    return Stream.periodic(const Duration(seconds: 5), (i) => getTopPlayersByStreams(limit: limit))
        .asyncMap((future) => future);
  }

  // Simulate song performance
  Future<void> simulateSongPerformance() async {
    final random = Random();
    
    for (int i = 0; i < _demoSongs.length && i < 10; i++) {
      final song = _demoSongs[i];
      
      // Add some random streams (higher quality songs get more)
      final qualityFactor = song.quality / 100.0;
      final newStreams = (random.nextInt(50) * qualityFactor).round();
      
      if (newStreams > 0) {
        _demoSongs[i] = song.copyWith(streams: song.streams + newStreams);
        
        // Update player total streams
        final playerIndex = _demoPlayers.indexWhere((p) => p.id == song.playerId);
        if (playerIndex != -1) {
          _demoPlayers[playerIndex] = _demoPlayers[playerIndex].copyWith(
            totalStreams: _demoPlayers[playerIndex].totalStreams + newStreams,
          );
        }
      }
    }
  }
}
