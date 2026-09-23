import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:chronosky/core/services/alarm_output.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;
import 'package:chronosky/data/repositories/todo_repository.dart';

/// Schedules and fires user alarms while the app is running.
///
/// Watches alarm-type [domain.TodoItem]s from the repository, arms a single
/// wall-clock [Timer] for the next enabled alarm, and on fire:
/// - marks the alarm disabled (one-shot) so it never fires twice,
/// - loops its sound until dismissed,
/// - exposes the ringing alarm so the UI can show a dismiss overlay.
///
/// Alarms whose time passed more than [_missedGrace] ago (e.g. while the app
/// was closed) are silently disarmed instead of ringing unexpectedly.
///
/// ## Known limitation
/// Scheduling is in-process only. A closed app misses its alarms entirely, and
/// because firing is one-shot they do not fire later either. Surviving app
/// closure needs OS-level scheduling, which is a new platform dependency and
/// therefore a deliberate decision rather than an implementation detail — see
/// roadmap item 3.8.
class AlarmSchedulerService extends ChangeNotifier {
  AlarmSchedulerService(
    this._repository,
    this._logger, {
    AlarmOutput? output,
    Duration retryBaseDelay = const Duration(seconds: 1),
  })  : _output = output ?? PlatformAlarmOutput(),
        _retryBaseDelay = retryBaseDelay {
    _subscribe();
  }

  final TodoRepository _repository;
  final Logger _logger;
  final AlarmOutput _output;
  final Duration _retryBaseDelay;

  static const Duration _missedGrace = Duration(minutes: 1);

  /// Resubscribe attempts before giving up on the alarm stream.
  static const int maxSubscribeRetries = 5;

  StreamSubscription<List<domain.TodoItem>>? _sub;
  Timer? _armed;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  List<domain.TodoItem> _alarms = const [];
  domain.TodoItem? _ringing;
  SoundFailure? _soundFailure;
  final List<domain.TodoItem> _missed = [];
  bool _disposed = false;

  /// The alarm currently ringing, or null. UI shows a dismiss overlay when set.
  domain.TodoItem? get ringing => _ringing;

  /// Why the ringing alarm made no sound, or null if it played.
  ///
  /// A silent alarm is otherwise indistinguishable from a muted device. The
  /// reason matters because the remedies differ: a missing file the user can
  /// re-pick, an unsupported platform they cannot.
  SoundFailure? get soundFailure => _soundFailure;

  /// Alarms whose time passed while the app was not running.
  ///
  /// Scheduling is in-process (see docs/decisions/0006), so a closed app misses
  /// its alarms. They used to be disarmed silently, which made a missed alarm
  /// indistinguishable from one that never existed. Reported instead, so the
  /// user learns rather than quietly losing trust.
  List<domain.TodoItem> get missedAlarms => List.unmodifiable(_missed);

  /// Clears the missed-alarm notice after the user has seen it.
  void acknowledgeMissedAlarms() {
    if (_missed.isEmpty) return;
    _missed.clear();
    if (!_disposed) notifyListeners();
  }

  /// Resubscribe attempts made since the stream last delivered.
  @visibleForTesting
  int get retryAttempts => _retryAttempt;

  void _subscribe() {
    _sub?.cancel();
    _sub = _repository.watchByType(domain.TodoItemType.alarm).listen(
      (items) {
        if (_disposed) return;
        _retryAttempt = 0;
        _alarms = items;
        _rearm();
      },
      onError: _handleStreamError,
    );
  }

  /// Recovers from a dropped alarm stream.
  ///
  /// Without this the subscription died on the first error and alarm
  /// scheduling stopped for the rest of the session, with nothing in the UI to
  /// indicate it — the same defect fixed in TodoProvider, and worse here,
  /// because the user only finds out when an alarm fails to ring.
  void _handleStreamError(Object error) {
    if (_disposed) return;
    _logger.error('Alarm stream error', error);
    if (_retryAttempt >= maxSubscribeRetries) {
      _logger.error('Giving up on the alarm stream; alarms will not fire');
      return;
    }
    final delay = _retryBaseDelay * (1 << _retryAttempt);
    _retryAttempt++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!_disposed) _subscribe();
    });
  }

  /// Recomputes the armed timer against the current wall clock.
  ///
  /// Call on app resume and on window focus: a Dart [Timer] does not survive a
  /// machine sleeping through its deadline, so a resumed app would otherwise
  /// sit holding a timer that has already expired.
  void refreshSchedule() => _rearm();

  /// (Re)arms the timer for the soonest enabled future alarm. Runs after
  /// every repository change, so edits/deletes/toggles take effect at once.
  void _rearm() {
    _armed?.cancel();
    _armed = null;

    final now = DateTime.now();
    var notifiedMissed = false;
    domain.TodoItem? next;
    for (final alarm in _alarms) {
      final at = alarm.scheduledAt;
      if (!alarm.enabled || at == null) continue;
      if (at.isBefore(now.subtract(_missedGrace))) {
        // Missed while the app was closed or asleep. Disarm so it cannot
        // ambush the user later, but record it so they are told.
        if (!_missed.any((m) => m.id == alarm.id)) {
          _missed.add(alarm);
          notifiedMissed = true;
        }
        unawaited(_disarm(alarm));
        continue;
      }
      if (next == null || at.isBefore(next.scheduledAt!)) {
        next = alarm;
      }
    }
    if (notifiedMissed && !_disposed) notifyListeners();
    if (next == null) return;

    final delay = next.scheduledAt!.difference(now);
    if (delay <= Duration.zero) {
      unawaited(_fire(next));
    } else {
      final target = next;
      _armed = Timer(delay, () => unawaited(_fire(target)));
    }
  }

  Future<void> _disarm(domain.TodoItem alarm) async {
    final result = await _repository.updateTodo(
      alarm.copyWith(enabled: false, updatedAt: DateTime.now()),
    );
    result.fold(
      onSuccess: (_) => null,
      onFailure: (f) => _logger.error('Failed to disarm alarm: ${f.message}'),
    );
  }

  Future<void> _fire(domain.TodoItem alarm) async {
    if (_disposed) return;
    _logger.info('Alarm firing: ${alarm.title}');
    _ringing = alarm;
    _soundFailure = null;
    notifyListeners();

    // One-shot: disable before anything else so a crash mid-ring cannot
    // cause a re-fire on the next launch.
    await _disarm(alarm);
    // Disposal can happen across any await below, and notifying a disposed
    // ChangeNotifier throws.
    if (_disposed) return;

    if (alarm.audioFilePath.isNotEmpty) {
      try {
        await _output.playLooping(alarm.audioFilePath);
      } on SoundException catch (e) {
        _logger.warning('Alarm sound failed (${e.reason.name}): ${e.cause}');
        if (_disposed) return;
        _soundFailure = e.reason;
        notifyListeners();
      } catch (e) {
        _logger.warning('Alarm sound failed: $e');
        if (_disposed) return;
        _soundFailure = SoundFailure.playbackFailed;
        notifyListeners();
      }
    }
    if (_disposed) return;

    try {
      await _output.bringToFront();
    } catch (e) {
      _logger.warning('Failed to focus window for alarm: $e');
    }
  }

  /// Stops the ringing sound and clears the overlay.
  Future<void> dismiss() async {
    try {
      await _output.stop();
    } catch (e) {
      // Never block dismissal on the audio layer: the overlay must always
      // clear, or the user is stuck behind it. Recorded rather than swallowed.
      _logger.warning('Failed to stop alarm audio: $e');
    }
    if (_disposed) return;
    _ringing = null;
    _soundFailure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _sub?.cancel();
    _armed?.cancel();
    unawaited(_output.dispose());
    super.dispose();
  }
}
