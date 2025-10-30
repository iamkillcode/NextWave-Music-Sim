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
import '../models/pending_practice.dart';
import '../utils/app_logger.dart';
import '../theme/app_theme.dart';
import 'world_map_screen.dart';
import 'music_hub_screen.dart';
import 'studios_list_screen.dart';
import 'activity_hub_screen.dart';
import 'media_hub_screen.dart';
import 'release_manager_screen.dart';
import '../utils/firebase_status.dart';
import '../utils/firestore_sanitizer.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'the_scoop_screen.dart';
import 'unified_charts_screen.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';
import 'dart:ui';
import '../widgets/glassmorphic_bottom_nav.dart';
import '../services/admin_service.dart';
import '../services/certifications_service.dart';

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
  DateTime?
      _lastLocalUpdate; // Track recent local stat changes to prevent overwrites
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
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  final List<Map<String, dynamic>> _notifications = []; // Store notifications
  int _unreadNotificationCount = 0; // Track unread notification count
  String _timeUntilNextDay = ''; // Formatted time until next day
  bool _hasPendingSave = false; // Track if we have pending changes to save
  List<PendingPractice> pendingPractices =
      []; // Track ongoing training programs
  bool _isAdmin = false; // Admin quick-actions
  final _certificationsService = CertificationsService();
  final _adminService = AdminService();

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
        name: 'Loading...',
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

    // Initialize push notification service
    _pushNotificationService.initialize();

    // Load unread count
    _loadUnreadNotificationCount();

    // Initialize Firebase authentication
    _initializeOnlineMode();

    // Check admin access (non-blocking)
    _adminService.isAdmin().then((isAdmin) {
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }
    });

    // Date-only system: Check for day changes every 5 minutes (much more efficient!)
    gameTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      print('⏰ Timer tick: Running _updateGameDate() check...');
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
            backgroundColor: AppTheme.successGreen,
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
            backgroundColor: AppTheme.errorRed,
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
            energy: safeParseInt(data['energy'],
                fallback: 100), // Load actual energy from Firebase
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

        // Guard against overwriting recent local changes
        if (_lastLocalUpdate != null &&
            DateTime.now().difference(_lastLocalUpdate!) <
                const Duration(seconds: 2)) {
          print('⏸️ Ignoring stale Firebase update (local change pending)');
          return;
        }

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
          } catch (e, stackTrace) {
            AppLogger.warning('Error loading songs in real-time update', 
              error: e, stackTrace: stackTrace);
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
              AppLogger.info('[RT] Loaded ${loadedSongs.length} songs from subcollection');
            }
          } catch (e, stackTrace) {
            AppLogger.warning('[RT] Fallback songs subcollection load failed', 
              error: e, stackTrace: stackTrace);
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
          } catch (e, stackTrace) {
            AppLogger.warning('Error loading albums in real-time update', 
              error: e, stackTrace: stackTrace);
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
        backgroundColor = AppTheme.chartGold;
        icon = Icons.card_giftcard;
        break;
      case 'achievement':
        backgroundColor = AppTheme.successGreen; // Green
        icon = Icons.emoji_events;
        break;
      case 'warning':
        backgroundColor = AppTheme.warningOrange; // Orange
        icon = Icons.warning;
        break;
      default:
        backgroundColor = AppTheme.primaryCyan; // Cyan
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

  /// Immediate update for money/energy changes
  /// Bypasses Cloud Function for faster updates and prevents real-time listener race conditions
  Future<void> _immediateStatUpdate({
    int? money,
    int? energy,
    Map<String, dynamic>? sideHustle,
    bool? clearSideHustle,
    String? context,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updates = <String, dynamic>{};
      if (money != null) updates['currentMoney'] = money;
      if (energy != null) updates['energy'] = energy;

      // Handle side hustle updates
      if (clearSideHustle == true) {
        updates['activeSideHustle'] = null;
        print('🗑️ Clearing side hustle from Firestore');
      } else if (sideHustle != null) {
        updates['activeSideHustle'] = sideHustle;
        print('💼 Saving side hustle to Firestore: ${sideHustle['type']}');
      }

      if (updates.isEmpty) return;

      // Mark that we just made a local update
      _lastLocalUpdate = DateTime.now();

      print(
          '💾 Immediate stat update (${context ?? 'unknown'}): ${updates.keys.toList()}');

      await FirebaseFirestore.instance
          .collection('players')
          .doc(user.uid)
          .update(updates);

      print('✅ Stats saved immediately to Firebase');
    } catch (e) {
      print('❌ Error saving stats immediately: $e');
    }
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

      // 🔍 DEBUG: Log EVERY check to see what's happening
      print('⏰ Timer fired: Checking for day change...');
      print(
          '   Current stored date: ${currentGameDate!.day}/${currentGameDate!.month}/${currentGameDate!.year}');
      print(
          '   New calculated date: ${newGameDate.day}/${newGameDate.month}/${newGameDate.year}');
      print('   Days match: ${newGameDate.day == currentGameDate!.day}');
      print('   Months match: ${newGameDate.month == currentGameDate!.month}');
      print('   Years match: ${newGameDate.year == currentGameDate!.year}');

      // Check again if still mounted after async operation
      if (!mounted) return;

      // Check if the day has changed
      if (newGameDate.day != currentGameDate!.day ||
          newGameDate.month != currentGameDate!.month ||
          newGameDate.year != currentGameDate!.year) {
        print(
          '🌅 Day changed! Old: ${currentGameDate!.day} → New: ${newGameDate.day}',
        );

        // Note: We DON'T reload the full profile here because:
        // 1. Cloud Functions update streams/money/fame in Firebase
        // 2. Real-time listener will pick those up automatically
        // 3. We need to preserve current local state for energy restoration
        // 4. Full reload would overwrite the energy we're about to restore

        print(
            '💡 Skipping profile reload - real-time listener will sync stats');

        // ❌ REMOVED: await _loadUserProfile();
        // The real-time listener handles syncing Firebase changes automatically
        // Reloading here causes race conditions with energy restoration

        // ❌ REMOVED: Client-side stream calculation (_applyDailyStreamGrowth)
        // ALL progression stats are now server-authoritative (full Option A implementation)
        // Server calculates: streams, last7DaysStreams, income, fanbase, fame
        // Client handles: energy replenishment, side hustle energy cost and payment

        // Apply side hustle effects (energy cost, daily pay, expiration check)
        bool sideHustleExpired = false;
        int sideHustleMoney = 0;
        int sideHustleEnergyCost = 0;

        if (artistStats.activeSideHustle != null) {
          final result = _sideHustleService.applyDailySideHustle(
            sideHustle: artistStats.activeSideHustle!,
            currentMoney: artistStats.money,
            currentEnergy: artistStats.energy,
            currentGameDate: newGameDate,
          );
          sideHustleExpired = result['expired'] == 1;

          if (!sideHustleExpired) {
            // Apply side hustle effects
            sideHustleMoney = result['money']! - artistStats.money;
            sideHustleEnergyCost = artistStats.energy - result['energy']!;

            print('💼 Side hustle effects:');
            print('   Daily pay: +\$$sideHustleMoney');
            print('   Energy cost: -$sideHustleEnergyCost');
          }
        }

        // Check for scheduled song releases
        await _checkScheduledReleases(newGameDate);

        // Update last sync time
        _lastSyncTime = DateTime.now();

        // Replenish energy for the new day (only if still mounted)
        if (mounted) {
          // GUARANTEED ENERGY RESTORATION - Direct implementation
          // Energies below 100 restore to 100, energies 100+ stay the same
          final int currentEnergy = artistStats.energy;
          final int restoredEnergy = currentEnergy < 100 ? 100 : currentEnergy;

          // Apply side hustle energy cost AFTER restoration
          final int finalEnergy = restoredEnergy - sideHustleEnergyCost;

          print('🔋 Energy restoration starting...');
          print('   Current energy: $currentEnergy');
          print('   Will restore to: $restoredEnergy');
          print('   Side hustle cost: -$sideHustleEnergyCost');
          print('   Final energy: $finalEnergy');
          print('   Restoration needed: ${currentEnergy < 100}');

          // Mark this as a local update to prevent real-time listener from overwriting
          _lastLocalUpdate = DateTime.now();
          print('   Marked local update at: $_lastLocalUpdate');

          setState(() {
            currentGameDate = newGameDate;
            _lastEnergyReplenishDay = newGameDate.day;

            artistStats = artistStats.copyWith(
              energy: finalEnergy,
              money: artistStats.money + sideHustleMoney,
              clearSideHustle: sideHustleExpired,
            );
          });

          print('   ✅ State updated!');
          print(
              '   New currentGameDate: ${currentGameDate!.day}/${currentGameDate!.month}/${currentGameDate!.year}');
          print('   Energy in artistStats: ${artistStats.energy}');
          print('   Money in artistStats: ${artistStats.money}');

          // Save restored energy and side hustle effects to Firebase immediately
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final updateData = <String, dynamic>{
                'energy': finalEnergy,
                'money': artistStats.money,
              };

              if (sideHustleExpired) {
                updateData['activeSideHustle'] = null;
              }

              await FirebaseFirestore.instance
                  .collection('players')
                  .doc(user.uid)
                  .update(updateData);
              print('✅ Daily update saved to Firebase:');
              print('   Energy: $finalEnergy');
              print('   Money: ${artistStats.money}');
              if (sideHustleExpired) {
                print('   Cleared expired side hustle');
              }
            }
          } catch (e) {
            print('❌ Error saving daily update to Firebase: $e');
          }

          // Show appropriate message based on energy restoration and side hustle
          String message = '☀️ New day! ';
          if (currentEnergy < 100) {
            message += 'Energy restored to 100';
          } else {
            message += 'You still have $restoredEnergy energy';
          }

          if (sideHustleMoney > 0) {
            message += '\n💼 Side hustle paid: \$$sideHustleMoney';
          }

          _showMessage(message);

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

          final energyMessage = currentEnergy < 100
              ? 'A new day has begun! Your energy has been restored to 100.'
              : 'A new day has begun! Your current energy: $restoredEnergy';

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

  /// Check for scheduled song releases and auto-release them if the date has arrived
  Future<void> _checkScheduledReleases(DateTime currentGameDate) async {
    if (!mounted) return;

    try {
      bool hasChanges = false;
      final List<Song> updatedSongs = [];
      final streamGrowthService = StreamGrowthService();

      // Compare dates without time component
      final currentDate = DateTime(
        currentGameDate.year,
        currentGameDate.month,
        currentGameDate.day,
      );

      for (final song in artistStats.songs) {
        if (song.state == SongState.scheduled &&
            song.scheduledReleaseDate != null) {
          final scheduledDate = DateTime(
            song.scheduledReleaseDate!.year,
            song.scheduledReleaseDate!.month,
            song.scheduledReleaseDate!.day,
          );

          // If scheduled date has arrived or passed, release the song
          if (!currentDate.isBefore(scheduledDate)) {
            print('🎵 Auto-releasing scheduled song: ${song.title}');

            // Calculate release metrics (similar to immediate release)
            final baseInitialStreams =
                artistStats.fanbase > 0 ? artistStats.fanbase : 10;

            final qualityMultiplier = (song.finalQuality / 100.0) * 0.6 + 0.4;
            final platformMultiplier =
                1.0 + (song.streamingPlatforms.length - 1) * 0.25;
            final realisticInitialStreams =
                (baseInitialStreams * qualityMultiplier * platformMultiplier)
                    .round();

            final viralityScore = streamGrowthService.calculateViralityScore(
              songQuality: song.finalQuality,
              artistFame: artistStats.fame,
              artistFanbase: artistStats.fanbase,
            );

            // Calculate regional streams
            final initialRegionalStreams =
                streamGrowthService.calculateRegionalStreamDistribution(
              totalDailyStreams: realisticInitialStreams,
              currentRegion: artistStats.currentRegion,
              regionalFanbase: artistStats.regionalFanbase,
              genre: song.genre,
            );

            final releasedSong = song.copyWith(
              state: SongState.released,
              releasedDate: currentGameDate,
              scheduledReleaseDate: null,
              clearScheduledDate: true,
              streams: realisticInitialStreams,
              regionalStreams: initialRegionalStreams,
              likes: (realisticInitialStreams * 0.3).round(),
              viralityScore: viralityScore,
              peakDailyStreams: realisticInitialStreams,
            );

            updatedSongs.add(releasedSong);
            hasChanges = true;

            // Show notification
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎵 "${song.title}" has been released!'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }

      if (hasChanges && mounted) {
        // Calculate stat bonuses for scheduled releases
        final fameGain = updatedSongs.fold<int>(
          0,
          (sum, song) => sum + (song.finalQuality * 0.1).round().clamp(1, 5),
        );
        final fanbaseGain = updatedSongs.fold<int>(
          0,
          (sum, song) => sum + (song.finalQuality * 0.5).round().clamp(5, 50),
        );

        // Calculate loyal fanbase growth
        int totalLoyalFanbaseGrowth = 0;
        for (final song in updatedSongs) {
          final growth = streamGrowthService.calculateLoyalFanbaseGrowth(
            currentLoyalFanbase:
                artistStats.loyalFanbase + totalLoyalFanbaseGrowth,
            songQuality: song.finalQuality,
            totalFanbase: artistStats.fanbase + fanbaseGain,
          );
          totalLoyalFanbaseGrowth += growth;
        }

        // Calculate regional fanbase growth
        final updatedRegionalFanbase =
            Map<String, int>.from(artistStats.regionalFanbase);
        for (final song in updatedSongs) {
          final regionalGrowth =
              streamGrowthService.calculateRegionalFanbaseGrowth(
            currentRegion: artistStats.currentRegion,
            originRegion: artistStats.currentRegion,
            songQuality: song.finalQuality,
            genre: song.genre,
            currentGlobalFanbase: artistStats.fanbase + fanbaseGain,
            currentRegionalFanbase: updatedRegionalFanbase,
          );
          regionalGrowth.forEach((region, growth) {
            updatedRegionalFanbase[region] =
                (updatedRegionalFanbase[region] ?? 0) + growth;
          });
        }

        // Update songs list
        final allSongs = artistStats.songs.map((s) {
          final updated = updatedSongs.firstWhere(
            (us) => us.id == s.id,
            orElse: () => s,
          );
          return updated;
        }).toList();

        setState(() {
          artistStats = artistStats.copyWith(
            songs: allSongs,
            fame: artistStats.fame + fameGain,
            fanbase: artistStats.fanbase + fanbaseGain,
            loyalFanbase: (artistStats.loyalFanbase + totalLoyalFanbaseGrowth)
                .clamp(0, 1e12)
                .toInt(),
            regionalFanbase: updatedRegionalFanbase,
          );
        });

        // Save to Firebase
        _immediateSave();

        print('✅ ${updatedSongs.length} scheduled song(s) auto-released');
      }
    } catch (e) {
      print('❌ Error checking scheduled releases: $e');
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
        backgroundColor: AppTheme.neonGreen,
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
      backgroundColor: AppTheme.backgroundDark,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.primaryCyan,
        backgroundColor: AppTheme.surfaceDark,
        child: SafeArea(
          child: Column(
            children: [
              // Show loading banner if profile not loaded
              if (artistStats.name == 'Loading...')
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.errorRed, AppTheme.errorRed.withOpacity(0.8)],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 450; // Increased from 400 to 450
        final isTinyScreen = constraints.maxWidth < 380; // For very small screens
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTinyScreen ? 6 : (isSmallScreen ? 8 : 12),
            vertical: isTinyScreen ? 4 : (isSmallScreen ? 6 : 8),
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              // LEFT: Date & Time Section
              Expanded(
                flex: isSmallScreen ? 2 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date Display
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryCyan,
                          size: isTinyScreen ? 12 : (isSmallScreen ? 14 : 16),
                        ),
                        SizedBox(width: isTinyScreen ? 3 : (isSmallScreen ? 4 : 6)),
                        Flexible(
                          child: Text(
                            currentGameDate != null
                                ? _gameTimeService.formatGameDate(currentGameDate!)
                                : 'Syncing...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTinyScreen ? 11 : (isSmallScreen ? 12 : 15),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Next Day Timer
                    if (_timeUntilNextDay.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: isTinyScreen ? 1 : 2,
                          left: isTinyScreen ? 15 : (isSmallScreen ? 17 : 22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: AppTheme.warningOrange,
                              size: isTinyScreen ? 9 : (isSmallScreen ? 10 : 12),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                isTinyScreen ? _timeUntilNextDay : (isSmallScreen ? _timeUntilNextDay : 'Next: $_timeUntilNextDay'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: isTinyScreen ? 8 : (isSmallScreen ? 9 : 11),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: isTinyScreen ? 3 : (isSmallScreen ? 4 : 8)),
              // CENTER: Money & Energy
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Money Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTinyScreen ? 5 : (isSmallScreen ? 6 : 10),
                      vertical: isTinyScreen ? 3 : (isSmallScreen ? 4 : 6),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(isTinyScreen ? 7 : (isSmallScreen ? 8 : 10)),
                      border: Border.all(
                        color: AppTheme.successGreen,
                        width: isSmallScreen ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: AppTheme.successGreen,
                          size: isTinyScreen ? 12 : (isSmallScreen ? 14 : 16),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatMoney(artistStats.money.toDouble()),
                          style: TextStyle(
                            color: AppTheme.successGreen,
                            fontSize: isTinyScreen ? 10 : (isSmallScreen ? 11 : 13),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isTinyScreen ? 3 : (isSmallScreen ? 4 : 6)),
                  // Energy Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTinyScreen ? 5 : (isSmallScreen ? 6 : 10),
                      vertical: isTinyScreen ? 3 : (isSmallScreen ? 4 : 6),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(isTinyScreen ? 7 : (isSmallScreen ? 8 : 10)),
                      border: Border.all(
                        color: AppTheme.errorRed,
                        width: isSmallScreen ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          color: AppTheme.errorRed,
                          size: isTinyScreen ? 12 : (isSmallScreen ? 14 : 16),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${artistStats.energy}',
                          style: TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: isTinyScreen ? 10 : (isSmallScreen ? 11 : 13),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(width: isTinyScreen ? 1 : (isSmallScreen ? 2 : 4)),
              // RIGHT: Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Admin Button (conditionally shown)
                  if (_isAdmin)
                    IconButton(
                      icon: Icon(
                        Icons.shield_outlined,
                        color: Colors.amberAccent,
                        size: isTinyScreen ? 18 : (isSmallScreen ? 20 : 22),
                      ),
                      tooltip: 'Admin Tools',
                      onPressed: _openAdminQuickActions,
                      padding: EdgeInsets.all(isTinyScreen ? 4 : (isSmallScreen ? 6 : 8)),
                      constraints: const BoxConstraints(),
                    ),
                  // Notification Button with Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: Colors.white70,
                          size: isTinyScreen ? 18 : (isSmallScreen ? 20 : 22),
                        ),
                        onPressed: _showNotifications,
                        padding: EdgeInsets.all(isTinyScreen ? 4 : (isSmallScreen ? 6 : 8)),
                        constraints: const BoxConstraints(),
                      ),
                      if (_unreadNotificationCount > 0)
                        Positioned(
                          right: isTinyScreen ? 1 : (isSmallScreen ? 2 : 4),
                          top: isTinyScreen ? 1 : (isSmallScreen ? 2 : 4),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppTheme.errorRed,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Center(
                              child: Text(
                                '$_unreadNotificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Settings Button
                  IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.white70,
                      size: isTinyScreen ? 18 : (isSmallScreen ? 20 : 22),
                    ),
                    tooltip: 'Settings',
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
                    padding: EdgeInsets.all(isTinyScreen ? 4 : (isSmallScreen ? 6 : 8)),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAdminQuickActions() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final controller = TextEditingController(text: userId);
    bool running = false;
    MigrationResult? result;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.backgroundElevated,
            title: const Text('Admin: Certifications',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Run certifications migration for a player (retro-awards song tiers).',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Text('Player ID',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter player UID',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                if (result != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Changed: ${result!.changed} • Awarded: ${result!.awarded}',
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: running ? null : () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: running
                    ? null
                    : () async {
                        setState(() => running = true);
                        try {
                          final r = await _certificationsService
                              .runMigrationForPlayer(controller.text.trim());
                          setState(() => result = r);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Migration done: changed ${r.changed}, awarded ${r.awarded}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Migration failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          setState(() => running = false);
                        }
                      },
                icon: running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: const Text('Run Migration'),
              ),
            ],
          );
        });
      },
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
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorRed, width: 1.5),
              ),
              child: _buildAdvancedStatusCard(
                'Fame',
                artistStats.fame,
                100, // Max value for progress bar
                Icons.stars_rounded,
                AppTheme.errorRed,
                AppTheme.backgroundElevated,
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
              AppTheme.neonPurple,
              AppTheme.backgroundElevated,
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
              AppTheme.accentBlue,
              AppTheme.backgroundElevated,
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row with icon and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: primaryColor, size: 14),
                      ),
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 60),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
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
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
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
                        fontSize: 18,
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
              gradient: AppTheme.mixedNeonGradient,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artistStats.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        currentGameDate != null
                            ? '${artistStats.getCurrentAge(currentGameDate!)} years old • ${artistStats.fameTier}'
                            : '${artistStats.age} years old • ${artistStats.fameTier}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Skills Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryCyan.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: AppTheme.primaryCyan, size: 18),
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
                      AppTheme.primaryCyan,
                    ),
                    const SizedBox(width: 12),
                    _buildSkillBar(
                      'Lyrics',
                      artistStats.lyricsSkill,
                      AppTheme.errorRed,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSkillBar(
                      'Composition',
                      artistStats.compositionSkill,
                      AppTheme.neonPurple,
                    ),
                    const SizedBox(width: 12),
                    _buildSkillBar(
                      'Inspiration',
                      artistStats.inspirationLevel,
                      AppTheme.warningOrange,
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
                        AppTheme.neonGreen.withOpacity(0.2),
                        AppTheme.neonGreen.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppTheme.neonGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Experience: ${artistStats.experience} XP',
                        style: const TextStyle(
                          color: AppTheme.neonGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Level ${(artistStats.experience / 100).floor() + 1}',
                        style: const TextStyle(
                          color: AppTheme.neonGreen,
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
                  color: AppTheme.primaryCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: AppTheme.primaryCyan,
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
                    'Studio',
                    Icons.album_rounded,
                    AppTheme.neonPurple,
                    energyCost: -1,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudiosListScreen(
                            artistStats: artistStats,
                            onStatsUpdated: (updatedStats) {
                              setState(() {
                                _lastLocalUpdate = DateTime.now();
                                artistStats = updatedStats;
                              });
                              // Immediate save for money/energy changes
                              _immediateStatUpdate(
                                money: updatedStats.money,
                                energy: updatedStats.energy,
                                context: 'Studio',
                              );
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
                    AppTheme.errorRed,
                    energyCost: -1,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReleaseManagerScreen(
                            artistStats: artistStats,
                            onStatsUpdated: (updatedStats) {
                              setState(() {
                                _lastLocalUpdate = DateTime.now();
                                artistStats = updatedStats;
                              });
                              // Immediate save - album releases are critical multiplayer events
                              _immediateSave();
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
                    AppTheme.neonGreen,
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
                    AppTheme.warningOrange,
                    energyCost: -1,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TheScoopScreen(
                            artistStats: artistStats,
                            onStatsUpdated: (updatedStats) {
                              setState(() => artistStats = updatedStats);
                              _immediateSave();
                            },
                          ),
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
                                ? AppTheme.successGreen
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

  // Song writing dialog methods removed - use dedicated WriteSongScreen or Music Hub instead

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
                  // Capture old side hustle before updating
                  final oldSideHustle = artistStats.activeSideHustle;

                  setState(() {
                    _lastLocalUpdate = DateTime.now();
                    artistStats = updatedStats;
                  });

                  // Prepare side hustle data for Firestore
                  Map<String, dynamic>? sideHustleData;
                  bool clearSideHustle = false;

                  if (updatedStats.activeSideHustle != null) {
                    // Side hustle was added or updated
                    sideHustleData = updatedStats.activeSideHustle!.toJson();
                    print(
                        '💼 Side hustle changed - will save to Firestore: ID=${sideHustleData['id']}, Type=${sideHustleData['type']}');
                  } else if (oldSideHustle != null &&
                      updatedStats.activeSideHustle == null) {
                    // Side hustle was cleared
                    clearSideHustle = true;
                    print(
                        '🗑️ Side hustle cleared - will remove from Firestore');
                  }

                  // Immediate save for money/energy/side hustle changes (prevents real-time listener race condition)
                  _immediateStatUpdate(
                    money: updatedStats.money,
                    energy: updatedStats.energy,
                    sideHustle: sideHustleData,
                    clearSideHustle: clearSideHustle,
                    context: 'Activity Hub',
                  );
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
              builder: (context) => TheScoopScreen(
                artistStats: artistStats,
                onStatsUpdated: (updatedStats) {
                  setState(() => artistStats = updatedStats);
                  _immediateSave();
                },
              ),
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
              color: AppTheme.borderDefault,
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
