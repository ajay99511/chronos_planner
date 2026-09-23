# 0002 — Drift over SQLite for local persistence

**Status:** Accepted · **Reasoning reconstructed from the code, not recovered
from the original author.**

**Decision:** All durable state lives in a local SQLite database accessed through
`drift`, with typed DAOs per aggregate.

**Context:** The app began by storing JSON in `SharedPreferences`; a one-time
`MigrationHelper` still carries that data forward, which is the clearest evidence
of why this changed. Preferences offered no querying, no constraints and no
transactions, and the schedule needs all three. Drift adds typed queries, a
versioned migration system, and reactive `watch()` streams.

**Alternatives** (inferred):

- **Continue with SharedPreferences JSON** — the thing being migrated away from.
  Rewriting the whole document on each mutation makes concurrent edits lossy and
  leaves the "duplicate day plans" class of bug with nowhere to be caught.
- **Isar / Hive** — less ceremony, but no SQL constraints. Given how much of this
  app's integrity work turned out to rest on `CHECK`, `UNIQUE` and
  `ON DELETE CASCADE` (see 0004, 0005), losing the relational engine would have
  been expensive.
- **Raw `sqflite`** — same engine, hand-written SQL, no generated migrations.
  Trades codegen for a class of runtime typo.

**Consequences:**

- Easy: constraints, transactions, multi-table queries, reactive reads.
- Hard: the generated `.g.dart` must stay in step with `tables.dart`; a stale one
  surfaces at runtime as a missing column, not as a compile error. CI now
  regenerates and fails on a diff.
- Sharp edge found the hard way: drift's generator reads the **source AST**, so a
  column constraint passed as a `const` reference or built by a helper function is
  silently dropped. See 0004.
- Reversing: expensive. The schema and its ten migrations are the system of
  record. Repository interfaces insulate the *app*; they do not insulate the data.
