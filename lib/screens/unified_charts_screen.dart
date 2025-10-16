import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/unified_chart_service.dart';

/// Unified Charts Screen - One screen for all chart types
///
/// Features:
/// - Period filter: Daily / Weekly
/// - Type filter: Singles / Albums / Artists
/// - Region filter: Global / Specific Region
///
/// Chart Combinations:
/// - Daily/Weekly Singles (Global/Regional)
/// - Daily/Weekly Albums (Global/Regional)
/// - Daily/Weekly Artists (Global/Regional)
class UnifiedChartsScreen extends StatefulWidget {
  const UnifiedChartsScreen({super.key});

  @override
  State<UnifiedChartsScreen> createState() => _UnifiedChartsScreenState();
}

class _UnifiedChartsScreenState extends State<UnifiedChartsScreen> {
  final UnifiedChartService _chartService = UnifiedChartService();

  // Filter state
  String _selectedPeriod = 'weekly'; // 'daily' or 'weekly'
  String _selectedType = 'singles'; // 'singles', 'albums', or 'artists'
  String _selectedRegion = 'global'; // 'global' or region code

  // Data state
  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadChartData();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _currentUserId = user?.uid;
      });
    }
  }

  Future<void> _loadChartData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> data;

      if (_selectedType == 'artists') {
        data = await _chartService.getArtistsChart(
          period: _selectedPeriod,
          region: _selectedRegion,
          limit: 100,
        );
      } else {
        data = await _chartService.getSongsChart(
          period: _selectedPeriod,
          type: _selectedType,
          region: _selectedRegion,
          limit: 100,
        );
      }

      if (mounted) {
        setState(() {
          _chartData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterChanged() {
    _loadChartData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_buildTitle()),
        backgroundColor: _getThemeColor(),
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildInfoBanner(),
          Expanded(child: _buildChartContent()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        children: [
          // Period filter
          Row(
            children: [
              const Text(
                '⏱️ Period: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'daily', label: Text('Daily')),
                    ButtonSegment(value: 'weekly', label: Text('Weekly')),
                  ],
                  selected: {_selectedPeriod},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedPeriod = newSelection.first;
                    });
                    _onFilterChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Type filter
          Row(
            children: [
              const Text(
                '🎵 Type: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'singles', label: Text('Singles')),
                    ButtonSegment(value: 'albums', label: Text('Albums')),
                    ButtonSegment(value: 'artists', label: Text('Artists')),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                    _onFilterChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Region filter
          Row(
            children: [
              const Text(
                '🌍 Region: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'global',
                      child: Text('🌍 Global'),
                    ),
                    ...UnifiedChartService.regions.map((region) {
                      final flag =
                          UnifiedChartService.regionFlags[region] ?? '🌍';
                      final name =
                          UnifiedChartService.regionNames[region] ?? region;
                      return DropdownMenuItem(
                        value: region,
                        child: Text('$flag $name'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRegion = value;
                      });
                      _onFilterChanged();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    String info = '';

    if (_selectedPeriod == 'daily') {
      info = '📊 Rankings based on streams gained in the last game day';
    } else {
      info = '📊 Rankings based on streams gained in the last 7 game days';
    }

    if (_selectedRegion != 'global') {
      final regionName =
          UnifiedChartService.regionNames[_selectedRegion] ?? _selectedRegion;
      info += ' in $regionName';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: _getThemeColor().withOpacity(0.2),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(info, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildChartContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading chart', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChartData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedType == 'artists'
                  ? Icons.person_outline
                  : Icons.music_note,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No $_selectedType charting yet',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedPeriod == 'daily'
                  ? 'Check back tomorrow for daily rankings'
                  : 'Release music to see it on the charts!',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChartData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _chartData.length,
        itemBuilder: (context, index) {
          final entry = _chartData[index];
          final position = index + 1;

          if (_selectedType == 'artists') {
            return _buildArtistCard(entry, position);
          } else {
            return _buildSongCard(entry, position);
          }
        },
      ),
    );
  }

  Widget _buildSongCard(Map<String, dynamic> entry, int position) {
    final isUserSong = entry['artistId'] == _currentUserId;
    final genre = entry['genre'] as String? ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUserSong ? Colors.green[900] : Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUserSong
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildPositionBadge(position),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry['title'] ?? 'Untitled',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _chartService.getGenreEmoji(genre),
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry['artist'] ?? 'Unknown Artist',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${_chartService.formatStreams(entry['periodStreams'] ?? 0)} streams',
                  style: TextStyle(
                    color: _getThemeColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_chartService.formatStreams(entry['totalStreams'] ?? 0)} total',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: isUserSong
            ? const Icon(Icons.star, color: Colors.amber)
            : null,
      ),
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> entry, int position) {
    final isCurrentUser = entry['artistId'] == _currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCurrentUser ? Colors.green[900] : Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentUser
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildPositionBadge(position),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry['artistName'] ?? 'Unknown Artist',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Text('🎤', style: TextStyle(fontSize: 20)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry['releasedSongs'] ?? 0} songs • ${_chartService.formatStreams(entry['fanbase'] ?? 0)} fans',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Text(
              '${_chartService.formatStreams(entry['periodStreams'] ?? 0)} streams ($_selectedPeriod)',
              style: TextStyle(
                color: _getThemeColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: isCurrentUser
            ? const Icon(Icons.star, color: Colors.amber)
            : null,
      ),
    );
  }

  Widget _buildPositionBadge(int position) {
    Color badgeColor;
    String emoji;

    if (position == 1) {
      badgeColor = Colors.amber;
      emoji = '🥇';
    } else if (position == 2) {
      badgeColor = Colors.grey[400]!;
      emoji = '🥈';
    } else if (position == 3) {
      badgeColor = Colors.brown;
      emoji = '🥉';
    } else {
      badgeColor = Colors.grey[700]!;
      emoji = '';
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji.isNotEmpty)
              Text(emoji, style: const TextStyle(fontSize: 18))
            else
              Text(
                '#$position',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildTitle() {
    String period = _selectedPeriod == 'daily' ? 'Daily' : 'Weekly';
    String type = _selectedType == 'singles'
        ? 'Singles'
        : _selectedType == 'albums'
        ? 'Albums'
        : 'Artists';

    return '$period $type Chart';
  }

  Color _getThemeColor() {
    if (_selectedPeriod == 'daily') {
      return Colors.orange;
    } else {
      if (_selectedType == 'singles') {
        return Colors.blue;
      } else if (_selectedType == 'albums') {
        return Colors.purple;
      } else {
        return Colors.green;
      }
    }
  }
}
