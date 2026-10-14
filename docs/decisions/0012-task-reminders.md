# 0012 — Per-task reminders, on one OS notification schedule

**Status:** Accepted. Extends [0010](0010-android-first-os-level-alarms.md).
Design record: [../TASK_REMINDERS_DESIGN.md](../TASK_REMINDERS_DESIGN.md).

**Decision:** A scheduled task can carry a reminder that fires a chosen number
of minutes before it starts, delivered by the operating system so it arrives
with the app closed. Alarms and reminders are two *kinds* of one
`ScheduledNotification`, and a single `NotificationCoordinator` owns the whole
OS-level schedule.

## Context

The ask was "toggle notifications per task, delivered while the user is outside
the app". Three things had to be settled before any of it could be built.

**It is not push.** A local scheduled notification already fires with the app
killed and survives a reboot. Push would add a backend, an `INTERNET`
permission and a dependency on connectivity to an app whose value is that it
works offline. Push only earns its place when a reminder has to originate
somewhere other than this device, which nothing in the product requires.

**The existing alarm path could not fire at all.** `flutter_local_notifications`
22.x declares only `POST_NOTIFICATIONS` and `VIBRATE` in its own manifest; since
v16 the host app must declare `ScheduledNotificationReceiver` and
`ScheduledNotificationBootReceiver`. This app declared the permissions but not
the receivers, so the OS fired the broadcast and nothing listened. Confirmed by
grepping the merged manifest of a real release build: one receiver, belonging to
AndroidX. Invisible to `flutter analyze`, to the test suite (the seam is mocked)
and to the build. Fixed first, as a prerequisite.

**Wholesale replacement needs a single owner.** `sync()` cancels everything and
reschedules, which is what keeps the OS schedule from drifting from what the
user sees (0010). Add a second service syncing reminders the same way and the
two alternately erase each other; the loser silently stops delivering. There was
also a latent id collision: `notificationIdFor(uuid)` gave a task's alarm and
that same task's reminder the *same* notification id, by construction.

## Value and risk, per option

### Where reminder state lives

| Option | Value | Risk | Verdict |
|---|---|---|---|
| **A. Two columns on `tasks` and `template_tasks`** | A reminder has no independent lifetime — it is a property of a task, which is how the request itself phrases it. Inherits `ON DELETE CASCADE` free. No join on the hottest query in the app. | Two columns per table to migrate, and a third notification source later needs its own. | **Chosen** |
| B. A `reminders` table keyed by owner | More extensible; supports several reminders per task. | Needs its own cascade and orphan sweep — this repo has already paid for orphan cleanup once (0005, migration v9). Adds a join to the week read. Buys extensibility that `ScheduledNotification` already provides. | Rejected |

Option A, because the extensibility B was bought for is recovered by the value
type: a third source converges on `ScheduledNotification` and the coordinator
does not change.

### How reminders reach the coordinator

| Option | Value | Risk | Verdict |
|---|---|---|---|
| **A. `ScheduleRepository.watchUpcomingDays`** (drift `.watch()`) | Cannot drift out of step with the database — the same guarantee the todo-alarm path already has. ~15 lines in `TaskDao`. | A drift watch binds its date variables at subscription, so the rolling window must be re-subscribed at a day rollover. | **Chosen** |
| B. Call the notifier from `ScheduleStateProvider` after each mutation | No new query. | Couples a UI provider to notifications and silently misses any write not going through it — recurring auto-apply, undo, a future importer. Re-creates the drift 0010 designed out. | Rejected |

## Consequences

- Easy: a reminder reaches the user without the app running, on Android and —
  as a side effect, since the plugin supports them — on Windows, Linux and
  macOS too.
- Easy: a third notification source plugs in by projecting to
  `ScheduledNotification`; nothing else changes.
- Separate channels (`chronos_alarms`, `chronos_reminders`) mean Android's
  per-channel settings let a user silence nudges while keeping alarms loud. One
  channel would have taken that choice away. Alarms stay `ongoing` and
  undismissable; reminders are swipeable, because a nudge that cannot be
  dismissed is an annoyance.
- Notification ids are namespaced by kind (`'reminder:$id'`), so an alarm and a
  reminder on the same entity can coexist. There is a regression test for
  exactly this.
- `AlarmSchedulerService` no longer touches the OS schedule or notification
  permission; both moved to `NotificationCoordinator`. It keeps the in-app
  ringing experience — timer, looping sound, dismiss overlay — which is a
  different job with a different lifetime.
- The pending schedule is capped at 48, soonest first. **iOS holds at most 64
  pending local notifications** and silently discards the rest; recent Android
  caps an app's alarms in the hundreds. A week of full plans with reminders on
  every block reaches either. Sorting before truncating means the ones kept are
  the ones about to happen.
- `tz.local` is re-resolved on every `sync()`, not once at startup: a user who
  crosses a timezone keeps the same process alive, and a reminder resolved
  against the old zone fires at the wrong wall-clock time with nothing to
  explain why.
- **Migration ordering is now load-bearing.** `TableMigration` rebuilds a table
  from the *current* Dart definition, and the v5 and v10 steps both rebuild
  `tasks` and `template_tasks`. A column added in a later branch therefore has
  no source to copy from, and the rebuild dies on drift's generated
  `CHECK (reminder_enabled IN (0, 1))`. The v11 `ALTER TABLE`s run at the **top**
  of `onUpgrade`, before every other step, and the comment there says so. Any
  future additive column belongs in the same place.
- Reminder state is carried on `template_tasks` as well, so applying a WorkPlan
  does not drop the reminders set on it.
- Hard: two delivery paths still exist for alarms (OS notification and in-app
  overlay) and remain deliberately non-exclusive, per 0010.
- **Unverified:** every scheduling *decision* is unit-tested behind the
  `ScheduledNotifier` seam, and the manifest receivers are confirmed present in
  the merged manifest of a real build. **Whether a reminder actually arrives on
  a device has not been tested** — that needs hardware this environment does not
  have. The checklist in
  [../TASK_REMINDERS_DESIGN.md §8](../TASK_REMINDERS_DESIGN.md) is required
  before release.
- Reversing: delete the coordinator, pass the alarm list straight to the
  notifier, drop two columns. The seam keeps the platform dependency in one
  file.

## Deliberately not built

Named so they do not creep in later as assumed scope:

1. **Notification actions** ("Done", "Snooze"). Needs `ActionBroadcastReceiver`,
   a `@pragma('vm:entry-point')` handler and — because that handler runs in an
   isolate with no access to app state — **its own database connection**. An
   architectural change, not a feature flag. The highest-value next item.
2. **Full-screen-intent reminders.** Android 14 restricts
   `USE_FULL_SCREEN_INTENT` to alarm and calling apps; a reminder would not
   qualify, and should not.
3. **Deep-linking a tap to the task.** The payload already carries
   `kind:ownerId`, so the data is there; the routing is not.
4. **Reminders on notes and checklists.** They have no due moment yet, so this
   needs a product decision first, not more plumbing.
5. **A global default lead time.** The per-task value already persists, and
   there is no settings screen to host a global one. `defaultReminderLeadMinutes`
   is the single place to change it meanwhile.
6. **Quiet hours.** Per-task opt-in is self-limiting, so this is premature.
