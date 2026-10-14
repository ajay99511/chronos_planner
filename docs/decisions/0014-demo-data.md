# 0014 — Sample content is flagged and filtered, never deleted

**Status:** Accepted.

**Decision:** Sample content carries an `isDemo` flag in the database (schema
v12). One global switch in Settings hides or shows all of it at once, by
**filtering** rather than deleting. Demo rows are never registered with the
operating system's notification schedule.

## Context

The starter WorkPlans from the previous round were seeded as ordinary rows,
indistinguishable from the user's own. That was right for them — they are meant
to be adopted or deleted. The ask then extended to the Workspace tab: three
samples of each of the four kinds (notes, timers, alarms, checklists), **plus a
toggle to include or exclude demo data from actual data**.

A toggle changes the requirement fundamentally. Sample content now has to stay
identifiable and reversible for the life of the install, which "just insert
some rows" cannot provide.

## Value and risk, per option

### Identifying sample content

| Option | Value | Risk | Verdict |
|---|---|---|---|
| **A. An `isDemo` column** | Survives renaming and editing a sample. One predicate everywhere. | Two additive migrations. | **Chosen** |
| B. A naming convention, or a reserved id prefix | No schema change. | Breaks the moment the user renames a sample, which is the first thing anyone does. Silently reclassifies their content. | Rejected |
| C. A separate table of demo ids | No column on the real tables. | A join on every read, plus its own orphan problem — a cost this repo has already paid once (0005). | Rejected |

### Hiding versus deleting

| Option | Value | Risk | Verdict |
|---|---|---|---|
| **A. Filter on read** | Instant both ways. Edits to a sample survive a round trip. | Every list walks the rows. Negligible at this scale. | **Chosen** |
| B. Delete on off, re-seed on on | Nothing to filter. | Destroys the user's edits, and re-seeding mints new ids so anything referencing them breaks. A toggle that destroys data is not a toggle. | Rejected |

## Consequences

- One switch governs the starter plans **and** the Workspace samples. The
  alternative — a switch per tab — would have meant explaining to the user why
  there are two.
- The flag is on `todo_items` and `plan_templates`. **Deliberately not on
  `tasks`:** a task created by applying a sample plan is the user's own
  schedule, and must not vanish when the switch goes off. The flag marks sample
  *content*, not what the user did with it. There is a test stating this.
- **Demo alarms are never scheduled with the OS, unconditionally** — not merely
  while samples are hidden. A sample alarm that actually rings on someone's
  phone is indefensible for content they did not create, and making the rule
  conditional would mean `schedulableAlarms` had to know about a UI setting.
  Three independent guards: the flag, `enabled: false`, and past-dated times.
- Filtering happens in the UI, beside the existing search filter, rather than
  in the providers. The providers' job is to mirror the repository, and
  everything else — applying a plan, recurrence, the notification schedule —
  still sees every row. A hidden sample is also not searchable: surfacing a
  result the user has chosen to hide is worse than not finding it.
- The switch **defaults to on**. Samples exist to show what the four workspace
  kinds and the plan library are for, which they cannot do while hidden.
- Seeding is gated on its own preference, not on "the workspace is empty" —
  the mistake the starter plans originally made, where deleting everything
  brought it all back on the next launch.
- The flag is set even if some seed writes fail. A partial seed is still a
  seed; retrying would duplicate whatever landed.
- Analytics is unaffected: it reads schedule tasks only, and tasks carry no
  demo flag. Demo plans *applied* to the schedule do count, which is correct —
  the user applied them.
- Existing rows default to `is_demo = 0`, so anything predating the flag is
  treated as the user's own and is never hidden.
- **A pre-existing dev database cannot be reconciled.** The starter plans
  seeded before v12 have no flag and are indistinguishable from hand-made ones.
  Nothing is published, so the only affected database is a developer's own; the
  fix is to clear app data once rather than guess by name.
- Reversing: drop two columns and the filter; the samples become ordinary rows.
