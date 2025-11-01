import 'dart:math';
import 'package:flutter/material.dart';

/// Service for evaluating sound mixing quality based on genre-specific ideal mixes
/// Each genre has an optimal balance of Bass, Mids, Treble, Vocals, and Effects
class SoundMixingService {
  /// Ideal mixing profiles for each genre
  /// Format: {bass, mids, treble, vocals, effects, description}
  static const Map<String, Map<String, dynamic>> _idealMixes = {
    // Hip Hop & Rap
    'Hip Hop': {
      'bass': 80.0,
      'mids': 60.0,
      'treble': 50.0,
      'vocals': 75.0,
      'effects': 70.0,
      'description': 'Heavy bass, prominent vocals, moderate effects for punch',
    },
    'Rap': {
      'bass': 75.0,
      'mids': 65.0,
      'treble': 55.0,
      'vocals': 80.0,
      'effects': 65.0,
      'description': 'Clear vocals, strong bass, crisp mids for lyric clarity',
    },
    'Trap': {
      'bass': 85.0,
      'mids': 55.0,
      'treble': 60.0,
      'vocals': 70.0,
      'effects': 80.0,
      'description': 'Massive bass, high effects (hi-hats), moderate vocals',
    },
    'Drill': {
      'bass': 80.0,
      'mids': 50.0,
      'treble': 55.0,
      'vocals': 75.0,
      'effects': 75.0,
      'description': 'Dark bass, cutting vocals, heavy effects and reverb',
    },

    // R&B & Soul
    'R&B': {
      'bass': 65.0,
      'mids': 70.0,
      'treble': 65.0,
      'vocals': 80.0,
      'effects': 60.0,
      'description': 'Smooth mids, prominent vocals, warm bass, subtle effects',
    },
    'Soul': {
      'bass': 60.0,
      'mids': 75.0,
      'treble': 60.0,
      'vocals': 85.0,
      'effects': 50.0,
      'description':
          'Rich mids, powerful vocals, organic feel with minimal effects',
    },
    'Neo-Soul': {
      'bass': 65.0,
      'mids': 70.0,
      'treble': 60.0,
      'vocals': 80.0,
      'effects': 65.0,
      'description':
          'Warm bass, smooth mids, expressive vocals, tasteful effects',
    },

    // Gospel
    'Gospel': {
      'bass': 60.0,
      'mids': 80.0,
      'treble': 65.0,
      'vocals': 90.0,
      'effects': 60.0,
      'description':
          'Powerful lead vocals and choir, prominent mids for organ/piano, reverberant space',
    },

    // Electronic & Dance
    'Electronic': {
      'bass': 75.0,
      'mids': 60.0,
      'treble': 70.0,
      'vocals': 55.0,
      'effects': 85.0,
      'description':
          'Punchy bass, bright treble, heavy effects, vocals as texture',
    },
    'House': {
      'bass': 80.0,
      'mids': 65.0,
      'treble': 70.0,
      'vocals': 60.0,
      'effects': 75.0,
      'description': 'Driving bass, energetic treble, effects for atmosphere',
    },
    'Techno': {
      'bass': 85.0,
      'mids': 55.0,
      'treble': 75.0,
      'vocals': 40.0,
      'effects': 80.0,
      'description': 'Relentless bass, minimal vocals, hypnotic effects',
    },

    // Pop & Mainstream
    'Pop': {
      'bass': 65.0,
      'mids': 70.0,
      'treble': 75.0,
      'vocals': 80.0,
      'effects': 70.0,
      'description': 'Balanced mix, crystal vocals, polished with effects',
    },
    'Pop Rap': {
      'bass': 70.0,
      'mids': 65.0,
      'treble': 70.0,
      'vocals': 75.0,
      'effects': 75.0,
      'description': 'Catchy bass, clear vocals, mainstream polish',
    },

    // Rock & Alternative
    'Rock': {
      'bass': 70.0,
      'mids': 80.0,
      'treble': 70.0,
      'vocals': 70.0,
      'effects': 55.0,
      'description': 'Powerful mids (guitars), balanced vocals, organic sound',
    },
    'Alternative': {
      'bass': 65.0,
      'mids': 75.0,
      'treble': 70.0,
      'vocals': 75.0,
      'effects': 65.0,
      'description': 'Textured mids, expressive vocals, creative effects',
    },

    // Jazz & Blues
    'Jazz': {
      'bass': 60.0,
      'mids': 75.0,
      'treble': 70.0,
      'vocals': 70.0,
      'effects': 45.0,
      'description':
          'Rich mids, natural treble, minimal effects for authenticity',
    },
    'Blues': {
      'bass': 65.0,
      'mids': 80.0,
      'treble': 65.0,
      'vocals': 75.0,
      'effects': 40.0,
      'description': 'Warm mids, soulful vocals, raw and unprocessed',
    },

    // Latin & World
    'Reggaeton': {
      'bass': 80.0,
      'mids': 60.0,
      'treble': 65.0,
      'vocals': 75.0,
      'effects': 70.0,
      'description': 'Dembow bass, clear vocals, percussive effects',
    },
    'Reggae': {
      'bass': 75.0,
      'mids': 65.0,
      'treble': 55.0,
      'vocals': 70.0,
      'effects': 60.0,
      'description': 'Deep bass, laid-back mids, smooth vocals, dub effects',
    },
    'Afrobeat': {
      'bass': 70.0,
      'mids': 70.0,
      'treble': 65.0,
      'vocals': 75.0,
      'effects': 65.0,
      'description': 'Rhythmic bass, vibrant mids, energetic vocals',
    },
    'Latin': {
      'bass': 70.0,
      'mids': 70.0,
      'treble': 70.0,
      'vocals': 75.0,
      'effects': 60.0,
      'description': 'Balanced energy, passionate vocals, percussion forward',
    },

    // Country & Folk
    'Country': {
      'bass': 55.0,
      'mids': 75.0,
      'treble': 65.0,
      'vocals': 80.0,
      'effects': 50.0,
      'description':
          'Clean vocals, acoustic mids, natural treble, minimal effects',
    },
    'Folk': {
      'bass': 50.0,
      'mids': 70.0,
      'treble': 60.0,
      'vocals': 80.0,
      'effects': 40.0,
      'description': 'Intimate vocals, warm mids, organic and unprocessed',
    },

    // Metal & Heavy
    'Metal': {
      'bass': 75.0,
      'mids': 85.0,
      'treble': 75.0,
      'vocals': 65.0,
      'effects': 60.0,
      'description':
          'Aggressive mids, crushing bass, powerful treble, raw vocals',
    },

    // Experimental & Ambient
    'Experimental': {
      'bass': 60.0,
      'mids': 65.0,
      'treble': 65.0,
      'vocals': 60.0,
      'effects': 80.0,
      'description': 'Creative freedom, heavy effects, unconventional balance',
    },
    'Ambient': {
      'bass': 55.0,
      'mids': 60.0,
      'treble': 70.0,
      'vocals': 50.0,
      'effects': 85.0,
      'description': 'Atmospheric effects, soft bass, ethereal vocals',
    },

    // Indie
    'Indie': {
      'bass': 60.0,
      'mids': 70.0,
      'treble': 70.0,
      'vocals': 75.0,
      'effects': 65.0,
      'description': 'Lo-fi charm, expressive vocals, creative effects',
    },
  };

  /// Get ideal mix for a specific genre
  Map<String, dynamic> getIdealMix(String genre) {
    return _idealMixes[genre] ??
        {
          'bass': 65.0,
          'mids': 65.0,
          'treble': 65.0,
          'vocals': 70.0,
          'effects': 60.0,
          'description': 'Balanced mix for general music',
        };
  }

  /// Evaluate current mix against ideal mix for the genre
  /// Returns score (0-100), feedback text, and color
  Map<String, dynamic> evaluateMix({
    required String genre,
    required double bass,
    required double mids,
    required double treble,
    required double vocals,
    required double effects,
  }) {
    final ideal = getIdealMix(genre);

    // Calculate deviation from ideal for each parameter
    final bassDeviation = (bass - ideal['bass']).abs();
    final midsDeviation = (mids - ideal['mids']).abs();
    final trebleDeviation = (treble - ideal['treble']).abs();
    final vocalsDeviation = (vocals - ideal['vocals']).abs();
    final effectsDeviation = (effects - ideal['effects']).abs();

    // Weighted importance (vocals and genre-specific elements matter most)
    final totalDeviation = (bassDeviation * 1.2) +
        (midsDeviation * 1.1) +
        (trebleDeviation * 1.0) +
        (vocalsDeviation * 1.3) +
        (effectsDeviation * 1.0);

    // Convert deviation to score (lower deviation = higher score)
    // Maximum possible deviation: ~520 (all parameters 100 points off)
    // We want: 0 deviation = 100 score, max deviation = 0 score
    final score = (100 - (totalDeviation / 5.2)).clamp(0, 100).round();

    // Generate feedback based on score
    String feedback;
    Color color;

    if (score >= 95) {
      feedback = '🎉 Perfect Mix! Genre mastery achieved!';
      color = const Color(0xFF00FF00);
    } else if (score >= 85) {
      feedback = '✨ Excellent! Studio quality mix!';
      color = const Color(0xFF32D74B);
    } else if (score >= 75) {
      feedback = '👍 Great mix! Very close to ideal!';
      color = const Color(0xFF32D74B);
    } else if (score >= 65) {
      feedback = '👌 Good mix! Minor adjustments needed.';
      color = const Color(0xFFFFD60A);
    } else if (score >= 50) {
      feedback = '🤔 Decent mix. Could use more work.';
      color = const Color(0xFFFF9500);
    } else if (score >= 35) {
      feedback = '😬 Needs improvement. Check the genre hint!';
      color = const Color(0xFFFF9500);
    } else {
      feedback = '❌ Poor mix. Study the genre characteristics!';
      color = const Color(0xFFFF3B30);
    }

    return {
      'score': score,
      'feedback': feedback,
      'color': color,
    };
  }

  /// Calculate quality bonus/penalty based on mixing score
  /// Perfect mix (+15%), Excellent (+10%), Great (+5%), Good (0%), Poor (-5% to -15%)
  int calculateQualityBonus(int score) {
    if (score >= 95) return 15; // Perfect
    if (score >= 85) return 10; // Excellent
    if (score >= 75) return 5; // Great
    if (score >= 60) return 0; // Good (no change)
    if (score >= 45) return -5; // Needs work
    if (score >= 30) return -10; // Poor
    return -15; // Very bad
  }

  /// Get a randomized starting mix (40-60% for challenge)
  Map<String, double> getRandomStartingMix() {
    final random = Random();
    return {
      'bass': 40 + random.nextDouble() * 20,
      'mids': 40 + random.nextDouble() * 20,
      'treble': 40 + random.nextDouble() * 20,
      'vocals': 40 + random.nextDouble() * 20,
      'effects': 40 + random.nextDouble() * 20,
    };
  }

  /// Get all genre names that have ideal mixes
  List<String> getAllGenres() {
    return _idealMixes.keys.toList()..sort();
  }

  /// Get difficulty rating for a genre (how precise the mix needs to be)
  String getGenreDifficulty(String genre) {
    final ideal = getIdealMix(genre);

    // Count how many extreme values (>80 or <50)
    int extremes = 0;
    for (var key in ['bass', 'mids', 'treble', 'vocals', 'effects']) {
      final value = ideal[key] as double;
      if (value > 80 || value < 50) extremes++;
    }

    if (extremes >= 4) return 'Expert';
    if (extremes >= 3) return 'Hard';
    if (extremes >= 2) return 'Medium';
    return 'Easy';
  }
}
