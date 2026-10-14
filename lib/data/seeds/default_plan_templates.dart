import 'package:uuid/uuid.dart';

import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/data/models/task_model.dart';

/// The starter WorkPlans a brand-new install is seeded with.
///
/// ## Why these exist
/// An empty WorkPlans tab teaches nothing: the feature's value is that a day
/// can be laid out once and re-applied, and that is hard to infer from a
/// "Create New Plan" card alone. Three plans is enough to show the shape of
/// one — a working day, a non-working day, and a single-purpose day — without
/// implying the user is supposed to keep them.
///
/// ## Why they are not recurring
/// [PlanTemplate.activeDays] is left empty on purpose. A recurring template is
/// auto-applied to every matching day on load (see
/// `ScheduleStateProvider._applyRecurringTemplates`), so seeding one would
/// write tasks into the user's week on first launch without being asked. These
/// are offered, not imposed: the user applies one with APPLY, or makes it
/// recurring from the plan dialog.
///
/// ## Why they are flagged as demo
/// Every one carries `isDemo: true`, so the single demo-data switch in
/// Settings governs these and the Workspace samples together. Hiding them
/// filters rather than deletes, so an edited sample is still there when the
/// switch goes back on.
///
/// ## Why the times are plain
/// Treat the contents as sample data, not as advice. They are ordinary
/// round-numbered blocks that read as something to edit, which is what a first
/// encounter with a template should invite.
///
/// Returns fresh instances with fresh ids on every call, because each is
/// persisted under its own primary key.
List<PlanTemplate> defaultPlanTemplates() => [
      _weekdayEssentials(),
      _weekendReset(),
      _deepWorkDay(),
    ];

const Uuid _uuid = Uuid();

/// Builds a template and stamps its own id onto every task.
///
/// [TemplateTask.templateId] is denormalised onto each task, so it can only be
/// filled in once the template's id exists. Doing it here keeps the in-memory
/// template equal to what the repository writes; the previous seed left the
/// field empty and relied on the repository overwriting it on insert, which
/// left the optimistic copy the UI shows until the next reload subtly wrong.
PlanTemplate _template({
  required String name,
  required String description,
  required List<TemplateTask> Function(String templateId) tasks,
}) {
  final id = _uuid.v4();
  return PlanTemplate(
    id: id,
    name: name,
    description: description,
    tasks: tasks(id),
    // Sample content, so the demo-data switch governs these too. Flagged
    // rather than deleted when hidden, so a plan the user has edited survives
    // a round trip through the switch.
    isDemo: true,
  );
}

TemplateTask _task(
  String templateId, {
  required String title,
  required String startTime,
  required String endTime,
  required TaskType type,
  TaskPriority priority = TaskPriority.medium,
  TaskEnergyLevel energyLevel = TaskEnergyLevel.medium,
  String description = '',
}) =>
    TemplateTask(
      id: _uuid.v4(),
      templateId: templateId,
      title: title,
      startTime: startTime,
      endTime: endTime,
      type: type,
      priority: priority,
      energyLevel: energyLevel,
      description: description,
    );

PlanTemplate _weekdayEssentials() => _template(
      name: 'Weekday Essentials',
      description: 'Wake, focus, move, wind down. A balanced working day.',
      tasks: (id) => [
        _task(
          id,
          title: 'Morning routine',
          startTime: '07:00',
          endTime: '07:45',
          type: TaskType.personal,
          energyLevel: TaskEnergyLevel.low,
        ),
        _task(
          id,
          title: 'Deep work block',
          startTime: '09:00',
          endTime: '11:30',
          type: TaskType.work,
          priority: TaskPriority.high,
          energyLevel: TaskEnergyLevel.high,
          description: 'Hardest task of the day, before the inbox opens.',
        ),
        _task(
          id,
          title: 'Lunch and a short walk',
          startTime: '13:00',
          endTime: '14:00',
          type: TaskType.personal,
          energyLevel: TaskEnergyLevel.low,
        ),
        _task(
          id,
          title: 'Meetings and admin',
          startTime: '14:00',
          endTime: '16:30',
          type: TaskType.work,
        ),
        _task(
          id,
          title: 'Workout',
          startTime: '18:00',
          endTime: '19:00',
          type: TaskType.health,
          energyLevel: TaskEnergyLevel.high,
        ),
        _task(
          id,
          title: 'Wind down, screens off',
          startTime: '22:00',
          endTime: '22:30',
          type: TaskType.leisure,
          priority: TaskPriority.low,
          energyLevel: TaskEnergyLevel.low,
        ),
      ],
    );

PlanTemplate _weekendReset() => _template(
      name: 'Weekend Reset',
      description: 'Chores, errands and real rest, without losing the day.',
      tasks: (id) => [
        _task(
          id,
          title: 'Slow breakfast',
          startTime: '08:30',
          endTime: '09:15',
          type: TaskType.personal,
          priority: TaskPriority.low,
          energyLevel: TaskEnergyLevel.low,
        ),
        _task(
          id,
          title: 'Home reset and laundry',
          startTime: '09:30',
          endTime: '11:00',
          type: TaskType.personal,
        ),
        _task(
          id,
          title: 'Groceries and errands',
          startTime: '11:00',
          endTime: '12:30',
          type: TaskType.personal,
        ),
        _task(
          id,
          title: 'Plan the week ahead',
          startTime: '15:00',
          endTime: '15:30',
          type: TaskType.work,
          priority: TaskPriority.high,
          energyLevel: TaskEnergyLevel.low,
          description: 'Half an hour now buys back the whole Monday morning.',
        ),
        _task(
          id,
          title: 'Long walk or sport',
          startTime: '16:00',
          endTime: '17:30',
          type: TaskType.health,
          energyLevel: TaskEnergyLevel.high,
        ),
        _task(
          id,
          title: 'Time with people',
          startTime: '19:00',
          endTime: '21:30',
          type: TaskType.leisure,
          energyLevel: TaskEnergyLevel.low,
        ),
      ],
    );

PlanTemplate _deepWorkDay() => _template(
      name: 'Deep Work Day',
      description:
          'Two long focus blocks, everything else pushed to the edges.',
      tasks: (id) => [
        _task(
          id,
          title: 'Pick the one thing',
          startTime: '08:30',
          endTime: '09:00',
          type: TaskType.work,
          priority: TaskPriority.high,
          energyLevel: TaskEnergyLevel.low,
          description: 'Decide what the day is for before anything else can.',
        ),
        _task(
          id,
          title: 'Focus block 1',
          startTime: '09:00',
          endTime: '12:00',
          type: TaskType.work,
          priority: TaskPriority.high,
          energyLevel: TaskEnergyLevel.high,
        ),
        _task(
          id,
          title: 'Lunch away from the desk',
          startTime: '12:00',
          endTime: '13:00',
          type: TaskType.personal,
          priority: TaskPriority.low,
          energyLevel: TaskEnergyLevel.low,
        ),
        _task(
          id,
          title: 'Focus block 2',
          startTime: '13:00',
          endTime: '15:30',
          type: TaskType.work,
          priority: TaskPriority.high,
          energyLevel: TaskEnergyLevel.high,
        ),
        _task(
          id,
          title: 'Email, messages, review',
          startTime: '16:00',
          endTime: '17:00',
          type: TaskType.work,
          priority: TaskPriority.low,
          energyLevel: TaskEnergyLevel.low,
        ),
        _task(
          id,
          title: 'Shutdown ritual',
          startTime: '17:00',
          endTime: '17:15',
          type: TaskType.work,
          priority: TaskPriority.low,
          energyLevel: TaskEnergyLevel.low,
          description: 'Write the first task for tomorrow, then stop.',
        ),
      ],
    );
