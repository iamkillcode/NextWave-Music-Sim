import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../models/side_hustle.dart';
import '../services/firebase_service.dart';
import '../services/demo_firebase_service.dart';
import '../services/game_time_service.dart';
import '../services/stream_growth_service.dart';
import '../services/side_hustle_service.dart';
import '../services/song_name_generator.dart';
import 'world_map_screen.dart';
import 'music_hub_screen.dart';
import 'media_hub_screen.dart';
import 'studios_list_screen.dart';
import 'activity_hub_screen.dart';
import '../utils/firebase_status.dart';
import 'settings_screen.dart';

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
  final List<Map<String, dynamic>> _notifications = []; // Store notifications

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
        fanbase: 1,
        albumsSold: 0,
        songsWritten: 0,
        concertsPerformed: 0,
        songwritingSkill: 10,
        experience: 0,
        lyricsSkill: 10,
        compositionSkill: 10,
        inspirationLevel: 0, // No hype yet - you're just starting!
      );
    }

    // Load user profile from Firestore
    _loadUserProfile();

    // Initialize Firebase authentication
    _initializeOnlineMode();

    // Date-only system: Check for day changes every 5 minutes (much more efficient!)
    gameTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateGameDate();
    });

    // Sync with Firebase every hour to stay synchronized
    syncTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await _syncWithFirebase();
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
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ No user signed in, using demo stats');
        return;
      }

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

        // Load regional fanbase with proper deserialization
        Map<String, int> loadedRegionalFanbase = {};
        if (data['regionalFanbase'] != null) {
          try {
            final regionalData =
                data['regionalFanbase'] as Map<dynamic, dynamic>;
            loadedRegionalFanbase = regionalData.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
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

        setState(() {
          artistStats = ArtistStats(
            name: data['displayName'] ?? 'Unknown Artist',
            fame: (data['currentFame'] ?? 0).toInt(),
            money: (data['currentMoney'] ?? 5000).toInt(),
            energy: 100, // Always start with full energy
            creativity: (data['inspirationLevel'] ?? 0).toInt(),
            fanbase: (data['level'] ?? 1).toInt(),
            loyalFanbase: (data['loyalFanbase'] ?? 0).toInt(),
            albumsSold: (data['albumsReleased'] ?? 0).toInt(),
            songsWritten: (data['songsPublished'] ?? 0).toInt(),
            concertsPerformed: (data['concertsPerformed'] ?? 0).toInt(),
            songwritingSkill: (data['songwritingSkill'] ?? 10).toInt(),
            experience: (data['experience'] ?? 0).toInt(),
            lyricsSkill: (data['lyricsSkill'] ?? 10).toInt(),
            compositionSkill: (data['compositionSkill'] ?? 10).toInt(),
            inspirationLevel: (data['inspirationLevel'] ?? 0).toInt(),
            songs: loadedSongs,
            currentRegion: data['homeRegion'] ?? 'usa',
            age: (data['age'] ?? 18).toInt(),
            careerStartDate:
                (data['careerStartDate'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            regionalFanbase: loadedRegionalFanbase,
            avatarUrl: data['avatarUrl'] as String?,
            activeSideHustle: loadedSideHustle,
          );
        });

        // Check if player missed days while offline
        await _checkForMissedDays(data);
      } else {
        print('⚠️ Profile not found in Firestore, using demo stats');
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      print('💡 Using demo stats instead');
      // Keep the default stats if loading fails
    }
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

  Future<void> _saveUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ No user signed in, cannot save profile');
        return;
      }

      print('💾 Saving user profile for: ${user.uid}');

      await FirebaseFirestore.instance
          .collection('players')
          .doc(user.uid)
          .update({
            'currentFame': artistStats.fame,
            'currentMoney': artistStats.money,
            'previousMoney': artistStats
                .money, // Store current money as previous for next session
            'inspirationLevel': artistStats.inspirationLevel,
            'level': artistStats.fanbase,
            'loyalFanbase': artistStats.loyalFanbase,
            'albumsReleased': artistStats.albumsSold,
            'songsPublished': artistStats.songsWritten,
            'concertsPerformed': artistStats.concertsPerformed,
            'songwritingSkill': artistStats.songwritingSkill,
            'experience': artistStats.experience,
            'lyricsSkill': artistStats.lyricsSkill,
            'compositionSkill': artistStats.compositionSkill,
            'homeRegion': artistStats.currentRegion,
            'age': artistStats.age,
            'regionalFanbase': artistStats.regionalFanbase,
            'lastActive': Timestamp.fromDate(
              DateTime.now(),
            ), // Track last activity
            'songs': artistStats.songs.map((song) => song.toJson()).toList(),
            'activeSideHustle': artistStats.activeSideHustle?.toJson(),
            if (artistStats.careerStartDate != null)
              'careerStartDate': Timestamp.fromDate(
                artistStats.careerStartDate!,
              ),
          })
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Profile save timeout');
            },
          );

      print('✅ Profile saved successfully');
    } catch (e) {
      print('❌ Error saving profile: $e');
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

        // Calculate passive income for the time that has passed
        final now = DateTime.now();
        final realSecondsSinceLastUpdate = now
            .difference(_lastSyncTime!)
            .inSeconds;
        _calculatePassiveIncome(realSecondsSinceLastUpdate);

        // Apply stream growth to all released songs
        _applyDailyStreamGrowth(newGameDate);

        // Update last sync time
        _lastSyncTime = now;

        // Replenish energy for the new day (only if still mounted)
        if (mounted) {
          setState(() {
            currentGameDate = newGameDate;
            _lastEnergyReplenishDay = newGameDate.day;
            artistStats = artistStats.copyWith(energy: 100);
          });

          _showMessage('☀️ New day! Energy fully restored to 100');
          _addNotification(
            'Energy Restored',
            'A new day has begun! Your energy has been fully restored to 100.',
            icon: Icons.wb_sunny,
          );
          print(
            '✅ Energy restored to 100 - Game Date: ${_gameTimeService.formatGameDate(newGameDate)}',
          );
        }
      } else {
        // Same day, just update passive income
        final now = DateTime.now();
        final realSecondsSinceLastUpdate = now
            .difference(_lastSyncTime!)
            .inSeconds;

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

  void _calculatePassiveIncome(int realSecondsPassed) {
    // Get all released songs
    final releasedSongs = artistStats.songs
        .where((s) => s.state == SongState.released)
        .toList();

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

    // Only update if we earned something meaningful (avoid tiny fractions)
    if (totalStreamsGained > 0) {
      final totalIncome = (totalIncomePerSecond * realSecondsPassed);

      setState(() {
        artistStats = artistStats.copyWith(
          money: artistStats.money + totalIncome.round(),
          songs: List.from(
            artistStats.songs,
          ), // Create new list to trigger update
        );
      });

      // Show notification for significant income (every $100+)
      if (totalIncome >= 100 &&
          DateTime.now()
                  .difference(_lastPassiveIncomeTime ?? DateTime.now())
                  .inSeconds >
              60) {
        _lastPassiveIncomeTime = DateTime.now();
        print(
          '💰 Passive income: \$${totalIncome.toStringAsFixed(2)} from $totalStreamsGained streams',
        );
        _addNotification(
          'Streaming Income',
          'Your ${releasedSongs.length} song${releasedSongs.length > 1 ? 's' : ''} earned \$${totalIncome.toStringAsFixed(0)} from $totalStreamsGained streams!',
          icon: Icons.music_note,
        );
      }
    }
  }

  /// Apply daily stream growth to all released songs
  void _applyDailyStreamGrowth(DateTime currentGameDate) {
    final List<Song> updatedSongs = [];
    int totalNewStreams = 0;
    int totalNewIncome = 0;

    for (final song in artistStats.songs) {
      // First, decay the 7-day stream count (one day drops off the rolling window)
      final decayedLast7Days = _streamGrowthService.decayLast7DaysStreams(
        song.last7DaysStreams,
      );

      // If song is not released, just apply decay and skip growth
      if (song.state != SongState.released || song.releasedDate == null) {
        updatedSongs.add(song.copyWith(last7DaysStreams: decayedLast7Days));
        continue;
      }

      // ⏰ REALISTIC STREAM DELAYS: Check if enough time has passed since last update
      // Songs on streaming platforms update every 12 hours (half in-game day)
      final lastUpdate = song.lastStreamUpdateDate ?? song.releasedDate!;
      final hoursSinceLastUpdate = currentGameDate
          .difference(lastUpdate)
          .inHours;

      // Skip if less than 12 hours have passed (need half-day delay)
      if (hoursSinceLastUpdate < 12) {
        updatedSongs.add(song.copyWith(last7DaysStreams: decayedLast7Days));
        print(
          '⏸️ ${song.title}: Waiting for stream update (${hoursSinceLastUpdate}h/12h)',
        );
        continue;
      }

      // Calculate stream growth for this song
      final newStreams = _streamGrowthService.calculateDailyStreamGrowth(
        song: song,
        artistStats: artistStats,
        currentGameDate: currentGameDate,
      );

      // Distribute streams regionally
      final regionalStreamDelta = _streamGrowthService
          .calculateRegionalStreamDistribution(
            totalDailyStreams: newStreams,
            currentRegion: artistStats.currentRegion,
            regionalFanbase: artistStats.regionalFanbase,
            genre: song.genre,
          );

      // Update regional streams for the song
      final updatedRegionalStreams = Map<String, int>.from(
        song.regionalStreams,
      );
      regionalStreamDelta.forEach((region, delta) {
        updatedRegionalStreams[region] =
            (updatedRegionalStreams[region] ?? 0) + delta;
      });

      // Update days on chart
      final daysSinceRelease =
          currentGameDate.difference(song.releasedDate!).inDays + 1;

      // Check if this is a new peak
      final newPeak = _streamGrowthService.updatePeakDailyStreams(
        song.peakDailyStreams,
        newStreams,
      );

      // Calculate income from new streams (pay artists daily royalties)
      int songIncome = 0;
      for (final platform in song.streamingPlatforms) {
        if (platform == 'tunify') {
          // Tunify: 85% reach, $0.003 per stream royalty
          songIncome += (newStreams * 0.85 * 0.003).round();
        } else if (platform == 'maple_music') {
          // Maple Music: 65% reach, $0.01 per stream royalty
          songIncome += (newStreams * 0.65 * 0.01).round();
        }
      }

      // Update the song (including daily and weekly streams for charts)
      // Add new streams to the already-decayed 7-day count
      final updatedSong = song.copyWith(
        streams: song.streams + newStreams,
        lastDayStreams: newStreams, // Update daily streams for daily charts
        last7DaysStreams: decayedLast7Days + newStreams,
        regionalStreams: updatedRegionalStreams,
        daysOnChart: daysSinceRelease,
        peakDailyStreams: newPeak,
        lastStreamUpdateDate:
            currentGameDate, // Track when streams were last updated
      );

      updatedSongs.add(updatedSong);
      totalNewStreams += newStreams;
      totalNewIncome += songIncome;

      print(
        '📈 ${song.title}: +${_streamGrowthService.formatStreams(newStreams)} streams (Total: ${_streamGrowthService.formatStreams(updatedSong.streams)})',
      );
    }

    // 🎯 BALANCE ARTIST STATS: Calculate fanbase and fame growth from streams
    // More streams = more fans discovering your music + growing reputation
    int fanbaseGrowth = 0;
    int fameGrowth = 0;
    int loyalFanGrowth = 0;

    if (totalNewStreams > 0) {
      // Every 1,000 streams converts 1 casual listener to a fan
      // Apply diminishing returns for established artists (prevents exploits)
      final baseFanGrowth = (totalNewStreams / 1000).floor();
      final diminishingFactor = 1.0 / (1.0 + artistStats.fanbase / 10000);
      fanbaseGrowth = (baseFanGrowth * diminishingFactor).round().clamp(
        0,
        50,
      ); // Max 50 fans per day

      // Every 10,000 streams increases fame by 1 point
      // Also has diminishing returns for mega-celebrities
      final baseFameGrowth = (totalNewStreams / 10000).floor();
      final fameDiminishing = 1.0 / (1.0 + artistStats.fame / 500);
      fameGrowth = (baseFameGrowth * fameDiminishing).round().clamp(
        0,
        10,
      ); // Max 10 fame per day

      // Convert casual fans to loyal fans based on consistent streaming
      // Every 5,000 streams converts 1 casual fan to loyal (they love your music!)
      final casualFans = (artistStats.fanbase - artistStats.loyalFanbase)
          .clamp(0, double.infinity)
          .toInt();
      if (casualFans > 0) {
        final baseLoyalGrowth = (totalNewStreams / 5000).floor();
        final loyalDiminishing = 1.0 / (1.0 + artistStats.loyalFanbase / 5000);
        final maxConvertible = (casualFans * 0.05)
            .round(); // Max 5% of casual fans per day
        loyalFanGrowth = (baseLoyalGrowth * loyalDiminishing).round().clamp(
          0,
          maxConvertible,
        );
      }
    }

    // 💼 SIDE HUSTLE SYSTEM: Apply daily side hustle effects (energy cost + pay)
    int sideHustlePay = 0;
    int sideHustleEnergyCost = 0;
    bool sideHustleExpired = false;

    if (artistStats.activeSideHustle != null) {
      final result = _sideHustleService.applyDailySideHustle(
        sideHustle: artistStats.activeSideHustle!,
        currentMoney: artistStats.money + totalNewIncome,
        currentEnergy: artistStats.energy,
        currentGameDate: currentGameDate,
      );

      sideHustlePay = result['money']! - (artistStats.money + totalNewIncome);
      sideHustleEnergyCost = (artistStats.energy - result['energy']!).round();
      sideHustleExpired = result['expired'] == 1;

      totalNewIncome += sideHustlePay;

      print(
        '💼 Side hustle (${artistStats.activeSideHustle!.type.displayName}): -$sideHustleEnergyCost energy, +\$$sideHustlePay pay',
      );
    }

    // Update artist stats with new songs, income, and growth from streaming success
    if (totalNewStreams > 0 ||
        fanbaseGrowth > 0 ||
        fameGrowth > 0 ||
        loyalFanGrowth > 0 ||
        sideHustlePay > 0 ||
        sideHustleEnergyCost > 0) {
      setState(() {
        artistStats = artistStats.copyWith(
          songs: updatedSongs,
          money: artistStats.money + totalNewIncome,
          energy: sideHustleEnergyCost > 0
              ? (artistStats.energy - sideHustleEnergyCost).clamp(0, 100)
              : artistStats.energy,
          fanbase: artistStats.fanbase + fanbaseGrowth,
          fame: artistStats.fame + fameGrowth,
          loyalFanbase: artistStats.loyalFanbase + loyalFanGrowth,
          clearSideHustle: sideHustleExpired, // Clear if contract expired
        );
      });

      print(
        '💰 Total daily streaming income: \$$totalNewIncome from ${_streamGrowthService.formatStreams(totalNewStreams)} streams',
      );

      if (fanbaseGrowth > 0 || fameGrowth > 0 || loyalFanGrowth > 0) {
        print(
          '📈 Artist growth: +$fanbaseGrowth fans (+$loyalFanGrowth loyal), +$fameGrowth fame (from streaming success)',
        );
      }

      if (sideHustleExpired) {
        print(
          '⏰ Side hustle contract expired: ${artistStats.activeSideHustle!.type.displayName}',
        );
        _addNotification(
          'Contract Ended',
          'Your ${artistStats.activeSideHustle!.type.displayName} contract has ended!',
          icon: Icons.work_off,
        );
      }

      // Save to Firebase to persist the income and growth
      _saveUserProfile();

      // Show notification
      _addNotification(
        'Daily Streams',
        'Your music earned ${_streamGrowthService.formatStreams(totalNewStreams)} streams and \$$totalNewIncome today!',
        icon: Icons.trending_up,
      );
    }
  }

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF21262D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Color(0xFFFF6B9D),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_notifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _notifications.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: Color(0xFFFF6B9D)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Expanded(
                  child: _notifications.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                color: Colors.white38,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No notifications yet',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D333B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    notification['icon'] as IconData,
                                    color: const Color(0xFF00D9FF),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification['title'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notification['message'] as String,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // GitHub dark background
      body: SafeArea(
        child: Column(
          children: [
            // Top Status Bar
            _buildTopStatusBar(),

            // Game Status Row
            _buildGameStatusRow(),

            // Profile Section (simplified)
            _buildProfileSection(),
            // Action Panel - Core gameplay
            Expanded(child: _buildActionPanel()),
          ],
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
          // Money and Energy Display
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Money
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
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
                      const Icon(
                        Icons.attach_money,
                        color: Color(0xFF32D74B),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatMoney(artistStats.money.toDouble()),
                        style: const TextStyle(
                          color: Color(0xFF32D74B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Energy
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
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
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${artistStats.energy}',
                        style: const TextStyle(
                          color: Color(0xFFFF6B9D),
                          fontSize: 14,
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
                  if (_notifications.isNotEmpty)
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
                          '${_notifications.length}',
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
                          _saveUserProfile();
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

  Widget _buildGameStatusRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildAdvancedStatusCard(
              'Fame',
              artistStats.fame,
              100, // Max value for progress bar
              Icons.stars_rounded,
              const Color(0xFFE94560), // Red
              const Color(0xFF16213E), // Dark blue
              'Rising Star',
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
              'Level',
              artistStats.fanbase,
              50, // Max value for progress bar
              Icons.military_tech_rounded,
              const Color(0xFFF39C12), // Orange
              const Color(0xFF1A252F), // Dark navy
              'Pro',
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
                        Text(
                          '$value',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
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
                          ? '${artistStats.getCurrentAge(currentGameDate!)} years old • ${artistStats.careerLevel}'
                          : '${artistStats.age} years old • ${artistStats.careerLevel}',
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
          Expanded(
            child: LayoutBuilder(
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
                  physics: const NeverScrollableScrollPhysics(),
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
                              },
                            ),
                          ),
                        );
                      },
                      customCostText: 'Record',
                    ),
                  ],
                );
              },
            ),
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
                  color: canPerform
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
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
            final avgQuality =
                songsToRelease
                    .map((s) => s.finalQuality)
                    .reduce((a, b) => a + b) /
                songsToRelease.length;
            final baseAlbumRevenue = 2000; // Base album advance
            final qualityBonus =
                (avgQuality / 100) * 3000; // Up to $3K for quality
            final fameBonus = artistStats.fame * 50; // $50 per fame point
            final albumEarnings = (baseAlbumRevenue + qualityBonus + fameBonus)
                .round();
            final fameGain =
                5 + (avgQuality ~/ 20); // 5-10 fame based on quality

            artistStats = artistStats.copyWith(
              energy: artistStats.energy - 40,
              albumsSold: artistStats.albumsSold + 1,
              money: artistStats.money + albumEarnings,
              fame: artistStats.fame + fameGain,
              songs: updatedSongs,
              fanbase:
                  artistStats.fanbase +
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
        case 'practice':
          if (artistStats.energy >= 15) {
            // Randomly choose which skills to improve
            final practiceTypes = [
              'songwriting',
              'lyrics',
              'composition',
              'inspiration',
            ];
            final selectedPractice = (practiceTypes..shuffle()).first;

            int skillGain =
                2 +
                (artistStats.energy > 50
                    ? 1
                    : 0); // Better results with more energy

            Map<String, int> improvements = {};
            String practiceMessage = '';

            switch (selectedPractice) {
              case 'songwriting':
                improvements['songwritingSkill'] = skillGain;
                improvements['experience'] = 15;
                practiceMessage = '🎼 Practiced songwriting techniques!';
                break;
              case 'lyrics':
                improvements['lyricsSkill'] = skillGain;
                improvements['experience'] = 12;
                practiceMessage = '📝 Worked on lyrical skills!';
                break;
              case 'composition':
                improvements['compositionSkill'] = skillGain;
                improvements['experience'] = 18;
                practiceMessage = '🎹 Practiced music composition!';
                break;
              case 'inspiration':
                improvements['inspirationLevel'] = skillGain * 2;
                improvements['experience'] = 10;
                practiceMessage = '💡 Gained creative inspiration!';
                break;
            }

            artistStats = artistStats.copyWith(
              energy: artistStats.energy - 15,
              creativity: artistStats.creativity + 3,
              fanbase: artistStats.fanbase + 1,
              songwritingSkill:
                  (artistStats.songwritingSkill +
                          (improvements['songwritingSkill'] ?? 0))
                      .clamp(0, 100),
              lyricsSkill:
                  (artistStats.lyricsSkill + (improvements['lyricsSkill'] ?? 0))
                      .clamp(0, 100),
              compositionSkill:
                  (artistStats.compositionSkill +
                          (improvements['compositionSkill'] ?? 0))
                      .clamp(0, 100),
              inspirationLevel:
                  (artistStats.inspirationLevel +
                          (improvements['inspirationLevel'] ?? 0))
                      .clamp(0, 100),
              experience:
                  artistStats.experience + (improvements['experience'] ?? 0),
            );
            _showMessage(
              '🎸 $practiceMessage\n+${improvements['experience']} XP, +${improvements.values.where((v) => v > 0 && improvements.keys.first != 'experience').first} ${selectedPractice[0].toUpperCase()}${selectedPractice.substring(1)} skill',
            );
          }
          break;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Quick Write Button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showQuickSongOptions();
                          },
                          icon: const Icon(Icons.flash_on, color: Colors.white),
                          label: const Text(
                            'Quick Write',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D9FF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Custom Write Button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showCustomSongForm();
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            'Custom Write',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF39C12),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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

  void _showQuickSongOptions() {
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
                  '⚡ Quick Write',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose your effort level:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ..._buildSongOptions(),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Back',
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

  List<Widget> _buildSongOptions() {
    final songTypes = [
      {
        'name': 'Quick Demo',
        'genre': 'R&B',
        'energy': 15,
        'creativity': 3,
        'fame': 2,
        'color': const Color(0xFF00D9FF),
        'icon': Icons.flash_on,
        'description': 'A smooth catchy tune',
      },
      {
        'name': 'Trap Banger',
        'genre': 'Trap',
        'energy': 25,
        'creativity': 8,
        'fame': 5,
        'color': const Color(0xFF9B59B6),
        'icon': Icons.graphic_eq,
        'description': 'Heavy beats and flows',
      },
      {
        'name': 'Drill Track',
        'genre': 'Drill',
        'energy': 30,
        'creativity': 6,
        'fame': 8,
        'color': const Color(0xFFFF6B9D),
        'icon': Icons.surround_sound,
        'description': 'Raw street energy',
      },
      {
        'name': 'Afrobeat Masterpiece',
        'genre': 'Afrobeat',
        'energy': 40,
        'creativity': 15,
        'fame': 12,
        'color': const Color(0xFFF39C12),
        'icon': Icons.auto_awesome,
        'description': 'Cultural rhythmic fusion',
      },
    ];

    return songTypes.map((songType) {
      bool canAfford = artistStats.energy >= (songType['energy'] as int);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: canAfford ? () => _writeSong(songType) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canAfford
                    ? [
                        (songType['color'] as Color).withOpacity(0.8),
                        (songType['color'] as Color).withOpacity(0.6),
                      ]
                    : [
                        Colors.grey.withOpacity(0.4),
                        Colors.grey.withOpacity(0.2),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: canAfford
                    ? (songType['color'] as Color).withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(canAfford ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    songType['icon'] as IconData,
                    color: canAfford
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songType['name'] as String,
                        style: TextStyle(
                          color: canAfford
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${songType['genre']} • ${songType['description']}',
                        style: TextStyle(
                          color: canAfford
                              ? Colors.white70
                              : Colors.white.withOpacity(0.3),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '-${songType['energy']} Energy',
                            style: TextStyle(
                              color: canAfford
                                  ? Colors.white70
                                  : Colors.white.withOpacity(0.3),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '+${songType['creativity']} Hype',
                            style: TextStyle(
                              color: canAfford
                                  ? const Color(0xFF32D74B)
                                  : Colors.white.withOpacity(0.3),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '+${songType['fame']} Fame',
                            style: TextStyle(
                              color: canAfford
                                  ? const Color(0xFFFF6B9D)
                                  : Colors.white.withOpacity(0.3),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _writeSong(Map<String, dynamic> songType) {
    Navigator.of(context).pop(); // Close dialog

    // Calculate skill gains based on effort level (quick songs give moderate skill gain)
    int effort =
        (songType['energy'] as int) ~/
        10; // Convert energy cost to effort level
    String genre = songType['genre'] as String;
    double songQuality = artistStats.calculateSongQuality(genre, effort);
    Map<String, int> skillGains = artistStats.calculateSkillGains(
      genre,
      effort,
      songQuality,
    );

    // Generate song name and create Song object
    final songName = _generateSongName(songType['genre'] as String);
    final newSong = Song(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: songName,
      genre: genre,
      quality: songQuality.round(),
      createdDate: DateTime.now(),
      state: SongState.written,
    );

    setState(() {
      artistStats = artistStats.copyWith(
        energy: artistStats.energy - (songType['energy'] as int),
        songsWritten: artistStats.songsWritten + 1,
        creativity: artistStats.creativity + (songType['creativity'] as int),
        fame: artistStats.fame + (songType['fame'] as int),
        songs: [...artistStats.songs, newSong], // Add the new song
        // Add skill progression
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
      );
    });

    // Show success message with song details and skill gains
    _showMessage(
      '🎵 Created "$songName" ($genre)!\n+${songType['creativity']} Hype, +${songType['fame']} Fame\n📈 +${skillGains['experience']} XP, Skills improved!',
    );
  }

  String _generateSongName(String genre, {int? quality}) {
    // Use the new SongNameGenerator service
    // Quality defaults to average skill level for quick songs
    final songQuality =
        quality ?? artistStats.calculateSongQuality(genre, 2).round();
    return SongNameGenerator.generateTitle(genre, quality: songQuality);
  }

  void _showCustomSongForm() {
    final TextEditingController songTitleController = TextEditingController();
    String selectedGenre = 'R&B';
    int selectedEffort = 2; // 1-4 scale
    List<String> nameSuggestions = [];

    // Generate initial suggestions based on default genre
    int estimatedQuality = artistStats
        .calculateSongQuality(selectedGenre, selectedEffort)
        .round();
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
                            items:
                                [
                                  'R&B',
                                  'Hip Hop',
                                  'Rap',
                                  'Trap',
                                  'Drill',
                                  'Afrobeat',
                                  'Country',
                                  'Jazz',
                                  'Reggae',
                                ].map((genre) {
                                  return DropdownMenuItem(
                                    value: genre,
                                    child: Row(
                                      children: [
                                        _getGenreIcon(genre),
                                        const SizedBox(width: 8),
                                        Text(genre),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              dialogSetState(() {
                                selectedGenre = value!;
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
                          bool canAfford =
                              artistStats.energy >=
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
                                    : const Color(0xFF30363D).withOpacity(0.3),
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

  Widget _getGenreIcon(String genre) {
    switch (genre) {
      case 'R&B':
        return const Icon(Icons.favorite, color: Color(0xFFFF6B9D), size: 16);
      case 'Hip Hop':
        return const Icon(Icons.mic, color: Color(0xFFFFD700), size: 16);
      case 'Rap':
        return const Icon(
          Icons.record_voice_over,
          color: Color(0xFF00D9FF),
          size: 16,
        );
      case 'Trap':
        return const Icon(Icons.graphic_eq, color: Color(0xFF9B59B6), size: 16);
      case 'Drill':
        return const Icon(
          Icons.surround_sound,
          color: Color(0xFFFF4500),
          size: 16,
        );
      case 'Afrobeat':
        return const Icon(
          Icons.celebration,
          color: Color(0xFFF39C12),
          size: 16,
        );
      case 'Country':
        return const Icon(Icons.landscape, color: Color(0xFF8B4513), size: 16);
      case 'Jazz':
        return const Icon(Icons.piano, color: Color(0xFF4169E1), size: 16);
      case 'Reggae':
        return const Icon(Icons.waves, color: Color(0xFF32CD32), size: 16);
      default:
        return const Icon(Icons.music_note, color: Colors.white, size: 16);
    }
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

    // Calculate rewards based on quality (much more modest)
    // Writing songs shouldn't make you rich - performing and releasing them should
    int moneyGain = ((songQuality / 100) * 100 * effort)
        .round(); // Max $300 for excellent song with max effort
    int fameGain = ((songQuality / 100) * 2 * effort)
        .round(); // Max 6 fame for excellent song
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

    setState(() {
      // Update main stats
      artistStats = artistStats.copyWith(
        energy: artistStats.energy - energyCost,
        songsWritten: artistStats.songsWritten + 1,
        money: artistStats.money + moneyGain,
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
      );
    }); // Publish song to Firebase if online
    if (_isOnlineMode) {
      _publishSongOnline(title, genre, songQuality.round());
    }

    // Show detailed success message
    String qualityRating = artistStats.getSongQualityRating(songQuality);
    String onlineStatus = _isOnlineMode ? ' 🌐 Published online!' : '';
    _showMessage(
      '🎵 Created "$title" ($genre - $qualityRating)\n'
      '💰 +\$${moneyGain.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} '
      '⭐ +$fameGain Fame +$creativityGain Hype\n'
      '📈 +${skillGains['experience']} XP, Skills improved!$onlineStatus',
    );
  }

  Future<void> _publishSongOnline(
    String title,
    String genre,
    int quality,
  ) async {
    try {
      await _multiplayerService.publishSong(
        title: title,
        genre: genre,
        playerName: artistStats.name,
        quality: quality,
      );
    } catch (e) {
      print('Failed to publish song online: $e');
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
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
                  _saveUserProfile(); // Save stats to Firestore
                },
                currentGameDate: currentGameDate ?? DateTime.now(),
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
                  _saveUserProfile(); // Save stats to Firestore
                },
              ),
            ),
          );
        } else if (index == 3) {
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
                  _saveUserProfile(); // Save stats to Firestore
                },
              ),
            ),
          );
        } else if (index == 4) {
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
                  _saveUserProfile(); // Save region change to Firestore
                },
              ),
            ),
          );
        } else {
          _showMessage('${_getNavItemName(index)} selected!');
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF21262D),
      selectedItemColor: const Color(0xFF00D9FF), // Cyan
      unselectedItemColor: Colors.white54,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_activity),
          label: 'Activity',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Music'),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt_rounded),
          label: 'Media',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.public), label: 'World'),
      ],
    );
  }

  String _getNavItemName(int index) {
    const names = ['Home', 'Activity', 'Music', 'Media', 'World'];
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
      // Update player stats periodically
      Timer.periodic(const Duration(minutes: 5), (timer) {
        _multiplayerService.updatePlayerStats(artistStats);
      });

      // Simulate song performance for all players
      _multiplayerService.simulateSongPerformance();
    }
  }
}
