# Comprehensive Code Quality & Architectural Audit: DayVault

> **Repository:** `C:\Users\ajaye\My_Products\chronos_planner` (pubspec name: `chronosky`)
> **Benchmarked against:** `C:\agents\agentresearchs\plans\engineering-skills\skills\engineering-standards`
> (`SKILL.md`, `references/design-judgment.md`, `security-privacy.md`, `performance-efficiency.md`,
> `reliability-observability.md`, `testing-quality.md`, `lifecycle-gates.md`, `stack-appendices.md` §4 Mobile)
> **Audit date:** 2026-08-24 · **Method:** exhaustive static read of all 45 hand-written `.dart` files in `lib/`
> (13,185 LOC excluding generated) + 11 test files, plus `flutter analyze` and `flutter test` runs.
> **Verification performed:** `flutter analyze --no-pub` → *No issues found (116.6s)*; `flutter test --no-pub` → *36 tests, all passed*.

---

## 1. Executive Summary & Quality Scorecard

DayVault is a **local-first Flutter desktop/mobile planner** built on Drift/SQLite with Provider state
management. It is meaningfully better-engineered than a typical hobby Flutter app: it has a real
layered structure (`core` / `data` / `providers` / `ui`), a sealed `Result<T>` error type instead of
naked exceptions, repository interfaces separated from Drift implementations, optimistic UI updates
with rollback, an eight-step versioned migration chain, and — notably — several comment blocks that
explain *why* rather than *what* (`main.dart:47-50`, `schedule_state_provider.dart:643-649`,
`task_dao.dart:25-26`). The analyzer is clean under a lint set stricter than `flutter_lints` default.

That is the good news, and it is real. The bad news is that **the project's strongest guarantees are
the ones that stop working in a release build.** Three of the four load-bearing correctness
mechanisms — foreign-key cascades, domain invariant validation, and the `Result` error envelope —
each have a hole that only opens in production or under a specific error path, and there is no
observability (`NoOpLogger` in release, `main.dart:30`), no global error handler, and no CI to catch
any of it. The presentation layer is where the debt is thickest: a single 537-line `build()` method,
zero widget tests across ~7,900 lines of UI, and unscoped `Provider.of` calls that rebuild four
screens on every state change.

The architecture will hold. The **integrity and verification layers will not**, and those are the
expensive ones to retrofit.

### Quality Scorecard

| Dimension | Score | Rationale |
|---|:---:|---|
| **Architecture & State Management** | **7 / 10** | Clean layer separation, DI by constructor injection, repository interfaces, sealed `Result`. Loses points for a missing domain/use-case layer (business rules live in the provider), manual cross-provider wiring, and a `getIt`-free but also seam-free singleton database. |
| **Standards Compliance (Dart/Flutter)** | **6 / 10** | Analyzer clean under strong lints; immutable models with `copyWith`/`==`/`hashCode`. Loses points for a 537-line `build()`, boolean behavior-selecting parameter, 4× duplicated `_wrap`, ~350 lines of dead code, stale doc comments, and one broken `hashCode`/`==` contract. |
| **Performance & Memory** | **5 / 10** | Batched template writes and an isolate for heavy analytics are genuinely good. Loses points for two leaked `TextEditingController`s, an uncancellable retry timer, sort-in-build, zero `Selector`/`RepaintBoundary`, N+1 day-task reads, and four always-mounted screens under `IndexedStack`. |
| **Security & Data Integrity** | **4 / 10** | Offline-only design keeps attack surface small and there are no secrets in source. But `PRAGMA foreign_keys` is never enabled (cascades inert), all invariant checks are `assert`-only (stripped in release), and the v8 migration performs an unbackuped destructive `DELETE`. |
| **Testability** | **4 / 10** | 36 passing tests with real mocks (`mocktail`) and real in-memory Drift instances — the right shape. But zero widget tests, zero integration tests, `widget_test.dart` is a 7-line placeholder, 4 of 8 migration steps untested, and `IntelligenceService` is instantiated inline so it cannot be mocked. |
| **Product Scalability** | **5 / 10** | Adding a *repository-backed* feature is cheap. Adding a *screen* requires editing `home_screen.dart`'s hardcoded `_screens` list, nav items in two places, and `main.dart`'s `MultiProvider`. No routing abstraction, no feature modules, no i18n seam. |

> **Weighted overall health: 5.2 / 10 — "Structurally sound, operationally fragile."**

### Top 3 Critical Risks (address immediately)

1. **Foreign-key enforcement is switched off, making every `ON DELETE CASCADE` a no-op.**
   `tables.dart:20, 58, 72` declare cascades; schema migration v5 (`app_database.dart:236-241`)
   explicitly rebuilt three tables *for the purpose of adding them*. SQLite defaults
   `foreign_keys` to **OFF** per connection, and no `beforeOpen` hook enables it anywhere in `lib/`
   (verified: `grep -rn "foreign_keys\|beforeOpen" lib/` → no matches). Deleting a `DayPlan` or
   `PlanTemplate` silently orphans its children forever. Violates the non-negotiable
   *"Correctness of data over everything"* and `stack-appendices.md` §2 *"Let the database enforce
   what the database can enforce."*

2. **All domain invariants are enforced by `assert`, which the Dart AOT compiler strips from release builds.**
   `task_model.dart:42-51`, `plan_template_model.dart:30-37`, `todo_item_model.dart:87`. In the
   shipped app, `Task(startTime: '99:99', title: '', estimatedCost: -5)` constructs and persists
   without complaint. The tests that "prove" validation works (`task_model_test.dart:46`) pass only
   because tests run in debug mode. Violates `security-privacy.md` *"Validate at the boundary, with
   an allowlist, into typed domain objects."*

3. **`StateError` escapes the `Result` envelope, producing a silent write failure that the UI reports as success.**
   `local_schedule_repository.dart:43-53` catches `on DriftWrappedException` then `on Exception`.
   `StateError` (thrown at `:101` and `:136`) is an `Error`, **not** an `Exception`, so it passes
   through uncaught. `ScheduleStateProvider.addTask` (`schedule_state_provider.dart:345`) awaits that
   call, so the throw propagates out of an unawaited future at `schedule_view.dart:109` — into a zone
   with no `runZonedGuarded` and no `PlatformDispatcher.onError` handler anywhere in `lib/`. The
   optimistic task stays on screen; nothing was written; nothing is logged (release logger is
   `NoOpLogger`). Violates the non-negotiable *"No silent failure."*

---

## 2. Standards Alignment Matrix

| Standard / Skill Guideline | Status | Evidence (File & Line) | Impact / Risk |
|---|---|---|---|
| **Non-negotiable:** Correctness of data over everything | ❌ **Non-Compliant** | `app_database.dart:94-369` has no `beforeOpen`; cascades declared at `tables.dart:20, 58, 72` | Orphaned `tasks`/`template_tasks` rows accumulate silently; DB grows and reports wrong counts |
| **Non-negotiable:** Migrations expand → backfill → contract, reversible | ⚠️ **Partial** | `app_database.dart:342-346` — unconditional `DELETE FROM day_plans` with no backup; `:311` backfill is correct | v8 duplicate-merge is irreversible; a bad merge destroys user schedule data with no rollback |
| **Non-negotiable:** Security is not a phase — validate at the boundary | ❌ **Non-Compliant** | `task_model.dart:42-51`; `plan_template_model.dart:30-37`; `todo_item_model.dart:87` (all `assert`) | Zero validation in release builds; malformed times crash `_parseTime`/`_toMinutes` downstream |
| **Non-negotiable:** No silent failure — never swallow | ❌ **Non-Compliant** | `local_schedule_repository.dart:50` (`on Exception` misses `Error`); `todo_detail_screen.dart:103-105`, `timer_view.dart:100-102` (`debugPrint`-and-drop); `alarm_scheduler_service.dart:123` (bare `catch (_) {}`) | Failed writes present as successes; empty catch at `:123` is explicitly called "a defect" by the standard |
| **Non-negotiable:** Evidence, not assertion | ✅ **Compliant** | `flutter analyze` clean; `flutter test` 36/36 green (both run during this audit) | — |
| **Non-negotiable:** Codebase stays coherent | ⚠️ **Partial** | `_wrap` duplicated verbatim at `local_schedule_repository.dart:43`, `local_template_repository.dart:16`, `local_todo_repository.dart:16`, `local_preference_repository.dart:13` | Four copies of the error taxonomy; a fix to one silently misses three |
| **design-judgment §2:** Rule of Three — extract on third occurrence | ❌ **Non-Compliant** | Same four `_wrap` sites above (4 occurrences, identical bodies) | Evidence threshold passed twice over; extraction is overdue, not premature |
| **design-judgment §6:** No dead code / speculative generality | ❌ **Non-Compliant** | `task_dto.dart` (111 lines) + `todo_item_dto.dart` (96 lines): **zero** references. `getRecurringTemplates` (`template_repository.dart:40` → `local_template_repository.dart:177-215` → `template_dao.dart:21-31`): never called. Also unused: `saveDayPlan` (`schedule_repository.dart:18`), `clearDay` (`:31`), `loadTodos` (`todo_repository.dart:7`), `BulkPreferenceRepository.getAll` (`preference_repository.dart:18`), `watchAllTemplates` (`template_dao.dart:34`), `watchTasksForDay` (`task_dao.dart:18`), `getDayPlansForWeek`/`updateDayPlan`/`deleteDayPlansForWeek` (`day_plan_dao.dart:13, 55, 60`), `CrashReportingLogger` (`logger.dart:71-86`), `NetworkFailure` (`result.dart:57`) | ~350 lines of maintained-but-unused surface. `NetworkFailure` in an offline-only app is textbook speculative generality |
| **testing-quality:** Test at the level the risk lives | ⚠️ **Partial** | Data/provider layers well covered (`local_schedule_repository_test.dart`, `schedule_state_provider_test.dart`). Presentation layer: **zero** — `test/widget_test.dart` is a 7-line stub | The optimistic-rollback + transient-error-snackbar UX (the app's most intricate logic) has no test at the level it actually fails |
| **testing-quality:** Every TODO has an owner and a reference | ❌ **Non-Compliant** | `test/widget_test.dart:6` — `// TODO: add widget tests with mock repositories` | Sole TODO in the codebase, unowned and unreferenced — "litter" by the standard's own wording |
| **testing-quality:** Regression test accompanies every bug fix | ⚠️ **Partial** | Migration regressions tested (`migration_test.dart:186`), but v1→v2, v2→v3, v3→v4, v5→v6 paths untested | Half the migration chain is unverified against real data shapes |
| **code-quality:** Function does one thing at one level of abstraction | ❌ **Non-Compliant** | `schedule_view.dart:210-747` — **537-line `build()`** with nested `LayoutBuilder`s and a closure-defined `buildDayCard` at `:293` | Unreviewable; a 2000-line PR "does not get reviewed, it gets approved" and this is one method |
| **code-quality:** Boolean params selecting behavior are a smell | ❌ **Non-Compliant** | `schedule_state_provider.dart:668-672` — `applyTemplate(template, [index, bool surfaceErrors = true])`; positional *and* boolean | Call site `applyTemplate(tmpl, i, false)` at `:737` is unreadable without opening the definition |
| **code-quality:** Push side effects to the edges | ❌ **Non-Compliant** | `schedule_view.dart:212` — `_consumeTransientError(provider)` invoked from inside `build()` | Side effect in a method Flutter may call at any time, any number of times |
| **code-quality:** No magic numbers | ⚠️ **Partial** | `7` hardcoded at `schedule_view.dart:414, 423` and `schedule_state_provider.dart:107`; `500` isolate threshold at `intelligence_service.dart:16`; `50` undo cap at `schedule_state_provider.dart:432` | Week length lives in three places; if any drifts, `weekPlan[index]` at `schedule_view.dart:294` throws `RangeError` |
| **code-quality:** Comment *why*; docs match reality | ⚠️ **Partial** | Excellent *why* comments (`main.dart:47-50`, `task_dao.dart:25-26`). But `app_database.dart:27` states **"Schema Version: 5"** while `:91` returns **8** | New contributors trust the doc header and reason about the wrong schema |
| **reliability-observability:** Structured logs w/ correlation id | ❌ **Non-Compliant** | `logger.dart:35-43` emits prose (`'[$level] $message'`), not key-values; no correlation/operation id; release build uses `NoOpLogger` (`main.dart:30`) | Cannot diagnose a production problem without shipping new code — the standard's stated bar |
| **reliability-observability:** Timeouts on everything external | ⚠️ **Partial** | `local_schedule_repository.dart:28-41` has retry with backoff (good, correctly bounded at 3) but no timeout on any DB call; `_audioPlayer.setFilePath` (`alarm_scheduler_service.dart:100`) unbounded | A wedged sqlite file lock hangs the load path with a spinner and no escape |
| **reliability-observability:** Background jobs idempotent, overlap-protected | ✅ **Compliant** | `task_dao.dart:27-34` uses `insertOnConflictUpdate`; `day_plan_dao.dart:43-52` uses `insertOrIgnore`; `getUpcomingDays` wraps read-create-read in a transaction (`local_schedule_repository.dart:63`) | Genuinely well done — retries are safe |
| **performance-efficiency:** No N+1 | ❌ **Non-Compliant** | `local_schedule_repository.dart:97-112` — `getTasksForDay` called once per day inside the loop (7 queries per load) | Bounded today at 7; the pattern is the defect, and it is the standard's #1 listed suspect |
| **performance-efficiency:** Work done per-request that could be done once | ❌ **Non-Compliant** | `schedule_view.dart:242` — `getSortedTasks()` copies and sorts the day's tasks on **every** rebuild (`schedule_state_provider.dart:316-324`) | O(n log n) per frame during any animation or hover |
| **performance-efficiency:** Virtualize long lists; keep work off main thread | ⚠️ **Partial** | `IntelligenceService.getEnergyPeaks` correctly offloads to `compute()` (`intelligence_service.dart:16-20`) — good. But zero `RepaintBoundary` in `lib/ui` (verified by grep) around 18 blur/shadow sites | Blur + shadow repaints propagate across the whole subtree on every state change |
| **stack-appendices §3:** Presentational components take data and callbacks | ⚠️ **Partial** | `task_card.dart`, `neo_button.dart`, `glass_container.dart` are clean. But `work_plan_detail_dialog.dart:37` and `focus_hud.dart:14` reach into `Provider.of<ScheduleStateProvider>` directly | Widgets are nominally, not genuinely, reusable |
| **stack-appendices §3:** Four async states — loading, empty, error, success | ⚠️ **Partial** | Schedule handles loading (`schedule_view.dart:214`) and error-with-retry (`:220-239`) — correct. `TodoProvider` surfaces `errorMessage` (`todo_list_view.dart:153`) but has **no retry affordance** | Todo stream failure leaves a dead-end error banner; user's only recovery is restarting the app |
| **stack-appendices §3:** i18n — keep strings out of components from day one | ❌ **Non-Compliant** | `main.dart:150-152` locks `supportedLocales` to `en_US`; every user-facing string is an inline literal (e.g. `schedule_view.dart:203`, `home_screen.dart:249`) | The standard calls this "the cheap seam"; retrofitting across ~7,900 UI lines will not be cheap |
| **stack-appendices §4 (Mobile):** Accessibility — screen reader, dynamic type, touch targets | ❌ **Non-Compliant** | Only **3** `Semantics(` wrappers in all of `lib/ui` (`home_screen.dart:401`, `schedule_view.dart:302`, `todo_list_view.dart`). No `Semantics` on task cards, sheets, dialogs, or timer controls; no reduced-motion check despite 18 blur/animation sites | App is largely unusable with a screen reader; `stack-appendices` §3 calls accessibility "a requirement, not an enhancement" |
| **stack-appendices §4 (Mobile):** Respect platform lifecycle, process death, restoration | ✅ **Compliant** | `home_screen.dart:49-58` handles `AppLifecycleState.resumed`; `main.dart:104-107` mirrors it via `onWindowFocus`; `main.dart:88-99` flushes state on window close with `preventClose` | Thoughtfully done on both desktop and mobile paths |
| **stack-appendices §4 (Mobile):** Store the minimum locally; keychain for sensitive data | ✅ **Compliant** | Unencrypted SQLite at `getApplicationDocumentsDirectory()` (`app_database.dart:372-388`) holds only user-authored planner content — no credentials, no PII beyond self-entered text | Appropriate to the data class; no secrets found anywhere in source |
| **stack-appendices §5:** CI on every commit — build, lint, test, scan | ❌ **Non-Compliant** | No `.github/` directory exists (verified) | Every gate in the standard is manual and therefore optional |
| **stack-appendices §5:** Pin versions with a lockfile | ✅ **Compliant** | `pubspec.lock` committed (30,257 bytes) | — |
| **stack-appendices §5:** Vet new dependencies; prefer stdlib | ⚠️ **Partial** | `pubspec.yaml:29-30` — `meta: any` and `sqlite3: any` are **unbounded** version constraints | An upstream breaking release enters the build unreviewed; contradicts the reproducible-build rule |
| **lifecycle-gates §3:** Record Consequential+ decisions (ADR) | ⚠️ **Partial** | `docs/ARCHITECTURE.md` exists and is substantial, but there is no decision record for Provider-over-Riverpod, Drift-over-Isar, or the singleton-database choice | The *winners* are visible in code forever; the rejected alternatives and their reasons have vanished |

---

## 3. Deep-Dive Gap Analysis & Findings

### 🔴 CRITICAL

---

#### C-1. Foreign-key enforcement is disabled — every declared `ON DELETE CASCADE` is inert

- **Location:** `lib/data/local/app_database.dart` (Lines 94–369, the entire `MigrationStrategy`);
  cascades declared at `lib/data/local/tables.dart:20, 58, 72`
- **Observation:** Three tables declare referential cascades — `Tasks.dayPlanId` → `DayPlans`
  (`tables.dart:19-20`), `TemplateActiveDays.templateId` → `PlanTemplates` (`:57-58`), and
  `TemplateTasks.templateId` → `PlanTemplates` (`:71-72`). Migration v5 went to the trouble of
  rebuilding `tasks` and `template_tasks` via `TableMigration` specifically to add them
  (`app_database.dart:236-241`, with the comment *"Recreate tasks and template_tasks with ON DELETE
  CASCADE"*). But SQLite defaults `PRAGMA foreign_keys` to **OFF on every new connection**, and
  Drift does not enable it automatically. A repository-wide grep for `foreign_keys` and `beforeOpen`
  returns **zero matches in `lib/`**. Every cascade in this schema is decorative.

  The code partly compensates by hand — `TemplateDao.deleteTemplate` (`template_dao.dart:53-57`)
  manually deletes child rows first — which is precisely the tell that the constraint isn't working,
  and it is applied inconsistently: nothing deletes `template_active_days` rows when a template is
  removed, and nothing cleans `tasks` when a `day_plan` row is deleted (as v8's merge does at
  `app_database.dart:342-346`).
- **Impact:** Silent, permanent data corruption. Deleting a template orphans its
  `template_active_days` rows forever; those orphans are read back by the `daysByTemplate` grouping
  in `getAllTemplates` (`local_template_repository.dart:51-54`), so a deleted template's recurrence
  days can resurrect against any template that reuses the id. Violates the standard's first
  non-negotiable and `stack-appendices.md` §2.
- **Remediation:**

  **Before** — `lib/data/local/app_database.dart:93-98`
  ```dart
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
  ```

  **After**
  ```dart
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        // SQLite defaults foreign_keys to OFF per connection. Without this the
        // ON DELETE CASCADE clauses in tables.dart are silently ignored and
        // deletes orphan their children. Enabled *after* migrations run, since
        // TableMigration's create-copy-drop-rename cycle trips FK checks.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (m, from, to) async {
  ```

  Then add a one-off orphan sweep as migration v9 and a regression test asserting that
  `DELETE FROM plan_templates` removes the matching `template_active_days` rows — the test must fail
  against the current code before the fix lands.

---

#### C-2. Every domain invariant is an `assert` and therefore absent from release builds

- **Location:** `lib/data/models/task_model.dart` (Lines 41–52), `lib/data/models/plan_template_model.dart`
  (Lines 29–38), `lib/data/models/todo_item_model.dart` (Lines 86–89)
- **Observation:** `Task`'s constructor body validates title length, `HH:mm` format via
  `RegExp(r'^([01]\d|2[0-3]):[0-5]\d$')`, and cost non-negativity — all with `assert`. Dart strips
  asserts in AOT/release compilation. In the shipped binary, `Task(title: '', startTime: '99:99',
  estimatedCost: -1.0)` constructs cleanly and is written straight to SQLite by
  `_modelTaskToCompanion` (`local_schedule_repository.dart:255-271`).

  Downstream consumers assume the invariant holds and degrade silently when it doesn't:
  `ScheduleStateProvider._toMinutes` (`schedule_state_provider.dart:280-286`) returns `0` for a
  malformed time, so a corrupt task becomes a midnight-to-midnight block that overlaps everything;
  `IntelligenceService._parseTime` (`intelligence_service.dart:63-70`) returns `null` and the task
  vanishes from analytics entirely. The database layer offers no backstop either — `Tasks.startTime`
  is a plain `text()()` (`tables.dart:9`) with no `CHECK` constraint.

  Note that `test/data/models/task_model_test.dart:46` ("Task validation asserts") passes only
  because the test runner enables asserts, so the suite actively creates false confidence here.
- **Impact:** Release builds have no input validation anywhere in the write path. This is the exact
  failure `security-privacy.md` names: *"Validate at the boundary, with an allowlist, into typed
  domain objects. Once inside, data is trusted because it was validated, not because it looked fine."*
- **Remediation:** Promote invariants to a real factory returning `Result`, and let the DB enforce
  what it can.

  **Before** — `lib/data/models/task_model.dart:28-52`
  ```dart
  Task({
    required this.id,
    required this.title,
    required this.startTime,
    // ...
  }) {
    assert(title.isNotEmpty && title.length <= 200,
        'Title must be 1-200 characters',);
    final timeRegex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    assert(
        timeRegex.hasMatch(startTime), 'Invalid startTime format: $startTime',);
    assert(timeRegex.hasMatch(endTime), 'Invalid endTime format: $endTime');
    assert(estimatedCost >= 0.0 && estimatedCost.isFinite,
        'estimatedCost must be >= 0.0 and finite',);
  }
  ```

  **After**
  ```dart
  static final _timeFormat = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// Unchecked constructor — only for values already known valid (DB reads).
  const Task.trusted({
    required this.id,
    required this.title,
    required this.startTime,
    // ...
  });

  /// Validating factory. Use for anything originating from the UI, an import,
  /// or a template. Enforced in release builds, unlike the previous asserts.
  static Result<Task> create({
    required String id,
    required String title,
    required String startTime,
    required String endTime,
    required TaskType type,
    double estimatedCost = 0.0,
    // ... remaining params
  }) {
    if (title.isEmpty || title.length > 200) {
      return const Failure(ValidationFailure('Title must be 1-200 characters'));
    }
    if (!_timeFormat.hasMatch(startTime)) {
      return Failure(ValidationFailure('Invalid start time: $startTime'));
    }
    if (!_timeFormat.hasMatch(endTime)) {
      return Failure(ValidationFailure('Invalid end time: $endTime'));
    }
    if (estimatedCost < 0.0 || !estimatedCost.isFinite) {
      return const Failure(ValidationFailure('Cost must be >= 0 and finite'));
    }
    return Success(Task.trusted(/* ... */));
  }
  ```

  Pair with a schema-level backstop in the next migration —
  `CHECK (length(title) BETWEEN 1 AND 200)` and
  `CHECK (start_time GLOB '[0-2][0-9]:[0-5][0-9]')` on `tasks` — so application-only validation
  never has to win alone. `ValidationFailure` (`result.dart:52`) already exists and is currently
  used only by tests; this gives it its intended job.

---

#### C-3. `StateError` bypasses the `Result` wrapper — a failed write is reported to the user as a success

- **Location:** `lib/data/repositories/local/local_schedule_repository.dart` (Lines 43–53, throws at
  101 and 136); propagates via `lib/providers/schedule_state_provider.dart:345-353` and
  `lib/ui/screens/schedule_view.dart:109`
- **Observation:** `_wrap` catches two types:
  ```dart
  } on DriftWrappedException catch (e) {   // :47
  } on Exception catch (e) {               // :50
  ```
  Dart's `Error` hierarchy does **not** implement `Exception`. The repository throws `StateError`
  in two places inside `_wrap`'s own body — `throw StateError('Day plan missing after insert for
  $date')` (`:101`) and `throw StateError('Failed to create day plan for $targetDate')` (`:136`) —
  and both sail straight through. `_retry` (`:28-41`) doesn't help either; it only catches
  `FileSystemException`.

  Trace the consequence for the most common write path. `_ensureDayPlanId` (`:122-139`) is called by
  `addTaskToDate` (`:146`). If the `INSERT OR IGNORE` at `:126` is ignored because a *different* row
  already claims that date under the v8 unique index, the re-read at `:134` returns `null` and
  `StateError` is thrown. `ScheduleStateProvider.addTask` awaits the call at `:345` — the throw
  aborts `addTask` before `result.fold` runs, so **the rollback at `:349` never executes and
  `_transientError` is never set**. The optimistic task added at `:341` remains on screen. The UI
  called `provider.addTask(task, date)` without awaiting (`schedule_view.dart:109`), so the error
  surfaces as an unhandled async error in a zone with **no `runZonedGuarded`, no
  `FlutterError.onError`, and no `PlatformDispatcher.onError`** (verified: zero matches in `lib/`),
  logged by a release-mode `NoOpLogger` (`main.dart:30`) that discards it.

  Net effect: **the user sees their task saved, it isn't, and no trace of the failure exists anywhere.**
- **Impact:** Silent data loss with positive user feedback — the worst possible failure shape. Directly
  violates *"No silent failure. Errors are handled, surfaced, or propagated — never swallowed."*
- **Remediation:** Widen the catch to `Object`, and install a global handler so nothing can vanish again.

  **Before** — `local_schedule_repository.dart:43-53`
  ```dart
  Future<Result<T>> _wrap<T>(Future<T> Function() action) async {
    try {
      final value = await _retry(action);
      return Success(value);
    } on DriftWrappedException catch (e) {
      return Failure(
          DatabaseFailure('Database operation failed', e.toString()),);
    } on Exception catch (e) {
      return Failure(UnknownFailure('Unexpected error', e.toString()));
    }
  }
  ```

  **After** (extract once and delete all four copies — see M-1). *Implementation note: this
  landed in `lib/data/repositories/local/db_guard.dart`, not `core/result.dart` — putting it in
  `core` would make the shared `Result` primitive import drift, inverting the
  volatile-depends-on-stable rule in `design-judgment.md` §3.*
  ```dart
  /// Runs [action], mapping any throwable into the [Result] taxonomy.
  ///
  /// Catches `Object`, not `Exception`: StateError/RangeError are `Error`s and
  /// would otherwise escape as unhandled async errors, skipping the caller's
  /// rollback entirely and losing the user's write with no trace.
  Future<Result<T>> guard<T>(
    Future<T> Function() action, {
    Logger? logger,
    String? operation,
  }) async {
    try {
      return Success(await action());
    } on DriftWrappedException catch (e, st) {
      logger?.error('DB failure in ${operation ?? "operation"}', e, st);
      return Failure(DatabaseFailure('Database operation failed', e.toString()));
    } catch (e, st) {
      logger?.error('Unexpected failure in ${operation ?? "operation"}', e, st);
      return Failure(UnknownFailure('Unexpected error', e.toString()));
    }
  }
  ```

  And in `lib/main.dart:26-31`:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final logger = kDebugMode ? const ConsoleLogger() : const CrashReportingLogger();

    // Nothing may fail silently: catch what escapes the widget tree and the
    // zone, including errors from unawaited futures in UI callbacks.
    FlutterError.onError = (details) =>
        logger.error('Flutter error', details.exception, details.stack);
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.error('Uncaught async error', error, stack);
      return true;
    };
    // ... rest of main
  ```

---

### 🟠 HIGH

---

#### H-1. Three models violate the `hashCode`/`==` contract

- **Location:** `lib/data/models/day_plan_model.dart` (Lines 55–65), `lib/data/models/todo_item_model.dart` (Lines 166–197), `lib/data/models/plan_template_model.dart` (Lines 234–251)
- **Observation:** `operator ==` compares tasks structurally with `listEquals(tasks, other.tasks)`
  (`:62`), but `hashCode` uses `tasks.hashCode` (`:65`) — which for a Dart `List` is **identity-based**.
  Two `DayPlan`s that are `==` will therefore have different hash codes whenever their task lists are
  distinct objects, which is always the case here: every mutation path builds a fresh list
  (`schedule_state_provider.dart:340, 370, 395, 698`).

  `TodoItem.hashCode` (`todo_item_model.dart:194`) has the same bug with `checklist.hashCode`
  versus `listEquals(checklist, ...)` at `:179`, and so does `PlanTemplate.hashCode`
  (`plan_template_model.dart:250-251`) on **both** `tasks` and `activeDays`. Only `Task` gets it
  right, by comparing scalar fields only.

  > **Correction (found during Phase 1 implementation):** this finding originally named two
  > affected types. `PlanTemplate` is a third. It was missed because the audit read that file for
  > its validation asserts and did not re-check its equality pair.
- **Impact:** `DayPlan` cannot be used in a `Set`, as a `Map` key, or in any hash-based
  memoization/diffing — lookups miss for objects that compare equal. It is a latent correctness trap
  for the exact refactor recommended in H-4.
- **Remediation:**

  **Before** — `day_plan_model.dart:64-65`
  ```dart
  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ tasks.hashCode;
  ```

  **After**
  ```dart
  // Object.hashAll over the elements, to match the listEquals in operator ==.
  // List.hashCode is identity-based, so the previous version produced different
  // hashes for objects that compare equal — breaking Set/Map membership.
  @override
  int get hashCode => Object.hash(id, date, Object.hashAll(tasks));
  ```

  Apply the same fix to `todo_item_model.dart:184-197` for `checklist`.

---

#### H-2. Two `TextEditingController` leaks in dialog builders

- **Location:** `lib/ui/screens/schedule_view.dart` (Lines 767–768) and
  `lib/ui/screens/work_plans_view.dart` (Lines 235–236)
- **Observation:** Both `_showSaveTemplateDialog` and `_showCreateTemplateDialog` allocate two
  `TextEditingController`s immediately before `showDialog` and never dispose them. Controllers are
  `ChangeNotifier`s holding listeners and, once attached to a `TextField`, native IME connections.
  Every dialog open leaks two.

  This contrasts with the rest of the codebase, which handles the same thing correctly everywhere
  else — `add_task_sheet.dart:77-81`, `new_item_sheet.dart:60-65`, `todo_detail_screen.dart:60-66`,
  and `todo_list_view.dart:27-29` all dispose properly. So this is a local lapse against an
  otherwise-followed convention, not an unknown pattern.
- **Impact:** Unbounded memory growth in a long-running desktop session — precisely the profile of
  this app, which is designed to stay open across midnight (`main.dart:101-107`).
- **Remediation:**

  **Before** — `schedule_view.dart:767-770`
  ```dart
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  showDialog(
    context: context,
  ```

  **After**
  ```dart
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  // Dialog controllers outlive the builder; dispose when the route pops.
  unawaited(
    showDialog(
      context: context,
      // ... unchanged builder
    ).whenComplete(() {
      nameCtrl.dispose();
      descCtrl.dispose();
    }),
  );
  ```

  The cleaner long-term fix is to promote both dialogs to `StatefulWidget`s (mirroring
  `_WeekSearchDialog`, already used at `schedule_view.dart:752`) so `dispose()` is structural rather
  than remembered.

---

#### H-3. `TodoProvider`'s stream-error retry survives `dispose()` and resurrects cancelled subscriptions

- **Location:** `lib/providers/todo_provider.dart` (Lines 148–162)
- **Observation:**
  ```dart
  void _handleStreamError(String type, dynamic error) {
    _errorMessage = 'Error loading $type: $error';
    notifyListeners();
    // Recovery: retry subscription after delay
    Future.delayed(const Duration(seconds: 5), _subscribe);   // :152
  }
  ```
  The delayed callback is neither stored nor cancellable, and `dispose()` (`:155-162`) cancels the
  four subscriptions but cannot cancel this. If a stream errors and the provider is disposed within
  the following five seconds, `_subscribe` runs on a dead object: it re-establishes all four
  subscriptions (`:115-145`) — which now leak, since `dispose` has already run and will not run
  again — and each will call `notifyListeners()` on a disposed `ChangeNotifier`, which throws
  `FlutterError: A TodoProvider was used after being disposed`.

  There is also no backoff or attempt cap: a persistently failing stream retries every 5 s forever.
  `reliability-observability.md` requires *"Retries with exponential backoff and jitter, bounded
  attempts."* `AlarmSchedulerService` shows the team knows the pattern — it tracks `_disposed`
  (`alarm_scheduler_service.dart:33`) and guards `_fire` with it (`:89`).
- **Impact:** Crash plus subscription leak on a real interleaving. The existing test
  `'dispose cancels all stream subscriptions'` (`todo_provider_test.dart:39`) does not cover it
  because it never errors a stream first.
- **Remediation:**

  **Before** — `todo_provider.dart:148-162`
  ```dart
  void _handleStreamError(String type, dynamic error) {
    _errorMessage = 'Error loading $type: $error';
    notifyListeners();
    // Recovery: retry subscription after delay
    Future.delayed(const Duration(seconds: 5), _subscribe);
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    _timersSub?.cancel();
    _listsSub?.cancel();
    _alarmsSub?.cancel();
    super.dispose();
  }
  ```

  **After**
  ```dart
  static const int _maxRetries = 5;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  bool _disposed = false;

  void _handleStreamError(String type, Object error) {
    if (_disposed) return;
    _errorMessage = 'Error loading $type: $error';
    notifyListeners();

    if (_retryAttempt >= _maxRetries) return;   // bounded, per reliability standard
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s. Held in a cancellable Timer so
    // dispose() can stop it — an uncancellable Future.delayed would resubscribe
    // on a disposed notifier and leak all four subscriptions.
    final delay = Duration(seconds: 1 << _retryAttempt);
    _retryAttempt++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!_disposed) _subscribe();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _notesSub?.cancel();
    _timersSub?.cancel();
    _listsSub?.cancel();
    _alarmsSub?.cancel();
    super.dispose();
  }
  ```

  Reset `_retryAttempt = 0` inside each successful `onData` handler. Add a `retry()` public method
  and wire it to a button in the `todo_list_view.dart:153-160` error banner, which currently offers
  no recovery path (see the four-async-states row in §2).

---

#### H-4. A 537-line `build()` with unscoped provider subscription and per-frame sorting

- **Location:** `lib/ui/screens/schedule_view.dart` (Lines 210–747); supporting evidence at
  `schedule_state_provider.dart:316-324`, `home_screen.dart:121-124`
- **Observation:** Three compounding problems in one method.

  1. **Size.** `build()` spans 537 lines, containing two nested `LayoutBuilder`s, a closure-defined
     `buildDayCard` (`:293-408`) with ~115 lines of decoration logic, an inline `Stack` of ambient
     blur decorations (`:247-276`), and the toolbar/task-list/detail-panel composition. The standard's
     rule — *"A function does one thing at one level of abstraction"* — is not close to met.
  2. **Rebuild scope.** `:211` does `Provider.of<ScheduleStateProvider>(context)` with default
     `listen: true` and no `Selector`. A repo-wide grep finds **zero** `Selector<` usages in `lib/ui`.
     `ScheduleStateProvider` calls `notifyListeners()` at 20 distinct sites; each one re-executes all
     537 lines. Because `home_screen.dart:121-124` mounts all four screens in an `IndexedStack`, and
     `analytics_view.dart:58-59`, `work_plans_view.dart:17`, and `focus_hud.dart:14` also subscribe
     unscoped, **a single task toggle rebuilds four screens' full widget trees.**
  3. **Work in build.** `:242` calls `provider.getSortedTasks(dayPlan)`, which copies the list and
     sorts it (`schedule_state_provider.dart:316-324`) — O(n log n) allocation on every frame. And
     `:212` calls `_consumeTransientError(provider)`, a *side effect* (it schedules a post-frame
     callback that shows a `SnackBar`) from inside a method Flutter may call arbitrarily often.

  There are also **zero `RepaintBoundary`s** in `lib/ui` despite 18 blur/shadow sites, including two
  300×300 `ImageFilter.blur(sigma: 60)` circles at `:247-276` that repaint with the whole subtree.
- **Impact:** Jank on every interaction on mid-tier hardware; unreviewable code (`lifecycle-gates.md`
  §7: *"Reviewability is a feature"*); and a side effect in `build()` that will misfire the moment
  Flutter rebuilds for a reason other than a state change (theme, media query, hot reload).
- **Remediation:**

  **Before** — `schedule_view.dart:209-242`
  ```dart
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleStateProvider>(context);
    _consumeTransientError(provider);

    if (provider.isLoading) { /* ... */ }
    if (provider.errorMessage != null) { /* ...537 lines total... */ }

    final dayPlan = provider.selectedDay;
    final sortedTasks = provider.getSortedTasks(dayPlan);
    return Stack(children: [ /* ~500 lines inline */ ]);
  }
  ```

  **After** — split by rebuild scope, hoist the side effect into a lifecycle hook
  ```dart
  @override
  void initState() {
    super.initState();
    // Side effects belong in lifecycle hooks, not build(): build may run for
    // reasons unrelated to state (theme, media query, hot reload).
    context.read<ScheduleStateProvider>().addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    context.read<ScheduleStateProvider>().removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() =>
      _consumeTransientError(context.read<ScheduleStateProvider>());

  @override
  Widget build(BuildContext context) {
    // Selector: only the status band rebuilds when loading/error flip.
    return Selector<ScheduleStateProvider, _ScheduleStatus>(
      selector: (_, p) => _ScheduleStatus(p.isLoading, p.errorMessage),
      builder: (context, status, _) {
        if (status.isLoading) return const _ScheduleLoading();
        if (status.error != null) {
          return _ScheduleError(
            message: status.error!,
            onRetry: context.read<ScheduleStateProvider>().loadData,
          );
        }
        return const Stack(
          children: [
            RepaintBoundary(child: _AmbientGlowBackdrop()), // static; isolate its layer
            Column(
              children: [
                _DaySelectorStrip(),   // Selector on (weekPlan summary, selectedDayIndex)
                _ScheduleHeader(),     // Selector on selectedDay date only
                Expanded(child: _TaskListArea()),  // Selector on sorted tasks
              ],
            ),
          ],
        );
      },
    );
  }
  ```

  And memoize the sort in the provider so it is computed on mutation, not on paint:

  **Before** — `schedule_state_provider.dart:316-324`
  ```dart
  List<Task> getSortedTasks(DayPlan dayPlan) {
    final tasks = List<Task>.from(dayPlan.tasks);
    tasks.sort((a, b) => _sortOrder == SortOrder.asc
        ? a.startTime.compareTo(b.startTime)
        : b.startTime.compareTo(a.startTime),);
    return tasks;
  }
  ```

  **After**
  ```dart
  final Map<String, List<Task>> _sortedCache = {};

  /// Sorted tasks for [dayPlan], memoized. Invalidated by every mutation and by
  /// [toggleSortOrder]; previously this sorted on every frame from build().
  List<Task> getSortedTasks(DayPlan dayPlan) {
    return _sortedCache.putIfAbsent(dayPlan.id, () {
      final tasks = List<Task>.from(dayPlan.tasks);
      tasks.sort((a, b) => _sortOrder == SortOrder.asc
          ? a.startTime.compareTo(b.startTime)
          : b.startTime.compareTo(a.startTime),);
      return List.unmodifiable(tasks);
    });
  }

  void _invalidateSortCache([String? dayPlanId]) =>
      dayPlanId == null ? _sortedCache.clear() : _sortedCache.remove(dayPlanId);
  ```

---

#### H-5. Zero widget and integration test coverage across ~7,900 lines of presentation code

- **Location:** `test/widget_test.dart` (Lines 1–7, entire file); absence of `integration_test/`
- **Observation:** The suite is 36 tests, all passing, and the tests that exist are good ones — they
  use `mocktail` for repository doubles and real in-memory Drift databases for persistence
  (`local_schedule_repository_test.dart`, `migration_test.dart`), which is exactly the standard's
  guidance that *"a 'unit' test that mocks the database to test a query proves nothing."*

  But every one of them targets `core/`, `data/`, or `providers/`. `lib/ui/` — 7,899 lines across 13
  files — has zero coverage. `test/widget_test.dart` in its entirety:
  ```dart
  // Placeholder test — the default counter test doesn't apply to Chronos.
  // The app now requires database-backed repositories, so widget tests need
  // proper test setup with mock repositories.

  void main() {
    // TODO: add widget tests with mock repositories
  }
  ```
  This is also the codebase's only `TODO`, unowned and unreferenced —
  `testing-quality.md`: *"Every TODO has an owner and a reference, or it's not a TODO — it's litter."*

  Coverage gaps that matter most, ranked by where the risk actually lives:
  - The **optimistic-update-and-rollback** cycle end-to-end. `schedule_state_provider_test.dart:97`
    tests rollback at the provider level, but nothing verifies the user-visible half:
    `takeTransientError` (`schedule_state_provider.dart:72-76`) is read-and-clear, so if the
    post-frame callback in `_consumeTransientError` (`schedule_view.dart:195-206`) fires while
    unmounted, the error is consumed and discarded with no snackbar. Untested.
  - The **overlap warning** logic (`schedule_view.dart:103-189`), including the overnight
    normalization at `schedule_state_provider.dart:305, 311`.
  - The **alarm ring/dismiss overlay** (`home_screen.dart:82-92`, `_AlarmRingingOverlay:178-259`) —
    the app's only real-time, user-blocking UI.
  - **Migration chain gaps:** `migration_test.dart` covers v4→v5, v6→v7, and v7→v8. The v1→v2,
    v2→v3, v3→v4, and v5→v6 steps (`app_database.dart:99-128, 129-167, 277-298`) are unverified —
    and v5→v6's `TableMigration` calls are destructive rebuilds.
- **Impact:** Any refactor of the presentation layer — including every fix in this report — is
  unverifiable. The standard's stated purpose of tests is *"confidence to change"*; that confidence
  currently stops at the provider boundary, which is exactly where this codebase's complexity begins.
- **Remediation:** Replace the placeholder with a real harness. This one test would have caught
  the C-3 silent-failure class:

  **Before** — `test/widget_test.dart` (whole file, 7 lines)

  **After**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:mocktail/mocktail.dart';
  import 'package:provider/provider.dart';

  import 'package:chronosky/core/result.dart';
  import 'package:chronosky/core/services/logger.dart';
  import 'package:chronosky/providers/schedule_state_provider.dart';
  import 'package:chronosky/ui/screens/schedule_view.dart';
  import 'helpers/mocks.dart'; // MockScheduleRepository et al., shared with provider tests

  void main() {
    testWidgets(
      'failed task write rolls back the optimistic row and shows a retry snackbar',
      (tester) async {
        final repo = MockScheduleRepository();
        when(() => repo.getUpcomingDays(any()))
            .thenAnswer((_) async => Success(sevenEmptyDays()));
        when(() => repo.addTaskToDate(any(), any())).thenAnswer(
          (_) async => const Failure(DatabaseFailure('disk full')),
        );

        final provider = ScheduleStateProvider(
          scheduleRepo: repo,
          templateRepo: MockTemplateRepository(),
          prefRepo: MockPreferenceRepository(),
          logger: const NoOpLogger(),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: provider, child: const ScheduleView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await provider.addTask(taskFixture(title: 'Deep Work'));
        await tester.pumpAndSettle();

        // Rollback happened: the optimistic row is gone.
        expect(find.text('Deep Work'), findsNothing);
        // And the failure was surfaced, not swallowed.
        expect(find.textContaining("Couldn't save"), findsOneWidget);
      },
    );
  }
  ```

---

#### H-6. No CI pipeline — every quality gate in the standard is optional

- **Location:** Repository root — no `.github/` directory exists (verified by `ls`)
- **Observation:** `flutter analyze` is clean and `flutter test` is green *today*, because this audit
  ran them by hand. Nothing enforces that on any commit. `stack-appendices.md` §5 requires *"CI on
  every commit: build, lint, typecheck, test, security scan, artifact build."* There is also no
  `dart format --set-exit-if-changed` gate, no dependency audit step, and no coverage reporting — so
  the H-5 gap has no ratchet preventing it from widening.
- **Impact:** The strong lint configuration in `analysis_options.yaml:15-28` (which enables
  `avoid_dynamic_calls`, `cancel_subscriptions`, `close_sinks`, `unawaited_futures` — genuinely good
  choices) is enforced only when a developer remembers to look.
- **Remediation:** Add `.github/workflows/ci.yaml`:
  ```yaml
  name: CI
  on: [push, pull_request]

  jobs:
    verify:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: subosito/flutter-action@v2
          with: { channel: stable }
        - run: flutter pub get
        - run: dart format --output=none --set-exit-if-changed .
        - run: flutter analyze --fatal-infos --fatal-warnings
        - run: flutter test --coverage
        - uses: actions/upload-artifact@v4
          with: { name: coverage, path: coverage/lcov.info }
        # Fails the build if generated Drift code drifts from tables.dart —
        # a stale .g.dart is otherwise invisible until runtime.
        - run: dart run build_runner build --delete-conflicting-outputs
        - run: git diff --exit-code -- '*.g.dart'
  ```

---

### 🟡 MEDIUM

---

#### M-1. `_wrap` duplicated verbatim across four repositories

- **Location:** `local_schedule_repository.dart:43-53`, `local_template_repository.dart:16-26`,
  `local_todo_repository.dart:16-26`, `local_preference_repository.dart:13-23`
- **Observation:** Four byte-identical implementations of the error-taxonomy mapping (modulo the
  schedule variant's `_retry` wrapper). `design-judgment.md` §2 sets the bar precisely: *"Rule of
  Three, applied honestly: first occurrence — write it. Second — duplicate it, note it. Third — now
  you have evidence of the shape; extract."* This is the fourth. Every gate passes: two-plus concrete
  cases (Gate 1), same reason to change — the error taxonomy (Gate 2), stable axis (Gate 3), fewer
  concepts across call sites (Gate 4), survives a fifth repository unchanged (Gate 5).

  The C-3 defect is a direct consequence: the `on Exception` bug exists in all four copies and would
  need four separate fixes.
- **Impact:** Divergence risk on the app's single most safety-critical helper.
- **Remediation:** Extract to a shared `guardDb<T>` in the data layer (full implementation given
  under C-3) and delete all four private copies. `local_schedule_repository.dart` keeps its
  `_retry` (`:28-41`) as a composed inner call: `guard(() => _retry(action))`.

---

#### M-2. Roughly 350 lines of dead code, including two entire DTO files

- **Location:** `lib/data/models/task_dto.dart` (111 lines), `lib/data/models/todo_item_dto.dart`
  (96 lines) — **zero** references anywhere in `lib/` or `test/`. Plus, all unreferenced:
  `getRecurringTemplates` (`template_repository.dart:40` + `local_template_repository.dart:177-215`
  + `template_dao.dart:21-31`, ~50 lines), `saveDayPlan` (`schedule_repository.dart:18` +
  `local_schedule_repository.dart:170-181`), `clearDay` (`schedule_repository.dart:31` +
  `local_schedule_repository.dart:212-216`), `loadTodos` (`todo_repository.dart:7` +
  `local_todo_repository.dart:29-34`), `BulkPreferenceRepository.getAll`
  (`preference_repository.dart:16-19` + `local_preference_repository.dart:41-43` +
  `preference_dao.dart:36-39`), `watchAllTemplates` (`template_dao.dart:34-36`),
  `watchTasksForDay` (`task_dao.dart:18-23`), `getDayPlansForWeek`/`updateDayPlan`/
  `deleteDayPlansForWeek` (`day_plan_dao.dart:13, 55, 60`), `CrashReportingLogger`
  (`logger.dart:71-86`, all four methods empty), `NetworkFailure` (`result.dart:57-59`)
- **Observation:** The DTOs are the most striking: `TaskDto` carries a `schemaVersion` field
  (`task_dto.dart:5, 21`) and full `fromDomain`/`toDomain`/`toJson` round-tripping for a serialization
  boundary that does not exist — the repositories map domain models directly to Drift companions
  (`local_schedule_repository.dart:255-271`). `NetworkFailure` in an app with no network dependency
  in `pubspec.yaml` is the canonical *"interface with one implementation; config nobody sets"* tell
  from `design-judgment.md` §6.

  `getRecurringTemplates` is a near-verbatim copy of `getAllTemplates` (compare
  `local_template_repository.dart:29-67` against `:177-215`) that nothing calls, because
  `ScheduleStateProvider._applyRecurringTemplates` (`schedule_state_provider.dart:722`) filters the
  already-loaded `_templates` list in memory instead.
- **Impact:** Every reader must determine whether each is load-bearing; every refactor must keep it
  compiling. `CrashReportingLogger` is worse than dead — it is a *trap*: it looks like production
  crash reporting and silently reports nothing.
- **Remediation:** Delete all of the above. `git` remembers them. For `CrashReportingLogger`
  specifically, either implement it against a real backend (it is the natural fix for C-3's
  observability half) or delete it — the current stub is a lie in the type system.

---

#### M-3. Release builds have no observability: `NoOpLogger`, prose logs, no correlation id

- **Location:** `lib/main.dart:30`; `lib/core/services/logger.dart:35-53, 57-68`
- **Observation:** `final logger = kDebugMode ? const ConsoleLogger() : const NoOpLogger();`
  In every shipped build, all 20+ `_logger.error/warning` calls across the codebase — including
  `'Failed to persist recurring dismissals'` (`schedule_state_provider.dart:273`), which the code's
  own comment (`:404-405`) says *"reads as data corruption to the user"* — discard their payload.

  Even in debug, `ConsoleLogger._log` (`logger.dart:35-43`) emits interpolated prose
  (`'[$level] $message'`) rather than structured key-values, with no correlation id, operation name,
  or principal. `reliability-observability.md` states the bar plainly: *"you can diagnose a novel
  production problem without shipping new code."*

  Separately, `MigrationHelper` bypasses the abstraction entirely, using `debugPrint` at
  `migration_helper.dart:25, 40, 42, 95, 136` — and swallows the migration failure at `:41-44` with
  only a debug print, meaning a failed SharedPreferences→Drift migration is invisible in production.
  That file also imports `package:flutter/material.dart` (`:4`) into a data-layer class purely to
  reach `debugPrint` — a layering violation with a trivial fix.
- **Impact:** Zero production diagnosability. Combined with C-3, failures are both silent to the user
  and invisible to the developer.
- **Remediation:** Ship a real logger in release, make records structured, and inject it into
  `MigrationHelper`:
  ```dart
  // logger.dart — structured records instead of interpolated prose
  void _log(
    String level,
    String message, {
    String? operation,
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      jsonEncode({
        'ts': DateTime.now().toUtc().toIso8601String(),
        'level': level,
        'op': operation,
        'msg': message,
        ...fields,
      }),
      name: 'chronos',
      error: error,
      stackTrace: stackTrace,
      level: _levelToValue(level),
    );
  }
  ```
  ```dart
  // migration_helper.dart — inject the Logger; drop the material.dart import
  static Future<void> migrateIfNeeded(AppDatabase db, Logger logger) async {
    // ...
    } catch (e, st) {
      // Not setting the migrated flag means we retry next launch — but a
      // permanent failure would otherwise loop forever unobserved.
      logger.error('SharedPreferences to Drift migration failed', e, st);
    }
  }
  ```

---

#### M-4. The v8 duplicate-merge migration is destructive and irreversible

- **Location:** `lib/data/local/app_database.dart` (Lines 315–367, specifically 329–346)
- **Observation:** Migration v8 reparents tasks off duplicate `day_plans` rows and then executes:
  ```dart
  await customStatement(
    'DELETE FROM day_plans WHERE rowid NOT IN ('
    '  SELECT MIN(rowid) FROM day_plans GROUP BY date'
    ')',
  );
  ```
  The intent is sound and the reparenting `UPDATE` at `:329-341` is carefully written. But the
  standard requires migrations be *"expand → backfill → contract, each independently deployable and
  reversible"* and *"reversible or provably safe."* This is contract-without-expand: rows are
  destroyed in the same step that creates the constraint, with no shadow table, no backup copy, and
  no down path. If the reparenting `UPDATE` misses any row — for instance because
  `PRAGMA foreign_keys` is off (**C-1**) and a task references a `day_plan_id` that no longer resolves
  — those tasks are orphaned and their day rows are then deleted.

  The step *is* covered by a test (`migration_test.dart:186`), which is genuinely better than most
  codebases manage. But the test exercises the happy shape, not a partially-corrupt one.
- **Impact:** A user upgrading with unusual data has no recovery path. This is the highest-blast-radius
  irreversible decision in the codebase.
- **Remediation:** Copy before you contract.
  ```dart
  if (from < 8) {
    // Snapshot before the destructive merge. Cheap (day_plans is ~7 rows/week)
    // and the only rollback path if reparenting misses a row.
    await customStatement(
      'CREATE TABLE IF NOT EXISTS day_plans_backup_v7 AS SELECT * FROM day_plans',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS tasks_backup_v7 AS SELECT * FROM tasks',
    );

    // ... existing reparent UPDATE at :329-341 ...

    // Fail closed rather than deleting rows that still own tasks.
    final orphaned = await customSelect(
      'SELECT COUNT(*) AS cnt FROM tasks t '
      'LEFT JOIN day_plans d ON t.day_plan_id = d.id WHERE d.id IS NULL',
    ).getSingle();
    if (orphaned.read<int>('cnt') > 0) {
      throw StateError(
        'v8 migration aborted: ${orphaned.read<int>('cnt')} orphaned tasks. '
        'Data preserved in day_plans_backup_v7 / tasks_backup_v7.',
      );
    }

    // ... existing DELETE + index creation ...
  }
  ```
  Add a migration test that seeds an orphaned task and asserts the migration aborts with data intact.

---

#### M-5. `AlarmSchedulerService` cannot fire when the app is not running

- **Location:** `lib/core/services/alarm_scheduler_service.dart` (Lines 50–76, 88–117)
- **Observation:** Alarms are armed with a single in-process `Timer` (`:74`). The service is honest
  about its scope in its own doc comment (*"while the app is running"*, `:12`) and handles the missed
  case deliberately: alarms more than `_missedGrace` = 1 minute stale are silently disarmed (`:27, 59`).
  That is a defensible product decision, clearly documented. Three engineering gaps remain:

  1. **No OS-level scheduling.** `pubspec.yaml` has no `flutter_local_notifications` or platform
     alarm-manager dependency, so a closed app misses every alarm permanently — the one-shot disarm
     at `:96` means it never fires later either.
  2. **Machine sleep.** Desktop suspend/resume across a trigger time lands in the `>1 minute stale`
     branch and silently disarms. `stack-appendices.md` §4: *"Respect the platform's lifecycle."*
  3. **Post-`await` disposal.** `_fire` checks `_disposed` at `:89` but then `await`s `_disarm`
     (`:96`) and audio setup (`:100-102`); `notifyListeners()` at `:92` and the window-focus calls at
     `:111-112` are not re-guarded. Disposal during those awaits throws.

  Also, audio failure is caught and logged as a warning (`:103-105`), so the overlay appears with no
  sound — a silent degradation the user cannot distinguish from a volume problem.
- **Impact:** An alarm feature that misses alarms is worse than no alarm feature, because users build
  trust in it.
- **Remediation:** Short term, re-guard and surface the audio failure:
  ```dart
  Future<void> _fire(domain.TodoItem alarm) async {
    if (_disposed) return;
    _ringing = alarm;
    notifyListeners();
    await _disarm(alarm);
    if (_disposed) return;   // disposal can occur across the await above

    if (alarm.audioFilePath.isNotEmpty) {
      if (!await File(alarm.audioFilePath).exists()) {
        // Surface it: a silent alarm is indistinguishable from a broken one.
        _logger.warning('Alarm audio missing: ${alarm.audioFilePath}');
        _audioMissing = true;
        notifyListeners();
      } else {
        try { /* ... existing play ... */ } catch (e) { /* ... */ }
      }
    }
    // ...
  }
  ```
  Medium term, add `flutter_local_notifications` and schedule at the OS level so the alarm survives
  app closure — treating the in-process `Timer` as the foreground fast path only. Record this as a
  Consequential decision per `design-judgment.md` §7, since it adds a permanent dependency.

---

#### M-6. N+1 read in `getUpcomingDays`

- **Location:** `lib/data/repositories/local/local_schedule_repository.dart` (Lines 96–112)
- **Observation:**
  ```dart
  for (int i = 0; i < count; i++) {
    final date = today.add(Duration(days: i));
    final existing = findByDate(dbPlans, date);
    // ...
    final dbTasks = await _taskDao.getTasksForDay(existing.id);   // :103
  ```
  One `SELECT` per day inside the loop — seven round-trips where one `WHERE day_plan_id IN (...)`
  suffices. `performance-efficiency.md` lists N+1 first among *"the usual suspects, in order of
  frequency"* and directs: *"Fix by batching or joining."*

  Note `findByDate` (`:64-71`) is also O(n) per call inside the same loop, making the lookup O(n²),
  and `getUpcomingDays` is called on every date rollover and every retry
  (`schedule_state_provider.dart:107`).
- **Impact:** Bounded at 7 today, so the runtime cost is small — but the standard's point is that
  this is a *design* defect, not a tuning question, and it is the pattern the codebase will copy when
  a month view arrives.
- **Remediation:**

  **Before** — `:96-112` (one query per day, O(n) lookup per iteration)

  **After**
  ```dart
  // Single batched read + O(1) grouping, replacing 7 sequential queries and an
  // O(n) findByDate scan per iteration.
  final planIds = [for (final p in dbPlans) p.id];
  final allTasks = await (_taskDao.select(_taskDao.tasks)
        ..where((t) => t.dayPlanId.isIn(planIds)))
      .get();

  final tasksByPlan = <String, List<domain.Task>>{};
  for (final t in allTasks) {
    tasksByPlan.putIfAbsent(t.dayPlanId, () => []).add(_dbTaskToModel(t));
  }
  final plansByDate = {
    for (final p in dbPlans) DateTime(p.date.year, p.date.month, p.date.day): p,
  };

  final List<domain.DayPlan> fullList = [];
  for (int i = 0; i < count; i++) {
    final date = today.add(Duration(days: i));
    final existing = plansByDate[date];
    if (existing == null) {
      throw StateError('Day plan missing after insert for $date');
    }
    fullList.add(
      domain.DayPlan(
        id: existing.id,
        date: existing.date,
        tasks: (tasksByPlan[existing.id] ?? [])
          ..sort((a, b) => a.startTime.compareTo(b.startTime)),
      ),
    );
  }
  ```
  (`local_template_repository.dart:29-67` already does exactly this grouping pattern — this change
  makes the schedule repository consistent with an existing good local convention, per
  `lifecycle-gates.md` §2: *"matching an existing good pattern beats introducing a better one."*)

---

#### M-7. Accessibility is largely absent

- **Location:** `lib/ui/` — only three `Semantics(` wrappers exist: `home_screen.dart:401`,
  `schedule_view.dart:302`, and one in `todo_list_view.dart`
- **Observation:** The three that exist are well written — `schedule_view.dart:302-306` builds a
  genuinely useful label (`'${day.dayOfWeek}, ${day.dateStr}, $completedCount of ${day.tasks.length}
  tasks completed'`), which shows the team knows how. But `task_card.dart` (445 lines),
  `task_detail_panel.dart` (852), `add_task_sheet.dart` (837), `new_item_sheet.dart` (628),
  `timer_view.dart` (264), `work_plan_detail_dialog.dart` (404) and the alarm overlay
  (`home_screen.dart:178-259`) have none. Icon-only `IconButton`s (e.g. `todo_detail_screen.dart:168`,
  `:174`) carry no tooltip or semantic label. There is no `MediaQuery.disableAnimations` /
  reduced-motion check despite 18 blur and animation sites, and no dynamic-type handling — font sizes
  are hardcoded throughout (`schedule_view.dart:355, 369, 445, 455`).

  `stack-appendices.md` §3: *"Accessibility is a requirement, not an enhancement."* §4 adds:
  *"platform screen reader support, dynamic type, touch targets, contrast."*
- **Impact:** The app is effectively unusable with a screen reader, and the heavy blur/motion design
  is hostile to users with vestibular sensitivity, with no opt-out.
- **Remediation:** Start with the highest-traffic interactive surfaces and the motion opt-out:
  ```dart
  // task_card.dart — wrap the tappable card
  return Semantics(
    button: true,
    label: '${task.title}, ${task.startTime} to ${task.endTime}, '
        '${task.type.name}, ${task.completed ? "completed" : "not completed"}',
    onTapHint: 'Open task details',
    child: /* existing card */,
  );
  ```
  ```dart
  // glass_container.dart / analytics_view.dart — respect the OS motion setting
  final reduceMotion = MediaQuery.of(context).disableAnimations;
  final duration = reduceMotion ? Duration.zero : AppAnimDurations.slow;
  ```
  Add accessibility guideline checks (`meetsGuideline(textContrastGuideline)`,
  `androidTapTargetGuideline`) to the widget-test harness from H-5 so this cannot regress once fixed.

---

#### M-8. `AppDatabase` singleton is never closed and has no test seam at the composition root

- **Location:** `lib/data/local/app_database.dart` (Lines 76–88); `lib/main.dart:54`, `:88-99`
- **Observation:** `AppDatabase.instance` (`:85-88`) is a lazily-initialized mutable static with no
  reset, and a grep for `.close()` across `lib/` returns nothing. The desktop close handler
  (`main.dart:88-99`) carefully flushes provider state via `flushState()` but never closes the
  database before `windowManager.destroy()`, so SQLite's WAL is not checkpointed on a clean exit.

  The class does provide `AppDatabase.forTesting` (`:79-80`, correctly marked `@visibleForTesting`)
  and the tests use it — good. But `main.dart:54` reaches for the global singleton directly, so the
  composition root has no seam: `main()` cannot be exercised against an in-memory database, which is
  part of why there is no app-level integration test.

  `design-judgment.md` §4 lists *"Persistence, when the storage choice is plausibly not final"*
  among the boundaries where a seam *"pays off almost every time."*
- **Impact:** Unclean shutdown risks WAL growth and, on abrupt termination, recovery on next launch.
  The missing seam blocks integration testing of startup + migration together — the single riskiest
  path in the app.
- **Remediation:**
  ```dart
  // main.dart — accept an injected database so main() is testable end-to-end
  Future<void> main() async => bootstrap();

  @visibleForTesting
  Future<void> bootstrap({AppDatabase? database}) async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = database ?? AppDatabase.instance;
    // ...
  }
  ```
  ```dart
  // main.dart:88-99 — checkpoint WAL before the process exits
  @override
  void onWindowClose() async {
    if (await windowManager.isPreventClose()) {
      try {
        await stateProvider.flushState();
        await db.close();   // checkpoints the WAL; a clean exit otherwise leaves one
      } finally {
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
      }
    }
  }
  ```

---

#### M-9. Unbounded dependency constraints break build reproducibility

- **Location:** `pubspec.yaml` (Lines 29–30)
- **Observation:**
  ```yaml
    meta: any
    sqlite3: any
  ```
  Every other dependency is properly caret-pinned. `sqlite3: any` is the notable one — it is the
  native engine backing all persistence, transitively pulled by `drift`/`sqlite3_flutter_libs`, and
  `any` permits a major version bump into the build without review.

  `security-privacy.md`: *"Pin versions with a lockfile; builds must be reproducible"* and *"A new
  dependency is a permanent liability and a Consequential decision."* The committed `pubspec.lock`
  protects the current checkout but not a fresh `pub upgrade`.
- **Impact:** An upstream breaking change enters the data layer unreviewed.
- **Remediation:**
  ```yaml
    # Pinned to the versions resolved in pubspec.lock. `any` on sqlite3 — the
    # native engine behind all persistence — allowed an unreviewed major bump.
    meta: ^1.15.0
    sqlite3: ^2.4.0
  ```
  (Confirm the exact resolved versions from `pubspec.lock` before pinning.) Add
  `flutter pub outdated --mode=null-safety` to the CI job from H-6.

---

#### M-10. Doc comment contradicts the code it documents

- **Location:** `lib/data/local/app_database.dart` (Line 27 vs. Line 91)
- **Observation:** The class doc header declares `## Schema Version: 5` while `schemaVersion` returns
  `8`. The migration history list immediately below (`:28-36`) correctly documents all the way to
  v7→v8, so only the header is stale — but the header is what a reader sees first.

  `testing-quality.md` on comments: *"Comment why, never what."* A "what" comment that has drifted
  out of sync is the failure mode that rule exists to prevent.
- **Impact:** A contributor reasons about the wrong schema version when writing migration v9.
- **Remediation:**
  ```dart
  /// ## Schema Version: 8
  /// Migration history:
  ```
  Better: delete the header line entirely and let `schemaVersion => 8` at `:91` be the single source
  of truth. A fact stated in two places will diverge again.

---

### 🟢 LOW

---

#### L-1. Positional boolean parameter selects behavior

- **Location:** `lib/providers/schedule_state_provider.dart` (Lines 668–672; call site at 737)
- **Observation:** `Future<void> applyTemplate(PlanTemplate template, [int? index, bool surfaceErrors = true])`.
  The call at `:737` reads `await applyTemplate(tmpl, i, false)` — unintelligible without opening the
  definition. The doc comment at `:661-667` is excellent and explains exactly why the flag exists,
  which is itself the evidence that two named operations are hiding inside one.
  `testing-quality.md`: *"Boolean parameters that select behavior are a smell — two named functions
  are clearer than `process(true)`."*
- **Remediation:**
  ```dart
  /// User-initiated apply: failures roll back and surface a snackbar.
  Future<void> applyTemplate(PlanTemplate template, [int? index]) =>
      _applyTemplate(template, index, surfaceErrors: true);

  /// Background recurrence apply: failures roll back and are logged only —
  /// the user did not request this apply, so a snackbar would be noise.
  Future<void> applyTemplateInBackground(PlanTemplate template, int index) =>
      _applyTemplate(template, index, surfaceErrors: false);
  ```

---

#### L-2. Week length `7` is a magic number duplicated in three places

- **Location:** `lib/ui/screens/schedule_view.dart:414, 423`;
  `lib/providers/schedule_state_provider.dart:107`
- **Observation:** `List.generate(7, ...)` and `itemCount: 7` in the view, `getUpcomingDays(7)` in the
  provider. `buildDayCard` indexes `provider.weekPlan[index]` at `:294` with no bounds check. If
  `_weekPlan` is ever shorter — a partial load, or a future "3-day view" — this is a `RangeError`
  during paint. Note `selectedDay` (`schedule_state_provider.dart:80-82`) already defends against the
  empty case with a dummy `DayPlan`, so the intent to be defensive exists; it just isn't applied here.
- **Remediation:**
  ```dart
  // schedule_state_provider.dart
  /// Days in the rolling window. The schedule view derives its item count from
  /// this, so the two cannot drift apart.
  static const int rollingWindowDays = 7;
  ```
  ```dart
  // schedule_view.dart — drive the view from the loaded data, not a literal
  itemCount: provider.weekPlan.length,
  ```

---

#### L-3. `IntelligenceService` is constructed inline, defeating mockability

- **Location:** `lib/providers/analytics_provider.dart` (Line 17)
- **Observation:** `final IntelligenceService _intel = IntelligenceService();` — hard-constructed,
  while every other dependency in this codebase is constructor-injected
  (`schedule_state_provider.dart:84-92` is a model of the pattern). `AnalyticsProvider` therefore
  cannot be tested without running the real peak calculation, including the `compute()` isolate hop
  at `intelligence_service.dart:16-20`. This is likely why `AnalyticsProvider` has no test file at all.
- **Remediation:**
  ```dart
  final IntelligenceService _intel;

  AnalyticsProvider(
    this._stateProvider, [
    this._scheduleRepo,
    IntelligenceService? intel,
  ]) : _intel = intel ?? IntelligenceService() {
    // ...
  }
  ```

---

#### L-4. Unmeasured magic threshold chooses between isolate and main thread

- **Location:** `lib/core/services/intelligence_service.dart` (Line 16)
- **Observation:** `if (history.length > 500) return compute(_calculatePeaks, history);`
  Offloading heavy work is right — but 500 is unexplained, and `compute()` carries a fixed isolate
  spawn + serialization cost that may exceed the computation for lists near the threshold.
  `performance-efficiency.md`: *"Optimization without a measurement is guessing that costs complexity."*

  Related: `:58-60` carries the comment *"Normalize: divide by total number of days... For now, we'll
  just return raw aggregated intensity"* — an acknowledged-incomplete implementation recorded as a
  comment rather than a tracked item, which means the analytics screen's "PEAK HOUR"
  (`analytics_view.dart:133`) shows an unnormalized figure that grows with history length.
- **Remediation:** Name the constant with its measurement, or delete the branch until one exists:
  ```dart
  /// Measured on a Pixel 6 / M1: below this, isolate spawn + list serialization
  /// costs more than the calculation itself. Re-measure if Task grows fields.
  static const int _isolateThreshold = 500;
  ```
  Track the normalization gap as a real issue rather than a comment.

---

#### L-5. Stale `// Set below` comment in template seeding

- **Location:** `lib/providers/schedule_state_provider.dart` (Line 201)
- **Observation:** `templateId: '', // Set below` — but nothing below sets it. The persisted row is
  correct by accident, because `LocalTemplateRepository._modelTaskToCompanion`
  (`local_template_repository.dart:243-258`) overrides `templateId` with the parent's id on write.
  The in-memory `_templates` entry, however, keeps `templateId: ''` until the next `loadData()`.
- **Remediation:** Build the id first and use it, deleting the comment:
  ```dart
  final templateId = const Uuid().v4();
  final seeds = [
    PlanTemplate(
      id: templateId,
      // ...
      tasks: [TemplateTask(id: const Uuid().v4(), templateId: templateId, /* ... */)],
    ),
  ];
  ```

---

#### L-6. Optional dependency creates two untested code paths

- **Location:** `lib/providers/todo_provider.dart` (Lines 28, 77–81, 84–85, 106)
- **Observation:** `TodoProvider(this._repository, {PreferenceRepository? prefRepo})` with null guards
  at `:84-85` and a null-safe call at `:106`. Production always supplies it (`main.dart:135`), so the
  null branch exists purely for test convenience — and silently disables alarm-sort persistence if
  anyone ever forgets. `design-judgment.md` §6 flags *"config nobody sets"* as speculative generality.
- **Remediation:** Make it required and pass a fake in tests, matching how `ScheduleStateProvider`
  (`schedule_state_provider.dart:84-92`) requires all four of its dependencies.

---

## 4. Architectural & Product Evolution Strategy

### What this architecture gets right, and should be protected

Three decisions here are genuinely load-bearing and worth defending against future "simplification":

1. **Repository interfaces separated from Drift implementations** (`schedule_repository.dart` vs.
   `local/local_schedule_repository.dart`). This is the seam `design-judgment.md` §4 says pays off
   almost every time — *"Persistence, when the storage choice is plausibly not final."* It is what
   makes `schedule_state_provider_test.dart` possible at all. If cloud sync ever arrives, it lands
   behind this interface as a `SyncingScheduleRepository` decorator rather than a rewrite.

2. **`Result<T>` with a sealed `AppFailure` hierarchy** (`result.dart:7-63`). Expected outcomes are
   modeled in the return type instead of thrown — exactly what `testing-quality.md` prescribes:
   *"Expected outcomes are part of the contract and belong in the return type or a typed error, not
   in exception control flow."* Fix C-3's leak and this becomes airtight.

3. **Optimistic updates with explicit rollback** (the `originalPlan` capture-and-restore pattern at
   `schedule_state_provider.dart:339, 367, 389, 697`). This is the right UX shape for a local-first
   app and it is applied consistently across all ten mutation methods.

### Where the architecture will bend first

**The missing domain layer.** `ScheduleStateProvider` is 751 lines and holds all of the app's real
business logic: overlap detection (`:293-314`), recurring-template application (`:721-742`), dismissal
key encoding and pruning (`:231-277`), undo semantics (`:431-466`), and weekday-index-to-date mapping
(`:650-659`). None of that depends on Flutter, yet all of it is trapped inside a `ChangeNotifier`.

The consequences are already visible: `_toMinutes` (`:280-286`) and
`IntelligenceService._parseTime` (`intelligence_service.dart:63-70`) are two independent
implementations of the same parse with *different* failure behavior (`0` vs. `null`), and
`AnalyticsProvider._calculateDuration` (`analytics_provider.dart:137-148`) is a third. This is the
coincidental-duplication trap from `design-judgment.md` Gate 2 — except here it is genuine
duplication across a boundary that does not exist.

The fix is not a ceremonial "use case per operation" layer — that is the cargo-cult layering the
standard explicitly warns about (*"Repository → service → controller with zero logic in two of them"*).
It is narrower: extract the **pure decision functions** into `lib/domain/`, keeping the provider as the
orchestrator that calls them and manages notification. Concretely:

```
lib/domain/
  time_range.dart        // TimeOfDayRange value object: parse, validate, overlaps(), minutes
                         // — replaces _toMinutes, _parseTime, _calculateDuration (3 impls, 1 concept)
  recurrence.dart        // pure: (templates, days, dismissals) -> List<PendingApply>
  scheduling_rules.dart  // pure: overlappingTasks, sortTasks
```

Each is a pure function over data, unit-testable with no mocks and no `pumpWidget`. This is the
*push side effects to the edges* rule, and it costs almost nothing to do incrementally — move one
function per PR, delete the duplicate, keep the provider's public API unchanged.

**The `String` time representation is the one-way door that is still open.** `startTime`/`endTime` are
`'HH:mm'` strings everywhere: in the domain model (`task_model.dart:17-18`), the table
(`tables.dart:9-10`), and every consumer. Sorting works only because lexical order coincides with
chronological order for zero-padded 24-hour strings — an invariant no code enforces once C-2 removes
the release-mode regex check. Overnight ranges need the `+24h` fudge in two separate places
(`schedule_state_provider.dart:305, 311` and `intelligence_service.dart:41`). Per
`design-judgment.md` §5, *"units, currency, timezone, and identity representation"* are explicitly
one-way doors. This is worth correcting **now**, while the app is pre-1.0 and the data volume is
small, via a `TimeOfDayRange` value object with an explicit `crossesMidnight` flag. In two years, with
users' data in the wild, it will require a migration.

### Making a new feature cheap to add

Today, shipping a new screen requires edits in four places: `main.dart`'s `MultiProvider` list
(`:129-141`), `home_screen.dart`'s `_screens` array (`:30-35`), the desktop sidebar items
(`:331-358`), and the bottom nav items (`:151-168`). Adding a fifth tab means touching the same file
three times. That is the *"how easily can a new module be added without modifying existing core
classes"* question answering itself.

Two changes, in order:

1. **A feature registry over a hardcoded list.** Not a plugin framework — `design-judgment.md` §4 is
   explicit that frameworks need evidence and a named owner. Just one `const List<FeatureTab>`
   describing `(icon, label, builder)`, from which both nav surfaces and the `IndexedStack` derive.
   New tab = one list entry.

2. **Reorganize `lib/` by feature, not by layer.** The current `ui/screens`, `ui/widgets`,
   `providers`, `data/repositories` split means one feature's code is scattered across four
   directories, and `ui/widgets/` is already a bag of unrelated components — the *"'helpers' that are
   just a bag of unrelated functions"* anti-pattern from `design-judgment.md` §3. A
   `lib/features/schedule/{view,provider,widgets}/` layout with a shared `lib/core/` and `lib/data/`
   makes ownership obvious and lets a feature be deleted in one `rm -rf`. Do this **after** the
   §5 Phase 1 fixes land, so the moves do not obscure the behavioral diffs.

### On state management

Provider is a fine choice and there is no reason to migrate to Riverpod or Bloc — that would be
replacing a working two-way door with churn. The actual problem is not the library; it is that
**nothing in this codebase scopes a rebuild**. Zero `Selector`s across 7,899 UI lines means Provider
is being used as a global-rebuild bus. Adding `Selector`/`context.select` where H-4 describes
recovers most of the performance benefit that a migration would be sold on, at a fraction of the cost.

One genuine Provider-idiom fix: `AnalyticsProvider` manually subscribes to `ScheduleStateProvider`
(`analytics_provider.dart:37, 44`) and is constructed with a captured reference in `main.dart:131-133`.
`ChangeNotifierProxyProvider` exists for exactly this and handles the lifecycle correctly.

---

## 5. Prioritized Remediation Roadmap (Action Plan)

Tiering per `SKILL.md` *"Applying the bar proportionally"* — rigor scales with blast radius ×
reversibility.

### Phase 1 — Critical Stability & Compliance *(Tier: Consequential — data integrity + release-only defects)*

**Goal: nothing can fail silently, and nothing can corrupt persisted data.**
Every item here is invisible in debug builds, which is exactly why they are first.

| # | Action | Files | Verification |
|---|---|---|---|
| 1.1 | Enable `PRAGMA foreign_keys = ON` in `beforeOpen`; add a v9 orphan sweep | `app_database.dart:93` | New test: deleting a `PlanTemplate` removes its `template_active_days` rows. **Must fail before the fix.** |
| 1.2 | Widen `_wrap` to `catch (e, st)`; extract to `core/result.dart` as `guard<T>` and delete all four copies | `result.dart`, all 4 `local/*_repository.dart` | New test: a repository throwing `StateError` returns `Failure(UnknownFailure)`, not a throw |
| 1.3 | Install `FlutterError.onError` + `PlatformDispatcher.instance.onError`; swap release logger to a real reporter | `main.dart:26-31`, `logger.dart:71-86` | Manual: throw from a UI callback in a profile build, confirm it is captured |
| 1.4 | Replace `assert`-based invariants with `Task.create` / `TemplateTask.create` returning `Result`; add DB `CHECK` constraints in v9 | `task_model.dart:41-52`, `plan_template_model.dart:29-38`, `todo_item_model.dart:86-89`, `tables.dart` | Test run with asserts disabled: invalid time returns `ValidationFailure` |
| 1.5 | Back up `day_plans`/`tasks` before the v8 merge; abort on detected orphans | `app_database.dart:315-367` | New migration test: seed an orphaned task, assert the migration aborts and data survives |
| 1.6 | Fix `DayPlan.hashCode` / `TodoItem.hashCode` to match their `==` | `day_plan_model.dart:65`, `todo_item_model.dart:194` | New test: `{planA, planB}.length == 1` for two equal plans |
| 1.7 | Dispose the two leaked `TextEditingController`s | `schedule_view.dart:767`, `work_plans_view.dart:235` | Widget test opening/closing the dialog 100× with no controller growth |
| 1.8 | Guard `TodoProvider` retry with `_disposed` + cancellable `Timer` + bounded backoff | `todo_provider.dart:148-162` | New test: error a stream, dispose within 5 s, assert no `used after being disposed` throw |
| 1.9 | Stand up CI (format, analyze, test, codegen-drift check) | `.github/workflows/ci.yaml` (new) | Pipeline green on a PR |

**Rollback for this phase:** every item is a small, independently revertable commit except 1.1, 1.4,
and 1.5, which add migration v9 — that one needs the backup-table strategy from M-4 applied to itself.
**Exit gate:** a release build surfaces a forced write failure to the user *and* records it in the
crash reporter.

---

### Phase 2 — Architectural Refactoring *(Tier: Standard → Consequential)*

**Goal: the code becomes reviewable and the presentation layer becomes testable.**
Order matters — 2.1 makes the rest verifiable.

| # | Action | Files | Verification |
|---|---|---|---|
| 2.1 | Build the widget-test harness (`test/helpers/mocks.dart` + pump helpers); replace the `widget_test.dart` placeholder with the rollback/snackbar test from H-5 | `test/` | ≥6 widget tests covering schedule load/error/retry, overlap warning, alarm overlay |
| 2.2 | Decompose `schedule_view.dart` `build()` into `_AmbientGlowBackdrop`, `_DaySelectorStrip`, `_ScheduleHeader`, `_TaskListArea`; move `_consumeTransientError` out of `build()` into a listener | `schedule_view.dart:210-747` | No `build()` in `lib/ui` exceeds ~80 lines; 2.1 tests still green |
| 2.3 | Introduce `Selector`/`context.select` at each decomposed boundary; add `RepaintBoundary` around the static blur backdrops | `schedule_view.dart`, `analytics_view.dart:58`, `work_plans_view.dart:17`, `focus_hud.dart:14` | DevTools: a task toggle rebuilds one subtree, not four screens |
| 2.4 | Extract `lib/domain/time_range.dart`; delete the three duplicate time parsers | `schedule_state_provider.dart:280-286`, `intelligence_service.dart:63-70`, `analytics_provider.dart:137-148` | Pure unit tests incl. overnight, malformed, and boundary (`00:00`, `23:59`) cases |
| 2.5 | Delete all dead code identified in M-2 (~350 lines) | `task_dto.dart`, `todo_item_dto.dart`, 11 unused methods, `CrashReportingLogger`, `NetworkFailure` | `flutter analyze` clean; suite green; LOC drops |
| 2.6 | Split `applyTemplate`'s boolean flag into two named methods; make `TodoProvider.prefRepo` required; inject `IntelligenceService` | `schedule_state_provider.dart:668`, `todo_provider.dart:28`, `analytics_provider.dart:17` | New `AnalyticsProvider` test with a fake `IntelligenceService` |
| 2.7 | Inject `Logger` into `MigrationHelper`; drop its `material.dart` import; replace all `debugPrint` | `migration_helper.dart:4, 25, 40, 42, 95, 136` | Grep: zero `debugPrint` in `lib/data/` |
| 2.8 | Add a `bootstrap({AppDatabase?})` seam; close the DB on window close | `main.dart:26, 88-99` | Integration test: `bootstrap` against an in-memory DB, assert migration + first frame |

**Exit gate:** every fix from Phase 1 has a test that fails without it; no method in `lib/` exceeds
100 lines.

---

### Phase 3 — Performance, Accessibility & Scalability Polish *(Tier: Standard)*

**Goal: the app is pleasant on mid-tier hardware and usable by everyone.**

| # | Action | Files | Verification |
|---|---|---|---|
| 3.1 | Batch the N+1 in `getUpcomingDays` into one `IN` query + O(1) grouping | `local_schedule_repository.dart:96-112` | Query-count assertion in the repository test: ≤2 queries per `getUpcomingDays(7)` |
| 3.2 | Memoize `getSortedTasks`; invalidate on mutation and sort-order change | `schedule_state_provider.dart:316-324` | Test: N rebuilds trigger 1 sort |
| 3.3 | Add `Semantics` to task cards, sheets, dialogs, timer controls, alarm overlay; labels on all icon-only buttons | `task_card.dart`, `task_detail_panel.dart`, `add_task_sheet.dart`, `new_item_sheet.dart`, `timer_view.dart`, `home_screen.dart:178-259` | `meetsGuideline(androidTapTargetGuideline)` + `textContrastGuideline` in the widget suite |
| 3.4 | Respect `MediaQuery.disableAnimations` across all 18 animation/blur sites | `glass_container.dart`, `analytics_view.dart:27-30`, `home_screen.dart:412-433`, `schedule_view.dart:314-316` | Manual: OS reduce-motion on → no blur transitions |
| 3.5 | Extract user-facing strings behind an `AppStrings` seam (no full l10n yet — just the seam) | all of `lib/ui/` | Grep: no bare string literals in `Text(` constructors |
| 3.6 | Replace hardcoded nav with a `FeatureTab` registry driving `IndexedStack` + both nav surfaces | `home_screen.dart:30-35, 151-168, 331-358` | Adding a 5th tab requires exactly one new list entry |
| 3.7 | Pin `meta` and `sqlite3`; add `flutter pub outdated` to CI | `pubspec.yaml:29-30`, CI | Reproducible resolve from a clean cache |
| 3.8 | Add OS-level alarm scheduling; re-guard `_fire` post-`await`; surface missing-audio state | `alarm_scheduler_service.dart:50-117`, `pubspec.yaml` | Manual: alarm fires with the app closed. Record as an ADR (new dependency = Consequential) |
| 3.9 | Fix the `Schema Version: 5` doc header; write ADRs for Provider, Drift, and the singleton-DB choices | `app_database.dart:27`, `docs/` | `docs/ARCHITECTURE.md` links three decision records |

**Exit gate:** DevTools shows no frame over 16 ms during normal schedule interaction; accessibility
guideline tests pass; adding a screen touches one file.

---

### Sequencing note

Phase 1 items **1.1, 1.2, and 1.4** are mutually reinforcing and should ship together as one reviewed
changeset with migration v9 — they collectively close the "release build has no integrity guarantees"
gap, and shipping any one alone leaves the other two providing false confidence. Phase 2 item **2.1**
(the widget-test harness) is the highest-leverage single task in this entire roadmap: without it,
every subsequent refactor is unverifiable, and with it, the remaining twenty-odd items become routine.
