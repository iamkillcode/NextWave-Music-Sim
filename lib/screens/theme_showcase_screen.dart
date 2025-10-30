import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_progress_bar.dart';
import '../widgets/neon_stat_card.dart';

/// Example screen showcasing the new futuristic gamified theme
/// 
/// Demonstrates:
/// - Neon green/purple color palette
/// - Glowing progress bars
/// - Stat cards with depth
/// - Futuristic typography
/// - Dark backgrounds with subtle accents
class ThemeShowcaseScreen extends StatelessWidget {
  const ThemeShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundElevated,
        elevation: 0,
        title: Text(
          'FUTURISTIC THEME',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.neonGreen,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),
            
            const SizedBox(height: 32),
            
            // Stats Grid
            _buildStatsGrid(),
            
            const SizedBox(height: 32),
            
            // Skills Section with Progress Bars
            _buildSkillsSection(),
            
            const SizedBox(height: 32),
            
            // Compact Stats Row
            _buildCompactStats(),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.backgroundElevated,
            AppTheme.surfaceDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.borderGlow.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: AppTheme.shadowGlowGreen,
      ),
      child: Column(
        children: [
          // Player Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.neonGreen, AppTheme.neonPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: AppTheme.shadowGlowMixed,
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Player Name
          Text(
            'DJ ARTEMIS',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.textPrimary,
              shadows: const [
                Shadow(
                  color: AppTheme.neonGreen,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: AppTheme.glassmorphicDecoration(withGlow: true),
            child: Text(
              'LEVEL 42',
              style: AppTheme.labelLarge.copyWith(
                color: AppTheme.neonGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // XP Progress
          const NeonProgressBar(
            progress: 0.68,
            label: 'EXPERIENCE',
            style: NeonProgressBarStyle.mixed,
            height: 20,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAREER STATS',
          style: AppTheme.headingSmall.copyWith(
            color: AppTheme.textPrimary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: const [
            NeonStatCard(
              title: 'Fanbase',
              value: '127.5K',
              icon: Icons.people,
              accentColor: AppTheme.neonGreen,
              subtitle: '+2.4K this week',
              progress: 0.65,
            ),
            NeonStatCard(
              title: 'Fame',
              value: '1,247',
              icon: Icons.star,
              accentColor: AppTheme.neonPurple,
              subtitle: 'Rising star',
              progress: 0.82,
            ),
            NeonStatCard(
              title: 'Total Streams',
              value: '5.2M',
              icon: Icons.play_arrow,
              accentColor: AppTheme.accentBlue,
              subtitle: '+450K today',
            ),
            NeonStatCard(
              title: 'Money',
              value: '\$196K',
              icon: Icons.attach_money,
              accentColor: AppTheme.chartGold,
              subtitle: 'Net worth',
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SKILL LEVELS',
          style: AppTheme.headingSmall.copyWith(
            color: AppTheme.textPrimary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration(),
          child: const Column(
            children: [
              NeonProgressBar(
                progress: 0.85,
                label: 'VOCAL PERFORMANCE',
                style: NeonProgressBarStyle.green,
                height: 24,
              ),
              SizedBox(height: 16),
              NeonProgressBar(
                progress: 0.72,
                label: 'MUSIC PRODUCTION',
                style: NeonProgressBarStyle.purple,
                height: 24,
              ),
              SizedBox(height: 16),
              NeonProgressBar(
                progress: 0.91,
                label: 'STAGE PRESENCE',
                style: NeonProgressBarStyle.mixed,
                height: 24,
              ),
              SizedBox(height: 16),
              NeonProgressBar(
                progress: 0.58,
                label: 'MARKETING',
                style: NeonProgressBarStyle.blue,
                height: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCompactStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK STATS',
          style: AppTheme.headingSmall.copyWith(
            color: AppTheme.textPrimary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        const Column(
          children: [
            NeonStatCardCompact(
              label: 'Songs Released',
              value: '24',
              icon: Icons.music_note,
              accentColor: AppTheme.neonGreen,
            ),
            SizedBox(height: 12),
            NeonStatCardCompact(
              label: 'Albums',
              value: '3 EPs, 2 LPs',
              icon: Icons.album,
              accentColor: AppTheme.neonPurple,
            ),
            SizedBox(height: 12),
            NeonStatCardCompact(
              label: 'Chart Position',
              value: '#12 Global',
              icon: Icons.trending_up,
              accentColor: AppTheme.chartGold,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIONS',
          style: AppTheme.headingSmall.copyWith(
            color: AppTheme.textPrimary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPrimaryButton('LEVEL UP', Icons.arrow_upward),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryButton('VIEW STATS', Icons.bar_chart),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPrimaryButton(String label, IconData icon) {
    return Container(
      height: 56,
      decoration: AppTheme.primaryButtonDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.backgroundDark),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.backgroundDark,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSecondaryButton(String label, IconData icon) {
    return Container(
      height: 56,
      decoration: AppTheme.secondaryButtonDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.textPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
