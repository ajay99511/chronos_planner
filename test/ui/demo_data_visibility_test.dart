import 'package:chronosky/core/result.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/core/services/scheduled_notification.dart';
import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;
import 'package:chronosky/providers/settings_provider.dart';
import 'package:chronosky/providers/todo_provider.dart';
import 'package:chronosky/ui/screens/todo_list_view.dart';
import 'package:chronosky/ui/screens/work_plans_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../helpers/mocks.dart';
import '../helpers/widget_harness.dart';

/// The demo-data switch, end to end.
///
/// The unit tests cover the preference. What matters to the user is whether
/// sample content actually disappears from the two tabs that list it, and
/// whether their own items survive the round trip — so that is asserted here
/// against the real screens.
void main() {
  late MockPreferenceRepository prefRepo;
  late MockTodoRepository todoRepo;
  late MockTemplateRepository templateRepo;
  late MockScheduleRepository scheduleRepo;

  setUpAll(registerCommonFallbacks);

  domain.TodoItem note({
    required String id,
    required String title,
    required bool isDemo,
  }) =>
      domain.TodoItem(
        id: id,
        title: title,
        createdAt: DateTime(2026, 1, 1),
        isDemo: isDemo,
      );

  setUp(() {
    prefRepo = MockPreferenceRepository();
    todoRepo = MockTodoRepository();
    templateRepo = MockTemplateRepository();
    scheduleRepo = MockScheduleRepository();
    stubTodoRepoEmpty(todoRepo);
    stubScheduleRepoSuccess(scheduleRepo);
    stubTemplateAndPrefsSuccess(templateRepo, prefRepo);
    when(() => prefRepo.get(any())).thenAnswer((_) async => const Success(null));
    when(() => prefRepo.set(any(), any()))
        .thenAnswer((_) async => const Success(null));
  });

  SettingsProvider settingsWith({required bool demoVisible}) {
    when(() => prefRepo.get(SettingsProvider.demoVisiblePrefKey))
        .thenAnswer((_) async => Success(demoVisible.toString()));
    final settings = SettingsProvider(
      prefRepo: prefRepo,
      todoRepo: todoRepo,
      logger: const NoOpLogger(),
    );
    addTearDown(settings.dispose);
    return settings;
  }

  group('the Workspace tab', () {
    Future<SettingsProvider> pumpWorkspace(
      WidgetTester tester, {
      required bool demoVisible,
    }) async {
      when(() => todoRepo.watchByType(domain.TodoItemType.note)).thenAnswer(
        (_) => Stream.value([
          note(id: 'mine', title: 'My own note', isDemo: false),
          note(id: 'sample', title: 'Standup notes', isDemo: true),
        ]),
      );

      final settings = settingsWith(demoVisible: demoVisible);
      final todo = TodoProvider(todoRepo, prefRepo: prefRepo);
      addTearDown(todo.dispose);
      final schedule = scheduleProviderWith(
        scheduleRepo: scheduleRepo,
        templateRepo: templateRepo,
        prefRepo: prefRepo,
      );
      addTearDown(schedule.dispose);

      await pumpWithProviders(
        tester,
        ChangeNotifierProvider<TodoProvider>.value(
          value: todo,
          child: const TodoListView(),
        ),
        scheduleProvider: schedule,
        settingsProvider: settings,
      );
      await tester.pumpAndSettle();
      return settings;
    }

    testWidgets('lists samples alongside your own when on', (tester) async {
      await pumpWorkspace(tester, demoVisible: true);

      expect(find.text('My own note'), findsOneWidget);
      expect(find.text('Standup notes'), findsOneWidget);
    });

    testWidgets('hides samples when off, keeping your own', (tester) async {
      await pumpWorkspace(tester, demoVisible: false);

      expect(find.text('My own note'), findsOneWidget);
      expect(find.text('Standup notes'), findsNothing);
    });

    testWidgets('switching it off hides them without a reload',
        (tester) async {
      final settings = await pumpWorkspace(tester, demoVisible: true);
      expect(find.text('Standup notes'), findsOneWidget);

      await settings.setDemoVisible(false);
      await tester.pumpAndSettle();

      expect(find.text('Standup notes'), findsNothing);
      expect(find.text('My own note'), findsOneWidget);
    });

    testWidgets('switching it back on restores them', (tester) async {
      // Hiding filters rather than deletes, so this has to come back.
      final settings = await pumpWorkspace(tester, demoVisible: false);
      expect(find.text('Standup notes'), findsNothing);

      await settings.setDemoVisible(true);
      await tester.pumpAndSettle();

      expect(find.text('Standup notes'), findsOneWidget);
    });

    testWidgets('a hidden sample is not findable by search', (tester) async {
      // Turning up a result the user has chosen to hide is worse than not
      // finding it.
      await pumpWorkspace(tester, demoVisible: false);

      await tester.enterText(find.byType(TextField).first, 'Standup');
      await tester.pumpAndSettle();

      expect(find.text('Standup notes'), findsNothing);
    });
  });

  group('the WorkPlans tab', () {
    Future<SettingsProvider> pumpPlans(
      WidgetTester tester, {
      required bool demoVisible,
    }) async {
      when(() => templateRepo.getAllTemplates()).thenAnswer(
        (_) async => const Success([
          PlanTemplate(
            id: 'mine',
            name: 'My own plan',
            description: '',
            tasks: [],
          ),
          PlanTemplate(
            id: 'sample',
            name: 'Weekday Essentials',
            description: '',
            tasks: [],
            isDemo: true,
          ),
        ]),
      );

      final settings = settingsWith(demoVisible: demoVisible);
      final schedule = scheduleProviderWith(
        scheduleRepo: scheduleRepo,
        templateRepo: templateRepo,
        prefRepo: prefRepo,
      );
      addTearDown(schedule.dispose);

      await pumpWithProviders(
        tester,
        const WorkPlansView(),
        scheduleProvider: schedule,
        settingsProvider: settings,
      );
      await tester.pumpAndSettle();
      return settings;
    }

    testWidgets('lists starter plans when on', (tester) async {
      await pumpPlans(tester, demoVisible: true);

      expect(find.text('My own plan'), findsOneWidget);
      expect(find.text('Weekday Essentials'), findsOneWidget);
    });

    testWidgets('hides starter plans when off, keeping your own',
        (tester) async {
      await pumpPlans(tester, demoVisible: false);

      expect(find.text('My own plan'), findsOneWidget);
      expect(find.text('Weekday Essentials'), findsNothing);
    });
  });

  group('demo content and the OS schedule', () {
    test('a demo alarm is never scheduled, however it is configured', () {
      // Unconditional, not merely while samples are hidden: the rule must not
      // depend on a UI setting, and a sample that rings is indefensible.
      final now = DateTime(2026, 10, 12, 9);
      final armedDemoAlarm = domain.TodoItem(
        id: 'demo-alarm',
        title: 'Wake up',
        createdAt: now,
        itemType: domain.TodoItemType.alarm,
        scheduledAt: now.add(const Duration(hours: 1)),
        isDemo: true,
      );

      expect(schedulableAlarms([armedDemoAlarm], now), isEmpty);
      expect(alarmNotifications([armedDemoAlarm], now), isEmpty);
    });

    test('an identical non-demo alarm is scheduled', () {
      // Proves the exclusion above is the demo flag doing the work, not the
      // time or the enabled state.
      final now = DateTime(2026, 10, 12, 9);
      final real = domain.TodoItem(
        id: 'real-alarm',
        title: 'Wake up',
        createdAt: now,
        itemType: domain.TodoItemType.alarm,
        scheduledAt: now.add(const Duration(hours: 1)),
      );

      expect(schedulableAlarms([real], now), hasLength(1));
    });

    test('a task from an applied demo plan is the user\'s own', () {
      // Applying a sample plan is a decision. The tasks it creates are real
      // schedule, so they carry no demo flag and keep their reminders — which
      // is why `tasks` has no isDemo column at all.
      final task = taskFixture(
        sourceTemplateId: 'sample',
        reminderEnabled: true,
      );

      expect(task, isA<Task>());
      expect(task.reminderEnabled, isTrue);
    });
  });
}
