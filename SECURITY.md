# Security Policy

> **Maintainer:** Ajay Elika ([@ajay99511](https://github.com/ajay99511)) — ajayelika99511@gmail.com

## Supported Versions

**Nothing has been released yet.** There are no tags and no published build, so
the only supported version is the current `master` branch. `pubspec.yaml` reads
`1.0.0+1`, which is the Flutter template default and not a shipped release.

Once there is a tagged release, this table will say which ones receive fixes.
Until then, please report against `master` and include the commit SHA.

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security problems.**

Report vulnerabilities privately through GitHub Security Advisories:

1. Go to the **Security** tab of this repository.
2. Click **Report a vulnerability** (GitHub Private Vulnerability Reporting).
3. Fill in the advisory form with the details below.

### What to include

- A description of the vulnerability and its impact.
- Steps to reproduce (a minimal proof-of-concept if possible).
- Affected version(s) / commit, OS, and platform.
- Any relevant logs, stack traces, or screenshots.

### What to expect

- **Acknowledgement:** within **3 business days**.
- **Initial assessment:** within **7 business days**, including whether the
  report is accepted, needs more information, or is declined (with reasoning).
- **Fix & disclosure:** we aim to ship a fix for accepted, valid reports within
  **90 days**. We will coordinate a disclosure timeline with you and credit you
  in the release notes unless you prefer to remain anonymous.

## Scope

Chronos Planner is an **offline-first planner, with Android as its primary
platform** and Windows and Linux as secondary targets. It stores everything
locally and makes no network calls of its own.

Areas where a report is most likely to be valid:

- **Local data at rest.** The schedule database is unencrypted SQLite in the
  app's private storage. That is a deliberate trade for an offline planner, and
  not in itself a vulnerability — but a path by which *another* app, or any
  unprivileged process, can read or modify it is.
- **Exported Android components.** The boot receiver, the alarm notification
  channel and any notification intents. A way for a third-party app to schedule,
  cancel or spoof an alarm would be in scope.
- **Notification content on a lock screen.** Alarm notifications carry the
  user's own task title, which is intentional. A path that discloses *more* than
  the user chose to put there is not.
- **File handling.** A custom alarm sound is an absolute path the user picked,
  read back when the alarm fires. Path traversal, or reading a file the user did
  not select, is in scope.
- **Input handling.** Task titles and descriptions reach SQLite. Most queries go
  through Drift's prepared statements, but there is hand-written SQL in the task
  history query — injection there would be a valid report.
- **Unexpected network traffic.** The app makes no network calls. `INTERNET` and
  `ACCESS_NETWORK_STATE` appear in the merged manifest because `just_audio`
  declares them, not because anything uses them. Observed traffic leaving the
  device is therefore worth reporting.
- **Permission escalation.** The app requests notification and exact-alarm
  permissions. A way to obtain more than it asks for is in scope.

Out of scope:

- Anything requiring physical access to an unlocked device, a rooted device, or
  USB debugging enabled.
- The absence of at-rest encryption for the local database, considered on its
  own. If you think it should be encrypted, open a feature request — that is a
  design discussion, not an advisory.
- Reports against versions other than current `master`.
- Vulnerabilities in a dependency with no demonstrated path through this app.
  Report those upstream; Dependabot advisories cover the rest.

## Known gaps we already know about

Reporting these is not necessary, though a concrete exploit path for one would
be very welcome:

- There is **no remote crash reporting**, so a crash on a user's device is not
  visible to us at all
  ([ADR 0008](docs/decisions/0008-error-reporting-sink.md)).
- Release builds are **not minified or resource-shrunk**, so the shipped Dart
  code is more legible than it needs to be.
- **On-device alarm behaviour is unverified**: notification delivery, reboot
  survival and permission denial have unit tests behind the platform seam but
  have not been exercised on real hardware.
