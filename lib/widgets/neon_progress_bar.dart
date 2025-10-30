import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A futuristic progress bar with glowing neon gradients
/// 
/// Features:
/// - Smooth gradient from dark to bright glowing colors
/// - Customizable colors (green, purple, or mixed)
/// - Rounded corners with subtle shadows
/// - Clear, legible text overlay
/// - Responsive sizing
class NeonProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? label;
  final double height;
  final NeonProgressBarStyle style;
  final bool showPercentage;
  final bool showGlow;
  
  const NeonProgressBar({
    super.key,
    required this.progress,
    this.label,
    this.height = 24,
    this.style = NeonProgressBarStyle.green,
    this.showPercentage = true,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress.clamp(0.0, 1.0) * 100).toInt();
    final gradient = _getGradient();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          children: [
            // Background track
            Container(
              height: height,
              decoration: BoxDecoration(
                color: AppTheme.backgroundElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: AppTheme.borderMuted,
                  width: 1.5,
                ),
                boxShadow: AppTheme.shadowSmall,
              ),
            ),
            
            // Foreground progress with gradient
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                  height: height,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    boxShadow: showGlow ? _getGlowShadow() : [],
                  ),
                );
              },
            ),
            
            // Text overlay
            if (showPercentage)
              SizedBox(
                height: height,
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: height * 0.5,
                      fontWeight: FontWeight.w800,
                      color: progress > 0.3 
                          ? AppTheme.backgroundDark
                          : AppTheme.textPrimary,
                      letterSpacing: 0.5,
                      shadows: progress > 0.3
                          ? [
                              const Shadow(
                                color: Colors.black26,
                                blurRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  LinearGradient _getGradient() {
    switch (style) {
      case NeonProgressBarStyle.green:
        return const LinearGradient(
          colors: [
            Color(0xFF003D26), // Dark green start
            Color(0xFF00664D), // Mid green
            AppTheme.neonGreen, // Bright glowing green
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case NeonProgressBarStyle.purple:
        return const LinearGradient(
          colors: [
            Color(0xFF330044), // Dark purple start
            Color(0xFF660088), // Mid purple
            AppTheme.neonPurple, // Bright glowing purple
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case NeonProgressBarStyle.mixed:
        return const LinearGradient(
          colors: [
            Color(0xFF003D26), // Dark green
            AppTheme.neonGreen, // Bright green
            Color(0xFF00CCFF), // Cyan
            AppTheme.neonPurple, // Purple
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case NeonProgressBarStyle.blue:
        return const LinearGradient(
          colors: [
            Color(0xFF003344), // Dark blue start
            Color(0xFF0066AA), // Mid blue
            AppTheme.accentBlue, // Bright glowing blue
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
    }
  }
  
  List<BoxShadow> _getGlowShadow() {
    switch (style) {
      case NeonProgressBarStyle.green:
        return AppTheme.shadowGlowGreen;
      case NeonProgressBarStyle.purple:
        return AppTheme.shadowGlowPurple;
      case NeonProgressBarStyle.mixed:
        return AppTheme.shadowGlowMixed;
      case NeonProgressBarStyle.blue:
        return const [
          BoxShadow(
            color: Color(0x8000CCFF),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ];
    }
  }
}

enum NeonProgressBarStyle {
  green,
  purple,
  mixed,
  blue,
}
