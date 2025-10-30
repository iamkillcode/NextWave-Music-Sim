import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';
import '../widgets/stat_card.dart';
import '../models/artist_stats.dart';

/// Profile banner component with avatar, name, verified badge, followers, listeners
class ProfileBanner extends StatelessWidget {
  final ArtistStats artistStats;
  final String? profileImageUrl;

  const ProfileBanner({
    super.key,
    required this.artistStats,
    this.profileImageUrl,
  });

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  int _getTotalStreams() {
    return artistStats.songs.fold(0, (sum, song) => sum + song.streams);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      padding: EdgeInsets.all(ResponsiveLayout.getValue(
        context,
        mobile: AppTheme.space20,
        tablet: AppTheme.space24,
        desktop: AppTheme.space32,
      )),
      decoration: AppTheme.cardDecoration(
        boxShadow: AppTheme.shadowMedium,
      ),
      child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Avatar
        _buildAvatar(80),
        const SizedBox(height: AppTheme.space16),
        // Name and badge
        _buildNameRow(),
        const SizedBox(height: AppTheme.space16),
        // Stats
        _buildStatsRow(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Avatar
        _buildAvatar(100),
        const SizedBox(width: AppTheme.space24),
        // Name, badge, and stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameRow(),
              const SizedBox(height: AppTheme.space16),
              _buildStatsRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryCyan,
          width: 3,
        ),
        boxShadow: AppTheme.shadowGlow,
      ),
      child: ClipOval(
        child: profileImageUrl != null
            ? Image.network(
                profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.surfaceElevated,
      child: const Icon(
        Icons.person,
        color: AppTheme.primaryCyan,
        size: 40,
      ),
    );
  }

  Widget _buildNameRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            artistStats.name.toUpperCase(),
            style: AppTheme.headingLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppTheme.space8),
        // Verified badge
        Container(
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: AppTheme.primaryCyan,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: AppTheme.backgroundDark,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Wrap(
      spacing: AppTheme.space32,
      runSpacing: AppTheme.space12,
      children: [
        _buildStatItem(
          'Followers',
          _formatNumber(artistStats.fanbase),
          Icons.group,
        ),
        _buildStatItem(
          'Monthly Listeners',
          _formatNumber(_getTotalStreams() ~/ 30),
          Icons.headphones,
        ),
        _buildStatItem(
          'Total Streams',
          _formatNumber(_getTotalStreams()),
          Icons.play_arrow,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 18),
        const SizedBox(width: AppTheme.space8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.labelSmall,
            ),
            Text(
              value,
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Insights panel with analytics, top tracks, fan demographics
class InsightsPanel extends StatelessWidget {
  final ArtistStats artistStats;

  const InsightsPanel({
    super.key,
    required this.artistStats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: AppTheme.cardDecoration(
        boxShadow: AppTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Analytics & Insights',
            style: AppTheme.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.space24),

          // Monthly Streams Graph Placeholder
          _buildSection(
            'Monthly Streams',
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.backgroundElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.borderDefault),
              ),
              child: Center(
                child: Text(
                  'Chart Coming Soon',
                  style: AppTheme.labelMedium,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.space24),

          // Top Tracks
          _buildSection(
            'Top Tracks',
            _buildTopTracks(),
          ),

          const SizedBox(height: AppTheme.space24),

          // Fan Demographics Placeholder
          _buildSection(
            'Fan Demographics',
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.backgroundElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.borderDefault),
              ),
              child: Center(
                child: Text(
                  'Demographics Coming Soon',
                  style: AppTheme.labelMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        content,
      ],
    );
  }

  Widget _buildTopTracks() {
    final topSongs = artistStats.songs
        .where((s) => s.releasedDate != null)
        .toList()
      ..sort((a, b) => b.streams.compareTo(a.streams));

    if (topSongs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.borderDefault),
        ),
        child: Center(
          child: Text(
            'No released songs yet',
            style: AppTheme.labelMedium,
          ),
        ),
      );
    }

    return Column(
      children: topSongs.take(5).map((song) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: AppTheme.primaryCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_formatStreams(song.streams)} streams',
                      style: AppTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatStreams(int streams) {
    if (streams >= 1000000) {
      return '${(streams / 1000000).toStringAsFixed(1)}M';
    } else if (streams >= 1000) {
      return '${(streams / 1000).toStringAsFixed(1)}K';
    }
    return streams.toString();
  }
}

/// Current Progress section with 4 key metrics
class CurrentProgressSection extends StatelessWidget {
  final ArtistStats artistStats;
  final int streamsToday;
  final double fanbaseGrowth;
  final double revenueThisWeek;
  final int chartPosition;

  const CurrentProgressSection({
    super.key,
    required this.artistStats,
    required this.streamsToday,
    required this.fanbaseGrowth,
    required this.revenueThisWeek,
    required this.chartPosition,
  });

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Progress',
          style: AppTheme.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.space20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
          crossAxisSpacing: AppTheme.space16,
          mainAxisSpacing: AppTheme.space16,
          childAspectRatio: isMobile ? 3 : (isTablet ? 2.5 : 1.5),
          children: [
            StatCard(
              title: 'Streams Today',
              value: _formatNumber(streamsToday.toDouble()),
              icon: Icons.trending_up,
              changeValue: '+${(streamsToday * 0.15).toStringAsFixed(0)}',
              isPositive: true,
              accentColor: AppTheme.successGreen,
            ),
            StatCard(
              title: 'Fanbase Growth',
              value: '+${fanbaseGrowth.toStringAsFixed(1)}%',
              icon: Icons.group,
              changeValue: 'vs last week',
              isPositive: fanbaseGrowth > 0,
              accentColor: AppTheme.accentBlue,
            ),
            StatCard(
              title: 'Revenue This Week',
              value: '\$${_formatNumber(revenueThisWeek)}',
              icon: Icons.attach_money,
              changeValue: '+\$${(revenueThisWeek * 0.08).toStringAsFixed(0)}',
              isPositive: true,
              accentColor: AppTheme.chartGold,
            ),
            StatCard(
              title: 'Chart Position',
              value: chartPosition > 0 ? '#$chartPosition' : 'N/A',
              icon: Icons.leaderboard,
              changeValue: chartPosition > 0 ? '+2' : null,
              isPositive: true,
              accentColor: AppTheme.primaryCyan,
            ),
          ],
        ),
      ],
    );
  }
}
