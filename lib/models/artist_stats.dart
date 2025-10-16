import 'song.dart';

class ArtistStats {
  final String name;
  final int fame;
  final int money;
  final int energy;
  final int creativity;
  final int fanbase;
  final int loyalFanbase; // Dedicated fans who consistently stream your music
  final Map<String, int>
  regionalFanbase; // Fans per region (e.g., {'usa': 500, 'europe': 200})
  final int albumsSold;
  final int songsWritten;
  final int concertsPerformed;

  // Player Skills
  final int songwritingSkill;
  final int experience;
  final int lyricsSkill;
  final int compositionSkill;
  final int inspirationLevel;
  // Song collection
  final List<Song> songs;

  // World location
  final String currentRegion;

  // Player age and career start
  final int age;
  final DateTime? careerStartDate;

  // Artist profile image
  final String? avatarUrl;

  const ArtistStats({
    required this.name,
    required this.fame,
    required this.money,
    required this.energy,
    required this.creativity,
    required this.fanbase,
    this.loyalFanbase = 0,
    this.regionalFanbase = const {},
    required this.albumsSold,
    required this.songsWritten,
    required this.concertsPerformed,
    this.songwritingSkill = 10,
    this.experience = 0,
    this.lyricsSkill = 10,
    this.compositionSkill = 10,
    this.inspirationLevel = 0, // No hype for new artists!
    this.songs = const [],
    this.currentRegion = 'usa',
    this.age = 18,
    this.careerStartDate,
    this.avatarUrl,
  });
  ArtistStats copyWith({
    String? name,
    int? fame,
    int? money,
    int? energy,
    int? creativity,
    int? fanbase,
    int? loyalFanbase,
    Map<String, int>? regionalFanbase,
    int? albumsSold,
    int? songsWritten,
    int? concertsPerformed,
    int? songwritingSkill,
    int? experience,
    int? lyricsSkill,
    int? compositionSkill,
    int? inspirationLevel,
    List<Song>? songs,
    String? currentRegion,
    int? age,
    DateTime? careerStartDate,
    String? avatarUrl,
  }) {
    return ArtistStats(
      name: name ?? this.name,
      fame: fame ?? this.fame,
      money: money ?? this.money,
      energy: energy ?? this.energy,
      creativity: creativity ?? this.creativity,
      fanbase: fanbase ?? this.fanbase,
      loyalFanbase: loyalFanbase ?? this.loyalFanbase,
      regionalFanbase: regionalFanbase ?? this.regionalFanbase,
      albumsSold: albumsSold ?? this.albumsSold,
      songsWritten: songsWritten ?? this.songsWritten,
      concertsPerformed: concertsPerformed ?? this.concertsPerformed,
      songwritingSkill: songwritingSkill ?? this.songwritingSkill,
      experience: experience ?? this.experience,
      lyricsSkill: lyricsSkill ?? this.lyricsSkill,
      compositionSkill: compositionSkill ?? this.compositionSkill,
      inspirationLevel: inspirationLevel ?? this.inspirationLevel,
      songs: songs ?? this.songs,
      currentRegion: currentRegion ?? this.currentRegion,
      age: age ?? this.age,
      careerStartDate: careerStartDate ?? this.careerStartDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  // Calculate current age based on career start and in-game time
  int getCurrentAge(DateTime currentGameDate) {
    if (careerStartDate == null) return age;
    final yearsPassed =
        currentGameDate.difference(careerStartDate!).inDays ~/ 365;
    return age + yearsPassed;
  }

  // Career level based on overall progress
  String get careerLevel {
    int totalPoints =
        fame + (money / 100).round() + fanbase + (albumsSold * 10);

    if (totalPoints < 50) return "Street Performer";
    if (totalPoints < 150) return "Local Artist";
    if (totalPoints < 300) return "Rising Star";
    if (totalPoints < 500) return "Popular Artist";
    if (totalPoints < 800) return "Celebrity";
    if (totalPoints < 1200) return "Superstar";
    return "Legend";
  }

  // Get next career milestone
  String get nextMilestone {
    if (albumsSold == 0) return "Release your first album!";
    if (concertsPerformed < 5) return "Perform 5 concerts!";
    if (fanbase < 100) return "Reach 100K fans!";
    if (fame < 200) return "Become more famous!";
    return "You're doing great! Keep growing!";
  }

  // Calculate song quality based on player skills and genre
  double calculateSongQuality(String genre, int effortLevel) {
    // Base quality from skills
    double baseQuality =
        (songwritingSkill + lyricsSkill + compositionSkill) / 3.0;
    // Genre skill multipliers
    double genreMultiplier = 1.0;
    switch (genre.toLowerCase()) {
      case 'pop':
        genreMultiplier = 1.0 + (songwritingSkill > 20 ? 0.2 : 0.0);
        break;
      case 'ballad':
        genreMultiplier = 1.0 + (lyricsSkill > 25 ? 0.3 : 0.0);
        break;
      case 'edm':
      case 'electronic':
        genreMultiplier = 1.0 + (compositionSkill > 20 ? 0.25 : 0.0);
        break;
      case 'rock':
      case 'alternative':
        genreMultiplier =
            1.0 + (songwritingSkill > 15 && compositionSkill > 15 ? 0.2 : 0.0);
        break;
      case 'r&b':
        genreMultiplier =
            1.0 + (lyricsSkill > 20 && songwritingSkill > 15 ? 0.25 : 0.0);
        break;
      case 'hip hop':
      case 'rap':
        genreMultiplier = 1.0 + (lyricsSkill > 30 ? 0.3 : 0.0);
        break;
      case 'trap':
      case 'drill':
        genreMultiplier =
            1.0 + (compositionSkill > 25 && lyricsSkill > 20 ? 0.28 : 0.0);
        break;
      case 'afrobeat':
        genreMultiplier =
            1.0 + (compositionSkill > 18 && songwritingSkill > 18 ? 0.22 : 0.0);
        break;
      case 'country':
        genreMultiplier =
            1.0 + (lyricsSkill > 22 && songwritingSkill > 20 ? 0.24 : 0.0);
        break;
      case 'jazz':
        genreMultiplier = 1.0 + (compositionSkill > 30 ? 0.35 : 0.0);
        break;
      case 'reggae':
        genreMultiplier =
            1.0 + (songwritingSkill > 18 && lyricsSkill > 18 ? 0.23 : 0.0);
        break;
    }

    // Effort level multiplier (1-4)
    double effortMultiplier = 0.5 + (effortLevel * 0.25);

    // Inspiration factor
    double inspirationFactor = 0.8 + (inspirationLevel / 100.0 * 0.4);

    // Experience bonus
    double experienceBonus = 1.0 + (experience / 1000.0 * 0.2);

    // Calculate final quality (0-100)
    double quality =
        baseQuality *
        genreMultiplier *
        effortMultiplier *
        inspirationFactor *
        experienceBonus;

    return quality.clamp(1.0, 100.0);
  }

  // Calculate skill gains from writing a song
  Map<String, int> calculateSkillGains(
    String genre,
    int effortLevel,
    double songQuality,
  ) {
    int baseGain = effortLevel;
    int bonusGain = songQuality > 70
        ? 2
        : songQuality > 50
        ? 1
        : 0;

    Map<String, int> gains = {
      'songwritingSkill': baseGain + bonusGain,
      'experience': (effortLevel * 10) + (songQuality / 10).round(),
      'lyricsSkill': 0,
      'compositionSkill': 0,
      'inspirationLevel': -5, // Using inspiration reduces it
    };
    // Genre-specific skill gains
    switch (genre.toLowerCase()) {
      case 'ballad':
        gains['lyricsSkill'] = baseGain + bonusGain + 1;
        break;
      case 'edm':
      case 'electronic':
        gains['compositionSkill'] = baseGain + bonusGain + 1;
        break;
      case 'rock':
      case 'alternative':
        gains['compositionSkill'] = (baseGain + bonusGain) ~/ 2;
        gains['lyricsSkill'] = (baseGain + bonusGain) ~/ 2;
        break;
      case 'r&b':
        gains['lyricsSkill'] = baseGain + bonusGain;
        gains['songwritingSkill'] = baseGain + bonusGain;
        break;
      case 'hip hop':
      case 'rap':
        gains['lyricsSkill'] = baseGain + bonusGain + 2;
        break;
      case 'trap':
      case 'drill':
        gains['lyricsSkill'] = baseGain + bonusGain + 1;
        gains['compositionSkill'] = baseGain + bonusGain;
        break;
      case 'afrobeat':
        gains['compositionSkill'] = baseGain + bonusGain + 1;
        gains['songwritingSkill'] = baseGain + bonusGain;
        break;
      case 'country':
        gains['lyricsSkill'] = baseGain + bonusGain + 1;
        gains['songwritingSkill'] = baseGain + bonusGain + 1;
        break;
      case 'jazz':
        gains['compositionSkill'] = baseGain + bonusGain + 2;
        break;
      case 'reggae':
        gains['songwritingSkill'] = baseGain + bonusGain + 1;
        gains['lyricsSkill'] = baseGain + bonusGain;
        break;
      default: // Pop and others
        gains['lyricsSkill'] = baseGain ~/ 2;
        gains['compositionSkill'] = baseGain ~/ 2;
    }

    return gains;
  }

  // Get song quality rating text
  String getSongQualityRating(double quality) {
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
}
