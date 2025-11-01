import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/poke_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

/// Player search screen for finding and poking players in StarChat
class PlayerSearchScreen extends StatefulWidget {
  const PlayerSearchScreen({super.key});

  @override
  State<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PokeService _pokeService = PokeService();
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, String> _pokeStatuses = {}; // userId -> status
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlayers(String query) async {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Fetch a batch of players (limit 50 for performance)
      final snapshot = await FirebaseFirestore.instance
          .collection('players')
          .limit(50)
          .get();

      final results = <Map<String, dynamic>>[];
      final statuses = <String, String>{};

      for (final doc in snapshot.docs) {
        if (doc.id == currentUserId) continue; // Skip self
        final data = doc.data();
        final displayName = (data['displayName'] ?? '').toString();
        // Keyword and case-insensitive match
        if (displayName.toLowerCase().contains(keyword)) {
          results.add({
            'id': doc.id,
            'name': displayName,
            'fame': data['fame'] ?? 0,
            'region': data['currentRegion'] ?? 'Unknown',
            'primaryGenre': data['primaryGenre'] ?? 'Unknown',
            'avatarUrl': data['avatarUrl'],
          });

          // Get poke status for each player
          final status = await _pokeService.getPokeStatus(doc.id);
          statuses[doc.id] = status;
        }
      }

      setState(() {
        _searchResults = results;
        _pokeStatuses = statuses;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Search failed: $e')),
        );
      }
    }
  }

  Future<void> _handlePoke(Map<String, dynamic> player) async {
    try {
      await _pokeService.pokeUser(player['id']);

      // Update local status
      setState(() {
        _pokeStatuses[player['id']] = 'sent';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('👋 Poked ${player['name']}!'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to poke: $e')),
        );
      }
    }
  }

  Future<void> _startChat(Map<String, dynamic> player) async {
    try {
      final conversation = await _chatService.startConversation(
        otherUserId: player['id'],
        otherUserName: player['name'],
      );

      if (conversation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ You need to poke each other first to chat! 👋'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              otherUserId: player['id'],
              otherUserName: player['name'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.neonGreen, AppTheme.neonPurple],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_search,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Find Players',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppTheme.surfaceDark,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchPlayers,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by player name...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: AppTheme.neonGreen),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _searchPlayers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Search results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.neonGreen),
            const SizedBox(height: 16),
            const Text(
              'Searching...',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.neonGreen.withOpacity(0.2),
                    AppTheme.neonPurple.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search,
                size: 64,
                color: AppTheme.neonGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Search for players',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type a player name to start',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No players found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildPlayerCard(_searchResults[index]);
      },
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final pokeStatus = _pokeStatuses[player['id']] ?? 'none';

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: player['avatarUrl'] == null
                        ? const LinearGradient(
                            colors: [AppTheme.neonGreen, AppTheme.neonPurple],
                          )
                        : null,
                    shape: BoxShape.circle,
                    image: player['avatarUrl'] != null
                        ? DecorationImage(
                            image: NetworkImage(player['avatarUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: player['avatarUrl'] == null
                      ? Center(
                          child: Text(
                            player['name'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Player info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${player['fame']} Fame',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on,
                            color: AppTheme.neonGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              player['region'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.music_note,
                            color: AppTheme.neonPurple,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            player['primaryGenre'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildPokeOrChatButton(player, pokeStatus),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokeOrChatButton(
      Map<String, dynamic> player, String pokeStatus) {
    switch (pokeStatus) {
      case 'mutual':
        return ElevatedButton.icon(
          onPressed: () => _startChat(player),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.neonGreen,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.chat_bubble),
          label: const Text(
            'Chat',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );

      case 'sent':
        return ElevatedButton.icon(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.neonPurple.withOpacity(0.3),
            foregroundColor: AppTheme.neonPurple,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.hourglass_empty),
          label: const Text(
            'Poked!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );

      case 'received':
        return ElevatedButton.icon(
          onPressed: () => _handlePoke(player),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.waving_hand),
          label: const Text(
            'Poke Back',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );

      default: // 'none'
        return ElevatedButton.icon(
          onPressed: () => _handlePoke(player),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.waving_hand),
          label: const Text(
            'Poke',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
    }
  }
}
