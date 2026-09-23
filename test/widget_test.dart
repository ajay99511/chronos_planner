import 'dart:async';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:chronosky/ui/screens/schedule_view.dart';
import 'package:chronosky/ui/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/mocks.dart';
import 'helpers/widget_harness.dart';

/// First widget coverage for the schedule screen.
///
/// The presentation layer had none, which meant the app's most intricate
/// behaviour — an optimistic write, its rollback, and the snackbar that tells
/// the user it failed — was only ever verified at the provider boundary, one
/// layer below where it actually goes wrong.
void main() {
  late MockScheduleRepository scheduleRepo;
  late MockTemplateRepository templateRepo;
  late MockPreferenceRepository prefRepo;
  late ScheduleStateProvider provider;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    scheduleRepo = MockScheduleRepository();
    templateRepo = MockTemplateRepository();
    prefRepo = MockPreferenceRepository();
    stubTemplateAndPrefsSuccess(templateRepo, prefRepo);
  });

  tearDown(() => provider.dispose());

  ScheduleStateProvider build() => provider = scheduleProviderWith(
        scheduleRepo: scheduleRepo,
        templateRepo: templateRepo,
        prefRepo: prefRepo,
      );

  group('ScheduleView loading and error states', () {
    testWidgets('shows a spinner while the first load is in flight',
        (tester) async {
      // The load has to be held open explicitly: a mock that returns an
      // already-resolved future completes on the first microtask drain, so
      // the loading frame would never be observable.
      final gate = Completer<Result<List<DayPlan>>>();
      stubScheduleRepoSuccess(scheduleRepo);
      when(() => scheduleRepo.getUpcomingDays(any()))
          .thenAnswer((_) => gate.future);

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete(Success(sevenEmptyDays()));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the failure and a Retry action when the load fails',
        (tester) async {
      when(() => scheduleRepo.getUpcomingDays(any())).thenAnswer(
        (_) async => const Failure(DatabaseFailure('disk unreadable')),
      );

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('disk unreadable'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });

    testWidgets('Retry re-reads the schedule and recovers', (tester) async {
      stubScheduleRepoSuccess(scheduleRepo);
      var attempt = 0;
      when(() => scheduleRepo.getUpcomingDays(any())).thenAnswer((_) async {
        attempt++;
        return attempt == 1
            ? const Failure(DatabaseFailure('temporarily locked'))
            : Success(sevenEmptyDays(tasksOnFirstDay: [taskFixture()]));
      });

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('temporarily locked'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.textContaining('temporarily locked'), findsNothing);
      expect(find.text('Deep work'), findsOneWidget);
    });
  });

  group('ScheduleView task rendering', () {
    testWidgets('renders the selected day\'s tasks', (tester) async {
      stubScheduleRepoSuccess(
        scheduleRepo,
        days: sevenEmptyDays(
          tasksOnFirstDay: [
            taskFixture(id: 't1', title: 'Write the audit'),
            taskFixture(id: 't2', title: 'Review the diff', startTime: '13:00'),
          ],
        ),
      );

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Write the audit'), findsOneWidget);
      expect(find.text('Review the diff'), findsOneWidget);
    });
  });

  // These guard the rebuild scoping introduced in 2.3. Provider's Selector
  // hands back a cached child when the selected value is unchanged, so any
  // widget state captured in a builder closure — the view mode, the selected
  // day — can silently stop propagating. Each of these would catch that.
  group('ScheduleView interaction', () {
    testWidgets('toggling the view mode updates the toolbar affordance',
        (tester) async {
      stubScheduleRepoSuccess(
        scheduleRepo,
        days: sevenEmptyDays(tasksOnFirstDay: [taskFixture()]),
      );

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Switch to List View'), findsOneWidget);

      await tester.tap(find.byTooltip('Switch to List View'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Switch to Card View'), findsOneWidget);
      expect(find.byTooltip('Switch to List View'), findsNothing);
    });

    testWidgets('selecting another day swaps the rendered tasks',
        (tester) async {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      stubScheduleRepoSuccess(
        scheduleRepo,
        days: [
          dayPlanFixture(
            id: 'day-0',
            date: start,
            tasks: [taskFixture(id: 't0', title: 'Task for today')],
          ),
          dayPlanFixture(
            id: 'day-1',
            date: start.add(const Duration(days: 1)),
            tasks: [taskFixture(id: 't1', title: 'Task for tomorrow')],
          ),
        ],
      );

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task for today'), findsOneWidget);
      expect(find.text('Task for tomorrow'), findsNothing);

      provider.selectDay(1);
      await tester.pumpAndSettle();

      expect(find.text('Task for today'), findsNothing);
      expect(find.text('Task for tomorrow'), findsOneWidget);
    });

    testWidgets('an empty day shows the empty state, not a bare list',
        (tester) async {
      stubScheduleRepoSuccess(scheduleRepo);

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No plans for'), findsOneWidget);
    });

    testWidgets('toggling sort order reverses the rendered task order',
        (tester) async {
      stubScheduleRepoSuccess(
        scheduleRepo,
        days: sevenEmptyDays(
          tasksOnFirstDay: [
            taskFixture(id: 'early', title: 'Early', startTime: '08:00'),
            taskFixture(id: 'late', title: 'Late', startTime: '17:00'),
          ],
        ),
      );

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pumpAndSettle();

      // Assert tree order rather than geometry: on a wide surface the cards
      // lay out side by side in a Wrap, so both share a y coordinate.
      List<String> renderedOrder() => tester
          .widgetList<TaskCard>(find.byType(TaskCard))
          .map((card) => card.task.title)
          .toList();

      expect(renderedOrder(), ['Early', 'Late']);

      await provider.toggleSortOrder();
      await tester.pumpAndSettle();

      expect(renderedOrder(), ['Late', 'Early']);
    });
  });

  group('ScheduleView failed-write reporting', () {
    // This is the user-visible half of C-3. The provider rolls back its
    // optimistic change and records a transient error; the screen has to
    // actually surface it, or a lost write looks identical to a saved one.
    testWidgets('rolls back the optimistic row and surfaces the failure',
        (tester) async {
      stubScheduleRepoSuccess(scheduleRepo);
      when(() => scheduleRepo.addTaskToDate(any(), any())).thenAnswer(
        (_) async => const Failure(DatabaseFailure('disk full')),
      );

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pumpAndSettle();

      await provider.addTask(taskFixture(title: 'Doomed task'));
      await tester.pumpAndSettle();

      expect(
        find.text('Doomed task'),
        findsNothing,
        reason: 'the optimistic row must be rolled back',
      );
      expect(
        find.textContaining("Couldn't save"),
        findsOneWidget,
        reason: 'the failure must be surfaced, not swallowed',
      );
    });

    testWidgets('a successful write keeps the task and shows no error',
        (tester) async {
      stubScheduleRepoSuccess(scheduleRepo);

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pumpAndSettle();

      await provider.addTask(taskFixture(title: 'Saved task'));
      await tester.pumpAndSettle();

      expect(find.text('Saved task'), findsOneWidget);
      expect(find.textContaining("Couldn't save"), findsNothing);
    });

    testWidgets('reports a failure only once', (tester) async {
      stubScheduleRepoSuccess(scheduleRepo);
      when(() => scheduleRepo.addTaskToDate(any(), any())).thenAnswer(
        (_) async => const Failure(DatabaseFailure('disk full')),
      );

      await pumpWithProviders(
        tester,
        const ScheduleView(),
        scheduleProvider: build(),
      );
      await tester.pumpAndSettle();

      await provider.addTask(taskFixture(title: 'Doomed task'));
      await tester.pumpAndSettle();
      expect(find.textContaining("Couldn't save"), findsOneWidget);

      // takeTransientError is read-and-clear, so an unrelated rebuild must
      // not resurrect the same message.
      provider.selectDay(1);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.textContaining("Couldn't save"), findsNothing);
    });
  });
}
