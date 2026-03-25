# Data Layer - Database & DAOs Documentation

## Files
- `lib/data/local/app_database.dart`
- `lib/data/local/tables.dart`
- `lib/data/local/daos/*.dart`
- `lib/data/local/migration_helper.dart`

---

## app_database.dart

### Purpose
Singleton Drift database connection manager. Central hub for all DAOs and schema migrations.

### Dependencies
- **Imports**: `drift`, `path_provider`, `path`, DAOs, tables
- **Dependents**: All repository implementations, migration helper

### AppDatabase Class

#### Schema Version
- **Current**: `schemaVersion = 4`
- **Migration Strategy**: Incremental upgrades

#### Migration History

##### v1 → v2
```sql
ALTER TABLE tasks ADD COLUMN source_template_id TEXT NOT NULL DEFAULT ''
ALTER TABLE plan_templates ADD COLUMN active_days TEXT NOT NULL DEFAULT ''
```
- **Purpose**: Template tracking and recurring schedules

##### v2 → v3
```dart
await m.createTable(todoItems);
```
- **Purpose**: Added standalone todo items

##### v3 → v4
```sql
ALTER TABLE tasks ADD COLUMN energy_level TEXT NOT NULL DEFAULT 'medium'
ALTER TABLE tasks ADD COLUMN estimated_cost REAL NOT NULL DEFAULT 0.0
ALTER TABLE tasks ADD COLUMN actual_cost REAL NOT NULL DEFAULT 0.0
ALTER TABLE template_tasks ADD COLUMN energy_level TEXT NOT NULL DEFAULT 'medium'
ALTER TABLE template_tasks ADD COLUMN estimated_cost REAL NOT NULL DEFAULT 0.0
```
- **Purpose**: Energy-based scheduling and cost tracking

#### Singleton Pattern
```dart
static AppDatabase get instance {
  _instance ??= AppDatabase._();
  return _instance!;
}
```
- **Thread Safety**: `LazyDatabase` handles background execution
- **Risk**: Not null-safe initialized (ensure first access before DAOs)

### Connection Setup
```dart
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'chronos_planner.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```
- **Storage Location**: Platform-specific documents directory
- **Database File**: `chronos_planner.sqlite`

### Risk Areas
- **Singleton State**: Global state can persist across test runs
- **Migration Order**: Must maintain sequential version upgrades
- **Schema Changes**: Breaking changes require careful migration logic

---

## tables.dart

### Purpose
Drift table definitions. Source of truth for database schema.

### Dependencies
- **Imports**: `drift/drift.dart`
- **Dependents**: `app_database.dart`, all DAOs

### Table Definitions

#### Tasks
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | Text | PRIMARY KEY |
| `title` | Text | 1-200 chars |
| `description` | Text | Default '' |
| `startTime` | Text | "HH:mm" |
| `endTime` | Text | "HH:mm" |
| `type` | Text | TaskType enum |
| `priority` | Text | Default 'medium' |
| `energyLevel` | Text | Default 'medium' |
| `estimatedCost` | Real | Default 0.0 |
| `actualCost` | Real | Default 0.0 |
| `completed` | Bool | Default false |
| `dayPlanId` | Text | FK → DayPlans.id |
| `sourceTemplateId` | Text | Default '' |

#### DayPlans
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | Text | PRIMARY KEY |
| `dateStr` | Text | "Feb 10" |
| `dayOfWeek` | Text | "Monday" |
| `date` | DateTime | |
| `weekKey` | Text | "2026-W07" |

#### PlanTemplates
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | Text | PRIMARY KEY |
| `name` | Text | 1-100 chars |
| `description` | Text | Default '' |
| `activeDays` | Text | Default '' (comma-separated) |

#### TemplateTasks
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | Text | PRIMARY KEY |
| `templateId` | Text | FK → PlanTemplates.id |
| `title` | Text | 1-200 chars |
| `description` | Text | Default '' |
| `startTime` | Text | "HH:mm" |
| `endTime` | Text | "HH:mm" |
| `type` | Text | TaskType enum |
| `priority` | Text | Default 'medium' |
| `energyLevel` | Text | Default 'medium' |
| `estimatedCost` | Real | Default 0.0 |

#### Preferences
| Column | Type | Constraints |
|--------|------|-------------|
| `key` | Text | PRIMARY KEY |
| `value` | Text | |

#### TodoItems
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | Text | PRIMARY KEY |
| `title` | Text | 1-200 chars |
| `description` | Text | Default '' |
| `completed` | Bool | Default false |
| `createdAt` | DateTime | Default now() |

### Risk Areas
- **Foreign Keys**: No CASCADE delete (manual cleanup required)
- **String Enums**: Stored as names, not integers (refactor-safe)
- **Active Days**: Comma-separated string instead of junction table

---

## DAOs (Data Access Objects)

### Common Pattern
```dart
@DriftAccessor(tables: [TableName])
class TableDao extends DatabaseAccessor<AppDatabase> with _$TableDaoMixin {
  TableDao(super.db);
  // CRUD methods
}
```

### task_dao.dart

#### Key Methods
| Method | Purpose | Returns |
|--------|---------|---------|
| `getTasksForDay(dayPlanId)` | Fetch tasks for date | `Future<List<Task>>` |
| `watchTasksForDay(dayPlanId)` | Reactive stream | `Stream<List<Task>>` |
| `insertTask(task)` | Add single task | `Future<void>` |
| `insertTasks(list)` | Batch insert | `Future<void>` |
| `updateTask(taskId, updates)` | Update by ID | `Future<void>` |
| `deleteTaskById(taskId)` | Delete single | `Future<int>` |
| `deleteTasksForDay(dayPlanId)` | Delete all for day | `Future<int>` |

#### Risk Areas
- **Batch Operations**: `insertTasks` uses transaction internally
- **Stream Ordering**: `watchTasksForDay` ordered by `startTime`

---

### day_plan_dao.dart

#### Key Methods
| Method | Purpose | Returns |
|--------|---------|---------|
| `getDayPlansForWeek(weekKey)` | Get week's plans | `Future<List<DayPlan>>` |
| `getDayPlansFrom(date, limit)` | Paginated fetch | `Future<List<DayPlan>>` |
| `getDayPlanId(date)` | Get ID for date | `Future<String?>` |
| `insertDayPlan(plan)` | Add single | `Future<void>` |
| `insertDayPlans(list)` | Batch insert week | `Future<void>` |
| `updateDayPlan(planId, updates)` | Update | `Future<void>` |
| `deleteDayPlansForWeek(weekKey)` | Delete week | `Future<int>` |
| `weekExists(weekKey)` | Check existence | `Future<bool>` |

#### Usage Pattern
```dart
// Check before creating
final exists = await db.dayPlanDao.weekExists(weekKey);
if (!exists) {
  await db.dayPlanDao.insertDayPlans(weekPlans);
}
```

---

### template_dao.dart

#### Key Methods
| Method | Purpose | Returns |
|--------|---------|---------|
| `getAllTemplates()` | Fetch all | `Future<List<PlanTemplate>>` |
| `getRecurringTemplates()` | With activeDays | `Future<List<PlanTemplate>>` |
| `watchAllTemplates()` | Reactive stream | `Stream<List<PlanTemplate>>` |
| `insertTemplate(tmpl)` | Add template | `Future<void>` |
| `updateTemplate(id, updates)` | Update metadata | `Future<void>` |
| `deleteTemplate(id)` | Cascade delete | `Future<void>` |
| `getTasksForTemplate(id)` | Fetch template tasks | `Future<List<TemplateTask>>` |
| `insertTemplateTask(task)` | Add task to template | `Future<void>` |
| `updateTemplateTask(id, updates)` | Update task | `Future<void>` |
| `deleteTemplateTask(id)` | Remove task | `Future<int>` |

#### Risk Areas
- **Cascade Delete**: Manual implementation (delete tasks first)
- **Active Days Filter**: SQL query on string length

---

### preference_dao.dart

#### Key Methods
| Method | Purpose | Returns |
|--------|---------|---------|
| `getValue(key)` | Get by key | `Future<String?>` |
| `setValue(key, value)` | Insert/update | `Future<void>` |
| `deleteValue(key)` | Remove | `Future<int>` |
| `getAll()` | All as map | `Future<Map<String, String>>` |

#### Implementation
```dart
Future<void> setValue(String key, String value) {
  return into(preferences).insertOnConflictUpdate(
    PreferencesCompanion(key: Value(key), value: Value(value)),
  );
}
```
- **Upsert Logic**: `insertOnConflictUpdate` handles insert or update

---

### todo_item_dao.dart

#### Key Methods
| Method | Purpose | Returns |
|--------|---------|---------|
| `getAllTodos()` | Fetch all | `Future<List<TodoItem>>` |
| `watchAllTodos()` | Reactive stream | `Stream<List<TodoItem>>` |
| `insertTodo(todo)` | Add | `Future<int>` |
| `updateTodo(todo)` | Replace | `Future<bool>` |
| `deleteTodoById(id)` | Delete | `Future<int>` |

#### Stream Ordering
```dart
Stream<List<TodoItem>> watchAllTodos() => (select(todoItems)
  ..orderBy([(t) => OrderingTerm(
    expression: t.createdAt,
    mode: OrderingMode.desc,
  )]))
  .watch();
```
- **Order**: Newest first (descending `createdAt`)

---

## migration_helper.dart

### Purpose
One-time migration from SharedPreferences to Drift database.

### Dependencies
- **Imports**: `shared_preferences`, `app_database.dart`, models
- **Dependents**: Called from `main.dart` on startup

### Migration Keys
```dart
static const _spWeekKey = 'chronos-week';
static const _spTemplatesKey = 'chronos-templates';
static const _spSortOrderKey = 'chronos-sort-order';
static const _spMigratedFlag = 'chronos-drift-migrated';
```

### Migration Flow
1. Check `_spMigratedFlag` in SharedPreferences
2. If not migrated:
   - Migrate week plan (day plans + tasks)
   - Migrate templates (templates + tasks)
   - Migrate preferences (sort order)
   - Set flag, clean up old keys
3. If already migrated: skip

### Risk Areas
- **Idempotency**: Safe to retry on failure (flag not set until complete)
- **Week Key Derivation**: Must match current calculation logic
- **Data Loss**: Old SP keys deleted after successful migration
