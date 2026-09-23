import 'package:flutter/material.dart';

import 'package:chronosky/ui/screens/analytics_view.dart';
import 'package:chronosky/ui/screens/schedule_view.dart';
import 'package:chronosky/ui/screens/todo_list_view.dart';
import 'package:chronosky/ui/screens/work_plans_view.dart';

/// One primary destination in the app shell.
@immutable
class FeatureTab {
  const FeatureTab({
    required this.icon,
    required this.label,
    required this.compactLabel,
    required this.screen,
  });

  final IconData icon;

  /// Used by the desktop sidebar, which has room for the full name.
  final String label;

  /// Used by the bottom navigation bar, where width is tight.
  final String compactLabel;

  final Widget screen;
}

/// The app's primary destinations, in display order.
///
/// Both navigation surfaces and the IndexedStack derive from this list, so a
/// new destination is one entry here rather than four separate edits — the
/// screen list, the sidebar items, the bottom-bar items and the ordering
/// between them, which previously had to be kept in agreement by hand.
const List<FeatureTab> appFeatureTabs = [
  FeatureTab(
    icon: Icons.calendar_today,
    label: 'Schedule',
    compactLabel: 'Schedule',
    screen: ScheduleView(),
  ),
  FeatureTab(
    icon: Icons.layers_outlined,
    label: 'WorkPlans',
    compactLabel: 'Plans',
    screen: WorkPlansView(),
  ),
  FeatureTab(
    icon: Icons.pie_chart_outline,
    label: 'Analytics',
    compactLabel: 'Insights',
    screen: AnalyticsView(),
  ),
  FeatureTab(
    icon: Icons.check_box_outlined,
    label: 'Tasks',
    compactLabel: 'Tasks',
    screen: TodoListView(),
  ),
];
