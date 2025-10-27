import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../models/nexttube_video.dart';
import '../services/nexttube_service.dart';
import 'nexttube_upload_screen.dart';
import 'nexttube_video_detail_screen.dart';

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
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF21262D),
        title: const Row(
          children: [
            Icon(Icons.ondemand_video_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('NexTube'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trending'),
            Tab(text: 'New'),
            Tab(text: 'My Videos'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildChannelHeader(),
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
        icon: const Icon(Icons.cloud_upload),
        label: const Text('Upload'),
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
          return const LinearProgressIndicator(minHeight: 2);
        }
        final ch = snapshot.data;
        final subs = ch?.subscribers ?? 0;
        final monetized = ch?.isMonetized == true || subs >= 1000;
        final rpm = ch?.rpmCents ?? 250;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            border: Border(
              bottom: BorderSide(color: Colors.white12, width: 1),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_circle, color: Colors.white70),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.artistStats.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                        '${_formatSubs(subs)} • ${monetized ? 'Monetized' : 'Not monetized'}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: monetized
                      ? const Color(0xFF32D74B).withOpacity(0.15)
                      : const Color(0xFFFFD700).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                    monetized
                        ? 'RPM: \$${(rpm / 100).toStringAsFixed(2)}'
                        : 'Goal: 1000 subs',
                    style: TextStyle(
                        color: monetized
                            ? const Color(0xFF32D74B)
                            : const Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
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
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child:
                Text('No videos yet', style: TextStyle(color: Colors.white54)),
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.white12),
          itemBuilder: (context, index) {
            final v = items[index];
            return ListTile(
              leading: _thumb(v.thumbnailUrl),
              title: Text(v.title, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                '${v.ownerName} • ${_typeLabel(v.type)} • ${_viewsLabel(v.totalViews)}',
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NextTubeVideoDetailScreen(video: v),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _thumb(String? url) {
    return Container(
      width: 80,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF30363D),
        borderRadius: BorderRadius.circular(6),
        image: url != null
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child:
          url == null ? const Icon(Icons.image, color: Colors.white38) : null,
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
