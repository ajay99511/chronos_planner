# Data Layer - Repositories Documentation

## Files
- `lib/data/repositories/*.dart` (abstract interfaces)
- `lib/data/repositories/local/*.dart` (implementations)

---

## Repository Pattern Overview

### Purpose
Abstraction layer between business logic (providers) and data sources (Drift). Enables:
- Test mocking via interface injection
- Future data source swaps (e.g., add remote sync)
- Clean separation of concerns

### Dependency Flow
```
Provider → Repository (interface) → Local Repository → DAO → Database
```

---

## schedule_repository.dart (Interface)

### Purpose
Contract for schedule (day plans + tasks) operations.

### Dependencies
- **Imports**: `day_plan_model.dart`, `task_model.dart`
- **Dependents**: `ScheduleProvider`, `LocalScheduleRepository`

### Interface Methods

| Method | Purpose |
|--------|---------|
| `getUpcomingDays(count)` | Get rolling N days from today |
| `addTaskToDate(date, task)` | Add task, auto-create day if needed |
| `saveDayPlan(dayPlan)` | Persist full day's tasks |
| `addTask(dayPlanId, task)` | Add task to existing day |
| `updateTask(dayPlanId, taskId, task)` | Update task |
| `deleteTask(dayPlanId, taskId)` | Delete task |
| `clearDay(dayPlanId)` | Delete all tasks for day |

---

## local_schedule_repository.dart (Implementation)

### Purpose
Drift-backed implementation of `ScheduleRepository`.

### Dependencies
- **Imports**: `drift`, `intl`, `uuid`, DAOs, models, interface
- **Dependents**: `main.dart` (injection), `ScheduleProvider`

### Key Properties
```dart
final DayPlanDao _dayPlanDao;
final TaskDao _taskDao;
```

### Constructor
```dart
LocalScheduleRepository(this._dayPlanDao, this._taskDao);
```

### Key Methods

#### `getUpcomingDays(int count)`
**Purpose**: Fetch or create rolling N-day schedule starting from today.

**Logic**:
1. Query existing day plans from database
2. For each requested day:
   - If exists: load with tasks
   - If missing: prepare for creation
3. Batch insert missing days
4. Return complete list

**Side Effects**: Creates missing days in database

**Risk**: Race condition if called concurrently (not an issue in single-threaded UI)

#### `addTaskToDate(DateTime date, Task task)`
**Purpose**: Add task to specific date, auto-creating day plan if needed.

**Logic**:
1. Normalize date to midnight
2. Check if day plan exists via `getDayPlanId()`
3. If missing: create day plan with week key
4. Call `addTask()` to persist

**Side Effects**: May create day plan

#### `saveDayPlan(DayPlan dayPlan)`
**Purpose**: Replace all tasks for a day (delete + re-insert).

**Logic**:
1. Delete all existing tasks for day
2. Batch insert new task list

**Side Effects**: Destructive replace

**Risk**: No transaction wrapper (partial failure possible)

#### Week Key Calculation
```dart
String _calculateWeekKey(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  final weekNumber = ((monday.difference(DateTime(monday.year, 1, 1)).inDays) / 7).ceil() + 1;
  return '${monday.year}-W${weekNumber.toString().padLeft(2, '0')}';
}
```
- **Format**: `YYYY-W##` (ISO week numbering)
- **Usage**: Groups 7 days into weeks

### Mapper Methods

#### `_dbTaskToModel(Task dbTask)`
- **Purpose**: Convert Drift `Task` to domain `Task`
- **Enum Parsing**: `TaskType.values.firstWhere(e.name == dbTask.type)`

#### `_modelTaskToCompanion(Task task, String dayPlanId)`
- **Purpose**: Convert domain `Task` to `TasksCompanion` for insertion
- **Usage**: All write operations

### Risk Areas
- **Optimistic Updates**: Provider handles UI before DB confirms
- **No Rollback**: Failed writes leave partial state
- **Date Normalization**: Critical for matching (midnight truncation)

---

## todo_repository.dart (Interface)

### Purpose
Contract for standalone todo item operations.

### Interface Methods

| Method | Purpose |
|--------|---------|
| `loadTodos()` | Fetch all todos |
| `watchTodos()` | Reactive stream |
| `addTodo(title, description)` | Create new todo |
| `updateTodo(todo)` | Update existing |
| `deleteTodo(id)` | Delete by ID |

---

## local_todo_repository.dart (Implementation)

### Purpose
Drift-backed implementation of `TodoRepository`.

### Dependencies
- **Imports**: `drift`, `uuid`, DAOs, interface
- **Dependents**: `main.dart`, `TodoProvider`

### Key Properties
```dart
final TodoItemDao _todoItemDao;
final _uuid = const Uuid();
```

### Key Methods

#### `addTodo(String title, {String description})`
**Logic**:
1. Generate UUID
2. Create `TodoItemsCompanion.insert()`
3. Insert to database
4. Fetch and return created item

**Side Effects**: Database insert

**Risk**: Fetch-after-insert ensures returned item has all defaults

#### `watchTodos()`
**Returns**: `Stream<List<TodoItem>>` from DAO

**Usage**: `TodoProvider` subscribes in `_init()`

---

## template_repository.dart (Interface)

### Purpose
Contract for plan template operations.

### Interface Methods

| Method | Purpose |
|--------|---------|
| `getAllTemplates()` | Fetch all templates |
| `addTemplate(template)` | Create new template |
| `updateTemplate(id, name, description)` | Update metadata |
| `deleteTemplate(id)` | Delete template + tasks |
| `addTaskToTemplate(id, task)` | Add task to template |
| `updateTaskInTemplate(id, taskId, task)` | Update template task |
| `removeTaskFromTemplate(id, taskId)` | Remove task from template |
| `updateTemplateActiveDays(id, days)` | Set recurring days |
| `getRecurringTemplates()` | Get templates with activeDays |

---

## local_template_repository.dart (Implementation)

### Purpose
Drift-backed implementation of `TemplateRepository`.

### Dependencies
- **Imports**: `drift`, DAOs, models, interface
- **Dependents**: `main.dart`, `ScheduleProvider`

### Key Properties
```dart
final TemplateDao _templateDao;
```

### Key Methods

#### `getAllTemplates()`
**Logic**:
1. Fetch all template metadata
2. For each template: fetch associated tasks
3. Build `PlanTemplate` objects with task lists

**Side Effects**: N+1 query pattern (could optimize with joins)

#### `addTemplate(PlanTemplate template)`
**Logic**:
1. Insert template metadata
2. If tasks exist: batch insert template tasks

**Side Effects**: Two separate inserts (not transactional)

#### `updateTemplateActiveDays(String templateId, List<int> days)`
**Encoding**:
```dart
String _encodeDays(List<int> days) {
  if (days.isEmpty) return '';
  return days.join(',');  // "0,2,4"
}
```

**Decoding**:
```dart
List<int> _parseActiveDays(String raw) {
  if (raw.isEmpty) return [];
  return raw.split(',').map((s) => int.tryParse(s.trim()) ?? -1)
    .where((i) => i >= 0).toList();
}
```

**Risk**: String encoding is fragile (no validation)

### Mapper Methods

#### `_dbTemplateTaskToModel(TemplateTask dbTask)`
- **Purpose**: Convert Drift `TemplateTask` to domain `Task`
- **Note**: Does not preserve `sourceTemplateId` (template tasks don't need it)

#### `_modelTaskToCompanion(Task task, String templateId)`
- **Purpose**: Convert domain `Task` to `TemplateTasksCompanion`

### Risk Areas
- **N+1 Queries**: `getAllTemplates` fetches tasks per template
- **String Encoding**: `activeDays` as comma-separated string
- **No Transactions**: Multi-step operations not atomic

---

## preference_repository.dart (Interface)

### Purpose
Contract for key-value preference storage.

### Interface Methods

| Method | Purpose |
|--------|---------|
| `get(key)` | Get value by key |
| `set(key, value)` | Set value |
| `remove(key)` | Delete by key |
| `getAll()` | Get all as map |

---

## local_preference_repository.dart (Implementation)

### Purpose
Drift-backed implementation of `PreferenceRepository`.

### Dependencies
- **Imports**: `preference_dao.dart`, interface
- **Dependents**: `main.dart`, `ScheduleProvider`

### Implementation
Simple delegation to `PreferenceDao`:
```dart
class LocalPreferenceRepository implements PreferenceRepository {
  final PreferenceDao _dao;
  LocalPreferenceRepository(this._dao);

  @override
  Future<String?> get(String key) => _dao.getValue(key);

  @override
  Future<void> set(String key, String value) => _dao.setValue(key, value);

  @override
  Future<void> remove(String key) => _dao.deleteValue(key);

  @override
  Future<Map<String, String>> getAll() => _dao.getAll();
}
```

### Usage
```dart
// Save sort order
await prefRepo.set('sort_order', 'desc');

// Load sort order
final sort = await prefRepo.get('sort_order');
```

---

## Testing Strategy

### Mocking Repositories
```dart
class MockScheduleRepository implements ScheduleRepository {
  @override
  Future<List<DayPlan>> getUpcomingDays(int count) async {
    return []; // Test data
  }
  // ... other methods
}
```

### Dependency Injection
```dart
// Production
final repo = LocalScheduleRepository(db.dayPlanDao, db.taskDao);

// Test
final repo = MockScheduleRepository();
```

### Benefits
- Test business logic without database
- Swap implementations (e.g., add cloud sync)
- Clear interface contracts
