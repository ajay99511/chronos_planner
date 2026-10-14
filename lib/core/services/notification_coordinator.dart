import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/core/services/scheduled_notification.dart';
import 'package:chronosky/core/services/scheduled_notifier.dart';
import 'package:chronosky/core/services/task_reminders.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;
import 'package:chronosky/data/repositories/preference_repository.dart';
import 'package:chronosky/data/repositories/schedule_repository.dart';
import 'package:chronosky/data/repositories/todo_repository.dart';
import 'package:chronosky/domain/reminder_tone.dart';

/// The single owner of the operating system's notification schedule.
///
/// ## Why this exists at all
/// [ScheduledNotifier.sync] replaces the *whole* OS schedule, which is what
/// keeps it from drifting out of step with what the user sees (ADR 0010). That
/// guarantee only holds while one object calls it. Two services each syncing
/// their own slice would alternately erase each other, and the loser would
/// silently stop delivering — with nothing in the UI to show it.
///
/// So both sources converge here:
/// - todo alarms, from [TodoRepository.watchByType],
/// - task reminders, from [ScheduleRepository.watchUpcomingDays],
///
/// and leave as one list of [ScheduledNotification].
///
/// ## What it is not
/// It does not ring anything. `AlarmSchedulerService` still owns the in-app
/// experience — the wall-clock timer, the looping sound and the dismiss
/// overlay — because that is a different job with a different lifetime. The
/// two are deliberately not mutually exclusive; see ADR 0010.
class NotificationCoordinator extends ChangeNotifier {
  NotificationCoordinator({
    required TodoRepository todoRepo,
    required ScheduleRepository scheduleRepo,
    required Logger logger,
    PreferenceRepository? prefRepo,
    ScheduledNotifier? notifier,
    int horizonDays = 7,
    Duration retryBaseDelay = const Duration(seconds: 1),
  })  : _todoRepo = todoRepo,
        _scheduleRepo = scheduleRepo,
        _logger = logger,
        _prefRepo = prefRepo,
        _notifier = notifier ?? const NoOpScheduledNotifier(),
        _horizonDays = horizonDays,
        _retryBaseDelay = retryBaseDelay {
    _subscribe();
    unawaited(_loadReminderTone());
  }

  final TodoRepository _todoRepo;
  final ScheduleRepository _scheduleRepo;
  final Logger _logger;

  /// Optional so a test can build a coordinator without a preference store;
  /// the tone then stays at [ReminderTone.fallback].
  final PreferenceRepository? _prefRepo;
  final ScheduledNotifier _notifier;

  /// How far ahead reminders are scheduled, in days.
  ///
  /// Matches the rolling window the schedule screen loads: there is nothing
  /// beyond it to remind about, and [refresh] re-subscribes at a day rollover
  /// so the horizon moves with the calendar.
  final int _horizonDays;

  final Duration _retryBaseDelay;

  /// Resubscribe attempts before giving up on a source stream.
  static const int maxSubscribeRetries = 5;

  StreamSubscription<List<domain.TodoItem>>? _alarmSub;
  StreamSubscription<List<DayPlan>>? _scheduleSub;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  List<domain.TodoItem> _alarms = const [];
  List<DayPlan> _days = const [];
  bool _notificationsBlocked = false;
  ReminderTone _reminderTone = ReminderTone.fallback;

  /// Whether the tone has been settled, by the initial load or by the user.
  ///
  /// The initial read is async and fired from the constructor, so a user who
  /// opens settings and picks a tone before it lands would otherwise have
  /// their choice overwritten by the stored value a moment later — and
  /// re-synced with the wrong sound. Whoever gets there first wins, and the
  /// user getting there first is the case that matters.
  bool _toneResolved = false;
  bool _disposed = false;

  /// Preference key for the chosen reminder tone.
  static const String reminderTonePrefKey = 'reminder_tone';

  /// The sound reminders currently make.
  ///
  /// Lives here rather than in a settings provider because it decides which
  /// Android channel reminders are scheduled on, so [_sync] needs it and the
  /// channel has to exist before the first notification goes out against it.
  ReminderTone get reminderTone => _reminderTone;

  /// Whether the OS will refuse to deliver.
  ///
  /// True when notification permission has been declined, which makes every
  /// scheduled item silently useless — so the UI says so rather than letting
  /// the user believe a reminder is set.
  bool get notificationsBlocked => _notificationsBlocked;

  /// Resubscribe attempts made since a source last delivered.
  @visibleForTesting
  int get retryAttempts => _retryAttempt;

  /// The schedule as it currently stands, for assertions in tests.
  @visibleForTesting
  List<ScheduledNotification> get pending => _project(DateTime.now());

  Future<void> _loadReminderTone() async {
    final repo = _prefRepo;
    if (repo == null) {
      _toneResolved = true;
      return;
    }
    final result = await repo.get(reminderTonePrefKey);
    if (_disposed) return;
    // The user chose while this was in flight; their choice stands.
    if (_toneResolved) return;
    _toneResolved = true;
    final stored = result.fold(
      onSuccess: (value) => value,
      onFailure: (failure) {
        _logger.warning('Could not read the reminder tone: ${failure.message}');
        return null;
      },
    );
    final tone = ReminderTone.fromName(stored);
    if (tone == _reminderTone) return;
    _reminderTone = tone;
    notifyListeners();
    await _sync();
  }

  /// Changes the reminder sound, persists it, and re-syncs.
  ///
  /// The re-sync is not optional: the tone determines the channel, and
  /// notifications already scheduled against the old channel keep the old
  /// sound until they are replaced.
  Future<void> setReminderTone(ReminderTone tone) async {
    // Set before the early return: choosing the tone that happens to already
    // be showing is still the user settling the question, and must stop a
    // pending load from replacing it.
    final wasResolved = _toneResolved;
    _toneResolved = true;
    if (tone == _reminderTone) {
      // Nothing to persist unless this is the first time it has been pinned.
      if (wasResolved) return;
    }
    _reminderTone = tone;
    notifyListeners();
    await _sync();
    final result = await _prefRepo?.set(reminderTonePrefKey, tone.name);
    result?.fold(
      onSuccess: (_) => null,
      onFailure: (failure) => _logger.error(
        'Could not persist the reminder tone: ${failure.message}',
      ),
    );
  }

  void _subscribe() {
    _alarmSub?.cancel();
    _scheduleSub?.cancel();

    _alarmSub = _todoRepo.watchByType(domain.TodoItemType.alarm).listen(
      (items) {
        if (_disposed) return;
        _retryAttempt = 0;
        _alarms = items;
        unawaited(_sync());
      },
      onError: (Object e) => _handleStreamError('alarm', e),
    );

    _scheduleSub = _scheduleRepo.watchUpcomingDays(_horizonDays).listen(
      (days) {
        if (_disposed) return;
        _retryAttempt = 0;
        _days = days;
        unawaited(_sync());
      },
      onError: (Object e) => _handleStreamError('schedule', e),
    );
  }

  /// Recovers from a dropped source stream.
  ///
  /// Without this a single error ended notification scheduling for the rest of
  /// the session, with nothing in the UI to indicate it — the user only finds
  /// out when something fails to go off. Backoff doubles rather than hammering
  /// a failing stream, and the budget is bounded so a permanently broken
  /// source cannot retry forever in the background.
  void _handleStreamError(String source, Object error) {
    if (_disposed) return;
    _logger.error('Notification $source stream error', error);
    if (_retryAttempt >= maxSubscribeRetries) {
      _logger.error(
        'Giving up on the $source stream; notifications will not be scheduled',
      );
      return;
    }
    final delay = _retryBaseDelay * (1 << _retryAttempt);
    _retryAttempt++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!_disposed) _subscribe();
    });
  }

  /// Everything the OS should be holding, as of [now].
  ///
  /// Both projections are pure and independently tested; the cap is applied
  /// once over the combined list rather than per source, because the platform
  /// limit is per app. Alarms are not allowed to be crowded out by a week of
  /// reminders: they are projected first and the sort inside
  /// [schedulableNotifications] is by time, so a soon alarm always outranks a
  /// distant reminder.
  List<ScheduledNotification> _project(DateTime now) =>
      schedulableNotifications(
        [
          ...alarmNotifications(_alarms, now),
          ...reminderNotifications(_days, now),
        ],
        now,
      );

  /// Hands the whole schedule to the OS.
  ///
  /// Failures are logged, never rethrown: losing the OS schedule degrades the
  /// feature to in-session only, which is bad but not a reason to break the
  /// running app.
  Future<void> _sync() async {
    try {
      final items = _project(DateTime.now());
      await _notifier.sync(items, reminderTone: _reminderTone);
      if (_disposed) return;
      final permitted = await _notifier.hasPermission();
      if (_disposed) return;
      if (_notificationsBlocked != !permitted) {
        _notificationsBlocked = !permitted;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      _logger.error('Could not sync the OS notification schedule', e,
          stackTrace,);
    }
  }

  /// Recomputes the schedule against the current clock, and re-reads the
  /// schedule window.
  ///
  /// Call on app resume and on window focus. Two things go stale while the app
  /// sits in the background: a reminder whose moment has passed is no longer
  /// schedulable, and the rolling window is anchored to the day it was
  /// subscribed on — so after midnight the horizon has to move. Re-subscribing
  /// is the only way to move it, because a drift watch binds its date
  /// parameter at subscription time.
  void refresh() {
    if (_disposed) return;
    _subscribe();
    unawaited(_sync());
  }

  /// Prompts for notification permission only if the OS would currently drop
  /// everything.
  ///
  /// Re-checks with the OS rather than trusting [notificationsBlocked], which
  /// is only as fresh as the last sync — and the case that matters most is a
  /// cold start where the user arms their first reminder before that sync has
  /// settled. A platform with no such permission is treated as permitted, so
  /// callers never nag a user who has nothing to grant.
  Future<bool> ensureNotificationPermission() async {
    try {
      if (await _notifier.hasPermission()) {
        if (_disposed) return true;
        if (_notificationsBlocked) {
          _notificationsBlocked = false;
          notifyListeners();
        }
        return true;
      }
    } catch (e, stackTrace) {
      _logger.error('Could not read notification permission', e, stackTrace);
      return true;
    }
    return requestNotificationPermission();
  }

  /// Asks the user for permission to deliver, then re-syncs.
  ///
  /// Returns whether permission is now held, so a caller that prompted in
  /// context can say what the refusal cost. On Android 13+ a second request
  /// after a denial returns false without showing anything, so a caller must
  /// not treat false as "the user has not decided yet" and ask again.
  Future<bool> requestNotificationPermission() async {
    final granted = await _notifier.requestPermission();
    if (_disposed) return granted;
    _notificationsBlocked = !granted;
    notifyListeners();
    if (granted) await _sync();
    return granted;
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _alarmSub?.cancel();
    _scheduleSub?.cancel();
    super.dispose();
  }
}
