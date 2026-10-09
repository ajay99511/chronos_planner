# Follow-up — alarm reliability, desktop audio finding, full migration chain

Works the two items recommended after the three phases merged: resolve ADR 0006,
then close the migration coverage gap.

**Base:** `master` · **Head:** `followup-alarm-reliability-and-migrations` · 3 commits

## The finding that reframed ADR 0006

Investigating "why don't alarms fire when the app is closed" turned up something
worse than the scheduling limitation:

> **`just_audio` 0.9.46 declares platforms for android, ios, macos and web only.
> This app targets Windows and Linux as its primary desktop experience.**

Verified in the package's own `pubspec.yaml` and confirmed against
`.flutter-plugins-dependencies`, which registers `just_audio` for android, ios
and macos and *not* windows or linux.

So on the main platform, **alarm and timer sound cannot play at all** — and until
this PR neither said so. The alarm path claimed *"the file may have moved"*,
sending a Windows user hunting for a problem that was never theirs. The timer
path swallowed it into a `debugPrint`, so the timer simply finished in silence.

That reorders the original question: firing-while-closed matters less than the
fact that the alarm is mute regardless. Recorded as **ADR 0009 (Open)** with four
costed options and a recommendation.

## What changed

**Alarms**
- `SoundFailure` distinguishes `fileMissing` / `unsupportedPlatform` /
  `playbackFailed`, carried on a typed `SoundException`. The overlay now tells
  the truth per case.
- Platform support is checked **up front** rather than discovered by catching
  `MissingPluginException`; `stop()` short-circuits so dismissal cannot throw.
- **Missed alarms are no longer discarded.** They were disarmed in silence, which
  is what turns a missed alarm into lost trust — the user cannot tell it from one
  that never existed. Now collected, reported once **by name**, acknowledged.
  Naming them is deliberate: "1 alarm was missed" leaves the user guessing which.
- `refreshSchedule()` recomputes against the wall clock on app resume. A Dart
  `Timer` does not survive the machine sleeping through its deadline.

**Timer** — same three reasons surfaced on screen, replacing the `debugPrint`.

**Migrations** — a full `v1 → v10` chain test against a seeded v1 schema.

## Why a chain test rather than four step tests

Four steps had no coverage (`v1→v2`, `v2→v3`, `v3→v4`, `v5→v6`, the last of which
does destructive `TableMigration` rebuilds). But testing them in isolation would
not reflect how the code runs: drift calls `onUpgrade` **once**, and every branch
is gated on `from` alone, so a v1 user executes all nine steps back to back. The
interactions are the risk — `v5` and `v10` both rebuild `tasks` from the current
Dart definition, which only works because `v2` and `v4` added the columns first.

The most valuable assertion: **the v10 CHECK constraints are live after an
upgrade**, not just on fresh installs. Had the rebuild failed to carry them, every
existing user would keep unguarded tables forever and nothing else in the suite
would have caught it.

All seven passed on the first run — the chain was already correct, and is now
pinned.

## Verification

```
flutter analyze --fatal-infos --fatal-warnings  →  No issues found
flutter test                                    →  205 passed  (was 190)
dart run build_runner build                     →  no .g.dart drift
```

Every migration step is now covered: `1→current`, `2→current`, `4→5`, `6→7`,
`7→8`, `8→9`, `9→10`.

## Decision needed from you

**ADR 0009** — a shipped feature that cannot work on the primary platform, and is
advertised by its own UI, since both the alarm and timer editors offer a sound
file picker. My recommendation: if desktop stays primary, add
`just_audio_media_kit` (covers Windows and Linux in one dependency, registers
under the existing `just_audio` API so `AlarmOutput` does not change) and delete
`audioSupportedOnThisPlatform`. If the file pickers stay, the feature should work.

I did not add it — a native dependency pulling in libmpv is Consequential and
yours to approve.

**ADR 0008** (remote crash reporting) remains Open and untouched.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
