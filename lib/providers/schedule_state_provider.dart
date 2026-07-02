import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/data/repositories/schedule_repository.dart';
import 'package:chronosky/data/repositories/template_repository.dart';
import 'package:chronosky/data/repositories/preference_repository.dart';

enum UndoType { deleteTask, clearDay }

enum SortOrder { asc, desc }

class UndoAction {
  final UndoType type;
  final int dayIndex;
  final Task? task;
  final List<Task>? tasks;

  UndoAction(
      {required this.type, required this.dayIndex, this.task, this.tasks,});
}

class ScheduleStateProvider extends ChangeNotifier {
  final ScheduleRepository _scheduleRepo;
  final TemplateRepository _templateRepo;
  final PreferenceRepository _prefRepo;
  final Logger _logger;

  List<DayPlan> _weekPlan = [];
  List<PlanTemplate> _templates = [];
  int _selectedDayIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  final List<UndoAction> _undoStack = [];
  SortOrder _sortOrder = SortOrder.asc;

  /// Persisted keys (`templateId|y-m-d`) marking recurring-template instances
  /// the user has deleted, so they are not auto-recreated on the next load.
  static const String _dismissalPrefKey = 'recurring_dismissals';
  Set<String> _dismissedRecurring = {};

  Completer<void>? _loadingCompleter;

  List<DayPlan> get weekPlan => _weekPlan;
  List<PlanTemplate> get templates => _templates;
  int get selectedDayIndex => _selectedDayIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canUndo => _undoStack.isNotEmpty;
  SortOrder get sortOrder => _sortOrder;

  DayPlan get selectedDay => _weekPlan.isNotEmpty
      ? _weekPlan[_selectedDayIndex]
      : DayPlan(id: 'dummy', date: DateTime.now(), tasks: []);

  ScheduleStateProvider({
    required ScheduleRepository scheduleRepo,
    required TemplateRepository templateRepo,
    required PreferenceRepository prefRepo,
    required Logger logger,
  })  : _scheduleRepo = scheduleRepo,
        _templateRepo = templateRepo,
        _prefRepo = prefRepo,
        _logger = logger {
    loadData();
  }

  Future<void> loadData() async {
    if (_isLoading) return _loadingCompleter?.future;

    _isLoading = true;
    _errorMessage = null; // Clear previous error so retry can succeed
    _loadingCompleter = Completer<void>();
    notifyListeners();

    try {
      _logger.info('Loading schedule data...');

      final weekResult = await _scheduleRepo.getUpcomingDays(7);

      weekResult.fold(
        onSuccess: (data) => _weekPlan = data,
        onFailure: (f) {
          _errorMessage = '${f.message}\n${f.originalError ?? ""}';
          _logger.error(
              'Failed to load week plan: ${f.message}', f.originalError,);
        },
      );

      // If week data failed, bail out early — schedule is unusable
      if (_errorMessage != null) return;

      final templateResult = await _templateRepo.getAllTemplates();
      final prefResult = await _prefRepo.get('sort_order');
      final dismissResult = await _prefRepo.get(_dismissalPrefKey);

      templateResult.fold(
        onSuccess: (data) {
          _templates = List<PlanTemplate>.from(data);
          if (_templates.isEmpty) {
            unawaited(_seedDefaultTemplates());
          }
        },
        onFailure: (f) =>
            _logger.error('Failed to load templates: ${f.message}'),
      );

      prefResult.fold(
        onSuccess: (val) =>
            _sortOrder = val == 'desc' ? SortOrder.desc : SortOrder.asc,
        onFailure: (f) => _logger.warning('Failed to load sort order'),
      );

      dismissResult.fold(
        onSuccess: (val) => _dismissedRecurring = _decodeDismissals(val),
        onFailure: (f) =>
            _logger.warning('Failed to load recurring dismissals'),
      );
      _pruneDismissals();

      _selectedDayIndex = 0;

      // Apply recurring templates — non-fatal if it fails
      try {
        await _applyRecurringTemplates();
      } catch (e) {
        _logger.warning('Failed to apply recurring templates: $e');
      }

      _logger.info('Schedule data loaded successfully');
    } catch (e, stackTrace) {
      _logger.error('Unexpected error loading data: $e\n$stackTrace');
      _errorMessage = 'Unexpected error: ${e.runtimeType}';
    } finally {
      _isLoading = false;
      _loadingCompleter?.complete();
      _loadingCompleter = null;
      notifyListeners();
    }
  }

  Future<void> _seedDefaultTemplates() async {
    // Basic seeds for MVP
    final seeds = [
      PlanTemplate(
        id: const Uuid().v4(),
        name: 'Deep Work Friday',
        description: 'Focused coding schedule',
        tasks: [
          TemplateTask(
            id: const Uuid().v4(),
            templateId: '', // Set below
            title: 'Deep Work Block',
            startTime: '09:00',
            endTime: '12:00',
            type: TaskType.work,
          ),
        ],
      ),
    ];

    for (final t in seeds) {
      await addTemplate(t);
    }
  }

  void selectDay(int index) {
    if (index >= 0 && index < _weekPlan.length) {
      _selectedDayIndex = index;
      notifyListeners();
    }
  }

  Future<void> toggleSortOrder() async {
    _sortOrder = _sortOrder == SortOrder.asc ? SortOrder.desc : SortOrder.asc;
    notifyListeners();
    await _prefRepo.set('sort_order', _sortOrder.name);
  }

  // ─── Recurring dismissal tracking ────────────

  String _dismissalKey(String templateId, DateTime date) =>
      '$templateId|${date.year}-${date.month}-${date.day}';

  Set<String> _decodeDismissals(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  DateTime? _parseDismissalDate(String key) {
    final sep = key.lastIndexOf('|');
    if (sep == -1) return null;
    final parts = key.substring(sep + 1).split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Drops dismissal markers for past dates so the preference never grows
  /// unbounded (the schedule only ever spans today..+6 days).
  void _pruneDismissals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dismissedRecurring.removeWhere((key) {
      final date = _parseDismissalDate(key);
      return date == null || date.isBefore(today);
    });
  }

  Future<void> _persistDismissals() async {
    await _prefRepo.set(
      _dismissalPrefKey,
      jsonEncode(_dismissedRecurring.toList()),
    );
  }

  /// Parses an "HH:mm" string into minutes-since-midnight (0 on failure).
  static int _toMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  /// Returns existing tasks on [date] whose time range overlaps [task].
  ///
  /// Overnight ranges (end <= start) are normalized by adding 24h. Tasks
  /// sharing [task]'s id (or [excludeId]) are ignored so editing a task does
  /// not flag it against itself. Used to warn the user about double-booking.
  List<Task> overlappingTasks(Task task, DateTime date, {String? excludeId}) {
    final idx = _weekPlan.indexWhere(
      (p) =>
          p.date.year == date.year &&
          p.date.month == date.month &&
          p.date.day == date.day,
    );
    if (idx == -1) return const [];

    final skipId = excludeId ?? task.id;
    var aStart = _toMinutes(task.startTime);
    var aEnd = _toMinutes(task.endTime);
    if (aEnd <= aStart) aEnd += 24 * 60;

    return _weekPlan[idx].tasks.where((t) {
      if (t.id == skipId) return false;
      var bStart = _toMinutes(t.startTime);
      var bEnd = _toMinutes(t.endTime);
      if (bEnd <= bStart) bEnd += 24 * 60;
      return aStart < bEnd && bStart < aEnd;
    }).toList();
  }

  List<Task> getSortedTasks(DayPlan dayPlan) {
    final tasks = List<Task>.from(dayPlan.tasks);
    tasks.sort(
      (a, b) => _sortOrder == SortOrder.asc
          ? a.startTime.compareTo(b.startTime)
          : b.startTime.compareTo(a.startTime),
    );
    return tasks;
  }

  // ─── CRUD Operations with Rollback ───────────

  Future<void> addTask(Task task, [DateTime? date]) async {
    final targetDate = date ?? selectedDay.date;
    final planIdx = _weekPlan.indexWhere(
      (p) =>
          p.date.year == targetDate.year &&
          p.date.month == targetDate.month &&
          p.date.day == targetDate.day,
    );

    List<DayPlan>? originalPlan;
    if (planIdx != -1) {
      originalPlan = List<DayPlan>.from(_weekPlan);
      final newTasks = List<Task>.from(_weekPlan[planIdx].tasks)..add(task);
      _weekPlan[planIdx] = _weekPlan[planIdx].copyWith(tasks: newTasks);
      notifyListeners();
    }

    final result = await _scheduleRepo.addTaskToDate(targetDate, task);
    result.fold(
      onSuccess: (_) => _logger.debug('Task added: ${task.id}'),
      onFailure: (f) {
        if (originalPlan != null) _weekPlan = originalPlan;
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  Future<void> updateTask(String taskId, Task updatedTask) async {
    int planIdx = -1;
    for (int i = 0; i < _weekPlan.length; i++) {
      if (_weekPlan[i].tasks.any((t) => t.id == taskId)) {
        planIdx = i;
        break;
      }
    }

    if (planIdx == -1) return;

    final originalPlan = List<DayPlan>.from(_weekPlan);
    final taskIdx = _weekPlan[planIdx].tasks.indexWhere((t) => t.id == taskId);

    final newTasks = List<Task>.from(_weekPlan[planIdx].tasks)
      ..[taskIdx] = updatedTask;
    _weekPlan[planIdx] = _weekPlan[planIdx].copyWith(tasks: newTasks);
    notifyListeners();

    final result = await _scheduleRepo.updateTask(
        _weekPlan[planIdx].id, taskId, updatedTask,);
    result.fold(
      onSuccess: (_) => null,
      onFailure: (f) {
        _weekPlan = originalPlan;
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  Future<void> deleteTask(String taskId) async {
    final planIdx = _selectedDayIndex;
    final originalPlan = List<DayPlan>.from(_weekPlan);

    final taskIdx = _weekPlan[planIdx].tasks.indexWhere((t) => t.id == taskId);
    if (taskIdx == -1) return;

    final removedTask = _weekPlan[planIdx].tasks[taskIdx];
    final newTasks = List<Task>.from(_weekPlan[planIdx].tasks)
      ..removeAt(taskIdx);
    _weekPlan[planIdx] = _weekPlan[planIdx].copyWith(tasks: newTasks);

    // Remember that a template-sourced instance was removed so recurring
    // templates don't silently re-create it on the next load.
    if (removedTask.sourceTemplateId.isNotEmpty) {
      _dismissedRecurring.add(
          _dismissalKey(removedTask.sourceTemplateId, _weekPlan[planIdx].date),);
      unawaited(_persistDismissals());
    }

    _addToUndoStack(
      UndoAction(
        type: UndoType.deleteTask,
        dayIndex: planIdx,
        task: removedTask,
      ),
    );

    notifyListeners();

    final result =
        await _scheduleRepo.deleteTask(_weekPlan[planIdx].id, taskId);
    result.fold(
      onSuccess: (_) => null,
      onFailure: (f) {
        _weekPlan = originalPlan;
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  void _addToUndoStack(UndoAction action) {
    if (_undoStack.length >= 50) {
      _undoStack.removeAt(0); // FIFO eviction
    }
    _undoStack.add(action);
  }

  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();

    switch (action.type) {
      case UndoType.deleteTask:
        if (action.task != null) {
          // Restoring a template-sourced task clears its dismissal marker.
          if (action.task!.sourceTemplateId.isNotEmpty) {
            _dismissedRecurring.remove(
              _dismissalKey(
                action.task!.sourceTemplateId,
                _weekPlan[action.dayIndex].date,
              ),
            );
            unawaited(_persistDismissals());
          }
          await addTask(action.task!, _weekPlan[action.dayIndex].date);
        }
        break;
      case UndoType.clearDay:
        if (action.tasks != null) {
          for (final t in action.tasks!) {
            await addTask(t, _weekPlan[action.dayIndex].date);
          }
        }
        break;
    }
  }

  // ─── Template Operations ──────────────────────

  Future<void> addTemplate(PlanTemplate template) async {
    _templates.add(template);
    notifyListeners();
    final result = await _templateRepo.addTemplate(template);
    if (result is Failure) {
      _templates.remove(template);
      _errorMessage = (result).failure.message;
      notifyListeners();
    }
  }

  Future<void> removeTemplate(String id) async {
    final original = List<PlanTemplate>.from(_templates);
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();

    final result = await _templateRepo.deleteTemplate(id);
    result.fold(
      onSuccess: (_) => _logger.debug('Template removed: $id'),
      onFailure: (f) {
        _templates = original;
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  Future<void> updateTemplate(String templateId,
      {String? name, String? description,}) async {
    final idx = _templates.indexWhere((t) => t.id == templateId);
    if (idx == -1) return;

    final original = List<PlanTemplate>.from(_templates);
    _templates[idx] =
        _templates[idx].copyWith(name: name, description: description);
    notifyListeners();

    final result = await _templateRepo.updateTemplate(templateId,
        name: name, description: description,);
    result.fold(
      onSuccess: (_) => null,
      onFailure: (f) {
        _templates = original;
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  Future<void> addTaskToTemplate(String templateId, Task task) async {
    final idx = _templates.indexWhere((t) => t.id == templateId);
    if (idx == -1) return;

    final original = List<PlanTemplate>.from(_templates);
    final templateTask = TemplateTask(
      id: task.id,
      templateId: templateId,
      title: task.title,
      startTime: task.startTime,
      endTime: task.endTime,
      type: task.type,
      priority: task.priority,
      energyLevel: task.energyLevel,
      estimatedCost: task.estimatedCost,
      description: task.description,
    );

    final newTasks = List<TemplateTask>.from(_templates[idx].tasks)
      ..add(templateTask);
    _templates[idx] = _templates[idx].copyWith(tasks: newTasks);
    notifyListeners();

    final result =
        await _templateRepo.addTaskToTemplate(templateId, templateTask);
    result.fold(
      onSuccess: (_) => null,
      onFailure: (f) {
        _templates = original;
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  Future<void> removeTaskFromTemplate(String templateId, String taskId) async {
    final idx = _templates.indexWhere((t) => t.id == templateId);
    if (idx == -1) return;

    final original = List<PlanTemplate>.from(_templates);
    final newTasks = List<TemplateTask>.from(_templates[idx].tasks)
      ..removeWhere((t) => t.id == taskId);
    _templates[idx] = _templates[idx].copyWith(tasks: newTasks);
    notifyListeners();

    final result =
        await _templateRepo.removeTaskFromTemplate(templateId, taskId);
    result.fold(
      onSuccess: (_) => null,
      onFailure: (f) {
        _templates = original;
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  Future<void> updateTaskInTemplate(
      String templateId, String taskId, Task task,) async {
    final idx = _templates.indexWhere((t) => t.id == templateId);
    if (idx == -1) return;

    final original = List<PlanTemplate>.from(_templates);
    final taskIdx = _templates[idx].tasks.indexWhere((t) => t.id == taskId);
    if (taskIdx == -1) return;

    final templateTask = TemplateTask(
      id: taskId,
      templateId: templateId,
      title: task.title,
      startTime: task.startTime,
      endTime: task.endTime,
      type: task.type,
      priority: task.priority,
      energyLevel: task.energyLevel,
      estimatedCost: task.estimatedCost,
      description: task.description,
    );

    final newTasks = List<TemplateTask>.from(_templates[idx].tasks)
      ..[taskIdx] = templateTask;
    _templates[idx] = _templates[idx].copyWith(tasks: newTasks);
    notifyListeners();

    final result = await _templateRepo.updateTaskInTemplate(
        templateId, taskId, templateTask,);
    result.fold(
      onSuccess: (_) => null,
      onFailure: (f) {
        _templates = original;
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  Future<void> setTemplateRecurring(String templateId, List<int> days) async {
    final idx = _templates.indexWhere((t) => t.id == templateId);
    if (idx == -1) return;

    final original = List<PlanTemplate>.from(_templates);
    _templates[idx] = _templates[idx].copyWith(activeDays: days);
    notifyListeners();

    // Explicitly (re)enabling recurrence overrides any prior per-day dismissals.
    _dismissedRecurring.removeWhere((key) => key.startsWith('$templateId|'));
    unawaited(_persistDismissals());

    final result =
        await _templateRepo.updateTemplateActiveDays(templateId, days);
    result.fold(
      onSuccess: (_) => unawaited(_applyRecurringTemplates()),
      onFailure: (f) {
        _templates = original;
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  Future<void> stopTemplateRecurring(String templateId) async {
    await setTemplateRecurring(templateId, []);
  }

  Future<void> applyTemplateToDays(
      PlanTemplate template, List<int> dayIndices,) async {
    for (final dayIdx in dayIndices) {
      if (dayIdx >= 0 && dayIdx < _weekPlan.length) {
        await applyTemplate(template, dayIdx);
      }
    }
  }

  Future<void> applyTemplate(PlanTemplate template, [int? index]) async {
    final dayIdx = index ?? _selectedDayIndex;
    if (dayIdx < 0 || dayIdx >= _weekPlan.length) return;
    final dayPlan = _weekPlan[dayIdx];

    final newTasks = template.tasks
        .map(
          (t) => Task(
            id: const Uuid().v4(),
            title: t.title,
            startTime: t.startTime,
            endTime: t.endTime,
            type: t.type,
            priority: t.priority,
            energyLevel: t.energyLevel,
            estimatedCost: t.estimatedCost,
            description: t.description,
            sourceTemplateId: template.id,
          ),
        )
        .toList();

    if (newTasks.isEmpty) return;

    // Single optimistic update + one batched write instead of N round-trips.
    final originalPlan = List<DayPlan>.from(_weekPlan);
    final mergedTasks = List<Task>.from(dayPlan.tasks)..addAll(newTasks);
    _weekPlan[dayIdx] = dayPlan.copyWith(tasks: mergedTasks);
    notifyListeners();

    final result = await _scheduleRepo.addTasksToDate(dayPlan.date, newTasks);
    result.fold(
      onSuccess: (_) => _logger.debug(
        'Applied template ${template.id} (${newTasks.length} tasks)',
      ),
      onFailure: (f) {
        _weekPlan = originalPlan;
        _errorMessage = f.message;
        notifyListeners();
      },
    );
  }

  Future<void> _applyRecurringTemplates() async {
    final recurring = _templates.where((t) => t.isRecurring).toList();
    for (final tmpl in recurring) {
      for (int i = 0; i < _weekPlan.length; i++) {
        final weekday = _weekPlan[i].date.weekday - 1; // 0-indexed Mon=0
        if (tmpl.activeDays.contains(weekday)) {
          // Respect a user's deletion of this template's instance for the day.
          if (_dismissedRecurring
              .contains(_dismissalKey(tmpl.id, _weekPlan[i].date))) {
            continue;
          }
          final alreadyApplied =
              _weekPlan[i].tasks.any((t) => t.sourceTemplateId == tmpl.id);
          if (!alreadyApplied) {
            await applyTemplate(tmpl, i);
          }
        }
      }
    }
  }

  void flushState() {
    _logger.info('Flushing state on window close');
    // Implement any final persistence if needed
  }
}
