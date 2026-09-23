# Phase 3 — Performance, Accessibility & Scalability

Implements Phase 3 of `AUDIT_AND_STANDARDS_ANALYSIS.md`, and closes the one item
deferred from Phase 1.

**Base:** `phase2-architectural-refactoring` · **Head:** `phase3-performance-scalability` · 10 commits

> ⚠️ **Stacked on Phase 2.** Review and merge that PR first, or this diff will
> include its commits.

## What changed

| # | Change | Effect |
|---|---|---|
| 3.1 | Batched the N+1 in `getUpcomingDays` | 7 queries → 1; O(n²) lookup → O(1). Added the repository's **first real-database tests** |
| 3.2 | Memoized `getSortedTasks` | Was an O(n log n) copy-and-sort per frame; result is unmodifiable |
| 3.8 | Alarm reliability | Stream now recovers instead of dying silently; disposal guarded across every `await`; missing sound surfaced in the UI |
| **1.4** | **SQL `CHECK` constraints (schema v10)** | Closes the backstop deferred from Phase 1 |
| 3.7 | Pinned `meta` and `sqlite3` | `any` had let `meta` cross a minor version unreviewed |
| 3.6 | Feature-tab registry | A new destination is one entry, was four coordinated edits |
| 3.3/3.4 | Accessibility + reduced motion | Screen-reader labels, three Flutter guideline matchers, reduce-motion support |
| 3.5 | `AppStrings` seam | Grammar-bearing messages only — see ADR 0007 |
| 3.9 | Eight decision records | `docs/decisions/`, linked from `ARCHITECTURE.md` |

## Verification

```
flutter analyze --fatal-infos --fatal-warnings  →  No issues found
flutter test                                    →  190 passed  (was 112)
dart run build_runner build                     →  no .g.dart drift
```

## Review notes

**The tests kept finding defects inspection had missed.** The accessibility
guideline matchers found the completion toggle — the single most-tapped control in
the app — was a 40×40 tap target, and that `neonBlue` fails WCAG AA for body text
(2.84:1 even at full opacity, so the alpha was not the cause). Neither was in the
audit. Contrast could not even be *measured* before, because the harness rendered
screens on a default light `Scaffold`; the app's `ThemeData` moved into
`AppTheme.dark` so tests and the app share one definition.

**One drift trap worth knowing before reviewing the v10 commit.** Drift's
generator reads the source AST, so a column constraint passed as a `const`
reference or built by a helper function is **silently dropped**. The first
implementation regenerated cleanly, analysed cleanly, and enforced nothing — only
a test inserting a bad row caught it. The constraints are now table-level
`customConstraints` as inline literals, and they don't appear in the `.g.dart`
either, because drift assembles `CREATE TABLE` at runtime. Written up in ADR 0004.

**I repeated one of my own mistakes.** The v10 quarantine assumed its columns
existed — exactly the bug fixed in the v9 sweep during Phase 1. `onUpgrade`
branches here are gated on `from` alone, so every step runs against schemas
predating its own columns. Both rounds broke existing migration tests. Now one
shared guard; recorded in ADR 0005.

**Migration v10 is destructive, and deliberately reversible.** Adding a `CHECK`
in SQLite means rebuilding the table and copying every row; one violating row
would abort the copy and leave the app unable to open its own database. Violating
rows are *expected*, because release builds had no validation before Phase 1. They
are quarantined to `tasks_invalid_v9` rather than deleted or allowed to block
startup.

**3.5 is scoped narrower than the audit demanded, on purpose.**
`design-judgment.md` puts i18n under *"defer, but leave a seam — do not build."*
Extracting all ~170 literals for a single-locale app is building. The
grammar-bearing text is behind `AppStrings` (the plural ternary was the
genuinely hard-to-find part); fixed labels stay put. The audit's criterion was
stricter than the standard it cited — flagged, not quietly ignored.

## Two decisions left open for you

Both are recorded as **Open** with alternatives costed, because each carries a
dependency or a data-egress question and should not be settled inside a refactor:

- **ADR 0006** — alarms don't fire when the app is closed. Reliability *while
  running* is fixed; OS scheduling needs a permanent platform dependency.
- **ADR 0008** — errors reach the platform log only. Remote reporting sends data
  off-device.

## Known gaps

- Accessibility covers the schedule surface and shared widgets. `work_plans_view`,
  `new_item_sheet`, `analytics_view` and `todo_detail_screen` still need the pass;
  the guideline matchers assert against `ScheduleView` only.
- Six `build()` methods outside the schedule surface still exceed 100 lines.
- Four of ten migration steps (v1→v2, v2→v3, v3→v4, v5→v6) still lack direct
  coverage.
- The CI workflow has **never run on GitHub** — there was no remote for these
  branches until now. Every gate passed locally; that is not the same thing.
- No `dart format` gate: the repo's `require_trailing_commas` lint conflicts with
  the formatter, which is why 35 files diverge. That conflict has to be settled
  first — formatting one file mid-refactor broke the analyze gate and was reverted.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
