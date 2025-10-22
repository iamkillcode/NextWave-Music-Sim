import 'package:flutter/material.dart';
import 'dart:ui';

/// Glassmorphic Bottom Navigation Bar - iOS 26 Style
///
/// Provides a frosted glass effect with blur and transparency
/// for a modern, premium feel consistent across all screens.
class GlassmorphicBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  const GlassmorphicBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B0D17).withOpacity(0.75),
              backgroundBlendMode: BlendMode.lighten,
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor:
                  selectedItemColor ?? const Color(0xFF00D9FF), // Cyan
              unselectedItemColor: unselectedItemColor ?? Colors.white54,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
              ),
              items: items,
            ),
          ),
        ),
      ),
    );
  }
}
