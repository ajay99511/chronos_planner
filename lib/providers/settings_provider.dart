import 'package:flutter/foundation.dart';

import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/repositories/preference_repository.dart';
import 'package:chronosky/data/repositories/todo_repository.dart';
import 'package:chronosky/data/seeds/demo_todo_items.dart';
import 'package:chronosky/domain/reminder_lead.dart';

/// App-wide preferences that are not about the OS notification schedule.
///
/// The reminder *tone* deliberately lives in `NotificationCoordinator`
/// instead, because it decides which Android channel reminders go out on and
/// so has to be known at sync time. What is here is settings that only the UI
/// and the seeds care about.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required PreferenceRepository prefRepo,
    required TodoRepository todoRepo,
    required Logger logger,
  })  : _prefRepo = prefRepo,
        _todoRepo = todoRepo,
        _logger = logger {
    _load();
  }

  final PreferenceRepository _prefRepo;
  final TodoRepository _todoRepo;
  final Logger _logger;

  /// Whether sample content is shown alongside the user's own.
  static const String demoVisiblePrefKey = 'demo_data_visible';

  /// Marks that the Workspace samples have been written once.
  static const String demoSeededPrefKey = 'demo_items_seeded';

  /// The lead time new reminders start from.
  static const String defaultLeadPrefKey = 'reminder_default_lead_minutes';

  bool _demoVisible = true;
  int _defaultLeadMinutes = defaultReminderLeadMinutes;
  bool _loaded = false;

  /// Whether demo content should be listed.
  ///
  /// Defaults to **true**: the samples exist to show what the four kinds of
  /// workspace item and the plan library are for, which they cannot do while
  /// hidden. Switching it off filters them out everywhere without deleting
  /// anything, so switching it back on restores them — edits included.
  bool get demoVisible => _demoVisible;

  /// Lead time a newly armed reminder starts at, in minutes before the task.
  int get defaultLeadMinutes => _defaultLeadMinutes;

  /// Whether the stored values have been read yet.
  ///
  /// The UI uses this to avoid rendering the switch in a position it is about
  /// to change out from under the user's finger.
  bool get loaded => _loaded;

  Future<void> _load() async {
    final visible = await _readBool(demoVisiblePrefKey, fallback: true);
    final lead = await _readInt(
      defaultLeadPrefKey,
      fallback: defaultReminderLeadMinutes,
    );
    _demoVisible = visible;
    _defaultLeadMinutes = lead;
    _loaded = true;
    notifyListeners();
  }

  Future<bool> _readBool(String key, {required bool fallback}) async {
    final result = await _prefRepo.get(key);
    return result.fold(
      onSuccess: (value) => value == null ? fallback : value == 'true',
      onFailure: (failure) {
        _logger.warning('Could not read $key: ${failure.message}');
        return fallback;
      },
    );
  }

  Future<int> _readInt(String key, {required int fallback}) async {
    final result = await _prefRepo.get(key);
    return result.fold(
      onSuccess: (value) {
        final parsed = value == null ? null : int.tryParse(value);
        // A stored value outside the allowed range is treated as absent: it
        // can only come from a build with different limits, and honouring it
        // would write a lead time the schema rejects.
        if (parsed == null || !isValidReminderLead(parsed)) return fallback;
        return parsed;
      },
      onFailure: (failure) {
        _logger.warning('Could not read $key: ${failure.message}');
        return fallback;
      },
    );
  }

  Future<void> _write(String key, String value) async {
    final result = await _prefRepo.set(key, value);
    result.fold(
      onSuccess: (_) => null,
      onFailure: (failure) =>
          _logger.error('Could not persist $key: ${failure.message}'),
    );
  }

  /// Shows or hides sample content everywhere at once.
  Future<void> setDemoVisible(bool visible) async {
    if (visible == _demoVisible) return;
    _demoVisible = visible;
    // Optimistic: the switch is the feedback, so it moves now and the write
    // follows. A failed write is logged and the setting reverts on next
    // launch, which is better than a switch that lags behind the finger.
    notifyListeners();
    await _write(demoVisiblePrefKey, visible.toString());
  }

  /// Sets the lead time new reminders start from.
  Future<void> setDefaultLeadMinutes(int minutes) async {
    if (!isValidReminderLead(minutes) || minutes == _defaultLeadMinutes) return;
    _defaultLeadMinutes = minutes;
    notifyListeners();
    await _write(defaultLeadPrefKey, minutes.toString());
  }

  /// Writes the Workspace samples, once per install.
  ///
  /// Gated on its own preference rather than on "the workspace is empty",
  /// because a user who deletes every sample has made a decision and must not
  /// have them reappear on the next launch — the mistake the starter plans
  /// originally made.
  ///
  /// The flag is set even if some writes failed: a partial seed is still a
  /// seed, and retrying would duplicate whatever did land.
  Future<void> seedDemoItemsIfNeeded() async {
    final alreadySeeded = await _readBool(demoSeededPrefKey, fallback: false);
    if (alreadySeeded) return;

    for (final item in demoTodoItems()) {
      final result = await _todoRepo.addTodo(item);
      result.fold(
        onSuccess: (_) => null,
        onFailure: (failure) => _logger.error(
          'Could not seed demo item "${item.title}": ${failure.message}',
        ),
      );
    }
    await _write(demoSeededPrefKey, 'true');
  }
}
