# Providers (State Management) Documentation

## Files
- `lib/providers/schedule_provider.dart`
- `lib/providers/todo_provider.dart`

---

## schedule_provider.dart

### Purpose
Central state management for weekly schedule, templates, and analytics. Handles CRUD operations, undo/redo, and recurring template logic.

### Dependencies
- **Imports**: `flutter/material.dart`, `uuid`, models, repositories
- **Dependents**: All schedule-related screens and widgets

### Class Structure

```dart
class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _scheduleRepo;
  final TemplateRepository _templateRepo;
  final PreferenceRepository _prefRepo;

  List<DayPlan> _weekPlan = [];
  List<PlanTemplate> _templates = [];
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  final List<_UndoAction> _undoStack = [];
  SortOrder _sortOrder = SortOrder.asc;
}
```

### State Properties

| Property | Type | Purpose |
|----------|------|---------|
| `weekPlan` | `List<DayPlan>` | Rolling 7-day schedule |
| `templates` | `List<PlanTemplate>` | Saved templates |
| `selectedDayIndex` | `int` | Currently viewed day (0-6) |
| `selectedDay` | `DayPlan` | Computed: current day plan |
| `isLoading` | `bool` | Loading state |
| `canUndo` | `bool` | Undo availability |
| `sortOrder` | `SortOrder` | Task sort (asc/desc) |

### Initialization Flow

```dart
ScheduleProvider({
  required ScheduleRepository scheduleRepo,
  required TemplateRepository templateRepo,
  required PreferenceRepository prefRepo,
})  : _scheduleRepo = scheduleRepo,
      _templateRepo = templateRepo,
      _prefRepo = prefRepo {
  _loadData();
}
```

#### `_loadData()`
**Purpose**: Initialize state from repositories.

**Steps**:
1. Set `_isLoading = true`
2. Load rolling 7-day plan: `_scheduleRepo.getUpcomingDays(7)`
3. Set selected index to 0 (today)
4. Load templates: `_templateRepo.getAllTemplates()`
5. Seed default templates if empty
6. Load sort order from preferences
7. Auto-apply recurring templates
8. Set `_isLoading = false`, notify listeners

**Side Effects**: Database reads, preference load

---

### Day Selection

#### `selectDay(int index)`
```dart
void selectDay(int index) {
  _selectedDayIndex = index;
  notifyListeners();
}
```
- **Purpose**: Change currently selected day
- **Side Effects**: Triggers UI rebuild

---

### Sort Order

#### `toggleSortOrder()`
```dart
void toggleSortOrder() async {
  _sortOrder = _sortOrder == SortOrder.asc ? SortOrder.desc : SortOrder.asc;
  await _prefRepo.set('sort_order', _sortOrder == SortOrder.desc ? 'desc' : 'asc');
  notifyListeners();
}
```
- **Purpose**: Toggle task sorting direction
- **Persistence**: Saves to preferences
- **Usage**: `schedule_view.dart` action toolbar

#### `getSortedTasks(DayPlan dayPlan)`
```dart
List<Task> getSortedTasks(DayPlan dayPlan) {
  final tasks = List<Task>.from(dayPlan.tasks);
  tasks.sort((a, b) => _sortOrder == SortOrder.asc
      ? a.startTime.compareTo(b.startTime)
      : b.startTime.compareTo(a.startTime));
  return tasks;
}
```
- **Purpose**: Return sorted copy of tasks
- **Does Not Modify**: Original list unchanged

---

### Time Validation

#### `validateTimeRange(String startTime, String endTime)`
```dart
String? validateTimeRange(String startTime, String endTime) {
  try {
    final s = startTime.split(':').map(int.parse).toList();
    final e = endTime.split(':').map(int.parse).toList();
    final startMinutes = s[0] * 60 + s[1];
    final endMinutes = e[0] * 60 + e[1];
    
    if (startMinutes == endMinutes) {
      return 'End time must differ from start time';
    }
    // Overnight ranges (e.g. 22:00–01:00) are valid
    return null;
  } catch (e) {
    return 'Invalid time format';
  }
}
```
- **Purpose**: Validate time range in `AddTaskSheet`
- **Allows**: Overnight tasks (22:00–01:00 = 3 hours)
- **Rejects**: Identical start/end times

---

### Task CRUD Operations

#### `addTask(Task task, [DateTime? date])`
**Purpose**: Add task to schedule.

**Logic**:
1. If no date provided: use selected day
2. Find matching day in loaded week
3. If found: optimistic UI update (add + sort)
4. Always: persist via repository

**Side Effects**:
- UI update (if day is visible)
- Database insert

**Risk**: Optimistic update may fail silently if DB write fails

#### `updateTask(String taskId, Task updatedTask)`
**Logic**:
1. Find task in selected day
2. Update in-memory
3. Re-sort by time
4. Persist to database

**Side Effects**: Database update

#### `toggleTaskComplete(String taskId)`
**Logic**:
1. Find task in selected day
2. Toggle `completed` boolean
3. Notify listeners
4. Persist to database

**Side Effects**: Database update

#### `deleteTask(String taskId)`
**Logic**:
1. Find and remove task from list
2. Push undo action to stack
3. Notify listeners
4. Delete from database

**Undo Support**:
```dart
_undoStack.add(_UndoAction(
  type: _UndoType.deleteTask,
  dayIndex: _selectedDayIndex,
  task: removed,
));
```

#### `clearDay()`
**Purpose**: Remove all tasks from selected day.

**Logic**:
1. Copy all tasks
2. Push undo action with full list
3. Clear in-memory list
4. Delete from database

**Undo Support**: Restores all tasks

---

### Undo System

#### `_UndoAction` Class
```dart
class _UndoAction {
  final _UndoType type;  // deleteTask or clearDay
  final int dayIndex;
  final Task? task;      // For single task
  final List<Task>? tasks; // For clear day
}
```

#### `undo()`
**Logic**:
1. Pop action from stack
2. Based on type:
   - `deleteTask`: Re-add task to day
   - `clearDay`: Restore all tasks
3. Re-sort tasks
4. Notify listeners
5. Persist to database

**Risk**: Undo after data refresh may conflict with server state

---

### Template Operations

#### `applyTemplate(PlanTemplate template)`
**Purpose**: Apply template to currently selected day.

**Delegates To**: `_applyTemplateToIndex(template, _selectedDayIndex)`

#### `applyTemplateToDays(PlanTemplate template, List<int> dayIndices)`
**Purpose**: Apply template to specific weekdays (0=Mon, 6=Sun).

**Usage**: "This Week" button in template detail

#### `_applyTemplateToIndex(...)`
**Logic**:
1. Copy template tasks with new UUIDs
2. Set `sourceTemplateId` for tracking
3. Add to day's task list
4. Re-sort
5. Persist full day plan

**Side Effects**: Database write

#### `setTemplateRecurring(String templateId, List<int> days)`
**Purpose**: Set template to auto-apply on specific weekdays.

**Logic**:
1. Update template's `activeDays`
2. Persist to repository
3. Immediately apply to matching days in current week
4. Skip if already applied (check `sourceTemplateId`)

**Recurring Logic**:
```dart
void setTemplateRecurring(String templateId, List<int> days) async {
  // Update template
  _templates[index] = _templates[index].copyWith(activeDays: days);
  await _templateRepo.updateTemplateActiveDays(templateId, days);

  // Apply to current week
  for (int i = 0; i < _weekPlan.length; i++) {
    final weekday = _weekPlan[i].date.weekday - 1;
    if (days.contains(weekday)) {
      final alreadyApplied = _weekPlan[i].tasks.any(
        (t) => t.sourceTemplateId == templateId
      );
      if (!alreadyApplied) {
        _applyTemplateToIndex(_templates[index], i,
            sourceTemplateId: templateId);
      }
    }
  }
}
```

#### `_applyRecurringTemplates()`
**Purpose**: Auto-apply recurring templates when loading data.

**Logic**:
1. Filter templates with `isRecurring`
2. For each day in week:
   - Check if weekday matches any template's `activeDays`
   - Skip if `sourceTemplateId` already exists
   - Apply template

**Called From**: `_loadData()`

#### `stopTemplateRecurring(String templateId)`
**Purpose**: Clear recurring schedule.

**Logic**:
1. Set `activeDays = []`
2. Persist to repository

---

### Template CRUD

| Method | Purpose |
|--------|---------|
| `addTemplate(template)` | Create new template |
| `removeTemplate(id)` | Delete template |
| `updateTemplate(id, name, description)` | Update metadata |
| `addTaskToTemplate(id, task)` | Add task to template |
| `removeTaskFromTemplate(id, taskId)` | Remove task |
| `updateTaskInTemplate(id, taskId, task)` | Update task |
| `saveCurrentDayAsTemplate(name, description)` | Create from current day |

---

### Analytics & Metrics

#### Computed Properties

##### `totalTasks`
```dart
int get totalTasks => _weekPlan.fold(
  0, (sum, day) => sum + day.tasks.length
);
```

##### `completedTasks`
```dart
int get completedTasks => _weekPlan.fold(
  0, (sum, day) => sum + day.tasks.where((t) => t.completed).length
);
```

##### `efficiency`
```dart
double get efficiency =>
  totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;
```

##### `totalFocusHours`
```dart
double get totalFocusHours {
  double hours = 0;
  for (var day in _weekPlan) {
    for (var task in day.tasks) {
      hours += _calculateDuration(task.startTime, task.endTime);
    }
  }
  return hours;
}
```

##### `categoryDistribution`
```dart
Map<TaskType, double> get categoryDistribution {
  Map<TaskType, double> dist = {
    TaskType.work: 0, TaskType.personal: 0,
    TaskType.health: 0, TaskType.leisure: 0,
  };
  for (var day in _weekPlan) {
    for (var task in day.tasks) {
      dist[task.type] = (dist[task.type] ?? 0) +
          _calculateDuration(task.startTime, task.endTime);
    }
  }
  return dist;
}
```

#### `_calculateDuration(String start, String end)`
**Logic**:
1. Parse "HH:mm" to decimal hours
2. Handle overnight: if `endH <= startH`, add 24
3. Clamp to [0, 24]

**Examples**:
- "09:00"–"12:00" → 3.0 hours
- "22:00"–"01:00" → 3.0 hours (overnight)

---

### Risk Areas

#### Shared State
- `_weekPlan` is mutable; callers can modify directly
- Mitigation: `getSortedTasks()` returns copy

#### Optimistic Updates
- UI updates before DB confirms
- Risk: Silent failures if DB write fails

#### Undo Stack
- Not persisted; lost on app restart
- No limit; could grow unbounded

#### Recurring Templates
- `sourceTemplateId` tracking prevents duplicates
- Edge case: Manual task edits may have stale `sourceTemplateId`

#### Concurrency
- Not thread-safe (Flutter UI thread only)
- No locking for read-modify-write operations

---

## todo_provider.dart

### Purpose
State management for standalone todo items (not connected to calendar).

### Dependencies
- **Imports**: `flutter/foundation.dart`, repository, `TodoItem`
- **Dependents**: `TodoListView`, `TodoDetailScreen`

### Class Structure

```dart
class TodoProvider extends ChangeNotifier {
  final TodoRepository _repository;
  List<TodoItem> _todos = [];
  StreamSubscription<List<TodoItem>>? _subscription;
}
```

### Initialization

```dart
TodoProvider(this._repository) {
  _init();
}

void _init() {
  _subscription = _repository.watchTodos().listen((newTodos) {
    _todos = newTodos;
    notifyListeners();
  });
}
```
- **Reactive**: Listens to database stream
- **Auto-Update**: UI refreshes on any change

### Lifecycle

```dart
@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```
- **Important**: Cancel subscription to prevent memory leaks

### CRUD Operations

| Method | Purpose |
|--------|---------|
| `addTodo(title, description)` | Create new todo |
| `toggleTodo(todo)` | Toggle completion |
| `updateTodoData(todo, title, description)` | Update metadata |
| `deleteTodo(id)` | Delete by ID |

### Implementation Pattern
```dart
Future<void> toggleTodo(TodoItem todo) async {
  final updated = todo.copyWith(completed: !todo.completed);
  await _repository.updateTodo(updated);
  // No notifyListeners() - stream handles it
}
```
- **Stream-Driven**: Database stream triggers rebuild
- **No Optimistic Updates**: Simpler than schedule provider

### Risk Areas
- **Subscription Leak**: Must cancel in `dispose()`
- **No Undo**: Unlike schedule provider
- **No Loading State**: Assumes fast local DB

---

## Provider Usage in UI

### Access Pattern
```dart
// Read-only
final provider = Provider.of<ScheduleProvider>(context);

// Without rebuild
final provider = Provider.of<ScheduleProvider>(context, listen: false);

// With Consumer
Consumer<ScheduleProvider>(
  builder: (context, provider, child) {
    return Text('${provider.totalTasks} tasks');
  },
)
```

### Dependency Injection (main.dart)
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => ScheduleProvider(
        scheduleRepo: scheduleRepo,
        templateRepo: templateRepo,
        prefRepo: prefRepo,
      ),
    ),
    ChangeNotifierProvider(
      create: (_) => TodoProvider(todoRepo),
    ),
  ],
  child: MaterialApp(...),
)
```
