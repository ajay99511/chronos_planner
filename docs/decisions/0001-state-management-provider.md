# 0001 — Provider + ChangeNotifier for state management

**Status:** Accepted · **Reasoning reconstructed from the code, not recovered
from the original author.**

**Decision:** Application state lives in `ChangeNotifier` subclasses exposed
through `package:provider`.

**Context:** Four providers exist — schedule, todos, analytics, alarms — wired in
`main.dart` via `MultiProvider`. The app is local-first, single-user and offline
only: there is no server state to cache or invalidate, which removes most of the
pressure that pushes projects toward heavier state libraries. `provider` is also
the package the Flutter team documents first, so it is the lowest-friction choice
for a contributor arriving cold.

**Alternatives** (inferred; there is no record of these being weighed at the time):

- **Riverpod** — compile-safe reads and no `BuildContext` dependency, at the cost
  of a larger API surface and a migration for every existing screen. Nothing in
  the current feature set needs what it adds.
- **Bloc** — event/state separation pays off where transitions are complex or
  need auditing. These flows are CRUD plus optimistic rollback, which does not
  justify the ceremony.
- **`setState` only** — the schedule is read by four screens; lifting it into
  widget state would mean threading it through the tree by hand.

**Consequences:**

- Easy: adding a provider; testing one directly, since they are plain Dart
  objects over injected repositories.
- Hard: *scoping* rebuilds. `Provider.of(context)` rebuilds the whole subtree, and
  there was no `Selector` anywhere in `lib/ui` until the Phase 2 work, so a
  single task toggle rebuilt four screens. The library did not cause that, but it
  makes it easy to write.
- One sharp edge, now documented in code: `ScheduleStateProvider` mutates
  `_weekPlan` in place, so any `Selector` over it must compare by **content**.
  Identity comparison silently misses real changes.
- Reversing: contained per screen. Every provider is constructed over repository
  interfaces, so swapping the delivery mechanism does not touch the data layer.
