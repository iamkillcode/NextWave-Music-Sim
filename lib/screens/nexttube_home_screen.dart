import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/nexttube_video.dart';
import '../services/nexttube_service.dart';
import 'nexttube_upload_screen.dart';
import 'nexttube_video_detail_screen.dart';
import '../theme/app_theme.dart';

class NextTubeHomeScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const NextTubeHomeScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<NextTubeHomeScreen> createState() => _NextTubeHomeScreenState();
}

class _NextTubeHomeScreenState extends State<NextTubeHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = NextTubeService();
  Future<List<NextTubeVideo>>? _trendingFuture;
  Future<List<NextTubeVideo>>? _newFuture;
  Future<List<NextTubeVideo>>? _myFuture;
  late Future<dynamic> _channelFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  void _load() {
    setState(() {
      _trendingFuture = _service.fetchTrending(limit: 25);
      _newFuture = _service.fetchNew(limit: 25);
      _myFuture = _service.fetchMyVideos(limit: 50);
      _channelFuture = _service.getOrCreateMyChannel();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        title: Row(
          children: [
            // YouTube-style NexTube logo
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.play_arrow, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'NexTube',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.video_call, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NextTubeUploadScreen(
                    artistStats: widget.artistStats,
                    onStatsUpdated: widget.onStatsUpdated,
                  ),
                ),
              );
              _load();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildChannelHeader(),
          // YouTube-style tab bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderDefault, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.errorRed,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              tabs: const [
                Tab(text: 'Trending'),
                Tab(text: 'New'),
                Tab(text: 'My Videos'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_trendingFuture),
                _buildList(_newFuture),
                _buildList(_myFuture),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.errorRed,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Upload', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NextTubeUploadScreen(
                artistStats: widget.artistStats,
                onStatsUpdated: widget.onStatsUpdated,
              ),
            ),
          );
          _load();
        },
      ),
    );
  }

  Widget _buildChannelHeader() {
    return FutureBuilder(
      future: _channelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: AppTheme.backgroundDark,
            color: AppTheme.errorRed,
          );
        }
        final ch = snapshot.data;
        final subs = ch?.subscribers ?? 0;
        final monetized = ch?.isMonetized == true || subs >= 1000;
        final rpm = ch?.rpmCents ?? 250;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderDefault, width: 1),
            ),
          ),
          child: Row(
            children: [
              // YouTube-style channel avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.errorRed, width: 2),
                ),
                child: Icon(Icons.person, color: AppTheme.errorRed, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.artistStats.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatSubs(subs),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(' • ', style: TextStyle(color: Colors.white38)),
                        Icon(
                          monetized ? Icons.monetization_on : Icons.lock,
                          color: monetized ? AppTheme.neonGreen : Colors.white38,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          monetized ? 'Monetized' : 'Not monetized',
                          style: TextStyle(
                            color: monetized ? AppTheme.neonGreen : Colors.white38,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: monetized
                      ? AppTheme.neonGreen.withOpacity(0.15)
                      : AppTheme.chartGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: monetized ? AppTheme.neonGreen : AppTheme.chartGold,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  monetized
                      ? 'RPM: \$${(rpm / 100).toStringAsFixed(2)}'
                      : '${subs}/1000',
                  style: TextStyle(
                    color: monetized ? AppTheme.neonGreen : AppTheme.chartGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatSubs(int subs) {
    if (subs >= 1000000) return '${(subs / 1000000).toStringAsFixed(1)}M subs';
    if (subs >= 1000) return '${(subs / 1000).toStringAsFixed(1)}K subs';
    return '$subs subs';
  }

  Widget _buildList(Future<List<NextTubeVideo>>? future) {
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<List<NextTubeVideo>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.errorRed),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, color: Colors.white24, size: 64),
                const SizedBox(height: 16),
                Text(
                  'No videos yet',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final v = items[index];
            return _buildYouTubeVideoCard(v, context);
          },
        );
      },
    );
  }

  Widget _buildYouTubeVideoCard(NextTubeVideo v, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NextTubeVideoDetailScreen(video: v),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // YouTube-style thumbnail
            _buildYouTubeThumbnail(v.thumbnailUrl, v.type),
            const SizedBox(width: 12),
            // Video info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    v.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Metadata
                  Text(
                    v.ownerName,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _viewsLabel(v.totalViews),
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      Text(' • ', style: TextStyle(color: Colors.white38)),
                      _buildTypeChip(v.type),
                    ],
                  ),
                ],
              ),
            ),
            // Options menu
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white70, size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouTubeThumbnail(String? url, NextTubeVideoType type) {
    return Stack(
      children: [
        Container(
          width: 160,
          height: 90,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            image: url != null
                ? DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: url == null
              ? Icon(Icons.image, color: Colors.white24, size: 40)
              : null,
        ),
        // Play overlay
        if (url != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        // Video type badge
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _typeLabel(type),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(NextTubeVideoType type) {
    Color color;
    IconData icon;
    
    switch (type) {
      case NextTubeVideoType.official:
        color = AppTheme.errorRed;
        icon = Icons.play_circle_filled;
        break;
      case NextTubeVideoType.lyrics:
        color = AppTheme.accentBlue;
        icon = Icons.text_fields;
        break;
      case NextTubeVideoType.live:
        color = AppTheme.neonPurple;
        icon = Icons.live_tv;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            _typeLabel(type),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(NextTubeVideoType t) {
    switch (t) {
      case NextTubeVideoType.official:
        return 'Official';
      case NextTubeVideoType.lyrics:
        return 'Lyrics';
      case NextTubeVideoType.live:
        return 'Live';
    }
  }

  String _viewsLabel(int views) {
    if (views >= 1000000)
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K views';
    return '$views views';
  }
}
