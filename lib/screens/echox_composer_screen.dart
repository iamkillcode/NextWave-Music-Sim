import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';

/// EchoX Post Composer Screen with @ mention support
class EchoXComposerScreen extends StatefulWidget {
  final ArtistStats artistStats;
  final Function(String content, {String? trackId, String? albumId}) onPost;

  const EchoXComposerScreen({
    Key? key,
    required this.artistStats,
    required this.onPost,
  }) : super(key: key);

  @override
  State<EchoXComposerScreen> createState() => _EchoXComposerScreenState();
}

class _EchoXComposerScreenState extends State<EchoXComposerScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isPosting = false;
  bool _showMentionSuggestions = false;
  List<Map<String, String>> _mentionSuggestions = [];
  int _cursorPosition = 0;

  Song? _attachedTrack;

  // Teal/Cyan color scheme (different from Twitter blue)
  static const Color _primaryColor = Color(0xFF00CED1); // Dark Turquoise
  static const Color _accentColor = Color(0xFF20B2AA); // Light Sea Green

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    final cursorPos = _textController.selection.baseOffset;

    setState(() {
      _cursorPosition = cursorPos;
    });

    // Check if we're typing a mention
    if (cursorPos > 0 && cursorPos <= text.length) {
      final beforeCursor = text.substring(0, cursorPos);
      final lastAtIndex = beforeCursor.lastIndexOf('@');

      if (lastAtIndex != -1) {
        // Check if @ is at start or preceded by whitespace
        final isValidMention = lastAtIndex == 0 ||
            (lastAtIndex > 0 && text[lastAtIndex - 1] == ' ');

        if (isValidMention) {
          final query = beforeCursor.substring(lastAtIndex + 1);

          // Only show suggestions if no space after @
          if (!query.contains(' ')) {
            _searchPlayers(query);
            setState(() => _showMentionSuggestions = true);
            return;
          }
        }
      }
    }

    // Hide suggestions if not in mention mode
    if (_showMentionSuggestions) {
      setState(() => _showMentionSuggestions = false);
    }
  }

  Future<void> _searchPlayers(String query) async {
    if (query.isEmpty) {
      // Show recent/popular players when no query
      final snapshot = await FirebaseFirestore.instance
          .collection('players')
          .orderBy('fame', descending: true)
          .limit(5)
          .get();

      setState(() {
        _mentionSuggestions = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['displayName'] as String? ?? 'Unknown',
            'fame': (data['fame'] as num? ?? 0).toString(),
            'avatarUrl': data['avatarUrl'] as String? ?? '',
          };
        }).toList();
      });
      return;
    }

    // Search by display name (case-insensitive)
    final snapshot = await FirebaseFirestore.instance
        .collection('players')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThan: query + 'z')
        .limit(10)
        .get();

    setState(() {
      _mentionSuggestions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['displayName'] as String? ?? 'Unknown',
          'fame': (data['fame'] as num? ?? 0).toString(),
          'avatarUrl': data['avatarUrl'] as String? ?? '',
        };
      }).toList();
    });
  }

  void _insertMention(String username) {
    final text = _textController.text;
    final cursorPos = _cursorPosition.clamp(0, text.length);

    // Safety check for empty text
    if (text.isEmpty || cursorPos == 0) {
      // Insert mention at the beginning
      _textController.value = TextEditingValue(
        text: '@$username ',
        selection: TextSelection.collapsed(offset: username.length + 2),
      );
      setState(() => _showMentionSuggestions = false);
      _focusNode.requestFocus();
      return;
    }

    final beforeCursor = text.substring(0, cursorPos);
    final afterCursor = text.substring(cursorPos);

    // Find the @ position
    final lastAtIndex = beforeCursor.lastIndexOf('@');
    if (lastAtIndex == -1) {
      // No @ found, shouldn't happen but handle gracefully
      setState(() => _showMentionSuggestions = false);
      return;
    }

    // Build new text: [text before @] + [@username ] + [text after cursor]
    final beforeMention = lastAtIndex > 0 ? text.substring(0, lastAtIndex) : '';
    final newText = beforeMention + '@$username ' + afterCursor;
    final newCursorPos = lastAtIndex + username.length + 2;

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    setState(() {
      _showMentionSuggestions = false;
    });

    _focusNode.requestFocus();
  }

  void _showTrackPicker() {
    final releasedTracks = widget.artistStats.songs
        .where((s) => s.state == SongState.released)
        .toList()
      ..sort((a, b) => (b.releasedDate ?? DateTime(2020))
          .compareTo(a.releasedDate ?? DateTime(2020)));

    if (releasedTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No released tracks to promote')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundDark,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Select Track to Promote'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: releasedTracks.length,
              itemBuilder: (context, index) {
                final track = releasedTracks[index];
                return ListTile(
                  leading: const Icon(Icons.music_note, color: _primaryColor),
                  title: Text(
                    track.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${track.streams.toStringAsFixed(0)} streams',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  onTap: () {
                    setState(() => _attachedTrack = track);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _post() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Post cannot be empty')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await widget.onPost(
        content,
        trackId: _attachedTrack?.id,
        albumId: null, // TODO: Add album support
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _textController.text.length;
    final charLimit = 280;
    final isOverLimit = charCount > charLimit;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryColor, _accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('New Post', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: (_isPosting || isOverLimit) ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('POST',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Author info
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: widget.artistStats.avatarUrl != null
                          ? Colors.grey[800]
                          : _primaryColor,
                      backgroundImage: widget.artistStats.avatarUrl != null
                          ? NetworkImage(widget.artistStats.avatarUrl!)
                          : null,
                      child: widget.artistStats.avatarUrl == null
                          ? Text(
                              widget.artistStats.name.isNotEmpty
                                  ? widget.artistStats.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.artistStats.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${widget.artistStats.name.toLowerCase().replaceAll(' ', '')}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Text input
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    maxLength: charLimit,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: "What's happening in your music career?",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),

              // Attached track preview
              if (_attachedTrack != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note,
                          color: _primaryColor, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _attachedTrack!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_attachedTrack!.streams.toStringAsFixed(0)} streams',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: () => setState(() => _attachedTrack = null),
                      ),
                    ],
                  ),
                ),

              const Divider(color: Colors.white12, height: 1),

              // Bottom toolbar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.music_note, color: _primaryColor),
                      onPressed: _showTrackPicker,
                      tooltip: 'Attach Track',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.alternate_email,
                          color: _primaryColor),
                      onPressed: () {
                        // Insert @ at cursor
                        final text = _textController.text;
                        final cursorPos = _textController.selection.baseOffset;
                        final newText = text.substring(0, cursorPos) +
                            '@' +
                            text.substring(cursorPos);
                        _textController.value = TextEditingValue(
                          text: newText,
                          selection:
                              TextSelection.collapsed(offset: cursorPos + 1),
                        );
                        _focusNode.requestFocus();
                      },
                      tooltip: 'Mention Player',
                    ),
                    const Spacer(),
                    // Character count
                    Text(
                      '$charCount/$charLimit',
                      style: TextStyle(
                        color: isOverLimit ? Colors.red : Colors.white60,
                        fontSize: 14,
                        fontWeight:
                            isOverLimit ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Energy cost
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primaryColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt,
                              color: _primaryColor, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            '5',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // @ mention suggestions overlay
          if (_showMentionSuggestions && _mentionSuggestions.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 80,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.surfaceDark,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _mentionSuggestions.length,
                    itemBuilder: (context, index) {
                      final player = _mentionSuggestions[index];
                      final avatarUrl = player['avatarUrl'];
                      final hasAvatar =
                          avatarUrl != null && avatarUrl.isNotEmpty;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              hasAvatar ? Colors.grey[800] : _accentColor,
                          backgroundImage:
                              hasAvatar ? NetworkImage(avatarUrl) : null,
                          child: !hasAvatar
                              ? Text(
                                  player['name']!.isNotEmpty
                                      ? player['name']![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(
                          player['name']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${player['fame']} Fame',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                        onTap: () => _insertMention(player['name']!),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
