import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../services/song_name_generator.dart';
import '../utils/genres.dart';

/// Shared dialog widget for writing songs
/// Used by both WriteSongScreen and DashboardScreen
class SongWritingDialog {
  /// Show the custom song creation form
  static Future<void> show({
    required BuildContext context,
    required ArtistStats artistStats,
    required Function(ArtistStats updatedStats) onSongCreated,
  }) {
    final TextEditingController songTitleController = TextEditingController();
    // Start with player's primary genre (first unlocked genre)
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

    return showDialog(
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
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              items: allGenres.map((String genre) {
                                bool isUnlocked = unlockedLower.contains(
                                  genre.toLowerCase(),
                                );
                                return DropdownMenuItem<String>(
                                  value: genre,
                                  enabled: isUnlocked,
                                  child: Row(
                                    children: [
                                      Text(
                                        genre,
                                        style: TextStyle(
                                          color: isUnlocked
                                              ? Colors.white
                                              : Colors.white30,
                                        ),
                                      ),
                                      if (!isUnlocked)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(
                                            Icons.lock,
                                            size: 16,
                                            color: Colors.white30,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  dialogSetState(() {
                                    selectedGenre = newValue;
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [1, 2, 3, 4].map((effort) {
                            bool isSelected = selectedEffort == effort;
                            bool canAfford = artistStats.energy >=
                                _getEnergyCostForEffort(effort);

                            return Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
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
                                            nameSuggestions = SongNameGenerator
                                                .getSuggestions(
                                              selectedGenre,
                                              count: 4,
                                              quality: quality,
                                            );
                                          });
                                        }
                                      : null,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 8,
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
                                      mainAxisSize: MainAxisSize.min,
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
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_getEnergyCostForEffort(effort)}\nEnergy',
                                          style: TextStyle(
                                            color: canAfford
                                                ? Colors.white70
                                                : Colors.white30,
                                            fontSize: 8,
                                            height: 1.1,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ),
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
                                  Navigator.of(context).pop();
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
                                    ? () {
                                        final updatedStats = _createSong(
                                          artistStats: artistStats,
                                          title:
                                              songTitleController.text.trim(),
                                          genre: selectedGenre,
                                          effort: selectedEffort,
                                        );
                                        Navigator.of(context).pop();
                                        onSongCreated(updatedStats);
                                      }
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

  /// Helper: Get effort level name
  static String _getEffortName(int effort) {
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

  /// Helper: Get energy cost for effort level
  static int _getEnergyCostForEffort(int effort) {
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

  /// Helper: Create the song and return updated stats
  static ArtistStats _createSong({
    required ArtistStats artistStats,
    required String title,
    required String genre,
    required int effort,
  }) {
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

    // Return updated stats
    return artistStats.copyWith(
      energy: artistStats.energy - energyCost,
      fame: artistStats.fame + fameGain,
      creativity: artistStats.creativity + creativityGain,
      songs: [...artistStats.songs, newSong],
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
      lastActivityDate: DateTime.now(),
    );
  }
}
