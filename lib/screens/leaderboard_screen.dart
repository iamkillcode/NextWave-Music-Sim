import 'package:flutter/material.dart';
import '../models/published_song.dart';
import '../models/multiplayer_player.dart';

class LeaderboardScreen extends StatefulWidget {
  final dynamic multiplayerService;
  
  const LeaderboardScreen({
    super.key,
    required this.multiplayerService,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late dynamic _multiplayerService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _multiplayerService = widget.multiplayerService;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black for Billboard style
      body: CustomScrollView(
        slivers: [
          // Billboard-style header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF000000),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 60),
              title: const Text(
                'THE SPOTLIGHT',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.2), // Gold
                      const Color(0xFF000000),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    // "THE SPOTLIGHT" logo - clean and elegant
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "THE" text
                        Text(
                          'THE',
                          style: TextStyle(
                            color: const Color(0xFFFFD700).withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // "SPOTLIGHT" with clean underline
                        Column(
                          children: [
                            const Text(
                              'SPOTLIGHT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 200,
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFFFFD700),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'GLOBAL MUSIC CHARTS',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: const Color(0xFF000000),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFFD700),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFFFFD700),
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  tabs: const [
                    Tab(text: 'HOT 100', icon: Icon(Icons.whatshot, size: 20)),
                    Tab(text: 'TOP ARTISTS', icon: Icon(Icons.stars, size: 20)),
                    Tab(text: 'SPOTLIGHT 200', icon: Icon(Icons.library_music, size: 20)),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 260,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTopSongsTab(),
                  _buildTopArtistsTab(),
                  _buildSpotlight200Tab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSongsTab() {
    return FutureBuilder<List<PublishedSong>>(
      future: _multiplayerService.getTopSongs(limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00D9FF),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading songs',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final songs = snapshot.data ?? [];
        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off,
                  color: Colors.white30,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'No songs published yet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Be the first to publish a song!',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final rank = index + 1;
            return _buildSongCard(song, rank);
          },
        );
      },
    );
  }

  Widget _buildTopArtistsTab() {
    return FutureBuilder<List<MultiplayerPlayer>>(
      future: _multiplayerService.getTopPlayersByStreams(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00D9FF),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading artists',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final players = snapshot.data ?? [];
        if (players.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  color: Colors.white30,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'No artists yet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Join the competition!',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            final rank = index + 1;
            return _buildPlayerCard(player, rank);
          },
        );
      },
    );
  }

  Widget _buildSpotlight200Tab() {
    return FutureBuilder<List<PublishedSong>>(
      future: _multiplayerService.getTopSongs(limit: 200),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00D9FF),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading charts',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final songs = snapshot.data ?? [];
        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_music,
                  color: Colors.white30,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'No songs in the charts yet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Be the first to chart!',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final rank = index + 1;
            return _buildSongCard(song, rank);
          },
        );
      },
    );
  }

  Widget _buildSongCard(PublishedSong song, int rank) {
    // Billboard-style rank colors
    Color rankColor = Colors.white;
    if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
    if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

    final bool isTop10 = rank <= 10;
    
    // Check if song is new (released within 7 days)
    final daysOld = DateTime.now().difference(song.releaseDate).inDays;
    final bool isNew = daysOld <= 7;
    
    // Calculate demo chart stats
    final lastWeekRank = rank <= 3 ? rank + 2 : (rank <= 10 ? rank - 1 : rank + 1);
    final peakRank = rank <= 5 ? 1 : (rank <= 10 ? rank - 2 : rank - 3);
    final weeksOnChart = rank <= 3 ? 12 + (4 - rank) : (rank <= 10 ? 8 - rank + 10 : 5);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isTop10 
            ? const Color(0xFF1A1A1A)
            : Colors.black,
        border: Border(
          left: BorderSide(
            color: rank <= 3 ? rankColor : const Color(0xFFFFD700).withOpacity(0.3),
            width: rank <= 3 ? 4 : 2,
          ),
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Rank badge with trend indicator
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  if (rank == 1)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.whatshot,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    )
                  else
                    Text(
                      '$rank',
                      style: TextStyle(
                        color: rank <= 3 ? rankColor : const Color(0xFFFFD700),
                        fontSize: isTop10 ? 32 : 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Trend indicator below rank
                  _buildTrendIndicator(rank, lastWeekRank),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Genre badge with NEW flag
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: rank <= 3 
                        ? rankColor.withOpacity(0.2)
                        : const Color(0xFFFFD700).withOpacity(0.1),
                    border: Border.all(
                      color: rank <= 3 ? rankColor : const Color(0xFFFFD700).withOpacity(0.5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: rank <= 3 
                        ? [
                            BoxShadow(
                              color: rankColor.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      song.genreEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                // NEW badge for recent releases
                if (isNew)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF32D74B), Color(0xFF28A745)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF32D74B).withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Song title
                  Text(
                    song.title.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isTop10 ? 15 : 14,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  // Artist name
                  Text(
                    song.playerName,
                    style: TextStyle(
                      color: const Color(0xFFFFD700).withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Billboard-style stats row
                  Row(
                    children: [
                      // Total Streams
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STREAMS',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.play_circle_filled,
                                  color: Color(0xFF00D9FF),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatNumber(song.streams),
                                  style: const TextStyle(
                                    color: Color(0xFF00D9FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // LW (Last Week)
                      _buildChartStat('LW', '$lastWeekRank'),
                      const SizedBox(width: 8),
                      // PEAK
                      _buildChartStat('PEAK', '$peakRank'),
                      const SizedBox(width: 8),
                      // WKS (Weeks on Chart)
                      _buildChartStat('WKS', '$weeksOnChart'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(MultiplayerPlayer player, int rank) {
    // Billboard-style rank colors
    Color rankColor = Colors.white;
    if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
    if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

    final bool isTop5 = rank <= 5;
    
    // Check if artist is new (joined within 7 days)
    final daysActive = DateTime.now().difference(player.joinDate).inDays;
    final bool isNew = daysActive <= 7;
    
    // Calculate demo chart stats
    final lastWeekRank = rank <= 3 ? rank + 2 : (rank <= 10 ? rank - 1 : rank + 1);
    final peakRank = rank <= 5 ? 1 : (rank <= 10 ? rank - 2 : rank - 3);
    final weeksOnChart = rank <= 3 ? 12 + (4 - rank) : (rank <= 10 ? 8 - rank + 10 : 5);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isTop5 
            ? const Color(0xFF1A1A1A)
            : Colors.black,
        border: Border(
          left: BorderSide(
            color: rank <= 3 ? rankColor : const Color(0xFFFFD700).withOpacity(0.3),
            width: rank <= 3 ? 4 : 2,
          ),
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Rank badge with trend indicator
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  if (rank == 1)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    )
                  else
                    Text(
                      '$rank',
                      style: TextStyle(
                        color: rank <= 3 ? rankColor : const Color(0xFFFFD700),
                        fontSize: isTop5 ? 32 : 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Trend indicator below rank
                  _buildTrendIndicator(rank, lastWeekRank),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Player Avatar with NEW flag
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: rank <= 3 
                          ? [rankColor, rankColor.withOpacity(0.7)]
                          : [const Color(0xFF7C3AED), const Color(0xFFFF6B9D)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: rank <= 3 
                        ? [
                            BoxShadow(
                              color: rankColor.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                // NEW badge for recent artists
                if (isNew)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF32D74B), Color(0xFF28A745)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF32D74B).withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artist name
                  Text(
                    player.displayName.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isTop5 ? 15 : 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rank title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: rankColor.withOpacity(0.15),
                      border: Border.all(
                        color: rankColor.withOpacity(0.4),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      player.rankTitle,
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Billboard-style stats row
                  Row(
                    children: [
                      // Total Streams
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL STREAMS',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.play_circle_filled,
                                  color: Color(0xFF00D9FF),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatNumber(player.totalStreams),
                                  style: const TextStyle(
                                    color: Color(0xFF00D9FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // LW (Last Week)
                      _buildChartStat('LW', '$lastWeekRank'),
                      const SizedBox(width: 8),
                      // PEAK
                      _buildChartStat('PEAK', '$peakRank'),
                      const SizedBox(width: 8),
                      // WKS (Weeks on Chart)
                      _buildChartStat('WKS', '$weeksOnChart'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for chart stats (LW, PEAK, WKS)
  Widget _buildChartStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // Trend indicator (below rank number)
  Widget _buildTrendIndicator(int currentRank, int lastWeekRank) {
    final change = lastWeekRank - currentRank;
    
    if (change > 0) {
      // Moving up
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_upward,
            color: Color(0xFF32D74B),
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            '+$change',
            style: const TextStyle(
              color: Color(0xFF32D74B),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else if (change < 0) {
      // Moving down
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_downward,
            color: Color(0xFFFF3366),
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            '$change',
            style: const TextStyle(
              color: Color(0xFFFF3366),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      // No change
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.remove,
            color: Colors.white54,
            size: 12,
          ),
          const SizedBox(width: 2),
          const Text(
            '0',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
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
