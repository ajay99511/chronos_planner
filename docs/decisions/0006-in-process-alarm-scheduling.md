# 0006 — Alarms are scheduled in-process only

**Status:** **Open.** Needs a product decision before the alarm feature can
honestly be described as working.

**Decision (current — by default rather than by choice):**
`AlarmSchedulerService` arms a single in-process `Timer` for the next enabled
alarm. Alarms therefore do not fire when the app is closed, and because firing is
one-shot they do not fire late either.

**Context:** The service is explicit about its scope in its own doc comment, and
it deliberately disarms alarms missed by more than a minute so a user is not
ambushed on relaunch. Reliability *while running* has been brought up to standard:
the stream resubscribes with bounded backoff instead of dying silently on the
first error, disposal is guarded across every `await`, and a missing sound file is
surfaced in the UI rather than logged and forgotten.

None of that changes the headline limitation. An alarm feature that misses alarms
is arguably worse than no alarm feature, because users build trust in it.

**Alternatives:**

- **`flutter_local_notifications`, or a platform alarm manager** — the real fix. A
  new permanent dependency that touches platform configuration on every target,
  which `security-privacy.md` treats as Consequential: it needs vetting and an
  owner, not a drive-by `pub add`.
- **A background isolate or periodic worker** — still dies with the process on
  desktop, so it solves nothing here.
- **Rename the feature to in-session reminders** — a product decision rather than
  an engineering one. Legitimate, and much cheaper, but it changes what the feature
  promises.

**Consequences:**

- Easy today: no extra dependency, no permission prompts, and the whole service is
  unit-testable behind the `AlarmOutput` seam.
- Hard: the feature's central promise is unmet, and the limitation is visible only
  in a doc comment.
- Reversing: adding OS scheduling is additive — the in-process timer stays as the
  foreground fast path.
