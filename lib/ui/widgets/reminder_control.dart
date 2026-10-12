import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chronosky/core/services/notification_coordinator.dart';
import 'package:chronosky/core/services/task_reminders.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/domain/reminder_lead.dart';
import 'package:chronosky/ui/strings.dart';

/// Switch and lead-time chooser for one task's reminder.
///
/// ## Honest state
/// A switch that renders as "on" while the OS has no permission to deliver is
/// worse than no switch at all: the user walks away believing they will be
/// told, and the first they learn otherwise is the meeting they missed. So
/// enabling a reminder goes through
/// [NotificationCoordinator.ensureNotificationPermission] first, and a refusal
/// is reported rather than swallowed.
///
/// A task whose start has already passed cannot be reminded about, so the
/// control is disabled and says why instead of accepting a setting that will
/// never fire.
class ReminderControl extends StatelessWidget {
  const ReminderControl({
    super.key,
    required this.task,
    required this.date,
    required this.onChanged,
  });

  final Task task;

  /// The day [task] is scheduled on, needed to tell past from future.
  final DateTime date;

  /// Called with the task as it should now be. The caller persists it.
  final ValueChanged<Task> onChanged;

  /// Whether a reminder for this task could still fire.
  ///
  /// Uses the same arithmetic as the scheduler, so what the UI offers and what
  /// the OS would accept cannot disagree.
  bool get _inFuture {
    final at = reminderFireTime(
      task.copyWith(reminderEnabled: true),
      date,
    );
    return at != null && at.isAfter(DateTime.now());
  }

  Future<void> _toggle(BuildContext context, bool wanted) async {
    if (!wanted) {
      // Turning it off keeps the chosen lead time, so switching back on
      // restores the user's choice rather than resetting to the default.
      onChanged(task.copyWith(reminderEnabled: false));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final coordinator = context.read<NotificationCoordinator>();
    // Asked at the first reminder, not at launch: this is the first moment
    // the request has a reason the user can see.
    final granted = await coordinator.ensureNotificationPermission();

    onChanged(task.copyWith(reminderEnabled: true));
    if (granted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Reminder saved, but notifications are off so it will not arrive. '
          'Enable them in system settings.',
        ),
        duration: Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = task.reminderEnabled;
    final canRemind = _inFuture;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                enabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                size: 18,
                color: AppColors.neonBlue,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Reminder',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.neonBlue,
                  ),
                ),
              ),
              Semantics(
                label: AppStrings.reminderToggleLabel(
                  taskTitle: task.title,
                  enabled: enabled,
                  leadMinutes: task.reminderLeadMinutes,
                ),
                child: Switch(
                  value: enabled && canRemind,
                  onChanged:
                      canRemind ? (v) => _toggle(context, v) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!canRemind)
            Text(
              task.completed
                  ? 'This task is done, so there is nothing to remind you of.'
                  : 'This task has already started, so a reminder cannot '
                      'reach you in time.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            )
          else if (!enabled)
            Text(
              'Off. Turn it on to be notified before this task starts, even '
              'with the app closed.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final minutes in reminderLeadChoices)
                  ChoiceChip(
                    label: Text(
                      AppStrings.reminderLeadLabel(minutes),
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: task.reminderLeadMinutes == minutes,
                    onSelected: (selected) {
                      if (!selected) return;
                      onChanged(
                        task.copyWith(reminderLeadMinutes: minutes),
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
