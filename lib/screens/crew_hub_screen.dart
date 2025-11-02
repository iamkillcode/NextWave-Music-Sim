import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crew.dart';
import '../services/crew_service.dart';
import '../services/crew_song_service.dart';
import '../services/crew_symbol_uploader.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Main crew hub screen
class CrewHubScreen extends StatefulWidget {
  const CrewHubScreen({super.key});

  @override
  State<CrewHubScreen> createState() => _CrewHubScreenState();
}

class _CrewHubScreenState extends State<CrewHubScreen>
    with SingleTickerProviderStateMixin {
  final CrewService _crewService = CrewService();
  final CrewSongService _crewSongService = CrewSongService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.neonPurple, AppTheme.neonGreen],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.group,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Crew Hub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonGreen,
          labelColor: AppTheme.neonGreen,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Members'),
            Tab(text: 'Projects'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: StreamBuilder<Crew?>(
        stream: _crewService.streamCurrentUserCrew(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.neonGreen),
            );
          }

          final crew = snapshot.data;

          if (crew == null) {
            return _buildNoCrewView();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(crew),
              _buildMembersTab(crew),
              _buildProjectsTab(crew),
              _buildSettingsTab(crew),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoCrewView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.neonPurple.withOpacity(0.3),
                    AppTheme.neonGreen.withOpacity(0.3),
                  ],
                ),
              ),
              child: const Icon(
                Icons.group_add,
                size: 60,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Not in a Crew',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create or join a crew to collaborate\nwith other artists',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateCrewDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Crew'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cost: \$5,000,000',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildCrewInvites(),
          ],
        ),
      ),
    );
  }

  Widget _buildCrewInvites() {
    return StreamBuilder<List<CrewInvite>>(
      stream: _crewService.streamPendingInvites(),
      builder: (context, snapshot) {
        final invites = snapshot.data ?? [];

        if (invites.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crew Invites',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...invites.map((invite) => _buildInviteCard(invite)),
          ],
        );
      },
    );
  }

  Widget _buildInviteCard(CrewInvite invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonPurple.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group, color: AppTheme.neonPurple, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.crewName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${invite.invitedByName} invited you',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptInvite(invite.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineInvite(invite.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: const BorderSide(color: AppTheme.errorRed),
                  ),
                  child: const Text('Decline'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Crew crew) {
    final formatCurrency =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final formatNumber = NumberFormat.compact();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crew header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonPurple.withOpacity(0.2),
                  AppTheme.neonGreen.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.neonGreen.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.neonPurple.withOpacity(0.3),
                      backgroundImage: crew.avatarUrl != null
                          ? NetworkImage(crew.avatarUrl!)
                          : null,
                      child: crew.avatarUrl == null
                          ? const Icon(Icons.group,
                              size: 30, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crew.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${crew.members.length} members • ${crew.primaryGenre}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (crew.bio != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    crew.bio!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats grid
          const Text(
            'Crew Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total Streams',
                formatNumber.format(crew.totalStreams),
                Icons.play_arrow,
                AppTheme.neonGreen,
              ),
              _buildStatCard(
                'Total Earnings',
                formatCurrency.format(crew.totalEarnings),
                Icons.attach_money,
                AppTheme.neonGreen,
              ),
              _buildStatCard(
                'Songs Released',
                '${crew.totalSongsReleased}',
                Icons.music_note,
                AppTheme.neonPurple,
              ),
              _buildStatCard(
                'Crew Fame',
                formatNumber.format(crew.crewFame),
                Icons.star,
                AppTheme.neonPurple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Shared bank
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: AppTheme.neonGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shared Bank',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatCurrency.format(crew.sharedBank),
                        style: const TextStyle(
                          color: AppTheme.neonGreen,
                          fontSize: 20,
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
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(Crew crew) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: crew.members.length,
      itemBuilder: (context, index) {
        final member = crew.members[index];
        final isLeader = member.userId == crew.leaderId;
        final revenueSplit = crew.revenueSplit[member.userId] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: isLeader
                ? Border.all(color: AppTheme.neonGreen, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.neonPurple.withOpacity(0.3),
                    backgroundImage: member.avatarUrl != null
                        ? NetworkImage(member.avatarUrl!)
                        : null,
                    child: member.avatarUrl == null
                        ? Text(
                            member.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  if (member.isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppTheme.surfaceDark, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isLeader) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LEADER',
                              style: TextStyle(
                                color: AppTheme.neonGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '$revenueSplit% revenue split • ${member.contributedSongs} songs',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectsTab(Crew crew) {
    return StreamBuilder<List<CrewSong>>(
      stream: _crewSongService.streamCrewSongs(crew.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonGreen),
          );
        }

        final songs = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Crew Songs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showStartSongDialog(crew),
                    icon: const Icon(Icons.add),
                    label: const Text('New Project'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '${songs.length}',
                      'Total Projects',
                      Icons.music_note,
                      AppTheme.neonPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '${songs.where((s) => s.status == 'released').length}',
                      'Released',
                      Icons.check_circle,
                      AppTheme.neonGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Songs list
              if (songs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.music_note_outlined,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No crew songs yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a collaborative project!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...songs.map((song) => _buildSongCard(song, crew)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSongCard(CrewSong song, Crew crew) {
    final currentUserId = _crewService.currentUserId;
    final hasVoted = song.approvedBy.contains(currentUserId);
    final votesNeeded = song.votesNeeded;
    final votesCount = song.approvedBy.length;

    // Status colors
    Color statusColor;
    IconData statusIcon;
    switch (song.status) {
      case 'writing':
        statusColor = Colors.blue;
        statusIcon = Icons.edit;
        break;
      case 'recording':
        statusColor = Colors.orange;
        statusIcon = Icons.mic;
        break;
      case 'approved':
        statusColor = AppTheme.neonGreen;
        statusIcon = Icons.check;
        break;
      case 'released':
        statusColor = AppTheme.neonPurple;
        statusIcon = Icons.album;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crew Song #${song.id.substring(0, 8)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        song.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Participating members
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: song.contributingMembers.map((memberId) {
                final member = crew.members.firstWhere(
                  (m) => m.userId == memberId,
                  orElse: () => crew.members.first,
                );
                final credit = song.creditSplit[memberId] ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${member.displayName} ($credit%)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Voting section (if writing or recording)
            if (song.status == 'writing' || song.status == 'recording') ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.how_to_vote,
                    size: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Votes: $votesCount/$votesNeeded',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (!hasVoted &&
                      song.contributingMembers.contains(currentUserId))
                    ElevatedButton.icon(
                      onPressed: () => _voteForRelease(song.id),
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: const Text('Vote to Release'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    )
                  else if (hasVoted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check,
                              size: 16, color: AppTheme.neonGreen),
                          SizedBox(width: 4),
                          Text(
                            'Voted',
                            style: TextStyle(
                              color: AppTheme.neonGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],

            // Recording buttons
            if (song.status == 'approved' &&
                song.contributingMembers.contains(currentUserId)) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _startRecording(song.id),
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('Start Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showStartSongDialog(Crew crew) async {
    final titleController = TextEditingController();
    final selectedMembers = <String>{};
    final creditSplits = <String, int>{};

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text(
              'Start Crew Song',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Song Title',
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.6)),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.neonPurple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Members',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...crew.members.map((member) {
                    final isSelected = selectedMembers.contains(member.userId);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedMembers.add(member.userId);
                            // Default equal split
                            creditSplits[member.userId] =
                                (100 / (selectedMembers.length)).round();
                          } else {
                            selectedMembers.remove(member.userId);
                            creditSplits.remove(member.userId);
                          }
                          // Recalculate splits
                          final equalSplit =
                              (100 / selectedMembers.length).round();
                          for (var id in selectedMembers) {
                            creditSplits[id] = equalSplit;
                          }
                        });
                      },
                      title: Text(
                        member.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: isSelected
                          ? Text(
                              'Credit: ${creditSplits[member.userId]}%',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6)),
                            )
                          : null,
                      activeColor: AppTheme.neonPurple,
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedMembers.length >= 2 &&
                        titleController.text.isNotEmpty
                    ? () {
                        Navigator.pop(context);
                        _createCrewSong(
                          crew.id,
                          titleController.text,
                          selectedMembers.toList(),
                          creditSplits,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Project'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createCrewSong(
    String crewId,
    String title,
    List<String> members,
    Map<String, int> creditSplit,
  ) async {
    try {
      // First create a placeholder song document
      final songId = _firestore.collection('songs').doc().id;

      // Create basic song document
      await _firestore.collection('songs').doc(songId).set({
        'id': songId,
        'title': title,
        'status': 'writing',
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'isCrewSong': true,
          'crewId': crewId,
        },
      });

      final result = await _crewSongService.startCrewSong(
        crewId: crewId,
        songId: songId,
        contributingMembers: members,
        creditSplit: creditSplit,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Crew song started! Start writing!'),
              backgroundColor: AppTheme.neonPurple,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error']}'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _voteForRelease(String crewSongId) async {
    try {
      final success = await _crewSongService.voteForRelease(
        crewSongId: crewSongId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vote recorded!'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _startRecording(String songId) async {
    try {
      final success = await _crewSongService.startRecording(songId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Recording started!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildSettingsTab(Crew crew) {
    // Only leader can access settings
    // For now, just show basic info
    final isLeader = crew.leaderId == _crewService.currentUserId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Crew Symbol Upload (Leader only)
          if (isLeader) ...[
            ListTile(
              leading:
                  const Icon(Icons.photo_camera, color: AppTheme.primaryCyan),
              title: const Text('Upload Crew Symbol',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                crew.avatarUrl != null ? 'Change crew logo' : 'Add a crew logo',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              trailing:
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54),
              onTap: () => _uploadCrewSymbol(crew.id),
            ),
            const Divider(color: Colors.white12),
          ],

          ListTile(
            leading: const Icon(Icons.person_add, color: AppTheme.neonGreen),
            title: const Text('Invite Member',
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
              '${crew.members.length}/${crew.maxMembers} members',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            trailing:
                const Icon(Icons.arrow_forward_ios, color: Colors.white54),
            onTap: () {
              // TODO: Implement invite flow
            },
          ),
          const Divider(color: Colors.white12),

          ListTile(
            leading: const Icon(Icons.exit_to_app, color: AppTheme.errorRed),
            title: const Text('Leave Crew',
                style: TextStyle(color: AppTheme.errorRed)),
            onTap: () => _confirmLeaveCrew(crew.id),
          ),
        ],
      ),
    );
  }

  void _showCreateCrewDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CreateCrewDialog(),
    );
  }

  Future<void> _acceptInvite(String inviteId) async {
    final success = await _crewService.acceptCrewInvite(inviteId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Joined crew successfully!'
              : '❌ Failed to join crew'),
          backgroundColor: success ? AppTheme.neonGreen : AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _declineInvite(String inviteId) async {
    final success = await _crewService.declineCrewInvite(inviteId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'Invite declined' : 'Failed to decline invite'),
          backgroundColor: success ? Colors.orange : AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadCrewSymbol(String crewId) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 Selecting image...'),
          backgroundColor: AppTheme.primaryCyan,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Pick and upload the symbol
      final symbolUrl = await CrewSymbolUploader.pickAndUploadCrewSymbol(
        crewId: crewId,
      );

      if (symbolUrl == null) {
        // User cancelled
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload cancelled'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Update crew with new symbol URL
      final success = await _crewService.uploadCrewSymbol(
        crewId: crewId,
        symbolUrl: symbolUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Crew symbol updated successfully!'
              : '❌ Failed to update crew symbol'),
          backgroundColor: success ? AppTheme.neonGreen : AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('❌ Error uploading crew symbol: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmLeaveCrew(String crewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Leave Crew?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to leave this crew?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _crewService.leaveCrew(crewId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Left crew successfully'
                        : 'Failed to leave crew'),
                    backgroundColor:
                        success ? AppTheme.neonGreen : AppTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child:
                const Text('Leave', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}

class _CreateCrewDialog extends StatefulWidget {
  const _CreateCrewDialog();

  @override
  State<_CreateCrewDialog> createState() => _CreateCrewDialogState();
}

class _CreateCrewDialogState extends State<_CreateCrewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final CrewService _crewService = CrewService();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _createCrew() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final result = await _crewService.createCrew(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
    );

    setState(() => _isCreating = false);

    if (mounted) {
      if (result['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Crew created successfully!'),
            backgroundColor: AppTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: const Text('Create Crew', style: TextStyle(color: Colors.white)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: 'Crew Name',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a crew name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Bio (Optional)',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.neonGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Creation Cost',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatCurrency
                                .format(CrewService.CREW_CREATION_COST),
                            style: const TextStyle(
                              color: AppTheme.neonGreen,
                              fontSize: 20,
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createCrew,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.neonGreen,
            foregroundColor: Colors.black,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
