# 0004 — Enforce task invariants in the app *and* the schema

**Status:** Accepted

**Decision:** Task invariants (title length, `HH:mm` clock times, non-negative
costs) are validated by `Task.create` / `TemplateTask.create` returning `Result`,
**and** independently by SQL `CHECK` constraints declared as table-level
`customConstraints`.

**Context:** The invariants were originally `assert`s in model constructors. Dart
strips asserts from release builds, so the shipped app had no validation at all:
`startTime: '99:99'` constructed and persisted happily, and the test that
"proved" validation worked passed only because tests run with asserts enabled.
Downstream code then degraded quietly — a malformed time parsed as `0`, turning a
corrupt task into a midnight-to-midnight block that overlapped everything else on
the day.

**Alternatives:**

- **Application validation only** — covers data *this version* writes. It does
  nothing for a future code path that forgets the factory, a raw SQL insert, or
  rows already on disk from an earlier build.
- **Schema constraints only** — a violation arrives as an opaque database
  exception at the bottom of a write, far from the form field that caused it.
  Users need a message naming the field.
- **Throwing constructors instead of `Result`** — invalid user input is an
  expected outcome, not an exceptional one, so `testing-quality.md` puts it in the
  return type rather than in exception control flow.

**Consequences:**

- Easy: the form reports which field failed; anything slipping past the factory
  still cannot reach disk.
- Hard: the rules exist in two places and must agree. The clauses are also
  duplicated between `Tasks` and `TemplateTasks`, because sharing them does not
  work (below). A test asserts `template_tasks` rejects what `tasks` rejects.
- **Trap worth remembering:** column-level `customConstraint` is ignored unless
  the string is an inline literal. Drift's generator reads the source AST, so a
  reference to a `const` string — or a value from a helper function — is emitted as
  *no constraint at all*. It regenerates cleanly, analyses cleanly, and enforces
  nothing; only a test that inserts a bad row catches it. The constraints are also
  absent from the `.g.dart`, because drift assembles `CREATE TABLE` at runtime from
  the table class that the generated one extends.
- Reversing: the app-level half is cheap. The schema half needs another table
  rebuild.
