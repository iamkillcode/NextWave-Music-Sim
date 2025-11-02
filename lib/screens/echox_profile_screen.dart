import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artist_stats.dart';
import '../services/echox_service.dart';
import '../theme/app_theme.dart';
import 'echox_screen.dart';
import 'echox_comments_screen.dart';

class EchoXProfileScreen extends StatefulWidget {
  final String userId;
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;
  final bool isOwnProfile;

  const EchoXProfileScreen({
    super.key,
    required this.userId,
    required this.artistStats,
    required this.onStatsUpdated,
    this.isOwnProfile = true,
  });

  @override
  State<EchoXProfileScreen> createState() => _EchoXProfileScreenState();
}

class _EchoXProfileScreenState extends State<EchoXProfileScreen> {
  final EchoXService _echoXService = EchoXService();
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isOwnProfile) {
      _checkFollowStatus();
    }
  }

  Future<void> _checkFollowStatus() async {
    final following = await _echoXService.isFollowing(widget.userId);
    if (mounted) {
      setState(() {
        _isFollowing = following;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: _buildProfileHeader(),
          ),
          // Stats Row (Followers/Following/Posts)
          SliverToBoxAdapter(
            child: _buildStatsRow(),
          ),
          // Divider
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 8,
              color: const Color(0xFF0F1419),
            ),
          ),
          // Posts Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00CED1), Color(0xFF20B2AA)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grid_on,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isOwnProfile ? 'My Posts' : 'Posts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Posts List
          _buildPostsList(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0E14),
            const Color(0xFF0F1419).withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.artistStats.avatarUrl == null
                      ? const LinearGradient(
                          colors: [Color(0xFF00CED1), Color(0xFF20B2AA)],
                        )
                      : null,
                  image: widget.artistStats.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.artistStats.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00CED1).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: widget.artistStats.avatarUrl == null
                    ? Center(
                        child: Text(
                          widget.artistStats.name.isNotEmpty
                              ? widget.artistStats.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              if (widget.isOwnProfile)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00CED1),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF0A0E14), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00CED1).withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.verified,
                        color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            widget.artistStats.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          // Username
          Text(
            '@${widget.artistStats.name.toLowerCase().replaceAll(' ', '')}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Bio / Genre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1419),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00CED1).withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_note,
                    color: Color(0xFF00CED1), size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.artistStats.primaryGenre,
                  style: const TextStyle(
                    color: Color(0xFF00CED1),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${widget.artistStats.fame} Fame',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (!widget.isOwnProfile) ...[
            const SizedBox(height: 20),
            // Follow/Unfollow Button
            _buildFollowButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoadingFollow ? null : _handleFollowToggle,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            gradient: _isFollowing
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF00CED1), Color(0xFF20B2AA)],
                  ),
            color: _isFollowing ? const Color(0xFF0F1419) : null,
            borderRadius: BorderRadius.circular(25),
            border: _isFollowing
                ? Border.all(color: const Color(0xFF00CED1), width: 2)
                : null,
            boxShadow: !_isFollowing
                ? [
                    BoxShadow(
                      color: const Color(0xFF00CED1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: _isLoadingFollow
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFollowing ? Icons.person_remove : Icons.person_add,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _handleFollowToggle() async {
    setState(() {
      _isLoadingFollow = true;
    });

    try {
      final result = await _echoXService.toggleFollow(widget.userId);
      if (result['success']) {
        setState(() {
          _isFollowing = result['action'] == 'followed';
        });
        if (mounted) {
          _showMessage(result['message'] ?? 'Success');
        }
      } else {
        if (mounted) {
          _showMessage('❌ ${result['error']}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('❌ Failed to update follow status');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFollow = false;
        });
      }
    }
  }

  Widget _buildStatsRow() {
    return StreamBuilder<Map<String, int>>(
      stream: _echoXService.streamFollowerStats(widget.userId),
      builder: (context, followerSnapshot) {
        final stats = followerSnapshot.data ?? {'followers': 0, 'following': 0};
        final followers = stats['followers'] ?? 0;
        final following = stats['following'] ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('echox_posts')
              .where('authorId', isEqualTo: widget.userId)
              .snapshots(),
          builder: (context, postSnapshot) {
            final postCount = postSnapshot.data?.docs.length ?? 0;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    label: 'Posts',
                    value: postCount.toString(),
                    icon: Icons.grid_on,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  _buildStatItem(
                    label: 'Followers',
                    value: followers.toString(),
                    icon: Icons.people,
                    color: const Color(0xFF00CED1),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  _buildStatItem(
                    label: 'Following',
                    value: following.toString(),
                    icon: Icons.person_add,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? Colors.white.withOpacity(0.6),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('echox_posts')
          .where('authorId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFF00CED1)),
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
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
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
                        Icons.article_outlined,
                        size: 48,
                        color: Color(0xFF00CED1),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.isOwnProfile ? 'No posts yet' : 'No posts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isOwnProfile
                          ? 'Share your journey with fans!'
                          : 'This artist hasn\'t posted yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _buildPostCard(posts[index],
                  showDelete: widget.isOwnProfile);
            },
            childCount: posts.length,
          ),
        );
      },
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: post.avatarUrl == null
                        ? const LinearGradient(
                            colors: [Color(0xFF00CED1), Color(0xFF20B2AA)],
                          )
                        : null,
                    color: post.avatarUrl != null ? Colors.grey[800] : null,
                    shape: BoxShape.circle,
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
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author info
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  post.authorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
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
                      // Content
                      Text(
                        post.content,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Interaction buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInteractionButton(
                            icon: Icons.chat_bubble_outline,
                            count: post.comments,
                            color: Colors.white.withOpacity(0.6),
                            onTap: () => _navigateToComments(post),
                          ),
                          _buildInteractionButton(
                            icon: Icons.repeat_rounded,
                            count: post.echoes,
                            color: Colors.white.withOpacity(0.6),
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
                          const SizedBox(width: 8),
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
          .update({
        'likes': isLiked ? post.likes - 1 : post.likes + 1,
        'likedBy': newLikedBy,
      });
    } catch (e) {
      _showMessage('❌ Failed to like post');
    }
  }

  Future<void> _echoPost(EchoPost post) async {
    try {
      await FirebaseFirestore.instance
          .collection('echox_posts')
          .doc(post.id)
          .update({
        'echoes': post.echoes + 1,
      });
      _showMessage('🔁 Echoed!');
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

  void _navigateToComments(EchoPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EchoXCommentsScreen(
          post: post,
          artistStats: widget.artistStats,
          onStatsUpdated: widget.onStatsUpdated,
        ),
      ),
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
}
