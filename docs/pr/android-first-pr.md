# Android-first: release blockers + OS-level alarms

Reorients the app for Android as the primary target, Windows secondary.

**Base:** `master` · **Head:** `android-first-alarm-reliability` · 9 commits

## Two things had to be true before any feature work mattered

The Android build config was the untouched Flutter template. Two items made the
app **unshippable regardless of the Dart code**:

1. `applicationId` was still `com.example.chronos_planner` — Google Play rejects
   any `com.example.*` id outright.
2. Release builds were signed with the **debug key**, per the template's own
   comment. Anyone can reproduce that key.

Neither is mine to decide: an applicationId is permanent once published and must
be a domain you control, and a keystore is a secret. So instead of guessing, the
build now **refuses** to produce a release with either problem, and says why:

```
> Release build blocked:
    - applicationId is still 'com.example.chronos_planner'. Google Play rejects
      com.example.*; set a domain you control ...
    - No android/key.properties, so this build is signed with the debug key ...
```

Verified by running it. `-PallowUnshippableRelease=true` downgrades it to a
warning so the guard doesn't block its own testing.

## The value/risk calculation

Android-first **inverts** the earlier assessment. Desktop-first, the blocker was
`just_audio` having no Windows implementation. Android-first, `just_audio` works
— so the real defect is the one ADR 0006 recorded: alarms not firing when the
app is closed. On Android that isn't a limitation, it's the feature not existing.

| Option | Value | Risk | Verdict |
|---|---|---|---|
| **`flutter_local_notifications`** | **High** — fires with the app killed, survives reboot. Verified to endorse **all six** platforms this app targets, so it fixes Android *and* covers Windows | **Moderate** — notification UX differs from the in-app overlay; needs channel, permissions, IANA timezone; 3 deps; not device-verifiable here | **Chosen** |
| `android_alarm_manager_plus` | High, Android only | **Higher** — background isolate, no UI, its own DB connection, less maintained | Rejected |
| Full-screen intent | Highest fidelity | `USE_FULL_SCREEN_INTENT` is Android-14-restricted; needs the above underneath anyway | Deferred |
| `just_audio_media_kit` | **Low now** — desktop secondary; Windows gets a notification sound anyway | libmpv native deps | Deferred; ADR 0009 downgraded |

Full reasoning in [ADR 0010](../decisions/0010-android-first-os-level-alarms.md).

## Design

Platform code kept thin so the decisions stay testable:

- **`AlarmNotifier`** is the seam. `sync()` replaces the whole OS schedule from
  the repository's current list rather than diffing — it cannot drift.
- **`schedulableAlarms()`** is pure: enabled, has a time, still in the future.
  Scheduling a past alarm either fires at once or is dropped depending on
  platform; neither is what was asked for.
- **`notificationIdFor()`** bridges UUIDs to integer notification ids using
  FNV-1a, *not* `String.hashCode` — which Dart doesn't guarantee stable across
  versions, and a shifted id leaves an alarm scheduled in the OS that nothing
  can cancel. Pinned test values were cross-checked against an independent
  FNV-1a implementation; my first guessed constant was wrong and the test caught
  it.
- Device IANA timezone via `flutter_timezone`. Without it `tz.local` is UTC and
  every alarm fires at the wrong wall-clock time. A fixed offset would instead
  be wrong twice a year — worse, because it looks correct.
- `exactAllowWhileIdle`, alarm-category channel, `ongoing`/`autoCancel: false`
  so an alarm can't be brushed away by accident.

Declining notification permission previously made every scheduled alarm silently
useless. The alarms tab now shows a banner offering the grant inline.

## Permission is asked for where it makes sense

Before: nothing ever prompted. The only route to a grant was noticing an orange
banner on the alarms tab, which a user with no alarms yet has no reason to read.

Now the prompt happens when the user saves their first alarm — the first moment
the request has a visible reason behind it. On Android a denial is effectively
permanent (a second `requestNotificationsPermission()` returns false without
showing anything), so *when* you ask is not a cosmetic choice: a prompt the user
cannot explain is the one they dismiss forever.

`ensureNotificationPermission()` re-reads the OS rather than trusting the cached
`notificationsBlocked` flag. That flag is only as fresh as the last sync, and the
case that matters most is a cold start where the first alarm is created before
the sync has settled — which would have skipped the prompt precisely once, on the
one run where it counted. A platform with no such permission is treated as
permitted, so nobody is nagged for a grant they cannot give.

If the user refuses, the alarm is still saved and a snackbar says it will not go
off and where to change that. The alarm is never the thing that gets lost.

## A silent failure found on the way

Making `_save()` async turned up `unawaited_futures` on all four write paths.
They were never awaited, so a rejected write set `errorMessage` on the provider
while the sheet closed as if it had worked — indistinguishable from success. The
writes are now awaited, and a failure keeps the sheet open with the reason, so
the user does not lose what they typed to a failure they had no part in.

## The sound picker no longer promises what it cannot deliver

`just_audio` has no Windows or Linux implementation, so both editors were
offering a file picker that stored a path nothing would ever play. Both are now
gated on `audioSupportedOnThisPlatform` and say so instead. This is the one cheap
item [ADR 0009](../decisions/0009-audio-unsupported-on-windows-and-linux.md)
recommended doing sooner; it is now closed.

## Verification

```
flutter analyze --fatal-infos --fatal-warnings  →  No issues found
flutter test                                    →  234 passed  (was 205)
flutter build apk --debug                       →  succeeds, permissions merged
flutter build apk --release                     →  blocked as designed
```

## ⚠️ What is NOT verified

**Whether a notification actually arrives on a device.** That needs a device or
emulator, which this environment doesn't have. The build is verified to compile
with the plugins and permissions merged, and every decision behind the seam is
unit-tested — but **treat on-device verification as required before release**:

1. Alarm fires with the app killed
2. Alarm survives a reboot
3. Permission denial degrades gracefully — the *decision* is unit-tested, but
   whether the system dialog appears at the right moment is not
4. The exact-alarm settings screen on API 31–32, which is a navigation away from
   the app rather than a dialog

## Deliberately excluded

- **Minification / resource shrinking.** Correct for a Play release, but can
  break at runtime in ways a debug build won't reveal, and I can't run a device
  smoke test. Bundling an unverifiable optimisation into a blocker fix is the
  wrong trade.
- **`INTERNET` / `ACCESS_NETWORK_STATE`** are merged in by `just_audio`. An
  offline-first planner asking for network access reads badly on a Play listing,
  but removing a plugin-declared permission needs device verification.
- **Kotlin 2.2.20** — the build warns Flutter will soon require ≥2.3.20. Builds
  fine today; worth scheduling.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
