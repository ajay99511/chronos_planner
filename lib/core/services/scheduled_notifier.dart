import 'package:chronosky/core/services/scheduled_notification.dart';
import 'package:chronosky/domain/reminder_tone.dart';

/// Registers notifications with the operating system so they fire when the app
/// is not running.
///
/// The in-process timer in `AlarmSchedulerService` only works while the app is
/// alive; Android routinely kills backgrounded processes and Doze suspends
/// timers even when the process survives. See docs/decisions/0010.
///
/// A seam, so the scheduling decisions — which notifications are due, what
/// identity they get, what happens without permission — are testable without a
/// device.
abstract class ScheduledNotifier {
  /// Prepares the platform. Safe to call more than once.
  Future<void> initialise();

  /// Whether the OS will actually deliver notifications.
  ///
  /// False when the user has declined notification permission, in which case
  /// scheduling silently achieves nothing — so callers surface it rather than
  /// assuming delivery.
  Future<bool> hasPermission();

  /// Asks for the permissions delivery needs, returning the resulting state.
  Future<bool> requestPermission();

  /// Replaces the entire OS-level schedule with [items].
  ///
  /// Wholesale replacement rather than incremental add/remove: the caller
  /// hands over its full list on every change, so recomputing cannot drift out
  /// of step with what the user sees.
  ///
  /// **Exactly one object may call this.** Replacement is implemented by
  /// cancelling everything first, so two callers syncing their own slice would
  /// alternately erase each other and whichever synced last would win. That is
  /// why both alarms and reminders converge on [ScheduledNotification] and are
  /// handed over together by `NotificationCoordinator`.
  ///
  /// [reminderTone] is the sound reminders should make. It is a parameter
  /// rather than state because the tone decides which Android channel the
  /// reminders go out on, and that channel has to exist before the first
  /// notification is scheduled against it. Alarms ignore it — their sound is
  /// their own, and nothing here changes alarm behaviour.
  Future<void> sync(
    List<ScheduledNotification> items, {
    ReminderTone reminderTone,
  });

  /// Removes every scheduled notification.
  Future<void> cancelAll();
}

/// A [ScheduledNotifier] that does nothing.
///
/// Used in tests and on platforms where OS scheduling is unavailable, so the
/// rest of the app does not need to know the difference.
class NoOpScheduledNotifier implements ScheduledNotifier {
  const NoOpScheduledNotifier();

  @override
  Future<void> initialise() async {}

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> sync(
    List<ScheduledNotification> items, {
    ReminderTone reminderTone = ReminderTone.fallback,
  }) async {}

  @override
  Future<void> cancelAll() async {}
}
