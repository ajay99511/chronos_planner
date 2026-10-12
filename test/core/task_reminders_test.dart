import 'package:chronosky/core/services/scheduled_notification.dart';
import 'package:chronosky/core/services/task_reminders.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/domain/reminder_lead.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rule deciding which tasks earn a notification.
///
/// Whether one arrives needs a device (docs/decisions/0010). What is testable
/// here is every exclusion — and each of these is a way the feature could
/// quietly nag someone about the wrong thing, which is how a reminder feature
/// loses trust.
void main() {
  // A Wednesday, mid-morning.
  final now = DateTime(2026, 10, 14, 9, 30);
  final today = DateTime(2026, 10, 14);

  Task task({
    String id = 't1',
    String title = 'Deep work block',
    String startTime = '14:00',
    String endTime = '16:00',
    bool reminderEnabled = true,
    int leadMinutes = 10,
    bool completed = false,
  }) =>
      Task(
        id: id,
        title: title,
        startTime: startTime,
        endTime: endTime,
        type: TaskType.work,
        reminderEnabled: reminderEnabled,
        reminderLeadMinutes: leadMinutes,
        completed: completed,
      );

  DayPlan day(List<Task> tasks, {DateTime? date}) =>
      DayPlan(id: 'd1', date: date ?? today, tasks: tasks);

  group('reminderFireTime', () {
    test('subtracts the lead time from the start', () {
      expect(
        reminderFireTime(task(startTime: '14:00', leadMinutes: 10), today),
        DateTime(2026, 10, 14, 13, 50),
      );
    });

    test('a zero lead fires exactly at the start', () {
      expect(
        reminderFireTime(task(startTime: '14:00', leadMinutes: 0), today),
        DateTime(2026, 10, 14, 14, 0),
      );
    });

    test('a lead crossing midnight lands on the previous day', () {
      // 00:30 minus an hour is 23:30 the day before, not 23:30 the same day.
      expect(
        reminderFireTime(
          task(startTime: '00:30', endTime: '01:30', leadMinutes: 60),
          today,
        ),
        DateTime(2026, 10, 13, 23, 30),
      );
    });

    test('is null when the reminder is off', () {
      expect(reminderFireTime(task(reminderEnabled: false), today), isNull);
    });

    test('a malformed start time cannot even be constructed here', () {
      // reminderFireTime skips an unparseable time rather than defaulting it,
      // because a silent 00:00 turns a corrupt row into a 3 a.m. notification
      // that looks perfectly legitimate. That branch is the release-mode
      // backstop and cannot be reached from a test: the model's assert stops
      // a malformed task being built at all while asserts are enabled. So
      // what is pinned here is the first line of defence.
      expect(
        () => task().copyWith(startTime: '9:00'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('uses the day it is given, not today', () {
      final tomorrow = DateTime(2026, 10, 15);

      expect(
        reminderFireTime(task(startTime: '08:00', leadMinutes: 0), tomorrow),
        DateTime(2026, 10, 15, 8, 0),
      );
    });
  });

  group('reminderNotifications', () {
    test('projects an enabled future task', () {
      final result = reminderNotifications([day([task()])], now);

      expect(result, hasLength(1));
      expect(result.single.kind, ScheduledNotificationKind.reminder);
      expect(result.single.ownerId, 't1');
      expect(result.single.title, 'Deep work block');
      expect(result.single.fireAt, DateTime(2026, 10, 14, 13, 50));
    });

    test('the body says when the task starts, not just that it will', () {
      // The notification arrives minutes early, so "Deep work block" alone
      // does not tell the user whether to move now.
      expect(
        reminderNotifications([day([task()])], now).single.body,
        'Starts in 10 minutes, at 14:00',
      );
    });

    test('skips a task with no reminder', () {
      expect(
        reminderNotifications([day([task(reminderEnabled: false)])], now),
        isEmpty,
      );
    });

    test('skips a completed task', () {
      // Nudging someone about work they already finished is the fastest way
      // to make them turn the feature off.
      expect(
        reminderNotifications([day([task(completed: true)])], now),
        isEmpty,
      );
    });

    test('skips a task whose reminder moment has passed', () {
      // 09:00 start, 10 minutes lead, and it is already 09:30.
      expect(
        reminderNotifications(
          [day([task(startTime: '09:00', endTime: '10:00')])],
          now,
        ),
        isEmpty,
      );
    });

    test('keeps a task later today whose lead has not elapsed', () {
      expect(
        reminderNotifications(
          [day([task(startTime: '09:45', endTime: '10:00', leadMinutes: 10)])],
          now,
        ),
        hasLength(1),
      );
    });

    test('spans every day in the window', () {
      final result = reminderNotifications(
        [
          day([task(id: 'today')]),
          day([task(id: 'tomorrow')], date: DateTime(2026, 10, 15)),
          day([task(id: 'later')], date: DateTime(2026, 10, 18)),
        ],
        now,
      );

      expect(result.map((n) => n.ownerId), ['today', 'tomorrow', 'later']);
    });

    test('returns soonest first across days', () {
      final result = reminderNotifications(
        [
          day([task(id: 'late-today', startTime: '22:00', endTime: '23:00')]),
          day(
            [task(id: 'early-tomorrow', startTime: '06:00', endTime: '07:00')],
            date: DateTime(2026, 10, 15),
          ),
          day([task(id: 'soon', startTime: '10:00', endTime: '11:00')]),
        ],
        now,
      );

      expect(
        result.map((n) => n.ownerId),
        ['soon', 'late-today', 'early-tomorrow'],
      );
    });

    test('caps a full week, keeping the soonest', () {
      // A week of plans with reminders on every block is the realistic worst
      // case, and it can exceed what iOS will hold.
      final days = [
        for (var d = 0; d < 7; d++)
          day(
            [
              for (var h = 10; h < 20; h++)
                task(
                  id: 'd${d}h$h',
                  startTime: '${h.toString().padLeft(2, '0')}:00',
                  endTime: '${(h + 1).toString().padLeft(2, '0')}:00',
                  leadMinutes: 0,
                ),
            ],
            date: today.add(Duration(days: d)),
          ),
      ];

      final result = reminderNotifications(days, now, maxPending: 5);

      expect(result, hasLength(5));
      expect(
        result.map((n) => n.ownerId),
        ['d0h10', 'd0h11', 'd0h12', 'd0h13', 'd0h14'],
      );
    });

    test('an empty window yields nothing', () {
      expect(reminderNotifications(const [], now), isEmpty);
      expect(reminderNotifications([day(const [])], now), isEmpty);
    });
  });

  group('isValidReminderLead', () {
    test('accepts the offered choices', () {
      for (final choice in reminderLeadChoices) {
        expect(isValidReminderLead(choice), isTrue, reason: '$choice');
      }
    });

    test('accepts the boundaries and rejects just outside them', () {
      expect(isValidReminderLead(0), isTrue);
      expect(isValidReminderLead(maxReminderLeadMinutes), isTrue);
      expect(isValidReminderLead(-1), isFalse);
      expect(isValidReminderLead(maxReminderLeadMinutes + 1), isFalse);
    });

    test('the default is one of the offered choices', () {
      // Otherwise the chooser opens on a value it cannot display as selected.
      expect(reminderLeadChoices, contains(defaultReminderLeadMinutes));
    });
  });
}
