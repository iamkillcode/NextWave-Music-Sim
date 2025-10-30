import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable metric card component for displaying key stats
/// Used in dashboard "Current Progress" section
class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? changeValue;
  final bool? isPositive;
  final Color? accentColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.changeValue,
    this.isPositive,
    this.accentColor,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.accentColor ?? AppTheme.primaryCyan;
    final changeColor = widget.isPositive == true
        ? AppTheme.successGreen
        : widget.isPositive == false
            ? AppTheme.errorRed
            : AppTheme.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          curve: AppTheme.animationCurve,
          padding: const EdgeInsets.all(AppTheme.space20),
          decoration: AppTheme.cardDecoration(
            boxShadow: _isHovered ? AppTheme.shadowMedium : AppTheme.shadowSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space8),
                    decoration: BoxDecoration(
                      color: effectiveColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      widget.icon,
                      color: effectiveColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTheme.labelLarge.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              // Value
              Text(
                widget.value,
                style: AppTheme.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Change indicator (optional)
              if (widget.changeValue != null) ...[
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: [
                    Icon(
                      widget.isPositive == true
                          ? Icons.arrow_upward
                          : widget.isPositive == false
                              ? Icons.arrow_downward
                              : Icons.remove,
                      color: changeColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      widget.changeValue!,
                      style: AppTheme.labelMedium.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
