import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collaboration.dart';
import '../services/collaboration_service.dart';
import '../models/song.dart';
import '../utils/genres.dart';

class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CollaborationService _collabService = CollaborationService();

  // Search filters
  String _searchQuery = '';
  String? _selectedGenre;
  String? _selectedRegion;
  double _minFame = 0;
  double _maxFame = 500;

  List<PlayerArtist> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecommended();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommended() async {
    setState(() => _isSearching = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userData = await FirebaseFirestore.instance
          .collection('players')
          .doc(currentUser.uid)
          .get();

      if (!userData.exists) return;

      final data = userData.data()!;
      final recommended = await _collabService.getRecommendedPlayers(
        data['genre'] as String? ?? 'Pop',
        data['homeRegion'] as String? ?? 'usa',
      );
      setState(() {
        _searchResults = recommended;
        _isSearching = false;
      });
    } catch (e) {
      print('Error loading recommended players: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchPlayers() async {
    setState(() => _isSearching = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final results = await _collabService.searchPlayers(
        query: _searchQuery,
        genre: _selectedGenre,
        region: _selectedRegion,
        minFame: _minFame.toInt(),
        maxFame: _maxFame.toInt(),
      );
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching players: $e');
      setState(() => _isSearching = false);
    }
  }

  void _showSendRequestDialog(PlayerArtist player) {
    showDialog(
      context: context,
      builder: (context) => _SendCollabRequestDialog(
        player: player,
        collabService: _collabService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('🤝 Collaborations',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'Find Players'),
            Tab(text: 'Requests'),
            Tab(text: 'Active'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFindPlayersTab(),
          _buildRequestsTab(),
          _buildActiveTab(),
        ],
      ),
    );
  }

  Widget _buildFindPlayersTab() {
    return Column(
      children: [
        // Search and filters
        Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search bar
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.amber),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.amber),
                    onPressed: () => _showFiltersDialog(),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _searchPlayers();
                },
              ),
              const SizedBox(height: 8),

              // Active filters chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedGenre != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_selectedGenre!),
                          onDeleted: () {
                            setState(() => _selectedGenre = null);
                            _searchPlayers();
                          },
                          backgroundColor: Colors.purple,
                          deleteIconColor: Colors.white,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ),
                    if (_selectedRegion != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_selectedRegion!.toUpperCase()),
                          onDeleted: () {
                            setState(() => _selectedRegion = null);
                            _searchPlayers();
                          },
                          backgroundColor: Colors.blue,
                          deleteIconColor: Colors.white,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ),
                    if (_minFame > 0 || _maxFame < 500)
                      Chip(
                        label: Text(
                            'Fame: ${_minFame.toInt()}-${_maxFame.toInt()}'),
                        onDeleted: () {
                          setState(() {
                            _minFame = 0;
                            _maxFame = 500;
                          });
                          _searchPlayers();
                        },
                        backgroundColor: Colors.amber,
                        deleteIconColor: Colors.white,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search results
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.amber))
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text(
                            'No players found',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search filters',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final player = _searchResults[index];
                        return _buildPlayerCard(player);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(PlayerArtist player) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showSendRequestDialog(player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.purple,
                    backgroundImage: player.avatarUrl != null
                        ? NetworkImage(player.avatarUrl!)
                        : null,
                    child: player.avatarUrl == null
                        ? Text(
                            player.name.isNotEmpty
                                ? player.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  if (player.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey[900]!, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getFameColor(player.fame),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${player.fame} 🔥',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.music_note,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          player.primaryGenre,
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          player.currentRegion.toUpperCase(),
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                    if (!player.isOnline)
                      Text(
                        'Last active ${_formatLastActive(player.lastActive)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),

              // Action button
              IconButton(
                icon: const Icon(Icons.send, color: Colors.amber),
                onPressed: () => _showSendRequestDialog(player),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
          child: Text('Not logged in', style: TextStyle(color: Colors.white)));
    }

    return StreamBuilder<List<Collaboration>>(
      stream: _collabService.getPendingRequests(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!;
        final incoming = requests
            .where((r) => r.featuringArtistId == currentUser.uid)
            .toList();
        final outgoing = requests
            .where((r) => r.primaryArtistId == currentUser.uid)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (incoming.isNotEmpty) ...[
              Text(
                '📥 Incoming Requests (${incoming.length})',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...incoming.map((collab) => _buildIncomingRequestCard(collab)),
              const SizedBox(height: 24),
            ],
            if (outgoing.isNotEmpty) ...[
              Text(
                '📤 Outgoing Requests (${outgoing.length})',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...outgoing.map((collab) => _buildOutgoingRequestCard(collab)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildIncomingRequestCard(Collaboration collab) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.purple,
                  child: Text(
                    collab.primaryArtistName.isNotEmpty
                        ? collab.primaryArtistName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collab.primaryArtistName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'wants to collaborate',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collab.metadata['songTitle'] ?? 'Untitled',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    collab.metadata['genre'] ?? 'Unknown Genre',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  if (collab.metadata['message'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"${collab.metadata['message']}"',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Split: ${collab.splitPercentage}% for you',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  if (collab.featureFee != null && collab.featureFee! > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_money,
                              color: Colors.purple, size: 16),
                          Text(
                            'Feature Fee: \$${_formatMoney(collab.featureFee!)}',
                            style: const TextStyle(
                                color: Colors.purple,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptCollaboration(collab),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectCollaboration(collab),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingRequestCard(Collaboration collab) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue,
              backgroundImage: collab.featuringArtistAvatar != null
                  ? NetworkImage(collab.featuringArtistAvatar!)
                  : null,
              child: collab.featuringArtistAvatar == null
                  ? Text(
                      collab.featuringArtistName.isNotEmpty
                          ? collab.featuringArtistName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To: ${collab.featuringArtistName}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    collab.metadata['songTitle'] ?? 'Untitled',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  Text(
                    '⏳ Waiting for response...',
                    style: TextStyle(color: Colors.amber[700], fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _cancelCollaboration(collab),
              tooltip: 'Cancel',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
          child: Text('Not logged in', style: TextStyle(color: Colors.white)));
    }

    return StreamBuilder<List<Collaboration>>(
      stream: _collabService.getActiveCollaborations(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'No active collaborations',
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start by finding players to collaborate with',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          );
        }

        final collaborations = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: collaborations.length,
          itemBuilder: (context, index) {
            final collab = collaborations[index];
            return _buildActiveCollabCard(collab, currentUser.uid);
          },
        );
      },
    );
  }

  Widget _buildActiveCollabCard(Collaboration collab, String currentUserId) {
    final isPrimary = collab.primaryArtistId == currentUserId;
    final partnerName =
        isPrimary ? collab.featuringArtistName : collab.primaryArtistName;
    final partnerAvatar = isPrimary ? collab.featuringArtistAvatar : null;

    String statusText = '';
    Color statusColor = Colors.amber;
    IconData statusIcon = Icons.music_note;

    switch (collab.status) {
      case CollaborationStatus.accepted:
        statusText = '🎤 Ready to Record';
        statusColor = Colors.blue;
        statusIcon = Icons.mic;
        break;
      case CollaborationStatus.recording:
        statusText = '🎵 Recording in Progress';
        statusColor = Colors.purple;
        statusIcon = Icons.radio_button_checked;
        break;
      case CollaborationStatus.recorded:
        statusText = '✅ Recorded, Ready to Release';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusText = collab.status.name;
    }

    // Check if regions are different
    final differentRegions = collab.primaryRegion != collab.featuringRegion;
    final travelCost = differentRegions &&
            collab.primaryRegion != null &&
            collab.featuringRegion != null
        ? _collabService.calculateTravelCost(
            collab.primaryRegion!, collab.featuringRegion!)
        : 0;

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.purple,
                  backgroundImage: partnerAvatar != null
                      ? NetworkImage(partnerAvatar)
                      : null,
                  child: partnerAvatar == null
                      ? Text(
                          partnerName.isNotEmpty
                              ? partnerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'with $partnerName',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        collab.metadata['songTitle'] ?? 'Untitled',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 8),
                  Text(statusText,
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Actions
            if (collab.status == CollaborationStatus.accepted) ...[
              if (!differentRegions || collab.recordedTogether)
                // Same region - can record together
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _recordTogether(collab),
                    icon: const Icon(Icons.mic),
                    label: const Text('Record Together'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              else
                // Different regions - show travel or remote options
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showTravelDialog(collab, travelCost),
                        icon: const Icon(Icons.flight),
                        label: Text(
                            'Travel & Record Together (\$${_formatMoney(travelCost)})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _sendRecordingRemotely(collab),
                        icon: const Icon(Icons.send),
                        label: const Text('Send Recording via StarChat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
            ] else if (collab.status == CollaborationStatus.recording &&
                !isPrimary) ...[
              // Featuring artist sends their recording
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _sendRecordingRemotely(collab),
                  icon: const Icon(Icons.send),
                  label: const Text('Send Your Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ] else if (collab.status == CollaborationStatus.recorded &&
                isPrimary) ...[
              // Primary artist accepts the recording
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _acceptRecording(collab),
                  icon: const Icon(Icons.check),
                  label: const Text('Accept Recording & Finalize'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],

            // Info
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${collab.primaryRegion?.toUpperCase() ?? 'UNKNOWN'} → ${collab.featuringRegion?.toUpperCase() ?? 'UNKNOWN'}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const Spacer(),
                if (collab.recordedTogether)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple),
                    ),
                    child: const Text(
                      '🎙️ Recorded Together',
                      style: TextStyle(
                          color: Colors.purple,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Search Filters', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Genre filter
              const Text('Genre',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGenre,
                dropdownColor: Colors.grey[850],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any Genre')),
                  ...Genres.all
                      .map((g) => DropdownMenuItem(value: g, child: Text(g))),
                ],
                onChanged: (value) => setState(() => _selectedGenre = value),
              ),
              const SizedBox(height: 16),

              // Region filter
              const Text('Region',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                dropdownColor: Colors.grey[850],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Any Region')),
                  ...[
                    'usa',
                    'europe',
                    'asia',
                    'africa',
                    'latin_america'
                  ].map((r) =>
                      DropdownMenuItem(value: r, child: Text(r.toUpperCase()))),
                ],
                onChanged: (value) => setState(() => _selectedRegion = value),
              ),
              const SizedBox(height: 16),

              // Fame range
              const Text('Fame Range',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(_minFame, _maxFame),
                min: 0,
                max: 500,
                divisions: 50,
                activeColor: Colors.amber,
                inactiveColor: Colors.grey[700],
                labels: RangeLabels(
                    _minFame.toInt().toString(), _maxFame.toInt().toString()),
                onChanged: (values) {
                  setState(() {
                    _minFame = values.start;
                    _maxFame = values.end;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedGenre = null;
                _selectedRegion = null;
                _minFame = 0;
                _maxFame = 500;
              });
              Navigator.pop(context);
              _searchPlayers();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _searchPlayers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Apply Filters',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showTravelDialog(Collaboration collab, int travelCost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('✈️ Travel to Record',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Travel from ${collab.primaryRegion?.toUpperCase() ?? 'UNKNOWN'} to ${collab.featuringRegion?.toUpperCase() ?? 'UNKNOWN'}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎁 Travel Bonuses:',
                      style: TextStyle(
                          color: Colors.purple, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('• +30% stream boost',
                      style: TextStyle(color: Colors.white)),
                  const Text('• +10 quality bonus',
                      style: TextStyle(color: Colors.white)),
                  const Text('• +10 fame bonus',
                      style: TextStyle(color: Colors.white)),
                  const Text('• "Recorded Together" badge',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Travel Cost:',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                Text(
                  '\$${_formatMoney(travelCost)}',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _recordTogether(collab, travelCost: travelCost);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Travel & Record'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptCollaboration(Collaboration collab) async {
    try {
      await _collabService.acceptCollaboration(collab.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Collaboration accepted!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectCollaboration(Collaboration collab) async {
    try {
      await _collabService.rejectCollaboration(collab.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('❌ Collaboration rejected'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelCollaboration(Collaboration collab) async {
    try {
      await _collabService.rejectCollaboration(collab.id); // Uses same method
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Collaboration request cancelled'),
              backgroundColor: Colors.grey),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _recordTogether(Collaboration collab, {int? travelCost}) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    try {
      // Check if user has enough money for travel
      if (travelCost != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('players')
            .doc(currentUser.uid)
            .get();
        final currentMoney = userDoc.data()?['currentMoney'] ?? 0;

        if (currentMoney < travelCost) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Not enough money! Need \$${_formatMoney(travelCost)}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Record together first
      await _collabService.recordTogether(collab.id);

      // Only deduct money after successful recording
      if (travelCost != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('players')
            .doc(currentUser.uid)
            .get();
        final currentMoney = userDoc.data()?['currentMoney'] ?? 0;

        await FirebaseFirestore.instance
            .collection('players')
            .doc(currentUser.uid)
            .update({'currentMoney': currentMoney - travelCost});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              travelCost != null
                  ? '✈️ Traveled & recorded together! (+30% boost)'
                  : '🎤 Recorded together!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendRecordingRemotely(Collaboration collab) async {
    try {
      // For now, use placeholder URL - in production this would be actual recording upload
      await _collabService.sendRecordingRemotely(
          collab.id, 'placeholder_recording_url');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📤 Recording sent via StarChat!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _acceptRecording(Collaboration collab) async {
    try {
      await _collabService.acceptRecording(collab.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recording accepted! Ready to release.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getFameColor(int fame) {
    if (fame >= 200) return Colors.red;
    if (fame >= 100) return Colors.orange;
    if (fame >= 50) return Colors.amber;
    return Colors.green;
  }

  String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) return 'Unknown';
    final diff = DateTime.now().difference(lastActive);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatMoney(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// Dialog for sending collaboration request
class _SendCollabRequestDialog extends StatefulWidget {
  final PlayerArtist player;
  final CollaborationService collabService;

  const _SendCollabRequestDialog({
    required this.player,
    required this.collabService,
  });

  @override
  State<_SendCollabRequestDialog> createState() =>
      _SendCollabRequestDialogState();
}

class _SendCollabRequestDialogState extends State<_SendCollabRequestDialog> {
  Song? _selectedSong;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _feeFeeController = TextEditingController();
  int _splitPercentage = 30;
  int? _featureFee;
  bool _isLoading = false;
  List<Song> _writtenSongs = [];

  @override
  void initState() {
    super.initState();
    _loadWrittenSongs();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _feeFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadWrittenSongs() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final playerDoc = await FirebaseFirestore.instance
          .collection('players')
          .doc(currentUser.uid)
          .get();

      if (!playerDoc.exists) {
        setState(() {
          _writtenSongs = [];
          _isLoading = false;
        });
        return;
      }

      final data = playerDoc.data()!;
      final songs =
          (data['songs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

      // Filter for written songs only (not recorded yet)
      final writtenSongs = songs
          .where((songData) => songData['state'] == 'written')
          .map((songData) => Song.fromJson(songData))
          .toList();

      setState(() {
        _writtenSongs = writtenSongs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading songs: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest() async {
    if (_selectedSong == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a song'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await widget.collabService.sendCollaborationRequest(
        songId: _selectedSong!.id,
        featuringArtistId: widget.player.id,
        featuringArtistName: widget.player.name,
        splitPercentage: _splitPercentage,
        featureFee: _featureFee,
        message: _messageController.text.trim(),
        songTitle: _selectedSong!.title,
        genre: _selectedSong!.genre,
        type: CollaborationType.written,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Collaboration request sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text('Send Request to ${widget.player.name}',
          style: const TextStyle(color: Colors.white)),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Song selection
                  const Text('Select Song',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _writtenSongs.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'No written songs available. Write a song first!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : DropdownButtonFormField<Song>(
                          value: _selectedSong,
                          dropdownColor: Colors.grey[850],
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          items: _writtenSongs.map((song) {
                            return DropdownMenuItem(
                              value: song,
                              child: Text('${song.title} (${song.genre})'),
                            );
                          }).toList(),
                          onChanged: (song) =>
                              setState(() => _selectedSong = song),
                        ),
                  const SizedBox(height: 16),

                  // Split percentage
                  const Text('Revenue Split',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _splitPercentage.toDouble(),
                          min: 20,
                          max: 50,
                          divisions: 6,
                          activeColor: Colors.amber,
                          inactiveColor: Colors.grey[700],
                          label: '$_splitPercentage%',
                          onChanged: (value) =>
                              setState(() => _splitPercentage = value.toInt()),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text(
                          '$_splitPercentage%',
                          style: const TextStyle(
                              color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'You: ${100 - _splitPercentage}% | ${widget.player.name}: $_splitPercentage%',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Feature Fee
                  const Text('Feature Fee (Optional)',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feeFeeController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g., 5000',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[850],
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(color: Colors.amber),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      helperText: 'Upfront payment they receive when accepting',
                      helperStyle:
                          TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      setState(() => _featureFee = parsed);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Message
                  const Text('Message (Optional)',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'Hey! Want to collab on this track?',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _writtenSongs.isEmpty ? null : _sendRequest,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          child:
              const Text('Send Request', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}
