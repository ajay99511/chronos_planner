# Phase 2 — Architectural Refactoring

Implements Phase 2 of `AUDIT_AND_STANDARDS_ANALYSIS.md`. Follows PR #1 (Phase 1).

**Base:** `master` · **Head:** `phase2-architectural-refactoring` · 9 commits

## Why

Phase 1 closed the integrity holes. This phase makes the codebase *changeable*:
it had no presentation-layer tests at all, a 537-line `build()` method, one
concept implemented five times, and ~390 lines of code nothing referenced.

## What changed

| # | Change | Effect |
|---|---|---|
| 2.1 | Widget-test harness + first presentation coverage | `lib/ui` went from 0 tests to 7 |
| 2.5 | Deleted dead code | −390 lines: both DTO files, `getRecurringTemplates` across 3 layers, 11 methods, `CrashReportingLogger`, `NetworkFailure` |
| 2.4 | Extracted `ClockTime` / `TimeRange` | Unified **five** `HH:mm` implementations with three different failure modes |
| 2.7 | Injected `Logger` into `MigrationHelper` | Zero `debugPrint` left in `lib/data` or `lib/core`; `material.dart` out of the data layer |
| 2.6 | Removed behaviour flags, injected dependencies | Made `AnalyticsProvider` testable at all |
| 2.2 | Decomposed `ScheduleView.build()` | **537 → 81 lines**; side effect moved out of `build()` |
| 2.3 | Scoped rebuilds with `Selector` | Was zero `Selector` in `lib/ui`; a task toggle rebuilt four screens |
| — | Fixed `ListTile` ink defect in list view | Found by the new harness on its first run |
| 2.8 | Added `composeDependencies` seam | First startup + migration integration test |

## Verification

```
flutter analyze --fatal-infos --fatal-warnings  →  No issues found
flutter test                                    →  112 passed  (was 70)
dart run build_runner build                     →  no .g.dart drift
```

## Review notes

**The 2.1 tests are characterization tests, not bug reproductions.** They pass
against the pre-change code. That is deliberate: they pin behaviour so 2.2/2.3
could rewrite the screen safely, and they did their job — the 537-line method was
replaced wholesale with all 7 still green.

**Two sharp edges shaped 2.3, both of which would have produced silent bugs:**

1. `ScheduleStateProvider` mutates `_weekPlan` **in place**, so identity
   comparison misses real changes. Both `Selector` value types compare by
   content. This is also why Phase 1's `hashCode` fix had to land first —
   `DayPlan` is compared inside that `listEquals`.
2. `Selector` returns a **cached child** when the selected value is unchanged, so
   widget state merely captured in the builder closure stops propagating.
   `_currentViewMode` is therefore part of `_TaskListData`'s equality. Four
   interaction tests guard exactly this.

**Two audit findings were wrong and the document is corrected in-branch:**
`PlanTemplate` was a third model with a broken `hashCode`/`==` pair, and the
extracted guard belongs in the data layer — putting it in `core/result.dart`
would make the shared `Result` primitive import drift.

## Known gaps

- 2.2's exit gate ("no `build()` over ~80 lines") holds for `ScheduleView` (81)
  but not the whole directory: `work_plans_view` (156), `analytics_view` (132),
  `timer_view` (126), `todo_list_view` (123), `new_item_sheet` (115),
  `task_detail_panel` (114). Only the schedule surface was in scope.
- 2.3's correctness is tested; the **reduction in rebuild count** is reasoned from
  structure, not measured. Confirming it needs DevTools.
- Existing provider/repository tests still declare their own mocks. Migrating them
  is churn with no behaviour change.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
