# Implementation Plan: Chronos Planner TSD

## Overview

This plan converts the Chronos Planner TSD design into incremental coding tasks for a Flutter/Dart implementation. Tasks are ordered so each step builds on the previous, starting with foundational infrastructure (dependency updates, core abstractions, schema migration) and progressing through feature completeness, UI/UX hardening, testing, and DevOps. All code is Dart/Flutter targeting the `chronosky` package.

---

## Tasks

- [ ] 1. Dependency and tooling bootstrap
  - [ ] 1.1 Update `pubspec.yaml`: upgrade `drift` to `^2.31.0` and `drift_dev` to `^2.31.0`, add `flutter_localizations` SDK dependency, add `mocktail: ^1.0.0` to `dev_dependencies`, upgrade `flutter_lints` to `^6.0.0`, remove `shared_preferences` (after confirming migration flag), and audit `file_picker`/`just_audio` for removal
    - Verify `sqlite3_flutter_libs` compatibility with the new `drift` version before committing
    - Commit `pubspec.lock` to version control
    - _Requirements: 16.2, 16.3, 16.4, 16.5, 16.9, 16.11_
  - [ ] 1.2 Upgrade `analysis_options.yaml` to include all additional lint rules from the design (`avoid_dynamic_calls`, `avoid_print`, `prefer_const_constructors`, `prefer_final_fields`, `prefer_single_quotes`, `require_trailing_commas`, `unawaited_futures`, `unnecessary_await_in_return`, `always_use_package_imports`, `cancel_subscriptions`, `close_sinks`, `use_key_in_widget_constructors`) and set `missing_required_param` and `missing_return` to `error`
    - _Requirements: 6.2, 6.3_
  - [ ] 1.3 Create `docs/dependencies.md` documenting every direct dependency (name, version constraint, purpose, last-reviewed date)
    - _Requirements: 16.7, 16.8_

- [ ] 2. Core abstractions — `Result<T>`, `AppFailure`, and `Logger`
  - [ ] 2.1 Create `lib/core/result.dart`: implement the `Result<T>` sealed class with `Success<T>` and `Failure<T>` subclasses, and the `AppFailure` sealed hierarchy (`DatabaseFailure`, `ValidationFailure`, `NetworkFailure`, `UnknownFailure`)
    - _Requirements: 10.2, 5.7_
  - [ ] 2.2 Create `lib/core/services/logger.dart`: implement the `Logger` abstract class with `debug`, `info`, `warning`, and `error` methods; implement `ConsoleLogger` (using `dart:developer log()`), `NoOpLogger`, and `CrashReportingLogger` stub; wire `ConsoleLogger` in debug builds and `NoOpLogger` in release builds inside `main.dart`
    - _Requirements: 14.1, 14.2, 14.3_
  - [ ]* 2.3 Write unit tests for `Result<T>` pattern-matching and `AppFailure` hierarchy
    - Verify `Success` and `Failure` cases are exhaustively matched
    - _Requirements: 10.2_

- [ ] 3. Immutable domain models and DTOs
  - [ ] 3.1 Refactor `Task` to be `@immutable` with `copyWith`, `toJson`, `fromJson`, and `==`/`hashCode`; add model-layer `assert` validation for `title` (1–200 chars), `startTime`/`endTime` regex, and `estimatedCost`/`actualCost` (≥ 0.0, finite); store enums as `.name` strings with `firstWhere` fallback in `fromJson`
    - _Requirements: 4.1, 4.2, 4.11, 6.9_
  - [ ] 3.2 Refactor `DayPlan` to be `@immutable` with `copyWith`, `toJson`, `fromJson`; expose `tasks` as `List.unmodifiable`; add `dateStr` and `dayOfWeek` as computed getters using `intl.DateFormat`; remove any stored `dateStr`/`dayOfWeek` fields
    - _Requirements: 4.1, 4.12, 6.9_
  - [ ] 3.3 Refactor `PlanTemplate` and `TemplateTask` to be `@immutable` with `copyWith`, `toJson`, `fromJson`; expose `tasks` and `activeDays` as unmodifiable views; add `isRecurring` getter
    - _Requirements: 4.1, 6.9_
  - [ ] 3.4 Refactor `TodoItem` to be `@immutable` with `copyWith`, `toJson`, `fromJson`; validate `title` 1–200 chars at model layer
    - _Requirements: 4.1, 3D.21_
  - [ ] 3.5 Create `lib/data/models/task_dto.dart` and `lib/data/models/todo_item_dto.dart` with `schemaVersion` field and `fromDomain`/`toDomain` conversion methods; keep DTOs separate from domain models
    - _Requirements: 4.10_
  - [ ]* 3.6 Write property test for Task JSON round-trip (Property 1)
    - **Property 1: Task JSON Round-Trip** — `Task.fromJson(task.toJson()) == task` for all valid `Task` inputs (all `TaskType`, `TaskPriority`, `TaskEnergyLevel` combinations; title 1–200 chars; valid `HH:mm` pairs; cost 0.0–9999.0)
    - **Validates: Requirements 7.6, 4.1, 4.2**
    - Run minimum 100 iterations
    - _Requirements: 7.6_

- [ ] 4. Schema v5 migration and Drift table definitions
  - [ ] 4.1 Update Drift table definitions in `lib/data/local/app_database.dart`: add `TemplateActiveDays` table (`templateId`, `dayIndex`, composite PK); add `ON DELETE CASCADE` FK to `Tasks.dayPlanId` and `TemplateTasks.templateId`; remove `active_days` column from `PlanTemplates`; remove `date_str` and `day_of_week` columns from `DayPlans`; add all indexes specified in the design
    - _Requirements: 4.3, 4.4, 4.5, 4.12_
  - [ ] 4.2 Implement the full `MigrationStrategy` in `AppDatabase` covering versions 1→5: add all `if (from < N)` blocks including the v4→v5 block that creates `template_active_days`, migrates comma-separated `active_days` to junction rows (with `whereType<int>().where((d) => d >= 0 && d <= 6)` guard), drops the old column via `TableMigration`, recreates `tasks` and `template_tasks` with CASCADE FKs, and removes derived columns from `day_plans`; wrap in Drift's transaction
    - _Requirements: 4.6, 4.3, 4.4, 4.5, 4.12_
  - [ ] 4.3 Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate all `*.g.dart` files; commit generated files
    - _Requirements: 5.11_
  - [ ]* 4.4 Write integration test for schema v4→v5 migration: seed an in-memory Drift DB at v4 with templates containing comma-separated `active_days`, run migration, verify `template_active_days` rows are correct and no data is lost
    - _Requirements: 4.6, 7.3_
  - [ ]* 4.5 Write property test for PlanTemplate active days round-trip (Property 2)
    - **Property 2: PlanTemplate Active Days Round-Trip** — `_parseActiveDays(_encodeDays(days)).toSet() == days.toSet()` for all `List<int>` subsets of [0..6]
    - **Validates: Requirements 7.7, 4.3**
    - Run minimum 100 iterations
    - _Requirements: 7.7_

- [ ] 5. Repository interfaces and `Result<T>` contracts
  - [ ] 5.1 Update `ScheduleRepository` abstract class to return `Future<Result<T>>` on all methods as specified in the design (Section 6.1); update `TemplateRepository` (Section 6.2) and `TodoRepository` (Section 6.3) likewise; split `PreferenceRepository` into `PreferenceRepository` (get/set/remove) and `BulkPreferenceRepository` (adds `getAll()`) per ISP
    - _Requirements: 10.2, 6.7, 6.8_
  - [ ] 5.2 Update `LocalScheduleRepository` to implement the new `Result<T>` interface: wrap all Drift calls in `try/catch`, return `Success`/`Failure`, implement exponential-backoff retry for `FileSystemException` (max 3 attempts, 200 ms initial delay, 2× multiplier), and catch `DriftWrappedException` with structured logging
    - _Requirements: 10.2, 10.3, 10.4_
  - [ ] 5.3 Update `LocalTemplateRepository` to implement `Result<T>` interface; fix the N+1 query in `getAllTemplates()` by replacing the per-template task fetch loop with a single JOIN query (`SELECT * FROM plan_templates JOIN template_tasks ON template_tasks.template_id = plan_templates.id`) plus a separate query for `template_active_days`; implement `updateTemplateActiveDays` using the junction table
    - _Requirements: 3C.18, 10.2_
  - [ ] 5.4 Update `LocalTodoRepository` to implement `Result<T>` interface; implement `watchTodos()` reactive stream via Drift's `watch()` API; implement `addTodo` with UUID v4 generation and title validation
    - _Requirements: 10.2, 3D.19, 3D.21_
  - [ ] 5.5 Update `LocalPreferenceRepository` to implement `Result<T>` interface; remove all `shared_preferences` usage and replace with Drift `preferences` table reads/writes
    - _Requirements: 10.2, 16.2_
  - [ ]* 5.6 Write unit tests for `LocalScheduleRepository`: `getUpcomingDays(7)` returns exactly 7 `DayPlan` objects; retry logic fires on `FileSystemException`; `DriftWrappedException` returns `Failure(DatabaseFailure)`
    - _Requirements: 7.1, 3B.11, 10.3, 10.4_
  - [ ]* 5.7 Write unit test for `LocalTemplateRepository.getAllTemplates()` with 100 templates: verify single-query execution (no N+1) and completion within 50 ms
    - _Requirements: 7.1, 3C.18_
  - [ ]* 5.8 Write property test for Preference round-trip (Property 10)
    - **Property 10: Preference Round-Trip** — `await prefRepo.set(key, value); await prefRepo.get(key) == value` for all non-empty alphanumeric key/value strings
    - **Validates: Requirements 3 (preferences), 10.2**
    - Run minimum 100 iterations
    - _Requirements: 7.7_

- [ ] 6. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. `ScheduleStateProvider` and `AnalyticsProvider` split
  - [ ] 7.1 Create `lib/providers/schedule_state_provider.dart`: extract from `ScheduleProvider` all state fields (`_weekPlan`, `_templates`, `_selectedDayIndex`, `_undoStack`, `_sortOrder`, `_isLoading`, `errorMessage`) and all CRUD + undo + template methods; inject `ScheduleRepository`, `TemplateRepository`, `PreferenceRepository`, and `Logger` via constructor; implement optimistic-update + rollback pattern for all write operations; cap `_undoStack` at 50 with FIFO eviction; implement `_isLoading` guard with `Completer` to debounce concurrent `_loadData()` calls; implement `WindowListener.onWindowClose` to flush state
    - _Requirements: 6.4, 1.7, 3A.1, 3A.2, 3A.3, 3A.4, 3A.5, 3A.6, 3A.7, 3B.11, 3B.12, 3B.13, 3C.14, 3C.15, 3C.16, 3C.17, 8.10, 10.1, 10.6, 10.11, 11.9_
  - [ ] 7.2 Create `lib/providers/analytics_provider.dart`: extract computed metrics (`efficiency`, `totalTasks`, `completedTasks`, `totalFocusHours`, `categoryDistribution`) from `ScheduleProvider`; take `ScheduleStateProvider` as constructor parameter and listen via `addListener`; offload `getEnergyPeaks()` to `compute()` when task history > 500 items
    - _Requirements: 6.4, 8.9_
  - [ ] 7.3 Update `TodoProvider`: implement `_subscribe()` with stream error recovery (re-subscribe after 1 s, up to 3 attempts); cancel `StreamSubscription` in `dispose()`; implement `addTodo`, `updateTodo`, `deleteTodo` with `Result<T>` handling and `errorMessage` surfacing; validate title 1–200 chars before calling repository
    - _Requirements: 3D.19, 3D.20, 3D.21, 8.7, 10.7_
  - [ ] 7.4 Update `main.dart`: wire `ConsoleLogger`/`NoOpLogger` injection; register `ScheduleStateProvider`, `AnalyticsProvider`, and `TodoProvider` via `MultiProvider` with constructor injection; implement `FlutterError.onError` and `PlatformDispatcher.instance.onError` global handlers; add lifecycle logging (`info` level) for app start, DB init, migration complete, provider load complete
    - _Requirements: 1.4, 1.8, 10.8, 10.9, 14.4_
  - [ ]* 7.5 Write unit tests for `ScheduleStateProvider`: `addTask` with valid task → `_weekPlan` updated, `notifyListeners` called, repo invoked; `addTask` with repo failure → rollback, `errorMessage` set; `deleteTask` → undo stack grows by 1; `undo()` after `deleteTask` → task restored; `undo()` on empty stack → no state change, no exception, warning logged; `_undoStack` capped at 50; `applyTemplate(N tasks)` to day with M tasks → M+N tasks; `setTemplateRecurring` applied twice → no duplicate `sourceTemplateId` tasks
    - _Requirements: 7.1, 7.4, 7.5, 3A.4, 3A.5, 8.10, 3C.15, 3C.16, 10.11_
  - [ ]* 7.6 Write unit test for `TodoProvider.dispose()` → `StreamSubscription` cancelled
    - _Requirements: 7.1, 8.7_

- [ ] 8. Property-based tests for provider and service invariants
  - [ ]* 8.1 Write property test for Task duration non-negative and bounded (Property 3)
    - **Property 3: Task Duration Non-Negative and Bounded** — `0.0 <= _calculateDuration(start, end) <= 24.0` for all valid `HH:mm` pairs including overnight (endHour ≤ startHour)
    - **Validates: Requirements 3A.10**
    - Run minimum 100 iterations
    - _Requirements: 3A.10_
  - [ ]* 8.2 Write property test for efficiency score bounded (Property 4)
    - **Property 4: Efficiency Score Bounded** — `0.0 <= calculateEfficiency(tasks) <= 100.0` for all `List<Task>` including empty list
    - **Validates: Requirements 3 (analytics), 8 (analytics)**
    - Run minimum 100 iterations
    - _Requirements: 7.1_
  - [ ]* 8.3 Write property test for energy peaks map validity (Property 5)
    - **Property 5: Energy Peaks Map Validity** — all keys in `[0, 23]` and all values in `[0.0, 1.0]` for any non-empty `List<Task>`
    - **Validates: Requirements 8.9**
    - Run minimum 100 iterations
    - _Requirements: 7.1_
  - [ ]* 8.4 Write property test for sort idempotence (Property 6)
    - **Property 6: Sort Idempotence** — `getSortedTasks(getSortedTasks(dayPlan, order), order) == getSortedTasks(dayPlan, order)` for any `DayPlan` and both `SortOrder` values
    - **Validates: Requirements 3A (sort), 6 (idempotence)**
    - Run minimum 100 iterations
    - _Requirements: 7.1_
  - [ ]* 8.5 Write property test for undo restores deleted task (Property 7)
    - **Property 7: Undo Restores Deleted Task** — after `deleteTask(task.id)` then `undo()`, `weekPlan` contains a task equal to the original (same `id`, `title`, `startTime`, `endTime`, `type`, `priority`, `energyLevel`, `estimatedCost`, `description`, `sourceTemplateId`)
    - **Validates: Requirements 3A.5, 7.15**
    - Run minimum 100 iterations
    - _Requirements: 7.15_
  - [ ]* 8.6 Write property test for template apply preserves task count (Property 8)
    - **Property 8: Template Apply Preserves Task Count** — after `applyTemplate(template)` on a day with M tasks and no `sourceTemplateId` overlap, `dayPlan.tasks.length == M + N`
    - **Validates: Requirements 3C.15**
    - Run minimum 100 iterations
    - _Requirements: 3C.15_
  - [ ]* 8.7 Write property test for week key determinism and format (Property 9)
    - **Property 9: Week Key Determinism and Format** — `_calculateWeekKey(date) == _calculateWeekKey(date)` and result matches `^\d{4}-W\d{2}$` for any `DateTime` in 2020-01-01 to 2030-12-31
    - **Validates: Requirements 4 (implicit), 3B.11**
    - Run minimum 100 iterations
    - _Requirements: 4.7_

- [ ] 9. `IntelligenceService` refactor and `RecommendationStrategy`
  - [ ] 9.1 Create `lib/core/services/recommendation_strategy.dart`: define `RecommendationStrategy` abstract interface with `recommend(TaskEnergyLevel energy, Map<int, double> peaks)` method; implement `PeakHourStrategy` and `OffPeakStrategy`; update `IntelligenceService.recommendTime` to delegate to the injected strategy
    - _Requirements: 6.5_
  - [ ] 9.2 Update `IntelligenceService.getEnergyPeaks()` to use `compute()` when the task list contains more than 500 items; add `dart:developer` `Timeline` instrumentation to `_loadData()`, `getAllTemplates()`, and `getEnergyPeaks()`
    - _Requirements: 8.9, 14.8_
  - [ ]* 9.3 Write unit tests for `IntelligenceService`: `calculateEfficiency([])` returns 0.0; `getEnergyPeaks` with 501 tasks verifies `compute()` is called; `_calculateDuration("22:00", "01:00")` returns 3.0
    - _Requirements: 7.1_

- [ ] 10. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. UI widget extraction and `AppTheme` token enforcement
  - [ ] 11.1 Extract `DaySelectorWidget` from `ScheduleView` into `lib/ui/widgets/day_selector_widget.dart` with the exact API from the design (`days`, `selectedIndex`, `onDaySelected`); add `Semantics` labels; use `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, `AppAnimDurations` tokens exclusively — no hardcoded literals
    - _Requirements: 5.8, 2.1, 2.2, 2.3, 2.4, 2.5, 12.1_
  - [ ] 11.2 Extract `MetricCard` from `AnalyticsView` into `lib/ui/widgets/metric_card.dart` with the exact API from the design (`label`, `value`, `icon`, `color`, `subtitle`); no provider access inside the widget; use `AppTextStyles.heading3` and `AppTextStyles.subtitle`
    - _Requirements: 5.9, 2.2_
  - [ ] 11.3 Audit all widget files and replace every hardcoded `Color(0x...)`, `Colors.*`, `TextStyle(fontSize: ...)`, magic-number padding, `BorderRadius.circular(N)`, and `Duration(milliseconds: N)` with the corresponding `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, and `AppAnimDurations` tokens
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  - [ ] 11.4 Update `TaskCard` widget: add `Semantics` label, `Semantics.checked` on completion toggle, `Dismissible(direction: DismissDirection.endToStart)` only, nullable `onEdit`/`onDuplicate` callbacks omitting menu items when null, `AnimatedOpacity` 300 ms on completion, min tap target 48×48 px, `const` constructor
    - _Requirements: 5.3, 5.4, 8.1, 8.3, 12.1, 12.3, 12.9_
  - [ ] 11.5 Update `AddTaskSheet`: implement edit mode (`editingTask != null` pre-populates all fields, calls `onUpdate` on submit, never calls `onAdd`); add inline validation errors for empty title, title > 200 chars, `startTime == endTime`, invalid time format, negative/NaN cost; dispose all `TextEditingController` instances in `dispose()`
    - _Requirements: 5.7, 3A.8, 3A.9, 9.8, 10.12_
  - [ ] 11.6 Update `GlassContainer`: implement scale animation (0.97 on tap-down, 1.0 on tap-up, `AppAnimDurations.fast`); set `Semantics(button: true)` when `onTap != null`; set `excludeSemantics: true` on gradient border `CustomPaint`; enforce `blurSigma` parameter
    - _Requirements: 2.12, 2.15, 12.2, 12.11_
  - [ ] 11.7 Create `lib/ui/widgets/debug_overlay.dart`: visible only in `kDebugMode`; toggled by `Ctrl+Shift+D`; displays last 50 log entries, `weekPlan.length`, `templates.length`, `todos.length`, and DB row counts per table; positioned as overlay above all content
    - _Requirements: 14.9_

- [ ] 12. Screen-level `Consumer`/`Selector` wiring and responsive layout
  - [ ] 12.1 Replace all `Provider.of<ScheduleProvider>(context)` calls in `build()` methods with `Selector<ScheduleStateProvider, T>` or `Consumer` with `child` parameter as specified in the design (Section 16.1); use `Provider.of<T>(context, listen: false)` exclusively in callbacks and `initState`
    - _Requirements: 5.5, 5.6, 8.2_
  - [ ] 12.2 Implement responsive layout in `ChronosHome`: render `_DesktopSidebar` (250 px) when width > 800 px; render bottom navigation bar with glassmorphism backdrop blur when width ≤ 800 px; enforce `WindowOptions.minimumSize = Size(800, 600)`
    - _Requirements: 2.6, 2.7, 2.8_
  - [ ] 12.3 Implement `AnimatedSwitcher` with fade + 2 % horizontal slide transition (`AppAnimDurations.normal`, `Curves.easeOutCubic`) on every top-level screen change; implement swipe-left/right gesture on task list (velocity threshold 300 px/s) to advance/retreat day
    - _Requirements: 2.10, 2.13_
  - [ ] 12.4 Add `RepaintBoundary` around `_DonutChartPainter` and the energy-peaks bar chart `CustomPaint` in `analytics_view.dart`; use `ListView.builder` for all task lists in `ScheduleView`; use `GridView.builder` for `TodoListView`
    - _Requirements: 8.4, 8.5, 8.11_
  - [ ] 12.5 Add `Tooltip` widgets on all icon-only buttons (sort toggle, undo, clear day, save template, focus mode); add `FocusTraversalGroup` on sidebar and main content area; add `Semantics` on day-selector chips and navigation items; add `excludeSemantics: true` on decorative elements
    - _Requirements: 12.5, 12.6, 12.7, 12.11_
  - [ ] 12.6 Implement reduced-motion support: read `MediaQuery.disableAnimations` and `PreferenceRepository` key `reduce_motion`; skip non-essential animations when either is true; add in-app animation-preference toggle persisted via `PreferenceRepository`
    - _Requirements: 12.8_
  - [ ]* 12.7 Write widget tests: width > 800 px → `_DesktopSidebar` rendered; width ≤ 800 px → bottom nav rendered; `DaySelectorWidget` tap → `onDaySelected` called with correct index; `MetricCard` renders label, value, icon
    - _Requirements: 7.2, 2.6, 2.7, 5.8, 5.9_

- [ ] 13. Focus Mode — `window_manager` integration and `FocusHUD`
  - [ ] 13.1 Implement Focus Mode toggle in `home_screen.dart`: on enter call `windowManager.setAlwaysOnTop(true)` → `windowManager.setSize(Size(320, 200))` → `windowManager.setAlignment(Alignment.topRight)` (each `await`ed); on exit call `setAlwaysOnTop(false)` → `setSize(Size(1200, 800))` → `center()`; guard all calls with `Platform.isWindows || Platform.isMacOS || Platform.isLinux`; catch `MissingPluginException` and disable Focus Mode button on unsupported platforms; log enter/exit at `info` level
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.7, 14.4_
  - [ ] 13.2 Implement `WindowListener` in `main.dart` or `home_screen.dart` to detect `onWindowClose` and call `ScheduleStateProvider.dispose()` before process exits
    - _Requirements: 11.9_
  - [ ] 13.3 Implement `FocusHUD` widget: compact 320×200 layout; show first uncompleted task from selected day ("All caught up!" if none); background `AppColors.background` with 0.95 alpha; `AppColors.neonBlue` glow border; `onExit` callback
    - _Requirements: 4.5 (FocusHUD), 11.2_
  - [ ]* 13.4 Write widget test for `FocusHUD`: renders first uncompleted task; renders "All caught up!" when all tasks completed; `onExit` callback fires on button tap
    - _Requirements: 7.2_

- [ ] 14. Logging instrumentation and security hardening
  - [ ] 14.1 Replace all `print()` calls in `lib/` with the appropriate `Logger` method (`debug`, `info`, `warning`, `error`); add structured logging for all lifecycle events (app start, DB init, migration complete, provider load complete, Focus Mode enter/exit) at `info` level; add debug-level logging for task created/deleted/completed, template applied, undo triggered; add error-level logging with full stack trace for repository write failures, migration failures, stream errors
    - _Requirements: 6.11, 14.4, 14.5, 14.6_
  - [ ] 14.2 Audit all logger call sites to ensure no PII is included: replace task titles, descriptions, and cost values with `[REDACTED]` in all log messages
    - _Requirements: 9.2, 14.7_
  - [ ] 14.3 Audit all DAOs to verify parameterised Drift queries are used exclusively; remove any raw SQL string interpolation with user-supplied values; add input sanitisation (trim whitespace, enforce character limits) in `AddTaskSheet` and `TodoDetailScreen` before calling repositories
    - _Requirements: 9.4, 9.5_
  - [ ] 14.4 Update `android/app/src/main/AndroidManifest.xml` to set `android:allowBackup="false"`; verify no OS permissions (camera, microphone, contacts, location) are declared that are not required
    - _Requirements: 9.9, 9.10_

- [ ] 15. Internationalisation (i18n) and localisation
  - [ ] 15.1 Add `flutter_localizations` SDK dependency and `intl: ^0.20.2` to `pubspec.yaml`; create `l10n.yaml` with `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`; configure `MaterialApp.localizationsDelegates` with `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, and `GlobalCupertinoLocalizations.delegate`
    - _Requirements: 13.1_
  - [ ] 15.2 Create `lib/l10n/app_en.arb` with all user-visible strings extracted from widget `build()` methods; run `flutter gen-l10n` to generate `AppLocalizations`; update all widgets to access strings via `AppLocalizations.of(context)!.stringKey`
    - _Requirements: 13.2, 13.3_
  - [ ] 15.3 Replace all hardcoded date formatting (`"Feb 10"`, `"Monday"`) with `intl.DateFormat.MMMd(locale).format(date)` and `intl.DateFormat.EEEE(locale).format(date)`; replace time formatting with `DateFormat.Hm(locale)` or `DateFormat.jm(locale)` based on device locale; replace cost formatting with `NumberFormat.currency(locale: locale, symbol: symbol)`
    - _Requirements: 13.4, 13.5, 13.6_
  - [ ] 15.4 Replace all directional `EdgeInsets.only(left: ...)` and `Alignment.centerLeft` with `EdgeInsetsDirectional.only(start: ...)` and `AlignmentDirectional.centerStart` for RTL support
    - _Requirements: 13.7_

- [ ] 16. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 17. Widget tests for `AddTaskSheet`, `TaskCard`, and accessibility
  - [ ]* 17.1 Write widget test: `AddTaskSheet` displays inline error when submitted with empty title; repo NOT called
    - _Requirements: 7.10, 3A.8_
  - [ ]* 17.2 Write widget test: `AddTaskSheet` displays inline error when `startTime == endTime`
    - _Requirements: 7.11, 3A.9_
  - [ ]* 17.3 Write widget test: `Dismissible` in `TaskCard` calls `onDelete` when swiped end-to-start
    - _Requirements: 7.12, 5.3_
  - [ ]* 17.4 Write widget test: long-press context menu on `TaskCard` shows "Edit", "Duplicate", "Delete" when all callbacks provided; shows only "Delete" when `onEdit`/`onDuplicate` are null
    - _Requirements: 7.13, 7.14, 5.4_
  - [ ]* 17.5 Write widget test: `AddTaskSheet` `dispose()` called → all `TextEditingController` instances disposed
    - _Requirements: 10.12_

- [ ] 18. Golden tests
  - [ ]* 18.1 Create golden tests for `TaskCard` in all 8 states (work/personal/health/leisure × active/completed) under `test/goldens/`
    - _Requirements: 7.8_
  - [ ]* 18.2 Create golden tests for `GlassContainer` in 6 states (no border / gradient border; `blurSigma` 5/10/20) under `test/goldens/`
    - _Requirements: 7.9_
  - [ ]* 18.3 Create golden tests for `DaySelectorWidget` (day 0 selected / day 3 selected / all days with tasks) and `MetricCard` (with subtitle / without subtitle) under `test/goldens/`
    - _Requirements: 7.8_

- [ ] 19. Integration tests for critical paths
  - [ ]* 19.1 Write integration test: task creation → persistence → display (create task via `AddTaskSheet`, verify in `ScheduleView` and DB)
    - _Requirements: 7.3_
  - [ ]* 19.2 Write integration test: template apply → day update (apply template, verify tasks appear in `ScheduleView`)
    - _Requirements: 7.3_
  - [ ]* 19.3 Write integration test: todo creation → stream update → grid display (create todo, verify `TodoListView` grid updates within one frame)
    - _Requirements: 7.3, 3D.19_
  - [ ]* 19.4 Write integration test: undo within 4 seconds (delete task, tap UNDO, verify task restored)
    - _Requirements: 7.15, 3A.5_
  - [ ]* 19.5 Write integration test: `ScheduleView` with 50 tasks renders within 16 ms per frame
    - _Requirements: 7.16_

- [ ] 20. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 21. CI/CD pipeline and build scripts
  - [ ] 21.1 Create `.github/workflows/ci.yml` with three jobs in order: `lint` (`flutter analyze --fatal-warnings`), `test` (`flutter test --coverage` + lcov coverage gate ≥ 70 % on `lib/data/` and `lib/providers/`, `dart pub outdated --mode=null-safety` comment, `flutter pub audit` fail on CVSS ≥ 7.0), `build` (matrix across Windows/Linux/macOS/Android APK/Android AAB/iOS); cache Flutter SDK, pub cache, and Gradle cache
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7_
  - [ ] 21.2 Create `.github/workflows/release.yml` triggered on `v*.*.*` tags: build all 6 artefacts, publish Windows MSIX to Microsoft Store staging, publish Android AAB to Google Play internal track, create GitHub Release with macOS DMG; auto-increment `BUILD` number via `$GITHUB_RUN_NUMBER`
    - _Requirements: 15.8, 15.10_
  - [ ] 21.3 Create `scripts/` directory with `Makefile` commands: `make lint`, `make test`, `make build-windows`, `make build-linux`, `make build-macos`, `make build-android`, `make build-ios`; add release build flags (`--obfuscate --split-debug-info=build/debug-info/`) to Android and iOS build commands
    - _Requirements: 15.11, 9.6_
  - [ ] 21.4 Add CI step to verify `CHANGELOG.md` has been updated on every PR that modifies `lib/`; configure branch protection rules (block direct pushes to `main`, require ≥ 1 approved review + passing CI)
    - _Requirements: 15.9, 15.12_

- [ ] 22. Documentation and ADR scaffolding
  - [ ] 22.1 Create `docs/adr/` directory with an `ADR-000-template.md` using the MADR template; create `docs/devops/build_guide.md` documenting all `make` commands and their expected outputs; create `CHANGELOG.md` following Keep a Changelog format with an initial entry for the TSD implementation
    - _Requirements: 1.10, 15.9, 15.11_
  - [ ] 22.2 Create `docs/accessibility/contrast_audit.md` documenting the WCAG 2.1 AA contrast ratio audit for all `AppColors` text/background pairs
    - _Requirements: 12.4_

- [ ] 23. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP; all non-starred tasks are required
- Each task references specific requirements for traceability
- Property tests P1–P10 each require a minimum of 100 iterations and must be tagged `// Feature: chronos-planner-tsd, Property N: <property_text>`
- The design uses Dart/Flutter throughout; no language selection was needed
- Schema migration (Task 4) must be completed before provider refactoring (Task 7) since providers depend on the updated Drift-generated types
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after any Drift table change (Tasks 4.1, 4.2) before proceeding
- Open clarification items C1–C8 from the design are not blocked by any task here; tasks are written to be compatible with either resolution of each item
- `shared_preferences` removal (Task 1.1) should only be executed after confirming the one-time migration flag has been set in all production installs

## Task Dependency Graph

```json
{
  "waves": [
    {
      "id": 0,
      "tasks": ["1.1", "1.2", "1.3"]
    },
    {
      "id": 1,
      "tasks": ["2.1", "2.2"]
    },
    {
      "id": 2,
      "tasks": ["2.3", "3.1", "3.2", "3.3", "3.4", "3.5"]
    },
    {
      "id": 3,
      "tasks": ["3.6", "4.1"]
    },
    {
      "id": 4,
      "tasks": ["4.2"]
    },
    {
      "id": 5,
      "tasks": ["4.3"]
    },
    {
      "id": 6,
      "tasks": ["4.4", "4.5", "5.1"]
    },
    {
      "id": 7,
      "tasks": ["5.2", "5.3", "5.4", "5.5"]
    },
    {
      "id": 8,
      "tasks": ["5.6", "5.7", "5.8", "9.1"]
    },
    {
      "id": 9,
      "tasks": ["7.1", "7.2", "7.3", "9.2"]
    },
    {
      "id": 10,
      "tasks": ["7.4", "9.3"]
    },
    {
      "id": 11,
      "tasks": ["7.5", "7.6", "8.1", "8.2", "8.3", "8.4", "8.5", "8.6", "8.7"]
    },
    {
      "id": 12,
      "tasks": ["11.1", "11.2", "11.3", "11.4", "11.5", "11.6", "11.7"]
    },
    {
      "id": 13,
      "tasks": ["12.1", "12.2", "12.3", "12.4", "12.5", "12.6"]
    },
    {
      "id": 14,
      "tasks": ["12.7", "13.1", "13.2", "13.3", "14.1", "14.2", "14.3", "14.4"]
    },
    {
      "id": 15,
      "tasks": ["15.1", "15.2", "15.3", "15.4"]
    },
    {
      "id": 16,
      "tasks": ["17.1", "17.2", "17.3", "17.4", "17.5", "18.1", "18.2", "18.3"]
    },
    {
      "id": 17,
      "tasks": ["19.1", "19.2", "19.3", "19.4", "19.5"]
    },
    {
      "id": 18,
      "tasks": ["21.1", "21.2", "21.3", "21.4"]
    },
    {
      "id": 19,
      "tasks": ["22.1", "22.2"]
    }
  ]
}
```
