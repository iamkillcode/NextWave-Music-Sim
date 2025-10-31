import 'package:flutter/material.dart';
import '../models/artist_stats.dart';
import '../widgets/comment_section.dart';
import 'echox_screen.dart';

class EchoXCommentsScreen extends StatefulWidget {
  final EchoPost post;
  final ArtistStats artistStats;
  final Function(ArtistStats) onStatsUpdated;

  const EchoXCommentsScreen({
    super.key,
    required this.post,
    required this.artistStats,
    required this.onStatsUpdated,
  });

  @override
  State<EchoXCommentsScreen> createState() => _EchoXCommentsScreenState();
}

class _EchoXCommentsScreenState extends State<EchoXCommentsScreen> {
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
        title: const Text(
          'Comments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Original post
          _buildOriginalPost(),
          const Divider(color: Colors.white12, height: 1),

          // Comments section using new unified widget
          Expanded(
            child: CommentSection(
              contextType: 'post',
              contextId: widget.post.id,
              contextTitle: widget.post.content.length > 30
                  ? '${widget.post.content.substring(0, 30)}...'
                  : widget.post.content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalPost() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181C),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.post.authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF00D9FF),
                          size: 16,
                        ),
                      ],
                    ),
                    Text(
                      _formatTimestamp(widget.post.timestamp),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Post content
          Text(
            widget.post.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Stats
          Row(
            children: [
              Text(
                '${widget.post.likes} likes',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Text(
                '${widget.post.comments} comments',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
