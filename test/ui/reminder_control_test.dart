import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/core/services/notification_coordinator.dart';
import 'package:chronosky/core/services/scheduled_notification.dart';
import 'package:chronosky/core/services/scheduled_notifier.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/ui/widgets/reminder_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/mocks.dart';

/// Records whether the control asked the OS for permission.
class _FakeNotifier implements ScheduledNotifier {
  int requestCount = 0;
  bool permitted = true;
  bool grantOnRequest = true;

  @override
  Future<void> initialise() async {}

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<bool> requestPermission() async {
    requestCount++;
    permitted = grantOnRequest;
    return grantOnRequest;
  }

  @override
  Future<void> sync(List<ScheduledNotification> items) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  late MockTodoRepository todoRepo;
  late MockScheduleRepository scheduleRepo;
  late _FakeNotifier notifier;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    todoRepo = MockTodoRepository();
    scheduleRepo = MockScheduleRepository();
    stubTodoRepoEmpty(todoRepo);
    stubScheduleRepoSuccess(scheduleRepo);
    notifier = _FakeNotifier();
  });

  /// A task starting two hours from now, so a reminder is still possible.
  Task futureTask({
    bool reminderEnabled = false,
    int leadMinutes = 10,
    bool completed = false,
  }) {
    final at = DateTime.now().add(const Duration(hours: 2));
    return taskFixture(
      startTime: '${at.hour.toString().padLeft(2, '0')}:'
          '${at.minute.toString().padLeft(2, '0')}',
      endTime: '23:59',
      completed: completed,
      reminderEnabled: reminderEnabled,
      reminderLeadMinutes: leadMinutes,
    );
  }

  Future<List<Task>> pumpControl(
    WidgetTester tester, {
    required Task task,
    DateTime? date,
  }) async {
    final changes = <Task>[];
    final coordinator = NotificationCoordinator(
      todoRepo: todoRepo,
      scheduleRepo: scheduleRepo,
      logger: const NoOpLogger(),
      notifier: notifier,
    );
    addTearDown(coordinator.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationCoordinator>.value(
        value: coordinator,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ReminderControl(
              task: task,
              date: date ?? DateTime.now(),
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return changes;
  }

  group('turning a reminder on', () {
    testWidgets('reports the task with the reminder enabled', (tester) async {
      final changes = await pumpControl(tester, task: futureTask());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(changes, hasLength(1));
      expect(changes.single.reminderEnabled, isTrue);
    });

    testWidgets('asks for delivery permission at that moment', (tester) async {
      notifier.permitted = false;
      await pumpControl(tester, task: futureTask());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Asked here, not at launch: this is the first point the request has a
      // reason the user can see.
      expect(notifier.requestCount, 1);
    });

    testWidgets('a refusal says the reminder will not arrive', (tester) async {
      notifier.permitted = false;
      notifier.grantOnRequest = false;
      await pumpControl(tester, task: futureTask());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // The setting is still saved — the user asked for it — but they are
      // told it cannot be delivered rather than left believing it is armed.
      expect(
        find.textContaining('notifications are off'),
        findsOneWidget,
      );
    });

    testWidgets('does not prompt a user who has already granted',
        (tester) async {
      await pumpControl(tester, task: futureTask());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(notifier.requestCount, 0);
      expect(find.textContaining('notifications are off'), findsNothing);
    });
  });

  group('turning a reminder off', () {
    testWidgets('keeps the chosen lead time', (tester) async {
      // So switching back on restores the user's choice instead of silently
      // resetting to the default.
      final changes = await pumpControl(
        tester,
        task: futureTask(reminderEnabled: true, leadMinutes: 30),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(changes.single.reminderEnabled, isFalse);
      expect(changes.single.reminderLeadMinutes, 30);
    });

    testWidgets('does not ask for permission', (tester) async {
      notifier.permitted = false;
      await pumpControl(
        tester,
        task: futureTask(reminderEnabled: true),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(notifier.requestCount, 0);
    });
  });

  group('lead time', () {
    testWidgets('choices only appear once the reminder is on', (tester) async {
      await pumpControl(tester, task: futureTask());

      expect(find.text('At start'), findsNothing);

      await pumpControl(tester, task: futureTask(reminderEnabled: true));

      expect(find.text('At start'), findsOneWidget);
    });

    testWidgets('picking one reports it', (tester) async {
      final changes = await pumpControl(
        tester,
        task: futureTask(reminderEnabled: true),
      );

      await tester.tap(find.text('30 minutes before'));
      await tester.pumpAndSettle();

      expect(changes.single.reminderLeadMinutes, 30);
      expect(changes.single.reminderEnabled, isTrue);
    });
  });

  group('a task that cannot be reminded about', () {
    testWidgets('a past task disables the switch and says why',
        (tester) async {
      await pumpControl(
        tester,
        task: taskFixture(startTime: '00:01', endTime: '23:59'),
        date: DateTime.now().subtract(const Duration(days: 1)),
      );

      final toggle = tester.widget<Switch>(find.byType(Switch));
      expect(toggle.onChanged, isNull);
      expect(find.textContaining('already started'), findsOneWidget);
    });

    testWidgets('a completed task says there is nothing to remind of',
        (tester) async {
      await pumpControl(
        tester,
        task: taskFixture(
          startTime: '00:01',
          endTime: '23:59',
          completed: true,
        ),
        date: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(find.textContaining('nothing to remind you of'), findsOneWidget);
    });

    testWidgets('an armed-but-past reminder does not render as on',
        (tester) async {
      // The honest-state rule: a switch showing "on" for something that can
      // never fire is worse than no switch.
      await pumpControl(
        tester,
        task: taskFixture(
          startTime: '00:01',
          endTime: '23:59',
          reminderEnabled: true,
        ),
        date: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });
  });
}
