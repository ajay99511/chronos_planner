import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:chronosky/core/services/alarm_scheduler_service.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;
import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:chronosky/ui/navigation/feature_tabs.dart';
import 'package:chronosky/ui/widgets/focus_hud.dart';

class ChronosHome extends StatefulWidget {
  const ChronosHome({super.key});

  @override
  State<ChronosHome> createState() => _ChronosHomeState();
}

class _ChronosHomeState extends State<ChronosHome>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isFocusMode = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On resume (foreground again), advance the rolling week if the calendar
    // day changed while the app was backgrounded. Covers mobile; on desktop
    // the window-focus listener in main.dart does the same. Both no-op when
    // the date is unchanged.
    if (state == AppLifecycleState.resumed) {
      context.read<ScheduleStateProvider>().refreshIfDateChanged();
    }
  }

  Future<void> _toggleFocusMode() async {
    setState(() {
      _isFocusMode = !_isFocusMode;
    });

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      if (_isFocusMode) {
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setSize(const Size(320, 200));
        await windowManager.setAlignment(Alignment.topRight);
      } else {
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setSize(const Size(1200, 800));
        await windowManager.center();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The ringing overlay sits above everything (including focus mode) so an
    // alarm can always be dismissed no matter where the user is.
    final alarmService = context.watch<AlarmSchedulerService>();
    final ringing = alarmService.ringing;
    return Stack(
      children: [
        _buildMain(context),
        if (ringing != null)
          _AlarmRingingOverlay(
            alarm: ringing,
            soundUnavailable: alarmService.audioUnavailable,
            onDismiss: () => context.read<AlarmSchedulerService>().dismiss(),
          ),
      ],
    );
  }

  Widget _buildMain(BuildContext context) {
    if (_isFocusMode) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: FocusHudWidget(onExit: _toggleFocusMode),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop)
            _DesktopSidebar(
              currentIndex: _currentIndex,
              onSelect: (idx) => setState(() => _currentIndex = idx),
              onToggleFocus: _toggleFocusMode,
            ),
          Expanded(
            child: SafeArea(
              // IndexedStack keeps every tab alive so per-screen state
              // (selected task, view mode, sub-tabs, search queries) survives
              // navigation. Trades the switch animation for state retention,
              // which is the standard pattern for primary navigation.
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  for (final tab in appFeatureTabs) tab.screen,
                ],
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
                    items: [
                      for (final tab in appFeatureTabs)
                        BottomNavigationBarItem(
                          icon: Icon(tab.icon),
                          label: tab.compactLabel,
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ─── Alarm ringing overlay ──────────────────────
class _AlarmRingingOverlay extends StatelessWidget {
  final domain.TodoItem alarm;

  /// Whether the alarm's sound could not be played. Shown explicitly, because
  /// a silent alarm is otherwise indistinguishable from a muted device and the
  /// user has no other way to learn their sound file has gone missing.
  final bool soundUnavailable;
  final VoidCallback onDismiss;

  const _AlarmRingingOverlay({
    required this.alarm,
    required this.onDismiss,
    this.soundUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheduled = alarm.scheduledAt;
    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.xl),
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.neonBlue.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonBlue.withValues(alpha: 0.3),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.alarm_rounded,
                color: AppColors.neonBlue,
                size: 56,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                alarm.title,
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
              if (alarm.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  alarm.description,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              if (scheduled != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DateFormat('EEE, MMM d • HH:mm').format(scheduled),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
              if (soundUnavailable) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.volume_off_rounded,
                      color: Colors.orangeAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Sound couldn't be played — the file may have moved.",
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.orangeAccent),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: onDismiss,
                child: const Text(
                  'DISMISS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
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
  final VoidCallback onToggleFocus;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onSelect,
    required this.onToggleFocus,
  });

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
                  child: const Icon(
                    Icons.access_time_filled,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'CHRONOS',
                  style: AppTextStyles.heading3
                      .copyWith(letterSpacing: 1.2, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonBlue.withValues(alpha: 0.1),
                foregroundColor: AppColors.neonCyan,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                side: BorderSide(
                  color: AppColors.neonBlue.withValues(alpha: 0.3),
                ),
              ),
              onPressed: onToggleFocus,
              icon: const Icon(Icons.bolt, size: 18),
              label: const Text('Enter Focus HUD'),
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < appFeatureTabs.length; i++)
            _SidebarItem(
              index: i,
              icon: appFeatureTabs[i].icon,
              label: appFeatureTabs[i].label,
              isSelected: currentIndex == i,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          // Footer
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Chronos v1.0',
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

    return Semantics(
      button: true,
      selected: isActive,
      label: widget.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (hovering) => setState(() => _isHovered = hovering),
          borderRadius: BorderRadius.circular(AppRadius.md),
          focusColor: AppColors.neonBlue.withValues(alpha: 0.12),
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
                Icon(
                  widget.icon,
                  color: isActive
                      ? AppColors.neonBlue
                      : (_isHovered ? Colors.white70 : Colors.grey),
                  size: 20,
                ),
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
      ),
    );
  }
}
