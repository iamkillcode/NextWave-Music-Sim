import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/side_hustle.dart';
import '../models/album.dart';
import '../services/firebase_service.dart';
import '../services/demo_firebase_service.dart';
import '../services/game_time_service.dart';
import '../services/stream_growth_service.dart';
import '../services/side_hustle_service.dart';
import '../services/song_name_generator.dart';
import '../models/pending_practice.dart';
import 'world_map_screen.dart';
import 'music_hub_screen.dart';
import 'studios_list_screen.dart';
import 'activity_hub_screen.dart';
import 'media_hub_screen.dart';
import 'release_manager_screen.dart';
import '../utils/firebase_status.dart';
import '../utils/firestore_sanitizer.dart';
import '../utils/genres.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'the_scoop_screen.dart';
import 'unified_charts_screen.dart';
import '../services/notification_service.dart';
import 'dart:ui';
import '../widgets/glassmorphic_bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  final dynamic initialStats;

  const DashboardScreen({super.key, this.initialStats});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ArtistStats artistStats;
  int _selectedIndex = 0;
  Timer? gameTimer; // Made nullable to prevent dispose errors
  Timer? syncTimer; // Made nullable to prevent dispose errors
  Timer? _countdownTimer; // Timer for next day countdown
  Timer? _saveDebounceTimer; // Timer for debouncing saves
  Timer? _multiplayerStatsTimer; // Timer for multiplayer stats updates
  StreamSubscription<DocumentSnapshot>?
      _playerDataSubscription; // Real-time player data listener
  StreamSubscription<QuerySnapshot>?
      _notificationsSubscription; // Real-time notifications listener
  DateTime?
      currentGameDate; // Will be set from Firebase, starts as null to show loading
  DateTime? _lastSyncTime; // Track when we last synced with Firebase
  int _lastEnergyReplenishDay = 0; // Track the last day we replenished energy
  DateTime?
      _lastPassiveIncomeTime; // Track when we last calculated passive income
  late dynamic _multiplayerService;
  bool _isOnlineMode = false;
  bool _isInitializing = false;
  final GameTimeService _gameTimeService = GameTimeService();
  final StreamGrowthService _streamGrowthService = StreamGrowthService();
  final SideHustleService _sideHustleService = SideHustleService();
  final NotificationService _notificationService = NotificationService();
  final List<Map<String, dynamic>> _notifications = []; // Store notifications
  int _unreadNotificationCount = 0; // Track unread notification count
  String _timeUntilNextDay = ''; // Formatted time until next day
  bool _hasPendingSave = false; // Track if we have pending changes to save
  List<PendingPractice> pendingPractices =
      []; // Track ongoing training programs

  @override
  void initState() {
    super.initState();
    // Initialize global game time
    _initializeGameTime();

    // Don't set _lastEnergyReplenishDay until we sync with Firebase

    // Initialize passive income tracking
    _lastPassiveIncomeTime = DateTime.now();

    // Initialize with provided initialStats (from onboarding) or defaults
    if (widget.initialStats != null && widget.initialStats is ArtistStats) {
      artistStats = widget.initialStats as ArtistStats;
    } else {
      artistStats = ArtistStats(
        name: "Loading...",
        fame: 0,
        money:
            5000, // Starting money - enough to get started with side hustles!
        energy: 100,
        creativity: 0, // No hype yet - you're just starting!
        fanbase: 100, // Start with 100 fans minimum
        albumsSold: 0,
        songsWritten: 0,
        concertsPerformed: 0,
        songwritingSkill: 10,
        experience: 0,
        lyricsSkill: 10,
        compositionSkill: 10,
        inspirationLevel: 0, // No hype yet - you're just starting!
        age: 18, // Will be updated from Firestore when profile loads
      );
    }

    // Load user profile from Firestore (will set up listeners after loading)
    _loadUserProfile();

    // Check for Firebase notifications (gifts from admin, etc.)
    _loadFirebaseNotifications();

    // Initialize notification service
    _notificationService.initialize();

    // Load unread count
    _loadUnreadNotificationCount();

    // Initialize Firebase authentication
    _initializeOnlineMode();

    // Date-only system: Check for day changes every 5 minutes (much more efficient!)
    gameTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateGameDate();
    });

    // Auto-save every 30 seconds for multiplayer sync
    // This ensures other players see your progress in near real-time
    // while still being cost-effective (only ~120 writes per hour vs constant updates)
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_hasPendingSave && mounted) {
        print('🔄 Auto-save: Syncing with Firebase for multiplayer...');
        _saveUserProfile();
      }
    });

    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  /// Initialize the global game time system
  Future<void> _initializeGameTime() async {
    try {
      print('🔧 Initializing game time system...');
      // Initialize the game time system in Firestore (only happens once)
      await _gameTimeService.initializeGameTime();
      print('✅ Game time system initialized');
      await _syncWithFirebase(); // Do initial sync
      print('🕐 Global game time initialized and synced');
    } catch (e) {
      print('❌ Error initializing game time: $e');
      // Even on error, try to sync with Firebase to get the date
      await _syncWithFirebase();
    }
  }

  /// Sync with Firebase to get the authoritative game time
  Future<void> _syncWithFirebase() async {
    // Check if widget is still mounted
    if (!mounted) return;

    try {
      print('🔄 Starting Firebase sync...');
      final gameDate = await _gameTimeService.getCurrentGameDate();
      print('✅ Got game date: ${_gameTimeService.formatGameDate(gameDate)}');

      // Check again after async operation
      if (!mounted) return;

      setState(() {
        currentGameDate = gameDate;
        _lastSyncTime = DateTime.now();
        // Update the last energy replenish day to match the synced date
        // This prevents false triggers on first sync
        _lastEnergyReplenishDay = gameDate.day;
      });
      print(
        '🔄 Synced: ${_gameTimeService.formatGameDate(gameDate)} (Day: ${gameDate.day})',
      );
      print('📅 Energy replenish day set to: $_lastEnergyReplenishDay');
      print('📊 currentGameDate is now: $currentGameDate');
    } catch (e) {
      print('❌ Sync failed: $e');
      // On sync failure, set a default date so UI can render
      if (!mounted) return;
      setState(() {
        currentGameDate = DateTime(2020, 1, 1);
        _lastSyncTime = DateTime.now();
        _lastEnergyReplenishDay = 1;
      });
      print('⚠️ Using fallback date: January 1, 2020');
    }
  }

  @override
  void dispose() {
    // Cancel timers if they exist
    gameTimer?.cancel();
    syncTimer?.cancel();
    _countdownTimer?.cancel();
    _saveDebounceTimer?.cancel();
    _multiplayerStatsTimer?.cancel();

    // Cancel real-time listeners
    _playerDataSubscription?.cancel();
    _notificationsSubscription?.cancel();

    // Save any pending changes before disposing
    if (_hasPendingSave) {
      _saveUserProfile();
    }

    super.dispose();
  }

  /// Pull-to-refresh handler
  Future<void> _handleRefresh() async {
    try {
      print('🔄 Manual refresh triggered');

      // Sync with Firebase to get latest game time
      await _syncWithFirebase();

      // Reload user profile from Firebase
      await _loadUserProfile();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Refreshed!'),
            backgroundColor: Color(0xFF32D74B),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Refresh error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Refresh failed. Please try again.'),
            backgroundColor: Color(0xFFFF6B9D),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ No user signed in, waiting for authentication...');

        // Wait a bit for Firebase to initialize after hot restart
        await Future.delayed(const Duration(seconds: 2));
        final retryUser = FirebaseAuth.instance.currentUser;

        if (retryUser == null) {
          print('❌ Still no user after waiting, using demo stats');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Not signed in. Pull down to refresh when ready.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        print('✅ User authenticated after waiting: ${retryUser.uid}');
        return _loadUserProfileForUser(retryUser);
      }

      return _loadUserProfileForUser(user);
    } catch (e) {
      print('❌ Error in _loadUserProfile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadUserProfileForUser(User user) async {
    try {
      print('📥 Loading user profile for: ${user.uid}');

      final doc = await FirebaseFirestore.instance
          .collection('players')
          .doc(user.uid)
          .get()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Profile load timeout');
        },
      );

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        print('✅ Profile loaded: ${data['displayName']}');

        // Load songs from Firebase
        List<Song> loadedSongs = [];
        if (data['songs'] != null) {
          try {
            final songsList = data['songs'] as List<dynamic>;
            loadedSongs = songsList
                .map(
                  (songData) =>
                      Song.fromJson(Map<String, dynamic>.from(songData)),
                )
                .toList();
            print('✅ Loaded ${loadedSongs.length} songs from Firebase');
          } catch (e) {
            print('⚠️ Error loading songs: $e');
          }
        }

        // Migration fallback: if songs array missing, load from subcollection
        if (loadedSongs.isEmpty) {
          try {
            final songsSnap = await FirebaseFirestore.instance
                .collection('players')
                .doc(user.uid)
                .collection('songs')
                .get();
            loadedSongs = songsSnap.docs
                .map((d) =>
                    Song.fromJson(Map<String, dynamic>.from(d.data() as Map)))
                .toList();
            if (loadedSongs.isNotEmpty) {
              print('ℹ️ Loaded ${loadedSongs.length} songs from subcollection');
            }
          } catch (e) {
            print('⚠️ Fallback subcollection songs load failed: $e');
          }
        }

        // Load regional fanbase with proper deserialization
        Map<String, int> loadedRegionalFanbase = {};
        if (data['regionalFanbase'] != null) {
          try {
            final regionalData = Map<String, dynamic>.from(
                data['regionalFanbase'] as Map<dynamic, dynamic>);
            loadedRegionalFanbase = regionalData.map(
              (key, value) =>
                  MapEntry(key.toString(), safeParseInt(value, fallback: 0)),
            );
            print(
              '✅ Loaded regional fanbase for ${loadedRegionalFanbase.length} regions',
            );
          } catch (e) {
            print('⚠️ Error loading regional fanbase: $e');
          }
        }

        // Load active side hustle
        SideHustle? loadedSideHustle;
        if (data['activeSideHustle'] != null) {
          try {
            loadedSideHustle = SideHustle.fromJson(
              Map<String, dynamic>.from(data['activeSideHustle']),
            );
            print(
              '✅ Loaded active side hustle: ${loadedSideHustle.type.displayName}',
            );
          } catch (e) {
            print('⚠️ Error loading side hustle: $e');
          }
        }

        // 🎸 GENRE SYSTEM: Load genre mastery data
        final String primaryGenre = data['primaryGenre'] ?? 'Hip Hop';

        // Load genre mastery map (default empty for new players)
        Map<String, int> loadedGenreMastery = {};
        if (data['genreMastery'] != null) {
          final masteryData = Map<String, dynamic>.from(data['genreMastery']);
          loadedGenreMastery = masteryData.map(
            (key, value) => MapEntry(key.toString(), safeParseInt(value)),
          );
        }

        // Load or initialize unlocked genres
        List<String> loadedUnlockedGenres = [];
        if (data['unlockedGenres'] != null) {
          loadedUnlockedGenres = List<String>.from(data['unlockedGenres']);
        } else {
          // First time: unlock only the primary genre
          loadedUnlockedGenres = [primaryGenre];
          // Initialize mastery for primary genre at 0
          loadedGenreMastery[primaryGenre] = 0;
        }

        // Load albums (EPs and Albums)
        List<Album> loadedAlbums = [];
        if (data['albums'] != null) {
          try {
            final albumsList = List<Map<String, dynamic>>.from(
                (data['albums'] as List<dynamic>));
            loadedAlbums = albumsList
                .map((albumData) =>
                    Album.fromJson(Map<String, dynamic>.from(albumData)))
                .toList();
            print('✅ Loaded ${loadedAlbums.length} albums/EPs');
          } catch (e) {
            print('⚠️ Error loading albums: $e');
          }
        }

        // Migration fallback: if albums array missing, load from subcollection
        if (loadedAlbums.isEmpty) {
          try {
            final albumsSnap = await FirebaseFirestore.instance
                .collection('players')
                .doc(user.uid)
                .collection('albums')
                .get();
            loadedAlbums = albumsSnap.docs
                .map((d) =>
                    Album.fromJson(Map<String, dynamic>.from(d.data() as Map)))
                .toList();
            if (loadedAlbums.isNotEmpty) {
              print(
                  'ℹ️ Loaded ${loadedAlbums.length} albums from subcollection');
            }
          } catch (e) {
            print('⚠️ Fallback subcollection albums load failed: $e');
          }
        }

        setState(() {
          artistStats = ArtistStats(
            name: data['displayName'] ?? 'Unknown Artist',
            fame: safeParseInt(data['currentFame'], fallback: 0),
            money: safeParseInt(data['currentMoney'], fallback: 5000),
            energy: 100, // Always start with full energy
            creativity: safeParseInt(data['inspirationLevel'], fallback: 0),
            fanbase: math.max(100,
                safeParseInt(data['fanbase'] ?? data['level'], fallback: 100)),
            loyalFanbase: safeParseInt(data['loyalFanbase'], fallback: 0),
            albumsSold: safeParseInt(data['albumsReleased'], fallback: 0),
            songsWritten: safeParseInt(data['songsPublished'], fallback: 0),
            concertsPerformed:
                safeParseInt(data['concertsPerformed'], fallback: 0),
            songwritingSkill:
                safeParseInt(data['songwritingSkill'], fallback: 10),
            experience: safeParseInt(data['experience'], fallback: 0),
            lyricsSkill: safeParseInt(data['lyricsSkill'], fallback: 10),
            compositionSkill:
                safeParseInt(data['compositionSkill'], fallback: 10),
            inspirationLevel:
                safeParseInt(data['inspirationLevel'], fallback: 0),
            songs: loadedSongs,
            albums: loadedAlbums,
            currentRegion: data['homeRegion'] ?? 'usa',
            age: safeParseInt(data['age'], fallback: 18),
            careerStartDate:
                (data['careerStartDate'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
            regionalFanbase: loadedRegionalFanbase,
            avatarUrl: data['avatarUrl'] as String?,
            activeSideHustle: loadedSideHustle,
            primaryGenre: primaryGenre,
            genreMastery: loadedGenreMastery,
            unlockedGenres: loadedUnlockedGenres,
          );
        });

        // Check if player missed days while offline
        await _checkForMissedDays(data);

        // Load pending practices
        await _loadPendingPractices();

        // Check for completed practices
        await _checkCompletedPractices();

        // Set up real-time listeners AFTER profile is loaded
        _setupRealtimeListeners();
      } else {
        print('⚠️ Profile not found in Firestore, using demo stats');
        // Show a message to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile not found. Using demo mode.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      print('💡 Retrying profile load in 3 seconds...');

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e. Retrying...'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Retry loading after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            print('🔄 Retrying profile load...');
            _loadUserProfile();
          }
        });
      }
    }
  }

  /// Set up real-time Firestore listeners for instant updates (gifts, stats changes, etc.)
  void _setupRealtimeListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ No user signed in, skipping real-time listeners');
      return;
    }

    print('🔔 Setting up real-time listeners for: ${user.uid}');

    // Listen to player document changes (stats updates from admin gifts, etc.)
    _playerDataSubscription = FirebaseFirestore.instance
        .collection('players')
        .doc(user.uid)
        .snapshots()
        .listen(
      (snapshot) async {
        if (!snapshot.exists || !mounted) return;

        final data = snapshot.data()!;
        print('📡 Real-time update received for player stats');
        print('💰 Money from Firestore: ${data['currentMoney']}');

        // Temporarily disable auto-save to prevent overwriting the update
        final hadPendingSave = _hasPendingSave;
        _hasPendingSave = false;

        // Load songs from the update
        List<Song> loadedSongs = [];
        if (data['songs'] != null) {
          try {
            final songsList = data['songs'] as List<dynamic>;
            loadedSongs = songsList
                .map((songData) =>
                    Song.fromJson(Map<String, dynamic>.from(songData)))
                .toList();
          } catch (e) {
            print('⚠️ Error loading songs in real-time update: $e');
          }
        }

        // Migration fallback: if songs array missing in snapshot, load from subcollection
        if (loadedSongs.isEmpty) {
          try {
            final songsSnap = await FirebaseFirestore.instance
                .collection('players')
                .doc(user.uid)
                .collection('songs')
                .get();
            loadedSongs = songsSnap.docs
                .map((d) =>
                    Song.fromJson(Map<String, dynamic>.from(d.data() as Map)))
                .toList();
            if (loadedSongs.isNotEmpty) {
              print(
                  'ℹ️ [RT] Loaded ${loadedSongs.length} songs from subcollection');
            }
          } catch (e) {
            print('⚠️ [RT] Fallback songs subcollection load failed: $e');
          }
        }

        // Load albums from the update
        List<Album> loadedAlbums = [];
        if (data['albums'] != null) {
          try {
            final albumsList = data['albums'] as List<dynamic>;
            loadedAlbums = albumsList
                .map((albumData) =>
                    Album.fromJson(Map<String, dynamic>.from(albumData)))
                .toList();
          } catch (e) {
            print('⚠️ Error loading albums in real-time update: $e');
          }
        }

        // Migration fallback: if albums array missing in snapshot, load from subcollection
        if (loadedAlbums.isEmpty) {
          try {
            final albumsSnap = await FirebaseFirestore.instance
                .collection('players')
                .doc(user.uid)
                .collection('albums')
                .get();
            loadedAlbums = albumsSnap.docs
                .map((d) =>
                    Album.fromJson(Map<String, dynamic>.from(d.data() as Map)))
                .toList();
            if (loadedAlbums.isNotEmpty) {
              print(
                  'ℹ️ [RT] Loaded ${loadedAlbums.length} albums from subcollection');
            }
          } catch (e) {
            print('⚠️ [RT] Fallback albums subcollection load failed: $e');
          }
        }

        // Load regional fanbase
        Map<String, int> loadedRegionalFanbase = {};
        if (data['regionalFanbase'] != null) {
          try {
            final regionalData =
                data['regionalFanbase'] as Map<dynamic, dynamic>;
            loadedRegionalFanbase = regionalData.map(
              (key, value) => MapEntry(key.toString(), safeParseInt(value)),
            );
          } catch (e) {
            print('⚠️ Error loading regional fanbase in real-time: $e');
          }
        }

        // Load active side hustle
        SideHustle? loadedSideHustle;
        if (data['activeSideHustle'] != null) {
          try {
            loadedSideHustle = SideHustle.fromJson(
              Map<String, dynamic>.from(data['activeSideHustle']),
            );
          } catch (e) {
            print('⚠️ Error loading side hustle in real-time: $e');
          }
        }

        // Load genre data
        final String primaryGenre = data['primaryGenre'] ?? 'Hip Hop';
        Map<String, int> loadedGenreMastery = {};
        if (data['genreMastery'] != null) {
          final masteryData = Map<String, dynamic>.from(
              data['genreMastery'] as Map<dynamic, dynamic>);
          loadedGenreMastery = masteryData.map(
            (key, value) => MapEntry(key.toString(), safeParseInt(value)),
          );
        }

        List<String> loadedUnlockedGenres = [];
        if (data['unlockedGenres'] != null) {
          loadedUnlockedGenres = List<String>.from(data['unlockedGenres']);
        } else {
          loadedUnlockedGenres = [primaryGenre];
          loadedGenreMastery[primaryGenre] = 0;
        }

        // Update UI with new data
        setState(() {
          artistStats = ArtistStats(
            name: data['displayName'] ?? artistStats.name,
            fame: safeParseInt(data['currentFame'], fallback: artistStats.fame),
            money:
                safeParseInt(data['currentMoney'], fallback: artistStats.money),
            energy: safeParseInt(data['energy'], fallback: artistStats.energy),
            creativity: safeParseInt(data['inspirationLevel'],
                fallback: artistStats.creativity),
            fanbase:
                safeParseInt(data['fanbase'], fallback: artistStats.fanbase),
            loyalFanbase: safeParseInt(data['loyalFanbase'],
                fallback: artistStats.loyalFanbase),
            albumsSold: safeParseInt(data['albumsReleased'],
                fallback: artistStats.albumsSold),
            songsWritten: safeParseInt(data['songsPublished'],
                fallback: artistStats.songsWritten),
            concertsPerformed: safeParseInt(data['concertsPerformed'],
                fallback: artistStats.concertsPerformed),
            songwritingSkill: safeParseInt(data['songwritingSkill'],
                fallback: artistStats.songwritingSkill),
            experience: safeParseInt(data['experience'],
                fallback: artistStats.experience),
            lyricsSkill: safeParseInt(data['lyricsSkill'],
                fallback: artistStats.lyricsSkill),
            compositionSkill: safeParseInt(data['compositionSkill'],
                fallback: artistStats.compositionSkill),
            inspirationLevel: safeParseInt(data['inspirationLevel'],
                fallback: artistStats.inspirationLevel),
            songs: loadedSongs,
            albums: loadedAlbums,
            currentRegion: data['homeRegion'] ?? artistStats.currentRegion,
            age: safeParseInt(data['age'], fallback: artistStats.age),
            careerStartDate:
                (data['careerStartDate'] as Timestamp?)?.toDate() ??
                    artistStats.careerStartDate,
            regionalFanbase: loadedRegionalFanbase,
            avatarUrl: data['avatarUrl'] as String?,
            activeSideHustle: loadedSideHustle,
            primaryGenre: primaryGenre,
            genreMastery: loadedGenreMastery,
            unlockedGenres: loadedUnlockedGenres,
          );
        });

        print('✅ Real-time stats updated successfully');
        print('💵 Updated money to: ${artistStats.money}');

        // Restore the pending save flag after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && hadPendingSave) {
            _hasPendingSave = true;
          }
        });
      },
      onError: (error) {
        print('❌ Error in player data listener: $error');
      },
    );

    // Listen to notifications collection for admin gifts, etc.
    // Simplified query to avoid needing a composite index
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('players')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .limit(10)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            print('🎁 New notification: ${data['title']}');

            // Determine icon based on notification type
            IconData icon;
            switch (data['type']) {
              case 'admin_gift':
                icon = Icons.card_giftcard;
                break;
              case 'achievement':
                icon = Icons.emoji_events;
                break;
              case 'warning':
                icon = Icons.warning;
                break;
              default:
                icon = Icons.notifications;
            }

            // Add to notification list
            _addNotification(
              data['title'] ?? 'Notification',
              data['message'] ?? '',
              icon: icon,
            );

            // Show notification snackbar
            _showNotificationSnackBar(
              data['title'] ?? 'Notification',
              data['message'] ?? '',
              data['type'] ?? 'info',
            );

            // Mark as read after showing
            change.doc.reference.update({'read': true});

            // Update unread count
            _loadUnreadNotificationCount();
          }
        }
      },
      onError: (error) {
        print('❌ Error in notifications listener: $error');
      },
    );

    print('✅ Real-time listeners set up successfully');
  }

  /// Load unread notification count
  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      print('❌ Error loading unread notification count: $e');
    }
  }

  /// Show a notification snackbar with custom styling based on type
  void _showNotificationSnackBar(String title, String message, String type) {
    if (!mounted) return;

    Color backgroundColor;
    IconData icon;

    switch (type) {
      case 'admin_gift':
        backgroundColor = const Color(0xFFFFD700); // Gold
        icon = Icons.card_giftcard;
        break;
      case 'achievement':
        backgroundColor = const Color(0xFF32D74B); // Green
        icon = Icons.emoji_events;
        break;
      case 'warning':
        backgroundColor = const Color(0xFFFF9500); // Orange
        icon = Icons.warning;
        break;
      default:
        backgroundColor = const Color(0xFF00D9FF); // Cyan
        icon = Icons.notifications;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Check if player was offline and show welcome back message
  /// Note: Server handles all daily updates automatically at midnight UTC
  /// This just shows the player what they earned while away
  Future<void> _checkForMissedDays(Map<String, dynamic> data) async {
    try {
      // Get last active time
      final lastActiveTimestamp = data['lastActive'] as Timestamp?;
      if (lastActiveTimestamp == null) {
        print('⚠️ No lastActive timestamp');
        return;
      }

      final lastActive = lastActiveTimestamp.toDate();
      final currentGameDate = await _gameTimeService.getCurrentGameDate();

      // Calculate how many in-game days passed since last login
      final daysMissed = currentGameDate
          .difference(
            DateTime(lastActive.year, lastActive.month, lastActive.day),
          )
          .inDays;

      if (daysMissed <= 0) {
        print('✅ Player is up to date');
        return;
      }

      print('🌅 Player was offline for $daysMissed day(s)');

      // Server already updated everything!
      // Just calculate what they earned to show them
      int totalStreams = 0;
      int previousMoney = data['previousMoney'] ?? artistStats.money;
      int incomeEarned = artistStats.money - previousMoney;

      // Calculate total streams earned (approximate)
      for (final song in artistStats.songs) {
        if (song.state == SongState.released) {
          totalStreams += song.lastDayStreams * daysMissed;
        }
      }

      // Show welcome back message
      if (daysMissed > 0) {
        _addNotification(
          'Welcome Back!',
          'While you were away for $daysMissed day(s), your music earned ${_streamGrowthService.formatStreams(totalStreams)} streams and \$$incomeEarned! 🎉',
          icon: Icons.celebration,
        );

        _showMessage(
          '💰 Offline earnings: \$$incomeEarned from $daysMissed day(s)!',
        );
      }
    } catch (e) {
      print('❌ Error checking missed days: $e');
      // Don't fail the login if this check fails
    }
  }

  /// Load Firebase notifications (gifts from admin, system notifications, etc.)
  Future<void> _loadFirebaseNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🔔 Loading Firebase notifications...');

      // Query unread notifications
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('players')
          .doc(user.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      if (!mounted) return;

      // Process each notification
      for (var doc in notificationsSnapshot.docs) {
        final data = doc.data();

        // Add to in-app notification list
        _addNotification(
          data['title'] ?? '🔔 Notification',
          data['message'] ?? '',
          icon: data['type'] == 'admin_gift'
              ? Icons.card_giftcard
              : Icons.info_outline,
        );

        // Mark as read in Firebase
        await doc.reference.update({'read': true});
      }

      if (notificationsSnapshot.docs.isNotEmpty) {
        print(
            '✅ Loaded ${notificationsSnapshot.docs.length} new notifications');
      }
    } catch (e) {
      print('❌ Error loading Firebase notifications: $e');
    }
  }

  Future<void> _saveUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ No user signed in, cannot save profile');
        return;
      }

      print('💾 Saving user profile for: ${user.uid}');

      // Use secure Firebase service instead of direct writes
      await FirebaseService().updatePlayerStats(artistStats);

      _hasPendingSave = false;
      print('✅ Profile saved successfully');
    } catch (e) {
      print('❌ Error saving profile: $e');
    }
  }

  /// Debounced save - batches rapid requests into a single Firebase write
  /// Short 500ms delay for multiplayer sync - balances responsiveness with cost
  /// For critical multiplayer updates, call _saveUserProfile() directly instead
  void _debouncedSave() {
    _hasPendingSave = true;

    // Cancel any existing timer
    _saveDebounceTimer?.cancel();

    // Short debounce for multiplayer - only prevents rapid-fire spam
    // 500ms is fast enough for good sync, but prevents excessive writes during UI interactions
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_hasPendingSave && mounted) {
        _saveUserProfile();
      }
    });
  }

  /// Immediate save for critical multiplayer events
  /// Use this for: publishing songs, completing contracts, major achievements, region changes
  void _immediateSave() {
    _saveDebounceTimer?.cancel();
    _hasPendingSave = false;
    _saveUserProfile();
  }

  // === PENDING PRACTICE MANAGEMENT ===

  /// Load pending practices from Firestore
  Future<void> _loadPendingPractices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('players')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['pendingPractices'] != null) {
        final practicesList = doc.data()!['pendingPractices'] as List<dynamic>;
        setState(() {
          pendingPractices = practicesList
              .map((data) =>
                  PendingPractice.fromMap(Map<String, dynamic>.from(data)))
              .toList();
        });
        print('✅ Loaded ${pendingPractices.length} pending practices');
      }
    } catch (e) {
      print('❌ Error loading pending practices: $e');
    }
  }

  /// Save pending practices to Firestore
  Future<void> _savePendingPractices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final sanitizedPractices =
          pendingPractices.map((p) => sanitizeForFirestore(p.toMap())).toList();
      await FirebaseFirestore.instance
          .collection('players')
          .doc(user.uid)
          .update(sanitizeForFirestore({
            'pendingPractices': sanitizedPractices,
          }));

      print('✅ Saved ${pendingPractices.length} pending practices');
    } catch (e) {
      print('❌ Error saving pending practices: $e');
    }
  }

  /// Check for completed practices and apply their benefits
  Future<void> _checkCompletedPractices() async {
    if (currentGameDate == null) return;

    final completedPractices = pendingPractices
        .where((practice) => practice.isComplete(currentGameDate!))
        .toList();

    if (completedPractices.isEmpty) return;

    print('🎓 Found ${completedPractices.length} completed practices!');

    for (final practice in completedPractices) {
      // Apply the skill gains based on practice type
      setState(() {
        switch (practice.practiceType) {
          case 'songwriting':
            artistStats = artistStats.copyWith(
              songwritingSkill:
                  artistStats.songwritingSkill + practice.skillGain,
              experience: artistStats.experience + practice.xpGain,
            );
            break;
          case 'lyrics':
            artistStats = artistStats.copyWith(
              lyricsSkill: artistStats.lyricsSkill + practice.skillGain,
              experience: artistStats.experience + practice.xpGain,
            );
            break;
          case 'composition':
            artistStats = artistStats.copyWith(
              compositionSkill:
                  artistStats.compositionSkill + practice.skillGain,
              experience: artistStats.experience + practice.xpGain,
            );
            break;
          case 'inspiration':
            artistStats = artistStats.copyWith(
              inspirationLevel:
                  artistStats.inspirationLevel + practice.skillGain,
              experience: artistStats.experience + practice.xpGain,
            );
            break;
          default:
            // Unknown practice type — award XP only
            artistStats = artistStats.copyWith(
              experience: artistStats.experience + practice.xpGain,
            );
        }
      });
    }

    // Remove completed practices
    setState(() {
      pendingPractices.removeWhere(
        (practice) => practice.isComplete(currentGameDate!),
      );
    });

    // Save the updated state
    await _savePendingPractices();
    _immediateSave(); // Save stats with new skills

    // Show notification to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎓 Training complete! Gained skills from ${completedPractices.length} program(s)',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _updateGameDate() async {
    // Check if widget is still mounted before doing anything
    if (!mounted) return;
    if (_lastSyncTime == null || currentGameDate == null) return;

    try {
      // Get the current game date from Firebase (date-only, no time component)
      final newGameDate = await _gameTimeService.getCurrentGameDate();

      // Check again if still mounted after async operation
      if (!mounted) return;

      // Check if the day has changed
      if (newGameDate.day != currentGameDate!.day ||
          newGameDate.month != currentGameDate!.month ||
          newGameDate.year != currentGameDate!.year) {
        print(
          '🌅 Day changed! Old: ${currentGameDate!.day} → New: ${newGameDate.day}',
        );

        // ✅ RELOAD stats from Firebase (Cloud Function has updated streams/money/fanbase/fame)
        print('🔄 Reloading player stats from server...');
        await _loadUserProfile();

        // ❌ REMOVED: Client-side stream calculation (_applyDailyStreamGrowth)
        // ALL progression stats are now server-authoritative (full Option A implementation)
        // Server calculates: streams, last7DaysStreams, income, fanbase, fame
        // Client only handles: energy replenishment, UI updates, side hustle energy cost

        // Check for side hustle expiration (client-side check only)
        bool sideHustleExpired = false;
        if (artistStats.activeSideHustle != null) {
          final result = _sideHustleService.applyDailySideHustle(
            sideHustle: artistStats.activeSideHustle!,
            currentMoney: artistStats.money,
            currentEnergy: artistStats.energy,
            currentGameDate: newGameDate,
          );
          sideHustleExpired = result['expired'] == 1;
        }

        // Update last sync time
        _lastSyncTime = DateTime.now();

        // Replenish energy for the new day (only if still mounted)
        if (mounted) {
          setState(() {
            currentGameDate = newGameDate;
            _lastEnergyReplenishDay = newGameDate.day;
            // Cap daily energy restore at 100, but allow energy to exceed 100 from gifts/purchases
            final restoredEnergy =
                artistStats.energy < 100 ? 100 : artistStats.energy;
            artistStats = artistStats.copyWith(
              energy: restoredEnergy,
              clearSideHustle: sideHustleExpired,
            );
          });

          if (artistStats.energy < 100) {
            _showMessage('☀️ New day! Energy restored to 100');
          } else {
            _showMessage(
                '☀️ New day! You still have ${artistStats.energy} energy');
          }

          if (sideHustleExpired) {
            _addNotification(
              'Contract Ended',
              'Your ${artistStats.activeSideHustle!.type.displayName} contract has ended!',
              icon: Icons.work_off,
            );
          }

          _addNotification(
            'New Day Stats',
            'Your daily streams, royalties, and fanbase have been updated by the server!',
            icon: Icons.cloud_done,
          );

          final energyMessage = artistStats.energy < 100
              ? 'A new day has begun! Your energy has been restored to 100.'
              : 'A new day has begun! Your current energy: ${artistStats.energy}';

          _addNotification(
            'Energy Update',
            energyMessage,
            icon: Icons.wb_sunny,
          );
          print(
            '✅ Energy restored - Game Date: ${_gameTimeService.formatGameDate(newGameDate)}',
          );

          // Check for completed practice programs
          await _checkCompletedPractices();
        }
      } else {
        // Same day, just update passive income
        final now = DateTime.now();
        final realSecondsSinceLastUpdate =
            now.difference(_lastSyncTime!).inSeconds;

        // Only calculate if significant time has passed (at least 1 minute)
        if (realSecondsSinceLastUpdate >= 60) {
          _calculatePassiveIncome(realSecondsSinceLastUpdate);
          _lastSyncTime = now;
        }
      }
    } catch (e) {
      print('❌ Error updating game date: $e');
    }
  }

  /// Update the countdown timer showing time until next game day
  void _updateCountdown() {
    if (!mounted) return;

    final duration = _gameTimeService.getTimeUntilNextGameDay();
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    setState(() {
      _timeUntilNextDay =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  void _calculatePassiveIncome(int realSecondsPassed) {
    // Get all released songs
    final releasedSongs =
        artistStats.songs.where((s) => s.state == SongState.released).toList();

    if (releasedSongs.isEmpty) return;

    // Calculate streams per second for each song based on quality and platforms
    double totalIncomePerSecond = 0;
    int totalStreamsGained = 0;

    for (final song in releasedSongs) {
      // Streams scale with artist fame and song quality
      // Early game: very few streams, late game: meaningful income
      final qualityFactor = song.finalQuality / 100.0; // 0-1 range
      final fameFactor = (artistStats.fame / 100.0).clamp(
        0.1,
        10.0,
      ); // 0.1x to 10x multiplier
      final fanbaseFactor = (artistStats.fanbase / 1000.0).clamp(
        0.1,
        5.0,
      ); // Fanbase matters

      // Much more conservative streaming - realistic artist journey
      final baseStreamsPerSecond =
          0.01 * qualityFactor; // 0-0.01 streams/sec base
      final scaledStreams = baseStreamsPerSecond * fameFactor * fanbaseFactor;
      final streamsGained = (scaledStreams * realSecondsPassed).round();

      // Calculate income based on platforms (realistic rates)
      double incomeForThisSong = 0;
      for (final platformId in song.streamingPlatforms) {
        if (platformId == 'tunify') {
          incomeForThisSong +=
              streamsGained * 0.003; // $0.003 per stream (Spotify rate)
        } else if (platformId == 'maple_music') {
          incomeForThisSong +=
              streamsGained * 0.01; // $0.01 per stream (premium platform)
        }
      }

      totalIncomePerSecond += incomeForThisSong / realSecondsPassed;
      totalStreamsGained += streamsGained;

      // Update song with new stream count
      final songIndex = artistStats.songs.indexOf(song);
      if (songIndex != -1) {
        artistStats.songs[songIndex] = song.copyWith(
          streams: song.streams + streamsGained,
        );
      }
    }

    // Only show notification if earning something meaningful (avoid tiny fractions)
    // ❌ REMOVED: Money update (passive income is display-only, actual income from Cloud Function)
    if (totalStreamsGained > 0) {
      final totalIncome = (totalIncomePerSecond * realSecondsPassed);

      // Note: We DON'T update money here anymore - Cloud Function handles income
      // This prevents duplicate income from passive calculations + server calculations

      // Show notification for significant streaming activity (every $100+ estimated)
      if (totalIncome >= 100 &&
          DateTime.now()
                  .difference(_lastPassiveIncomeTime ?? DateTime.now())
                  .inSeconds >
              60) {
        _lastPassiveIncomeTime = DateTime.now();
        print(
          '� Streaming activity: ~\$${totalIncome.toStringAsFixed(2)} estimated from $totalStreamsGained streams',
        );
        _addNotification(
          'Streaming Activity',
          'Your ${releasedSongs.length} song${releasedSongs.length > 1 ? 's' : ''} is getting ${_streamGrowthService.formatStreams(totalStreamsGained)} streams!',
          icon: Icons.music_note,
        );
      }
    }
  }

  // ❌ REMOVED: _applyDailyStreamGrowth function
  // ALL progression stats (streams, money, fanbase, fame) are now server-authoritative
  // Cloud Function (dailyGameUpdate) handles:
  //   - Stream growth calculation
  //   - last7DaysStreams decay + addition
  //   - Regional stream distribution
  //   - Income calculation
  //   - Fanbase/fame growth
  // Client only handles:
  //   - Energy replenishment
  //   - Side hustle energy cost
  //   - UI updates
  //   - Loading server data

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF32FF32),
      ),
    );
  }

  void _addNotification(
    String title,
    String message, {
    IconData icon = Icons.info_outline,
  }) {
    setState(() {
      _notifications.insert(0, {
        'title': title,
        'message': message,
        'icon': icon,
        'time': DateTime.now(),
      });
      // Keep only last 20 notifications
      if (_notifications.length > 20) {
        _notifications.removeLast();
      }
    });
  }

  void _showNotifications() {
    // Navigate to the full notifications screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    ).then((_) {
      // Reload unread count when returning from notifications screen
      _loadUnreadNotificationCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // GitHub dark background
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF00D9FF),
        backgroundColor: const Color(0xFF21262D),
        child: SafeArea(
          child: Column(
            children: [
              // Show loading banner if profile not loaded
              if (artistStats.name == "Loading...")
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFE94560)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Loading profile... Pull down to refresh if stuck.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: Colors.white, size: 20),
                        onPressed: _handleRefresh,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Top Status Bar
                      _buildTopStatusBar(),
                      // Game Status Row
                      _buildGameStatusRow(),
                      // Profile Section (simplified)
                      _buildProfileSection(),
                      // Action Panel - Core gameplay (now scrollable)
                      _buildActionPanel(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTopStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date-only display (simplified!)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF00D9FF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentGameDate != null
                        ? _gameTimeService.formatGameDate(currentGameDate!)
                        : 'Syncing...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_timeUntilNextDay.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFFFFD60A),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Next day in: $_timeUntilNextDay',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Money and Energy Display
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Money
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF32D74B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF32D74B),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _formatMoney(artistStats.money.toDouble()),
                            style: const TextStyle(
                              color: Color(0xFF32D74B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Energy
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B9D).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF6B9D),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: Color(0xFFFF6B9D),
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${artistStats.energy}',
                        style: const TextStyle(
                          color: Color(0xFFFF6B9D),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Notification and Settings Buttons
          Row(
            children: [
              // Notification Button
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      _showNotifications();
                    },
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B9D),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_unreadNotificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // Settings Button
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        artistStats: artistStats,
                        onStatsUpdated: (updatedStats) {
                          setState(() {
                            artistStats = updatedStats;
                          });
                          _debouncedSave();
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return '$number';
    }
  }

  Widget _buildGameStatusRow() {
    // Calculate fame bonuses for tooltip
    final streamBonus = ((artistStats.fameStreamBonus - 1.0) * 100).round();
    final fanBonus = ((artistStats.fameFanConversionBonus - 1.0) * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message:
                  'Stream Bonus: +$streamBonus%\nFan Conversion: +$fanBonus%\n\n${artistStats.fameTier}\nTap to see fame benefits',
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2128),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE94560), width: 1),
              ),
              child: _buildAdvancedStatusCard(
                'Fame',
                artistStats.fame,
                100, // Max value for progress bar
                Icons.stars_rounded,
                const Color(0xFFE94560), // Red
                const Color(0xFF16213E), // Dark blue
                artistStats
                    .fameTier, // ✨ Show fame tier instead of generic label
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildAdvancedStatusCard(
              'Hype',
              artistStats.creativity,
              500, // Max value for progress bar
              Icons.whatshot_rounded,
              const Color(0xFF9B59B6), // Purple
              const Color(0xFF2C3E50), // Dark slate
              'Viral',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildAdvancedStatusCard(
              'Fanbase',
              artistStats.fanbase,
              artistStats.fanbase + 1000, // Dynamic max value for progress
              Icons.people_rounded,
              const Color(0xFF00D9FF), // Cyan
              const Color(0xFF1A252F), // Dark navy
              _formatNumber(artistStats.fanbase),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedStatusCard(
    String title,
    int value,
    int maxValue,
    IconData icon,
    Color primaryColor,
    Color backgroundColor,
    String status,
  ) {
    double progress = (value / maxValue).clamp(0.0, 1.0);

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row with icon and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: primaryColor, size: 16),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bottom section with title, value, and progress
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Show numeric fame for the Fame card; otherwise show status text.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title == 'Fame' ? _formatNumber(value) : status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Progress bar
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          // Profile Info with enhanced styling
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: artistStats.avatarUrl == null
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    image: artistStats.avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(artistStats.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: artistStats.avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artistStats.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentGameDate != null
                          ? '${artistStats.getCurrentAge(currentGameDate!)} years old • ${artistStats.fameTier}'
                          : '${artistStats.age} years old • ${artistStats.fameTier}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Skills Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D9FF).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Color(0xFF00D9FF), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Skills & Experience',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSkillBar(
                      'Songwriting',
                      artistStats.songwritingSkill,
                      const Color(0xFF00D9FF),
                    ),
                    const SizedBox(width: 12),
                    _buildSkillBar(
                      'Lyrics',
                      artistStats.lyricsSkill,
                      const Color(0xFFFF6B9D),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSkillBar(
                      'Composition',
                      artistStats.compositionSkill,
                      const Color(0xFF9B59B6),
                    ),
                    const SizedBox(width: 12),
                    _buildSkillBar(
                      'Inspiration',
                      artistStats.inspirationLevel,
                      const Color(0xFFF39C12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2ECC71).withOpacity(0.2),
                        const Color(0xFF27AE60).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFF2ECC71),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Experience: ${artistStats.experience} XP',
                        style: const TextStyle(
                          color: Color(0xFF2ECC71),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Level ${(artistStats.experience / 100).floor() + 1}',
                        style: const TextStyle(
                          color: Color(0xFF2ECC71),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Color(0xFF00D9FF),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid columns based on width
              int crossAxisCount = 2;
              double childAspectRatio = 2.0;

              if (constraints.maxWidth < 400) {
                // Small mobile (less than 400px)
                crossAxisCount = 2;
                childAspectRatio = 1.8;
              } else if (constraints.maxWidth >= 600 &&
                  constraints.maxWidth < 1024) {
                // Tablet
                crossAxisCount = 3;
                childAspectRatio = 2.2;
              } else if (constraints.maxWidth >= 1024) {
                // Desktop
                crossAxisCount = 4;
                childAspectRatio = 2.5;
              }

              return GridView.count(
                physics: const AlwaysScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildActionCard(
                    'Write Song',
                    Icons.edit_rounded,
                    const Color(0xFF00D9FF),
                    energyCost: 15,
                    onTap: () => _performAction('write_song'),
                    customCostText: '15-40',
                  ),
                  _buildActionCard(
                    'Studio',
                    Icons.album_rounded,
                    const Color(0xFF9B59B6),
                    energyCost: -1,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudiosListScreen(
                            artistStats: artistStats,
                            onStatsUpdated: (updatedStats) {
                              setState(() {
                                artistStats = updatedStats;
                              });
                              _debouncedSave(); // ✅ Save after recording songs
                            },
                          ),
                        ),
                      );
                    },
                    customCostText: 'Record',
                  ),
                  _buildActionCard(
                    'Releases',
                    Icons.library_music_rounded,
                    const Color(0xFFE94560),
                    energyCost: -1,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReleaseManagerScreen(
                            artistStats: artistStats,
                            onStatsUpdated: (updatedStats) {
                              setState(() {
                                artistStats = updatedStats;
                              });
                              _debouncedSave(); // ✅ Save after releasing albums
                            },
                          ),
                        ),
                      );
                    },
                    customCostText: 'EPs/Albums',
                  ),
                  _buildActionCard(
                    'Spotlight',
                    Icons.bar_chart_rounded,
                    const Color(0xFF4CAF50),
                    energyCost: -1,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UnifiedChartsScreen(),
                        ),
                      );
                    },
                    customCostText: 'Charts',
                  ),
                  _buildActionCard(
                    'The Scoop',
                    Icons.newspaper_rounded,
                    const Color(0xFFFF9800),
                    energyCost: -1,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TheScoopScreen(),
                        ),
                      );
                    },
                    customCostText: 'News',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color, {
    required int energyCost,
    required VoidCallback onTap,
    String? customCostText,
  }) {
    bool canPerform = energyCost < 0 || artistStats.energy >= energyCost;

    return GestureDetector(
      onTap: canPerform ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canPerform
                ? [color.withOpacity(0.8), color.withOpacity(0.6)]
                : [Colors.grey.withOpacity(0.4), Colors.grey.withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canPerform
                ? color.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: canPerform
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(canPerform ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color:
                      canPerform ? Colors.white : Colors.white.withOpacity(0.5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: canPerform
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      customCostText ??
                          (energyCost < 0 ? '+${-energyCost}' : '-$energyCost'),
                      style: TextStyle(
                        color: canPerform
                            ? (energyCost < 0
                                ? const Color(0xFF32D74B)
                                : Colors.white.withOpacity(0.7))
                            : Colors.white.withOpacity(0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performAction(String action) {
    setState(() {
      switch (action) {
        case 'write_song':
          if (artistStats.energy >= 20) {
            _showSongWritingDialog();
          }
          break;
        // Concert feature removed
        case 'record_album':
          // Count recorded songs (not yet released)
          final recordedSongs = artistStats.songs
              .where((s) => s.state == SongState.recorded)
              .length;

          if (artistStats.energy >= 40 && recordedSongs >= 3) {
            // Find the 3 recorded songs to use for the album
            final songsToRelease = artistStats.songs
                .where((s) => s.state == SongState.recorded)
                .take(3)
                .toList();

            // Update those songs to released state
            final updatedSongs = artistStats.songs.map((song) {
              if (songsToRelease.contains(song)) {
                return song.copyWith(
                  state: SongState.released,
                  releasedDate: currentGameDate,
                );
              }
              return song;
            }).toList();

            // Calculate album earnings based on fame and song quality
            final avgQuality = songsToRelease
                    .map((s) => s.finalQuality)
                    .reduce((a, b) => a + b) /
                songsToRelease.length;
            final baseAlbumRevenue = 2000; // Base album advance
            final qualityBonus =
                (avgQuality / 100) * 3000; // Up to $3K for quality
            final fameBonus = artistStats.fame * 50; // $50 per fame point
            final albumEarnings =
                (baseAlbumRevenue + qualityBonus + fameBonus).round();
            final fameGain =
                5 + (avgQuality ~/ 20); // 5-10 fame based on quality

            artistStats = artistStats.copyWith(
              energy: artistStats.energy - 40,
              albumsSold: artistStats.albumsSold + 1,
              songsWritten:
                  artistStats.songsWritten + 3, // ✅ Count 3 released songs!
              money: artistStats.money + albumEarnings,
              fame: artistStats.fame + fameGain,
              songs: updatedSongs,
              fanbase: artistStats.fanbase +
                  (50 + (fameGain * 10)), // Album releases attract more fans
            );
            _showMessage(
              '💿 Album released! Fame +$fameGain, +\$${albumEarnings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}\n3 songs now streaming!',
            );
            _addNotification(
              'Album Released!',
              'Your new album is out! Gained +$fameGain Fame and earned \$${albumEarnings.toStringAsFixed(0)}. Your songs are now earning passive income!',
              icon: Icons.album_rounded,
            );
          } else if (recordedSongs < 3) {
            _showMessage(
              '❌ Need at least 3 RECORDED songs to release an album\nGo to the Studio to record your written songs!',
            );
          }
          break;
        // REMOVED: Quick practice from dashboard
        // Players must use the dedicated Practice screen from Activity Hub
        case 'social_media':
          if (artistStats.energy >= 10) {
            artistStats = artistStats.copyWith(
              energy: artistStats.energy - 10,
              fame: artistStats.fame + 3,
              creativity: artistStats.creativity + 2,
            );
            _showMessage('📱 Posted on social media! Hype +2, Fame +3');
          }
          break;
      }
    });
  }

  void _showSongWritingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF21262D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎵 Write a Song',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Single action: write a custom song
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCustomSongForm();
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Write Custom Song',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Quick write flow removed per product decision

  // _writeSong and quick templates removed

  void _showCustomSongForm() {
    final TextEditingController songTitleController = TextEditingController();
    // 🎸 Start with player's primary genre (first unlocked genre)
    String selectedGenre = artistStats.unlockedGenres.isNotEmpty
        ? artistStats.unlockedGenres.first
        : artistStats.primaryGenre;
    int selectedEffort = 2; // 1-4 scale
    List<String> nameSuggestions = [];

    // Generate initial suggestions based on default genre
    int estimatedQuality =
        artistStats.calculateSongQuality(selectedGenre, selectedEffort).round();
    nameSuggestions = SongNameGenerator.getSuggestions(
      selectedGenre,
      count: 4,
      quality: estimatedQuality,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            // Canonical genre list and normalization (centralized)
            final List<String> allGenres = Genres.all;
            selectedGenre = Genres.toCanonical(selectedGenre);
            final Set<String> unlockedLower =
                artistStats.unlockedGenres.map((g) => g.toLowerCase()).toSet();
            // Calculate energy cost for display
            int energyCost = _getEnergyCostForEffort(selectedEffort);

            return Dialog(
              backgroundColor: const Color(0xFF21262D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Center(
                        child: Text(
                          '🎼 Create Your Song',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Song Title Input with Generate Button
                      Row(
                        children: [
                          const Text(
                            'Song Title:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              dialogSetState(() {
                                int quality = artistStats
                                    .calculateSongQuality(
                                      selectedGenre,
                                      selectedEffort,
                                    )
                                    .round();
                                nameSuggestions =
                                    SongNameGenerator.getSuggestions(
                                  selectedGenre,
                                  count: 4,
                                  quality: quality,
                                );
                              });
                            },
                            icon: const Icon(
                              Icons.refresh,
                              size: 16,
                              color: Color(0xFF00D9FF),
                            ),
                            label: const Text(
                              'New Ideas',
                              style: TextStyle(
                                color: Color(0xFF00D9FF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: songTitleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter song title or pick a suggestion...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF30363D),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLength: 50,
                      ),
                      const SizedBox(height: 8),

                      // Name Suggestions
                      const Text(
                        '💡 Suggestions:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: nameSuggestions.map((suggestion) {
                          return GestureDetector(
                            onTap: () {
                              dialogSetState(() {
                                songTitleController.text = suggestion;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF00D9FF).withOpacity(0.3),
                                    const Color(0xFF9B59B6).withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF00D9FF,
                                  ).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                suggestion,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Genre Selection
                      const Text(
                        'Genre:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF30363D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedGenre,
                            dropdownColor: const Color(0xFF30363D),
                            style: const TextStyle(color: Colors.white),
                            items: allGenres.map((genre) {
                              // 🔒 Check if genre is unlocked
                              final bool isUnlocked =
                                  unlockedLower.contains(genre.toLowerCase());

                              return DropdownMenuItem(
                                value: genre,
                                enabled: isUnlocked, // Disable locked genres
                                child: Row(
                                  children: [
                                    // Show lock icon for locked genres
                                    if (!isUnlocked)
                                      const Icon(
                                        Icons.lock,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    if (!isUnlocked) const SizedBox(width: 4),
                                    Genres.getIcon(genre),
                                    const SizedBox(width: 8),
                                    Text(
                                      genre,
                                      style: TextStyle(
                                        color: isUnlocked
                                            ? Colors.white
                                            : Colors.grey,
                                      ),
                                    ),
                                    if (!isUnlocked)
                                      const Text(
                                        ' (Locked)',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              // Only allow changing to unlocked genres
                              if (value != null &&
                                  artistStats.unlockedGenres.contains(value)) {
                                dialogSetState(() {
                                  selectedGenre = value;
                                  // Regenerate suggestions when genre changes
                                  int quality = artistStats
                                      .calculateSongQuality(
                                        selectedGenre,
                                        selectedEffort,
                                      )
                                      .round();
                                  nameSuggestions =
                                      SongNameGenerator.getSuggestions(
                                    selectedGenre,
                                    count: 4,
                                    quality: quality,
                                  );
                                });
                              }
                            },
                            isExpanded: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Effort Level Selection
                      const Text(
                        'Effort Level:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [1, 2, 3, 4].map((effort) {
                          bool isSelected = selectedEffort == effort;
                          bool canAfford = artistStats.energy >=
                              _getEnergyCostForEffort(effort);

                          return GestureDetector(
                            onTap: canAfford
                                ? () {
                                    dialogSetState(() {
                                      selectedEffort = effort;
                                      // Regenerate suggestions when effort changes
                                      int quality = artistStats
                                          .calculateSongQuality(
                                            selectedGenre,
                                            selectedEffort,
                                          )
                                          .round();
                                      nameSuggestions =
                                          SongNameGenerator.getSuggestions(
                                        selectedGenre,
                                        count: 4,
                                        quality: quality,
                                      );
                                    });
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00D9FF)
                                    : canAfford
                                        ? const Color(0xFF30363D)
                                        : const Color(0xFF30363D)
                                            .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00D9FF)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _getEffortName(effort),
                                    style: TextStyle(
                                      color: canAfford
                                          ? Colors.white
                                          : Colors.white30,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${_getEnergyCostForEffort(effort)} Energy',
                                    style: TextStyle(
                                      color: canAfford
                                          ? Colors.white70
                                          : Colors.white30,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Energy Cost Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF30363D).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Energy Cost:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '-$energyCost Energy',
                              style: TextStyle(
                                color: artistStats.energy >= energyCost
                                    ? const Color(0xFFFF6B9D)
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed:
                                  (songTitleController.text.trim().isNotEmpty &&
                                          artistStats.energy >= energyCost)
                                      ? () => _createCustomSong(
                                            songTitleController.text.trim(),
                                            selectedGenre,
                                            selectedEffort,
                                          )
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D9FF),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Create Song',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getEffortName(int effort) {
    switch (effort) {
      case 1:
        return 'Quick';
      case 2:
        return 'Focused';
      case 3:
        return 'Intense';
      case 4:
        return 'Masterwork';
      default:
        return 'Normal';
    }
  }

  int _getEnergyCostForEffort(int effort) {
    switch (effort) {
      case 1:
        return 15;
      case 2:
        return 25;
      case 3:
        return 35;
      case 4:
        return 45;
      default:
        return 25;
    }
  }

  String _getSongQualityRating(double quality) {
    if (quality >= 90) return "Legendary";
    if (quality >= 80) return "Masterpiece";
    if (quality >= 70) return "Excellent";
    if (quality >= 60) return "Great";
    if (quality >= 50) return "Good";
    if (quality >= 40) return "Decent";
    if (quality >= 30) return "Average";
    if (quality >= 20) return "Poor";
    return "Terrible";
  }

  void _createCustomSong(String title, String genre, int effort) {
    Navigator.of(context).pop(); // Close dialog

    // Calculate song quality and skill gains
    double songQuality = artistStats.calculateSongQuality(genre, effort);
    Map<String, int> skillGains = artistStats.calculateSkillGains(
      genre,
      effort,
      songQuality,
    );
    int energyCost = _getEnergyCostForEffort(effort);

    // Calculate rewards based on quality (no money - only from streams!)
    int fameGain = ((songQuality / 100) * 2 * effort).round();
    int creativityGain = effort * 2;

    // Create the new song object
    final newSong = Song(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      genre: genre,
      quality: songQuality.round(),
      createdDate: DateTime.now(),
      state: SongState.written,
    );

    // Calculate genre mastery gain
    int masteryGain = artistStats.calculateGenreMasteryGain(
      genre,
      effort,
      songQuality,
    );
    Map<String, int> updatedMastery = artistStats.applyGenreMasteryGain(
      genre,
      masteryGain,
    );

    setState(() {
      // Update main stats
      artistStats = artistStats.copyWith(
        energy: artistStats.energy - energyCost,
        // songsWritten removed - only counts when released
        // money removed - artists only earn from streams, not writing!
        fame: artistStats.fame + fameGain,
        creativity: artistStats.creativity + creativityGain,
        songs: [...artistStats.songs, newSong], // Add the new song
        // Update skills
        songwritingSkill:
            (artistStats.songwritingSkill + skillGains['songwritingSkill']!)
                .clamp(0, 100),
        experience: (artistStats.experience + skillGains['experience']!).clamp(
          0,
          10000,
        ),
        lyricsSkill: (artistStats.lyricsSkill + skillGains['lyricsSkill']!)
            .clamp(0, 100),
        compositionSkill:
            (artistStats.compositionSkill + skillGains['compositionSkill']!)
                .clamp(0, 100),
        inspirationLevel:
            (artistStats.inspirationLevel + skillGains['inspirationLevel']!)
                .clamp(0, 100),
        // Update genre mastery
        genreMastery: updatedMastery,
        lastActivityDate: DateTime.now(), // ✅ Update activity for fame decay
      );
    });

    _debouncedSave(); // Save after writing song

    // Show success message with song details and skill gains
    final qualityText = _getSongQualityRating(songQuality);
    _showMessage(
      '🎵 Created "$title" ($genre)!\n'
      'Quality: $qualityText | +$creativityGain Hype, +$fameGain Fame\n'
      '📈 +${skillGains['experience']} XP, Skills improved!',
    );
  }

  Widget _buildBottomNavigationBar() {
    return GlassmorphicBottomNav(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        }); // Handle navigation
        if (index == 1) {
          // Activity tab -> Activity Hub
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityHubScreen(
                artistStats: artistStats,
                onStatsUpdated: (updatedStats) {
                  setState(() {
                    artistStats = updatedStats;
                  });
                  _debouncedSave(); // Save stats to Firestore (debounced)
                },
                currentGameDate: currentGameDate ?? DateTime.now(),
                pendingPractices: pendingPractices,
                onPracticeStarted: (practice) {
                  setState(() {
                    pendingPractices.add(practice);
                  });
                  _savePendingPractices();
                  _debouncedSave();
                },
              ),
            ),
          );
        } else if (index == 2) {
          // Music tab -> Music Hub
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MusicHubScreen(
                artistStats: artistStats,
                onStatsUpdated: (updatedStats) {
                  setState(() {
                    artistStats = updatedStats;
                  });
                  _immediateSave(); // Immediate save - song releases are critical multiplayer events
                },
              ),
            ),
          );
        } else if (index == 3) {
          // The Scoop tab -> Music News Feed
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TheScoopScreen(),
            ),
          );
        } else if (index == 4) {
          // Media tab -> All Media Platforms
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaHubScreen(
                artistStats: artistStats,
                onStatsUpdated: (updatedStats) {
                  setState(() {
                    artistStats = updatedStats;
                  });
                  _debouncedSave(); // Debounced - social media posts can wait 500ms
                },
              ),
            ),
          );
        } else if (index == 5) {
          // World tab -> World Map
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorldMapScreen(
                artistStats: artistStats,
                onStatsUpdated: (updatedStats) {
                  setState(() {
                    artistStats = updatedStats;
                  });
                  _immediateSave(); // Immediate save - region changes affect multiplayer matchmaking
                },
              ),
            ),
          );
        } else {
          _showMessage('${_getNavItemName(index)} selected!');
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_activity),
          label: 'Activity',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Music'),
        BottomNavigationBarItem(
          icon: Icon(Icons.newspaper),
          label: 'The Scoop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt_rounded),
          label: 'Media',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.public), label: 'World'),
      ],
    );
  }

  String _getNavItemName(int index) {
    const names = ['Home', 'Activity', 'Music', 'The Scoop', 'Media', 'World'];
    return names[index];
  }

  // Add this helper method for skill bars
  Widget _buildSkillBar(String skillName, int skillLevel, Color color) {
    double progress = skillLevel / 100.0;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skillName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$skillLevel',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF30363D),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add Firebase initialization method
  Future<void> _initializeOnlineMode() async {
    if (_isInitializing) return; // Prevent multiple initialization attempts

    // Check if mounted before setState
    if (!mounted) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      // Check if Firebase was initialized successfully
      if (FirebaseStatus.isInitialized) {
        print('Firebase is available, attempting real Firebase service...');
        _multiplayerService = FirebaseService();
        await _multiplayerService.signInAnonymously();

        // Check if still mounted after async operation
        if (!mounted) return;

        if (_multiplayerService.isSignedIn) {
          setState(() {
            _isOnlineMode = true;
            _isInitializing = false;
          });
          print('✅ Connected to Firebase successfully!');
          return;
        }
      } else {
        print('Firebase not initialized: ${FirebaseStatus.errorMessage}');
      }
    } catch (e) {
      print('Firebase connection failed: $e');
    }

    // Check if still mounted before fallback
    if (!mounted) return;

    // Fallback to demo service
    print('Using demo service...');
    _multiplayerService = DemoFirebaseService();
    final success = await _multiplayerService.signInAnonymously();

    // Check if still mounted after async operation
    if (!mounted) return;

    setState(() {
      _isOnlineMode = success;
      _isInitializing = false;
    });

    if (success) {
      _showMessage(
        '🎮 Connected in Demo Mode! Leaderboards available via Activity tab.',
      );
    }

    if (_isOnlineMode) {
      // Update player stats periodically (with proper disposal)
      _multiplayerStatsTimer =
          Timer.periodic(const Duration(minutes: 5), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        _multiplayerService.updatePlayerStats(artistStats);
      });

      // Simulate song performance for all players
      _multiplayerService.simulateSongPerformance();
    }
  }
}
