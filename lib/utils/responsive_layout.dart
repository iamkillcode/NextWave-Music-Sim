import 'package:flutter/material.dart';

/// Responsive layout helper that adapts to different screen sizes
class ResponsiveLayout {
  /// Check if screen is mobile (width < 600)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if screen is tablet (600 <= width < 1024)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Check if screen is desktop (width >= 1024)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Get responsive value based on screen size
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive font size
  static double fontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) {
      return baseSize * 1.1;
    }
    if (isTablet(context)) {
      return baseSize * 1.05;
    }
    return baseSize;
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context, EdgeInsets basePadding) {
    if (isDesktop(context)) {
      return basePadding * 1.5;
    }
    if (isTablet(context)) {
      return basePadding * 1.25;
    }
    return basePadding;
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, double baseSpacing) {
    if (isDesktop(context)) {
      return baseSpacing * 1.5;
    }
    if (isTablet(context)) {
      return baseSpacing * 1.25;
    }
    return baseSpacing;
  }

  /// Get max content width for centered layouts
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200;
    }
    if (isTablet(context)) {
      return 800;
    }
    return double.infinity;
  }

  /// Get number of grid columns based on screen size
  static int getGridCrossAxisCount(BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isDesktop(context)) {
      return desktop;
    }
    if (isTablet(context)) {
      return tablet;
    }
    return mobile;
  }

  /// Wrap content with responsive constraints
  static Widget constrainedContent(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) {
      return baseSize * 1.2;
    }
    if (isTablet(context)) {
      return baseSize * 1.1;
    }
    return baseSize;
  }

  /// Get responsive card elevation
  static double cardElevation(BuildContext context, double baseElevation) {
    if (isDesktop(context)) {
      return baseElevation * 1.5;
    }
    return baseElevation;
  }

  /// Check if landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return screenWidth * 0.4;
    }
    if (isTablet(context)) {
      return screenWidth * 0.6;
    }
    return screenWidth * 0.9;
  }
}
