import 'package:uuid/uuid.dart';

import 'package:chronosky/data/models/todo_item_model.dart';

/// Sample content for the Workspace tab: three notes, timers, alarms and
/// checklists.
///
/// ## Why this is flagged rather than just inserted
/// Unlike the starter WorkPlans, which are meant to be adopted or deleted,
/// these exist to show what each of the four kinds *is* — so they have to be
/// removable in one action and restorable in the next. Every row carries
/// `isDemo: true`, the demo-data switch filters on it, and nothing is deleted
/// when the switch goes off. See docs/decisions/0014-demo-data.md.
///
/// ## Why the alarms are inert
/// A sample alarm with a real future time would actually go off on the user's
/// phone, which is indefensible for content they did not create. Two things
/// prevent it: demo rows never reach `NotificationCoordinator`, and the times
/// below are deliberately in the past so even the in-app scheduler treats them
/// as missed rather than arming them.
///
/// Returns fresh instances with fresh ids on every call, because each is
/// persisted under its own primary key.
List<TodoItem> demoTodoItems() => [
      ..._notes(),
      ..._timers(),
      ..._alarms(),
      ..._checklists(),
    ];

const Uuid _uuid = Uuid();

/// A fixed point in the past, so demo alarms can never ring.
///
/// Relative to a fixed date rather than `DateTime.now()` so the seeded rows do
/// not shift depending on when the app was first opened, which makes them
/// reproducible in a test.
final DateTime _inertPast = DateTime(2026, 1, 1, 7, 0);

TodoItem _item({
  required String title,
  required TodoItemType type,
  String description = '',
  int durationMinutes = 0,
  List<ChecklistItem> checklist = const [],
  DateTime? scheduledAt,
  bool completed = false,
}) =>
    TodoItem(
      id: _uuid.v4(),
      title: title,
      description: description,
      completed: completed,
      createdAt: DateTime.now(),
      itemType: type,
      durationMinutes: durationMinutes,
      checklist: checklist,
      scheduledAt: scheduledAt,
      // Demo alarms are disarmed as well as past-dated: belt and braces, so
      // nothing rings for content the user did not create.
      enabled: type != TodoItemType.alarm,
      isDemo: true,
    );

List<TodoItem> _notes() => [
      _item(
        title: 'Standup notes',
        type: TodoItemType.note,
        description: 'Shipped the migration. Blocked on the staging key. '
            'Next: wire the retry path.',
      ),
      _item(
        title: 'Reading list',
        type: TodoItemType.note,
        description: 'Thinking in Systems. A Philosophy of Software Design. '
            'The Timeless Way of Building.',
      ),
      _item(
        title: 'Idea — weekly review ritual',
        type: TodoItemType.note,
        description: 'Fifteen minutes on Sunday: close the loops, pick the '
            'one thing for Monday.',
      ),
    ];

List<TodoItem> _timers() => [
      _item(
        title: 'Focus sprint',
        type: TodoItemType.timer,
        description: 'The classic pomodoro.',
        durationMinutes: 25,
      ),
      _item(
        title: 'Short break',
        type: TodoItemType.timer,
        description: 'Stand up, look out of a window.',
        durationMinutes: 5,
      ),
      _item(
        title: 'Deep work block',
        type: TodoItemType.timer,
        description: 'Long enough to get somewhere.',
        durationMinutes: 90,
      ),
    ];

List<TodoItem> _alarms() => [
      _item(
        title: 'Wake up',
        type: TodoItemType.alarm,
        description: 'Sample alarm — switched off.',
        scheduledAt: _inertPast,
      ),
      _item(
        title: 'Leave for the gym',
        type: TodoItemType.alarm,
        description: 'Sample alarm — switched off.',
        scheduledAt: _inertPast.add(const Duration(hours: 11)),
      ),
      _item(
        title: 'Wind down',
        type: TodoItemType.alarm,
        description: 'Sample alarm — switched off.',
        scheduledAt: _inertPast.add(const Duration(hours: 15)),
      ),
    ];

List<TodoItem> _checklists() => [
      _item(
        title: 'Groceries',
        type: TodoItemType.list,
        checklist: const [
          ChecklistItem(text: 'Coffee', done: true),
          ChecklistItem(text: 'Oats'),
          ChecklistItem(text: 'Olive oil'),
          ChecklistItem(text: 'Something green'),
        ],
      ),
      _item(
        title: 'Packing — two nights',
        type: TodoItemType.list,
        checklist: const [
          ChecklistItem(text: 'Charger', done: true),
          ChecklistItem(text: 'Passport', done: true),
          ChecklistItem(text: 'Running shoes'),
          ChecklistItem(text: 'Book'),
        ],
      ),
      _item(
        title: 'New laptop setup',
        type: TodoItemType.list,
        checklist: const [
          ChecklistItem(text: 'Dotfiles', done: true),
          ChecklistItem(text: 'SSH keys'),
          ChecklistItem(text: 'Password manager'),
          ChecklistItem(text: 'Turn off the startup chime'),
        ],
      ),
    ];
