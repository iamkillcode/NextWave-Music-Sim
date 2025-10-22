import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen_new.dart';
import '../models/artist_stats.dart';
import '../services/game_time_service.dart';
import '../utils/genres.dart';

class OnboardingScreen extends StatefulWidget {
  final User user;

  const OnboardingScreen({super.key, required this.user});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  String _artistName = '';
  String _selectedGenre = 'Hip Hop';
  String _selectedRegion = 'usa';
  String _artistBio = '';
  String? _selectedGender; // 'male', 'female', 'other', or null
  int _selectedAge = 18;
  bool _isLoading = false;

  // Available options - genres centralized
  final List<String> _genres = Genres.all;

  final Map<String, Map<String, String>> _regions = {
    'usa': {'name': 'United States', 'flag': '🇺🇸'},
    'europe': {'name': 'Europe', 'flag': '🇪🇺'},
    'uk': {'name': 'United Kingdom', 'flag': '🇬🇧'},
    'asia': {'name': 'Asia', 'flag': '🌏'},
    'africa': {'name': 'Africa', 'flag': '🌍'},
    'latin_america': {'name': 'Latin America', 'flag': '🌎'},
    'oceania': {'name': 'Oceania', 'flag': '🇦🇺'},
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_artistName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your artist name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    print('🚀 Starting onboarding completion...');
    print('   Artist Name: $_artistName');
    print('   Genre: $_selectedGenre');
    print('   Region: $_selectedRegion');
    print('   User ID: ${widget.user.uid}');

    try {
      // Get current game date to set as career start date
      DateTime careerStartGameDate;
      try {
        final gameTimeService = GameTimeService();
        careerStartGameDate = await gameTimeService.getCurrentGameDate();
        print('✅ Career starting in game-world date: $careerStartGameDate');
      } catch (e) {
        print('⚠️ Could not get game date, using default: $e');
        // Fallback to game world start date (Jan 1, 2020)
        careerStartGameDate = DateTime(2020, 1, 1);
      }

      // Create player profile in Firestore
      final playerData = {
        'id': widget.user.uid,
        'displayName': _artistName.trim(),
        'email': widget.user.email ?? '',
        'gender': _selectedGender,
        'primaryGenre': _selectedGenre,
        'homeRegion': _selectedRegion,
        'bio': _artistBio.trim(),
        'joinDate': Timestamp.now(),
        'lastActive': Timestamp.now(),
        'isOnline': true,
        'currentMoney': 5000, // Starting money - enough to get started!
        'currentFame': 0,
        'level': 1,
        'fanbase': 1, // Starting fanbase (you're your own first fan!)
        'loyalFanbase': 0,
        'totalStreams': 0,
        'songsPublished': 0,
        'albumsReleased': 0,
        'concertsPerformed': 0,
        // Skills
        'songwritingSkill': 10,
        'lyricsSkill': 10,
        'compositionSkill': 10,
        'experience': 0,
        'age': _selectedAge,
        'careerStartDate': Timestamp.fromDate(careerStartGameDate), // Use game-world date!
        'inspirationLevel': 0, // No hype yet - you're just starting!
        'regionalFanbase': {}, // Empty regional fanbase initially
        'songs': [], // Empty songs list initially
      };

      // Add timeout to prevent infinite loading
      await FirebaseFirestore.instance
          .collection('players')
          .doc(widget.user.uid)
          .set(playerData)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Connection timeout. Please check your internet connection and Firebase setup.',
          );
        },
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Build initial ArtistStats to pass to Dashboard so onboarding selections show immediately
        final initialStats = ArtistStats(
          name: _artistName.trim(),
          fame: 0,
          money: 5000,
          energy: 100,
          creativity: 0,
          fanbase: 1,
          loyalFanbase: 0,
          regionalFanbase: {},
          albumsSold: 0,
          songsWritten: 0,
          concertsPerformed: 0,
          songwritingSkill: 10,
          experience: 0,
          lyricsSkill: 10,
          compositionSkill: 10,
          inspirationLevel: 0,
          songs: [],
          currentRegion: _selectedRegion,
          age: _selectedAge,
          careerStartDate: careerStartGameDate, // Use game-world date!
        );

        // Navigate to dashboard and pass initial stats
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(initialStats: initialStats),
          ),
        );
      }
    } catch (e) {
      print('❌ Onboarding error: $e');

      if (mounted) {
        setState(() => _isLoading = false);

        // Show detailed error with options
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F2E),
            title: const Text(
              '⚠️ Connection Issue',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unable to save your profile to Firebase.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Possible causes:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• No internet connection\n'
                  '• Firestore database not created\n'
                  '• Firebase not properly configured',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Try again
                  _completeOnboarding();
                },
                child: const Text(
                  'RETRY',
                  style: TextStyle(color: Color(0xFF00D9FF)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Continue anyway to dashboard (demo mode)
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                  );
                },
                child: const Text(
                  'CONTINUE ANYWAY',
                  style: TextStyle(color: Color(0xFF00D9FF)),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1117), Color(0xFF1A1F2E), Color(0xFF0D1117)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      IconButton(
                        onPressed: _previousPage,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / 5,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00D9FF),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_currentPage + 1}/5',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildWelcomePage(),
                    _buildArtistNamePage(),
                    _buildAgeSelectionPage(),
                    _buildGenderSelectionPage(),
                    _buildGenreSelectionPage(),
                    _buildRegionSelectionPage(),
                  ],
                ),
              ),

              // Bottom Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : Text(
                            _currentPage == 5
                                ? 'START YOUR JOURNEY'
                                : 'CONTINUE',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D9FF).withOpacity(0.3),
                  const Color(0xFF7C3AED).withOpacity(0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, size: 80, color: Color(0xFF00D9FF)),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to NextWave',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Music Empire Starts Here',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildFeatureItem(
            icon: Icons.music_note,
            title: 'Create Music',
            description:
                'Write songs, record albums, and build your discography',
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.public,
            title: 'Go Global',
            description: 'Travel the world and perform in different regions',
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.trending_up,
            title: 'Rise to Fame',
            description: 'Compete on global charts and become a legend',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00D9FF), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistNamePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.person, size: 80, color: Color(0xFF00D9FF)),
          const SizedBox(height: 32),
          const Text(
            'What\'s Your Artist Name?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose a name that will be remembered',
            style: TextStyle(fontSize: 16, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00D9FF).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                TextFormField(
                  initialValue: _artistName,
                  onChanged: (value) => setState(() => _artistName = value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Enter your artist name',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00D9FF),
                        width: 2,
                      ),
                    ),
                  ),
                  maxLength: 30,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: _artistBio,
                  onChanged: (value) => setState(() => _artistBio = value),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio (Optional)',
                    labelStyle: const TextStyle(color: Colors.white60),
                    hintText: 'Tell us about yourself...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00D9FF),
                        width: 2,
                      ),
                    ),
                  ),
                  maxLength: 200,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.cake, size: 80, color: Color(0xFF00D9FF)),
          const SizedBox(height: 32),
          const Text(
            'How Old Are You?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your age will progress as you play',
            style: TextStyle(fontSize: 16, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00D9FF).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$_selectedAge',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00D9FF),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Years Old',
                  style: TextStyle(fontSize: 18, color: Colors.white60),
                ),
                const SizedBox(height: 32),
                Slider(
                  value: _selectedAge.toDouble(),
                  min: 16,
                  max: 50,
                  divisions: 34,
                  activeColor: const Color(0xFF00D9FF),
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() {
                      _selectedAge = value.round();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '16',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '50',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You\'ll age naturally as time passes in the game. Your career journey will span years!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.person, size: 80, color: Color(0xFF00D9FF)),
          const SizedBox(height: 32),
          const Text(
            'Choose Your Gender',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Optional - This helps personalize your experience',
            style: TextStyle(fontSize: 16, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Male Option
          _buildGenderOption(
            gender: 'male',
            icon: Icons.male,
            label: 'Male',
            color: const Color(0xFF00D9FF),
          ),
          const SizedBox(height: 16),

          // Female Option
          _buildGenderOption(
            gender: 'female',
            icon: Icons.female,
            label: 'Female',
            color: const Color(0xFFFF6B9D),
          ),
          const SizedBox(height: 16),

          // Other Option
          _buildGenderOption(
            gender: 'other',
            icon: Icons.person_outline,
            label: 'Other',
            color: const Color(0xFF9D4EDD),
          ),
          const SizedBox(height: 16),

          // Prefer not to say
          _buildGenderOption(
            gender: null,
            icon: Icons.lock_outline,
            label: 'Prefer not to say',
            color: Colors.white60,
          ),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can change this later in settings (one time only)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption({
    required String? gender,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedGender == gender;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.3 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.music_note, size: 80, color: Color(0xFF00D9FF)),
          const SizedBox(height: 32),
          const Text(
            'Pick Your Primary Genre',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'You can experiment with other genres later',
            style: TextStyle(fontSize: 16, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _genres.length,
            itemBuilder: (context, index) {
              final genre = _genres[index];
              final isSelected = _selectedGenre == genre;

              return InkWell(
                onTap: () => setState(() => _selectedGenre = genre),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00D9FF).withOpacity(0.2)
                        : const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFF00D9FF) : Colors.white30,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      genre,
                      style: TextStyle(
                        color:
                            isSelected ? const Color(0xFF00D9FF) : Colors.white,
                        fontSize: 18,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.public, size: 80, color: Color(0xFF00D9FF)),
          const SizedBox(height: 32),
          const Text(
            'Choose Your Starting Region',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'You can travel to other regions later',
            style: TextStyle(fontSize: 16, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ..._regions.entries.map((entry) {
            final regionId = entry.key;
            final regionData = entry.value;
            final isSelected = _selectedRegion == regionId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => setState(() => _selectedRegion = regionId),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00D9FF).withOpacity(0.2)
                        : const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFF00D9FF) : Colors.white30,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        regionData['flag']!,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          regionData['name']!,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00D9FF)
                                : Colors.white,
                            fontSize: 20,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF00D9FF),
                          size: 28,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
