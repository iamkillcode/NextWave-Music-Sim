class StreamingPlatform {
  final String id;
  final String name;
  final String color; // Hex color code
  final String emoji;
  final double royaltiesPerStream; // In dollars
  final int popularity; // 1-100 scale
  final String description;

  const StreamingPlatform({
    required this.id,
    required this.name,
    required this.color,
    required this.emoji,
    required this.royaltiesPerStream,
    required this.popularity,
    required this.description,
  });

  static const tunify = StreamingPlatform(
    id: 'tunify',
    name: 'Tunify',
    color: '#1DB954', // Green like Spotify
    emoji: '🎵',
    royaltiesPerStream: 0.003, // $0.003 per stream
    popularity: 85,
    description: 'Most popular streaming platform globally with massive reach',
  );

  static const mapleMusic = StreamingPlatform(
    id: 'maple_music',
    name: 'Maple Music',
    color: '#FC3C44', // Red like Apple Music
    emoji: '🍎',
    royaltiesPerStream: 0.01, // $0.01 per stream (higher payout)
    popularity: 65,
    description: 'Premium platform with higher royalties but smaller audience',
  );

  static List<StreamingPlatform> get all => [tunify, mapleMusic];

  static StreamingPlatform getById(String id) {
    return all.firstWhere((platform) => platform.id == id, orElse: () => tunify);
  }

  int getColorValue() {
    return int.parse(color.substring(1), radix: 16) + 0xFF000000;
  }
}
