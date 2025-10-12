import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../services/firebase_service.dart';
import '../services/demo_firebase_service.dart';
import '../services/game_time_service.dart';
import 'leaderboard_screen.dart';
import 'tunify_screen.dart';
import 'world_map_screen.dart';
import 'music_hub_screen.dart';
import '../utils/firebase_status.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ArtistStats artistStats;
  int _selectedIndex = 0;
  late Timer gameTimer;
  late Timer syncTimer;
  DateTime currentGameDate = DateTime(2020, 1, 1); // Default, will be updated by global time
  late dynamic _multiplayerService; // Can be FirebaseService or DemoFirebaseService
  bool _isOnlineMode = false;
  bool _isInitializing = false;
  final GameTimeService _gameTimeService = GameTimeService();

  @override
  void initState() {
    super.initState();
    // Initialize global game time
    _initializeGameTime();
    
    // Initialize with default stats (will be replaced by user profile)
    artistStats = ArtistStats(
      name: "Loading...",
      fame: 0,
      money: 5000,
      energy: 100,
      creativity: 50,
      fanbase: 1,
      albumsSold: 0,
      songsWritten: 0,
      concertsPerformed: 0,
      songwritingSkill: 10,
      experience: 0,
      lyricsSkill: 10,
      compositionSkill: 10,
      inspirationLevel: 50,
    );
    
    // Load user profile from Firestore
    _loadUserProfile();
    
    // Initialize Firebase authentication
    _initializeOnlineMode();
    
    // Start the game world timer - updates every second for live time display
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateGameTime();
    });
    
    // Sync with Firebase every 5 minutes to ensure accuracy
    syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final gameDate = await _gameTimeService.getCurrentGameDate();
        setState(() {
          currentGameDate = gameDate;
        });
        print('🔄 Synced with global time: ${_gameTimeService.formatGameDate(gameDate)}');
      } catch (e) {
        print('❌ Error syncing time: $e');
      }
    });
  }

  /// Initialize the global game time system
  Future<void> _initializeGameTime() async {
    try {
      // Initialize the game time system in Firestore (only happens once)
      await _gameTimeService.initializeGameTime();
      
      // Get the current synchronized game date
      final gameDate = await _gameTimeService.getCurrentGameDate();
      setState(() {
        currentGameDate = gameDate;
      });
      
      print('🕐 Global game time loaded: ${_gameTimeService.formatGameDate(gameDate)}');
    } catch (e) {
      print('❌ Error initializing game time: $e');
      // Fallback to local calculation
      setState(() {
        currentGameDate = DateTime(2020, 1, 1);
      });
    }
  }

  @override
  void dispose() {
    gameTimer.cancel();
    syncTimer.cancel();
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

      if (doc.exists) {
        final data = doc.data()!;
        print('✅ Profile loaded: ${data['displayName']}');
        
        setState(() {
          artistStats = ArtistStats(
            name: data['displayName'] ?? 'Unknown Artist',
            fame: (data['currentFame'] ?? 0).toInt(),
            money: (data['currentMoney'] ?? 5000).toInt(),
            energy: 100, // Always start with full energy
            creativity: (data['inspirationLevel'] ?? 50).toInt(),
            fanbase: (data['level'] ?? 1).toInt(),
            albumsSold: (data['albumsReleased'] ?? 0).toInt(),
            songsWritten: (data['songsPublished'] ?? 0).toInt(),
            concertsPerformed: (data['concertsPerformed'] ?? 0).toInt(),
            songwritingSkill: (data['songwritingSkill'] ?? 10).toInt(),
            experience: (data['experience'] ?? 0).toInt(),
            lyricsSkill: (data['lyricsSkill'] ?? 10).toInt(),
            compositionSkill: (data['compositionSkill'] ?? 10).toInt(),
            inspirationLevel: (data['inspirationLevel'] ?? 50).toInt(),
            currentRegion: data['homeRegion'] ?? 'usa',
            age: (data['age'] ?? 18).toInt(),
            careerStartDate: (data['careerStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        });
      } else {
        print('⚠️ Profile not found in Firestore, using demo stats');
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      print('💡 Using demo stats instead');
      // Keep the default stats if loading fails
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
            'inspirationLevel': artistStats.inspirationLevel,
            'level': artistStats.fanbase,
            'albumsReleased': artistStats.albumsSold,
            'songsPublished': artistStats.songsWritten,
            'concertsPerformed': artistStats.concertsPerformed,
            'songwritingSkill': artistStats.songwritingSkill,
            'experience': artistStats.experience,
            'lyricsSkill': artistStats.lyricsSkill,
            'compositionSkill': artistStats.compositionSkill,
            'homeRegion': artistStats.currentRegion,
            'age': artistStats.age,
            if (artistStats.careerStartDate != null)
              'careerStartDate': Timestamp.fromDate(artistStats.careerStartDate!),
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

  void _updateGameTime() {
    // Update time locally every second for smooth display
    // This calculates the game time based on the passage of real time
    // 1 real second = 24 game seconds (since 1 real hour = 1 game day)
    setState(() {
      currentGameDate = currentGameDate.add(const Duration(seconds: 24));
    });
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
            Expanded(
              child: _buildActionPanel(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTopStatusBar() {
    // Use game time instead of real time
    final gameTime = currentGameDate;
    final timeString = '${gameTime.hour.toString().padLeft(2, '0')}:${gameTime.minute.toString().padLeft(2, '0')}';
    final dateString = '${_getMonthName(gameTime.month)} ${gameTime.day}, ${gameTime.year}';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '\$${(artistStats.money / 1000000).toStringAsFixed(1)}M',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B69), // Deep purple
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00D9FF).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.public,
                  color: Color(0xFF00D9FF),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeString,
                      style: const TextStyle(
                        color: Color(0xFF00D9FF), // Cyan blue
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateString,
                      style: TextStyle(
                        color: const Color(0xFF00D9FF).withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Time conversion indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B9D).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '1h = 1 day ⚡',
                        style: TextStyle(
                          color: Color(0xFFFF6B9D),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Show global time sync indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF32D74B).withOpacity(0.2), // Green
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sync,
                  color: Color(0xFF32D74B),
                  size: 10,
                ),
                SizedBox(width: 4),
                Text(
                  'SYNCED',
                  style: TextStyle(
                    color: Color(0xFF32D74B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Online mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (_isOnlineMode ? const Color(0xFF32D74B) : const Color(0xFF8E8E93)).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOnlineMode ? Icons.cloud_done : Icons.cloud_off,
                  color: _isOnlineMode ? const Color(0xFF32D74B) : const Color(0xFF8E8E93),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnlineMode ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: _isOnlineMode ? const Color(0xFF32D74B) : const Color(0xFF8E8E93),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildGameStatusRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          _buildAdvancedStatusCard(
            'Fame',
            artistStats.fame,
            100, // Max value for progress bar
            Icons.stars_rounded,
            const Color(0xFFE94560), // Red
            const Color(0xFF16213E), // Dark blue
            'Rising Star',
          ),
          const SizedBox(width: 8),
          _buildAdvancedStatusCard(
            'Hype', 
            artistStats.creativity,
            500, // Max value for progress bar
            Icons.whatshot_rounded,
            const Color(0xFF9B59B6), // Purple
            const Color(0xFF2C3E50), // Dark slate
            'Viral',
          ),
          const SizedBox(width: 8),
          _buildAdvancedStatusCard(
            'Level',
            artistStats.fanbase,
            50, // Max value for progress bar
            Icons.military_tech_rounded,
            const Color(0xFFF39C12), // Orange
            const Color(0xFF1A252F), // Dark navy
            'Pro',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBlock(String title, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF21262D), // Darker GitHub card color
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),      ),
    );
  }

  Widget _buildEnhancedStatusBlock(String title, String value, IconData icon, Color primaryColor, Color darkColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withOpacity(0.8), darkColor.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );  }

  Widget _buildAdvancedStatusCard(String title, int value, int maxValue, IconData icon, Color primaryColor, Color backgroundColor, String status) {
    double progress = (value / maxValue).clamp(0.0, 1.0);
    
    return Expanded(
      child: Container(
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
          border: Border.all(
            color: primaryColor.withOpacity(0.4),
            width: 1.5,
          ),
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
                          child: Icon(
                            icon,
                            color: primaryColor,
                            size: 16,
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    ),                    Text(
                      '${artistStats.getCurrentAge(currentGameDate)} years old • ${artistStats.careerLevel}',
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
              border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
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
                    _buildSkillBar('Songwriting', artistStats.songwritingSkill, const Color(0xFF00D9FF)),
                    const SizedBox(width: 12),
                    _buildSkillBar('Lyrics', artistStats.lyricsSkill, const Color(0xFFFF6B9D)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSkillBar('Composition', artistStats.compositionSkill, const Color(0xFF9B59B6)),
                    const SizedBox(width: 12),
                    _buildSkillBar('Inspiration', artistStats.inspirationLevel, const Color(0xFFF39C12)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      const Icon(Icons.star, color: Color(0xFF2ECC71), size: 16),
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

  Widget _buildCareerCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Career Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildCareerCard('Songs Written', '${artistStats.songsWritten}', Icons.music_note, const Color(0xFF00D9FF)),
                _buildCareerCard('Albums Sold', '${artistStats.albumsSold}K', Icons.album, const Color(0xFFFF6B9D)),
                _buildCareerCard('Concerts', '${artistStats.concertsPerformed}', Icons.stadium, const Color(0xFF7C3AED)),
                _buildCareerCard('Energy', '${artistStats.energy}%', Icons.bolt, const Color(0xFFF59E0B)),
              ],
            ),
          ),
        ],
      ),
    );  }

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
                child: const Icon(Icons.flash_on, color: Color(0xFF00D9FF), size: 16),
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
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.95,
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
                  'Concert',
                  Icons.mic_rounded,
                  const Color(0xFFFF6B9D),
                  energyCost: 30,
                  onTap: () => _performAction('concert'),
                ),
                _buildActionCard(
                  'Album',
                  Icons.album_rounded,
                  const Color(0xFF9B59B6),
                  energyCost: 40,
                  onTap: () => _performAction('record_album'),
                ),
                _buildActionCard(
                  'Practice',
                  Icons.music_note_rounded,
                  const Color(0xFFF39C12),
                  energyCost: 15,
                  onTap: () => _performAction('practice'),
                ),
                _buildActionCard(
                  'Social',
                  Icons.share_rounded,
                  const Color(0xFF32D74B),
                  energyCost: 10,
                  onTap: () => _performAction('social_media'),
                ),
                _buildActionCard(
                  'Rest',
                  Icons.bed_rounded,
                  const Color(0xFF8E8E93),
                  energyCost: -50,
                  onTap: () => _performAction('rest'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, {required int energyCost, required VoidCallback onTap, String? customCostText}) {
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
            color: canPerform ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: canPerform ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(canPerform ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: canPerform ? Colors.white : Colors.white.withOpacity(0.5),
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: canPerform ? Colors.white : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                customCostText ?? (energyCost < 0 ? '+${-energyCost}' : '-$energyCost'),
                style: TextStyle(
                  color: canPerform 
                      ? (energyCost < 0 ? const Color(0xFF32D74B) : Colors.white.withOpacity(0.7))
                      : Colors.white.withOpacity(0.3),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performAction(String action) {
    setState(() {
      switch (action) {        case 'write_song':
          if (artistStats.energy >= 20) {
            _showSongWritingDialog();
          }
          break;
        case 'concert':
          if (artistStats.energy >= 30) {
            artistStats = artistStats.copyWith(
              energy: artistStats.energy - 30,
              concertsPerformed: artistStats.concertsPerformed + 1,
              fame: artistStats.fame + 10,
              money: artistStats.money + 50000,
            );
            _showMessage('🎤 Great concert! Fame +10, +\$50K');
          }
          break;
        case 'record_album':
          if (artistStats.energy >= 40 && artistStats.songsWritten >= 3) {
            artistStats = artistStats.copyWith(
              energy: artistStats.energy - 40,
              albumsSold: artistStats.albumsSold + 1,
              songsWritten: artistStats.songsWritten - 3, // Use 3 songs for album
              money: artistStats.money + 200000,
              fame: artistStats.fame + 15,
            );
            _showMessage('💿 Album released! Fame +15, +\$200K');
          } else if (artistStats.songsWritten < 3) {
            _showMessage('❌ Need at least 3 songs to record an album');
          }
          break;        case 'practice':
          if (artistStats.energy >= 15) {
            // Randomly choose which skills to improve
            final practiceTypes = ['songwriting', 'lyrics', 'composition', 'inspiration'];
            final selectedPractice = (practiceTypes..shuffle()).first;
            
            int skillGain = 2 + (artistStats.energy > 50 ? 1 : 0); // Better results with more energy
            
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
              songwritingSkill: (artistStats.songwritingSkill + (improvements['songwritingSkill'] ?? 0)).clamp(0, 100),
              lyricsSkill: (artistStats.lyricsSkill + (improvements['lyricsSkill'] ?? 0)).clamp(0, 100),
              compositionSkill: (artistStats.compositionSkill + (improvements['compositionSkill'] ?? 0)).clamp(0, 100),
              inspirationLevel: (artistStats.inspirationLevel + (improvements['inspirationLevel'] ?? 0)).clamp(0, 100),
              experience: artistStats.experience + (improvements['experience'] ?? 0),
            );
            _showMessage('🎸 $practiceMessage\n+${improvements['experience']} XP, +${improvements.values.where((v) => v > 0 && improvements.keys.first != 'experience').first} ${selectedPractice[0].toUpperCase()}${selectedPractice.substring(1)} skill');
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
        case 'rest':
          int energyGain = (100 - artistStats.energy).clamp(0, 50);
          artistStats = artistStats.copyWith(
            energy: (artistStats.energy + energyGain).clamp(0, 100),
          );
          _showMessage('😴 You rested and gained $energyGain energy');
          break;
      }
    });  }

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
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
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

  List<Widget> _buildSongOptions() {    final songTypes = [
      {
        'name': 'Quick Demo',
        'genre': 'R&B',
        'energy': 15,
        'creativity': 3,
        'fame': 2,
        'color': const Color(0xFF00D9FF),
        'icon': Icons.flash_on,
        'description': 'A smooth catchy tune'
      },
      {
        'name': 'Trap Banger',
        'genre': 'Trap',
        'energy': 25,
        'creativity': 8,
        'fame': 5,
        'color': const Color(0xFF9B59B6),
        'icon': Icons.graphic_eq,
        'description': 'Heavy beats and flows'
      },
      {
        'name': 'Drill Track',
        'genre': 'Drill',
        'energy': 30,
        'creativity': 6,
        'fame': 8,
        'color': const Color(0xFFFF6B9D),
        'icon': Icons.surround_sound,
        'description': 'Raw street energy'
      },
      {
        'name': 'Afrobeat Masterpiece',
        'genre': 'Afrobeat',
        'energy': 40,
        'creativity': 15,
        'fame': 12,
        'color': const Color(0xFFF39C12),
        'icon': Icons.auto_awesome,
        'description': 'Cultural rhythmic fusion'
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
                    ? [(songType['color'] as Color).withOpacity(0.8), (songType['color'] as Color).withOpacity(0.6)]
                    : [Colors.grey.withOpacity(0.4), Colors.grey.withOpacity(0.2)],
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
                    color: canAfford ? Colors.white : Colors.white.withOpacity(0.5),
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
                          color: canAfford ? Colors.white : Colors.white.withOpacity(0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${songType['genre']} • ${songType['description']}',
                        style: TextStyle(
                          color: canAfford ? Colors.white70 : Colors.white.withOpacity(0.3),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '-${songType['energy']} Energy',
                            style: TextStyle(
                              color: canAfford ? Colors.white70 : Colors.white.withOpacity(0.3),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '+${songType['creativity']} Hype',
                            style: TextStyle(
                              color: canAfford ? const Color(0xFF32D74B) : Colors.white.withOpacity(0.3),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '+${songType['fame']} Fame',
                            style: TextStyle(
                              color: canAfford ? const Color(0xFFFF6B9D) : Colors.white.withOpacity(0.3),
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
    int effort = (songType['energy'] as int) ~/ 10; // Convert energy cost to effort level
    String genre = songType['genre'] as String;
    double songQuality = artistStats.calculateSongQuality(genre, effort);
    Map<String, int> skillGains = artistStats.calculateSkillGains(genre, effort, songQuality);
    
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
        songwritingSkill: (artistStats.songwritingSkill + skillGains['songwritingSkill']!).clamp(0, 100),
        experience: (artistStats.experience + skillGains['experience']!).clamp(0, 10000),
        lyricsSkill: (artistStats.lyricsSkill + skillGains['lyricsSkill']!).clamp(0, 100),
        compositionSkill: (artistStats.compositionSkill + skillGains['compositionSkill']!).clamp(0, 100),
        inspirationLevel: (artistStats.inspirationLevel + skillGains['inspirationLevel']!).clamp(0, 100),
      );
    });

    // Show success message with song details and skill gains
    _showMessage('🎵 Created "$songName" ($genre)!\n+${songType['creativity']} Hype, +${songType['fame']} Fame\n📈 +${skillGains['experience']} XP, Skills improved!');
  }

  String _generateSongName(String genre) {
    final songTitles = {
      'R&B': ['Smooth Operator', 'Soul Connection', 'Midnight Vibes', 'Love Languages', 'Velvet Touch'],
      'Hip Hop': ['Street Chronicles', 'Flow State', 'City Dreams', 'Hustle Hard', 'Crown Jewels'],
      'Rap': ['Lyrical Genius', 'Bars & Beats', 'Mic Drop', 'Word Play', 'Real Talk'],
      'Trap': ['Money Moves', 'Trap House', 'Bass Heavy', 'Street Life', 'Get Money'],
      'Drill': ['No Cap', 'Block Hot', 'Drill Time', 'Street Code', 'Real One'],
      'Afrobeat': ['Lagos Nights', 'African Queen', 'Rhythm Divine', 'Motherland', 'Tribal Beats'],
      'Country': ['Small Town', 'Country Roads', 'Whiskey Nights', 'Southern Belle', 'Pickup Truck'],
      'Jazz': ['Blue Notes', 'Smooth Jazz', 'Midnight Sax', 'Cool Breeze', 'Swing Time'],
      'Reggae': ['One Love', 'Island Vibes', 'Rasta Mon', 'Good Times', 'Peaceful Mind'],
    };
    
    final titles = songTitles[genre] ?? ['New Song'];
    titles.shuffle();
    return titles.first;
  }

  void _showCustomSongForm() {
    final TextEditingController songTitleController = TextEditingController();
    String selectedGenre = 'R&B';
    int selectedEffort = 2; // 1-4 scale
    
    showDialog(
      context: context,
      builder: (BuildContext context) {        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            // Calculate energy cost for display
            int energyCost = _getEnergyCostForEffort(selectedEffort);
            
            return Dialog(
              backgroundColor: const Color(0xFF21262D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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

                    // Song Title Input
                    const Text(
                      'Song Title:',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: songTitleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter song title...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: const Color(0xFF30363D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Genre Selection
                    const Text(
                      'Genre:',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF30363D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedGenre,
                          dropdownColor: const Color(0xFF30363D),
                          style: const TextStyle(color: Colors.white),
                          items: ['R&B', 'Hip Hop', 'Rap', 'Trap', 'Drill', 'Afrobeat', 'Country', 'Jazz', 'Reggae'].map((genre) {
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
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [1, 2, 3, 4].map((effort) {
                        bool isSelected = selectedEffort == effort;
                        bool canAfford = artistStats.energy >= _getEnergyCostForEffort(effort);
                        
                        return GestureDetector(
                          onTap: canAfford ? () {
                            dialogSetState(() {
                              selectedEffort = effort;
                            });
                          } : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF00D9FF) 
                                  : canAfford 
                                      ? const Color(0xFF30363D)
                                      : const Color(0xFF30363D).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00D9FF) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _getEffortName(effort),
                                  style: TextStyle(
                                    color: canAfford ? Colors.white : Colors.white30,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${_getEnergyCostForEffort(effort)} Energy',
                                  style: TextStyle(
                                    color: canAfford ? Colors.white70 : Colors.white30,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),                    const SizedBox(height: 20),

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
                            style: TextStyle(color: Colors.white70, fontSize: 14),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                            onPressed: (songTitleController.text.trim().isNotEmpty && 
                                       artistStats.energy >= energyCost)
                                ? () => _createCustomSong(
                                    songTitleController.text.trim(),
                                    selectedGenre,
                                    selectedEffort,
                                  )
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D9FF),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
        return const Icon(Icons.record_voice_over, color: Color(0xFF00D9FF), size: 16);
      case 'Trap':
        return const Icon(Icons.graphic_eq, color: Color(0xFF9B59B6), size: 16);
      case 'Drill':
        return const Icon(Icons.surround_sound, color: Color(0xFFFF4500), size: 16);
      case 'Afrobeat':
        return const Icon(Icons.celebration, color: Color(0xFFF39C12), size: 16);
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
      case 1: return 'Quick';
      case 2: return 'Focused';
      case 3: return 'Intense';
      case 4: return 'Masterwork';
      default: return 'Normal';
    }
  }

  int _getEnergyCostForEffort(int effort) {
    switch (effort) {
      case 1: return 15;
      case 2: return 25;
      case 3: return 35;
      case 4: return 45;
      default: return 25;
    }
  }

  void _createCustomSong(String title, String genre, int effort) {
    Navigator.of(context).pop(); // Close dialog
    
    // Calculate song quality and skill gains
    double songQuality = artistStats.calculateSongQuality(genre, effort);
    Map<String, int> skillGains = artistStats.calculateSkillGains(genre, effort, songQuality);
    int energyCost = _getEnergyCostForEffort(effort);
    
    // Calculate rewards based on quality
    int moneyGain = ((songQuality / 100) * 50000 * effort).round();
    int fameGain = ((songQuality / 100) * 10 * effort).round();
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
        songwritingSkill: (artistStats.songwritingSkill + skillGains['songwritingSkill']!).clamp(0, 100),
        experience: (artistStats.experience + skillGains['experience']!).clamp(0, 10000),
        lyricsSkill: (artistStats.lyricsSkill + skillGains['lyricsSkill']!).clamp(0, 100),
        compositionSkill: (artistStats.compositionSkill + skillGains['compositionSkill']!).clamp(0, 100),
        inspirationLevel: (artistStats.inspirationLevel + skillGains['inspirationLevel']!).clamp(0, 100),
      );
    });// Publish song to Firebase if online
    if (_isOnlineMode) {
      _publishSongOnline(title, genre, songQuality.round());
    }

    // Show detailed success message
    String qualityRating = artistStats.getSongQualityRating(songQuality);
    String onlineStatus = _isOnlineMode ? ' 🌐 Published online!' : '';
    _showMessage('🎵 Created "$title" ($genre - $qualityRating)\n'
                '💰 +\$${moneyGain.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} '
                '⭐ +$fameGain Fame +$creativityGain Hype\n'
                '📈 +${skillGains['experience']} XP, Skills improved!$onlineStatus');
  }

  Future<void> _publishSongOnline(String title, String genre, int quality) async {
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
      currentIndex: _selectedIndex,      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });          // Handle navigation
        if (index == 1 && _isOnlineMode) { // Activity tab -> Leaderboards
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LeaderboardScreen(
                multiplayerService: _multiplayerService,
              ),
            ),
          );
        } else if (index == 1 && !_isOnlineMode) {
          _showMessage('🌐 Connecting to online mode...');
          _initializeOnlineMode();        } else if (index == 2) { // Music tab -> Music Hub
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
          );        } else if (index == 3) { // Tunify tab -> Tunify Platform
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TunifyScreen(
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
        } else if (index == 4) { // World tab -> World Map
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
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_activity),
          label: 'Activity',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.music_note),
          label: 'Music',
        ),        BottomNavigationBarItem(
          icon: Icon(Icons.queue_music),
          label: 'Tunify',
        ),        BottomNavigationBarItem(
          icon: Icon(Icons.public),
          label: 'World',
        ),
      ],
    );
  }

  String _getNavItemName(int index) {
    const names = ['Home', 'Activity', 'Music', 'Tunify', 'World'];
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
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
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
    
    setState(() {
      _isInitializing = true;
    });

    try {
      // Check if Firebase was initialized successfully
      if (FirebaseStatus.isInitialized) {
        print('Firebase is available, attempting real Firebase service...');
        _multiplayerService = FirebaseService();
        await _multiplayerService.signInAnonymously();
        
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

    // Fallback to demo service
    print('Using demo service...');
    _multiplayerService = DemoFirebaseService();
    final success = await _multiplayerService.signInAnonymously();
    
    setState(() {
      _isOnlineMode = success;
      _isInitializing = false;
    });
    
    if (success) {
      _showMessage('🎮 Connected in Demo Mode! Leaderboards available via Activity tab.');
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
