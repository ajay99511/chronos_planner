# Decision records

Short records of decisions that are expensive to reverse, in the format from
`engineering-standards/references/design-judgment.md` §7:

```
Decision:     What we're doing, in one sentence.
Context:      The forces — constraints, load, deadlines, existing systems.
Alternatives: What else we considered and the specific reason each lost.
Consequences: What this makes easy, what it makes hard, how we'd reverse it.
```

Recording the *losing* options matters more than recording the winner. The
winner is visible in the code forever; the reasoning is what disappears, and its
absence is why the next engineer either cargo-cults a decision or rips it out
without understanding the constraint it was solving.

## A caveat on 0001–0003

Those three describe decisions taken **before** these records existed. The
reasoning in them is **reconstructed from the code and its comments, not
recovered from the original author.** Where a record states a motive it can only
infer, it says so. They are written down because an inferred rationale that is
labelled as inferred is more useful than none — but they should be corrected by
anyone who actually knows.

## Index

| # | Decision | Status |
|---|---|---|
| [0001](0001-state-management-provider.md) | Provider + ChangeNotifier for state management | Accepted (reconstructed) |
| [0002](0002-local-persistence-drift-sqlite.md) | Drift over SQLite for local persistence | Accepted (reconstructed) |
| [0003](0003-database-singleton-and-composition-seam.md) | Database singleton, with a composition seam for tests | Amended |
| [0004](0004-invariants-in-both-app-and-schema.md) | Enforce task invariants in the app *and* the schema | Accepted |
| [0005](0005-quarantine-not-delete-in-migrations.md) | Destructive migrations quarantine rows rather than delete them | Accepted |
| [0006](0006-in-process-alarm-scheduling.md) | Alarms are scheduled in-process | Accepted — limitation now surfaced |
| [0007](0007-i18n-seam-without-localisation.md) | An i18n seam without localising | Accepted |
| [0008](0008-error-reporting-sink.md) | Errors reach the platform log, not a remote service | **Open** — needs a product decision |
| [0009](0009-audio-unsupported-on-windows-and-linux.md) | Alarm and timer sound do not work on Windows or Linux | **Open** — shipped feature, primary platform |
