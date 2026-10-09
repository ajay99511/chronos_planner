<!--
This text becomes the PR description automatically. Delete the sections that do
not apply rather than leaving them empty, and delete these comments as you go.

Keep it short. The point of each heading is the reasoning that disappears
otherwise -- the diff already says what changed.
-->

## What this changes

<!-- One or two sentences. What is different for a user or a caller after this? -->

## Why

<!--
The problem, not the solution. If this is a fix, what was the user-visible
symptom? If there is an issue, link it: "Closes #123".
-->

## Alternatives considered

<!--
What else you tried or rejected, and the specific reason it lost. Delete this
heading only if there genuinely was one way to do it.

If this decision is expensive to reverse -- a dependency, a schema change, a
platform permission, a data format -- record it in docs/decisions/ instead and
link the ADR here. See docs/decisions/README.md.
-->

## Verification

<!-- Paste real output. "Tests pass" is not evidence; the count is. -->

```
flutter analyze --fatal-infos --fatal-warnings  →
flutter test                                    →
```

- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean
      <!-- The bare `flutter analyze` is NOT the gate. CI fails on infos. -->
- [ ] `flutter test` passes, and new behaviour has a test that fails without the change
- [ ] `dart run build_runner build --delete-conflicting-outputs` leaves no diff
      <!-- Only if you touched lib/data/local/tables.dart or any *.g.dart source. -->
- [ ] `flutter build apk --debug` succeeds
      <!-- Android is the primary target. Required for anything touching lib/ or android/. -->

### On a device or emulator

<!--
Android is the primary platform and most of what matters about it cannot be
proven by a unit test. Tick what you actually ran; say "not run" rather than
leaving it ambiguous.
-->

- [ ] Not applicable -- no runtime behaviour changed
- [ ] Ran on Android: API level ___, device/emulator ___
- [ ] Alarms still fire with the app killed
- [ ] Alarms still survive a reboot
- [ ] Permission denial still degrades gracefully

## What is NOT verified

<!--
Required. The single most useful line in a review here. If everything is
covered, write "Nothing -- every path above is exercised" and mean it.

Known-unverifiable things in this repo: notification delivery, reboot survival,
and release-build behaviour under minification.
-->

## Risk and reversibility

<!--
How would this be undone if it turns out to be wrong? A one-way door --
a published applicationId, a destructive migration, a stored data format --
needs saying out loud, because it cannot be reverted by a revert.
-->

- [ ] This is a two-way door: reverting the commit is enough
- [ ] This is a one-way door, described above

## Schema and data

<!-- Delete this section unless you touched lib/data/local/. -->

- [ ] `schemaVersion` bumped, with a migration step for the new version
- [ ] Migration covered in `test/data/` across the whole chain, not just the new step
- [ ] Destructive steps quarantine rows rather than delete them (ADR 0005)

## Docs

- [ ] ADR added or amended if a decision here is expensive to reverse
- [ ] `CHANGELOG.md` updated under `Unreleased` for anything user-visible
- [ ] Comments explain *why*, not what, where the reason is not obvious from the code
