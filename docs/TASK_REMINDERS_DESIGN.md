# Task reminders — requirements and design

**Status:** Implemented. The decision is recorded as
[ADR 0012](decisions/0012-task-reminders.md); this document is the research and
requirements behind it, kept because the reasoning is longer than an ADR should
be.
**Date:** 2026-10-11
**Still outstanding:** the on-device pass in §8, and the deferred items in §4.

> Toggle notifications on or off per task, and have them reach the user while
> the app is closed.

This document is the research behind that request: what it actually requires,
what the codebase already provides, one confirmed blocker, and the design that
fits the app as it exists rather than a generic "add notifications" recipe.

---

## 1. The first thing to know: this is not push

The request says "push notification". The feature does not need push, and
should not use it.

| | Push (FCM / APNs) | Local scheduled notification |
|---|---|---|
| Needs a server | Yes | No |
| Needs `INTERNET` | Yes | No |
| Works offline / in flight mode | No | Yes |
| Works with the app killed | Yes | **Yes** |
| Works after reboot | Yes | Yes, via a boot receiver |
| Fires at an exact local time | Only if the server is reachable then | Yes |
| Per-device setup cost | Firebase project, keys, token refresh, a backend | None |

Every property the request actually asks for — *the user is outside the app and
still gets told* — is delivered by a **local scheduled notification**, which is
what [ADR 0010](decisions/0010-android-first-os-level-alarms.md) already chose
and what `flutter_local_notifications` already does in this app for alarms.

Push becomes the right answer only when a reminder has to originate somewhere
other than this device — a shared plan, a second phone, a web companion. None
of those exist. Introducing FCM now would add a backend, a network permission,
and a dependency on connectivity to an app whose entire value is that it works
offline.

**Requirement: no new network dependency. Reminders are local and offline.**

---

## 2. Confirmed blocker: the current alarm feature cannot fire on a device

Before any new feature is built on it, this has to be fixed, because reminders
will inherit the same defect.

`flutter_local_notifications` 22.x declares only `POST_NOTIFICATIONS` and
`VIBRATE` in its own manifest. Since version 16 the plugin requires the **host
app** to declare the two receivers that actually deliver a scheduled
notification and restore the schedule after a reboot.

`android/app/src/main/AndroidManifest.xml` declares the permissions (including
`RECEIVE_BOOT_COMPLETED`) but not the receivers. Evidence, from the merged
manifest of the last real release build:

```
$ grep -o 'android:name="[^"]*Receiver[^"]*"' \
    build/app/intermediates/merged_manifest/release/.../AndroidManifest.xml
android:name="androidx.profileinstaller.ProfileInstallReceiver"
```

One receiver, and it belongs to AndroidX. Consequences:

- `zonedSchedule` succeeds, the OS registers the alarm, the broadcast fires at
  the right moment — and nothing is listening, so **no notification is ever
  shown**.
- `RECEIVE_BOOT_COMPLETED` is held but unused, so **pending alarms are lost on
  reboot** anyway.

This is invisible in unit tests (the seam is mocked), invisible in
`flutter analyze`, and invisible in a build (it compiles fine). It only shows up
on a device, which ADR 0010 already flagged as unverified.

The fix is four lines inside `<application>`:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

`MY_PACKAGE_REPLACED` matters during development: without it every app update
silently drops the schedule.

**Fixed.** The receivers are declared, and confirmed present in the merged
manifest of a real build. Whether a notification then *arrives* still needs the
device pass in §8.

---

## 3. What "a task" means here — and why it is two things

The request says "once we have something on our radar". The app has two
different radars, and the design has to be explicit about which gets reminders.

| | `Tasks` (Schedule tab) | `TodoItems` (Tasks tab) |
|---|---|---|
| Model | `lib/data/models/task_model.dart` | `lib/data/models/todo_item_model.dart` |
| Time | `startTime`/`endTime` as `"HH:mm"`, plus the owning `DayPlan.date` | `scheduledAt` as a full `DateTime`, alarms only |
| Lives for | One calendar day | Indefinitely |
| Has notification state | **No** | Partly — `enabled`, used by alarm items |
| Created by | Hand, or by applying a WorkPlan | Hand |

So:

- **Schedule tasks are the gap.** A time-blocked day is exactly the thing worth
  being nudged through, and today it has no notification state at all. This is
  where the feature's value is.
- **Todo alarms already work** (modulo §2). They are a *ring-until-dismissed*
  alarm clock, not a reminder.
- **Notes and checklists have no time**, so a reminder means first giving them
  an optional due moment. Useful, but a smaller win than schedule tasks.

**Recommended v1 scope: schedule tasks.** Notes and lists in v2, reusing
everything built here.

### A reminder is not an alarm

These are different products and must not share a channel. Collapsing them is
the most common way this feature goes wrong.

| | Alarm (exists) | Reminder (new) |
|---|---|---|
| Intent | Wake me / stop me | Nudge me |
| Channel | `chronos_alarms` | `chronos_reminders` |
| Importance | `max` | `high` |
| Sound | Loops until dismissed | One notification sound |
| Dismissible | No (`ongoing: true`, `autoCancel: false`) | Yes |
| Category | `AndroidNotificationCategory.alarm` | `...reminder` |
| Fires | At an absolute moment | Lead time *before* a task starts |
| In-app behaviour | Full-screen dismiss overlay | Nothing; the notification is the whole feature |

Two channels is also the user's own control surface: Android's per-channel
settings let someone silence reminders while keeping alarms loud. One channel
takes that away.

---

## 4. Requirements

### Functional

| # | Requirement | Notes |
|---|---|---|
| F1 | Each schedule task can have a reminder toggled on or off | The headline ask |
| F2 | The toggle is reachable where the task is: detail panel and the add/edit sheet | Not buried in settings |
| F3 | A reminder fires with the app backgrounded, killed, or after a reboot | The point of the feature |
| F4 | Lead time is per task, from a fixed set: at start, 5, 10, 15, 30, 60 min before | A free-text minute field invites 7-minute reminders nobody wants |
| F5 | A global default lead time, used as the initial value for new toggles | One `Preferences` row |
| F6 | A task with a reminder shows that in the list without being opened | A bell glyph on the card |
| F7 | Completing a task cancels its reminder | A nudge for finished work erodes trust fastest |
| F8 | Deleting a task, or clearing a day, cancels its reminders | Falls out of §6's design for free |
| F9 | Reminders survive a WorkPlan being applied | A plan is the main way tasks get created, so reminder state belongs on template tasks too |
| F10 | When the OS will not deliver, the Schedule tab says so and offers the fix | The alarms list already does this; reuse it |
| F11 | Tapping a reminder opens the app | Deep-linking to the exact task is v2 |

### Non-functional

| # | Requirement | Why |
|---|---|---|
| N1 | No network permission, no backend | §1 |
| N2 | Correct across DST and timezone changes | A reminder is wall-clock: 09:00 means 09:00 in whatever zone the user is standing in |
| N3 | Scheduling decisions unit-testable without a device | The `AlarmNotifier` seam already establishes this; ADR 0010 |
| N4 | Bounded pending-notification count | iOS allows **64** pending local notifications; recent Android caps app alarms in the hundreds. A 7-day window of a full plan can approach both |
| N5 | A failure to schedule degrades, never crashes | Matches the existing `_syncOsSchedule` posture |
| N6 | Reminders do not clobber alarms, and vice versa | See the collision in §5 — this is a real defect waiting to happen |
| N7 | Additive migration; no data loss | ADR 0005 |
| N8 | Works on Windows and Linux too, as a side effect | The plugin supports them; no extra work, and it softens ADR 0009 further |

### Explicitly out of scope for v1

Named so they do not creep in:

- **Notification actions** ("Done", "Snooze 10m"). Needs `ActionBroadcastReceiver`,
  a `@pragma('vm:entry-point')` background handler, and — because that handler
  runs in an isolate with no access to app state — **its own database
  connection**. That is an architectural change, not a feature flag. Highest-value
  v2 item.
- **Full-screen intent** reminders. Android 14 restricts `USE_FULL_SCREEN_INTENT`
  to alarm and calling apps; reminders would not qualify, and should not.
- **Deep link to the task** on tap.
- **Quiet hours.** Per-task opt-in is self-limiting, so this is premature.
- **A daily agenda summary** ("5 blocks today") as an alternative to per-task
  reminders.
- **Recurring reminders** independent of the recurring-WorkPlan mechanism that
  already exists.

---

## 5. Two defects in the current notifier that reminders would inherit

Both are consequences of a design that assumed a single source of notifications.
They are cheap to fix now and expensive later.

### 5.1 `sync()` cancels everything, including the other feature's work

`LocalNotificationAlarmNotifier.sync` starts with `cancelAll()` and then
reschedules its whole list. That is sound — ADR 0010 chose wholesale replacement
precisely so the OS schedule cannot drift from what the user sees — but it is
only sound while **one** thing owns the OS schedule.

Add a second service that syncs reminders the same way and they alternately
erase each other. Whichever synced last wins; the other feature silently stops
working. Nothing in the type system prevents this.

### 5.2 Notification ids collide across kinds

`notificationIdFor(alarmId)` hashes a UUID to 31 bits. If a reminder's id is
derived from a task's UUID with the same function, then a task and a todo item
that happen to share an id get the **same** notification id, and one cancels the
other. More importantly, if a single entity ever has both an alarm and a
reminder, they are guaranteed to collide — same input, same hash.

Fix: namespace the key before hashing — `notificationIdFor('reminder:$taskId')`
versus `notificationIdFor('alarm:$alarmId')` — and make the namespace part of
the value type below so it cannot be forgotten at a call site.

---

## 6. Design

### 6.1 One owner of the OS schedule

Collapse the two problems in §5 into one answer: the notifier stops being
alarm-shaped and becomes a scheduler of *scheduled notifications*, of which
alarms and reminders are two kinds.

```dart
enum ScheduledNotificationKind { alarm, reminder }

/// One thing the OS should show at one moment.
@immutable
class ScheduledNotification {
  final ScheduledNotificationKind kind;
  final String ownerId;      // task or todo id, for cancellation and payload
  final String title;
  final String body;
  final DateTime fireAt;     // wall-clock local; resolved to tz at schedule time
  final String? soundPath;   // alarms only

  /// Namespaced so an alarm and a reminder on the same entity cannot collide.
  int get notificationId => notificationIdFor('${kind.name}:$ownerId');
}
```

```dart
abstract class ScheduledNotifier {       // today's AlarmNotifier, widened
  Future<void> initialise();
  Future<bool> hasPermission();
  Future<bool> requestPermission();

  /// Replaces the ENTIRE OS schedule with [items]. One caller, one list.
  Future<void> sync(List<ScheduledNotification> items);
  Future<void> cancelAll();
}
```

The channel, importance, sound, ongoing-ness and category are chosen from
`kind` inside the implementation — the one place that knows about platforms.

This keeps everything ADR 0010 earned (wholesale replace, testable decisions,
one platform file) and makes a second source safe instead of destructive.

### 6.2 Where reminders come from

```
TodoRepository.watchByType(alarm) ─┐
                                   ├─► NotificationCoordinator ─► ScheduledNotifier.sync()
ScheduleRepository.watchUpcoming() ─┘      (pure projection + horizon cap)
```

`ScheduleRepository` is `Future`-based today and has no stream. Two ways to feed
the coordinator:

| Option | Value | Risk | Verdict |
|---|---|---|---|
| **A. Add `watchUpcomingDays(int)`**, drift `.watch()` on the existing join | Cannot drift out of step with the database — the same guarantee the todo path already has. ~15 lines in `TaskDao` | A drift watch binds its date variable at subscription, so the rolling window must be re-subscribed at day rollover. `refreshIfDateChanged()` is already the hook for exactly that | **Chosen** |
| B. Call the notifier from `ScheduleStateProvider` after each mutation | No new query | Couples a UI provider to notifications, and silently misses any write that does not go through the provider (recurring auto-apply, undo, a future importer). Re-creates the drift that ADR 0010 designed out | Rejected |

### 6.3 The projection is a pure function

The rule — which tasks deserve a pending notification right now — is the part
worth testing, and it needs no platform:

```dart
/// Reminders the OS should hold, given the loaded week and the clock.
///
/// Pure: enabled, not completed, resolvable time, still in the future, and
/// within the horizon. Capped at [maxPending], soonest first, because iOS
/// allows only 64 pending local notifications and Android caps app alarms.
List<ScheduledNotification> remindersFor(
  List<DayPlan> days,
  DateTime now, {
  int maxPending = 48,
});
```

Fire time is `DayPlan.date` + `Task.startTime` − `reminderLeadMinutes`, parsed
through `ClockTime` (never `int.parse` at the call site — that is what
`clock_time.dart` exists to prevent). A task whose stored time will not parse is
**skipped, not defaulted**; a silent 00:00 would schedule a 3 a.m. reminder that
looks legitimate.

Horizon: the rolling 7-day window the schedule already loads. Beyond that there
is nothing loaded to remind about, and re-subscription at rollover extends it
naturally.

### 6.4 Resync triggers

The OS schedule must be recomputed on each of these. Most already have a hook:

| Trigger | Hook | Exists? |
|---|---|---|
| Task added / edited / deleted / completed | drift watch emission | After 6.2 |
| WorkPlan applied, including recurring auto-apply | same | After 6.2 |
| Day rollover past midnight | `refreshIfDateChanged()` | Yes |
| App resume / window focus | `refreshSchedule()`, `onWindowFocus` | Yes |
| Permission granted | `requestNotificationPermission()` already re-syncs | Yes |
| Device timezone change | **Nothing.** `tz.local` is resolved once in `initialise()` | **New** — re-resolve on resume |
| Reboot | plugin boot receiver | After slice 0 |

### 6.5 Data model — schema v11

Additive columns, no table rewrite, no quarantine needed.

```dart
// Tasks, TemplateTasks
BoolColumn get reminderEnabled => boolean().withDefault(const Constant(false))();
IntColumn get reminderLeadMinutes => integer().withDefault(const Constant(10))();
```

```sql
-- onUpgrade, if (from < 11), guarded by PRAGMA table_info like every step before it
ALTER TABLE tasks ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 0;
ALTER TABLE tasks ADD COLUMN reminder_lead_minutes INTEGER NOT NULL DEFAULT 10;
-- same two on template_tasks
```

Plus a `CHECK (reminder_lead_minutes BETWEEN 0 AND 1440)` on both, per
[ADR 0004](decisions/0004-invariants-in-both-app-and-schema.md) — and written as
an inline literal, because drift's generator reads the source AST and silently
emits nothing for a referenced constant (the warning already in `tables.dart`).

Default **off**. A planner that starts notifying about everything the moment it
updates is a planner people uninstall.

**Why columns and not a `reminders` table.** A separate table is the more
extensible shape and it is the wrong call here:

- A reminder has no independent lifetime. It is a property of a task — which is
  how the request itself phrases it ("notifications for *that* task").
- Columns inherit `ON DELETE CASCADE` for free; a side table needs its own
  cascade and its own orphan sweep, and this codebase has already paid for
  orphan cleanup once ([ADR 0005](decisions/0005-quarantine-not-delete-in-migrations.md),
  migration v9).
- Reading the week already loads tasks; a side table adds a join to the hottest
  query in the app.
- The extensibility a side table buys is **recovered by `ScheduledNotification`**
  (§6.1), which is where a third source would plug in anyway.

Two columns per table, defaults on both — reversible by dropping them.

### 6.6 Domain additions

- `Task` / `TemplateTask`: `reminderEnabled`, `reminderLeadMinutes`, through
  `copyWith`, `toJson`/`fromJson`, `==`, `hashCode`, and
  `validateTaskFields` (lead minutes in `0..1440`) — the shared validator both
  models already use, so they cannot drift apart.
- `_applyTemplate` carries both fields onto the materialised `Task`, satisfying
  F9.
- `AppStrings` gains the grammar-carrying strings: `reminderLeadLabel(int)`
  ("at start" / "10 minutes before"), `reminderSetFor(...)`. Per
  [ADR 0007](decisions/0007-i18n-seam-without-localisation.md), these carry a
  plural and a preposition, so they belong in `strings.dart`, not at the call
  site.

### 6.7 UI

| Surface | Change |
|---|---|
| `task_detail_panel.dart` | A reminder card: `Switch` + lead-time segmented chooser, disabled with an explanation when the task is in the past |
| `add_task_sheet.dart` | A "Remind me" row, pre-filled from the global default (F5) |
| `task_card.dart` | A small bell glyph when a reminder is armed; greyed when permission is blocked (F6) |
| `schedule_view.dart` | The permission banner, when blocked (F10) |
| `todo_list_view.dart` | Extract its existing `_buildPermissionBanner` into `lib/ui/widgets/` so both tabs show one banner, not two copies |

Accessibility: the switch needs a `Semantics` label that says what it does
("Remind me 10 minutes before Deep work block"), not just "switch". There is an
`accessibility_test.dart` to extend.

The honest-state rule the alarms list already follows applies here too: if
permission is denied, a reminder toggle must **not** render as an armed
reminder. An on-looking switch that delivers nothing is worse than no switch.

---

## 7. Slices

Each is independently shippable and leaves the app working.

| # | Slice | Verification |
|---|---|---|
| **0** | **Manifest receivers (§2)** | **On device: a todo alarm fires with the app killed, and survives a reboot. Blocks everything else** |
| 1 | `ScheduledNotification` + namespaced ids + two channels; widen `AlarmNotifier` → `ScheduledNotifier`; migrate the alarm path onto it | Unit: id namespacing, kind→channel mapping. Existing alarm tests stay green |
| 2 | Schema v11 + `CHECK`s + drift regeneration | `migration_chain_test.dart` extended v1→v11; `check_constraints_test.dart` |
| 3 | Domain fields, shared validation, `_applyTemplate` carry-over | Model, validation and equality tests |
| 4 | `watchUpcomingDays`, `remindersFor()`, the coordinator, resync triggers | Unit: horizon cap, completed/past/unparseable exclusion, lead-time arithmetic across DST |
| 5 | UI: toggle, chooser, bell, shared banner, default-lead pref | Widget tests; accessibility test extended |
| 6 | ADR 0012, CHANGELOG, FEATURES, docs index | Links resolve |
| 7 | On-device pass | The checklist in §8 |

Slices 0–1 are worth doing even if the rest is deferred: 0 fixes a shipped
feature that does not work, and 1 removes a defect that is currently latent.

---

## 8. On-device verification checklist

Nothing here can be judged from a unit test, and the repo already treats this as
required before release (ADR 0010, CONTRIBUTING).

1. Reminder fires at the right minute with the app **backgrounded**.
2. Reminder fires with the app **force-stopped**.
3. Reminder fires after a **reboot** (and after an app update — `MY_PACKAGE_REPLACED`).
4. Reminder does **not** fire for a task completed beforehand.
5. Reminder does **not** fire for a deleted task, or a day that was cleared.
6. Toggling off cancels a pending reminder; toggling on re-arms it.
7. Denying notification permission shows the banner and no armed-looking toggle.
8. Alarms and reminders **coexist**: arm one of each, confirm both fire (this is
   the §5.1 regression test).
9. Channel settings: silencing reminders in Android settings leaves alarms loud.
10. Change the device timezone forward and back; a 09:00 task still reminds at 09:00.
11. Cross a DST boundary (set the clock); same.
12. An OEM with aggressive battery management (Xiaomi, Huawei, Samsung with
    "deep sleep") — expect degradation here, and decide whether to surface an
    in-app explanation.
13. A full week of plans armed at once: count pending notifications against the
    horizon cap.

---

## 9. Open questions — need a product decision

1. **v1 scope: schedule tasks only, or todo notes and lists too?** The design
   recommends schedule tasks; notes/lists need a due-moment concept first.
2. **Default lead time?** 10 minutes assumed. "At start" is defensible for
   time-blocking, since the block *is* the appointment.
3. **Should completing a task also cancel the reminder for the *next* task?**
   No — stated only to close it off.
4. **One reminder per task, or two (e.g. 30 min and at start)?** One, in v1. Two
   means a reminder becomes a list, which pushes toward the side table §6.5
   rejected.
5. **Is a reminder on a past task an error or silently inert?** Design says
   inert and visibly disabled, matching `schedulableAlarms`.
6. **Notification actions in v2 — worth the background-isolate cost?** "Done"
   from the notification shade is the single biggest usability win available, and
   the most expensive thing on the list.

---

## 10. Related

- [ADR 0004](decisions/0004-invariants-in-both-app-and-schema.md) — invariants in the app *and* the schema
- [ADR 0005](decisions/0005-quarantine-not-delete-in-migrations.md) — migrations do not delete
- [ADR 0007](decisions/0007-i18n-seam-without-localisation.md) — where user-facing strings live
- [ADR 0009](decisions/0009-audio-unsupported-on-windows-and-linux.md) — desktop audio gap
- [ADR 0010](decisions/0010-android-first-os-level-alarms.md) — OS-level alarm scheduling, and the seam this builds on
