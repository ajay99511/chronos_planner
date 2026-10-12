import 'package:chronosky/core/services/scheduled_notification.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/domain/clock_time.dart';
import 'package:chronosky/ui/strings.dart';

/// The wall-clock moment a reminder for [task] on [date] should fire, or null
/// if the task has no reminder or its stored time cannot be parsed.
///
/// An unparseable time is skipped, never defaulted. The three call sites
/// `ClockTime` replaced each invented a different fallback, and a silent 00:00
/// turns a corrupt row into a 3 a.m. notification that looks legitimate.
DateTime? reminderFireTime(Task task, DateTime date) {
  if (!task.reminderEnabled) return null;
  final start = ClockTime.tryParse(task.startTime);
  if (start == null) return null;
  return DateTime(
    date.year,
    date.month,
    date.day,
    start.hour,
    start.minutesSinceMidnight % 60,
  ).subtract(Duration(minutes: task.reminderLeadMinutes));
}

/// Reminders the OS should hold for the loaded schedule window.
///
/// Pure, so every exclusion below is testable without a device:
/// - reminder not switched on → nothing,
/// - task already completed → nothing, because nudging someone about finished
///   work is the fastest way to lose their trust in the feature,
/// - unparseable clock time → skipped rather than defaulted,
/// - fire time already past → dropped by [schedulableNotifications], since a
///   past schedule either fires at once or is discarded by the platform.
///
/// The window itself is the horizon: [days] is the rolling week the schedule
/// already loads, so nothing beyond it can be reminded about and nothing
/// needs a separate cap on how far ahead to look. The count is still capped —
/// see [maxPendingNotifications].
List<ScheduledNotification> reminderNotifications(
  List<DayPlan> days,
  DateTime now, {
  int maxPending = maxPendingNotifications,
}) {
  final candidates = <ScheduledNotification>[];
  for (final day in days) {
    for (final task in day.tasks) {
      if (task.completed) continue;
      final fireAt = reminderFireTime(task, day.date);
      if (fireAt == null) continue;
      candidates.add(
        ScheduledNotification(
          kind: ScheduledNotificationKind.reminder,
          ownerId: task.id,
          title: task.title,
          body: AppStrings.reminderBody(
            start: task.startTime,
            leadMinutes: task.reminderLeadMinutes,
          ),
          fireAt: fireAt,
        ),
      );
    }
  }
  return schedulableNotifications(candidates, now, maxPending: maxPending);
}
