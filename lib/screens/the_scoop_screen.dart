import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/news_item.dart';
import '../services/the_scoop_service.dart';
import 'unified_charts_screen.dart';

class TheScoopScreen extends StatefulWidget {
  const TheScoopScreen({super.key});

  @override
  State<TheScoopScreen> createState() => _TheScoopScreenState();
}

class _TheScoopScreenState extends State<TheScoopScreen> {
  final TheScoopService _newsService = TheScoopService();
  NewsCategory? _selectedCategory;

  // Editorial content
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _todaysHits = [];
  Map<String, dynamic>? _weeklyTopSong;
  Map<String, dynamic>? _weeklyTopAlbum;
  Map<String, dynamic>? _weeklyTopArtist;
  List<Map<String, dynamic>> _newThisWeek = [];
  Map<String, dynamic>? _highestDebut;
  Map<String, dynamic>? _biggestMover;

  @override
  void initState() {
    super.initState();
    _loadEditorial();
  }

  Future<void> _loadEditorial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _newsService.getTodaysHits(limit: 4),
        _newsService.getWeeklyTopSong(),
        _newsService.getWeeklyTopAlbum(),
        _newsService.getWeeklyTopArtist(),
        _newsService.getNewThisWeek(limit: 12),
        _newsService.getHighestDebutSong(),
        // Biggest mover is optional; ignore errors per-section
        _newsService.getBiggestMoverSong().catchError((_) => null),
      ]);
      setState(() {
        _todaysHits = (results[0] as List<Map<String, dynamic>>);
        _weeklyTopSong = results[1] as Map<String, dynamic>?;
        _weeklyTopAlbum = results[2] as Map<String, dynamic>?;
        _weeklyTopArtist = results[3] as Map<String, dynamic>?;
        _newThisWeek = (results[4] as List<Map<String, dynamic>>);
        _highestDebut = results[5] as Map<String, dynamic>?;
        _biggestMover = results[6] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Row(
          children: [
            Text('📰', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('The Scoop', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFFF44336),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showCategoryFilter,
            tooltip: 'Filter by category',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadEditorial();
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: ${_error ?? ''}', style: const TextStyle(color: Colors.redAccent)),
                ),
              )
            else ...[
              if (_weeklyTopArtist != null)
                SliverToBoxAdapter(child: _buildHeroBanner()),
              if (_todaysHits.isNotEmpty)
                SliverToBoxAdapter(child: _buildSectionTitle("Today's Hits")),
              if (_todaysHits.isNotEmpty)
                SliverToBoxAdapter(child: _buildHorizontalCovers(
                  _todaysHits,
                  deepLinkPeriod: 'daily',
                  deepLinkType: 'singles',
                )),
              if (_weeklyTopSong != null)
                SliverToBoxAdapter(child: _buildFeaturedStory()),
              if (_newThisWeek.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildSectionTitle('New This Week')),
                SliverToBoxAdapter(child: _buildHorizontalCovers(
                  _newThisWeek,
                  deepLinkPeriod: 'weekly',
                  deepLinkType: 'singles',
                )),
              ],
              // Info cards like screenshot 2
              if (_weeklyTopArtist != null)
                SliverToBoxAdapter(child: _buildInfoCard(
                  title: 'Most Streamed Artist',
                  imageUrl: _weeklyTopArtist!['avatarUrl'],
                  headline: (_weeklyTopArtist!['artistName'] ?? 'Unknown') +
                      ' led this week with ' +
                      _newsService.shortStreams((_weeklyTopArtist!['periodStreams'] ?? _weeklyTopArtist!['streams'] ?? 0) as int) +
                      ' streams.',
                  onTap: () => _openArtistDetails(_weeklyTopArtist!),
                )),
              if (_weeklyTopAlbum != null)
                SliverToBoxAdapter(child: _buildInfoCard(
                  title: 'Top Album This Week',
                  imageUrl: _weeklyTopAlbum!['coverArtUrl'],
                  headline: (_weeklyTopSong?['artist'] ?? _weeklyTopAlbum!['artist'] ?? 'Unknown') +
                      ' earned the top album this week with ' +
                      (_weeklyTopAlbum!['title'] ?? 'Untitled') + ', accumulating ' +
                      _newsService.shortStreams((_weeklyTopAlbum!['periodStreams'] ?? 0) as int) +
                      ' streams.',
                  onTap: () => _openSongDetails(_weeklyTopAlbum!),
                )),
              if (_highestDebut != null)
                SliverToBoxAdapter(child: _buildInfoCard(
                  title: 'Highest Debut',
                  imageUrl: _highestDebut!['coverArtUrl'],
                  headline: '"${(_highestDebut!['title'] ?? 'Untitled') as String}" by ${(_highestDebut!['artist'] ?? 'Unknown') as String} debuts at #${_highestDebut!['position'] ?? 0} on this week\'s chart.',
                  onTap: () => _openSongDetails(_highestDebut!),
                )),
              if (_biggestMover != null)
                SliverToBoxAdapter(child: _buildInfoCard(
                  title: 'Biggest Mover',
                  imageUrl: _biggestMover!['coverArtUrl'],
                  headline: '"${(_biggestMover!['title'] ?? 'Untitled') as String}" by ${(_biggestMover!['artist'] ?? 'Unknown') as String} jumps ${((_biggestMover!['movement'] ?? 0) as int).abs()} spots to #${_biggestMover!['position'] ?? 0}.',
                  onTap: () => _openSongDetails(_biggestMover!),
                )),
              SliverToBoxAdapter(child: _buildSectionDivider()),
              // News stream below editorial
              if (_selectedCategory != null)
                SliverToBoxAdapter(child: _buildCategoryChip()),
              SliverFillRemaining(
                hasScrollBody: true,
                child: _buildNewsFeed(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Divider(color: Colors.white12, height: 1),
      );

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildHeroBanner() {
    final artist = _weeklyTopArtist!;
    final name = artist['artistName'] ?? 'Unknown';
    final avatar = artist['avatarUrl'];
    final bg = avatar ?? '';
    return GestureDetector(
      onTap: () => _openArtistDetails(artist),
      child: Container(
      height: 180,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: bg.isNotEmpty
              ? CachedNetworkImageProvider(bg)
              : const AssetImage('assets/icon/app_icon.png') as ImageProvider,
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(Colors.black.withOpacity(0.35), BlendMode.darken),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'is #1 this week',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildHorizontalCovers(
    List<Map<String, dynamic>> items, {
    String? deepLinkPeriod,
    String? deepLinkType,
  }) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, i) {
          final item = items[i];
          final img = item['coverArtUrl'];
          final title = (item['title'] ?? '') as String;
          final artist = (item['artist'] ?? '') as String;
          return SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _openSongDetails(
                    item,
                    preferredPeriod: deepLinkPeriod,
                    preferredType: deepLinkType,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.white10,
                      height: 100,
                      width: 120,
                      child: img != null
                          ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover)
                          : const Image(
                              image: AssetImage('assets/icon/app_icon.png'),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildFeaturedStory() {
    final s = _weeklyTopSong!;
    final streams = (s['periodStreams'] ?? 0) as int;
    final img = s['coverArtUrl'];
    return GestureDetector(
      onTap: () => _openSongDetails(s),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (s['title'] ?? 'Untitled') as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.white10,
              height: 180,
              width: double.infinity,
        child: img != null
                  ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover)
          : const Image(
            image: AssetImage('assets/icon/app_icon.png'),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${s['artist'] ?? 'Unknown'} is #1 this week with ${(s['title'] ?? 'this track')}, accumulating ${_newsService.shortStreams(streams)} streams.',
            style: const TextStyle(color: Colors.white70, height: 1.6),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String? imageUrl, required String headline, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.white10,
              width: 90,
              height: 90,
        child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
          : const Image(
            image: AssetImage('assets/icon/app_icon.png'),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  headline,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  // Detail sheets
  void _openSongDetails(Map<String, dynamic> item, {String? preferredPeriod, String? preferredType}) {
    final isAlbum = (item['isAlbum'] as bool?) ?? false;
    final title = (item['title'] ?? (isAlbum ? 'Untitled Album' : 'Untitled')) as String;
    final artist = (item['artist'] ?? 'Unknown') as String;
    final cover = item['coverArtUrl'] as String?;
    final streams = (item['periodStreams'] ?? item['streams'] ?? 0) as int;
    final pos = item['position'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.white10,
                    child: cover != null
                        ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover)
                        : const Image(image: AssetImage('assets/icon/app_icon.png'), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(artist, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('${isAlbum ? 'Album' : 'Song'} • ${_newsService.shortStreams(streams)} streams', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      if (pos != null) Text('Chart position: #$pos', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final isAlbum = (item['isAlbum'] as bool?) ?? false;
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnifiedChartsScreen(
                          initialPeriod: preferredPeriod ?? 'weekly',
                          initialType: preferredType ?? (isAlbum ? 'albums' : 'singles'),
                          initialRegion: 'global',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View on Charts'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _openArtistDetails(Map<String, dynamic> artist) {
    final name = (artist['artistName'] ?? artist['artist'] ?? 'Unknown') as String;
    final avatar = artist['avatarUrl'] as String?;
    final streams = (artist['periodStreams'] ?? artist['streams'] ?? 0) as int;
    final released = artist['releasedSongs'] as int?;
    final charting = artist['chartingSongs'] as int?;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.white10,
                    child: avatar != null
                        ? CachedNetworkImage(imageUrl: avatar, fit: BoxFit.cover)
                        : const Image(image: AssetImage('assets/icon/app_icon.png'), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('This week: ${_newsService.shortStreams(streams)} streams', style: const TextStyle(color: Colors.white70)),
                      if (released != null || charting != null)
                        Text('Songs: ${released ?? '-'} • Charting: ${charting ?? '-'}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UnifiedChartsScreen(
                          initialPeriod: 'weekly',
                          initialType: 'artists',
                          initialRegion: 'global',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View on Charts'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breaking Music News',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your exclusive source for industry gossip',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF44336),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip() {
    // Create a temp NewsItem to get category display info
    final tempNews = NewsItem(
      id: '',
      headline: '',
      body: '',
      category: _selectedCategory!,
      timestamp: DateTime.now(),
    );
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Chip(
            avatar: Text(tempNews.getCategoryEmoji()),
            label: Text(tempNews.getCategoryName()),
            backgroundColor: Color(tempNews.getCategoryColorValue()).withOpacity(0.2),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() {
                _selectedCategory = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewsFeed() {
    final stream = _selectedCategory != null
        ? _newsService.getNewsByCategory(_selectedCategory!)
        : _newsService.getNewsStream();

    return StreamBuilder<List<NewsItem>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading news',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        final newsItems = snapshot.data ?? [];

        if (newsItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📰', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'No news yet',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back soon for breaking stories!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: newsItems.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildNewsCard(newsItems[index]);
          },
        );
      },
    );
  }

  Widget _buildNewsCard(NewsItem news) {
    final categoryColor = Color(news.getCategoryColorValue());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showNewsDetail(news),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category and timestamp
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(news.getCategoryEmoji(), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          news.getCategoryName().toUpperCase(),
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _newsService.formatTimestamp(news.timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Headline
              Text(
                news.headline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              // Body preview
              Text(
                news.body,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              // Related artist badge
              if (news.relatedArtistName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      news.relatedArtistName!,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showNewsDetail(NewsItem news) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final categoryColor = Color(news.getCategoryColorValue());
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(news.getCategoryEmoji(), style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              news.getCategoryName().toUpperCase(),
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _newsService.formatTimestamp(news.timestamp),
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    news.headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  if (news.relatedArtistName != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person, size: 18, color: categoryColor),
                        const SizedBox(width: 6),
                        Text(
                          news.relatedArtistName!,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    news.body,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Share this story',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildShareButton(Icons.share, 'Share'),
                      const SizedBox(width: 12),
                      _buildShareButton(Icons.bookmark_border, 'Save'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShareButton(IconData icon, String label) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label feature coming soon!')),
          );
        },
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: BorderSide(color: Colors.grey[700]!),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🌟', style: TextStyle(fontSize: 24)),
                title: const Text('All News', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ...NewsCategory.values.map((category) {
                final newsItem = NewsItem(
                  id: '',
                  headline: '',
                  body: '',
                  category: category,
                  timestamp: DateTime.now(),
                );
                return ListTile(
                  leading: Text(newsItem.getCategoryEmoji(), style: const TextStyle(fontSize: 24)),
                  title: Text(
                    newsItem.getCategoryName(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
