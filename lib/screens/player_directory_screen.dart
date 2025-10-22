import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/multiplayer_player.dart';
import 'tunify_screen.dart';
import 'maple_music_screen.dart';

class PlayerDirectoryScreen extends StatefulWidget {
  const PlayerDirectoryScreen({super.key});

  @override
  State<PlayerDirectoryScreen> createState() => _PlayerDirectoryScreenState();
}

class _PlayerDirectoryScreenState extends State<PlayerDirectoryScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0; // 0=Streams, 1=Fame, 2=NetWorth
  bool _loading = false;
  List<MultiplayerPlayer> _players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() => _loading = true);
    try {
      List<MultiplayerPlayer> res = [];
      if (_tabIndex == 0) {
        res = await _service.getTopPlayersByStreams(limit: 50);
      } else if (_tabIndex == 1) {
        res = await _service.getTopPlayersByFame(limit: 50);
      } else {
        res = await _service.getTopPlayersByNetWorth(limit: 50);
      }
    
      setState(() => _players = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load players: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MultiplayerPlayer> get _filteredPlayers {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _players;
    return _players
        .where((p) => p.displayName.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _openPlatform(
      MultiplayerPlayer p, String platform) async {
    try {
      final stats = await _service.getArtistStatsForPlayer(p.id);
      if (stats == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load artist profile')),
          );
        }
        return;
      }
      if (!mounted) return;
      if (platform == 'tunify') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TunifyScreen(artistStats: stats, onStatsUpdated: (s) {}),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MapleMusicScreen(artistStats: stats, onStatsUpdated: (s) {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Players', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF21262D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlayers,
        color: const Color(0xFF00D9FF),
        backgroundColor: const Color(0xFF21262D),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 12),
            _buildTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
                    )
                  : _filteredPlayers.isEmpty
                      ? const Center(
                          child: Text('No players found', style: TextStyle(color: Colors.white54)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _filteredPlayers.length,
                          itemBuilder: (context, index) {
                            final p = _filteredPlayers[index];
                            return _buildPlayerTile(p, index + 1);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white54, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search players by name…',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: const Icon(Icons.close, color: Colors.white54, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabChip('Top Streams', 0),
          const SizedBox(width: 8),
          _buildTabChip('Top Fame', 1),
          const SizedBox(width: 8),
          _buildTabChip('Top Net Worth', 2),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int index) {
    final selected = _tabIndex == index;
    return ChoiceChip(
      selected: selected,
      label: Text(label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w600,
          )),
      selectedColor: const Color(0xFF00D9FF),
      backgroundColor: const Color(0xFF21262D),
      onSelected: (v) {
        if (v) {
          setState(() => _tabIndex = index);
          _loadPlayers();
        }
      },
    );
  }

  Widget _buildPlayerTile(MultiplayerPlayer p, int rank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D), width: 1),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Text('$rank', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          // Avatar placeholder
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00D9FF), Color(0xFF7C3AED)],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.displayName, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white54, size: 14),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        _formatNumber(p.totalStreams), 
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.stars, color: Colors.white54, size: 14),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '${p.currentFame}', 
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.attach_money, color: Colors.white54, size: 14),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        p.formattedMoney, 
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions - compact buttons
          Flexible(
            child: OutlinedButton(
              onPressed: () => _openPlatform(p, 'tunify'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1DB954),
                side: const BorderSide(color: Color(0xFF1DB954)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: const Size(60, 32),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note, size: 14),
                  const SizedBox(width: 4),
                  const Text('Tunify', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: OutlinedButton(
              onPressed: () => _openPlatform(p, 'maple'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFC3C44),
                side: const BorderSide(color: Color(0xFFFC3C44)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: const Size(60, 32),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.album_rounded, size: 14),
                  const SizedBox(width: 4),
                  const Text('Maple', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) return '${(number / 1000000000).toStringAsFixed(1)}B';
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}
