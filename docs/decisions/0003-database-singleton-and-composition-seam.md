# 0003 — Database singleton, with a composition seam for tests

**Status:** Amended (the seam was added later)

**Decision:** `AppDatabase.instance` remains a lazily-initialised singleton, but
object-graph construction moved into `composeDependencies({database, logger})`,
which accepts an injected database.

**Context:** A desktop/mobile app has exactly one database file, and SQLite
tolerates one writer; a singleton matches that reality and avoids threading a
handle through every layer. But `main()` reached for the singleton directly, so
startup — the riskiest path in the app, since it both migrates and opens the
schema — could not be exercised against an in-memory database. That is why there
was no app-level integration test.

**Alternatives:**

- **A DI container** (`get_it` and similar) — solves the same problem, adds a
  dependency and a second lookup mechanism alongside `provider`. Rejected: the app
  has one graph, built once, in one place.
- **Remove the singleton entirely** — every call site would thread a handle it has
  no other use for, to make a one-per-process resource look configurable.
- **Keep reaching for the singleton and test only below it** — the status quo. It
  leaves migration-plus-open untested, which is where the damage lives.

**Consequences:**

- Easy: `composeDependencies` builds the real graph over
  `NativeDatabase.memory()`, so startup, migration and provider wiring are tested
  together.
- Hard: the singleton is still reachable, so nothing *forces* the seam. A new call
  site can bypass it.
- Known gap: `AppDatabase.instance` has no reset, so a test that touches it rather
  than the seam pollutes the process.
- Reversing: cheap. The seam is additive; production still defaults to the
  singleton.
