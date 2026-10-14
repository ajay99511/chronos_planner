import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chronosky/core/services/notification_coordinator.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/domain/reminder_lead.dart';
import 'package:chronosky/domain/reminder_tone.dart';
import 'package:chronosky/providers/settings_provider.dart';
import 'package:chronosky/ui/strings.dart';
import 'package:chronosky/ui/widgets/notification_permission_banner.dart';

/// App settings: reminder sound, reminder default, and sample content.
///
/// Deliberately small. Each row here exists because the setting cannot
/// sensibly live anywhere else — a reminder tone is global by nature, the
/// default lead time is the starting point for every new reminder, and the
/// demo switch governs content across two tabs at once. Anything that belongs
/// on the thing it affects stays on the thing it affects: a task's own
/// reminder is set on the task.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = AppResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        // A ListView, not a Column: at 320px with a large text scale the rows
        // exceed the viewport, and settings is exactly the screen where the
        // text scale is likely to be large.
        padding: EdgeInsets.fromLTRB(padding, padding, padding, AppSpacing.xl),
        children: [
          Text(
            'Settings',
            style: AppTextStyles.heading1.copyWith(
              fontSize: AppResponsive.heading1Size(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reminders and sample content.',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          const NotificationPermissionBanner(
            message: 'Notifications are off — reminders will not arrive.',
          ),
          const _ReminderToneSection(),
          const SizedBox(height: AppSpacing.lg),
          const _DefaultLeadSection(),
          const SizedBox(height: AppSpacing.lg),
          const _DemoDataSection(),
        ],
      ),
    );
  }
}

/// A titled card, so every section reads the same way.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        AppResponsive.isTiny(context) ? AppSpacing.md : AppSpacing.lg,
      ),
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
              Icon(icon, size: 18, color: AppColors.neonBlue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.neonBlue,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ReminderToneSection extends StatelessWidget {
  const _ReminderToneSection();

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<NotificationCoordinator>();
    final selected = coordinator.reminderTone;

    return _Section(
      icon: Icons.music_note_rounded,
      title: 'Reminder sound',
      subtitle: 'The bundled tones ring for ten seconds and stop. Alarms are '
          'unaffected — they keep their own sound.',
      // RadioGroup rather than per-tile onChanged, which is deprecated: the
      // group owns the selection and the tiles only declare their value.
      child: RadioGroup<ReminderTone>(
        groupValue: selected,
        onChanged: (chosen) {
          if (chosen != null) coordinator.setReminderTone(chosen);
        },
        // Transparent Material around the tiles. A ListTile paints its ripple
        // on the nearest Material ancestor, and the section card is a
        // DecoratedBox with a background — so without this the tap feedback
        // would be painted underneath the card and never seen. Flutter
        // asserts on exactly this, which the responsive gate surfaced.
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
            for (final tone in ReminderTone.values)
              RadioListTile<ReminderTone>(
                value: tone,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.neonBlue,
                title: Text(
                  tone.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                ),
                subtitle: Text(
                  tone.description,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultLeadSection extends StatelessWidget {
  const _DefaultLeadSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return _Section(
      icon: Icons.timer_outlined,
      title: 'Default reminder time',
      subtitle: 'Where a newly switched-on reminder starts. Changing it does '
          'not alter reminders you have already set.',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final minutes in reminderLeadChoices)
            ChoiceChip(
              label: Text(
                AppStrings.reminderLeadLabel(minutes),
                style: const TextStyle(fontSize: 12),
              ),
              selected: settings.defaultLeadMinutes == minutes,
              onSelected: (chosen) {
                if (chosen) settings.setDefaultLeadMinutes(minutes);
              },
            ),
        ],
      ),
    );
  }
}

class _DemoDataSection extends StatelessWidget {
  const _DemoDataSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return _Section(
      icon: Icons.science_outlined,
      title: 'Sample content',
      subtitle: 'Shows the starter plans and the sample notes, timers, alarms '
          'and checklists. Switching this off hides them — nothing is '
          'deleted, and your own items are never affected.',
      trailing: Semantics(
        label: settings.demoVisible
            ? 'Sample content shown'
            : 'Sample content hidden',
        child: Switch(
          value: settings.demoVisible,
          onChanged: settings.loaded ? settings.setDemoVisible : null,
        ),
      ),
      child: Row(
        children: [
          Icon(
            settings.demoVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              settings.demoVisible
                  ? 'Samples are listed alongside your own items.'
                  : 'Only your own items are listed.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
