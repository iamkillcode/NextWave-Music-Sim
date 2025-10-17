import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../services/song_name_generator.dart';

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

  void _showQuickSongOptions() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  onPressed: () {
                    Navigator.of(context).pop(); // Close Quick Options
                    _showSongWritingDialog(); // Go back to main dialog
                  },
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
    int effort = (songType['energy'] as int) ~/
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
      artistStats = artistStats.copyWith(
        energy: artistStats.energy - (songType['energy'] as int),
        // songsWritten removed - only counts when released
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
        // Update genre mastery
        genreMastery: updatedMastery,
        lastActivityDate: DateTime.now(), // ✅ Update activity for fame decay
      );
    });

    // Close the screen and return updated stats
    Navigator.of(context).pop(artistStats);
  }

  String _generateSongName(String genre, {int? quality}) {
    // Use the SongNameGenerator service
    final songQuality =
        quality ?? artistStats.calculateSongQuality(genre, 2).round();
    return SongNameGenerator.generateTitle(genre, quality: songQuality);
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
                            items: [
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
                              // 🔒 Check if genre is unlocked
                              final bool isUnlocked =
                                  artistStats.unlockedGenres.contains(genre);

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
                                    _getGenreIcon(genre),
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

    // Calculate rewards based on quality
    int moneyGain = ((songQuality / 100) * 100 * effort).round();
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
        // Update genre mastery
        genreMastery: updatedMastery,
        lastActivityDate: DateTime.now(), // ✅ Update activity for fame decay
      );
    });

    // Close the screen and return updated stats
    Navigator.of(context).pop(artistStats);
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
