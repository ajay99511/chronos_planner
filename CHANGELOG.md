# Changelog

All notable changes to Chronos Planner are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Nothing has been released yet.** `pubspec.yaml` reads `1.0.0+1`, but there
> are no tags and no published build, so every entry below is unreleased. The
> first tagged release needs an `applicationId` and a signing key that are not
> in this repository — see [SECURITY.md](SECURITY.md) and
> [ADR 0010](docs/decisions/0010-android-first-os-level-alarms.md).

Entries describe what changed for a *user or a caller*. Refactors with no
observable effect are left to the git history, which is where they belong.

## [Unreleased]

### Added

- **Alarms are registered with the operating system**, so they fire with the app
  closed and survive a reboot. Previously a single in-process `Timer` armed the
  next alarm, which an Android process kill or Doze silently ended.
  ([ADR 0010](docs/decisions/0010-android-first-os-level-alarms.md))
- **Notification permission is requested when the first alarm is saved**, which
  is the first moment the request has a visible reason behind it. Declining
  leaves the alarm saved and says plainly that it will not go off.
- **Missed alarms are reported by name** instead of being disarmed in silence,
  and the schedule is recomputed against the wall clock on resume.
- **Task invariants are enforced in SQL** as well as in the app (schema v10):
  title length, `HH:MM` time format, and non-negative costs.
  ([ADR 0004](docs/decisions/0004-invariants-in-both-app-and-schema.md))
- **Accessibility**: screen-reader labels on interactive elements, WCAG AA
  contrast for accent text, minimum touch targets, and respect for the
  platform's reduce-motion setting.
- **A release-build guard**: `bundleRelease` and `assembleRelease` refuse to
  produce an artifact while the `applicationId` is still `com.example.*` or the
  build would be signed with the debug key, and say which. Override with
  `-PallowUnshippableRelease=true`.
- **Decision records** in [`docs/decisions/`](docs/decisions/) for the choices
  that are expensive to reverse, including the ones still open.
- **CI** running analyze, tests, and a check that generated Drift code is not
  stale.

### Changed

- **Android is the primary platform**; Windows and Linux are secondary. This
  reversed an earlier assessment, and with it the priority of the alarm work.
  ([ADR 0010](docs/decisions/0010-android-first-os-level-alarms.md))
- **The alarm sound picker is withheld on Windows and Linux**, where `just_audio`
  has no implementation, rather than collecting a file path that would never
  play. ([ADR 0009](docs/decisions/0009-audio-unsupported-on-windows-and-linux.md))
- The Android app label is `Chronos` rather than the template's `chronosky`.
- Navigation is derived from a single feature-tab registry instead of parallel
  switch statements that could disagree.

### Fixed

- **Foreign keys were never enforced.** SQLite defaults `PRAGMA foreign_keys` to
  *off* for every new connection, so the schema's relationships were decorative
  and orphaned rows could accumulate. They are now enabled on open, and
  pre-existing orphans are swept on migration.
- **A failed save looked exactly like a successful one** in the new-item sheet:
  the write was never awaited, so a rejection set an error message while the
  sheet closed. Failures now keep the sheet open and say why.
- **The v8 duplicate-day merge could strand tasks irreversibly.** It now fails
  closed and keeps a backup, and destructive migration steps quarantine rows
  rather than delete them.
  ([ADR 0005](docs/decisions/0005-quarantine-not-delete-in-migrations.md))
- **Task invariants were only checked by `assert`**, which the AOT compiler
  strips — so release builds enforced nothing.
- **`Error`s escaped the `Result` envelope**, because Dart's `Error` does not
  implement `Exception` and the repository guards only caught the latter.
- **Uncaught errors were discarded in release builds**; they now reach the
  platform log. Where they go beyond that is still open
  ([ADR 0008](docs/decisions/0008-error-reporting-sink.md)).
- **A silent alarm was indistinguishable from a muted device.** The reason is
  now reported, and an unsupported platform is no longer described as a missing
  file.
- A dropped alarm stream resubscribes with bounded backoff instead of ending
  scheduling for the session; the same retry in `TodoProvider` is now
  cancellable and bounded.
- `TextEditingController`s in dialogs were not disposed when the route popped.
- Structural equality and `hashCode` disagreed on models with collection fields,
  which breaks any set or map keyed by them.
- The schedule screen crashed on Android, and migrations failed on first run.

### Performance

- `ScheduleView` rebuilds are scoped with content-comparing `Selector`s, rather
  than rebuilding the tree on every provider notification.
- The per-day task read in `getUpcomingDays` is batched into one query instead of
  one per day.
- `getSortedTasks` is memoized rather than re-sorting on every build.
- 390 lines of dead code removed.

### Security

- Foreign-key enforcement and schema-level invariants close the paths by which
  invalid or orphaned rows entered the database.
- Android permissions are declared explicitly and individually justified in
  `AndroidManifest.xml`, rather than inherited silently from plugins.

### Known limitations

Deliberate, and recorded rather than hidden:

- **Notification delivery, reboot survival and permission denial are not
  verified on a device.** Every decision behind the platform seam is unit
  tested; the platform itself is not. Treat on-device verification as required
  before any release.
- A **custom** alarm sound cannot play on Windows or Linux
  ([ADR 0009](docs/decisions/0009-audio-unsupported-on-windows-and-linux.md));
  alarms there arrive as a system notification.
- There is **no remote crash reporting**
  ([ADR 0008](docs/decisions/0008-error-reporting-sink.md)).
- The app ships **one locale**, behind a seam that keeps adding a second local
  ([ADR 0007](docs/decisions/0007-i18n-seam-without-localisation.md)).
- `INTERNET` and `ACCESS_NETWORK_STATE` are merged into the manifest by
  `just_audio`, although the app makes no network calls.

[Unreleased]: https://github.com/ajay99511/chronos_planner/commits/master
