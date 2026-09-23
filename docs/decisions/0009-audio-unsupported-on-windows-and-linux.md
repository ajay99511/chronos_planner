# 0009 — Alarm and timer sound do not work on Windows or Linux

**Status:** **Open.** Needs a product decision. This is a shipped feature that
does not work on the primary platform.

**Decision (current):** The app detects the unsupported platform up front and
tells the user plainly — "Alarm sound is not supported on this platform" — rather
than failing silently or blaming their file. No audio backend has been added.

**Context:** `just_audio` 0.9.46 declares platforms for **android, ios, macos
and web only.** Verified in the package's own `pubspec.yaml`, and consistent with
`.flutter-plugins-dependencies`, which registers `just_audio` for android, ios
and macos and *not* for windows or linux.

This app targets Windows and Linux as well. `window_manager`, `screen_retriever`
and the 1200×800 hidden-title-bar window are all desktop-only, and the focus-HUD
mode resizes the desktop window — so desktop is not a secondary target, it is the
main one.

The consequence: **both sound-producing features are silent on Windows and
Linux.** Alarms ring visually with no audio; timers complete with no chime. Until
now neither said so — the alarm path claimed the file had moved, and the timer
path swallowed the failure into a `debugPrint`, so the user saw nothing at all.

This was not in the original audit. It was found while investigating 0006.

**Alternatives:**

- **Add a desktop audio backend** — `just_audio_windows`, or `just_audio_media_kit`
  which covers Windows and Linux together. Federated backends register under the
  existing `just_audio` API, so `AlarmOutput` would not change. This is a new
  dependency with native build implications (media_kit pulls in libmpv), which
  makes it Consequential rather than a drive-by `pub add`.
- **Swap to a package with first-class desktop support** — e.g. `audioplayers`.
  Touches every audio call site, though `AlarmOutput` already contains most of
  them.
- **Drop sound on desktop and lean on the window** — the alarm already calls
  `windowManager.show()` + `focus()`, so it does demand attention. Cheapest, and
  arguably defensible for an app running on the machine in front of you. It makes
  the audio file picker in the alarm and timer editors misleading on desktop,
  which would need addressing.
- **Do nothing** — no longer silent, since the app now says sound is unsupported,
  but a user who picked a sound file still cannot get one.

**Consequences of the current state:**

- Easy: honest. Nobody wastes time re-picking a file that was never the problem.
- Hard: the feature is advertised by its own UI — both editors offer a file
  picker — and cannot deliver on the primary platform.
- Reversing: adding a backend is additive and `AlarmOutput` absorbs it;
  `audioSupportedOnThisPlatform` becomes the thing to delete.

**Recommendation:** if desktop stays the primary target, add
`just_audio_media_kit` (Windows + Linux in one dependency) and delete the
platform check. If the file pickers are to stay, the feature should work.
