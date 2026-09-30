# 0006 — Alarms are scheduled in-process

**Status:** **Superseded by [0010](0010-android-first-os-level-alarms.md).**

Kept for the reasoning, not the conclusion. Scope later changed to Android-first
and the open platform question below was answered: `flutter_local_notifications`
does endorse Windows, so OS-level scheduling covers both targets. Alarms now
fire with the app closed. What remains accurate here is the in-process
behaviour, which is still the foreground path, and the missed-alarm reporting.

**Decision as recorded at the time:** `AlarmSchedulerService` arms a single
in-process `Timer` for the next enabled alarm, and alarms therefore did not fire
when the app was closed. Rather than pretending otherwise, the app reports which
alarms it missed — that part is still live, and still useful, because an alarm
can be missed while the process is dead even with OS scheduling in place.

**Context:** This was originally recorded as Open, on the assumption that the
fix was simply "add an OS-level scheduling package". Investigating it turned up
something that changes the shape of the problem.

`just_audio` 0.9.46 declares platforms for **android, ios, macos and web only**
(verified in the package's own `pubspec.yaml`, not inferred from behaviour).
This app also targets **Windows and Linux** — that is where `window_manager`
runs, with a 1200×800 window and a hidden title bar, which is plainly the
primary experience. So on the main desktop platform an alarm could not make a
sound even if it fired perfectly on time.

That reorders the work. Firing reliably matters less than the fact that, on the
platform most users are on, the alarm is silent regardless. Sound is tracked
separately in 0009.

What *could* be fixed without a dependency has been:

- Missed alarms are collected and reported by name instead of being disarmed in
  silence. A missed alarm the user is told about is a limitation; one that
  vanishes is lost trust.
- `refreshSchedule()` recomputes against the wall clock on app resume. A Dart
  `Timer` does not survive the machine sleeping through its deadline.
- A dropped alarm stream resubscribes with bounded backoff rather than ending
  scheduling for the session.
- Why a sound failed is reported accurately, so an unsupported platform is not
  described as a missing file.

**Alternatives:**

- **An OS-level scheduling package** (`flutter_local_notifications` or similar) —
  still the real fix for firing-while-closed. **Its Windows support has not been
  verified here and must be, before anyone commits to it**; if it does not cover
  Windows, it solves the secondary platforms and leaves the primary one exactly
  as it is. Also a permanent dependency touching platform configuration on every
  target, which `security-privacy.md` treats as Consequential.
- **Windows Task Scheduler / a background service** — genuinely fires when the
  app is closed on the primary platform, and is a substantially larger piece of
  work with its own install and permission story.
- **Rename the feature to in-session reminders** — cheapest, and honest. Still
  available; the missed-alarm reporting makes the current behaviour legible
  either way.

**Consequences:**

- Easy: no dependency, no permission prompts, and the whole service is unit
  testable behind the `AlarmOutput` seam.
- Hard *at the time*: the feature did not fire when closed. Resolved by 0010.
- Reversing: additive. OS scheduling would sit alongside the in-process timer,
  which stays as the foreground fast path.

**What changed this:** the verified answer. `flutter_local_notifications`
22.3.1 endorses android, ios, macos, linux, windows and web, so the objection
in the first alternative below does not hold. See 0010.
