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
/// - Mobile responsive design
/// - Trending indicators (up/down/same arrows)
/// - Weeks on chart display
///
/// Chart Combinations:
/// - Daily/Weekly Singles (Global/Regional)
/// - Daily/Weekly Albums (Global/Regional)
/// - Daily/Weekly Artists (Global/Regional)
class UnifiedChartsScreen extends StatefulWidget {
  final String? initialPeriod; // 'daily' | 'weekly'
  final String? initialType; // 'singles' | 'albums' | 'artists'
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

  // Responsive sizing helper
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return baseSize * 0.85; // Small phones
    } else if (width < 600) {
      return baseSize; // Normal phones
    } else if (width < 900) {
      return baseSize * 1.1; // Tablets
    } else {
      return baseSize * 1.2; // Desktop
    }
  }

  double _getResponsivePadding(BuildContext context, double basePadding) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return basePadding * 0.7;
    } else if (width < 600) {
      return basePadding;
    } else {
      return basePadding * 1.2;
    }
  }

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
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return _getThemeColor().withOpacity(0.3);
                      }
                      return Colors.grey[800]!;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return _getThemeColor();
                      }
                      return Colors.white;
                    }),
                  ),
                  segments: [
                    ButtonSegment(
                      value: 'daily',
                      label: Text(
                        'Daily',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedType == 'artists'
                              ? Colors.grey[600]
                              : null,
                        ),
                      ),
                      enabled: _selectedType !=
                          'artists', // Disable Daily for Artists
                    ),
                    const ButtonSegment(
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
                      // Auto-switch to weekly when Artists is selected (daily doesn't work for artists)
                      if (_selectedType == 'artists' &&
                          _selectedPeriod == 'daily') {
                        _selectedPeriod = 'weekly';
                      }
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
                  value: _selectedRegion,
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

    // Special message when Artists + Daily would be selected (but isn't allowed)
    if (_selectedType == 'artists') {
      info =
          '📊 Artist rankings based on combined streams from all songs over the last 7 game days';
    } else if (_selectedPeriod == 'daily') {
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
    final movement = entry['movement'] as int? ?? 0;
    final lastWeekPosition = entry['lastWeekPosition'] as int?;

    // Responsive sizing
    final coverSize = _getResponsiveSize(context, 56.0);
    final titleFontSize = _getResponsiveSize(context, 15.0);
    final artistFontSize = _getResponsiveSize(context, 13.0);

    return Container(
      margin: EdgeInsets.only(bottom: _getResponsivePadding(context, 8.0)),
      decoration: BoxDecoration(
        color: isUserSong ? const Color(0xFF1B4D3E) : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: isUserSong ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(_getResponsivePadding(context, 12.0)),
        child: Row(
          children: [
            // Position number with special styling for top 3
            _buildPositionNumber(position),
            SizedBox(width: _getResponsivePadding(context, 12.0)),

            // Cover art
            _buildCoverArt(entry, coverSize),
            SizedBox(width: _getResponsivePadding(context, 12.0)),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with trending indicator
                  Row(
                    children: [
                      if (_selectedPeriod == 'weekly') ...[
                        _buildTrendingIndicator(movement, lastWeekPosition),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          entry['title'] ?? 'Untitled',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUserSong)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child:
                              Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Artist name
                  Text(
                    entry['artist'] ?? 'Unknown Artist',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: artistFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Streams and stats
                  Row(
                    children: [
                      Text(
                        '${_chartService.formatStreams(entry['periodStreams'] ?? 0)}',
                        style: TextStyle(
                          color: _getStreamColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: _getResponsiveSize(context, 13.0),
                        ),
                      ),
                      Text(
                        ' streams',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: _getResponsiveSize(context, 11.0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Show track count for albums, or total streams for singles
                      if (_selectedType == 'albums' &&
                          entry['trackCount'] != null)
                        Text(
                          '${entry['trackCount']} tracks',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: _getResponsiveSize(context, 11.0),
                          ),
                        )
                      else
                        Text(
                          '${_chartService.formatStreams(entry['totalStreams'] ?? 0)} total',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: _getResponsiveSize(context, 11.0),
                          ),
                        ),
                    ],
                  ),

                  // Weeks on chart badge
                  if (_selectedPeriod == 'weekly' &&
                      _getChartEntryText(entry).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getChartEntryColor(entry).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getChartEntryColor(entry).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getChartEntryText(entry),
                          style: TextStyle(
                            color: _getChartEntryColor(entry),
                            fontSize: _getResponsiveSize(context, 10.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionNumber(int position) {
    Color badgeColor;
    Color textColor = Colors.white;

    if (position == 1) {
      badgeColor = const Color(0xFFFFD700); // Gold
      textColor = Colors.black;
    } else if (position == 2) {
      badgeColor = const Color(0xFFC0C0C0); // Silver
      textColor = Colors.black;
    } else if (position == 3) {
      badgeColor = const Color(0xFFCD7F32); // Bronze
      textColor = Colors.white;
    } else {
      badgeColor = Colors.transparent;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
        border:
            position <= 3 ? null : Border.all(color: Colors.white24, width: 1),
      ),
      child: Center(
        child: Text(
          '$position',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: position <= 3 ? 16 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCoverArt(Map<String, dynamic> entry, double size) {
    final coverUrl = entry['coverArtUrl'] as String?;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: coverUrl != null && coverUrl.isNotEmpty
            ? CachedNetworkImage(
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
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note,
                      color: Colors.white30, size: 24),
                ),
              )
            : Container(
                color: Colors.grey[800],
                child: const Icon(Icons.music_note,
                    color: Colors.white30, size: 24),
              ),
      ),
    );
  }

  String _getChartEntryText(Map<String, dynamic> entry) {
    final entryType = entry['entryType'] as String?;
    final weeksOnChart = entry['weeksOnChart'] as int? ?? 0;

    if (entryType == 'new') {
      return 'New Entry';
    } else if (entryType == 're-entry') {
      return 'Re-Entry';
    } else if (weeksOnChart > 0) {
      return '$weeksOnChart ${weeksOnChart == 1 ? "week" : "weeks"} on chart';
    }
    return '';
  }

  Color _getChartEntryColor(Map<String, dynamic> entry) {
    final entryType = entry['entryType'] as String?;
    if (entryType == 'new') {
      return Colors.green;
    } else if (entryType == 're-entry') {
      return Colors.amber;
    }
    return Colors.cyan;
  }

  Widget _buildTrendingIndicator(int movement, int? lastWeekPosition) {
    if (movement == 0) {
      // No change — show subtle dash
      return Tooltip(
        message: lastWeekPosition != null
            ? 'No change (#$lastWeekPosition)'
            : 'No change (no previous data)',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(
            Icons.remove,
            color: Colors.white38,
            size: 12,
          ),
        ),
      );
    }

    final isUp = movement > 0;
    final color = isUp ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);
    final icon = isUp ? Icons.arrow_upward : Icons.arrow_downward;
    final tooltip = lastWeekPosition != null
        ? '${isUp ? 'Up' : 'Down'} ${movement.abs()} from #$lastWeekPosition'
        : '${isUp ? 'Up' : 'Down'} ${movement.abs()} from previous week';

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 2),
            Text(
              '${movement.abs()}',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> entry, int position) {
    final isCurrentUser = entry['artistId'] == _currentUserId;
    final movement = entry['movement'] as int? ?? 0;
    final lastWeekPosition = entry['lastWeekPosition'] as int?;

    // Responsive sizing
    final avatarSize = _getResponsiveSize(context, 56.0);
    final titleFontSize = _getResponsiveSize(context, 15.0);

    return Container(
      margin: EdgeInsets.only(bottom: _getResponsivePadding(context, 8.0)),
      decoration: BoxDecoration(
        color:
            isCurrentUser ? const Color(0xFF1B4D3E) : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border:
            isCurrentUser ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(_getResponsivePadding(context, 12.0)),
        child: Row(
          children: [
            // Position number with special styling for top 3
            _buildPositionNumber(position),
            SizedBox(width: _getResponsivePadding(context, 12.0)),

            // Avatar
            _buildAvatar(entry, avatarSize),
            SizedBox(width: _getResponsivePadding(context, 12.0)),

            // Artist info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Artist name with trending indicator
                  Row(
                    children: [
                      if (_selectedPeriod == 'weekly') ...[
                        _buildTrendingIndicator(movement, lastWeekPosition),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          entry['artistName'] ?? 'Unknown Artist',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child:
                              Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Song count
                  Text(
                    '${entry['songCount'] ?? 0} ${(entry['songCount'] ?? 0) == 1 ? 'song' : 'songs'}',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: _getResponsiveSize(context, 13.0),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Streams and stats
                  Row(
                    children: [
                      Text(
                        '${_chartService.formatStreams(entry['periodStreams'] ?? 0)}',
                        style: TextStyle(
                          color: _getStreamColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: _getResponsiveSize(context, 13.0),
                        ),
                      ),
                      Text(
                        ' streams',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: _getResponsiveSize(context, 11.0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_chartService.formatStreams(entry['totalStreams'] ?? 0)} total',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: _getResponsiveSize(context, 11.0),
                        ),
                      ),
                    ],
                  ),

                  // Weeks on chart badge
                  if (_selectedPeriod == 'weekly' &&
                      _getChartEntryText(entry).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getChartEntryColor(entry).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getChartEntryColor(entry).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getChartEntryText(entry),
                          style: TextStyle(
                            color: _getChartEntryColor(entry),
                            fontSize: _getResponsiveSize(context, 10.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> entry, double size) {
    final avatarUrl = entry['avatarUrl'] as String?;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
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
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child:
                      const Icon(Icons.person, color: Colors.white30, size: 24),
                ),
              )
            : Container(
                color: Colors.grey[800],
                child:
                    const Icon(Icons.person, color: Colors.white30, size: 24),
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
