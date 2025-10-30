import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';

/// Navigation item data
class NavItem {
  final String label;
  final IconData icon;
  final int index;

  const NavItem({
    required this.label,
    required this.icon,
    required this.index,
  });
}

/// Vertical sidebar navigation for desktop/tablet, collapsible drawer for mobile
class VerticalSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<NavItem> items;
  final Widget? header;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const VerticalSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.header,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  State<VerticalSidebar> createState() => _VerticalSidebarState();
}

class _VerticalSidebarState extends State<VerticalSidebar> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final sidebarWidth = widget.isCollapsed ? 72.0 : 240.0;

    return AnimatedContainer(
      duration: AppTheme.animationNormal,
      curve: AppTheme.animationCurve,
      width: isMobile ? double.infinity : sidebarWidth,
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated,
        border: isMobile
            ? null
            : const Border(
                right: BorderSide(color: AppTheme.borderDefault, width: 1),
              ),
      ),
      child: Column(
        children: [
          // Header (optional)
          if (widget.header != null) ...[
            widget.header!,
            const Divider(height: 1),
          ],

          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: AppTheme.space8,
                horizontal: widget.isCollapsed ? AppTheme.space8 : AppTheme.space12,
              ),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = widget.selectedIndex == item.index;
                final isHovered = _hoveredIndex == item.index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space4),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = item.index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: GestureDetector(
                      onTap: () => widget.onItemSelected(item.index),
                      child: AnimatedContainer(
                        duration: AppTheme.animationFast,
                        curve: AppTheme.animationCurve,
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isCollapsed ? AppTheme.space12 : AppTheme.space16,
                          vertical: AppTheme.space12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryCyan.withOpacity(0.1)
                              : isHovered
                                  ? AppTheme.overlayLight
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: isSelected
                              ? Border.all(
                                  color: AppTheme.primaryCyan.withOpacity(0.3),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: widget.isCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected
                                  ? AppTheme.primaryCyan
                                  : isHovered
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                              size: 22,
                            ),
                            if (!widget.isCollapsed) ...[
                              const SizedBox(width: AppTheme.space12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: isSelected
                                        ? AppTheme.primaryCyan
                                        : isHovered
                                            ? AppTheme.textPrimary
                                            : AppTheme.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Collapse toggle button (desktop/tablet only)
          if (!isMobile && widget.onToggleCollapse != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space8),
              child: IconButton(
                icon: Icon(
                  widget.isCollapsed
                      ? Icons.chevron_right
                      : Icons.chevron_left,
                  color: AppTheme.textSecondary,
                ),
                onPressed: widget.onToggleCollapse,
                tooltip: widget.isCollapsed ? 'Expand' : 'Collapse',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sidebar header with app logo and title
class SidebarHeader extends StatelessWidget {
  final bool isCollapsed;

  const SidebarHeader({
    super.key,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Row(
        children: [
          // Logo/Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryCyan, AppTheme.accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              boxShadow: AppTheme.shadowGlow,
            ),
            child: const Icon(
              Icons.music_note,
              color: AppTheme.backgroundDark,
              size: 24,
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: AppTheme.space12),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NextWave',
                    style: AppTheme.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryCyan,
                    ),
                  ),
                  Text(
                    'Music Sim',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
