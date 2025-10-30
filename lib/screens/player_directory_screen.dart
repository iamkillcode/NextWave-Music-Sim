import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/chat_service.dart';
import '../services/poke_service.dart';
import '../models/multiplayer_player.dart';
import 'tunify_screen.dart';
import 'maple_music_screen.dart';
import 'chat_screen.dart';

class PlayerDirectoryScreen extends StatefulWidget {
  const PlayerDirectoryScreen({super.key});

  @override
  State<PlayerDirectoryScreen> createState() => _PlayerDirectoryScreenState();
}

class _PlayerDirectoryScreenState extends State<PlayerDirectoryScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirebaseService();
  final _pokeService = PokeService();
  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0; // 0=Streams, 1=Fame, 2=NetWorth
  bool _loading = false;
  List<MultiplayerPlayer> _players = [];
  Map<String, String> _pokeStatuses = {}; // userId -> status

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

  Future<void> _openPlatform(MultiplayerPlayer p, String platform) async {
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
            builder: (_) =>
                TunifyScreen(artistStats: stats, onStatsUpdated: (s) {}),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MapleMusicScreen(artistStats: stats, onStatsUpdated: (s) {}),
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

  Future<void> _handlePoke(MultiplayerPlayer p) async {
    final currentUserId = _pokeService.currentUserId;
    
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to poke')),
        );
      }
      return;
    }
    
    if (currentUserId == p.id) return;

    final success = await _pokeService.pokeUser(p.id);
    
    if (success && mounted) {
      setState(() {
        _pokeStatuses[p.id] = 'sent';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Poked ${p.displayName}! 👋'),
          backgroundColor: AppTheme.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startChat(MultiplayerPlayer p) async {
    final chatService = ChatService();
    final currentUserId = chatService.currentUserId;
    
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to send messages')),
        );
      }
      return;
    }
    
    if (currentUserId == p.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot message yourself')),
        );
      }
      return;
    }

    try {
      final conversation = await chatService.startConversation(
        otherUserId: p.id,
        otherUserName: p.displayName,
        otherUserAvatar: p.avatarUrl,
      );

      if (conversation == null && mounted) {
        // No mutual pokes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You need to poke each other first to chat! 👋'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (conversation != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversation.id,
              otherUserId: p.id,
              otherUserName: p.displayName,
              otherUserAvatar: p.avatarUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Players', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.surfaceDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlayers,
        color: AppTheme.accentBlue,
        backgroundColor: AppTheme.surfaceDark,
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
                      child:
                          CircularProgressIndicator(color: AppTheme.accentBlue),
                    )
                  : _filteredPlayers.isEmpty
                      ? const Center(
                          child: Text('No players found',
                              style: TextStyle(color: Colors.white54)),
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
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDefault),
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
          Expanded(child: _buildTabChip('Streams', 0)),
          const SizedBox(width: 6),
          Expanded(child: _buildTabChip('Fame', 1)),
          const SizedBox(width: 6),
          Expanded(child: _buildTabChip('Net Worth', 2)),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int index) {
    final selected = _tabIndex == index;
    return ChoiceChip(
      selected: selected,
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      selectedColor: AppTheme.accentBlue,
      backgroundColor: AppTheme.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      onSelected: (v) {
        if (v) {
          setState(() => _tabIndex = index);
          _loadPlayers();
        }
      },
    );
  }

  Widget _buildPlayerTile(MultiplayerPlayer p, int rank) {
    // Rank colors for top 3
    Color? rankColor;
    if (rank == 1) rankColor = AppTheme.chartGold; // Gold
    if (rank == 2) rankColor = AppTheme.chartSilver; // Silver
    if (rank == 3) rankColor = AppTheme.chartBronze; // Bronze

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rankColor ?? AppTheme.borderDefault,
          width: rankColor != null ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Rank, Avatar, Name, Stats
          Row(
            children: [
              // Rank badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rankColor?.withOpacity(0.2) ?? AppTheme.surfaceDark,
                  border: Border.all(
                    color:
                        rankColor?.withOpacity(0.6) ?? AppTheme.borderDefault,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: rankColor ?? Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Avatar with rank indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: p.avatarUrl == null
                          ? LinearGradient(
                              colors: rankColor != null
                                  ? [rankColor, rankColor.withOpacity(0.7)]
                                  : _getAvatarGradient(p.gender),
                            )
                          : null,
                      image: p.avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(p.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: rankColor != null
                          ? [
                              BoxShadow(
                                color: rankColor.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: p.avatarUrl == null
                        ? Icon(
                            _getAvatarIcon(p.gender),
                            color: Colors.white,
                            size: 28,
                          )
                        : null,
                  ),
                  // Top 3 crown badge
                  if (rank <= 3)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: rankColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.surfaceDark, width: 2),
                        ),
                        child: const Icon(Icons.emoji_events,
                            color: Colors.black, size: 12),
                      ),
                    ),
                  // Online status indicator
                  if (p.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.surfaceDark, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Name and stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        shadows: rankColor != null
                            ? [
                                Shadow(
                                    color: rankColor.withOpacity(0.5),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.rankTitle,
                      style: TextStyle(
                        color: rankColor?.withOpacity(0.9) ??
                            AppTheme.accentBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stats row - responsive layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatBadge(
                  Icons.play_circle_filled,
                  _formatNumber(p.totalStreams),
                  AppTheme.accentBlue,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatBadge(
                  Icons.star,
                  '${p.currentFame}',
                  AppTheme.chartGold,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatBadge(
                  Icons.attach_money,
                  p.formattedMoney,
                  AppTheme.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Platform buttons row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openPlatform(p, 'tunify'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successGreen,
                    side: BorderSide(color: AppTheme.successGreen),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                  icon: const Icon(Icons.music_note, size: 14),
                  label: const Text('Tunify',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openPlatform(p, 'maple'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFC3C44),
                    side: const BorderSide(color: Color(0xFFFC3C44)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                  icon: const Text('🍎', style: TextStyle(fontSize: 12)),
                  label: const Text('Maple',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 6),
              // Dynamic Poke/Chat button
              Expanded(
                child: _buildPokeOrChatButton(p),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPokeOrChatButton(MultiplayerPlayer p) {
    final currentUserId = _pokeService.currentUserId;
    
    // Can't poke yourself
    if (currentUserId == p.id) {
      return OutlinedButton.icon(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white38,
          side: BorderSide(color: Colors.white38),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        ),
        icon: const Icon(Icons.person, size: 14),
        label: const Text('You',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );
    }

    return FutureBuilder<String>(
      future: _pokeService.getPokeStatus(p.id),
      builder: (context, snapshot) {
        final status = _pokeStatuses[p.id] ?? snapshot.data ?? 'none';

        switch (status) {
          case 'mutual':
            // Can chat!
            return OutlinedButton.icon(
              onPressed: () => _startChat(p),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.neonGreen,
                side: BorderSide(color: AppTheme.neonGreen),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              icon: const Icon(Icons.chat_bubble, size: 14),
              label: const Text('Chat',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            );

          case 'sent':
            // Waiting for poke back
            return OutlinedButton.icon(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.neonPurple,
                side: BorderSide(color: AppTheme.neonPurple),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              icon: const Icon(Icons.hourglass_empty, size: 14),
              label: const Text('Poked!',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            );

          case 'received':
            // They poked you - poke back!
            return OutlinedButton.icon(
              onPressed: () => _handlePoke(p),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.chartGold,
                side: BorderSide(color: AppTheme.chartGold),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              icon: const Icon(Icons.waving_hand, size: 14),
              label: const Text('Poke Back',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            );

          default:
            // No connection yet - send poke
            return OutlinedButton.icon(
              onPressed: () => _handlePoke(p),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentBlue,
                side: BorderSide(color: AppTheme.accentBlue),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              icon: const Icon(Icons.waving_hand, size: 14),
              label: const Text('Poke',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            );
        }
      },
    );
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000000)
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  // Get avatar icon based on gender
  IconData _getAvatarIcon(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return Icons.person;
      case 'female':
        return Icons.person_outline;
      case 'other':
        return Icons.person_4;
      default:
        return Icons.person; // Default icon
    }
  }

  // Get avatar gradient based on gender
  List<Color> _getAvatarGradient(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return [AppTheme.accentBlue, const Color(0xFF0066CC)]; // Blue
      case 'female':
        return [AppTheme.neonPurple, const Color(0xFFFF1744)]; // Pink
      case 'other':
        return [AppTheme.neonPurple, const Color(0xFF4C1D95)]; // Purple
      default:
        return [
          AppTheme.accentBlue,
          AppTheme.neonPurple
        ]; // Default gradient
    }
  }
}
