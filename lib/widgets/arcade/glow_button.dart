import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/nextwave_theme.dart';

/// Glowing arcade-style button with scale and glow animations
class GlowButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? glowColor;
  final Gradient? gradient;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool enabled;
  final double glowIntensity;

  const GlowButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.glowColor,
    this.gradient,
    this.icon,
    this.width,
    this.height,
    this.enabled = true,
    this.glowIntensity = 1.0,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: NextWaveTheme.normalDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor =
        widget.glowColor ?? NextWaveTheme.electricGold;
    final effectiveGradient = widget.gradient ?? NextWaveTheme.goldGradient;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              width: widget.width,
              height: widget.height ?? 56,
              decoration: BoxDecoration(
                gradient: widget.enabled ? effectiveGradient : null,
                color: widget.enabled
                    ? null
                    : NextWaveTheme.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.enabled
                      ? effectiveGlowColor.withOpacity(0.5)
                      : NextWaveTheme.textTertiary.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: widget.enabled
                    ? [
                        BoxShadow(
                          color: effectiveGlowColor
                              .withOpacity(0.3 * _glowAnimation.value * widget.glowIntensity),
                          blurRadius: 20 * _glowAnimation.value,
                          spreadRadius: 2 * _glowAnimation.value,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.enabled
                            ? Colors.black
                            : NextWaveTheme.textTertiary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      widget.text,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: widget.enabled
                                ? Colors.black
                                : NextWaveTheme.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
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
