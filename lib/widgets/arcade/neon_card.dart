import 'package:flutter/material.dart';
import '../../theme/nextwave_theme.dart';

/// Neon-styled card with glow effect
class NeonCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowIntensity;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const NeonCard({
    super.key,
    required this.child,
    this.glowColor = NextWaveTheme.neonCyan,
    this.glowIntensity = 1.0,
    this.padding,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient == null ? NextWaveTheme.surfaceDark : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: glowColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.3 * glowIntensity),
            blurRadius: 20 * glowIntensity,
            spreadRadius: 2 * glowIntensity,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
