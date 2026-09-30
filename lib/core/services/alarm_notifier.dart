import 'package:chronosky/data/models/todo_item_model.dart';

/// Registers alarms with the operating system so they fire when the app is not
/// running.
///
/// The in-process timer in `AlarmSchedulerService` only works while the app is
/// alive; Android routinely kills backgrounded processes and Doze suspends
/// timers even when the process survives. See docs/decisions/0010.
///
/// A seam, so the scheduling decisions — which alarms are due, what identity
/// they get, what happens without permission — are testable without a device.
abstract class AlarmNotifier {
  /// Prepares the platform. Safe to call more than once.
  Future<void> initialise();

  /// Whether the OS will actually deliver alarms.
  ///
  /// False when the user has declined notification permission, in which case
  /// scheduling silently achieves nothing — so callers surface it rather than
  /// assuming delivery.
  Future<bool> hasPermission();

  /// Asks for the permissions delivery needs, returning the resulting state.
  Future<bool> requestPermission();

  /// Replaces the entire OS-level schedule with [alarms].
  ///
  /// Wholesale replacement rather than incremental add/remove: the repository
  /// hands over its full list on every change, so recomputing cannot drift out
  /// of step with what the user sees. Past and disabled alarms are skipped.
  Future<void> sync(List<TodoItem> alarms);

  /// Removes every scheduled alarm.
  Future<void> cancelAll();
}

/// Stable 31-bit identity for an alarm's UUID.
///
/// Notification ids are integers while alarm ids are UUIDs, and the mapping has
/// to survive a restart or a scheduled alarm can never be cancelled. FNV-1a
/// rather than [String.hashCode], which Dart does not guarantee to be stable
/// across versions.
int notificationIdFor(String alarmId) {
  var hash = 0x811c9dc5;
  for (final unit in alarmId.codeUnits) {
    hash ^= unit;
    // 16777619, applied with 32-bit wraparound.
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  // Masked to 31 bits: Android notification ids are signed 32-bit ints.
  return hash & 0x7fffffff;
}

/// The alarms that should hold an OS-level schedule, given the clock.
///
/// Pure, so the rule is testable without a platform: enabled, has a time, and
/// that time is still in the future. Scheduling a past alarm either fires
/// immediately or is dropped, depending on the platform — neither is wanted.
List<TodoItem> schedulableAlarms(List<TodoItem> alarms, DateTime now) => [
      for (final alarm in alarms)
        if (alarm.enabled &&
            alarm.scheduledAt != null &&
            alarm.scheduledAt!.isAfter(now))
          alarm,
    ];

/// An [AlarmNotifier] that does nothing.
///
/// Used in tests and on platforms where OS scheduling is unavailable, so the
/// rest of the app does not need to know the difference.
class NoOpAlarmNotifier implements AlarmNotifier {
  const NoOpAlarmNotifier();

  @override
  Future<void> initialise() async {}

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> sync(List<TodoItem> alarms) async {}

  @override
  Future<void> cancelAll() async {}
}
