import 'package:flutter/foundation.dart';

import 'package:chronosky/data/models/todo_item_model.dart';

/// What a scheduled notification is *for*, which decides how it presents.
///
/// An alarm and a reminder are different products and must not be collapsed
/// into one: an alarm wakes you and rings until dismissed, a reminder nudges
/// you and is swiped away. They get separate channels so the user can silence
/// one without silencing the other — see docs/TASK_REMINDERS_DESIGN.md §3.
enum ScheduledNotificationKind {
  /// A todo alarm. Rings, undismissable by a swipe, alarm category.
  alarm,

  /// A lead-time nudge before a scheduled task starts.
  reminder,
}

/// One thing the operating system should show at one moment.
///
/// The platform layer takes a list of these and nothing else, so every source
/// of notifications — todo alarms, task reminders, whatever comes next —
/// converges on one type before it reaches a platform call. That is what makes
/// a single owner of the OS schedule possible, which [ScheduledNotifier.sync]
/// requires to be correct.
@immutable
class ScheduledNotification {
  const ScheduledNotification({
    required this.kind,
    required this.ownerId,
    required this.title,
    required this.body,
    required this.fireAt,
    this.soundPath = '',
  });

  final ScheduledNotificationKind kind;

  /// Id of the task or todo item this belongs to.
  ///
  /// Carried so a notification can be traced back to what created it, and so
  /// the payload can route a tap.
  final String ownerId;

  final String title;
  final String body;

  /// Local wall-clock moment to fire.
  ///
  /// Resolved against the device's IANA zone at schedule time, never stored as
  /// an offset: an offset is wrong twice a year, and wrong in a way that looks
  /// correct.
  final DateTime fireAt;

  /// Custom sound to loop. Alarms only; empty means the channel default.
  final String soundPath;

  /// Stable 31-bit identity, namespaced by [kind].
  ///
  /// The namespace is the point. Hashing a bare entity id means a task's alarm
  /// and that same task's reminder produce the *same* notification id by
  /// construction, so scheduling one cancels the other — and two different
  /// entity types that happen to share an id collide too. Including the kind
  /// makes the collision impossible rather than unlikely.
  int get notificationId => notificationIdFor('${kind.name}:$ownerId');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledNotification &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          ownerId == other.ownerId &&
          title == other.title &&
          body == other.body &&
          fireAt == other.fireAt &&
          soundPath == other.soundPath;

  @override
  int get hashCode =>
      Object.hash(kind, ownerId, title, body, fireAt, soundPath);

  @override
  String toString() =>
      'ScheduledNotification(${kind.name}:$ownerId at $fireAt)';
}

/// Stable 31-bit identity for a notification key.
///
/// Notification ids are integers while the app's ids are UUIDs, and the
/// mapping has to survive a restart or a scheduled notification can never be
/// cancelled. FNV-1a rather than [String.hashCode], which Dart does not
/// guarantee to be stable across versions.
///
/// Prefer [ScheduledNotification.notificationId] over calling this directly:
/// it applies the kind namespace that keeps the two features from colliding.
int notificationIdFor(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    // 16777619, applied with 32-bit wraparound.
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  // Masked to 31 bits: Android notification ids are signed 32-bit ints.
  return hash & 0x7fffffff;
}

/// The default ceiling on pending notifications held with the OS.
///
/// iOS keeps at most **64** pending local notifications and silently discards
/// the rest; recent Android versions cap an app's alarms in the hundreds. A
/// full week of plans with reminders on every block can reach either, so the
/// schedule is capped here rather than discovered to be truncated on a device.
/// Below iOS's limit deliberately, leaving room for alarms alongside.
const int maxPendingNotifications = 48;

/// The notifications the OS should hold, given the clock.
///
/// Pure, so the rule is testable without a platform: still in the future, and
/// soonest first up to [maxPending]. Scheduling a past moment either fires
/// immediately or is dropped depending on the platform — neither is wanted.
///
/// Sorting before truncating matters: if the list has to be cut, the ones kept
/// must be the ones about to happen.
List<ScheduledNotification> schedulableNotifications(
  List<ScheduledNotification> items,
  DateTime now, {
  int maxPending = maxPendingNotifications,
}) {
  final future = [
    for (final item in items)
      if (item.fireAt.isAfter(now)) item,
  ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));

  if (future.length <= maxPending) return future;
  return future.sublist(0, maxPending);
}

/// The alarms that should hold an OS-level schedule, given the clock.
///
/// Pure, so the rule is testable without a platform: enabled, has a time, and
/// that time is still in the future.
List<TodoItem> schedulableAlarms(List<TodoItem> alarms, DateTime now) => [
      for (final alarm in alarms)
        if (alarm.enabled &&
            alarm.scheduledAt != null &&
            alarm.scheduledAt!.isAfter(now))
          alarm,
    ];

/// Projects todo alarms onto the common notification type.
List<ScheduledNotification> alarmNotifications(
  List<TodoItem> alarms,
  DateTime now,
) =>
    [
      for (final alarm in schedulableAlarms(alarms, now))
        ScheduledNotification(
          kind: ScheduledNotificationKind.alarm,
          ownerId: alarm.id,
          title: alarm.title,
          body: alarm.description.isEmpty ? 'Alarm' : alarm.description,
          fireAt: alarm.scheduledAt!,
          soundPath: alarm.audioFilePath,
        ),
    ];
