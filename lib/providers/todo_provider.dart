import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;
import 'package:chronosky/data/repositories/preference_repository.dart';
import 'package:chronosky/data/repositories/todo_repository.dart';

/// Sort orders for the alarm list, persisted across sessions.
enum AlarmSort {
  /// Soonest alarm first.
  upcomingAsc,

  /// Latest alarm first.
  upcomingDesc,

  /// Most recently created first.
  addedDesc,

  /// Oldest created first.
  addedAsc,
}

/// State management for standalone todo items (Notes, Timers, Lists, Alarms).
class TodoProvider extends ChangeNotifier {
  final TodoRepository _repository;
  final PreferenceRepository _prefRepo;

  static const String _alarmSortPrefKey = 'alarm_sort_order';

  List<domain.TodoItem> _notes = [];
  List<domain.TodoItem> _timers = [];
  List<domain.TodoItem> _lists = [];
  List<domain.TodoItem> _alarms = [];
  AlarmSort _alarmSort = AlarmSort.upcomingAsc;
  String? _errorMessage;

  List<domain.TodoItem> get notes => _notes;
  List<domain.TodoItem> get timers => _timers;
  List<domain.TodoItem> get lists => _lists;
  AlarmSort get alarmSort => _alarmSort;
  String? get errorMessage => _errorMessage;

  /// Alarms ordered by the persisted [alarmSort] preference.
  List<domain.TodoItem> get alarms {
    final sorted = List<domain.TodoItem>.from(_alarms);
    int byScheduled(domain.TodoItem a, domain.TodoItem b) {
      // Alarms always carry scheduledAt; fall back to createdAt defensively.
      final at = a.scheduledAt ?? a.createdAt;
      final bt = b.scheduledAt ?? b.createdAt;
      return at.compareTo(bt);
    }

    switch (_alarmSort) {
      case AlarmSort.upcomingAsc:
        sorted.sort(byScheduled);
        break;
      case AlarmSort.upcomingDesc:
        sorted.sort((a, b) => byScheduled(b, a));
        break;
      case AlarmSort.addedDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case AlarmSort.addedAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return sorted;
  }

  StreamSubscription<List<domain.TodoItem>>? _notesSub;
  StreamSubscription<List<domain.TodoItem>>? _timersSub;
  StreamSubscription<List<domain.TodoItem>>? _listsSub;
  StreamSubscription<List<domain.TodoItem>>? _alarmsSub;

  /// Maximum resubscribe attempts before the provider gives up and leaves
  /// [errorMessage] set. Bounded so a permanently failing stream cannot retry
  /// forever in the background.
  static const int maxSubscribeRetries = 5;

  /// First backoff interval; each attempt doubles it.
  ///
  /// Injectable so tests do not have to wait real seconds — the clock is a
  /// boundary, not something this provider should reach for directly.
  final Duration _retryBaseDelay;

  Timer? _retryTimer;
  int _retryAttempt = 0;
  bool _disposed = false;

  /// Resubscribe attempts made since the last successful emission.
  @visibleForTesting
  int get retryAttempts => _retryAttempt;

  TodoProvider(
    this._repository, {
    required PreferenceRepository prefRepo,
    Duration retryBaseDelay = const Duration(seconds: 1),
  })  : _prefRepo = prefRepo,
        _retryBaseDelay = retryBaseDelay {
    _subscribe();
    _loadAlarmSort();
  }

  Future<void> _loadAlarmSort() async {
    final result = await _prefRepo.get(_alarmSortPrefKey);
    result.fold(
      onSuccess: (val) {
        final match = AlarmSort.values.cast<AlarmSort?>().firstWhere(
              (s) => s!.name == val,
              orElse: () => null,
            );
        if (match != null && match != _alarmSort) {
          _alarmSort = match;
          notifyListeners();
        }
      },
      onFailure: (_) => null,
    );
  }

  Future<void> setAlarmSort(AlarmSort sort) async {
    if (sort == _alarmSort) return;
    _alarmSort = sort;
    notifyListeners();
    await _prefRepo.set(_alarmSortPrefKey, sort.name);
  }

  void _subscribe() {
    _notesSub?.cancel();
    _timersSub?.cancel();
    _listsSub?.cancel();
    _alarmsSub?.cancel();

    _notesSub = _repository.watchByType(domain.TodoItemType.note).listen(
      (items) => _apply(() => _notes = items),
      onError: (Object e) => _handleStreamError('Notes', e),
    );

    _timersSub = _repository.watchByType(domain.TodoItemType.timer).listen(
      (items) => _apply(() => _timers = items),
      onError: (Object e) => _handleStreamError('Timers', e),
    );

    _listsSub = _repository.watchByType(domain.TodoItemType.list).listen(
      (items) => _apply(() => _lists = items),
      onError: (Object e) => _handleStreamError('Lists', e),
    );

    _alarmsSub = _repository.watchByType(domain.TodoItemType.alarm).listen(
      (items) => _apply(() => _alarms = items),
      onError: (Object e) => _handleStreamError('Alarms', e),
    );
  }

  /// Applies a stream emission. A successful emission means the stream
  /// recovered, so the backoff counter resets and the next outage gets a full
  /// retry budget again.
  void _apply(void Function() assign) {
    if (_disposed) return;
    assign();
    _retryAttempt = 0;
    notifyListeners();
  }

  void _handleStreamError(String type, Object error) {
    if (_disposed) return;
    _errorMessage = 'Error loading $type: $error';
    notifyListeners();

    if (_retryAttempt >= maxSubscribeRetries) return;

    // Held in a cancellable Timer rather than Future.delayed: an uncancellable
    // retry outlives dispose(), resubscribes to all four streams (leaking
    // them, since dispose has already run) and notifies a disposed
    // ChangeNotifier. Backoff doubles each attempt instead of hammering a
    // failing stream at a fixed interval.
    final delay = _retryBaseDelay * (1 << _retryAttempt);
    _retryAttempt++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!_disposed) _subscribe();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _notesSub?.cancel();
    _timersSub?.cancel();
    _listsSub?.cancel();
    _alarmsSub?.cancel();
    super.dispose();
  }

  // ── Helper ──
  Future<void> _handleResult(Future<Result<void>> action) async {
    final result = await action;
    result.fold(
      onSuccess: (_) => _errorMessage = null,
      onFailure: (f) {
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  // ── CRUD ──

  Future<void> addTodo(domain.TodoItem todo) =>
      _handleResult(_repository.addTodo(todo));

  Future<void> addNote(String title, {String description = ''}) {
    return addTodo(
      domain.TodoItem(
        id: const Uuid().v4(),
        title: title,
        description: description,
        createdAt: DateTime.now(),
        itemType: domain.TodoItemType.note,
      ),
    );
  }

  Future<void> addTimer(String title,
      {String description = '',
      int durationMinutes = 25,
      String audioFilePath = '',}) {
    return addTodo(
      domain.TodoItem(
        id: const Uuid().v4(),
        title: title,
        description: description,
        createdAt: DateTime.now(),
        itemType: domain.TodoItemType.timer,
        durationMinutes: durationMinutes,
        audioFilePath: audioFilePath,
      ),
    );
  }

  Future<void> addAlarm(String title,
      {String description = '',
      required DateTime scheduledAt,
      String audioFilePath = '',}) {
    return addTodo(
      domain.TodoItem(
        id: const Uuid().v4(),
        title: title,
        description: description,
        createdAt: DateTime.now(),
        itemType: domain.TodoItemType.alarm,
        scheduledAt: scheduledAt,
        audioFilePath: audioFilePath,
      ),
    );
  }

  Future<void> addList(String title,
      {String description = '',
      List<domain.ChecklistItem> checklist = const [],}) {
    return addTodo(
      domain.TodoItem(
        id: const Uuid().v4(),
        title: title,
        description: description,
        createdAt: DateTime.now(),
        itemType: domain.TodoItemType.list,
        checklist: checklist,
      ),
    );
  }

  Future<void> toggleTodo(domain.TodoItem todo) {
    return updateTodo(todo.copyWith(completed: !todo.completed));
  }

  /// Persists [todo], stamping [domain.TodoItem.updatedAt] with the current time.
  Future<void> updateTodo(domain.TodoItem todo) => _handleResult(
      _repository.updateTodo(todo.copyWith(updatedAt: DateTime.now())),);

  Future<void> deleteTodo(String id) =>
      _handleResult(_repository.deleteTodo(id));
}
