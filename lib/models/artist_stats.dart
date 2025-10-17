import 'song.dart';
import 'side_hustle.dart';
import 'album.dart';

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

  // Side hustle system
  final SideHustle? activeSideHustle; // Current active side hustle contract

  // Player Skills
  final int songwritingSkill;
  final int experience;
  final int lyricsSkill;
  final int compositionSkill;
  final int inspirationLevel;
  // Song collection
  final List<Song> songs;

  // Album/EP collection
  final List<Album> albums;

  // World location
  final String currentRegion;

  // Player age and career start
  final int age;
  final DateTime? careerStartDate;

  // Artist profile image
  final String? avatarUrl;

  // Last activity tracking for fame decay
  final DateTime? lastActivityDate;

  // Genre system - PRIMARY GENRE & MASTERY
  final String primaryGenre; // Genre chosen during onboarding
  final Map<String, int> genreMastery; // Mastery level per genre (0-100)
  final List<String> unlockedGenres; // Genres player can use

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
    this.albums = const [],
    this.currentRegion = 'usa',
    this.age = 18,
    this.careerStartDate,
    this.avatarUrl,
    this.lastActivityDate,
    this.activeSideHustle,
    this.primaryGenre = 'Hip Hop', // Default to Hip Hop if not specified
    this.genreMastery = const {}, // Empty initially
    this.unlockedGenres =
        const [], // Empty initially, will be populated with primaryGenre
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
    List<Album>? albums,
    String? currentRegion,
    int? age,
    DateTime? careerStartDate,
    String? avatarUrl,
    DateTime? lastActivityDate,
    SideHustle? activeSideHustle,
    bool clearSideHustle = false, // Flag to explicitly clear side hustle
    String? primaryGenre,
    Map<String, int>? genreMastery,
    List<String>? unlockedGenres,
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
      albums: albums ?? this.albums,
      currentRegion: currentRegion ?? this.currentRegion,
      age: age ?? this.age,
      careerStartDate: careerStartDate ?? this.careerStartDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      activeSideHustle:
          clearSideHustle ? null : (activeSideHustle ?? this.activeSideHustle),
      primaryGenre: primaryGenre ?? this.primaryGenre,
      genreMastery: genreMastery ?? this.genreMastery,
      unlockedGenres: unlockedGenres ?? this.unlockedGenres,
    );
  }

  // Calculate current age based on career start and in-game time
  int getCurrentAge(DateTime currentGameDate) {
    if (careerStartDate == null) return age;
    final yearsPassed =
        currentGameDate.difference(careerStartDate!).inDays ~/ 365;
    return age + yearsPassed;
  }

  // Career level based on overall progress (15 tiers with exponential growth)
  String get careerLevel {
    int totalPoints =
        fame + (money / 100).round() + fanbase + (albumsSold * 10);

    // Exponential tier thresholds
    if (totalPoints < 100) return "Street Busker"; // Tier 1
    if (totalPoints < 300) return "Open Mic Regular"; // Tier 2
    if (totalPoints < 600) return "Local Talent"; // Tier 3
    if (totalPoints < 1000) return "Underground Artist"; // Tier 4
    if (totalPoints < 1600) return "Rising Star"; // Tier 5
    if (totalPoints < 2500) return "Breakthrough Act"; // Tier 6
    if (totalPoints < 4000) return "Chart Regular"; // Tier 7
    if (totalPoints < 6500) return "Radio Favorite"; // Tier 8
    if (totalPoints < 10000) return "Platinum Artist"; // Tier 9
    if (totalPoints < 15000) return "Award Winner"; // Tier 10
    if (totalPoints < 22000) return "Global Star"; // Tier 11
    if (totalPoints < 32000) return "Superstar"; // Tier 12
    if (totalPoints < 45000) return "Icon"; // Tier 13
    if (totalPoints < 65000) return "Living Legend"; // Tier 14
    return "Hall of Fame"; // Tier 15
  }

  // Get career tier number (1-15)
  int get careerTier {
    int totalPoints =
        fame + (money / 100).round() + fanbase + (albumsSold * 10);

    if (totalPoints < 100) return 1;
    if (totalPoints < 300) return 2;
    if (totalPoints < 600) return 3;
    if (totalPoints < 1000) return 4;
    if (totalPoints < 1600) return 5;
    if (totalPoints < 2500) return 6;
    if (totalPoints < 4000) return 7;
    if (totalPoints < 6500) return 8;
    if (totalPoints < 10000) return 9;
    if (totalPoints < 15000) return 10;
    if (totalPoints < 22000) return 11;
    if (totalPoints < 32000) return 12;
    if (totalPoints < 45000) return 13;
    if (totalPoints < 65000) return 14;
    return 15;
  }

  // Get next career milestone
  String get nextMilestone {
    if (albumsSold == 0) return "Release your first album!";
    if (concertsPerformed < 5) return "Perform 5 concerts!";
    if (fanbase < 100) return "Reach 100K fans!";
    if (fame < 200) return "Become more famous!";
    return "You're doing great! Keep growing!";
  }

  // ============================================================================
  // FAME BONUSES - Fame impacts multiple game systems
  // ============================================================================

  /// Stream growth multiplier based on fame (1.0 = no bonus, 2.0 = double)
  /// Higher fame = more people discover your music
  double get fameStreamBonus {
    if (fame < 10) return 1.0; // No bonus
    if (fame < 25) return 1.05; // +5%
    if (fame < 50) return 1.10; // +10%
    if (fame < 75) return 1.15; // +15%
    if (fame < 100) return 1.20; // +20%
    if (fame < 150) return 1.30; // +30%
    if (fame < 200) return 1.40; // +40%
    if (fame < 300) return 1.50; // +50%
    if (fame < 400) return 1.65; // +65%
    if (fame < 500) return 1.80; // +80%
    return 2.0; // +100% (double streams!)
  }

  /// Fan conversion rate multiplier (how likely listeners become fans)
  /// Higher fame = people more likely to follow you
  double get fameFanConversionBonus {
    if (fame < 10) return 1.0; // 15% base rate
    if (fame < 25) return 1.1; // +10% conversion
    if (fame < 50) return 1.2; // +20%
    if (fame < 100) return 1.35; // +35%
    if (fame < 150) return 1.5; // +50%
    if (fame < 200) return 1.7; // +70%
    if (fame < 300) return 1.9; // +90%
    if (fame < 400) return 2.1; // +110%
    if (fame < 500) return 2.3; // +130%
    return 2.5; // +150%
  }

  /// Concert ticket price multiplier
  /// More famous = charge more per ticket
  double get fameTicketPriceMultiplier {
    if (fame < 10) return 1.0; // $10 base
    if (fame < 25) return 1.2; // $12
    if (fame < 50) return 1.5; // $15
    if (fame < 75) return 1.8; // $18
    if (fame < 100) return 2.0; // $20
    if (fame < 150) return 2.5; // $25
    if (fame < 200) return 3.0; // $30
    if (fame < 300) return 4.0; // $40
    if (fame < 400) return 5.0; // $50
    if (fame < 500) return 6.0; // $60
    return 8.0; // $80
  }

  /// Unlock collaboration opportunities based on fame
  bool get canCollaborateWithLocalArtists => fame >= 25;
  bool get canCollaborateWithNPCs => fame >= 50;
  bool get canCollaborateWithStars => fame >= 100;
  bool get canCollaborateWithLegends => fame >= 200;

  /// Record label interest tier
  String get recordLabelInterest {
    if (fame < 50) return "None";
    if (fame < 100) return "Indie Labels Watching";
    if (fame < 150) return "Small Label Interest";
    if (fame < 200) return "Major Label Scouting";
    if (fame < 300) return "Multiple Offers";
    if (fame < 400) return "Bidding War";
    return "Dream Contract Available";
  }

  /// Check if record labels are interested
  bool get hasRecordLabelInterest => fame >= 50;

  /// Unlock features based on fame
  bool get canTourInternationally => fame >= 75;
  bool get canAccessPremiumStudios => fame >= 100;
  bool get canHostConcertTour => fame >= 150;
  bool get canReleaseDeluxeEditions => fame >= 125;
  bool get canCreateMerchandise => fame >= 175;
  bool get canStreamOnAllPlatforms => fame >= 50;

  /// Regional unlock based on fame (expands market reach)
  List<String> get unlockedRegions {
    List<String> regions = ['usa']; // Everyone starts in USA

    if (fame >= 25) regions.add('uk');
    if (fame >= 50) regions.add('europe');
    if (fame >= 75) regions.add('latin_america');
    if (fame >= 100) regions.add('asia');
    if (fame >= 150) regions.add('africa');
    if (fame >= 200) regions.add('oceania');

    return regions;
  }

  /// Get fame tier name for UI display
  String get fameTier {
    if (fame < 10) return "Unknown";
    if (fame < 25) return "Local Scene";
    if (fame < 50) return "City Famous";
    if (fame < 100) return "Regional Star";
    if (fame < 150) return "National Celebrity";
    if (fame < 200) return "Chart Topper";
    if (fame < 300) return "International Star";
    if (fame < 400) return "Global Icon";
    if (fame < 500) return "Living Legend";
    return "Hall of Fame";
  }

  // Calculate song quality based on player skills and genre
  double calculateSongQuality(String genre, int effortLevel) {
    // Base quality from skills
    double baseQuality =
        (songwritingSkill + lyricsSkill + compositionSkill) / 3.0;

    // 🎸 GENRE MASTERY BONUS - Higher mastery = Better quality!
    // 0% mastery = 1.0x (no bonus)
    // 50% mastery = 1.15x (+15% quality)
    // 100% mastery = 1.3x (+30% quality boost!)
    int genreMasteryLevel = genreMastery[genre] ?? 0;
    double masteryBonus = 1.0 + (genreMasteryLevel / 100.0 * 0.3);

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

    // Calculate final quality (0-100) with mastery bonus!
    double quality = baseQuality *
        genreMultiplier *
        effortMultiplier *
        inspirationFactor *
        experienceBonus *
        masteryBonus; // 🎸 Mastery multiplier added!

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

  // Calculate genre mastery gain from writing a song
  // Returns the amount to add to that genre's mastery (0-100 scale)
  int calculateGenreMasteryGain(
      String genre, int effortLevel, double songQuality) {
    // Base gain from effort (1-4 effort = 5-20 base points)
    int baseGain = effortLevel * 5;

    // Quality bonus (0-15 points based on song quality)
    int qualityBonus = (songQuality / 100 * 15).round();

    // Total gain (clamped to 5-35 range to prevent too fast progression)
    int totalGain = (baseGain + qualityBonus).clamp(5, 35);

    return totalGain;
  }

  // Apply mastery gain to the genre mastery map
  // Returns updated genreMastery map with the gain applied (capped at 100)
  Map<String, int> applyGenreMasteryGain(String genre, int masteryGain) {
    Map<String, int> updatedMastery = Map.from(genreMastery);
    int currentMastery = updatedMastery[genre] ?? 0;
    int newMastery = (currentMastery + masteryGain).clamp(0, 100);
    updatedMastery[genre] = newMastery;
    return updatedMastery;
  }

  // Get mastery level description
  String getGenreMasteryLevel(String genre) {
    int mastery = genreMastery[genre] ?? 0;
    if (mastery >= 90) return "Master";
    if (mastery >= 80) return "Expert";
    if (mastery >= 70) return "Advanced";
    if (mastery >= 60) return "Proficient";
    if (mastery >= 50) return "Skilled";
    if (mastery >= 40) return "Competent";
    if (mastery >= 30) return "Intermediate";
    if (mastery >= 20) return "Learning";
    if (mastery >= 10) return "Novice";
    return "Beginner";
  }
}
