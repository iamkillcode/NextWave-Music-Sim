import 'dart:math';

/// Service for generating creative song titles
class SongNameGenerator {
  static final Random _random = Random();

  // Genre-specific word banks
  static const Map<String, List<String>> _genreWords = {
    'Hip Hop': [
      'Street', 'Dreams', 'Hustle', 'Crown', 'Rise', 'Legacy', 'Cipher', 'Boom',
      'Flow', 'Bars', 'Gold', 'Chains', 'Ice', 'Grind', 'Real', 'Truth'
    ],
    'R&B': [
      'Love', 'Heart', 'Soul', 'Tonight', 'Forever', 'Desire', 'Feeling', 'Touch',
      'Sweet', 'Baby', 'Angel', 'Heaven', 'Dream', 'Passion', 'Emotion', 'Vibe'
    ],
    'Rap': [
      'Money', 'Power', 'Game', 'Boss', 'King', 'Legend', 'Trap', 'Hood',
      'Flex', 'Drip', 'Stack', 'Pressure', 'Move', 'Wave', 'Fire', 'Beast'
    ],
    'Trap': [
      'Bands', 'Drip', 'Sauce', 'Flex', 'Bag', 'Run', 'Chase', 'Vibe',
      'Lit', 'Fire', 'Mood', 'Energy', 'Wave', 'Bounce', 'Pop', 'Lock'
    ],
    'Drill': [
      'Block', 'Slide', 'Smoke', 'Opp', 'Gang', 'War', 'Pain', 'Cold',
      'Dark', 'Night', 'Street', 'Zone', 'Ride', 'Mask', 'Ghost', 'Storm'
    ],
    'Afrobeat': [
      'African', 'Lagos', 'Rhythm', 'Dance', 'Celebrate', 'Joy', 'Life', 'Sun',
      'Ocean', 'Spirit', 'Melody', 'Groove', 'Move', 'Party', 'Freedom', 'Pride'
    ],
    'Country': [
      'Road', 'Home', 'Whiskey', 'Truck', 'Boots', 'Ranch', 'Sunset', 'Sky',
      'Heart', 'Dust', 'River', 'Mountain', 'Wild', 'Free', 'Country', 'Soul'
    ],
    'Jazz': [
      'Blue', 'Night', 'Smooth', 'Satin', 'Velvet', 'Cool', 'Swing', 'Soul',
      'Midnight', 'Moon', 'Cafe', 'City', 'Rain', 'Dream', 'Melancholy', 'Suite'
    ],
    'Reggae': [
      'Island', 'Peace', 'Unity', 'Jah', 'Roots', 'Rise', 'Sun', 'One',
      'Love', 'Tribe', 'Vibration', 'Freedom', 'Natural', 'Mystic', 'Irie', 'Zion'
    ],
  };

  // Connecting words and articles
  static const List<String> _connectors = [
    'of', 'in', 'on', 'the', 'to', 'from', 'with', 'without', 'for', 'by',
    'and', '&', 'or', 'like', 'after', 'before', 'into', 'through'
  ];

  // Common song title patterns
  static const List<String> _patterns = [
    'emotion', // e.g., "Love"
    'emotion + noun', // e.g., "Love Dreams"
    'noun + noun', // e.g., "Street Dreams"
    'adjective + noun', // e.g., "Dark Streets"
    'noun + connector + noun', // e.g., "Dreams of Fire"
    'emotion + connector + the + noun', // e.g., "Love in the Night"
    'number + noun', // e.g., "24 Hours"
  ];

  // Quality-based adjectives
  static const Map<String, List<String>> _qualityAdjectives = {
    'excellent': ['Perfect', 'Supreme', 'Ultimate', 'Elite', 'Legendary'],
    'good': ['Pure', 'True', 'Real', 'Golden', 'Classic'],
    'average': ['Late', 'Early', 'Young', 'Old', 'Lost'],
    'poor': ['Broken', 'Fading', 'Last', 'Empty', 'Lonely'],
  };

  /// Generate a random song title based on genre
  static String generateTitle(String genre, {int? quality}) {
    final words = _genreWords[genre] ?? _genreWords['Hip Hop']!;
    final pattern = _patterns[_random.nextInt(_patterns.length)];

    String title = '';

    switch (pattern) {
      case 'emotion':
        title = words[_random.nextInt(words.length)];
        break;

      case 'emotion + noun':
        final word1 = words[_random.nextInt(words.length)];
        final word2 = words[_random.nextInt(words.length)];
        title = '$word1 $word2';
        break;

      case 'noun + noun':
        final word1 = words[_random.nextInt(words.length)];
        final word2 = words[_random.nextInt(words.length)];
        title = '$word1 $word2';
        break;

      case 'adjective + noun':
        final adjectives = _getQualityAdjectives(quality);
        final adj = adjectives[_random.nextInt(adjectives.length)];
        final noun = words[_random.nextInt(words.length)];
        title = '$adj $noun';
        break;

      case 'noun + connector + noun':
        final word1 = words[_random.nextInt(words.length)];
        final connector = _connectors[_random.nextInt(_connectors.length)];
        final word2 = words[_random.nextInt(words.length)];
        title = '$word1 $connector $word2';
        break;

      case 'emotion + connector + the + noun':
        final word1 = words[_random.nextInt(words.length)];
        final connector = _connectors[_random.nextInt(_connectors.length)];
        final word2 = words[_random.nextInt(words.length)];
        title = '$word1 $connector the $word2';
        break;

      case 'number + noun':
        final number = [24, 100, 365, 7, 3, 2, 1, 99][_random.nextInt(8)];
        final noun = words[_random.nextInt(words.length)];
        title = '$number $noun';
        break;
    }

    return title;
  }

  /// Get suggestions for song titles
  static List<String> getSuggestions(String genre, {int count = 5, int? quality}) {
    final suggestions = <String>{};
    
    while (suggestions.length < count) {
      suggestions.add(generateTitle(genre, quality: quality));
    }
    
    return suggestions.toList();
  }

  /// Get quality-based adjectives
  static List<String> _getQualityAdjectives(int? quality) {
    if (quality == null) return _qualityAdjectives['good']!;
    
    if (quality >= 80) return _qualityAdjectives['excellent']!;
    if (quality >= 60) return _qualityAdjectives['good']!;
    if (quality >= 40) return _qualityAdjectives['average']!;
    return _qualityAdjectives['poor']!;
  }

  /// Validate custom title
  static bool isValidTitle(String title) {
    final trimmed = title.trim();
    return trimmed.isNotEmpty && 
           trimmed.length >= 1 && 
           trimmed.length <= 50;
  }

  /// Generate title from first letters (acronym style)
  static String generateAcronymTitle(String genre) {
    final words = _genreWords[genre] ?? _genreWords['Hip Hop']!;
    final numWords = 2 + _random.nextInt(3); // 2-4 words
    
    final selectedWords = <String>[];
    for (var i = 0; i < numWords; i++) {
      selectedWords.add(words[_random.nextInt(words.length)]);
    }
    
    return selectedWords.map((w) => w[0]).join('') + 
           ' (${selectedWords.join(' ')})';
  }
}
