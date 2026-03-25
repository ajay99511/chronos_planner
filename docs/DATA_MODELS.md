# Data Layer - Models Documentation

## Files
- `lib/data/models/task_model.dart`
- `lib/data/models/day_plan_model.dart`
- `lib/data/models/plan_template_model.dart`

---

## task_model.dart

### Purpose
Core domain model representing a scheduled task with time, type, priority, and energy attributes.

### Dependencies
- **Imports**: None (pure Dart)
- **Dependents**: All layers (providers, repositories, UI, services)

### Enums

#### `TaskType`
Categories for task classification:
- `work`, `personal`, `health`, `leisure`

#### `TaskPriority`
Importance levels:
- `low`, `medium`, `high`

#### `TaskEnergyLevel`
Mental/physical energy required:
- `low`, `medium`, `high`

### Task Class

#### Properties
| Property | Type | Description |
|----------|------|-------------|
| `id` | String | UUID v4 |
| `title` | String | Task name (1-200 chars) |
| `startTime` | String | "HH:mm" format |
| `endTime` | String | "HH:mm" format |
| `type` | TaskType | Category |
| `priority` | TaskPriority | Importance |
| `energyLevel` | TaskEnergyLevel | Required energy |
| `estimatedCost` | double | Planned cost (default 0.0) |
| `actualCost` | double | Actual cost (default 0.0) |
| `description` | String | Details (optional) |
| `sourceTemplateId` | String | Template origin (optional) |
| `completed` | bool | Completion status |

#### Key Methods

##### `copyWith({...})`
- **Purpose**: Immutable updates
- **Returns**: New Task instance with merged values
- **Usage**: State updates in providers

##### `toJson()` / `fromJson()`
- **Purpose**: JSON serialization
- **Side Effects**: None
- **Risk**: `fromJson` uses `orElse` defaults for enums

### Risk Areas
- **Time Format**: String-based "HH:mm" - no validation at model level
- **Mutable State**: `completed` is mutable (intentional for toggling)
- **Default Values**: Silent fallbacks in `fromJson` may hide data issues

### Usage Pattern
```dart
// Create task
final task = Task(
  id: uuid.v4(),
  title: 'Deep Work',
  startTime: '09:00',
  endTime: '12:00',
  type: TaskType.work,
  priority: TaskPriority.high,
);

// Update immutably
final updated = task.copyWith(completed: true);

// Serialize
final json = task.toJson();
```

---

## day_plan_model.dart

### Purpose
Aggregates tasks for a specific date. Represents one day in the weekly schedule.

### Dependencies
- **Imports**: `task_model.dart`
- **Dependents**: Providers, repositories, schedule views

### DayPlan Class

#### Properties
| Property | Type | Description |
|----------|------|-------------|
| `id` | String | UUID v4 |
| `dateStr` | String | Display format "Feb 10" |
| `dayOfWeek` | String | Full name "Monday" |
| `date` | DateTime | Actual date object |
| `tasks` | List<Task> | Mutable task list |

#### Key Methods

##### `toJson()` / `fromJson()`
- **Purpose**: JSON serialization
- **Note**: Tasks are serialized as nested array

### Risk Areas
- **Mutable Tasks List**: Direct reference exposed; callers can modify
- **Date Parsing**: `fromJson` handles null date with `DateTime.now()` fallback

### Relationships
```
DayPlan
  ├── id (PK)
  ├── dateStr, dayOfWeek, date (metadata)
  └── tasks[] → Task[]
```

---

## plan_template_model.dart

### Purpose
Reusable task templates for recurring schedules. Supports "Deep Work Friday" style patterns.

### Dependencies
- **Imports**: `task_model.dart`
- **Dependents**: Providers, template repositories, work plans views

### PlanTemplate Class

#### Properties
| Property | Type | Description |
|----------|------|-------------|
| `id` | String | UUID v4 |
| `name` | String | Template name (e.g., "Deep Work Friday") |
| `description` | String | Details |
| `tasks` | List<Task> | Template tasks |
| `activeDays` | List<int> | Recurring days (0=Mon, 6=Sun) |

#### Computed Properties

##### `isRecurring`
- **Returns**: `true` if `activeDays.isNotEmpty`
- **Usage**: UI shows "Recurring" badge

#### Key Methods

##### `copyWith({...})`
- **Purpose**: Immutable updates
- **Usage**: Provider state updates

##### `toJson()` / `fromJson()`
- **Purpose**: JSON serialization
- **Note**: `activeDays` encoded as integer array

### Risk Areas
- **Active Days Encoding**: Stored as comma-separated string in DB, parsed to `List<int>`
- **Task Source Tracking**: `sourceTemplateId` links applied tasks back to templates

### Recurring Logic
```dart
// Apply template to specific weekdays
template.activeDays = [0, 2, 4]; // Mon, Wed, Fri

// Auto-apply checks:
// 1. Day's weekday matches activeDays
// 2. Task with sourceTemplateId doesn't already exist
```

### Relationships
```
PlanTemplate
  ├── id (PK)
  ├── name, description (metadata)
  ├── activeDays[] → [0-6]
  └── tasks[] → Task[] (with sourceTemplateId link)
```
