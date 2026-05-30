# Requirements Document

## Introduction

> **Chronos Planner Technical Specification Document (TSD)**

This document is the single source of truth for the Chronos Planner Flutter application (`chronosky`). It covers all engineering, QA, and DevOps requirements across 16 technical domains. The application is a futuristic time-management tool targeting desktop platforms (Windows, Linux, macOS) as primary, with Android and iOS as supported secondary targets. The current codebase is at schema version 4, uses `provider` ^6.1.1 for state management, `drift` ^2.25.0 for SQLite persistence, and Navigator 1.0 for routing. This TSD formalises the standards, patterns, and measurable acceptance criteria that all future development MUST satisfy.

---

## Glossary

- **App**: The Chronos Planner Flutter application (`chronosky`).
- **ScheduleProvider**: The `ChangeNotifier` that owns weekly schedule, template, and analytics state.
- **TodoProvider**: The `ChangeNotifier` that owns standalone todo-item state.
- **Repository**: An abstract Dart interface that decouples business logic from data sources.
- **DAO**: A Drift `DatabaseAccessor` subclass responsible for raw SQL operations.
- **DayPlan**: Domain model aggregating all `Task` objects for a single calendar date.
- **Task**: Domain model representing a time-blocked activity with type, priority, energy level, and cost.
- **PlanTemplate**: A reusable collection of `Task` objects that can be applied to one or more weekdays.
- **TemplateTask**: A `Task` variant stored inside a `PlanTemplate` (no `dayPlanId`).
- **TodoItem**: A standalone checklist item not bound to a calendar date.
- **IntelligenceService**: A stateless analytics service that computes efficiency, energy peaks, and task ROI.
- **AppTheme**: The compile-time design-token system (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppAnimDurations`, `AppGradients`).
- **FocusHUD**: The compact 320×200 floating overlay used in desktop Focus Mode.
- **WeekKey**: An ISO-style string `YYYY-W##` grouping seven `DayPlan` rows.
- **UndoStack**: An in-memory list of reversible `_UndoAction` objects inside `ScheduleProvider`.
- **Drift**: The SQLite ORM used for all local persistence (`drift` ^2.25.0).
- **Navigator**: Flutter's imperative Navigator 1.0 API (no `go_router`).
- **CI/CD**: Continuous Integration / Continuous Delivery pipeline.
- **WCAG**: Web Content Accessibility Guidelines 2.1.
- **ARB**: Application Resource Bundle — Flutter's standard localisation file format.
- **PBT**: Property-Based Testing.
- **Golden Test**: A pixel-snapshot regression test for Flutter widgets.
- **Isolate**: A Dart concurrency primitive for background computation.
- **FFI**: Dart Foreign Function Interface for native code interop.
- **MethodChannel**: Flutter platform channel for invoking native platform APIs.
- **EventChannel**: Flutter platform channel for receiving native event streams.

---

## Requirements


---

### Requirement 1: Architectural Foundation

**User Story:** As a Principal Software Architect, I want the codebase to enforce a strict layered architecture with documented dependency rules, so that every engineer can make changes in one layer without unintentionally coupling to another.

#### Acceptance Criteria

1. THE App SHALL enforce a four-layer dependency hierarchy: UI → Providers → Repositories → DAOs, where no lower layer imports from a higher layer.
2. THE App SHALL define every repository as a Dart abstract class (interface) before any concrete implementation is written, so that the UI and Providers depend only on abstractions.
3. WHEN a new feature module is added, THE App SHALL place its files under `lib/<feature>/` with sub-folders `models/`, `repositories/`, `providers/`, and `ui/`, matching the existing `data/`, `providers/`, and `ui/` conventions.
4. THE App SHALL perform all dependency injection in `main.dart` via constructor injection; no service locator (`get_it` or equivalent) SHALL be introduced without an explicit Architecture Decision Record (ADR).
5. THE App SHALL retain `provider` ^6.1.1 (`ChangeNotifier`) as the sole state-management library; BLoC, Riverpod, and Redux SHALL NOT be introduced in v1.x without an ADR.
6. THE App SHALL retain Navigator 1.0 (imperative push/pop) for all routing in v1.x; `go_router` or `auto_route` SHALL NOT be introduced without an ADR documenting the migration plan.
7. WHEN `ScheduleProvider` or `TodoProvider` is instantiated, THE App SHALL inject all repository dependencies through the constructor so that tests can substitute mock implementations.
8. THE App SHALL expose no `static` mutable state outside of `AppDatabase.instance`; the singleton pattern SHALL be limited to the database connection.
9. WHERE a feature requires cross-provider communication, THE App SHALL use a shared repository or a dedicated coordinator class rather than having one `ChangeNotifier` hold a reference to another.
10. THE App SHALL document every architectural decision that deviates from the patterns in this TSD in a file at `docs/adr/ADR-NNN-title.md` using the MADR template.

---

### Requirement 2: UI/UX Standards and Responsiveness

**User Story:** As a UI engineer, I want a single authoritative design-token system and clear responsiveness rules, so that every screen is visually consistent and adapts correctly to all supported window sizes.

#### Acceptance Criteria

1. THE App SHALL source all colours exclusively from `AppColors`; no hardcoded `Color(0x...)` or `Colors.*` literals SHALL appear in widget files except inside `AppTheme` itself.
2. THE App SHALL source all text styles exclusively from `AppTextStyles`; no inline `TextStyle(fontSize: ...)` literals SHALL appear in widget files.
3. THE App SHALL source all spacing values exclusively from `AppSpacing`; no magic-number padding or margin literals SHALL appear in widget files.
4. THE App SHALL source all border-radius values exclusively from `AppRadius`; no inline `BorderRadius.circular(N)` literals with unlisted values SHALL appear in widget files.
5. THE App SHALL source all animation durations exclusively from `AppAnimDurations`; no inline `Duration(milliseconds: N)` literals with unlisted values SHALL appear in widget files.
6. WHEN the window or screen width exceeds 800 logical pixels, THE App SHALL render the sidebar navigation layout (`_DesktopSidebar`, 250 px wide).
7. WHEN the window or screen width is 800 logical pixels or less, THE App SHALL render the bottom navigation bar layout with glassmorphism backdrop blur.
8. THE App SHALL support a minimum desktop window size of 800×600 logical pixels as enforced by `WindowOptions.minimumSize`.
9. WHEN the system font-scale factor exceeds 1.5, THE App SHALL not clip or overflow any text in the sidebar, bottom nav, or task cards; all text containers SHALL use `overflow: TextOverflow.ellipsis` or equivalent.
10. THE App SHALL apply `AnimatedSwitcher` with a fade + 2 % horizontal slide transition (duration `AppAnimDurations.normal`, curve `Curves.easeOutCubic`) on every top-level screen change.
11. THE App SHALL apply `AnimatedOpacity` (duration `AppAnimDurations.normal`) and `AnimatedContainer` (duration `AppAnimDurations.normal`) on task-card completion state changes.
12. WHEN a `GlassContainer` receives a tap-down event, THE App SHALL animate its scale to 0.97 within `AppAnimDurations.fast`; on tap-up it SHALL animate back to 1.0.
13. THE App SHALL support swipe-left gesture on the task list to advance to the next day, and swipe-right to go to the previous day, with a minimum velocity threshold of 300 logical pixels per second.
14. WHERE a light-mode theme is introduced (v1.2 roadmap), THE App SHALL define a parallel `AppColorsLight` token set and switch via `ThemeMode`; no widget SHALL hardcode `Brightness.dark`.
15. THE App SHALL render the `GlassContainer` backdrop blur with `sigmaX = sigmaY = 10` by default; the `blurSigma` parameter SHALL be configurable per instance.
16. THE App SHALL use `Google Fonts Inter` as the sole typeface; the `textTheme` SHALL be constructed via `GoogleFonts.interTextTheme(ThemeData.dark().textTheme)`.
17. [NEEDS CLARIFICATION] The product team must confirm whether the custom hidden title bar (`TitleBarStyle.hidden`) should expose a drag region on all desktop platforms, and whether a custom close/minimise/maximise control row is required.

---

### Requirement 3: Feature Completeness — End-to-End CRUD

**User Story:** As a product engineer, I want every user-facing feature to have a fully specified end-to-end data flow from UI interaction through business logic, persistence, and state hydration, so that no feature has silent failure paths.

#### Acceptance Criteria

##### 3A — Task CRUD

1. WHEN a user submits the `AddTaskSheet` with a non-empty title and a valid time range, THE App SHALL create a `Task` with a UUID v4 `id`, persist it via `ScheduleRepository.addTaskToDate`, update `ScheduleProvider._weekPlan` optimistically, and call `notifyListeners()`.
2. IF the `ScheduleRepository.addTaskToDate` call throws an exception, THEN THE App SHALL roll back the optimistic in-memory update, restore the previous `_weekPlan` state, and display a `SnackBar` with the message "Failed to save task. Please try again."
3. WHEN a user submits an edit in `AddTaskSheet` with `editingTask` set, THE App SHALL call `ScheduleProvider.updateTask`, persist via `ScheduleRepository.updateTask`, and re-sort the day's task list by `startTime`.
4. WHEN a user swipes a `TaskCard` from right to left past the dismiss threshold, THE App SHALL call `ScheduleProvider.deleteTask`, push an `_UndoAction` of type `deleteTask` onto `_undoStack`, show a `SnackBar` with a 4-second "UNDO" action, and persist the deletion via `ScheduleRepository.deleteTask`.
5. WHEN the user taps "UNDO" within 4 seconds of a task deletion, THE App SHALL call `ScheduleProvider.undo`, re-insert the task at its original position in the day's list, re-sort by `startTime`, and persist via `ScheduleRepository.addTask`.
6. WHEN a user long-presses a `TaskCard` and selects "Duplicate", THE App SHALL create a new `Task` with a fresh UUID v4, identical fields except `id` and `completed = false`, add it to the same day, and persist it.
7. WHEN a user taps the completion checkbox on a `TaskCard`, THE App SHALL call `ScheduleProvider.toggleTaskComplete`, update `task.completed` in memory, and persist via `ScheduleRepository.updateTask`.
8. THE App SHALL validate that `task.title` is between 1 and 200 characters before persisting; IF the title is empty or exceeds 200 characters, THEN THE App SHALL always display a visible inline validation error to the user and SHALL NOT call the repository; a missing error display SHALL be treated as a validation failure.
9. THE App SHALL validate that `task.startTime` and `task.endTime` are in `HH:mm` format and are not equal; IF validation fails, THEN THE App SHALL display an inline error and SHALL NOT call the repository.
10. THE App SHALL allow overnight tasks (e.g., `startTime = "22:00"`, `endTime = "01:00"`); the duration calculation SHALL add 24 hours when `endHour ≤ startHour`.

##### 3B — Day Plan Lifecycle

11. WHEN `ScheduleProvider._loadData()` is called, THE App SHALL call `ScheduleRepository.getUpcomingDays(7)`, which SHALL return exactly 7 `DayPlan` objects starting from today, creating missing rows in the database if necessary.
12. WHEN `ScheduleProvider.clearDay()` is called, THE App SHALL push a `clearDay` `_UndoAction` containing all current tasks, clear the in-memory list, call `ScheduleRepository.clearDay`, and show a `SnackBar` with a 4-second "UNDO" action.
13. WHEN `ScheduleProvider.saveDayPlan(dayPlan)` is called, THE App SHALL wrap the delete-then-insert sequence in a single Drift database transaction so that a partial failure leaves the database in its prior state.

##### 3C — Template CRUD

14. WHEN a user creates a new `PlanTemplate`, THE App SHALL assign a UUID v4 `id`, persist via `TemplateRepository.addTemplate`, and add it to `ScheduleProvider._templates` in memory.
15. WHEN `ScheduleProvider.applyTemplate(template)` is called, THE App SHALL copy each `TemplateTask` into a new `Task` with a fresh UUID v4, set `sourceTemplateId` to the template's `id`, add the tasks to the selected day, re-sort, and persist via `ScheduleRepository.saveDayPlan`.
16. WHEN `ScheduleProvider.setTemplateRecurring(templateId, days)` is called, THE App SHALL update `template.activeDays`, persist via `TemplateRepository.updateTemplateActiveDays`, and immediately apply the template to all matching days in the current week that do not already contain a task with `sourceTemplateId == templateId`.
17. WHEN `TemplateRepository.deleteTemplate(id)` is called, THE App SHALL delete all associated `TemplateTask` rows before deleting the `PlanTemplate` row, within a single Drift transaction.
18. THE App SHALL fix the N+1 query in `LocalTemplateRepository.getAllTemplates()` by replacing the per-template task fetch loop with a single JOIN query or a batched `WHERE templateId IN (...)` query.

##### 3D — Todo CRUD

19. WHEN a user saves a new `TodoItem` in `TodoDetailScreen`, THE App SHALL call `TodoProvider.addTodo`, persist via `TodoRepository.addTodo`, and the reactive `watchTodos()` stream SHALL automatically update the `TodoListView` grid.
20. WHEN a user deletes a `TodoItem` and confirms the dialog, THE App SHALL call `TodoProvider.deleteTodo`, persist via `TodoRepository.deleteTodo`, and the stream SHALL remove the item from the grid within one frame.
21. THE App SHALL validate that `TodoItem.title` is between 1 and 200 characters before persisting; IF the title is empty, THEN THE App SHALL display a `SnackBar` with "Title cannot be empty" and SHALL NOT call the repository.

---

### Requirement 4: Data Modelling and Infrastructure

**User Story:** As a data engineer, I want all domain models, database schemas, and serialisation contracts to be precisely defined and migration-safe, so that schema upgrades never corrupt user data.

#### Acceptance Criteria

1. THE App SHALL represent all domain entities as immutable Dart classes with `copyWith`, `toJson`, and `fromJson` methods; no public mutable field SHALL exist on `Task`, `DayPlan`, `PlanTemplate`, or `TodoItem`.
2. THE App SHALL store `Task.type`, `Task.priority`, and `Task.energyLevel` as their enum `.name` string in SQLite; `fromJson` and DAO mappers SHALL use `firstWhere((e) => e.name == raw, orElse: () => defaultValue)` to guard against unknown values.
3. THE App SHALL replace the `activeDays` comma-separated string column in `PlanTemplates` with a `TemplateActiveDays` junction table (`templateId TEXT, dayIndex INTEGER, PRIMARY KEY (templateId, dayIndex)`) in schema version 5, with a migration that parses existing comma-separated values and inserts rows.
4. THE App SHALL add `FOREIGN KEY (dayPlanId) REFERENCES day_plans(id) ON DELETE CASCADE` to the `Tasks` table in schema version 5, replacing the current manual cleanup pattern.
5. THE App SHALL add `FOREIGN KEY (templateId) REFERENCES plan_templates(id) ON DELETE CASCADE` to the `TemplateTasks` table in schema version 5.
6. WHEN the database schema version is incremented, THE App SHALL provide a `MigrationStrategy` in `AppDatabase` that handles every version step from 1 to N; no migration step SHALL be skipped.
7. THE App SHALL store the SQLite database file at the path returned by `getApplicationDocumentsDirectory()` joined with `chronos_planner.sqlite`; this path SHALL NOT be hardcoded.
8. THE App SHALL use `NativeDatabase.createInBackground` so that all Drift queries execute on a background isolate and do not block the UI thread.
9. THE App SHALL remove `shared_preferences` from `pubspec.yaml` dependencies after confirming the one-time migration flag has been set in all production installs; `MigrationHelper` SHALL be retained but marked `@visibleForTesting`.
10. THE App SHALL define a `TaskDto` and `TodoItemDto` for any future JSON export/import feature (v1.1 roadmap); these DTOs SHALL be separate from the domain models and SHALL include a `schemaVersion` field.
11. THE App SHALL cap `Task.title` at 200 characters and `PlanTemplate.name` at 100 characters at the model layer via assertion or validation, not only at the UI layer.
12. THE App SHALL store `DayPlan.date` as a `DateTime` column (Drift `dateTime()`) and derive `dateStr` and `dayOfWeek` at read time using `intl`; these derived fields SHALL NOT be stored in the database.
13. [NEEDS CLARIFICATION] The product team must confirm whether `Task.actualCost` should be editable by the user in the current UI or only populated by a future time-tracking feature (v1.3 roadmap).


---

### Requirement 5: Component Communication and Reusability

**User Story:** As a widget engineer, I want every reusable widget to have a documented contract (props, callbacks, invariants) and a clear communication pattern, so that widgets can be composed without hidden side effects.

#### Acceptance Criteria

1. THE App SHALL define every reusable widget's public API using named parameters with explicit types; no widget SHALL accept `dynamic` or `Object` parameters.
2. THE App SHALL document each reusable widget (`TaskCard`, `GlassContainer`, `AddTaskSheet`, `FocusHUD`, `WorkPlanDetailDialog`) with a Dart doc comment listing all parameters, their types, whether they are required or optional, and their default values.
3. WHEN `TaskCard` receives an `onDelete` callback, THE App SHALL invoke it only after the `Dismissible` widget confirms the dismiss direction is `DismissDirection.endToStart`; the callback SHALL NOT be invoked for other directions.
4. THE App SHALL pass `onEdit` and `onDuplicate` as nullable callbacks to `TaskCard`; WHEN they are null, THE App SHALL omit the corresponding items from the long-press context menu.
5. THE App SHALL use `Consumer<ScheduleProvider>` or `Selector<ScheduleProvider, T>` in every widget that reads provider state, so that only the widgets that depend on changed data rebuild; broad `Provider.of<ScheduleProvider>(context)` calls in `build()` methods SHALL be replaced.
6. THE App SHALL use `Provider.of<T>(context, listen: false)` exclusively for write-only access (calling methods) inside callbacks and `initState`; it SHALL NOT be used in `build()` methods.
7. WHEN `AddTaskSheet` is opened in edit mode (`editingTask != null`), THE App SHALL pre-populate all form fields from `editingTask` and call `onUpdate` on submit; `onAdd` SHALL NOT be called in edit mode.
8. THE App SHALL extract the day-selector row in `ScheduleView` into a standalone `DaySelectorWidget` that accepts `List<DayPlan> days`, `int selectedIndex`, and `ValueChanged<int> onDaySelected` as its complete public API.
9. THE App SHALL extract the analytics metric cards in `AnalyticsView` into standalone `MetricCard` widgets that accept only primitive data (no provider access inside the widget).
10. WHERE a widget requires access to two or more providers, THE App SHALL use `MultiProvider` or nested `Consumer` widgets rather than calling `Provider.of` multiple times in the same `build()` method.
11. THE App SHALL generate Drift table companions and query classes via `build_runner`; generated files (`*.g.dart`) SHALL be committed to version control and regenerated as part of the CI pipeline.

---

### Requirement 6: OOP and Best Practices

**User Story:** As a senior engineer, I want the codebase to enforce SOLID principles, null safety, and strict linting, so that the code is maintainable, predictable, and free of common Dart anti-patterns.

#### Acceptance Criteria

1. THE App SHALL enable Dart sound null safety (`sdk: '>=3.0.0 <4.0.0'`); no `!` null-assertion operator SHALL appear without an inline comment explaining why the value is guaranteed non-null.
2. THE App SHALL upgrade `analysis_options.yaml` to include `package:flutter_lints/flutter.yaml` plus the following additional rules: `avoid_dynamic_calls`, `avoid_print`, `prefer_const_constructors`, `prefer_final_fields`, `prefer_single_quotes`, `require_trailing_commas`, `unawaited_futures`, `unnecessary_await_in_return`.
3. THE App SHALL treat all linter warnings as errors in CI (`--fatal-warnings` flag on `flutter analyze`); no warning SHALL be suppressed with `// ignore:` without a comment explaining the exception.
4. THE App SHALL follow the Single Responsibility Principle: each class SHALL have one reason to change; `ScheduleProvider` SHALL be split into `ScheduleStateProvider` (CRUD + undo) and `AnalyticsProvider` (computed metrics) if the class exceeds 400 lines.
5. THE App SHALL follow the Open/Closed Principle for `IntelligenceService`: new recommendation algorithms SHALL be added by implementing a `RecommendationStrategy` interface, not by modifying existing methods.
6. THE App SHALL follow the Liskov Substitution Principle: every `LocalXxxRepository` SHALL be substitutable for its abstract `XxxRepository` interface without altering the correctness of `ScheduleProvider` or `TodoProvider`.
7. THE App SHALL follow the Interface Segregation Principle: repository interfaces SHALL NOT expose methods that their consumers do not use; if `ScheduleProvider` never calls `PreferenceRepository.getAll()`, that method SHALL be moved to a separate `BulkPreferenceRepository` interface.
8. THE App SHALL follow the Dependency Inversion Principle: `ScheduleProvider` SHALL depend on `ScheduleRepository` (abstract), not on `LocalScheduleRepository` (concrete).
9. THE App SHALL make all domain model classes (`Task`, `DayPlan`, `PlanTemplate`, `TodoItem`) `@immutable`; the `tasks` list on `DayPlan` SHALL be `List<Task>` returned as an unmodifiable view.
10. THE App SHALL replace all `catch (e) {}` empty catch blocks with explicit error handling; every caught exception SHALL be either rethrown, logged, or surfaced to the UI.
11. THE App SHALL not use `print()` in production code; all diagnostic output SHALL use a structured logger (see Requirement 14).
12. THE App SHALL remove `file_picker` and `just_audio` from `pubspec.yaml` only when they are confirmed unused in `lib/`; selective removal is permitted — a package SHALL be retained if its corresponding feature is already implemented and SHALL be removed if its feature is not yet implemented.

---

### Requirement 7: Testing Robustness

**User Story:** As a QA engineer, I want a comprehensive test suite covering unit, widget, integration, golden, and property-based tests, so that regressions are caught before they reach users.

#### Acceptance Criteria

1. THE App SHALL achieve a minimum of 70 % line coverage on all files under `lib/data/` and `lib/providers/` as measured by `flutter test --coverage`.
2. THE App SHALL achieve a minimum of 20 % line coverage on all files under `lib/ui/` via widget tests.
3. THE App SHALL achieve end-to-end integration test coverage for the following critical paths: task creation → persistence → display; template apply → day update; todo creation → stream update → grid display.
4. WHEN `ScheduleProvider.addTask` is called with a valid `Task`, THE Unit_Test SHALL verify that `_weekPlan` contains the task, `notifyListeners` was called, and `ScheduleRepository.addTaskToDate` was invoked with the correct arguments.
5. WHEN `ScheduleProvider.addTask` is called and the repository throws, THE Unit_Test SHALL verify that `_weekPlan` does NOT contain the task after rollback and that a `SnackBar` error is triggered.
6. FOR ALL valid `Task` objects generated by a property-based test, THE PBT SHALL verify that `task.toJson()` followed by `Task.fromJson()` produces an object equal to the original (round-trip property).
7. FOR ALL valid `PlanTemplate` objects generated by a property-based test, THE PBT SHALL verify that serialising and deserialising `activeDays` produces the same integer list (round-trip property).
8. THE App SHALL include golden tests for `TaskCard` in its four `TaskType` states (work, personal, health, leisure) and in completed vs. active states, stored under `test/goldens/`.
9. THE App SHALL include golden tests for `GlassContainer` with and without gradient border, and with `blurSigma` at 5, 10, and 20.
10. THE App SHALL include a widget test verifying that `AddTaskSheet` displays an inline error when submitted with an empty title.
11. THE App SHALL include a widget test verifying that `AddTaskSheet` displays an inline error when `startTime == endTime`.
12. THE App SHALL include a widget test verifying that the `Dismissible` in `TaskCard` calls `onDelete` when swiped end-to-start.
13. THE App SHALL include a widget test verifying that the long-press context menu on `TaskCard` shows "Edit", "Duplicate", and "Delete" items when all callbacks are provided.
14. THE App SHALL include a widget test verifying that the long-press context menu on `TaskCard` omits "Edit" and "Duplicate" when those callbacks are null.
15. THE App SHALL include an integration test verifying that `ScheduleProvider.undo()` restores a deleted task within the 4-second window.
16. THE App SHALL include a performance test verifying that rendering a `ScheduleView` with 50 tasks completes within 16 ms per frame (no jank) on a reference device.
17. THE App SHALL configure `flutter_test` with a `MockScheduleRepository`, `MockTemplateRepository`, `MockPreferenceRepository`, and `MockTodoRepository` using the `mockito` or `mocktail` package.
18. THE App SHALL run all tests in CI on every pull request; a failing test SHALL block the merge.

---

### Requirement 8: Performance and Efficiency

**User Story:** As a performance engineer, I want the app to maintain 60 fps on desktop and avoid unnecessary widget rebuilds, memory leaks, and slow startup, so that the user experience is smooth on all supported platforms.

#### Acceptance Criteria

1. THE App SHALL achieve a cold-start time (from process launch to first interactive frame) of ≤ 2 seconds on a reference desktop machine (Intel Core i5, 8 GB RAM, SSD).
2. THE App SHALL use `Selector<ScheduleProvider, T>` or `Consumer` with a `child` parameter for all widgets that depend on a single computed value from `ScheduleProvider`, so that a change to `selectedDayIndex` does not rebuild the analytics section.
3. THE App SHALL use `const` constructors on all stateless widgets and on all widget subtrees that do not depend on runtime data.
4. THE App SHALL use `ListView.builder` (or `SliverList` with a delegate) for all lists that may contain more than 10 items; no `Column(children: tasks.map(...).toList())` pattern SHALL be used for task lists.
5. THE App SHALL use `GridView.builder` for `TodoListView`; no `GridView.count` with a pre-built children list SHALL be used.
6. THE App SHALL limit `BackdropFilter` (blur) usage to at most 3 simultaneously visible instances per screen; excessive blur layers SHALL be replaced with opaque semi-transparent containers on low-end devices detected via `MediaQuery.platformBrightness` or a capability flag.
7. THE App SHALL cancel the `StreamSubscription` in `TodoProvider.dispose()` to prevent memory leaks; this SHALL be verified by a unit test that calls `dispose()` and asserts the subscription is cancelled.
8. THE App SHALL not perform synchronous database reads on the UI isolate; all Drift queries SHALL be `async` and awaited.
9. THE App SHALL offload `IntelligenceService.getEnergyPeaks()` to a background `Isolate` when the task history list contains more than 500 items (i.e., 501 or more), using `compute()` or `Isolate.run()`.
10. THE App SHALL limit `_undoStack` to a maximum of 50 entries; when the limit is reached, the oldest entry SHALL be discarded.
11. THE App SHALL use `RepaintBoundary` around `_DonutChartPainter` and the energy-peaks bar chart to isolate their repaint from the rest of the analytics screen.
12. THE App SHALL not call `notifyListeners()` more than once per logical state mutation; methods that perform multiple mutations SHALL batch them and call `notifyListeners()` once at the end.
13. WHEN the app is backgrounded on desktop (window minimised), THE App SHALL pause non-critical background work and resume it when the window is restored, using `WidgetsBindingObserver.didChangeAppLifecycleState`.


---

### Requirement 9: Security Standards

**User Story:** As a security engineer, I want all user data to be stored securely, all inputs to be validated, and the release build to be obfuscated, so that the app meets baseline security standards for a productivity tool handling personal schedule data.

#### Acceptance Criteria

1. THE App SHALL store the SQLite database file in the platform's application documents directory (returned by `getApplicationDocumentsDirectory()`), which is sandboxed and not accessible to other apps on Android and iOS.
2. THE App SHALL NOT store any sensitive user data (task titles, descriptions, costs) in `shared_preferences`, system logs, or crash-report payloads in plain text.
3. WHERE a cloud-sync feature is introduced (v1.3 roadmap), THE App SHALL use HTTPS (TLS 1.2 minimum) for all network requests and SHALL validate the server certificate chain; self-signed certificates SHALL NOT be accepted in production builds.
4. THE App SHALL sanitise all user-supplied text inputs before persisting them; inputs SHALL be trimmed of leading/trailing whitespace and SHALL not exceed the defined character limits (title: 200, template name: 100).
5. THE App SHALL use parameterised Drift queries for all database operations; no raw SQL string interpolation with user-supplied values SHALL appear in any DAO.
6. THE App SHALL enable Dart code obfuscation (`--obfuscate --split-debug-info=<dir>`) for all release builds on Android and iOS; the split debug info SHALL be stored securely for crash symbolication.
7. THE App SHALL not include any API keys, tokens, or secrets in the Dart source code or `pubspec.yaml`; secrets required for future integrations SHALL be injected via environment variables at build time using `--dart-define`.
8. THE App SHALL validate that `Task.estimatedCost` and `Task.actualCost` are non-negative finite doubles before persisting; IF a negative, NaN, infinite, or empty cost value is submitted, THEN THE App SHALL always display a visible inline validation error to the user and SHALL NOT persist the value.
9. THE App SHALL not request any OS permissions (camera, microphone, contacts, location) that are not required by the current feature set; permission requests SHALL be added only when the corresponding feature is implemented.
10. THE App SHALL configure `android/app/src/main/AndroidManifest.xml` with `android:allowBackup="false"` until a secure encrypted backup strategy is defined.
11. [NEEDS CLARIFICATION] The product team must confirm whether the SQLite database should be encrypted using SQLCipher (`drift_sqflite` with encryption) for v1.0, or whether OS-level sandboxing is considered sufficient.

---

### Requirement 10: Async Logic and Error Resilience

**User Story:** As a reliability engineer, I want all asynchronous operations to have explicit error handling, retry logic where appropriate, and no race conditions, so that the app never silently corrupts state or leaves the UI in an inconsistent state.

#### Acceptance Criteria

1. THE App SHALL wrap every `async` repository call in `ScheduleProvider` and `TodoProvider` with a `try/catch` block; both the `try/catch` wrapping AND the UI error surfacing MUST be implemented together — caught exceptions SHALL be stored in a provider-level `String? errorMessage` field and surfaced to the UI via a `SnackBar` or error banner.
2. THE App SHALL define a `Result<T>` sealed class (or use `Either<Failure, T>`) as the return type for all repository methods, so that callers are forced to handle both success and failure paths.
3. WHEN a Drift database write fails due to a constraint violation, THE App SHALL catch the `DriftWrappedException`, log the error with context (operation name, entity id), and surface a user-friendly message.
4. THE App SHALL implement an exponential-backoff retry (max 3 attempts, initial delay 200 ms, multiplier 2×) for any repository operation that fails with a transient I/O error (`FileSystemException`).
5. THE App SHALL use `unawaited_futures` lint rule to detect fire-and-forget `Future` calls; every `Future` returned by a repository method SHALL be either `await`ed or explicitly handled with `.catchError()`.
6. THE App SHALL guard against race conditions in `ScheduleProvider._loadData()` by setting a `_isLoading` flag before the first `await` and clearing it in a `finally` block; concurrent calls SHALL be debounced using a `Completer` or a loading guard.
7. WHEN `TodoProvider._subscription` emits an error event, THE App SHALL log the error and attempt to re-subscribe after a 1-second delay, up to 3 times.
8. THE App SHALL implement a global `FlutterError.onError` handler in `main()` that logs unhandled Flutter framework errors to the structured logger (see Requirement 14) and, in release builds, to the crash-reporting service.
9. THE App SHALL implement a `PlatformDispatcher.instance.onError` handler in `main()` that catches unhandled Dart isolate errors and logs them before allowing the app to continue or restart.
10. THE App SHALL not use `Future.delayed` as a synchronisation mechanism; all timing-dependent logic SHALL use `StreamController`, `Completer`, or `Timer` with explicit cancellation.
11. WHEN `ScheduleProvider.undo()` is called and the undo stack is empty, THE App SHALL log a warning and return without modifying state; it SHALL NOT throw an exception. These constraints (log warning, no state change, no exception) apply only when `undo()` is called with an empty stack.
12. THE App SHALL dispose all `TextEditingController`, `AnimationController`, and `ScrollController` instances in the `dispose()` method of their owning `State`; this SHALL be verified by a widget test that mounts and unmounts the widget.

---

### Requirement 11: Platform Channels and Native Interoperability

**User Story:** As a platform engineer, I want all native platform integrations to use typed, versioned channel contracts, so that platform-specific code is isolated, testable, and upgradeable independently of the Dart layer.

#### Acceptance Criteria

1. THE App SHALL use `window_manager` ^0.5.1 exclusively for all desktop window operations (resize, reposition, always-on-top); no direct `MethodChannel` calls to window APIs SHALL be made outside of the `window_manager` abstraction.
2. WHEN Focus Mode is activated on a desktop platform, THE App SHALL call `windowManager.setAlwaysOnTop(true)`, `windowManager.setSize(const Size(320, 200))`, and `windowManager.setAlignment(Alignment.topRight)` in that order; each call SHALL be `await`ed.
3. WHEN Focus Mode is deactivated, THE App SHALL handle the platform restriction internally: window operations (`windowManager.setAlwaysOnTop(false)`, `windowManager.setSize(const Size(1200, 800))`, `windowManager.center()`) SHALL only execute on desktop platforms (Windows, macOS, Linux) and SHALL be silently skipped on Android and iOS; each call SHALL be `await`ed.
4. THE App SHALL guard all `window_manager` calls with `if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)` checks; these calls SHALL NOT be made on Android or iOS.
5. WHERE a notification feature is introduced (v1.1 roadmap), THE App SHALL use a `MethodChannel` named `com.chronosky.notifications/channel` with a versioned message schema (`{"version": 1, "action": "schedule", ...}`); the channel contract SHALL be documented in `docs/platform/notifications_channel.md`.
6. WHERE a `MethodChannel` or `EventChannel` is introduced, THE App SHALL define a Dart wrapper class that encodes/decodes the message map and throws typed exceptions for unknown responses; raw `Map<String, dynamic>` SHALL NOT be used directly in business logic.
7. THE App SHALL handle `MissingPluginException` from any platform channel by catching it, logging a warning, and degrading gracefully (e.g., disabling the Focus Mode button on unsupported platforms).
8. WHERE Dart FFI is used for native library calls (e.g., SQLCipher), THE App SHALL define all FFI bindings in a dedicated `lib/native/` directory and wrap them in a Dart class with a documented API.
9. THE App SHALL implement `WindowListener` from `window_manager` to detect window close events on desktop and call `ScheduleProvider.dispose()` to flush any pending state before the process exits.
10. [NEEDS CLARIFICATION] The product team must confirm whether a system-tray icon (via `tray_manager` or equivalent) is required for the Focus Mode desktop experience in v1.1.

---

### Requirement 12: Accessibility and Inclusivity

**User Story:** As an accessibility engineer, I want every interactive element to have correct semantic labels, keyboard focus support, and sufficient colour contrast, so that the app is usable by people with visual, motor, or cognitive disabilities.

#### Acceptance Criteria

1. THE App SHALL wrap every interactive widget (`TaskCard`, `GlassContainer` with `onTap`, day-selector chips, navigation items) with a `Semantics` widget providing a `label` that describes the action (e.g., "Task: Deep Work, 09:00 to 12:00, Work category, not completed").
2. THE App SHALL set `Semantics.button = true` on all tappable containers that are not `ElevatedButton` or `TextButton` widgets.
3. THE App SHALL set `Semantics.checked` on task completion checkboxes and todo completion toggles, reflecting the current `completed` state.
4. THE App SHALL ensure all text/background colour pairs in `AppColors` meet WCAG 2.1 AA contrast ratio (≥ 4.5:1 for normal text, ≥ 3:1 for large text ≥ 18 pt or bold ≥ 14 pt); a contrast audit SHALL be documented in `docs/accessibility/contrast_audit.md`.
5. THE App SHALL support keyboard navigation on desktop: Tab SHALL move focus between interactive elements in logical reading order; Enter/Space SHALL activate the focused element.
6. THE App SHALL set `FocusTraversalGroup` on the sidebar navigation and the main content area so that Tab does not cycle between them unexpectedly.
7. THE App SHALL provide `Tooltip` widgets on all icon-only buttons (sort toggle, undo, clear day, save template, focus mode) with descriptive text.
8. WHEN `MediaQuery.disableAnimations` is `true`, THE App SHALL skip all non-essential animations (stagger delays, chart bar animations, screen transitions) and render the final state immediately; essential state-communicating animations (loading spinners, progress indicators) SHALL be preserved even when motion is disabled. THE App SHALL also provide an in-app animation-preference toggle (persisted via `PreferenceRepository` under key `reduce_motion`) that, when enabled, applies the same reduced-motion behaviour regardless of the system setting.
9. THE App SHALL set a minimum tap target size of 48×48 logical pixels for all interactive elements, as required by Material Design and WCAG 2.5.5.
10. THE App SHALL not convey information through colour alone; task type SHALL be indicated by both colour and an icon or text label.
11. THE App SHALL set `excludeSemantics: true` on purely decorative elements (gradient borders, glow shadows, background blur layers).
12. [NEEDS CLARIFICATION] The product team must confirm whether screen-reader support (TalkBack on Android, VoiceOver on iOS/macOS, Narrator on Windows) is a v1.0 requirement or a v1.2 roadmap item.


---

### Requirement 13: Internationalisation and Localisation

**User Story:** As a product manager, I want the app to be architected for multi-language support from the start, so that adding a new locale in v1.2 does not require touching widget code.

#### Acceptance Criteria

1. THE App SHALL add `flutter_localizations` and `intl` to `pubspec.yaml` and configure `MaterialApp.localizationsDelegates` with `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, and `GlobalCupertinoLocalizations.delegate`.
2. THE App SHALL define all user-visible strings in ARB files under `lib/l10n/`; the base locale SHALL be `app_en.arb`; no user-facing string literal SHALL appear directly in widget `build()` methods; non-user-facing string literals (debug labels, widget keys, semantic identifiers) are permitted inline. Widgets MUST both define strings in ARB files AND access them via `AppLocalizations.of(context)!.stringKey` — both parts are required.
3. THE App SHALL generate a `AppLocalizations` class via `flutter gen-l10n`; all widgets SHALL access strings via `AppLocalizations.of(context)!.stringKey`.
4. THE App SHALL format all displayed dates using `intl.DateFormat` with the current locale; no hardcoded `"Feb 10"` or `"Monday"` string formatting SHALL remain in the codebase after i18n is implemented.
5. THE App SHALL format all displayed times using `intl.DateFormat.Hm()` (24-hour) or `DateFormat.jm()` (12-hour) based on the device locale; the `HH:mm` internal storage format SHALL remain locale-independent.
6. THE App SHALL format all displayed currency values using `intl.NumberFormat.currency(locale: locale, symbol: symbol)`; the `estimatedCost` and `actualCost` fields SHALL remain stored as raw `double` values.
7. THE App SHALL support right-to-left (RTL) layouts by using `Directionality`-aware widgets (`EdgeInsetsDirectional`, `AlignmentDirectional`) instead of `EdgeInsets.only(left: ...)` or `Alignment.centerLeft`.
8. THE App SHALL include a locale switcher in the preferences screen (v1.2 roadmap); the selected locale SHALL be persisted via `PreferenceRepository` under the key `app_locale`.
9. THE App SHALL include at least two locales in the initial i18n implementation: `en` (English) and one additional locale chosen by the product team; [NEEDS CLARIFICATION] the product team must confirm the second locale.
10. THE App SHALL not use `Platform.localeName` directly for formatting; all locale-sensitive formatting SHALL go through the `intl` package using the locale resolved by `MaterialApp`.

---

### Requirement 14: Analytics, Logging, and Observability

**User Story:** As a DevOps engineer, I want structured logs, in-app analytics events, and performance traces, so that I can diagnose production issues and measure feature adoption without accessing user devices.

#### Acceptance Criteria

1. THE App SHALL introduce a `Logger` abstraction (`lib/core/services/logger.dart`) with methods `debug`, `info`, `warning`, `error(message, {Object? exception, StackTrace? stackTrace})`; all log calls in the codebase SHALL use this abstraction.
2. THE App SHALL implement a `ConsoleLogger` (debug builds) and a `NoOpLogger` (release builds by default) as concrete implementations of the `Logger` interface; the active implementation SHALL be injected in `main.dart`.
3. WHERE a crash-reporting service is integrated (e.g., Sentry, Firebase Crashlytics), THE App SHALL implement a `CrashReportingLogger` that forwards `error`-level events to the service; this SHALL be the release-build implementation.
4. THE App SHALL log the following lifecycle events at `info` level: app start, database initialisation complete, migration complete, provider load complete, Focus Mode enter/exit.
5. THE App SHALL log the following user-action events at `debug` level: task created (with `taskId`, `type`, `priority`), task deleted, task completed, template applied, undo triggered.
6. THE App SHALL log the following error events at `error` level with full stack trace: repository write failure, database migration failure, stream subscription error, unhandled Flutter framework error.
7. THE App SHALL NOT include any personally identifiable information (PII) in log payloads; task titles, descriptions, and cost values SHALL be replaced with `[REDACTED]` in all log messages.
8. THE App SHALL instrument the following operations with performance traces (using `dart:developer` `Timeline` API or a future APM integration): `ScheduleProvider._loadData()`, `LocalTemplateRepository.getAllTemplates()`, `IntelligenceService.getEnergyPeaks()`.
9. THE App SHALL expose a `DebugOverlay` widget (visible only in debug builds, toggled by a keyboard shortcut `Ctrl+Shift+D`) that displays the last 50 log entries, current provider state summary, and database row counts.
10. THE App SHALL track the following product analytics events (anonymised, opt-in, v1.2 roadmap): `feature_used` (feature name), `task_created` (type, priority — no title), `template_applied`, `focus_mode_entered`; WHEN a user has not opted in to analytics, THE App SHALL skip all analytics validation and event tracking entirely; [NEEDS CLARIFICATION] the product team must confirm the analytics provider (Firebase Analytics, Mixpanel, or self-hosted).

---

### Requirement 15: CI/CD and DevOps

**User Story:** As a DevOps engineer, I want a fully automated CI/CD pipeline that enforces quality gates, builds release artefacts for all target platforms, and deploys them to distribution channels, so that every merged commit is releasable.

#### Acceptance Criteria

1. THE App SHALL have a CI pipeline (GitHub Actions or equivalent) that triggers on every pull request to `main` and runs the following stages in order: `lint` → `test` → `build`.
2. THE `lint` stage SHALL run `flutter analyze --fatal-warnings` and fail the pipeline if any warning or error is reported.
3. THE `test` stage SHALL run `flutter test --coverage` and fail the pipeline if line coverage on `lib/data/` or `lib/providers/` drops below 70 %.
4. THE `build` stage SHALL produce the following artefacts: Windows MSIX installer, Linux AppImage, macOS DMG, Android APK (debug), Android AAB (release), iOS IPA (release); the build stage SHALL pass if and only if all required artefacts are successfully generated and archived; failure to produce any single artefact SHALL fail the entire build stage.
5. THE CI pipeline SHALL cache the Flutter SDK, pub cache, and Gradle cache between runs to achieve a total pipeline duration of ≤ 10 minutes on a standard CI runner.
6. THE CI pipeline SHALL run `dart pub outdated --mode=null-safety` and post a comment on the pull request listing any packages with available updates; it SHALL NOT fail the build for outdated packages.
7. THE CI pipeline SHALL run `flutter pub audit` (or `dart pub audit` equivalent) and fail the build if any dependency has a known critical or high-severity vulnerability.
8. THE App SHALL use semantic versioning (`MAJOR.MINOR.PATCH+BUILD`) in `pubspec.yaml`; the `BUILD` number SHALL be auto-incremented by the CI pipeline using the CI run number.
9. THE App SHALL maintain a `CHANGELOG.md` following the Keep a Changelog format; the CI pipeline SHALL verify that the changelog has been updated on every pull request that modifies `lib/`.
10. THE App SHALL have a release pipeline that triggers on a `v*.*.*` git tag and publishes the Windows MSIX to the Microsoft Store staging environment, the Android AAB to the Google Play internal track, and the macOS DMG to a GitHub Release; [NEEDS CLARIFICATION] the product team must confirm Apple Developer account availability for iOS/macOS notarisation.
11. THE App SHALL include a `Makefile` or `scripts/` directory with the following commands: `make lint`, `make test`, `make build-windows`, `make build-linux`, `make build-macos`, `make build-android`, `make build-ios`; each command SHALL be documented in `docs/devops/build_guide.md`.
12. THE App SHALL use branch protection rules on `main`: direct pushes SHALL be blocked; all merges SHALL require at least one approved review and a passing CI pipeline.

---

### Requirement 16: Dependency Hygiene

**User Story:** As a security and maintenance engineer, I want all dependencies to be pinned to exact or tightly bounded versions, audited for vulnerabilities, and free of unused packages, so that the supply chain is predictable and secure.

#### Acceptance Criteria

1. THE App SHALL pin all production dependencies in `pubspec.yaml` to a minimum version with a caret constraint (`^`) that prevents breaking changes; no open-ended version ranges (e.g., `>=2.0.0`) SHALL be used without an explicit comment.
2. THE App SHALL remove `shared_preferences` from `pubspec.yaml` once the one-time migration is confirmed complete in all production installs; the removal SHALL be tracked as a technical-debt ticket.
3. THE App SHALL remove `file_picker` and `just_audio` from `pubspec.yaml` selectively: each package SHALL be removed only when its corresponding feature is not yet implemented; a package SHALL be retained if its feature is already implemented; their re-addition SHALL be part of the respective feature branch.
4. THE App SHALL upgrade `drift` to the latest stable patch release within the `^2.x` range and lock it in `pubspec.lock`; `pubspec.lock` SHALL be committed to version control.
5. THE App SHALL upgrade `provider` to the latest stable patch release within the `^6.1.x` range; the upgrade SHALL be tested against all existing widget tests before merging.
6. THE App SHALL run `flutter pub audit` in CI (see Requirement 15.7) and block merges if any dependency has a CVE with CVSS score ≥ 7.0.
7. THE App SHALL document the rationale for every direct dependency in `docs/dependencies.md`, listing: package name, version constraint, purpose, and the date it was last reviewed.
8. THE App SHALL not introduce any new dependency without a corresponding entry in `docs/dependencies.md` and a review comment in the pull request explaining why an existing package could not satisfy the requirement.
9. THE App SHALL upgrade `flutter_lints` to `^6.0.0` (already at this version) and review the new lint rules introduced in each minor version; any newly enabled rule that causes warnings SHALL be addressed within one sprint.
10. THE App SHALL use `dart pub upgrade --major-versions` at most once per quarter, in a dedicated dependency-upgrade branch, with a full test run before merging.
11. THE App SHALL verify that `sqlite3_flutter_libs` is compatible with the locked `drift` version after every `drift` upgrade; if `sqlite3_flutter_libs` is incompatible, all `drift` upgrades SHALL be blocked until `sqlite3_flutter_libs` releases a compatible version, even if this results in an extended delay.
12. THE App SHALL not use `dependency_overrides` in `pubspec.yaml` except as a temporary workaround; any active override SHALL have a linked issue tracking its removal.


---

## Correctness Properties

The following properties are derived from the acceptance criteria above and are suitable for property-based testing (PBT) using the `test` package with a PBT library such as `fast_check` or a custom generator. Each property is classified by type.

### P1 — Task JSON Round-Trip (Round-Trip Property)

**Source:** Requirement 7.6

For all valid `Task` objects (all combinations of `TaskType`, `TaskPriority`, `TaskEnergyLevel`, non-empty title ≤ 200 chars, valid `HH:mm` times, non-negative costs):

```
Task.fromJson(task.toJson()) == task
```

This property catches any serialisation bug in `toJson`/`fromJson`, including enum name mismatches and default-value clobbering.

### P2 — PlanTemplate Active Days Round-Trip (Round-Trip Property)

**Source:** Requirement 7.7

For all `List<int>` values where each element is in `[0, 6]` and the list has 0–7 elements:

```
_parseActiveDays(_encodeDays(days)) == days.toSet().toList()..sort()
```

This property catches encoding bugs in the comma-separated `activeDays` string (and, after Requirement 4.3, in the junction-table mapper).

### P3 — Task Duration Non-Negative (Invariant)

**Source:** Requirement 3A.10

For all `Task` objects with valid `startTime` and `endTime`:

```
_calculateDuration(task.startTime, task.endTime) >= 0.0
_calculateDuration(task.startTime, task.endTime) <= 24.0
```

This property catches the overnight-task edge case where `endHour < startHour`.

### P4 — Efficiency Score Bounded (Invariant)

**Source:** Requirement 3 (analytics)

For all `List<Task>` inputs to `IntelligenceService.calculateEfficiency`:

```
0.0 <= calculateEfficiency(tasks) <= 100.0
```

This property catches division-by-zero and percentage-overflow bugs.

### P5 — Energy Peaks Map Completeness (Invariant)

**Source:** Requirement 3 (analytics)

For all non-empty `List<Task>` inputs to `IntelligenceService.getEnergyPeaks`:

```
getEnergyPeaks(tasks).keys.every((h) => h >= 0 && h <= 23)
getEnergyPeaks(tasks).values.every((r) => r >= 0.0 && r <= 1.0)
```

### P6 — Sort Idempotence (Idempotence)

**Source:** Requirement 3A (sort)

For all `DayPlan` objects and both `SortOrder` values:

```
getSortedTasks(getSortedTasks(dayPlan, order), order) == getSortedTasks(dayPlan, order)
```

Sorting an already-sorted list produces the same result.

### P7 — Undo Restores State (Round-Trip / Inverse)

**Source:** Requirement 3A.5

For any `Task` added to a `DayPlan` and then deleted:

```
deleteTask(taskId) followed by undo() results in weekPlan containing the original task
```

This is a non-strict inverse: the task is restored but may be at a different list index (re-sorted by time).

### P8 — Template Apply Preserves Task Count (Metamorphic)

**Source:** Requirement 3C.15

For any `PlanTemplate` with N tasks applied to a `DayPlan` with M tasks (no prior `sourceTemplateId` overlap):

```
dayPlan.tasks.length == M + N after applyTemplate(template)
```

### P9 — Week Key Determinism (Invariant)

**Source:** Requirement 4.7 (implicit)

For any `DateTime` value:

```
_calculateWeekKey(date) == _calculateWeekKey(date)  // same input → same output
_calculateWeekKey(date).matches(RegExp(r'^\d{4}-W\d{2}$'))
```

### P10 — Preference Round-Trip (Round-Trip Property)

**Source:** Requirement 3 (preferences)

For all non-empty string keys and values:

```
await prefRepo.set(key, value)
await prefRepo.get(key) == value
```

---

## Open Clarification Items Summary

The following items are marked `[NEEDS CLARIFICATION]` throughout this document and require product-team decisions before the corresponding requirements can be finalised:

| # | Section | Question |
|---|---------|----------|
| C1 | Req 2.17 | Is a custom drag region and close/minimise/maximise control row required for the hidden title bar on all desktop platforms? |
| C2 | Req 4.13 | Should `Task.actualCost` be user-editable in the current UI, or reserved for the v1.3 time-tracking feature? |
| C3 | Req 9.11 | Should the SQLite database be encrypted with SQLCipher, or is OS-level sandboxing sufficient for v1.0? |
| C4 | Req 11.10 | Is a system-tray icon required for the Focus Mode desktop experience in v1.1? |
| C5 | Req 12.12 | Is full screen-reader support (TalkBack, VoiceOver, Narrator) a v1.0 requirement or a v1.2 roadmap item? |
| C6 | Req 13.9 | Which second locale should be included in the initial i18n implementation? |
| C7 | Req 14.10 | Which analytics provider should be used (Firebase Analytics, Mixpanel, or self-hosted)? |
| C8 | Req 15.10 | Is an Apple Developer account available for iOS/macOS notarisation in the release pipeline? |
