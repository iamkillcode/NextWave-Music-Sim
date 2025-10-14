import 'package:flutter/material.dart';
import 'artist_stats.dart';
import 'song.dart';

enum StudioTier {
  legendary,
  professional,
  premium,
  standard,
  budget,
}

enum StudioAttitude {
  welcoming,    // Eager to work with you
  friendly,     // Happy to have you
  neutral,      // Professional but distant
  skeptical,    // Unsure about you
  dismissive,   // Don't think you're ready
  closed,       // Won't work with you
}

class StudioRequirements {
  final int minFame;
  final int minAlbums;
  final int minSongsReleased;
  final bool requiresLabelDeal;
  final int minReputation; // Studio-specific reputation (0-100)

  const StudioRequirements({
    this.minFame = 0,
    this.minAlbums = 0,
    this.minSongsReleased = 0,
    this.requiresLabelDeal = false,
    this.minReputation = 0,
  });
}

class Studio {
  final String id;
  final String name;
  final String location;
  final StudioTier tier;
  final int basePrice;
  final int qualityRating;
  final int reputation;
  final List<String> specialties;
  final bool hasProducer;
  final int producerFee;
  final int producerSkill;
  final String description;
  final StudioRequirements requirements;
  final String exclusiveNote; // What makes this studio special/exclusive

  const Studio({
    required this.id,
    required this.name,
    required this.location,
    required this.tier,
    required this.basePrice,
    required this.qualityRating,
    required this.reputation,
    required this.specialties,
    required this.hasProducer,
    required this.producerFee,
    required this.producerSkill,
    required this.description,
    this.requirements = const StudioRequirements(),
    this.exclusiveNote = '',
  });

  int getTotalCost(bool useProducer, double regionMultiplier) {
    int cost = (basePrice * regionMultiplier).round();
    if (useProducer && hasProducer) {
      cost += (producerFee * regionMultiplier).round();
    }
    return cost;
  }

  double getQualityBonus(String genre, bool useProducer) {
    double bonus = qualityRating / 100.0;
    
    if (specialties.any((s) => s.toLowerCase() == genre.toLowerCase())) {
      bonus += 0.15;
    }
    
    bonus += (reputation / 100.0) * 0.1;
    
    if (useProducer && hasProducer) {
      bonus += (producerSkill / 100.0) * 0.2;
    }
    
    return bonus.clamp(0.0, 1.0);
  }

  // Check if player meets requirements to access studio
  bool meetsRequirements(ArtistStats stats) {
    if (stats.fame < requirements.minFame) return false;
    if (stats.albumsSold < requirements.minAlbums) return false;
    final releasedSongs = stats.songs.where((s) => s.state == SongState.released).length;
    if (releasedSongs < requirements.minSongsReleased) return false;
    // TODO: Add label deal check when labels are implemented
    return true;
  }

  // Get studio's attitude toward player
  StudioAttitude getAttitude(ArtistStats stats) {
    // Budget studios are always welcoming
    if (tier == StudioTier.budget) return StudioAttitude.welcoming;

    final releasedSongs = stats.songs.where((s) => s.state == SongState.released).length;
    
    // Calculate how well player matches studio expectations
    final fameRatio = requirements.minFame > 0 ? stats.fame / requirements.minFame : stats.fame / 10.0;
    final albumRatio = requirements.minAlbums > 0 ? stats.albumsSold / requirements.minAlbums : stats.albumsSold + 1.0;
    final songRatio = requirements.minSongsReleased > 0 ? releasedSongs / requirements.minSongsReleased : releasedSongs + 1.0;
    
    // Genre match bonus
    final genreMatch = stats.songs.any((s) => specialties.contains(s.genre));
    final genreBonus = genreMatch ? 0.3 : 0.0;
    
    // Quality of work (average song quality)
    final avgQuality = stats.songs.isNotEmpty 
        ? stats.songs.map((s) => s.finalQuality).reduce((a, b) => a + b) / stats.songs.length 
        : 50;
    final qualityBonus = (avgQuality - 50) / 100.0; // -0.5 to +0.5
    
    // Overall score
    final score = (fameRatio + albumRatio + songRatio) / 3.0 + genreBonus + qualityBonus;
    
    // Doesn't meet basic requirements
    if (!meetsRequirements(stats)) {
      return score < 0.3 ? StudioAttitude.closed : StudioAttitude.dismissive;
    }
    
    // Determine attitude based on score
    if (score >= 2.0) return StudioAttitude.welcoming;
    if (score >= 1.5) return StudioAttitude.friendly;
    if (score >= 1.0) return StudioAttitude.neutral;
    if (score >= 0.7) return StudioAttitude.skeptical;
    return StudioAttitude.dismissive;
  }

  // Get attitude description
  String getAttitudeDescription(StudioAttitude attitude) {
    switch (attitude) {
      case StudioAttitude.welcoming:
        return "🌟 They're excited to work with you!";
      case StudioAttitude.friendly:
        return "😊 They're happy to have you here.";
      case StudioAttitude.neutral:
        return "😐 Professional but not particularly impressed.";
      case StudioAttitude.skeptical:
        return "🤨 They're unsure if you're ready for this level.";
      case StudioAttitude.dismissive:
        return "😒 They don't think you belong here yet.";
      case StudioAttitude.closed:
        return "🚫 They won't work with you. Build your reputation first.";
    }
  }

  // Get attitude color
  Color getAttitudeColor(StudioAttitude attitude) {
    switch (attitude) {
      case StudioAttitude.welcoming:
        return const Color(0xFF32D74B); // Green
      case StudioAttitude.friendly:
        return const Color(0xFF00D9FF); // Cyan
      case StudioAttitude.neutral:
        return const Color(0xFF8E8E93); // Gray
      case StudioAttitude.skeptical:
        return const Color(0xFFF39C12); // Orange
      case StudioAttitude.dismissive:
        return const Color(0xFFFF6B9D); // Pink
      case StudioAttitude.closed:
        return const Color(0xFFFF3B30); // Red
    }
  }

  // Apply attitude bonus/penalty to price
  int getAdjustedPrice(bool useProducer, double regionMultiplier, StudioAttitude attitude) {
    int baseCost = getTotalCost(useProducer, regionMultiplier);
    
    switch (attitude) {
      case StudioAttitude.welcoming:
        return (baseCost * 0.9).round(); // 10% discount
      case StudioAttitude.friendly:
        return (baseCost * 0.95).round(); // 5% discount
      case StudioAttitude.neutral:
        return baseCost; // Standard price
      case StudioAttitude.skeptical:
        return (baseCost * 1.1).round(); // 10% markup
      case StudioAttitude.dismissive:
        return (baseCost * 1.25).round(); // 25% markup
      case StudioAttitude.closed:
        return baseCost * 10; // Ridiculously expensive (effectively closed)
    }
  }

  // Apply attitude bonus/penalty to quality
  double getAttitudeQualityModifier(StudioAttitude attitude) {
    switch (attitude) {
      case StudioAttitude.welcoming:
        return 1.15; // 15% bonus - they give extra effort
      case StudioAttitude.friendly:
        return 1.08; // 8% bonus
      case StudioAttitude.neutral:
        return 1.0; // No modifier
      case StudioAttitude.skeptical:
        return 0.95; // 5% penalty - not their best work
      case StudioAttitude.dismissive:
        return 0.85; // 15% penalty - half-hearted effort
      case StudioAttitude.closed:
        return 0.5; // 50% penalty (shouldn't happen)
    }
  }

  // Check if studio has connection benefits (legendary/professional only)
  bool hasConnectionBenefits() {
    return tier == StudioTier.legendary || tier == StudioTier.professional;
  }

  // Get connection benefit description
  String getConnectionBenefit() {
    if (!hasConnectionBenefits()) return '';
    
    switch (tier) {
      case StudioTier.legendary:
        return '+5% chance for song to go viral, +50 bonus fans';
      case StudioTier.professional:
        return '+2% chance for song to go viral, +20 bonus fans';
      default:
        return '';
    }
  }

  int getFameBonus() {
    switch (tier) {
      case StudioTier.legendary:
        return 25;
      case StudioTier.professional:
        return 15;
      case StudioTier.premium:
        return 10;
      case StudioTier.standard:
        return 5;
      case StudioTier.budget:
        return 2;
    }
  }

  Color getTierColor() {
    switch (tier) {
      case StudioTier.legendary:
        return const Color(0xFFFFD700);
      case StudioTier.professional:
        return const Color(0xFF9B59B6);
      case StudioTier.premium:
        return const Color(0xFF00D9FF);
      case StudioTier.standard:
        return const Color(0xFF32D74B);
      case StudioTier.budget:
        return const Color(0xFF8E8E93);
    }
  }

  String getTierIcon() {
    switch (tier) {
      case StudioTier.legendary:
        return '👑';
      case StudioTier.professional:
        return '⭐';
      case StudioTier.premium:
        return '💎';
      case StudioTier.standard:
        return '🎵';
      case StudioTier.budget:
        return '🎤';
    }
  }

  static List<Studio> getStudiosByRegion(String regionId) {
    switch (regionId) {
      case 'usa':
        return [
          Studio(
            id: 'sunset_sound',
            name: 'Sunset Sound Studios',
            location: 'Los Angeles, CA',
            tier: StudioTier.legendary,
            basePrice: 15000,
            qualityRating: 95,
            reputation: 98,
            specialties: ['Hip Hop', 'R&B', 'Rap'],
            hasProducer: true,
            producerFee: 25000,
            producerSkill: 90,
            description: 'Where legends are made. Used by Drake and Kendrick.',
            requirements: StudioRequirements(
              minFame: 80,
              minAlbums: 2,
              minSongsReleased: 5,
            ),
            exclusiveNote: 'Doors open only to established artists. Your work here defines your legacy.',
          ),
          Studio(
            id: 'record_plant',
            name: 'The Record Plant',
            location: 'Los Angeles, CA',
            tier: StudioTier.legendary,
            basePrice: 14000,
            qualityRating: 93,
            reputation: 97,
            specialties: ['Hip Hop', 'Rap', 'R&B', 'Rock'],
            hasProducer: true,
            producerFee: 22000,
            producerSkill: 92,
            description: 'Historic studio where Tupac and Snoop Dogg recorded.',
            requirements: StudioRequirements(
              minFame: 75,
              minAlbums: 2,
              minSongsReleased: 4,
            ),
            exclusiveNote: 'Follow in the footsteps of hip-hop royalty. Selective about who records here.',
          ),
          Studio(
            id: 'hitsville_usa',
            name: 'Hitsville U.S.A.',
            location: 'Detroit, MI',
            tier: StudioTier.legendary,
            basePrice: 12000,
            qualityRating: 91,
            reputation: 96,
            specialties: ['Hip Hop', 'R&B', 'Rap'],
            hasProducer: true,
            producerFee: 20000,
            producerSkill: 88,
            description: 'Motown legacy meets modern hip-hop production.',
            requirements: StudioRequirements(
              minFame: 70,
              minAlbums: 1,
              minSongsReleased: 4,
            ),
            exclusiveNote: 'Motown\'s hallowed halls. Respect the legacy or don\'t come through.',
          ),
          Studio(
            id: 'atlantic_records',
            name: 'Atlantic Records Studio',
            location: 'New York, NY',
            tier: StudioTier.professional,
            basePrice: 8000,
            qualityRating: 85,
            reputation: 90,
            specialties: ['Hip Hop', 'Rap', 'R&B'],
            hasProducer: true,
            producerFee: 15000,
            producerSkill: 85,
            description: 'Historic label studio with modern equipment.',
            requirements: StudioRequirements(
              minFame: 40,
              minAlbums: 1,
              minSongsReleased: 3,
            ),
            exclusiveNote: 'Major label facility. They want artists with proven track records.',
          ),
          Studio(
            id: 'electric_lady',
            name: 'Electric Lady Studios',
            location: 'New York, NY',
            tier: StudioTier.professional,
            basePrice: 9000,
            qualityRating: 88,
            reputation: 92,
            specialties: ['Hip Hop', 'R&B', 'Jazz', 'Rock'],
            hasProducer: true,
            producerFee: 17000,
            producerSkill: 87,
            description: 'Jimi Hendrix\'s legacy studio in Greenwich Village.',
          ),
          Studio(
            id: 'stankonia',
            name: 'Stankonia Recording',
            location: 'Atlanta, GA',
            tier: StudioTier.professional,
            basePrice: 7500,
            qualityRating: 86,
            reputation: 89,
            specialties: ['Hip Hop', 'Trap', 'R&B', 'Rap'],
            hasProducer: true,
            producerFee: 14000,
            producerSkill: 84,
            description: 'OutKast\'s legendary Atlanta studio.',
          ),
          Studio(
            id: 'patchwerk',
            name: 'Patchwerk Recording',
            location: 'Atlanta, GA',
            tier: StudioTier.premium,
            basePrice: 5500,
            qualityRating: 82,
            reputation: 86,
            specialties: ['Hip Hop', 'Trap', 'R&B'],
            hasProducer: true,
            producerFee: 11000,
            producerSkill: 81,
            description: 'Where the Atlanta trap sound was born.',
          ),
          Studio(
            id: 'bad_boy_studios',
            name: 'Daddy\'s House Recording',
            location: 'New York, NY',
            tier: StudioTier.premium,
            basePrice: 6000,
            qualityRating: 83,
            reputation: 87,
            specialties: ['Hip Hop', 'Rap', 'R&B'],
            hasProducer: true,
            producerFee: 12000,
            producerSkill: 82,
            description: 'Diddy\'s iconic NYC recording complex.',
          ),
          Studio(
            id: 'chicago_drill',
            name: 'Chicago Sound Factory',
            location: 'Chicago, IL',
            tier: StudioTier.standard,
            basePrice: 2500,
            qualityRating: 70,
            reputation: 75,
            specialties: ['Hip Hop', 'Drill', 'R&B'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'Up-and-coming drill and trap studio.',
          ),
          Studio(
            id: 'miami_heat',
            name: 'Hit Factory Criteria',
            location: 'Miami, FL',
            tier: StudioTier.premium,
            basePrice: 5000,
            qualityRating: 80,
            reputation: 84,
            specialties: ['Hip Hop', 'Trap', 'R&B', 'Reggae'],
            hasProducer: true,
            producerFee: 10000,
            producerSkill: 79,
            description: 'Miami\'s hottest Latin trap and hip-hop studio.',
          ),
          Studio(
            id: 'cash_money',
            name: 'Cash Money Studios',
            location: 'New Orleans, LA',
            tier: StudioTier.standard,
            basePrice: 3000,
            qualityRating: 72,
            reputation: 78,
            specialties: ['Hip Hop', 'Rap', 'R&B'],
            hasProducer: true,
            producerFee: 6000,
            producerSkill: 73,
            description: 'Southern bounce and hip-hop headquarters.',
          ),
          Studio(
            id: 'oakland_sound',
            name: 'Oakland Underground Studios',
            location: 'Oakland, CA',
            tier: StudioTier.standard,
            basePrice: 2800,
            qualityRating: 71,
            reputation: 74,
            specialties: ['Hip Hop', 'Rap', 'R&B'],
            hasProducer: true,
            producerFee: 5500,
            producerSkill: 71,
            description: 'Bay Area hip-hop\'s hidden gem.',
          ),
          Studio(
            id: 'home_studio_la',
            name: 'DIY Home Studio',
            location: 'Los Angeles, CA',
            tier: StudioTier.budget,
            basePrice: 800,
            qualityRating: 55,
            reputation: 45,
            specialties: ['Hip Hop', 'Rap'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'Affordable bedroom setup for beginners.',
          ),
        ];
      case 'uk':
        return [
          Studio(
            id: 'abbey_road',
            name: 'Abbey Road Studios',
            location: 'London, UK',
            tier: StudioTier.legendary,
            basePrice: 18000,
            qualityRating: 98,
            reputation: 100,
            specialties: ['Jazz', 'Hip Hop', 'R&B', 'Drill'],
            hasProducer: true,
            producerFee: 30000,
            producerSkill: 95,
            description: 'The world\'s most famous recording studio.',
            requirements: StudioRequirements(
              minFame: 90,
              minAlbums: 3,
              minSongsReleased: 8,
            ),
            exclusiveNote: 'The world\'s most prestigious studio. Reserved for true icons only.',
          ),
          Studio(
            id: 'air_studios',
            name: 'AIR Studios',
            location: 'London, UK',
            tier: StudioTier.legendary,
            basePrice: 16000,
            qualityRating: 94,
            reputation: 96,
            specialties: ['Hip Hop', 'R&B', 'Drill', 'Jazz'],
            hasProducer: true,
            producerFee: 26000,
            producerSkill: 91,
            description: 'George Martin\'s world-class production facility.',
            requirements: StudioRequirements(
              minFame: 80,
              minAlbums: 2,
              minSongsReleased: 6,
            ),
            exclusiveNote: 'George Martin\'s legendary studio. Requires proven success and multiple platinum records.',
          ),
          Studio(
            id: 'maida_vale',
            name: 'Maida Vale Studios',
            location: 'London, UK',
            tier: StudioTier.professional,
            basePrice: 6000,
            qualityRating: 82,
            reputation: 88,
            specialties: ['Drill', 'Hip Hop', 'R&B'],
            hasProducer: true,
            producerFee: 10000,
            producerSkill: 80,
            description: 'BBC\'s legendary live session studio.',
            requirements: StudioRequirements(
              minFame: 50,
              minAlbums: 1,
              minSongsReleased: 4,
            ),
            exclusiveNote: 'BBC\'s prestigious facility. Requires established career and radio play.',
          ),
          Studio(
            id: 'sarm_west',
            name: 'SARM West Studios',
            location: 'London, UK',
            tier: StudioTier.professional,
            basePrice: 7000,
            qualityRating: 85,
            reputation: 89,
            specialties: ['Hip Hop', 'R&B', 'Drill'],
            hasProducer: true,
            producerFee: 12000,
            producerSkill: 83,
            description: 'Where Frankie Goes to Hollywood and Bob Marley recorded.',
            requirements: StudioRequirements(
              minFame: 55,
              minAlbums: 1,
              minSongsReleased: 4,
            ),
            exclusiveNote: 'Historic studio with legendary legacy. Prefers artists with chart presence.',
          ),
          Studio(
            id: 'tileyard',
            name: 'Tileyard Studios',
            location: 'London, UK',
            tier: StudioTier.premium,
            basePrice: 4500,
            qualityRating: 79,
            reputation: 82,
            specialties: ['Hip Hop', 'Drill', 'Trap', 'R&B'],
            hasProducer: true,
            producerFee: 8000,
            producerSkill: 77,
            description: 'London\'s creative hub for urban music.',
          ),
          Studio(
            id: 'manchester_sound',
            name: 'Manchester Sound Studios',
            location: 'Manchester, UK',
            tier: StudioTier.standard,
            basePrice: 3200,
            qualityRating: 73,
            reputation: 76,
            specialties: ['Hip Hop', 'Drill', 'R&B'],
            hasProducer: true,
            producerFee: 5500,
            producerSkill: 72,
            description: 'Northern England\'s grime and hip-hop base.',
          ),
          Studio(
            id: 'birmingham_beats',
            name: 'Birmingham Beats Studio',
            location: 'Birmingham, UK',
            tier: StudioTier.standard,
            basePrice: 2700,
            qualityRating: 69,
            reputation: 72,
            specialties: ['Hip Hop', 'Drill', 'Trap'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'Rising UK drill scene headquarters.',
          ),
          Studio(
            id: 'glasgow_underground',
            name: 'Glasgow Underground Studios',
            location: 'Glasgow, Scotland',
            tier: StudioTier.budget,
            basePrice: 1500,
            qualityRating: 62,
            reputation: 65,
            specialties: ['Hip Hop', 'R&B'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'Scotland\'s emerging hip-hop scene.',
          ),
        ];
      case 'africa':
        return [
          Studio(
            id: 'lagos_afrobeat',
            name: 'Lagos Afrobeat Studios',
            location: 'Lagos, Nigeria',
            tier: StudioTier.premium,
            basePrice: 3000,
            qualityRating: 82,
            reputation: 88,
            specialties: ['Afrobeat', 'Hip Hop', 'R&B'],
            hasProducer: true,
            producerFee: 5000,
            producerSkill: 85,
            description: 'Where Burna Boy and Wizkid record.',
          ),
          Studio(
            id: 'chocolate_city',
            name: 'Chocolate City Studios',
            location: 'Abuja, Nigeria',
            tier: StudioTier.premium,
            basePrice: 2800,
            qualityRating: 80,
            reputation: 85,
            specialties: ['Afrobeat', 'Hip Hop', 'R&B', 'Rap'],
            hasProducer: true,
            producerFee: 4500,
            producerSkill: 82,
            description: 'Nigeria\'s premier hip-hop label studio.',
          ),
          Studio(
            id: 'mavin_records',
            name: 'Mavin Records Studio',
            location: 'Lagos, Nigeria',
            tier: StudioTier.professional,
            basePrice: 4000,
            qualityRating: 84,
            reputation: 87,
            specialties: ['Afrobeat', 'Hip Hop', 'R&B'],
            hasProducer: true,
            producerFee: 6500,
            producerSkill: 84,
            description: 'Don Jazzy\'s legendary production house.',
            requirements: StudioRequirements(
              minFame: 45,
              minAlbums: 1,
              minSongsReleased: 3,
            ),
            exclusiveNote: 'Don Jazzy\'s elite label. Prefers artists with African or global streaming success.',
          ),
          Studio(
            id: 'joburg_sound',
            name: 'Johannesburg Sound',
            location: 'Johannesburg, South Africa',
            tier: StudioTier.standard,
            basePrice: 1800,
            qualityRating: 70,
            reputation: 75,
            specialties: ['Hip Hop', 'Afrobeat', 'R&B'],
            hasProducer: true,
            producerFee: 3000,
            producerSkill: 70,
            description: 'South African hip-hop headquarters.',
          ),
          Studio(
            id: 'cape_town_records',
            name: 'Cape Town Records',
            location: 'Cape Town, South Africa',
            tier: StudioTier.premium,
            basePrice: 2500,
            qualityRating: 76,
            reputation: 79,
            specialties: ['Hip Hop', 'Afrobeat', 'R&B'],
            hasProducer: true,
            producerFee: 4000,
            producerSkill: 75,
            description: 'Scenic studio with world-class equipment.',
          ),
          Studio(
            id: 'accra_sound',
            name: 'Accra Sound Studios',
            location: 'Accra, Ghana',
            tier: StudioTier.standard,
            basePrice: 2000,
            qualityRating: 72,
            reputation: 76,
            specialties: ['Afrobeat', 'Hip Hop', 'R&B'],
            hasProducer: true,
            producerFee: 3500,
            producerSkill: 73,
            description: 'Ghana\'s growing Afrobeats scene.',
          ),
          Studio(
            id: 'nairobi_beats',
            name: 'Nairobi Beats Studio',
            location: 'Nairobi, Kenya',
            tier: StudioTier.standard,
            basePrice: 1600,
            qualityRating: 68,
            reputation: 71,
            specialties: ['Hip Hop', 'Afrobeat', 'R&B'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'East African hip-hop rising star.',
          ),
          Studio(
            id: 'cairo_sound',
            name: 'Cairo Sound Studios',
            location: 'Cairo, Egypt',
            tier: StudioTier.budget,
            basePrice: 1200,
            qualityRating: 63,
            reputation: 67,
            specialties: ['Hip Hop', 'R&B', 'Rap'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'North African hip-hop emerging scene.',
          ),
        ];
      case 'europe':
        return [
          Studio(
            id: 'berlin_techno',
            name: 'Berlin Sound Studios',
            location: 'Berlin, Germany',
            tier: StudioTier.professional,
            basePrice: 7000,
            qualityRating: 88,
            reputation: 90,
            specialties: ['Hip Hop', 'Trap', 'R&B'],
            hasProducer: true,
            producerFee: 12000,
            producerSkill: 85,
            description: 'Cutting-edge production in the heart of Europe.',
            requirements: StudioRequirements(
              minFame: 50,
              minAlbums: 1,
              minSongsReleased: 3,
            ),
            exclusiveNote: 'Leading European production hub. Seeks artists with chart potential.',
          ),
          Studio(
            id: 'hansa_studios',
            name: 'Hansa Studios',
            location: 'Berlin, Germany',
            tier: StudioTier.legendary,
            basePrice: 13000,
            qualityRating: 92,
            reputation: 94,
            specialties: ['Hip Hop', 'R&B', 'Rock', 'Jazz'],
            hasProducer: true,
            producerFee: 21000,
            producerSkill: 89,
            description: 'Historic Berlin Wall studio, legendary acoustics.',
            requirements: StudioRequirements(
              minFame: 75,
              minAlbums: 2,
              minSongsReleased: 5,
            ),
            exclusiveNote: 'Berlin\'s most iconic studio. Demands proven international presence.',
          ),
          Studio(
            id: 'paris_studios',
            name: 'Studio Ferber',
            location: 'Paris, France',
            tier: StudioTier.premium,
            basePrice: 5500,
            qualityRating: 85,
            reputation: 87,
            specialties: ['Hip Hop', 'Jazz', 'R&B'],
            hasProducer: true,
            producerFee: 9000,
            producerSkill: 82,
            description: 'Iconic Parisian studio, home of French hip-hop.',
          ),
          Studio(
            id: 'studio_davout',
            name: 'Studio Davout',
            location: 'Paris, France',
            tier: StudioTier.professional,
            basePrice: 6500,
            qualityRating: 86,
            reputation: 88,
            specialties: ['Hip Hop', 'R&B', 'Rap', 'Jazz'],
            hasProducer: true,
            producerFee: 11000,
            producerSkill: 84,
            description: 'France\'s oldest and most prestigious studio.',
            requirements: StudioRequirements(
              minFame: 45,
              minAlbums: 1,
              minSongsReleased: 3,
            ),
            exclusiveNote: 'France\'s historic facility. Values European chart success.',
          ),
          Studio(
            id: 'amsterdam_recording',
            name: 'Amsterdam Recording House',
            location: 'Amsterdam, Netherlands',
            tier: StudioTier.standard,
            basePrice: 3500,
            qualityRating: 75,
            reputation: 78,
            specialties: ['Hip Hop', 'Trap', 'R&B'],
            hasProducer: true,
            producerFee: 5000,
            producerSkill: 75,
            description: 'Modern facilities with a laid-back vibe.',
          ),
          Studio(
            id: 'stockholm_sound',
            name: 'Stockholm Sound Factory',
            location: 'Stockholm, Sweden',
            tier: StudioTier.premium,
            basePrice: 5000,
            qualityRating: 81,
            reputation: 84,
            specialties: ['Hip Hop', 'R&B', 'Trap'],
            hasProducer: true,
            producerFee: 8500,
            producerSkill: 80,
            description: 'Scandinavian precision meets modern hip-hop.',
          ),
          Studio(
            id: 'madrid_records',
            name: 'Madrid Records Studio',
            location: 'Madrid, Spain',
            tier: StudioTier.standard,
            basePrice: 3200,
            qualityRating: 74,
            reputation: 77,
            specialties: ['Hip Hop', 'Trap', 'R&B', 'Reggae'],
            hasProducer: true,
            producerFee: 5500,
            producerSkill: 73,
            description: 'Spanish hip-hop and Latin trap fusion.',
          ),
          Studio(
            id: 'rome_studio',
            name: 'Rome Sound Studios',
            location: 'Rome, Italy',
            tier: StudioTier.standard,
            basePrice: 3800,
            qualityRating: 76,
            reputation: 79,
            specialties: ['Hip Hop', 'R&B', 'Rap'],
            hasProducer: true,
            producerFee: 6000,
            producerSkill: 74,
            description: 'Italian rap and hip-hop cultural hub.',
          ),
          Studio(
            id: 'warsaw_beats',
            name: 'Warsaw Beats Studio',
            location: 'Warsaw, Poland',
            tier: StudioTier.budget,
            basePrice: 1800,
            qualityRating: 65,
            reputation: 68,
            specialties: ['Hip Hop', 'Trap', 'R&B'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'Eastern European hip-hop on the rise.',
          ),
        ];
      case 'asia':
        return [
          Studio(
            id: 'tokyo_sound',
            name: 'Tokyo Sound Factory',
            location: 'Tokyo, Japan',
            tier: StudioTier.professional,
            basePrice: 8500,
            qualityRating: 90,
            reputation: 92,
            specialties: ['Hip Hop', 'R&B', 'Trap'],
            hasProducer: true,
            producerFee: 14000,
            producerSkill: 88,
            description: 'State-of-the-art Japanese production house.',
            requirements: StudioRequirements(
              minFame: 55,
              minAlbums: 1,
              minSongsReleased: 4,
            ),
            exclusiveNote: 'Premier Japanese studio. Seeks artists with proven streaming numbers.',
          ),
          Studio(
            id: 'onkio_haus',
            name: 'Onkio Haus',
            location: 'Tokyo, Japan',
            tier: StudioTier.legendary,
            basePrice: 15000,
            qualityRating: 94,
            reputation: 96,
            specialties: ['Hip Hop', 'R&B', 'Jazz', 'Trap'],
            hasProducer: true,
            producerFee: 24000,
            producerSkill: 92,
            description: 'Japan\'s most prestigious recording facility.',
            requirements: StudioRequirements(
              minFame: 80,
              minAlbums: 2,
              minSongsReleased: 6,
            ),
            exclusiveNote: 'Japan\'s most elite studio. Reserved for international stars with Asian market presence.',
          ),
          Studio(
            id: 'seoul_music',
            name: 'Seoul Music Studios',
            location: 'Seoul, South Korea',
            tier: StudioTier.premium,
            basePrice: 6000,
            qualityRating: 87,
            reputation: 89,
            specialties: ['Hip Hop', 'R&B', 'Trap'],
            hasProducer: true,
            producerFee: 10000,
            producerSkill: 85,
            description: 'Where K-Hip Hop meets global sound.',
          ),
          Studio(
            id: 'yg_studios',
            name: 'YG Entertainment Studios',
            location: 'Seoul, South Korea',
            tier: StudioTier.professional,
            basePrice: 7500,
            qualityRating: 88,
            reputation: 91,
            specialties: ['Hip Hop', 'R&B', 'Trap', 'Rap'],
            hasProducer: true,
            producerFee: 13000,
            producerSkill: 87,
            description: 'K-pop label\'s legendary hip-hop division.',
            requirements: StudioRequirements(
              minFame: 50,
              minAlbums: 1,
              minSongsReleased: 4,
            ),
            exclusiveNote: 'K-pop powerhouse studio. Requires strong social media presence and fanbase.',
          ),
          Studio(
            id: 'aomg_studio',
            name: 'AOMG Studios',
            location: 'Seoul, South Korea',
            tier: StudioTier.premium,
            basePrice: 5500,
            qualityRating: 84,
            reputation: 87,
            specialties: ['Hip Hop', 'R&B', 'Trap'],
            hasProducer: true,
            producerFee: 9000,
            producerSkill: 83,
            description: 'Jay Park\'s Korean hip-hop powerhouse.',
          ),
          Studio(
            id: 'mumbai_records',
            name: 'Mumbai Records',
            location: 'Mumbai, India',
            tier: StudioTier.standard,
            basePrice: 2500,
            qualityRating: 72,
            reputation: 75,
            specialties: ['Hip Hop', 'R&B', 'Trap'],
            hasProducer: true,
            producerFee: 4000,
            producerSkill: 72,
            description: 'India\'s growing hip-hop scene headquarters.',
          ),
          Studio(
            id: 'gully_gang',
            name: 'Gully Gang Studios',
            location: 'Mumbai, India',
            tier: StudioTier.premium,
            basePrice: 3500,
            qualityRating: 78,
            reputation: 81,
            specialties: ['Hip Hop', 'Rap', 'R&B'],
            hasProducer: true,
            producerFee: 5500,
            producerSkill: 77,
            description: 'Divine\'s Mumbai hip-hop movement HQ.',
          ),
          Studio(
            id: 'beijing_sound',
            name: 'Beijing Sound Lab',
            location: 'Beijing, China',
            tier: StudioTier.premium,
            basePrice: 4500,
            qualityRating: 80,
            reputation: 83,
            specialties: ['Hip Hop', 'Trap', 'R&B'],
            hasProducer: true,
            producerFee: 7000,
            producerSkill: 79,
            description: 'Chinese hip-hop\'s premier recording space.',
          ),
          Studio(
            id: 'shanghai_records',
            name: 'Shanghai Records',
            location: 'Shanghai, China',
            tier: StudioTier.standard,
            basePrice: 3000,
            qualityRating: 73,
            reputation: 76,
            specialties: ['Hip Hop', 'Trap', 'R&B'],
            hasProducer: true,
            producerFee: 5000,
            producerSkill: 72,
            description: 'Modern Chinese trap and hip-hop fusion.',
          ),
          Studio(
            id: 'bangkok_beats',
            name: 'Bangkok Beats Studio',
            location: 'Bangkok, Thailand',
            tier: StudioTier.standard,
            basePrice: 2200,
            qualityRating: 70,
            reputation: 73,
            specialties: ['Hip Hop', 'Trap', 'R&B'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'Southeast Asian hip-hop rising scene.',
          ),
          Studio(
            id: 'singapore_sound',
            name: 'Singapore Sound Studios',
            location: 'Singapore',
            tier: StudioTier.premium,
            basePrice: 5000,
            qualityRating: 82,
            reputation: 85,
            specialties: ['Hip Hop', 'R&B', 'Trap'],
            hasProducer: true,
            producerFee: 8000,
            producerSkill: 80,
            description: 'Ultra-modern facility in Asia\'s hub.',
          ),
        ];
      case 'latin_america':
        return [
          Studio(
            id: 'medellin_studios',
            name: 'Medellín Studios',
            location: 'Medellín, Colombia',
            tier: StudioTier.professional,
            basePrice: 4500,
            qualityRating: 83,
            reputation: 86,
            specialties: ['Hip Hop', 'Trap', 'Reggae', 'R&B'],
            hasProducer: true,
            producerFee: 7000,
            producerSkill: 81,
            description: 'J Balvin and Maluma\'s recording home.',
            requirements: StudioRequirements(
              minFame: 45,
              minAlbums: 1,
              minSongsReleased: 3,
            ),
            exclusiveNote: 'Latin music powerhouse. Seeks artists with Spanish-language or global appeal.',
          ),
          Studio(
            id: 'sao_paulo_sound',
            name: 'São Paulo Sound Studios',
            location: 'São Paulo, Brazil',
            tier: StudioTier.premium,
            basePrice: 3800,
            qualityRating: 80,
            reputation: 83,
            specialties: ['Hip Hop', 'Trap', 'R&B', 'Reggae'],
            hasProducer: true,
            producerFee: 6000,
            producerSkill: 78,
            description: 'Brazilian funk and hip-hop fusion capital.',
          ),
          Studio(
            id: 'rio_records',
            name: 'Rio Records',
            location: 'Rio de Janeiro, Brazil',
            tier: StudioTier.premium,
            basePrice: 3500,
            qualityRating: 78,
            reputation: 81,
            specialties: ['Hip Hop', 'R&B', 'Reggae', 'Trap'],
            hasProducer: true,
            producerFee: 5500,
            producerSkill: 76,
            description: 'Beach vibes meet urban beats.',
          ),
          Studio(
            id: 'mexico_city_sound',
            name: 'Mexico City Sound Lab',
            location: 'Mexico City, Mexico',
            tier: StudioTier.premium,
            basePrice: 4000,
            qualityRating: 81,
            reputation: 84,
            specialties: ['Hip Hop', 'Trap', 'R&B', 'Rap'],
            hasProducer: true,
            producerFee: 6500,
            producerSkill: 79,
            description: 'Latin trap and hip-hop powerhouse.',
          ),
          Studio(
            id: 'buenos_aires_studios',
            name: 'Buenos Aires Studios',
            location: 'Buenos Aires, Argentina',
            tier: StudioTier.standard,
            basePrice: 2800,
            qualityRating: 73,
            reputation: 76,
            specialties: ['Hip Hop', 'Trap', 'R&B'],
            hasProducer: true,
            producerFee: 4500,
            producerSkill: 72,
            description: 'Argentine hip-hop and trap scene.',
          ),
          Studio(
            id: 'havana_sound',
            name: 'Havana Sound Studios',
            location: 'Havana, Cuba',
            tier: StudioTier.standard,
            basePrice: 2000,
            qualityRating: 70,
            reputation: 73,
            specialties: ['Hip Hop', 'Reggae', 'R&B', 'Jazz'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'Cuban rhythm meets modern hip-hop.',
          ),
          Studio(
            id: 'kingston_records',
            name: 'Kingston Records',
            location: 'Kingston, Jamaica',
            tier: StudioTier.premium,
            basePrice: 3200,
            qualityRating: 77,
            reputation: 85,
            specialties: ['Reggae', 'Hip Hop', 'R&B', 'Trap'],
            hasProducer: true,
            producerFee: 5000,
            producerSkill: 78,
            description: 'Legendary reggae and dancehall home.',
          ),
        ];
      case 'oceania':
        return [
          Studio(
            id: 'sydney_sound',
            name: 'Sydney Sound Studios',
            location: 'Sydney, Australia',
            tier: StudioTier.professional,
            basePrice: 6500,
            qualityRating: 85,
            reputation: 88,
            specialties: ['Hip Hop', 'R&B', 'Trap', 'Rock'],
            hasProducer: true,
            producerFee: 11000,
            producerSkill: 83,
            description: 'Australia\'s premier urban music facility.',
            requirements: StudioRequirements(
              minFame: 50,
              minAlbums: 1,
              minSongsReleased: 4,
            ),
            exclusiveNote: 'Australia\'s top urban studio. Looks for artists with strong streaming performance.',
          ),
          Studio(
            id: 'melbourne_records',
            name: 'Melbourne Records',
            location: 'Melbourne, Australia',
            tier: StudioTier.premium,
            basePrice: 5000,
            qualityRating: 82,
            reputation: 85,
            specialties: ['Hip Hop', 'R&B', 'Trap'],
            hasProducer: true,
            producerFee: 8500,
            producerSkill: 80,
            description: 'Melbourne\'s cutting-edge hip-hop scene.',
          ),
          Studio(
            id: 'auckland_sound',
            name: 'Auckland Sound Studios',
            location: 'Auckland, New Zealand',
            tier: StudioTier.standard,
            basePrice: 3500,
            qualityRating: 75,
            reputation: 78,
            specialties: ['Hip Hop', 'R&B', 'Reggae'],
            hasProducer: true,
            producerFee: 6000,
            producerSkill: 74,
            description: 'Kiwi hip-hop and Pacific island fusion.',
          ),
        ];
      case 'canada':
        return [
          Studio(
            id: 'toronto_sound',
            name: 'Toronto Sound Studios',
            location: 'Toronto, Canada',
            tier: StudioTier.legendary,
            basePrice: 13000,
            qualityRating: 93,
            reputation: 95,
            specialties: ['Hip Hop', 'R&B', 'Rap', 'Trap'],
            hasProducer: true,
            producerFee: 22000,
            producerSkill: 90,
            description: 'Drake\'s OVO Sound headquarters.',
            requirements: StudioRequirements(
              minFame: 80,
              minAlbums: 2,
              minSongsReleased: 6,
            ),
            exclusiveNote: 'Drake\'s legendary OVO studios. Reserved for platinum-selling artists with major hits.',
          ),
          Studio(
            id: 'noble_street',
            name: 'Noble Street Studios',
            location: 'Toronto, Canada',
            tier: StudioTier.professional,
            basePrice: 7500,
            qualityRating: 87,
            reputation: 89,
            specialties: ['Hip Hop', 'R&B', 'Rap'],
            hasProducer: true,
            producerFee: 13000,
            producerSkill: 85,
            description: 'Toronto\'s iconic recording facility.',
            requirements: StudioRequirements(
              minFame: 50,
              minAlbums: 1,
              minSongsReleased: 4,
            ),
            exclusiveNote: 'Toronto\'s premier indie studio. Prefers artists with proven Canadian success.',
          ),
          Studio(
            id: 'montreal_sound',
            name: 'Montreal Sound Lab',
            location: 'Montreal, Canada',
            tier: StudioTier.premium,
            basePrice: 5000,
            qualityRating: 81,
            reputation: 84,
            specialties: ['Hip Hop', 'R&B', 'Jazz', 'Trap'],
            hasProducer: true,
            producerFee: 8500,
            producerSkill: 79,
            description: 'Bilingual hip-hop and jazz fusion.',
          ),
          Studio(
            id: 'vancouver_records',
            name: 'Vancouver Records',
            location: 'Vancouver, Canada',
            tier: StudioTier.standard,
            basePrice: 4000,
            qualityRating: 76,
            reputation: 79,
            specialties: ['Hip Hop', 'R&B', 'Trap'],
            hasProducer: true,
            producerFee: 6500,
            producerSkill: 75,
            description: 'West Coast Canadian hip-hop scene.',
          ),
        ];
      default:
        return [
          Studio(
            id: 'local_studio',
            name: 'Local Sound Studio',
            location: 'Downtown',
            tier: StudioTier.budget,
            basePrice: 1000,
            qualityRating: 60,
            reputation: 50,
            specialties: ['Hip Hop', 'R&B'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'Basic recording facility.',
          ),
          Studio(
            id: 'community_studio',
            name: 'Community Recording Space',
            location: 'Local Area',
            tier: StudioTier.budget,
            basePrice: 600,
            qualityRating: 50,
            reputation: 40,
            specialties: ['Hip Hop'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'Affordable option for aspiring artists.',
          ),
          Studio(
            id: 'indie_studio',
            name: 'Indie Sound Studio',
            location: 'Local Area',
            tier: StudioTier.standard,
            basePrice: 2000,
            qualityRating: 68,
            reputation: 65,
            specialties: ['Hip Hop', 'R&B', 'Rap'],
            hasProducer: false,
            producerFee: 0,
            producerSkill: 0,
            description: 'Independent recording space with decent gear.',
          ),
        ];
    }
  }
}
