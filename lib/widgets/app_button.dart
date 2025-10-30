import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonType { primary, secondary, outline, text }

enum AppButtonSize { small, medium, large }

/// Standardized button component with consistent styling
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  double get _height {
    switch (widget.size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
    }
  }

  double get _horizontalPadding {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppTheme.space12;
      case AppButtonSize.medium:
        return AppTheme.space20;
      case AppButtonSize.large:
        return AppTheme.space24;
    }
  }

  TextStyle get _textStyle {
    final baseStyle = widget.size == AppButtonSize.small
        ? AppTheme.labelLarge
        : AppTheme.bodyMedium;

    switch (widget.type) {
      case AppButtonType.primary:
        return baseStyle.copyWith(
          color: AppTheme.backgroundDark,
          fontWeight: FontWeight.w600,
        );
      case AppButtonType.secondary:
      case AppButtonType.outline:
      case AppButtonType.text:
        return baseStyle.copyWith(
          color: widget.onPressed == null
              ? AppTheme.textDisabled
              : AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        );
    }
  }

  BoxDecoration? get _decoration {
    if (widget.type == AppButtonType.text) return null;

    final isDisabled = widget.onPressed == null;

    switch (widget.type) {
      case AppButtonType.primary:
        return BoxDecoration(
          gradient: isDisabled
              ? null
              : const LinearGradient(
                  colors: [AppTheme.primaryCyan, AppTheme.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isDisabled ? AppTheme.textDisabled : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: _isPressed || isDisabled ? [] : AppTheme.shadowMedium,
        );

      case AppButtonType.secondary:
        return BoxDecoration(
          color: isDisabled
              ? AppTheme.surfaceDark.withOpacity(0.5)
              : _isHovered
                  ? AppTheme.surfaceElevated
                  : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.borderDefault, width: 1),
        );

      case AppButtonType.outline:
        return BoxDecoration(
          color: _isHovered ? AppTheme.overlayLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isDisabled ? AppTheme.textDisabled : AppTheme.primaryCyan,
            width: 1.5,
          ),
        );

      case AppButtonType.text:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isLoading || isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          curve: AppTheme.animationCurve,
          height: _height,
          width: widget.isFullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          decoration: _decoration,
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.type == AppButtonType.primary
                            ? AppTheme.backgroundDark
                            : AppTheme.primaryCyan,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: widget.size == AppButtonSize.small ? 16 : 20,
                          color: widget.type == AppButtonType.primary
                              ? AppTheme.backgroundDark
                              : isDisabled
                                  ? AppTheme.textDisabled
                                  : AppTheme.primaryCyan,
                        ),
                        const SizedBox(width: AppTheme.space8),
                      ],
                      Text(widget.text, style: _textStyle),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
