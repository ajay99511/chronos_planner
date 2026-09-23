# 0005 — Destructive migrations quarantine rows rather than delete them

**Status:** Accepted

**Decision:** Any migration that would remove or reject existing rows copies them
to a suffixed table first (`day_plans_backup_v7`, `tasks_orphaned_v8`,
`tasks_invalid_v9`) and only then deletes. Where an invariant must hold before a
destructive step, the migration checks it and aborts rather than proceeding.

**Context:** Three migrations in this schema destroy data.

- **v8** merges duplicate `day_plans` rows and deletes the losers.
- **v9** sweeps rows orphaned while `PRAGMA foreign_keys` was off — which was the
  entire time, since nothing enabled it until v9.
- **v10** adds `CHECK` constraints, which in SQLite means rebuilding the table and
  copying every row. A single violating row aborts that copy and leaves the app
  unable to open its own database. Violating rows are *expected*, because release
  builds had no validation until the invariants work (0004).

`lifecycle-gates.md` requires migrations be "reversible or provably safe", and the
first non-negotiable in the standard is that a change must never lose persisted
data.

**Alternatives:**

- **Delete outright** — what v8 originally did. Fast, and irreversible on any data
  shape the reparenting logic did not anticipate.
- **Abort the upgrade on any bad row** — fails closed, which is right for an
  invariant violation but wrong for pre-existing data: it bricks the app on launch
  for exactly the users with the most history.
- **Repair rows automatically** — inventing a start time for a row whose time is
  unparseable is fabricating user data.

**Consequences:**

- Easy: every destructive step is recoverable with a `SELECT`. Nothing silently
  disappears, and nothing blocks startup.
- Hard: quarantine tables accumulate and nothing prunes them. They are invisible
  to the app but they are in the file. A future migration should report on them.
- Reversing: the quarantined rows *are* the reversal. Re-inserting them requires
  fixing whatever made them invalid.
- Related discipline, learned twice: `onUpgrade` branches here are gated on `from`
  alone, so **every** step runs against schemas that predate its tables and
  columns. Both the v9 sweep and the v10 quarantine broke existing migration tests
  by assuming their columns existed. Each step must check first.
