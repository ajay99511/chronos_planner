# 0011 — `pubspec.yaml` is the only version, and the build number never resets

**Status:** Accepted

**Decision:** `version:` in `pubspec.yaml` is the single source for both Android
version fields. The name before the `+` follows semver and changes only on a
release; the build number after it **increases on every build handed to anyone**
and is never reset when the name changes. Releases are marked `v<name>` as a git
tag, and the first one waits for a signing key
([ADR 0010](0010-android-first-os-level-alarms.md)).

**Context:** Two mechanisms make this more constrained than it looks.

- **Google Play treats a `versionCode` as permanently spent.** Once an upload
  claims a number, that number can never be re-used in that listing, and a lower
  number can never follow a higher one.
- **`--split-per-abi` rewrites the number.** The Flutter Gradle plugin overrides
  it per ABI as `abiVersionCode * 1000 + versionCode`, with armeabi-v7a = 1,
  arm64-v8a = 2 and x86_64 = 4 — so `1.0.0+1` ships as 1001, 2001 and 4001. This
  is how one listing serves three APKs, and it is also a **ceiling: a build
  number of 1000 or more collides with the next ABI's range** and silently
  inverts Play's ordering.

`android/local.properties` holds `flutter.versionName` / `flutter.versionCode`,
which makes it look like a place to set them. It is a git-ignored cache that the
`flutter` tool rewrites from `pubspec.yaml` on every build. Editing it appears to
work, then reverts.

The project is pre-release — no tags, nothing published, one developer — so the
scheme is still free to choose. After the first published upload it is not.

**Alternatives:**

- **Reset the build number per version name** (`1.0.0+1`, then `1.1.0+1`) — the
  reading of "build 1 of version 1.1.0" that most people reach for first. Play
  does not scope the number to the name, so the second `+1` is a number already
  spent and the upload is rejected.
- **Derive the build number from a date or a CI run number** — monotonic for
  free, and the usual answer at larger scale. Here it breaks immediately:
  `20261011` is far past the 1000 ceiling, so it collides across ABIs. It also
  decouples the artifact from the commit that produced it.
- **Set `versionCode` / `versionName` in `build.gradle.kts` directly** — two
  sources that silently disagree, and the `local.properties` regeneration above
  makes the disagreement hard to see.
- **`-Pforce-version-code-ignoring-abi=true`** to escape the ceiling — then all
  three APKs carry the same number and Play refuses the set outright. It exists
  for builds that are not going to Play at all.
- **Automate the release in CI now** — rejected for the moment, not on merit: it
  needs the keystore in repository secrets, which does not exist yet, so it would
  be written unverified against a process nobody has run once by hand.

**Consequences:**

- Easy: bumping a version is one line, and every artifact traces to a tag.
  Nothing has to be kept in sync by hand.
- Hard: roughly 999 builds of headroom before the ABI ceiling. Ample, but it is a
  ceiling with no warning attached — the collision shows up as Play mis-ordering
  releases, not as a build failure. If it is ever approached, move to an app
  bundle, which needs no per-ABI offsetting.
- Hard: the discipline is manual. Nothing in CI fails a PR that bumps the version
  without touching `CHANGELOG.md`, or hands out a build without bumping. That
  check is deliberately deferred until the manual process has been run once.
- Reversing: the scheme itself is free to change while nothing is published.
  Afterwards, individual spent `versionCode`s are permanent, so the *name* can be
  re-chosen but the number can only ever go up.
