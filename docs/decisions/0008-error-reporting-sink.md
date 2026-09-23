# 0008 — Errors reach the platform log, not a remote service

**Status:** **Open.** Needs a product decision.

**Decision (current):** Errors are captured globally (`FlutterError.onError`,
`PlatformDispatcher.onError`) and written as structured JSON records to the
platform log via `dart:developer`. Release builds log at `info` and above. There
is no remote crash reporting.

**Context:** Release builds previously selected `NoOpLogger`, so every `error` and
`warning` call in the app discarded its payload — including "Failed to persist
recurring dismissals", which the code's own comment says "reads as data corruption
to the user". Nothing installed a global handler either, so anything escaping a
widget or an unawaited future vanished entirely. Together, that is what made the
lost-write bug *silent* rather than merely broken.

That half is fixed. What remains is that nobody sees these logs unless they are
attached to the device.

**Alternatives:**

- **Sentry / Firebase Crashlytics** — the usual answer. A permanent dependency that
  sends data off-device, which `security-privacy.md` treats as Consequential: it
  needs a decision about what leaves the boundary and what the vendor retains.
- **A local rotating log file** — no egress at all, which suits a local-first
  desktop app, and `path_provider` is already a dependency. Viable specifically
  because nothing user-authored is logged today: records carry ids and fixed
  strings, not task titles. Adding one would create a retention question.
- **Leave it here** — honest and cheap, but a production failure stays invisible
  unless the user reproduces it for you.

**Consequences:**

- Easy: no egress, no consent question, no dependency. `flutter logs` and the
  platform console show structured, filterable records.
- Hard: no aggregate view, so a failure affecting many users looks like silence.
- Note: `CrashReportingLogger` was deleted rather than left in place. Four empty
  methods that looked like crash reporting and reported nothing is worse than an
  obvious gap.
- Reversing: the `Logger` interface is the seam; a sink is an implementation plus
  one line in `createLogger`.
