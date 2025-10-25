import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/firestore_sanitizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artist_stats.dart';
import 'echox_comments_screen.dart';
import '../services/firebase_service.dart';
import 'tunify_screen.dart';
import 'maple_music_screen.dart';

class EchoPost {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int echoes; // Retweets/shares
  final int comments; // Comment count
  final List<String> likedBy;

  EchoPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.echoes = 0,
    this.comments = 0,
    this.likedBy = const [],
  });

  factory EchoPost.fromFirestore(Map<String, dynamic> data, String id) {
    return EchoPost(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown Artist',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      echoes: data['echoes'] ?? 0,
      comments: data['comments'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'echoes': echoes,
      'comments': comments,
      'likedBy': likedBy,
    };
  }
}

class EchoComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime timestamp;
  final int likes;
  final List<String> likedBy;

  EchoComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.likedBy = const [],
  });

  factory EchoComment.fromFirestore(Map<String, dynamic> data, String id) {
    return EchoComment(
      id: id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown Artist',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'likedBy': likedBy,
    };
  }
}

class EchoXScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const EchoXScreen({
    super.key,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<EchoXScreen> createState() => _EchoXScreenState();
}

class _EchoXScreenState extends State<EchoXScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ArtistStats _currentStats;
  final TextEditingController _postController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentStats = widget.artistStats;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D9FF), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EchoX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Artist Social Network',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D9FF),
          indicatorWeight: 3,
          labelColor: const Color(0xFF00D9FF),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'FEED', icon: Icon(Icons.dynamic_feed, size: 18)),
            Tab(text: 'MY POSTS', icon: Icon(Icons.person, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(),
          _buildMyPostsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostDialog,
        backgroundColor: const Color(0xFF00D9FF),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'POST',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('echox_posts')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading feed',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data?.docs
                .map((doc) => EchoPost.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ))
                .toList() ??
            [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔊', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  'No posts yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Be the first to post on EchoX!',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(posts[index]);
          },
        );
      },
    );
  }

  Widget _buildMyPostsTab() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(
        child: Text(
          'Sign in to see your posts',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('echox_posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
          );
        }

        final posts = snapshot.data?.docs
                .map((doc) => EchoPost.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ))
                .toList() ??
            [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📝', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  'No posts yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share your journey with fans!',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(posts[index], showDelete: true);
          },
        );
      },
    );
  }

  Widget _buildPostCard(EchoPost post, {bool showDelete = false}) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = userId != null && post.likedBy.contains(userId);
    final isMyPost = userId == post.authorId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info
          Row(
            children: [
              // Make avatar tappable to view artist platforms
              GestureDetector(
                onTap: () =>
                    _showViewArtistOptions(post.authorId, post.authorName),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMyPost
                          ? [const Color(0xFF00D9FF), const Color(0xFF7C3AED)]
                          : [Colors.grey.shade700, Colors.grey.shade800],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _showViewArtistOptions(post.authorId, post.authorName),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isMyPost) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF00D9FF),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatTimestamp(post.timestamp),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showDelete && isMyPost)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deletePost(post.id),
                ),
              // Quick action to open platforms
              IconButton(
                tooltip: 'View platforms',
                icon: const Icon(Icons.open_in_new, color: Colors.white70),
                onPressed: () =>
                    _showViewArtistOptions(post.authorId, post.authorName),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Post content
          Text(
            post.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Interaction buttons
          Row(
            children: [
              _buildInteractionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                count: post.likes,
                color: isLiked ? Colors.red : Colors.white54,
                onTap: () => _toggleLike(post),
              ),
              const SizedBox(width: 24),
              _buildInteractionButton(
                icon: Icons.chat_bubble_outline,
                count: post.comments,
                color: Colors.white54,
                onTap: () => _navigateToComments(post),
              ),
              const SizedBox(width: 24),
              _buildInteractionButton(
                icon: Icons.repeat,
                count: post.echoes,
                color: Colors.white54,
                onTap: () => _echoPost(post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Text(
              _formatCount(count),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPostDialog() {
    if (_currentStats.energy < 5) {
      _showMessage('❌ Need at least 5 energy to post!');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16181C),
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Color(0xFF00D9FF)),
            SizedBox(width: 8),
            Text(
              'Create Post',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _postController,
                maxLines: 4,
                maxLength: 280,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "What's happening in your music career?",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00D9FF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00D9FF), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00D9FF)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF00D9FF), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cost: 5 Energy • Gain: +1 Fame, +2 Hype',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: _isPosting ? null : _createPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
            ),
            child: _isPosting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text('POST'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) {
      _showMessage('❌ Post cannot be empty!');
      return;
    }

    if (_currentStats.energy < 5) {
      _showMessage('❌ Not enough energy to post!');
      return;
    }

    setState(() => _isPosting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      final post = EchoPost(
        id: '',
        authorId: user.uid,
        authorName: _currentStats.name,
        content: content,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('echox_posts')
          .add(post.toFirestore());

      // Update stats
      _currentStats = _currentStats.copyWith(
        energy: _currentStats.energy - 5,
        fame: _currentStats.fame + 1,
        creativity: _currentStats.creativity + 2,
        lastActivityDate: DateTime.now(), // ✅ Update activity for fame decay
      );
      widget.onStatsUpdated(_currentStats);

      _postController.clear();
      if (mounted) {
        Navigator.pop(context);
        _showMessage('📢 Posted on EchoX! +1 Fame, +2 Hype');
      }
    } catch (e) {
      _showMessage('❌ Failed to post: $e');
    } finally {
      setState(() => _isPosting = false);
    }
  }

  Future<void> _toggleLike(EchoPost post) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final isLiked = post.likedBy.contains(userId);
    final newLikedBy = List<String>.from(post.likedBy);

    if (isLiked) {
      newLikedBy.remove(userId);
    } else {
      newLikedBy.add(userId);
    }

    try {
      await FirebaseFirestore.instance
          .collection('echox_posts')
          .doc(post.id)
          .update(sanitizeForFirestore({
            'likes': isLiked ? post.likes - 1 : post.likes + 1,
            'likedBy': newLikedBy,
          }));
    } catch (e) {
      _showMessage('❌ Failed to like post');
    }
  }

  Future<void> _echoPost(EchoPost post) async {
    if (_currentStats.energy < 3) {
      _showMessage('❌ Need 3 energy to echo!');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('echox_posts')
          .doc(post.id)
          .update(sanitizeForFirestore({
            'echoes': post.echoes + 1,
          }));

      _currentStats = _currentStats.copyWith(
        energy: _currentStats.energy - 3,
        fame: _currentStats.fame + 1,
        lastActivityDate: DateTime.now(), // ✅ Update activity for fame decay
      );
      widget.onStatsUpdated(_currentStats);

      _showMessage('🔁 Echoed! +1 Fame');
    } catch (e) {
      _showMessage('❌ Failed to echo');
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('echox_posts')
          .doc(postId)
          .delete();
      _showMessage('🗑️ Post deleted');
    } catch (e) {
      _showMessage('❌ Failed to delete');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${timestamp.month}/${timestamp.day}';
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  void _navigateToComments(EchoPost post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EchoXCommentsScreen(
          post: post,
          artistStats: _currentStats,
          onStatsUpdated: (updatedStats) {
            setState(() {
              _currentStats = updatedStats;
            });
            widget.onStatsUpdated(updatedStats);
          },
        ),
      ),
    );

    // Refresh if stats were updated
    if (result != null && mounted) {
      setState(() {});
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF16181C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show options to view the author's platform pages and navigate after loading stats
  void _showViewArtistOptions(String playerId, String authorName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(builder: (context, setModalState) {
          Future<void> openFor(String platform) async {
            if (isLoading) return;
            setModalState(() => isLoading = true);
            try {
              final stats =
                  await FirebaseService().getArtistStatsForPlayer(playerId);
              if (stats == null) {
                if (mounted)
                  _showMessage('⚠️ Could not load $authorName\'s profile');
                return;
              }
              if (!mounted) return;
              Navigator.pop(context); // close sheet first
              if (platform == 'tunify') {
                // Open Tunify
                // Read-only view: pass a no-op onStatsUpdated
                // ignore: use_build_context_synchronously
                Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (ctx) => TunifyScreen(
                      artistStats: stats,
                      onStatsUpdated: (s) {},
                    ),
                  ),
                );
              } else if (platform == 'maple') {
                // ignore: use_build_context_synchronously
                Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (ctx) => MapleMusicScreen(
                      artistStats: stats,
                      onStatsUpdated: (s) {},
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) _showMessage('❌ Failed to open: $e');
            } finally {
              setModalState(() => isLoading = false);
            }
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'View $authorName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Open on streaming platforms',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      const Icon(Icons.music_note, color: Color(0xFF1DB954)),
                  title: const Text('Tunify',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('Spotify-style profile',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: () => openFor('tunify'),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.album_rounded, color: Color(0xFFFC3C44)),
                  title: const Text('Maple Music',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('Apple Music-style profile',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: () => openFor('maple'),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
