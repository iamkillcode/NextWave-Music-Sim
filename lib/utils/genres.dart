import 'package:flutter/material.dart';

class Genres {
  // Canonical list of supported genres used across the app
  static const List<String> all = <String>[
    'R&B',
    'Hip Hop',
    'Rap',
    'Pop',
    'Trap',
    'Drill',
    'Afrobeat',
    'Country',
    'Jazz',
    'Reggae',
    'Gospel',
  ];

  // Returns the canonical genre name matching the input (case-insensitive),
  // or the first canonical genre if no match is found.
  static String toCanonical(String input) {
    if (input.isEmpty) return all.first;
    final lower = input.toLowerCase();
    return all.firstWhere(
      (g) => g.toLowerCase() == lower,
      orElse: () => all.first,
    );
  }

  // Returns a themed icon widget for each genre
  static Widget getIcon(String genre, {double size = 16}) {
    switch (genre) {
      case 'R&B':
        return Icon(Icons.favorite, color: const Color(0xFFFF6B9D), size: size);
      case 'Hip Hop':
        return Icon(Icons.mic, color: const Color(0xFFFFD700), size: size);
      case 'Rap':
        return Icon(Icons.record_voice_over, color: const Color(0xFF00D9FF), size: size);
      case 'Trap':
        return Icon(Icons.graphic_eq, color: const Color(0xFF9B59B6), size: size);
      case 'Drill':
        return Icon(Icons.surround_sound, color: const Color(0xFFFF4500), size: size);
      case 'Afrobeat':
        return Icon(Icons.celebration, color: const Color(0xFFF39C12), size: size);
      case 'Country':
        return Icon(Icons.landscape, color: const Color(0xFF8B4513), size: size);
      case 'Jazz':
        return Icon(Icons.piano, color: const Color(0xFF4169E1), size: size);
      case 'Reggae':
        return Icon(Icons.waves, color: const Color(0xFF32CD32), size: size);
      case 'Pop':
        return Icon(Icons.star, color: const Color(0xFFFF69B4), size: size);
      case 'Gospel':
        return Icon(Icons.self_improvement, color: const Color.fromARGB(255, 15, 207, 233), size: size);
      default:
        return Icon(Icons.music_note, color: Colors.white, size: size);
    }
  }
}
