import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/firestore_sanitizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artist_stats.dart';
import 'echox_comments_screen.dart';
import 'echox_composer_screen.dart';
import 'echox_profile_screen.dart';
import '../services/firebase_service.dart';
import 'tunify_screen.dart';
import 'maple_music_screen.dart';

class EchoPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? avatarUrl;
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
    this.avatarUrl,
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
      avatarUrl: data['avatarUrl'] as String?,
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
      'avatarUrl': avatarUrl,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'echoes': echoes,
      'comments': comments,
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
      backgroundColor: const Color(0xFF0A0E14), // Darker background
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: const Color(0xFF0A0E14),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  // Animated gradient bolt icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00CED1), Color(0xFF20B2AA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00CED1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.bolt, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'EchoX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'What\'s trending in music?',
                        style: TextStyle(
                          color: Color(0xFF00CED1),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF00CED1),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF00CED1),
                    unselectedLabelColor: Colors.white38,
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'For You'),
                      Tab(text: 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00CED1), Color(0xFF20B2AA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00CED1).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showPostDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.create, color: Colors.white),
          label: const Text(
            'POST',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00CED1), Color(0xFF20B2AA)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00CED1).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Loading feed...',
                  style: TextStyle(
                    color: Color(0xFF00CED1),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1419),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load feed',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
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
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1419),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00CED1).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00CED1).withOpacity(0.2),
                          const Color(0xFF20B2AA).withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt,
                      size: 64,
                      color: Color(0xFF00CED1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to EchoX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Be the first to share your music journey!\nTap the POST button to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
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

  Widget _buildProfileTab() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(
        child: Text(
          'Sign in to see your profile',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return EchoXProfileScreen(
      userId: userId,
      artistStats: _currentStats,
      onStatsUpdated: (updatedStats) {
        setState(() {
          _currentStats = updatedStats;
        });
        widget.onStatsUpdated(updatedStats);
      },
      isOwnProfile: true,
    );
  }

  Widget _buildPostCard(EchoPost post, {bool showDelete = false}) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = userId != null && post.likedBy.contains(userId);
    final isMyPost = userId == post.authorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToComments(post),
          splashColor: const Color(0xFF00CED1).withOpacity(0.05),
          highlightColor: const Color(0xFF00CED1).withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                GestureDetector(
                  onTap: () =>
                      _showViewArtistOptions(post.authorId, post.authorName),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: post.avatarUrl == null
                          ? LinearGradient(
                              colors: isMyPost
                                  ? [
                                      const Color(0xFF00CED1),
                                      const Color(0xFF20B2AA)
                                    ]
                                  : [
                                      const Color(0xFF2C3440),
                                      const Color(0xFF1C2128)
                                    ],
                            )
                          : null,
                      color: post.avatarUrl != null ? Colors.grey[800] : null,
                      shape: BoxShape.circle,
                      boxShadow: isMyPost
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00CED1).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                      image: post.avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(post.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: post.avatarUrl == null
                        ? Center(
                            child: Text(
                              post.authorName.isNotEmpty
                                  ? post.authorName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author info row
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () => _showViewArtistOptions(
                                  post.authorId, post.authorName),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      post.authorName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (isMyPost) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      color: Color(0xFF00CED1),
                                      size: 18,
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Text(
                                    '@${post.authorName.toLowerCase().replaceAll(' ', '')}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '· ${_formatTimestamp(post.timestamp)}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (showDelete && isMyPost)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                              onPressed: () => _deletePost(post.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Post content
                      _buildPostContentWithMentions(post.content),
                      const SizedBox(height: 12),
                      // Interaction buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInteractionButton(
                            icon: Icons.chat_bubble_outline,
                            count: post.comments,
                            color: Colors.white.withOpacity(0.6),
                            activeColor: const Color(0xFF00CED1),
                            onTap: () => _navigateToComments(post),
                          ),
                          _buildInteractionButton(
                            icon: Icons.repeat_rounded,
                            count: post.echoes,
                            color: Colors.white.withOpacity(0.6),
                            activeColor: const Color(0xFF00FF7F),
                            onTap: () => _echoPost(post),
                          ),
                          _buildInteractionButton(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            count: post.likes,
                            color: Colors.white.withOpacity(0.6),
                            activeColor: const Color(0xFFFF1493),
                            isActive: isLiked,
                            onTap: () => _toggleLike(post),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.open_in_new,
                              color: Colors.white.withOpacity(0.6),
                              size: 18,
                            ),
                            onPressed: () => _showViewArtistOptions(
                                post.authorId, post.authorName),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    required Color color,
    Color? activeColor,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    final displayColor = isActive && activeColor != null ? activeColor : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: displayColor, size: 18),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                _formatCount(count),
                style: TextStyle(
                  color: displayColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPostDialog() {
    if (_currentStats.energy < 5) {
      _showMessage('❌ Need at least 5 energy to post!');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EchoXComposerScreen(
          artistStats: _currentStats,
          onPost: (content, {trackId, albumId}) async {
            await _createPostWithContent(content,
                trackId: trackId, albumId: albumId);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _createPostWithContent(String content,
      {String? trackId, String? albumId}) async {
    if (content.isEmpty) {
      _showMessage('❌ Post cannot be empty!');
      return;
    }

    if (_currentStats.energy < 5) {
      _showMessage('❌ Not enough energy to post!');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      // Parse @ mentions
      final mentionedUsers = _extractMentions(content);

      final post = EchoPost(
        id: '',
        authorId: user.uid,
        authorName: _currentStats.name,
        avatarUrl: _currentStats.avatarUrl,
        content: content,
        timestamp: DateTime.now(),
      );

      // Create post document
      final postData = post.toFirestore();
      postData['mentionedUsers'] = mentionedUsers;
      if (trackId != null) postData['attachedTrackId'] = trackId;
      if (albumId != null) postData['attachedAlbumId'] = albumId;

      await FirebaseFirestore.instance.collection('echox_posts').add(postData);

      // Update stats
      final hypeGain = _currentStats.hypeFromPost; // 8 hype per post
      _currentStats = _currentStats.copyWith(
        energy: _currentStats.energy - 5,
        fame: _currentStats.fame + 1,
        creativity: _currentStats.creativity + hypeGain, // Update old field too
        inspirationLevel: (_currentStats.inspirationLevel + hypeGain)
            .clamp(0, 100), // 🔥 Add hype (max 100)
        lastActivityDate: DateTime.now(), // ✅ Update activity for fame decay
      );
      widget.onStatsUpdated(_currentStats);

      _postController.clear();
      if (mounted) {
        _showMessage('📢 Posted on EchoX! +1 Fame, +$hypeGain Hype');
      }
    } catch (e) {
      _showMessage('❌ Failed to post: $e');
    }
  }

  List<String> _extractMentions(String content) {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(content);
    return matches.map((m) => m.group(1)!).toSet().toList();
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

  Widget _buildPostContentWithMentions(String content) {
    const mentionColor = Color(0xFF00CED1);

    final spans = <TextSpan>[];
    final mentionRegex = RegExp(r'(@\w+)');
    int lastMatchEnd = 0;

    for (final match in mentionRegex.allMatches(content)) {
      // Add text before the mention
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: content.substring(lastMatchEnd, match.start),
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 15,
            height: 1.4,
            letterSpacing: 0.2,
          ),
        ));
      }

      // Add the @ mention with glow effect
      final mentionText = match.group(0)!;
      spans.add(TextSpan(
        text: mentionText,
        style: const TextStyle(
          color: mentionColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.4,
          letterSpacing: 0.2,
          shadows: [
            Shadow(
              color: mentionColor,
              blurRadius: 8,
            ),
          ],
        ),
        // TODO: Add GestureRecognizer to navigate to player profile
        // recognizer: TapGestureRecognizer()
        //   ..onTap = () => _navigateToPlayer(mentionText.substring(1)),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after last mention
    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastMatchEnd),
        style: TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontSize: 15,
          height: 1.4,
          letterSpacing: 0.2,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
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
          backgroundColor: AppTheme.surfaceDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show options to view the author's platform pages and navigate after loading stats
  void _showViewArtistOptions(String playerId, String authorName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
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
              if (platform == 'echox') {
                // Open EchoX Profile
                // ignore: use_build_context_synchronously
                Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (ctx) => EchoXProfileScreen(
                      userId: playerId,
                      artistStats: stats,
                      onStatsUpdated: (s) {},
                      isOwnProfile: false,
                    ),
                  ),
                );
              } else if (platform == 'tunify') {
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
                  leading: const Icon(Icons.bolt, color: Color(0xFF00CED1)),
                  title: const Text('EchoX Profile',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('View full profile & followers',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: () => openFor('echox'),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: Icon(Icons.music_note, color: AppTheme.successGreen),
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
