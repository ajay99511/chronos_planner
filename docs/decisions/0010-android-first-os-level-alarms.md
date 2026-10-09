# 0010 — Android-first: schedule alarms with the OS

**Status:** Accepted. Supersedes the "Open" state of [0006](0006-in-process-alarm-scheduling.md)
and downgrades [0009](0009-audio-unsupported-on-windows-and-linux.md).

**Decision:** Add `flutter_local_notifications` (with `timezone` and
`flutter_timezone`) and register every enabled alarm with the operating system,
so it fires when the app is backgrounded, killed or the device has rebooted. The
existing in-process timer stays as the foreground path.

## Context

Scope changed: **Android is the primary target**, Windows a secondary one to
accommodate later. That inverts the previous assessment.

Under the old desktop-first reading, the blocking problem was that `just_audio`
has no Windows implementation, so alarms were mute on the main platform (0009).
Android-first, that inverts: `just_audio` **does** support Android, so sound
works where it matters, and the real defect becomes the one 0006 recorded —
an alarm that does not fire when the app is closed. On Android that is not a
limitation, it is the feature not existing. Android routinely kills backgrounded
processes, and Doze suspends timers even when the process survives.

## Value and risk, per option

Assessed against the app's actual stage: pre-release (it could not even be
published until the previous commit — `applicationId` was still `com.example.*`),
Android primary, one developer.

| Option | Value | Risk | Verdict |
|---|---|---|---|
| **A. `flutter_local_notifications.zonedSchedule`** | **High.** Fires with the app killed; the plugin's boot receiver restores schedules after a reboot. Verified to endorse **android, ios, macos, linux, windows and web** — every platform this app targets, so it also gives Windows an audible notification without a native audio backend. | **Moderate.** Notification UX differs from the in-app full-screen overlay. Needs a channel, runtime permission, exact-alarm permission and IANA timezone data. Three new dependencies. Cannot be verified on a device from this environment. | **Chosen** |
| B. `android_alarm_manager_plus` | High, but Android only. | **Higher.** Runs a Dart callback in a background isolate with no UI and no access to the app's state, so it needs its own database connection. Narrower platform coverage and less active maintenance than A, for the same permission constraints. | Rejected |
| C. Full-screen-intent notification | Highest fidelity — reproduces a real alarm-clock screen over the lock screen. | Needs `USE_FULL_SCREEN_INTENT`, which Android 14 restricts to alarm and calling apps, plus more native wiring. Requires A underneath regardless. | Deferred — A first, C as a later enhancement |
| D. `just_audio_media_kit` (desktop audio) | **Low now.** Desktop is secondary, Android audio already works, and A gives Windows a notification sound anyway. | Moderate: pulls libmpv native dependencies into the desktop builds. | Deferred; 0009 downgraded |

Option A is chosen because it is the only one that fixes the primary platform,
covers the secondary platform as a side effect, and keeps the risk in
configuration rather than in architecture.

## Consequences

- Easy: an alarm now reaches the user without the app running. `sync()` replaces
  the whole OS-level schedule from the repository's current list, so it cannot
  drift out of step with what the user sees.
- Easy: Windows gets an audible alert, which softens 0009 from "silent" to
  "does not play your chosen file".
- Hard: two delivery paths now exist — the OS notification and the in-app
  overlay. They are deliberately not mutually exclusive; the in-app overlay is
  still the richer experience when the app is open, and suppressing one from the
  other would need process-state knowledge that is unreliable on Android.
- Hard: notification ids are integers and alarm ids are UUIDs. A stable 31-bit
  FNV-1a hash bridges them, chosen over `String.hashCode` because the latter is
  not guaranteed stable across Dart versions and these ids must survive a
  restart to be cancellable.
- **Unverified:** the scheduling *decisions* are unit-tested behind the
  `AlarmNotifier` seam, and the Android build is verified to compile with the
  permissions merged. **Whether a notification actually fires on a device has
  not been tested** — that needs a device or emulator, which this environment
  does not have. Treat on-device verification as required before release.
- Reversing: the dependency is isolated behind `AlarmNotifier`. Removing it
  means deleting one implementation and passing a no-op.

## Follow-ups this creates

1. On-device verification: alarm fires with the app killed; alarm survives a
   reboot; permission denial degrades gracefully.
2. Consider option C so an alarm presents over the lock screen.
3. Minification and resource shrinking for the release build (needs a device
   smoke test, so not bundled with the config fix).
4. `INTERNET` and `ACCESS_NETWORK_STATE` are merged into the manifest by
   `just_audio`. An offline-first planner requesting network access reads badly
   on a Play listing; removing a plugin-declared permission needs device
   verification.
