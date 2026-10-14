import 'package:chronosky/providers/analytics_provider.dart';
import 'package:chronosky/providers/todo_provider.dart';
import 'package:chronosky/ui/screens/analytics_view.dart';
import 'package:chronosky/ui/screens/schedule_view.dart';
import 'package:chronosky/ui/screens/settings_view.dart';
import 'package:chronosky/ui/screens/todo_list_view.dart';
import 'package:chronosky/ui/screens/work_plans_view.dart';
import 'package:chronosky/ui/widgets/add_task_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/mocks.dart';
import '../helpers/responsive_matrix.dart';
import '../helpers/widget_harness.dart';

/// Every screen must lay out without overflowing, at every size and text
/// scale the app claims to support.
///
/// ## Why this exists
/// A `RenderFlex` overflow is invisible in release mode — no exception, no
/// log, just content silently clipped or a yellow-striped bar in debug. So it
/// is only ever found by opening the app on the right device, which is exactly
/// the device nobody has. When this test was first written **every screen
/// overflowed at 320px**, and the Tasks tab overflowed at 411px with a text
/// scale of 1.3, which is an ordinary accessibility setting on an ordinary
/// phone.
///
/// ## What it actually asserts
/// Pumping a screen and taking no exception is the assertion: Flutter reports
/// an overflow as a framework error, which `flutter_test` records and
/// `takeException` surfaces. The matrix is in
/// `test/helpers/responsive_matrix.dart`, with the reasoning for each entry.
///
/// ## When this fails
/// Do not widen the matrix or raise `maxTextScale` to make it pass. The two
/// fixes that work are making the layout flexible (`Expanded`, `Flexible`,
/// `FittedBox`, `maxLines` + ellipsis) and deriving fixed dimensions from the
/// text scale via `AppResponsive.scaled`. A grid in particular should use
/// `mainAxisExtent`, never `childAspectRatio` — a ratio ties tile height to
/// tile width, so the column count silently decides whether the contents fit,
/// which is how two of these grids broke.
void main() {
  setUpAll(registerCommonFallbacks);

  /// Screens are built lazily so each case gets a fresh widget.
  final screens = <String, Widget Function()>{
    'Schedule': () => const ScheduleView(),
    'WorkPlans': () => const WorkPlansView(),
    'Analytics': () => const AnalyticsView(),
    'Tasks': () => const TodoListView(),
    'Settings': () => const SettingsView(),
    'Add/edit task sheet': () => AddTaskSheet(
          editingTask: taskFixture(reminderEnabled: true),
          showDateControls: false,
          onAdd: (_, __) {},
          onUpdate: (_) {},
        ),
  };

  for (final entry in screens.entries) {
    group(entry.key, () {
      for (final size in responsiveProbeSizes) {
        for (final scale in responsiveProbeScales) {
          final label = '${size.width.toInt()}x${size.height.toInt()} '
              'at text scale $scale';
          testWidgets('lays out without overflow at $label', (tester) async {
            await _pumpScreen(
              tester,
              build: entry.value,
              size: size,
              textScale: scale,
            );

            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} overflows at $label',
            );
          });
        }
      }
    });
  }
}

/// Mounts [build] under the app's providers at a given size and text scale.
///
/// The schedule is seeded with one task that has a reminder armed, because an
/// empty screen is the easy case: the pills on a task card and the reminder
/// badge are what actually run out of room.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required Widget Function() build,
  required Size size,
  required double textScale,
}) async {
  final todoRepo = MockTodoRepository();
  final prefRepo = MockPreferenceRepository();
  final templateRepo = MockTemplateRepository();
  final scheduleRepo = MockScheduleRepository();
  stubTodoRepoEmpty(todoRepo);
  stubScheduleRepoSuccess(
    scheduleRepo,
    days: sevenEmptyDays(
      tasksOnFirstDay: [
        taskFixture(
          title: 'Deep work block',
          reminderEnabled: true,
          reminderLeadMinutes: 30,
        ),
      ],
    ),
  );
  stubTemplateAndPrefsSuccess(templateRepo, prefRepo);

  final provider = scheduleProviderWith(
    scheduleRepo: scheduleRepo,
    templateRepo: templateRepo,
    prefRepo: prefRepo,
  );
  final todo = TodoProvider(todoRepo, prefRepo: prefRepo);
  addTearDown(provider.dispose);
  addTearDown(todo.dispose);

  await pumpWithProviders(
    tester,
    ChangeNotifierProvider<TodoProvider>.value(
      value: todo,
      child: Builder(
        // The real app clamps the text scale once in `MyApp.builder`; this
        // mirrors it so the matrix measures what ships rather than a scale
        // the app would never pass through.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: build(),
        ),
      ),
    ),
    scheduleProvider: provider,
    analyticsProvider: AnalyticsProvider(provider),
    surfaceSize: size,
  );
  await tester.pumpAndSettle();
}
