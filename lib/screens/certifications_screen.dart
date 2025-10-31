import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/artist_stats.dart';
import '../models/song.dart';

class CertificationsScreen extends StatefulWidget {
  final ArtistStats artistStats;

  const CertificationsScreen({
    super.key,
    required this.artistStats,
  });

  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final certifiedSongs = widget.artistStats.songs
        .where((song) =>
            song.state == SongState.released &&
            song.highestCertification != 'none')
        .toList();

    // Sort by certification level (highest first)
    certifiedSongs.sort((a, b) {
      final levelComparison = _getCertificationRank(b.highestCertification)
          .compareTo(_getCertificationRank(a.highestCertification));
      if (levelComparison != 0) return levelComparison;
      return b.certificationLevel.compareTo(a.certificationLevel);
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Certifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'My Certifications'),
            Tab(text: 'Rankings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyCertifications(certifiedSongs),
          _buildRankings(),
        ],
      ),
    );
  }

  Widget _buildMyCertifications(List<Song> certifiedSongs) {
    if (certifiedSongs.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Card
          _buildStatsCard(certifiedSongs),
          const SizedBox(height: 24),

          // Certifications List
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  color: AppTheme.accentBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Certified Songs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Song Cards
          ...certifiedSongs.map((song) => _buildSongCard(song)),
        ],
      ),
    );
  }

  Widget _buildRankings() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('players').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          );
        }

        // Calculate certification scores for each player
        final playerScores = <Map<String, dynamic>>[];
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final songs = data['songs'] as List<dynamic>? ?? [];

          int totalScore = 0;
          int certCount = 0;

          for (final songData in songs) {
            if (songData is Map<String, dynamic>) {
              final cert =
                  songData['highestCertification'] as String? ?? 'none';
              final level = songData['certificationLevel'] as int? ?? 0;

              if (cert != 'none') {
                certCount++;
                totalScore += _getCertificationScore(cert, level);
              }
            }
          }

          if (certCount > 0) {
            playerScores.add({
              'id': doc.id,
              'name': data['displayName'] ?? 'Unknown Artist',
              'avatarUrl': data['avatarUrl'],
              'score': totalScore,
              'certCount': certCount,
            });
          }
        }

        // Sort by score
        playerScores
            .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: playerScores.length,
          itemBuilder: (context, index) {
            final player = playerScores[index];
            final isCurrentUser = player['id'] == currentUserId;

            return _buildRankingCard(
              rank: index + 1,
              name: player['name'],
              avatarUrl: player['avatarUrl'],
              score: player['score'],
              certCount: player['certCount'],
              isCurrentUser: isCurrentUser,
            );
          },
        );
      },
    );
  }

  Widget _buildRankingCard({
    required int rank,
    required String name,
    String? avatarUrl,
    required int score,
    required int certCount,
    required bool isCurrentUser,
  }) {
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = Colors.white60;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.accentBlue.withOpacity(0.1)
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? AppTheme.accentBlue.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 2),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rankColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarUrl != null
                  ? Colors.grey[800]
                  : AppTheme.accentBlue.withOpacity(0.2),
              shape: BoxShape.circle,
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
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
                        name,
                        style: TextStyle(
                          color: isCurrentUser
                              ? AppTheme.accentBlue
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$certCount certifications • $score pts',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Trophy
          Icon(
            Icons.emoji_events_rounded,
            color: rankColor,
            size: 28,
          ),
        ],
      ),
    );
  }

  int _getCertificationScore(String cert, int level) {
    switch (cert) {
      case 'diamond':
        return 1000;
      case 'multi_platinum':
        return 500 * level;
      case 'platinum':
        return 300;
      case 'gold':
        return 150;
      case 'silver':
        return 50;
      default:
        return 0;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No Certifications Yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep releasing music and gaining streams\nto earn your first certification!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(List<Song> certifiedSongs) {
    final totalCertifications = certifiedSongs.length;
    final diamondCount =
        certifiedSongs.where((s) => s.highestCertification == 'diamond').length;
    final multiPlatinumCount = certifiedSongs
        .where((s) => s.highestCertification == 'multi_platinum')
        .length;
    final platinumCount = certifiedSongs
        .where((s) => s.highestCertification == 'platinum')
        .length;
    final goldCount =
        certifiedSongs.where((s) => s.highestCertification == 'gold').length;
    final silverCount =
        certifiedSongs.where((s) => s.highestCertification == 'silver').length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceDark,
            AppTheme.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded,
                  color: AppTheme.accentBlue, size: 24),
              SizedBox(width: 8),
              Text(
                'Certification Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBadge(
                  'Total', totalCertifications.toString(), AppTheme.accentBlue),
              if (diamondCount > 0)
                _buildStatBadge(
                    '💎', diamondCount.toString(), const Color(0xFFB9F2FF)),
              if (multiPlatinumCount > 0)
                _buildStatBadge('Multi-Platinum', multiPlatinumCount.toString(),
                    const Color(0xFFE5E4E2)),
              if (platinumCount > 0)
                _buildStatBadge('Platinum', platinumCount.toString(),
                    const Color(0xFFE5E4E2)),
              if (goldCount > 0)
                _buildStatBadge(
                    'Gold', goldCount.toString(), const Color(0xFFFFD700)),
              if (silverCount > 0)
                _buildStatBadge(
                    'Silver', silverCount.toString(), const Color(0xFFC0C0C0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSongCard(Song song) {
    final certColor = _getCertificationColor(song.highestCertification);
    final certLabel = _getCertificationLabel(
        song.highestCertification, song.certificationLevel);
    final certIcon = _getCertificationIcon(song.highestCertification);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: certColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: certColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Certification Badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  certColor,
                  certColor.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: certColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                certIcon,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Song Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  certLabel,
                  style: TextStyle(
                    color: certColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatNumber(song.streams)} streams',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Arrow Icon
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.3),
            size: 28,
          ),
        ],
      ),
    );
  }

  int _getCertificationRank(String certification) {
    switch (certification) {
      case 'diamond':
        return 5;
      case 'multi_platinum':
        return 4;
      case 'platinum':
        return 3;
      case 'gold':
        return 2;
      case 'silver':
        return 1;
      default:
        return 0;
    }
  }

  Color _getCertificationColor(String certification) {
    switch (certification) {
      case 'diamond':
        return const Color(0xFFB9F2FF);
      case 'multi_platinum':
        return const Color(0xFFE5E4E2);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      default:
        return Colors.grey;
    }
  }

  String _getCertificationIcon(String certification) {
    switch (certification) {
      case 'diamond':
        return '💎';
      case 'multi_platinum':
        return '🏆';
      case 'platinum':
        return '⚪';
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      default:
        return '🏅';
    }
  }

  String _getCertificationLabel(String certification, int level) {
    switch (certification) {
      case 'diamond':
        return 'Diamond';
      case 'multi_platinum':
        return '${level}× Platinum';
      case 'platinum':
        return 'Platinum';
      case 'gold':
        return 'Gold';
      case 'silver':
        return 'Silver';
      default:
        return 'Certified';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
