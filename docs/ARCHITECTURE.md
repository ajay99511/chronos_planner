# Chronos Planner - Architecture Overview

## Application Type
Flutter-based time management and productivity application with desktop support (Windows, Linux, macOS).

## Architecture Pattern
**Layered Architecture** with clear separation of concerns:
- **UI Layer**: Screens, Widgets, Dialogs
- **State Management**: Providers (ChangeNotifier via `provider` package)
- **Data Layer**: Repositories (abstract interfaces + local implementations)
- **Local Storage**: Drift (SQLite) with DAOs
- **Core Services**: Theme, Intelligence Service

## Dependency Flow

```
UI (Screens/Widgets)
    ↓
Providers (State Management)
    ↓
Repositories (Abstract Interfaces)
    ↓
Local Implementations → Drift DAOs → SQLite Database
```

## Key Design Decisions

### 1. Repository Pattern
- Abstract interfaces define contracts (`ScheduleRepository`, `TodoRepository`, etc.)
- Local implementations (`LocalScheduleRepository`) use Drift directly
- UI depends only on abstractions, not concrete implementations

### 2. ChangeNotifier-based State
- Providers manage UI state and trigger rebuilds
- Optimistic UI updates followed by persistence
- Undo/redo support via action stacks

### 3. Template System
- Reusable plan templates with recurring support
- Templates can auto-apply to specific weekdays
- Source tracking links tasks back to templates

### 4. Rolling Week Model
- Always shows 7 days starting from today
- Auto-creates missing days on load
- Week key format: `YYYY-W##` (ISO week numbering)

## Core Technologies

| Technology | Purpose |
|------------|---------|
| `provider` | State management |
| `drift` | SQLite ORM with reactive streams |
| `shared_preferences` | Legacy storage (migration only) |
| `window_manager` | Desktop window control (Focus Mode) |
| `google_fonts` | Typography (Inter font) |
| `uuid` | Unique ID generation |
| `intl` | Date/time formatting |

## Data Model Relationships

```
DayPlan (1) ──→ (N) Task
    │
    └── weekKey: groups 7 days

PlanTemplate (1) ──→ (N) TemplateTask
    │
    └── activeDays: recurring schedule

TodoItem (standalone)
```

## Threading Model
- Drift uses `LazyDatabase` with background execution
- UI remains responsive during database operations
- Streams (`watchTasksForDay`) provide reactive updates

## Platform Support
- **Primary**: Desktop (Windows, Linux, macOS)
- **Window Management**: Custom sizing for Focus Mode
- **Mobile**: Supported but not optimized

## Entry Point
`lib/main.dart` → `MyApp` widget with dependency injection

---

## 📚 Documentation Index

This document is part of the Chronos Planner documentation suite:

| Document | Description |
|----------|-------------|
| [Architecture](ARCHITECTURE.md) | System overview, dependency flow, design decisions |
| [Core Layer](CORE_LAYER.md) | Intelligence Service, Theme system |
| [Data Models](DATA_MODELS.md) | Task, DayPlan, PlanTemplate domain models |
| [Database](DATA_DATABASE.md) | Schema, DAOs, migrations |
| [Repositories](DATA_REPOSITORIES.md) | Repository pattern, implementations |
| [Providers](PROVIDERS.md) | State management, undo system, analytics |
| [Screens](UI_SCREENS.md) | UI screens, navigation, interactions |
| [Widgets](UI_WIDGETS.md) | Reusable components, glassmorphism |
| [Getting Started](GETTING_STARTED.md) | Developer onboarding, setup guide |
| [Features](FEATURES.md) | Complete feature list and roadmap |

**Main README:** [../README.md](../README.md)
