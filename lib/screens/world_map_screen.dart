import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/world_region.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
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
        backgroundColor: const Color(0xFF21262D),
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
            const Color(0xFF00D9FF).withOpacity(0.2),
            const Color(0xFF7C3AED).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.5),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF),
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

    return regions.where((r) => r.id != _currentStats.currentRegion).map((region) {
      final travelCost = _calculateTravelCost(currentRegion.id, region.id);
      final canAfford = _currentStats.money >= travelCost;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: canAfford ? () => _showTravelConfirmation(region, travelCost) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canAfford
                    ? [
                        const Color(0xFF21262D),
                        const Color(0xFF30363D),
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
                              color: canAfford ? const Color(0xFF00D9FF) : Colors.white30,
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
                        color: canAfford ? const Color(0xFFFF6B9D) : Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.flight_takeoff,
                      color: canAfford ? const Color(0xFF00D9FF) : Colors.white30,
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
    // Adjacent regions cost less
    const adjacentRegions = {
      'usa': ['latin_america'],
      'europe': ['uk', 'africa', 'asia'],
      'uk': ['europe', 'usa'],
      'asia': ['oceania', 'europe'],
      'africa': ['europe', 'asia'],
      'latin_america': ['usa'],
      'oceania': ['asia'],
    };

    if (adjacentRegions[from]?.contains(to) ?? false) {
      return 5000;
    }

    return 15000;
  }

  void _showTravelConfirmation(WorldRegion region, int cost) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF21262D),
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
                  color: const Color(0xFF30363D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Travel Cost:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '\$${_formatNumber(cost)}',
                      style: const TextStyle(
                        color: Color(0xFFFF6B9D),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '✨ New studios and opportunities await!',
                style: TextStyle(
                  color: Color(0xFF00D9FF),
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
                backgroundColor: const Color(0xFF00D9FF),
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

  void _travelToRegion(WorldRegion region, int cost) {
    setState(() {
      _currentStats = _currentStats.copyWith(
        money: _currentStats.money - cost,
        currentRegion: region.id,
      );
    });

    widget.onStatsUpdated(_currentStats);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✈️ Welcome to ${region.name}!'),
        backgroundColor: const Color(0xFF00D9FF),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
