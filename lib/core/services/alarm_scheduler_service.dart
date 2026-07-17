import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:window_manager/window_manager.dart';

import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;
import 'package:chronosky/data/repositories/todo_repository.dart';

/// Schedules and fires user alarms while the app is running.
///
/// Watches alarm-type [domain.TodoItem]s from the repository, arms a single
/// wall-clock [Timer] for the next enabled alarm, and on fire:
/// - marks the alarm disabled (one-shot) so it never fires twice,
/// - loops its sound via `just_audio` until dismissed,
/// - exposes the ringing alarm so the UI can show a dismiss overlay.
///
/// Alarms whose time passed more than [_missedGrace] ago (e.g. while the app
/// was closed) are silently disarmed instead of ringing unexpectedly.
class AlarmSchedulerService extends ChangeNotifier {
  final TodoRepository _repository;
  final Logger _logger;
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const Duration _missedGrace = Duration(minutes: 1);

  StreamSubscription<List<domain.TodoItem>>? _sub;
  Timer? _armed;
  List<domain.TodoItem> _alarms = const [];
  domain.TodoItem? _ringing;
  bool _disposed = false;

  /// The alarm currently ringing, or null. UI shows a dismiss overlay when set.
  domain.TodoItem? get ringing => _ringing;

  AlarmSchedulerService(this._repository, this._logger) {
    _sub = _repository.watchByType(domain.TodoItemType.alarm).listen(
      (items) {
        _alarms = items;
        _rearm();
      },
      onError: (e) => _logger.error('Alarm stream error: $e'),
    );
  }

  /// (Re)arms the timer for the soonest enabled future alarm. Runs after
  /// every repository change, so edits/deletes/toggles take effect at once.
  void _rearm() {
    _armed?.cancel();
    _armed = null;

    final now = DateTime.now();
    domain.TodoItem? next;
    for (final alarm in _alarms) {
      final at = alarm.scheduledAt;
      if (!alarm.enabled || at == null) continue;
      if (at.isBefore(now.subtract(_missedGrace))) {
        unawaited(_disarm(alarm));
        continue;
      }
      if (next == null || at.isBefore(next.scheduledAt!)) {
        next = alarm;
      }
    }
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
    notifyListeners();

    // One-shot: disable before anything else so a crash mid-ring cannot
    // cause a re-fire on the next launch.
    await _disarm(alarm);

    if (alarm.audioFilePath.isNotEmpty) {
      try {
        await _audioPlayer.setFilePath(alarm.audioFilePath);
        await _audioPlayer.setLoopMode(LoopMode.one);
        await _audioPlayer.play();
      } catch (e) {
        _logger.warning('Failed to play alarm audio: $e');
      }
    }

    // Bring the window to the user's attention on desktop.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        await windowManager.show();
        await windowManager.focus();
      } catch (e) {
        _logger.warning('Failed to focus window for alarm: $e');
      }
    }
  }

  /// Stops the ringing sound and clears the overlay.
  Future<void> dismiss() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _ringing = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _armed?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
