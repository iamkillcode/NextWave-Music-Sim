import 'package:flutter/material.dart';

enum StudioTier {
  legendary,
  professional,
  premium,
  standard,
  budget,
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
        ];
    }
  }
}
