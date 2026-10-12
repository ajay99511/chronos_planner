import 'package:chronosky/core/services/scheduled_notification.dart';
import 'package:chronosky/core/services/scheduled_notifier.dart';
import 'package:chronosky/data/models/todo_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The decisions behind the OS-scheduling seam.
///
/// Whether a notification actually arrives needs a device (see
/// docs/decisions/0010). What is testable here is everything that decides
/// *what* gets scheduled and under what identity — which is where a bug would
/// silently cost someone their alarm.
void main() {
  final now = DateTime(2026, 9, 29, 8, 0);

  TodoItem alarm({
    String id = 'alarm-1',
    DateTime? at,
    bool enabled = true,
  }) =>
      TodoItem(
        id: id,
        title: 'Wake up',
        createdAt: DateTime(2026, 1, 1),
        itemType: TodoItemType.alarm,
        scheduledAt: at,
        enabled: enabled,
      );

  group('notificationIdFor', () {
    test('is stable for the same id', () {
      expect(
        notificationIdFor('a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
        notificationIdFor('a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
      );
    });

    test('matches FNV-1a computed independently', () {
      // Pinned deliberately, and cross-checked against a separate FNV-1a
      // implementation rather than against whatever this code happens to
      // emit. String.hashCode is not guaranteed stable across Dart versions,
      // and an id that shifts leaves an alarm scheduled in the OS that nothing
      // can cancel.
      expect(notificationIdFor('alarm-1'), 597688044);
      expect(notificationIdFor(''), 18652613);
      expect(
        notificationIdFor('a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
        1186161055,
      );
    });

    test('fits in a signed 32-bit int, as Android requires', () {
      for (final id in [
        'alarm-1',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'z' * 200,
        '',
      ]) {
        final value = notificationIdFor(id);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThanOrEqualTo(0x7fffffff));
      }
    });

    test('separates ids that differ only slightly', () {
      // UUIDs share long prefixes; a weak hash would collide across a user's
      // alarms and cancel the wrong one.
      final ids = [
        for (var i = 0; i < 500; i++)
          'a1b2c3d4-e5f6-7890-abcd-ef12345678${i.toString().padLeft(2, '0')}',
      ];
      final hashes = ids.map(notificationIdFor).toSet();
      expect(hashes, hasLength(ids.length));
    });
  });

  group('schedulableAlarms', () {
    test('keeps an enabled future alarm', () {
      final future = alarm(at: now.add(const Duration(hours: 1)));

      expect(schedulableAlarms([future], now), [future]);
    });

    test('drops a disabled alarm', () {
      expect(
        schedulableAlarms(
          [alarm(at: now.add(const Duration(hours: 1)), enabled: false)],
          now,
        ),
        isEmpty,
      );
    });

    test('drops an alarm with no time', () {
      expect(schedulableAlarms([alarm()], now), isEmpty);
    });

    test('drops an alarm already in the past', () {
      // Scheduling a past time either fires at once or is discarded depending
      // on the platform; neither is what the user asked for.
      expect(
        schedulableAlarms(
          [alarm(at: now.subtract(const Duration(minutes: 1)))],
          now,
        ),
        isEmpty,
      );
    });

    test('drops an alarm for exactly now', () {
      expect(schedulableAlarms([alarm(at: now)], now), isEmpty);
    });

    test('keeps only the schedulable ones from a mixed list', () {
      final keep = alarm(id: 'keep', at: now.add(const Duration(hours: 2)));
      final past = alarm(id: 'past', at: now.subtract(const Duration(days: 1)));
      final off = alarm(
        id: 'off',
        at: now.add(const Duration(hours: 3)),
        enabled: false,
      );
      final noTime = alarm(id: 'no-time');

      expect(
        schedulableAlarms([past, keep, off, noTime], now).map((a) => a.id),
        ['keep'],
      );
    });

    test('handles an empty list', () {
      expect(schedulableAlarms(const [], now), isEmpty);
    });
  });

  group('NoOpScheduledNotifier', () {
    test('reports no permission, so callers surface the gap', () async {
      // Used on platforms without OS scheduling. Reporting "no permission"
      // rather than "granted" keeps the UI honest about delivery.
      const notifier = NoOpScheduledNotifier();

      expect(await notifier.hasPermission(), isFalse);
      expect(await notifier.requestPermission(), isFalse);
    });

    test('accepts every call without throwing', () async {
      const notifier = NoOpScheduledNotifier();

      await notifier.initialise();
      await notifier.sync(
        alarmNotifications(
          [alarm(at: now.add(const Duration(hours: 1)))],
          now,
        ),
      );
      await notifier.cancelAll();
    });
  });

  group('ScheduledNotification.notificationId', () {
    ScheduledNotification item(
      ScheduledNotificationKind kind,
      String ownerId,
    ) =>
        ScheduledNotification(
          kind: kind,
          ownerId: ownerId,
          title: 'T',
          body: 'B',
          fireAt: now,
        );

    test('an alarm and a reminder on the same entity do not collide', () {
      // The defect this namespace exists to prevent. Hashing the bare id gave
      // both the same notification id, so scheduling one cancelled the other
      // -- by construction, every time, not as an unlucky collision.
      expect(
        item(ScheduledNotificationKind.alarm, 'same-id').notificationId,
        isNot(
          item(ScheduledNotificationKind.reminder, 'same-id').notificationId,
        ),
      );
    });

    test('is stable across instances with the same kind and owner', () {
      // Must survive a restart or the OS holds a notification nothing can
      // cancel.
      expect(
        item(ScheduledNotificationKind.reminder, 'task-1').notificationId,
        item(ScheduledNotificationKind.reminder, 'task-1').notificationId,
      );
    });

    test('is the namespaced hash, not the bare one', () {
      expect(
        item(ScheduledNotificationKind.alarm, 'alarm-1').notificationId,
        notificationIdFor('alarm:alarm-1'),
      );
      expect(
        item(ScheduledNotificationKind.alarm, 'alarm-1').notificationId,
        isNot(notificationIdFor('alarm-1')),
      );
    });

    test('fits in a signed 32-bit int across both kinds', () {
      for (final kind in ScheduledNotificationKind.values) {
        final value = item(kind, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890')
            .notificationId;
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThanOrEqualTo(0x7fffffff));
      }
    });
  });

  group('schedulableNotifications', () {
    ScheduledNotification at(String id, Duration offset) =>
        ScheduledNotification(
          kind: ScheduledNotificationKind.reminder,
          ownerId: id,
          title: id,
          body: '',
          fireAt: now.add(offset),
        );

    test('drops anything already past, and anything at exactly now', () {
      expect(
        schedulableNotifications(
          [
            at('past', const Duration(minutes: -1)),
            at('now', Duration.zero),
            at('future', const Duration(minutes: 1)),
          ],
          now,
        ).map((n) => n.ownerId),
        ['future'],
      );
    });

    test('returns soonest first', () {
      expect(
        schedulableNotifications(
          [
            at('late', const Duration(hours: 5)),
            at('soon', const Duration(minutes: 5)),
            at('mid', const Duration(hours: 1)),
          ],
          now,
        ).map((n) => n.ownerId),
        ['soon', 'mid', 'late'],
      );
    });

    test('caps the list, keeping the soonest', () {
      // iOS silently discards past 64 pending local notifications, so the cut
      // has to be made here and has to keep the ones about to happen.
      final many = [
        for (var i = 20; i >= 1; i--) at('t$i', Duration(minutes: i)),
      ];

      final kept = schedulableNotifications(many, now, maxPending: 3);

      expect(kept.map((n) => n.ownerId), ['t1', 't2', 't3']);
    });

    test('an under-cap list is returned whole', () {
      expect(
        schedulableNotifications(
          [at('a', const Duration(minutes: 1))],
          now,
          maxPending: 10,
        ),
        hasLength(1),
      );
    });

    test('handles an empty list', () {
      expect(schedulableNotifications(const [], now), isEmpty);
    });
  });

  group('alarmNotifications', () {
    test('projects an alarm, carrying its sound and description', () {
      final item = TodoItem(
        id: 'a1',
        title: 'Wake up',
        description: 'Gently',
        createdAt: DateTime(2026, 1, 1),
        itemType: TodoItemType.alarm,
        scheduledAt: now.add(const Duration(hours: 1)),
        audioFilePath: 'C:/sounds/birds.mp3',
      );

      final projected = alarmNotifications([item], now);

      expect(projected, hasLength(1));
      expect(projected.single.kind, ScheduledNotificationKind.alarm);
      expect(projected.single.ownerId, 'a1');
      expect(projected.single.title, 'Wake up');
      expect(projected.single.body, 'Gently');
      expect(projected.single.soundPath, 'C:/sounds/birds.mp3');
      expect(projected.single.fireAt, item.scheduledAt);
    });

    test('a description-less alarm still has a body', () {
      // An empty body renders as a notification with a title and blank space.
      expect(
        alarmNotifications(
          [alarm(at: now.add(const Duration(hours: 1)))],
          now,
        ).single.body,
        'Alarm',
      );
    });

    test('applies the same exclusions as schedulableAlarms', () {
      expect(
        alarmNotifications(
          [
            alarm(id: 'off', at: now.add(const Duration(hours: 1)),
                enabled: false,),
            alarm(id: 'past', at: now.subtract(const Duration(hours: 1))),
            alarm(id: 'no-time'),
          ],
          now,
        ),
        isEmpty,
      );
    });
  });
}
