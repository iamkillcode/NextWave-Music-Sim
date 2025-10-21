import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../theme/nextwave_theme.dart';

class RewardItem {
  final String icon;
  final String label;
  final int value;

  const RewardItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// Animated reward popup with sparkle particles and count-up animations
class RewardPopup extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;
  final List<RewardItem> rewards;
  final VoidCallback? onDismiss;

  const RewardPopup({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor,
    required this.rewards,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color? accentColor,
    required List<RewardItem> rewards,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RewardPopup(
        title: title,
        subtitle: subtitle,
        icon: icon,
        accentColor: accentColor,
        rewards: rewards,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<RewardPopup> createState() => _RewardPopupState();
}

class _RewardPopupState extends State<RewardPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _sparkleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Scale and fade animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    // Sparkle animation (continuous)
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Delay before showing popup
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.accentColor ?? NextWaveTheme.electricGold;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Sparkle particles
              ...List.generate(12, (index) => _buildSparkle(index, effectiveColor)),
              
              // Main content
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      NextWaveTheme.surfaceDark,
                      NextWaveTheme.surfaceMedium,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: effectiveColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            effectiveColor,
                            effectiveColor.withOpacity(0.6),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: effectiveColor.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 48,
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [effectiveColor, effectiveColor.withOpacity(0.8)],
                      ).createShader(bounds),
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Rewards list
                    ...widget.rewards.map((reward) => _buildRewardItem(reward)),
                    
                    const SizedBox(height: 24),
                    
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onDismiss?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: effectiveColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'AWESOME!',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardItem(RewardItem reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            reward.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reward.label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          TweenAnimationBuilder<int>(
            duration: const Duration(milliseconds: 800),
            tween: IntTween(begin: 0, end: reward.value),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Text(
                '+$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: NextWaveTheme.successGreen,
                      fontWeight: FontWeight.w700,
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSparkle(int index, Color color) {
    final angle = (index * 30.0) * (math.pi / 180);
    final distance = 80.0 + (index % 3) * 20.0;

    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        final progress = (_sparkleController.value + (index * 0.1)) % 1.0;
        final opacity = (math.sin(progress * math.pi) * 0.8).clamp(0.0, 1.0);
        final scale = 0.5 + (math.sin(progress * math.pi) * 0.5);

        return Positioned(
          left: 150 + math.cos(angle) * distance * progress,
          top: 50 + math.sin(angle) * distance * progress,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
