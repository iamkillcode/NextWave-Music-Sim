
class WorldRegion {
  final String id;
  final String name;
  final String flag;
  final String description;
  final List<String> popularGenres;
  final double marketSize;
  final double avgIncomeLevel;
  final String timezone;
  final Map<String, double> genrePopularity;

  const WorldRegion({
    required this.id,
    required this.name,
    required this.flag,
    required this.description,
    required this.popularGenres,
    required this.marketSize,
    required this.avgIncomeLevel,
    required this.timezone,
    required this.genrePopularity,
  });

  double getStreamingPotential(String genre) {
    final genrePop = genrePopularity[genre.toLowerCase()] ?? 0.5;
    return marketSize * avgIncomeLevel * genrePop;
  }

  double getRegionalMultiplier(String genre) {
    return genrePopularity[genre.toLowerCase()] ?? 0.5;
  }

  double get costOfLivingMultiplier {
    switch (id) {
      case 'usa': return 1.2;
      case 'europe': return 1.1;
      case 'uk': return 1.15;
      case 'asia': return 0.8;
      case 'africa': return 0.6;
      case 'latin_america': return 0.7;
      case 'oceania': return 1.05;
      default: return 1.0;
    }
  }

  static List<WorldRegion> getAllRegions() {
    return [
      WorldRegion(
        id: 'usa',
        name: 'United States',
        flag: '🇺🇸',
        description: 'The birthplace of modern music industry.',
        popularGenres: ['Hip Hop', 'Rap', 'Country', 'R&B'],
        marketSize: 1.0,
        avgIncomeLevel: 1.0,
        timezone: 'PST/EST',
        genrePopularity: {
          'hip hop': 0.95,
          'rap': 0.9,
          'r&b': 0.85,
          'country': 0.8,
          'trap': 0.75,
          'drill': 0.7,
          'afrobeat': 0.6,
          'jazz': 0.65,
          'reggae': 0.55,
        },
      ),
      WorldRegion(
        id: 'uk',
        name: 'United Kingdom',
        flag: '🇬🇧',
        description: 'Home of The Beatles and grime music.',
        popularGenres: ['Hip Hop', 'Drill', 'Jazz', 'R&B'],
        marketSize: 0.7,
        avgIncomeLevel: 1.05,
        timezone: 'GMT',
        genrePopularity: {
          'drill': 0.95,
          'hip hop': 0.85,
          'jazz': 0.8,
          'r&b': 0.75,
          'rap': 0.7,
          'reggae': 0.65,
          'trap': 0.6,
          'afrobeat': 0.85,
          'country': 0.3,
        },
      ),
      WorldRegion(
        id: 'africa',
        name: 'Africa',
        flag: '🌍',
        description: 'The cradle of rhythm and Afrobeat.',
        popularGenres: ['Afrobeat', 'Hip Hop', 'R&B', 'Reggae'],
        marketSize: 0.8,
        avgIncomeLevel: 0.5,
        timezone: 'CAT/WAT',
        genrePopularity: {
          'afrobeat': 1.0,
          'hip hop': 0.85,
          'r&b': 0.8,
          'reggae': 0.75,
          'rap': 0.7,
          'trap': 0.65,
          'drill': 0.6,
          'jazz': 0.55,
          'country': 0.2,
        },
      ),
      WorldRegion(
        id: 'europe',
        name: 'Europe',
        flag: '🇪🇺',
        description: 'Diverse music scene from Berlin techno to Paris hip-hop.',
        popularGenres: ['Hip Hop', 'Jazz', 'R&B', 'Trap'],
        marketSize: 0.85,
        avgIncomeLevel: 1.1,
        timezone: 'CET',
        genrePopularity: {
          'hip hop': 0.9,
          'jazz': 0.85,
          'r&b': 0.8,
          'trap': 0.75,
          'drill': 0.7,
          'rap': 0.85,
          'afrobeat': 0.7,
          'reggae': 0.65,
          'country': 0.35,
        },
      ),
      WorldRegion(
        id: 'asia',
        name: 'Asia',
        flag: '🌏',
        description: 'Massive markets from Tokyo to Mumbai.',
        popularGenres: ['Hip Hop', 'R&B', 'Trap', 'Jazz'],
        marketSize: 1.2,
        avgIncomeLevel: 0.8,
        timezone: 'JST/KST',
        genrePopularity: {
          'hip hop': 0.9,
          'r&b': 0.85,
          'trap': 0.8,
          'jazz': 0.75,
          'rap': 0.8,
          'drill': 0.65,
          'afrobeat': 0.55,
          'reggae': 0.5,
          'country': 0.25,
        },
      ),
    ];
  }
}
