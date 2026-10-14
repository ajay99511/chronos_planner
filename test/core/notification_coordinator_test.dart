import 'dart:async';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/core/services/notification_coordinator.dart';
import 'package:chronosky/core/services/scheduled_notification.dart';
import 'package:chronosky/core/services/scheduled_notifier.dart';
import 'package:chronosky/domain/reminder_tone.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/todo_item_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

/// Records what was handed to the OS scheduler.
class _FakeNotifier implements ScheduledNotifier {
  int syncCount = 0;
  int cancelAllCount = 0;
  int requestCount = 0;
  List<ScheduledNotification> lastSynced = const [];
  bool permitted = true;

  /// Whether the simulated user accepts the prompt.
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

  ReminderTone? lastTone;

  @override
  Future<void> sync(
    List<ScheduledNotification> items, {
    ReminderTone reminderTone = ReminderTone.fallback,
  }) async {
    syncCount++;
    lastSynced = items;
    lastTone = reminderTone;
  }

  @override
  Future<void> cancelAll() async => cancelAllCount++;
}

/// An OS scheduler that is unavailable, as on a platform without support.
class _FailingNotifier implements ScheduledNotifier {
  @override
  Future<void> initialise() async => throw Exception('no platform');

  @override
  Future<bool> hasPermission() async => throw Exception('no platform');

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> sync(
    List<ScheduledNotification> items, {
    ReminderTone reminderTone = ReminderTone.fallback,
  }) async =>
      throw Exception('no platform');

  @override
  Future<void> cancelAll() async {}
}

void main() {
  late MockTodoRepository todoRepo;
  late MockScheduleRepository scheduleRepo;
  late StreamController<List<TodoItem>> alarmStream;
  late StreamController<List<DayPlan>> scheduleStream;
  late _FakeNotifier notifier;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    todoRepo = MockTodoRepository();
    scheduleRepo = MockScheduleRepository();
    notifier = _FakeNotifier();
    // Broadcast so a retry can resubscribe, matching drift's watch().
    alarmStream = StreamController<List<TodoItem>>.broadcast();
    scheduleStream = StreamController<List<DayPlan>>.broadcast();
    when(() => todoRepo.watchByType(TodoItemType.alarm))
        .thenAnswer((_) => alarmStream.stream);
    when(() => scheduleRepo.watchUpcomingDays(any()))
        .thenAnswer((_) => scheduleStream.stream);
  });

  tearDown(() {
    alarmStream.close();
    scheduleStream.close();
  });

  NotificationCoordinator coordinator({
    ScheduledNotifier? withNotifier,
    MockPreferenceRepository? withPrefs,
    Duration retryBaseDelay = const Duration(milliseconds: 10),
  }) =>
      NotificationCoordinator(
        todoRepo: todoRepo,
        scheduleRepo: scheduleRepo,
        prefRepo: withPrefs,
        logger: const NoOpLogger(),
        notifier: withNotifier ?? notifier,
        retryBaseDelay: retryBaseDelay,
      );

  /// A preference store that answers with [stored] for the tone key.
  MockPreferenceRepository prefsWithTone(String? stored) {
    final prefs = MockPreferenceRepository();
    when(() => prefs.get(any())).thenAnswer((_) async => Success(stored));
    when(() => prefs.set(any(), any()))
        .thenAnswer((_) async => const Success(null));
    return prefs;
  }

  TodoItem alarm({String id = 'alarm-1', required DateTime at}) => TodoItem(
        id: id,
        title: 'Wake up',
        createdAt: DateTime(2026, 1, 1),
        itemType: TodoItemType.alarm,
        scheduledAt: at,
      );

  /// Tomorrow, so a fixed clock time on it is always still in the future.
  ///
  /// The first version of this helper used `now + 2 hours` and formatted the
  /// result as "HH:mm" on *today's* date. Run after 22:00 that wraps past
  /// midnight and lands in the past, so the reminder was correctly dropped and
  /// the test failed — a flake that only appears late in the evening, which is
  /// the worst kind. Nothing here depends on the wall clock now.
  DateTime tomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  /// A day holding one task with a reminder armed [leadMinutes] ahead.
  DayPlan dayWithReminder({
    String taskId = 'task-1',
    String startTime = '12:00',
    int leadMinutes = 10,
    bool completed = false,
    DateTime? date,
  }) =>
      dayPlanFixture(
        date: date ?? tomorrow(),
        tasks: [
          taskFixture(
            id: taskId,
            startTime: startTime,
            endTime: '23:59',
            completed: completed,
            reminderEnabled: true,
            reminderLeadMinutes: leadMinutes,
          ),
        ],
      );

  group('one owner of the OS schedule', () {
    test('alarms and reminders are synced together, in one list', () async {
      // The regression this class exists to prevent. Two services each
      // replacing the whole schedule with their own slice would alternately
      // erase each other, and the loser would silently stop delivering.
      final subject = coordinator();
      addTearDown(subject.dispose);

      alarmStream
          .add([alarm(at: DateTime.now().add(const Duration(hours: 1)))]);
      await pumpEventQueue();
      scheduleStream.add([dayWithReminder()]);
      await pumpEventQueue();

      expect(
        notifier.lastSynced.map((n) => n.kind),
        containsAll(<ScheduledNotificationKind>[
          ScheduledNotificationKind.alarm,
          ScheduledNotificationKind.reminder,
        ]),
      );
    });

    test('a reminder arriving does not drop the alarms', () async {
      final subject = coordinator();
      addTearDown(subject.dispose);

      alarmStream
          .add([alarm(at: DateTime.now().add(const Duration(hours: 1)))]);
      await pumpEventQueue();
      expect(notifier.lastSynced, hasLength(1));

      scheduleStream.add([dayWithReminder()]);
      await pumpEventQueue();

      expect(notifier.lastSynced, hasLength(2));
      expect(
        notifier.lastSynced.map((n) => n.ownerId),
        containsAll(<String>['alarm-1', 'task-1']),
      );
    });

    test('an alarm arriving does not drop the reminders', () async {
      final subject = coordinator();
      addTearDown(subject.dispose);

      scheduleStream.add([dayWithReminder()]);
      await pumpEventQueue();
      expect(notifier.lastSynced, hasLength(1));

      alarmStream
          .add([alarm(at: DateTime.now().add(const Duration(hours: 1)))]);
      await pumpEventQueue();

      expect(notifier.lastSynced, hasLength(2));
    });

    test('ids do not collide when both kinds share an owner id', () async {
      final subject = coordinator();
      addTearDown(subject.dispose);

      alarmStream
          .add([alarm(id: 'same', at: DateTime.now().add(const Duration(hours: 1)))]);
      await pumpEventQueue();
      scheduleStream.add(
        [dayWithReminder(taskId: 'same')],
      );
      await pumpEventQueue();

      final ids = notifier.lastSynced.map((n) => n.notificationId).toSet();
      expect(notifier.lastSynced, hasLength(2));
      // Two entries, two distinct ids. Hashing the bare id gave one.
      expect(ids, hasLength(2));
    });
  });

  group('syncing', () {
    test('re-syncs on every change, replacing the whole schedule', () async {
      final subject = coordinator();
      addTearDown(subject.dispose);

      scheduleStream.add([dayWithReminder()]);
      await pumpEventQueue();
      scheduleStream.add(const []);
      await pumpEventQueue();

      expect(notifier.syncCount, 2);
      expect(notifier.lastSynced, isEmpty);
    });

    test('a completed task is dropped from the schedule', () async {
      final subject = coordinator();
      addTearDown(subject.dispose);

      scheduleStream
          .add([dayWithReminder(completed: true)]);
      await pumpEventQueue();

      expect(notifier.lastSynced, isEmpty);
    });

    test('refresh re-reads and re-syncs', () async {
      // Called on resume: moments have passed, and the window may still be
      // anchored to yesterday.
      final subject = coordinator();
      addTearDown(subject.dispose);
      scheduleStream.add([dayWithReminder()]);
      await pumpEventQueue();
      final before = notifier.syncCount;

      subject.refresh();
      await pumpEventQueue();

      expect(notifier.syncCount, greaterThan(before));
      // Re-subscribed, which is the only way a drift window moves.
      verify(() => scheduleRepo.watchUpcomingDays(any())).called(2);
    });
  });

  group('permission', () {
    test('reports blocked notifications so the UI can say so', () async {
      notifier.permitted = false;
      final subject = coordinator();
      addTearDown(subject.dispose);

      scheduleStream.add([dayWithReminder()]);
      await pumpEventQueue();

      // Without permission everything scheduled is silently useless, so the
      // user must not be left believing a reminder is set.
      expect(subject.notificationsBlocked, isTrue);
    });

    test('clears the blocked flag once permission is granted', () async {
      notifier.permitted = false;
      final subject = coordinator();
      addTearDown(subject.dispose);
      scheduleStream.add([dayWithReminder()]);
      await pumpEventQueue();
      expect(subject.notificationsBlocked, isTrue);

      await subject.requestNotificationPermission();

      expect(notifier.requestCount, 1);
      expect(subject.notificationsBlocked, isFalse);
    });

    test('reports a declined prompt to the caller that asked', () async {
      notifier.permitted = false;
      notifier.grantOnRequest = false;
      final subject = coordinator();
      addTearDown(subject.dispose);

      // A caller prompting in context has to know, so it can say what the
      // refusal cost rather than implying the reminder is armed.
      expect(await subject.requestNotificationPermission(), isFalse);
      expect(subject.notificationsBlocked, isTrue);
    });

    test('ensure does not prompt a user who has already granted', () async {
      final subject = coordinator();
      addTearDown(subject.dispose);

      expect(await subject.ensureNotificationPermission(), isTrue);
      expect(notifier.requestCount, 0);
    });

    test('ensure prompts when the OS would drop everything', () async {
      notifier.permitted = false;
      final subject = coordinator();
      addTearDown(subject.dispose);

      expect(await subject.ensureNotificationPermission(), isTrue);
      expect(notifier.requestCount, 1);
      expect(subject.notificationsBlocked, isFalse);
    });

    test('ensure re-checks rather than trusting the cached flag', () async {
      // The flag is only as fresh as the last sync. Granting in system
      // settings leaves it stale-true; prompting again on the strength of it
      // would ask for something the user has already given.
      notifier.permitted = false;
      final subject = coordinator();
      addTearDown(subject.dispose);
      scheduleStream.add([dayWithReminder()]);
      await pumpEventQueue();
      expect(subject.notificationsBlocked, isTrue);

      notifier.permitted = true;

      expect(await subject.ensureNotificationPermission(), isTrue);
      expect(notifier.requestCount, 0);
      expect(subject.notificationsBlocked, isFalse);
    });

    test('ensure treats a platform that cannot answer as permitted', () async {
      // Reading the permission throws where there is no such concept. Nagging
      // for a grant the user has no way to give is worse than assuming yes.
      final subject = coordinator(withNotifier: _FailingNotifier());
      addTearDown(subject.dispose);

      expect(await subject.ensureNotificationPermission(), isTrue);
      expect(subject.notificationsBlocked, isFalse);
    });
  });

  group('resilience', () {
    test('an unavailable OS scheduler does not break the app', () async {
      // Losing the OS schedule degrades the feature to in-session only. That
      // is worse than nothing, but not a reason to take the app down.
      final subject = coordinator(withNotifier: _FailingNotifier());
      addTearDown(subject.dispose);

      scheduleStream.add([dayWithReminder()]);

      await expectLater(pumpEventQueue(), completes);
    });

    test('a stream error resubscribes, so scheduling keeps working', () async {
      final subject = coordinator();
      addTearDown(subject.dispose);

      scheduleStream.addError(Exception('db gone'));
      await pumpEventQueue();
      // One subscribe at construction, one on recovery.
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(subject.retryAttempts, greaterThan(0));
      verify(() => scheduleRepo.watchUpcomingDays(any()))
          .called(greaterThan(1));
    });

    test('resubscribe attempts are bounded', () async {
      final subject = coordinator();
      addTearDown(subject.dispose);

      for (var i = 0; i < NotificationCoordinator.maxSubscribeRetries + 2;
          i++) {
        scheduleStream.addError(Exception('still gone'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }

      // A permanently failing source must not retry forever in the
      // background.
      expect(
        subject.retryAttempts,
        NotificationCoordinator.maxSubscribeRetries,
      );
    });

    test('dispose stops listening and syncing', () async {
      final subject = coordinator();

      subject.dispose();
      final before = notifier.syncCount;
      scheduleStream.add([dayWithReminder()]);
      await pumpEventQueue();

      expect(notifier.syncCount, before);
    });
  });

  group('reminder tone', () {
    test('defaults to the fallback tone when nothing is stored', () async {
      final subject = coordinator(withPrefs: prefsWithTone(null));
      addTearDown(subject.dispose);
      await pumpEventQueue();

      expect(subject.reminderTone, ReminderTone.fallback);
      expect(ReminderTone.fallback.ringsForTenSeconds, isTrue);
    });

    test('restores a stored tone on construction', () async {
      final subject =
          coordinator(withPrefs: prefsWithTone(ReminderTone.marimba.name));
      addTearDown(subject.dispose);
      await pumpEventQueue();

      expect(subject.reminderTone, ReminderTone.marimba);
    });

    test('a stored tone this build does not know falls back', () async {
      // A downgrade, or a retired tone. Falling back silently beats a crash
      // or a user whose reminders stop making any sound.
      final subject = coordinator(withPrefs: prefsWithTone('didgeridoo'));
      addTearDown(subject.dispose);
      await pumpEventQueue();

      expect(subject.reminderTone, ReminderTone.fallback);
    });

    test('the chosen tone is handed to every sync', () async {
      final prefs = prefsWithTone(null);
      final subject = coordinator(withPrefs: prefs);
      addTearDown(subject.dispose);

      await subject.setReminderTone(ReminderTone.pulse);
      scheduleStream.add([dayWithReminder()]);
      await pumpEventQueue();

      expect(notifier.lastTone, ReminderTone.pulse);
    });

    test('changing the tone persists it and re-syncs', () async {
      // The re-sync is the point: already-scheduled notifications keep the old
      // channel, and therefore the old sound, until they are replaced.
      final prefs = prefsWithTone(null);
      final subject = coordinator(withPrefs: prefs);
      addTearDown(subject.dispose);
      await pumpEventQueue();
      final before = notifier.syncCount;

      await subject.setReminderTone(ReminderTone.marimba);

      expect(subject.reminderTone, ReminderTone.marimba);
      expect(notifier.syncCount, greaterThan(before));
      verify(() => prefs.set('reminder_tone', 'marimba')).called(1);
    });

    test('re-selecting the current tone does nothing', () async {
      final prefs = prefsWithTone(null);
      final subject = coordinator(withPrefs: prefs);
      addTearDown(subject.dispose);
      await pumpEventQueue();
      final before = notifier.syncCount;

      await subject.setReminderTone(ReminderTone.fallback);

      expect(notifier.syncCount, before);
      verifyNever(() => prefs.set(any(), any()));
    });

    test('a choice made before the stored tone loads is not overwritten',
        () async {
      // The initial read is async and fired from the constructor. Without a
      // guard, a user who opens settings and picks a tone before it lands has
      // their choice silently replaced by the stored value a moment later —
      // and the schedule re-synced with the wrong sound.
      final prefs = MockPreferenceRepository();
      final loadGate = Completer<Result<String?>>();
      when(() => prefs.get(any())).thenAnswer((_) => loadGate.future);
      when(() => prefs.set(any(), any()))
          .thenAnswer((_) async => const Success(null));

      final subject = coordinator(withPrefs: prefs);
      addTearDown(subject.dispose);

      // User picks while the read is still in flight.
      await subject.setReminderTone(ReminderTone.marimba);
      expect(subject.reminderTone, ReminderTone.marimba);

      // The stored value now arrives, and says something else.
      loadGate.complete(Success(ReminderTone.pulse.name));
      await pumpEventQueue();

      expect(subject.reminderTone, ReminderTone.marimba);
      expect(notifier.lastTone, ReminderTone.marimba);
    });

    test('an unreadable preference leaves the fallback in place', () async {
      final prefs = MockPreferenceRepository();
      when(() => prefs.get(any())).thenAnswer(
        (_) async => const Failure(DatabaseFailure('pref read failed')),
      );
      when(() => prefs.set(any(), any()))
          .thenAnswer((_) async => const Success(null));

      final subject = coordinator(withPrefs: prefs);
      addTearDown(subject.dispose);
      await pumpEventQueue();

      expect(subject.reminderTone, ReminderTone.fallback);
    });
  });
}
