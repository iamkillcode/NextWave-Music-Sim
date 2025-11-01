import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/artist_stats.dart';
import '../models/world_region.dart';
import '../widgets/app_navigation_wrapper.dart';

class WorldMapScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const WorldMapScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  late ArtistStats _currentStats;

  @override
  void initState() {
    super.initState();
    _currentStats = widget.artistStats;
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrapper(
      currentIndex: 5, // World Map is index 5
      artistStats: _currentStats,
      onStatsUpdated: (updatedStats) {
        setState(() => _currentStats = updatedStats);
        widget.onStatsUpdated(updatedStats);
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Row(
            children: [
              Text(
                '🌍',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 8),
              Text(
                'World Map',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceDark,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentLocationCard(),
              const SizedBox(height: 24),
              _buildTravelInfoCard(),
              const SizedBox(height: 16),
              const Text(
                'Travel Destinations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildRegionCards(),
            ],
          ),
        ), // Close body SingleChildScrollView
      ), // Close Scaffold
    ); // Close AppNavigationWrapper
  }

  Widget _buildTravelInfoCard() {
    final fame = _currentStats.fame;
    final money = _currentStats.money;

    String statusText;
    Color statusColor;
    String statusIcon;

    if (money > 50000) {
      statusText = 'Elite Traveler - 20% discount on all flights!';
      statusColor = AppTheme.chartGold; // Gold
      statusIcon = '💎';
    } else if (money > 20000) {
      statusText = 'Premium Traveler - 10% discount on flights';
      statusColor = AppTheme.accentBlue; // Cyan
      statusIcon = '✨';
    } else if (fame > 50) {
      statusText = 'Famous Artist - Travel costs scale with your fame';
      statusColor = AppTheme.neonPurple; // Pink
      statusIcon = '⭐';
    } else {
      statusText = 'Rising Artist - Affordable travel rates available';
      statusColor = Colors.green;
      statusIcon = '🎵';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(statusIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    final regions = WorldRegion.getAllRegions();
    final currentRegion = regions.firstWhere(
      (r) => r.id == _currentStats.currentRegion,
      orElse: () => regions.first,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentBlue.withOpacity(0.2),
            AppTheme.neonPurple.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentBlue.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                currentRegion.flag,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Location',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      currentRegion.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'HERE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentRegion.description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currentRegion.popularGenres.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  genre,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRegionCards() {
    final regions = WorldRegion.getAllRegions();
    final currentRegion = regions.firstWhere(
      (r) => r.id == _currentStats.currentRegion,
      orElse: () => regions.first,
    );

    return regions
        .where((r) => r.id != _currentStats.currentRegion)
        .map((region) {
      final travelCost = _calculateTravelCost(currentRegion.id, region.id);
      final canAfford = _currentStats.money >= travelCost;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: canAfford
              ? () => _showTravelConfirmation(region, travelCost)
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canAfford
                    ? [
                        AppTheme.surfaceDark,
                        AppTheme.borderDefault,
                      ]
                    : [
                        Colors.grey.withOpacity(0.2),
                        Colors.grey.withOpacity(0.1),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: canAfford
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  region.flag,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        region.name,
                        style: TextStyle(
                          color: canAfford ? Colors.white : Colors.white30,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        region.description,
                        style: TextStyle(
                          color: canAfford ? Colors.white60 : Colors.white30,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: region.popularGenres.take(3).map((genre) {
                          return Text(
                            genre,
                            style: TextStyle(
                              color: canAfford
                                  ? AppTheme.accentBlue
                                  : Colors.white30,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${_formatNumber(travelCost)}',
                      style: TextStyle(
                        color:
                            canAfford ? AppTheme.neonPurple : Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.flight_takeoff,
                      color: canAfford ? AppTheme.accentBlue : Colors.white30,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  int _calculateTravelCost(String from, String to) {
    // Same region = free (shouldn't happen)
    if (from == to) return 0;

    // Base costs scale with fame (starts low, increases with success)
    // Early game (0-20 fame): $500-$1,500
    // Mid game (20-50 fame): $1,500-$5,000
    // Late game (50-80 fame): $5,000-$15,000
    // Endgame (80+ fame): $15,000-$30,000

    final fame = _currentStats.fame;
    final fameMultiplier =
        1.0 + (fame / 100.0); // 1.0x at 0 fame, 2.0x at 100 fame

    // Distance-based costs
    const adjacentRegions = {
      'usa': ['canada', 'latin_america', 'uk'],
      'canada': ['usa', 'uk'],
      'uk': ['europe', 'usa', 'canada'],
      'europe': ['uk', 'africa', 'asia'],
      'asia': ['europe', 'oceania', 'africa'],
      'africa': ['europe', 'asia', 'latin_america'],
      'latin_america': ['usa', 'africa'],
      'oceania': ['asia'],
    };

    int baseCost;
    if (adjacentRegions[from]?.contains(to) ?? false) {
      // Adjacent regions base cost
      baseCost = 500; // Start at $500
    } else {
      // Far regions base cost
      baseCost = 1500; // Start at $1,500
    }

    // Apply fame scaling
    final scaledCost = (baseCost * fameMultiplier).round();

    // Wealth-based discount (if you're rich, travel is relatively cheaper)
    // Players with lots of money get slight discount (max 20% off)
    final wealthMultiplier = _currentStats.money > 50000
        ? 0.8 // 20% discount for rich players
        : _currentStats.money > 20000
            ? 0.9 // 10% discount for mid-wealth
            : 1.0; // No discount for broke players

    final finalCost = (scaledCost * wealthMultiplier).round();

    // Minimum cost: $100 (always affordable for new players)
    // Maximum cost: $50,000 (prevents ridiculous scaling)
    return finalCost.clamp(100, 50000);
  }

  void _showTravelConfirmation(WorldRegion region, int cost) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Text(region.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Travel to ${region.name}?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                region.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.borderDefault,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Travel Cost:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${_formatNumber(cost)}',
                          style: const TextStyle(
                            color: AppTheme.neonPurple,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_currentStats.money > 20000) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _currentStats.money > 50000
                                ? '💎 Elite Traveler: 20% discount applied'
                                : '✨ Premium: 10% discount applied',
                            style: TextStyle(
                              color: AppTheme.accentBlue.withOpacity(0.8),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '✨ New studios and opportunities await!',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _travelToRegion(region, cost);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Travel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _travelToRegion(WorldRegion region, int cost) async {
    try {
      // Update Firestore first
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('players')
            .doc(user.uid)
            .update({
          'currentMoney': _currentStats.money - cost,
          'homeRegion': region.id,
        });
      }

      // Then update local state
      setState(() {
        _currentStats = _currentStats.copyWith(
          money: _currentStats.money - cost,
          currentRegion: region.id,
        );
      });

      widget.onStatsUpdated(_currentStats);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✈️ Welcome to ${region.name}!'),
            backgroundColor: AppTheme.accentBlue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error traveling: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
