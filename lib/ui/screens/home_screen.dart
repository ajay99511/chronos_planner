import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'analytics_view.dart';
import 'schedule_view.dart';
import 'work_plans_view.dart';

class ChronosHome extends StatefulWidget {
  const ChronosHome({super.key});

  @override
  State<ChronosHome> createState() => _ChronosHomeState();
}

class _ChronosHomeState extends State<ChronosHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ScheduleView(),
    WorkPlansView(),
    AnalyticsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop)
            _DesktopSidebar(
              currentIndex: _currentIndex,
              onSelect: (idx) => setState(() => _currentIndex = idx),
            ),
          Expanded(
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: AppAnimDurations.normal,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.02, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_currentIndex),
                  child: _screens[_currentIndex],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white10)),
                    color: Color(0xCC0F172A),
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    currentIndex: _currentIndex,
                    onTap: (idx) => setState(() => _currentIndex = idx),
                    selectedItemColor: AppColors.neonBlue,
                    unselectedItemColor: Colors.grey,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    type: BottomNavigationBarType.fixed,
                    selectedFontSize: 12,
                    unselectedFontSize: 12,
                    items: const [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.calendar_today), label: "Schedule"),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.layers_outlined), label: "Plans"),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.pie_chart_outline),
                          label: "Insights"),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ─── Desktop Sidebar ────────────────────────────
class _DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _DesktopSidebar({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryBlue,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.access_time_filled,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "CHRONOS",
                  style: AppTextStyles.heading3
                      .copyWith(letterSpacing: 1.2, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          _SidebarItem(
              index: 0,
              icon: Icons.calendar_today,
              label: "Schedule",
              isSelected: currentIndex == 0,
              onTap: () => onSelect(0)),
          _SidebarItem(
              index: 1,
              icon: Icons.layers_outlined,
              label: "WorkPlans",
              isSelected: currentIndex == 1,
              onTap: () => onSelect(1)),
          _SidebarItem(
              index: 2,
              icon: Icons.pie_chart_outline,
              label: "Analytics",
              isSelected: currentIndex == 2,
              onTap: () => onSelect(2)),
          const Spacer(),
          // Footer
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              "Chronos v1.0",
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;
    final showHighlight = isActive || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimDurations.fast,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: showHighlight
                ? AppColors.neonBlue.withValues(alpha: isActive ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              // Active indicator bar
              AnimatedContainer(
                duration: AppAnimDurations.fast,
                width: 3,
                height: isActive ? 24 : 0,
                decoration: BoxDecoration(
                  color: AppColors.neonBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: isActive ? 12 : 0),
              Icon(widget.icon,
                  color: isActive
                      ? AppColors.neonBlue
                      : (_isHovered ? Colors.white70 : Colors.grey),
                  size: 20),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : (_isHovered ? Colors.white70 : Colors.grey),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
