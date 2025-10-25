import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../services/song_name_generator.dart';
import '../utils/genres.dart';

class WriteSongScreen extends StatefulWidget {
  final ArtistStats artistStats;

  const WriteSongScreen({super.key, required this.artistStats});

  @override
  State<WriteSongScreen> createState() => _WriteSongScreenState();
}

class _WriteSongScreenState extends State<WriteSongScreen> {
  late ArtistStats artistStats;

  @override
  void initState() {
    super.initState();
    artistStats = widget.artistStats;
    // Show the song writing dialog immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSongWritingDialog();
    });
  }

  void _showSongWritingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
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
                // Custom Write Button (Full width)
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
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(
                      context,
                    ).pop(artistStats); // Return to previous screen
                  },
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
      barrierDismissible: false,
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
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: SingleChildScrollView(
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
                            hintText:
                                'Enter song title or pick a suggestion...',
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
                                    unlockedLower
                                        .contains(value.toLowerCase())) {
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
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pop(); // Close custom form
                                  _showSongWritingDialog(); // Go back to main dialog
                                },
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
                                onPressed: (songTitleController.text
                                            .trim()
                                            .isNotEmpty &&
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

  void _createCustomSong(String title, String genre, int effort) {
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

    // Update stats before navigation
    final updatedStats = artistStats.copyWith(
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
      lyricsSkill:
          (artistStats.lyricsSkill + skillGains['lyricsSkill']!).clamp(0, 100),
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

    // Close dialog and screen with updated stats - no setState needed
    Navigator.of(context).pop(); // Close dialog
    Navigator.of(context)
        .pop(updatedStats); // Return to previous screen with updated stats
  }

  @override
  Widget build(BuildContext context) {
    // Empty scaffold - dialog shows immediately on init
    return const Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF00D9FF))),
    );
  }
}
