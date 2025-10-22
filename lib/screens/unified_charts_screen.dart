import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final String? initialPeriod; // 'daily' | 'weekly'
  final String? initialType;   // 'singles' | 'albums' | 'artists'
  final String? initialRegion; // 'global' | region code

  const UnifiedChartsScreen({
    super.key,
    this.initialPeriod,
    this.initialType,
    this.initialRegion,
  });

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
    // Apply initial filters if provided (for deep-links)
    if (widget.initialPeriod != null) {
      _selectedPeriod = widget.initialPeriod!;
    }
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    if (widget.initialRegion != null) {
      _selectedRegion = widget.initialRegion!;
    }
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return _getThemeColor().withOpacity(0.3);
                      }
                      return Colors.grey[800]!;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return _getThemeColor();
                      }
                      return Colors.white;
                    }),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'daily',
                      label: Text(
                        'Daily',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ButtonSegment(
                      value: 'weekly',
                      label: Text(
                        'Weekly',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return _getThemeColor().withOpacity(0.3);
                      }
                      return Colors.grey[800]!;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return _getThemeColor();
                      }
                      return Colors.white;
                    }),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'singles',
                      label: Text(
                        'Singles',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ButtonSegment(
                      value: 'albums',
                      label: Text(
                        'Albums',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ButtonSegment(
                      value: 'artists',
                      label: Text(
                        'Artists',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedRegion,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  dropdownColor: Colors.grey[850],
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
                      child: Text(
                        '🌍 Global',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ...UnifiedChartService.regions.map((region) {
                      final flag =
                          UnifiedChartService.regionFlags[region] ?? '🌍';
                      final name =
                          UnifiedChartService.regionNames[region] ?? region;
                      return DropdownMenuItem(
                        value: region,
                        child: Text(
                          '$flag $name',
                          style: const TextStyle(color: Colors.white),
                        ),
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
          const Icon(Icons.info_outline, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              info,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
            Text(
              'Error loading chart',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
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
              style: const TextStyle(fontSize: 18, color: Colors.white),
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
        leading: (() {
          final coverUrl = entry['coverArtUrl'] as String?;
          if (coverUrl != null && coverUrl.isNotEmpty) {
            return Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildPositionBadge(position),
                    ),
                  ),
                ),
                // Position badge overlay
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: position <= 3
                            ? (position == 1
                                ? Colors.amber
                                : position == 2
                                    ? Colors.grey[300]!
                                    : Colors.brown)
                            : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      position <= 3
                          ? (position == 1
                              ? '🥇'
                              : position == 2
                                  ? '🥈'
                                  : '🥉')
                          : '#$position',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: position <= 3 ? 14 : 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return _buildPositionBadge(position);
        }()),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry['title'] ?? 'Untitled',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${_chartService.formatStreams(entry['periodStreams'] ?? 0)} streams',
                  style: TextStyle(
                    color: _getStreamColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_chartService.formatStreams(entry['totalStreams'] ?? 0)} total',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing:
            isUserSong ? const Icon(Icons.star, color: Colors.amber) : null,
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
        leading: (() {
          final avatar = entry['avatarUrl'] as String?;
          if (avatar != null && avatar.isNotEmpty) {
            return Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildPositionBadge(position),
                    ),
                  ),
                ),
                // Position badge overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: position <= 3
                            ? (position == 1
                                ? Colors.amber
                                : position == 2
                                    ? Colors.grey[300]!
                                    : Colors.brown)
                            : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      position <= 3
                          ? (position == 1
                              ? '🥇'
                              : position == 2
                                  ? '🥈'
                                  : '🥉')
                          : '#$position',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: position <= 3 ? 12 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return _buildPositionBadge(position);
        }()),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry['artistName'] ?? 'Unknown Artist',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
              '${entry['songCount'] ?? entry['releasedSongs'] ?? 0} songs • ${_chartService.formatStreams(entry['fanbase'] ?? 0)} fans',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              '${_chartService.formatStreams(entry['streams'] ?? entry['periodStreams'] ?? 0)} streams ($_selectedPeriod)',
              style: TextStyle(
                color: _getStreamColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing:
            isCurrentUser ? const Icon(Icons.star, color: Colors.amber) : null,
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
      badgeColor = Colors.grey[300]!;
      emoji = '🥈';
    } else if (position == 3) {
      badgeColor = Colors.brown;
      emoji = '🥉';
    } else {
      badgeColor = Colors.grey[600]!;
      emoji = '';
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.25),
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
                  color: Colors.white,
                  fontSize: 14,
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

    return '$period Spotlight $type'; // ✅ Changed: "Daily/Weekly Spotlight Singles/Albums/Artists"
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

  /// Get high-contrast color for stream counts
  Color _getStreamColor() {
    if (_selectedPeriod == 'daily') {
      return const Color(0xFFFFAA00); // Bright orange
    } else {
      if (_selectedType == 'singles') {
        return const Color(0xFF00D9FF); // Bright cyan
      } else if (_selectedType == 'albums') {
        return const Color(0xFFAA66FF); // Bright purple
      } else {
        return const Color(0xFF00FF88); // Bright green
      }
    }
  }
}
