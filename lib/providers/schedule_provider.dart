import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/models/day_plan_model.dart';
import '../data/models/plan_template_model.dart';
import '../data/models/task_model.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/template_repository.dart';
import '../data/repositories/preference_repository.dart';

/// Undo action types for the undo stack.
/// 
/// Tracks what was deleted for potential restoration.
enum _UndoType { deleteTask, clearDay }

/// Internal class representing an undoable action.
/// 
/// Stored in [_undoStack] for later reversal.
class _UndoAction {
  final _UndoType type;
  final int dayIndex;
  final Task? task;
  final List<Task>? tasks;

  _UndoAction(
      {required this.type, required this.dayIndex, this.task, this.tasks});
}

/// Sort order for task lists.
enum SortOrder { asc, desc }

/// Central state management for weekly schedule, templates, and analytics.
/// 
/// ## Responsibilities:
/// - Manage rolling 7-day schedule (CRUD operations)
/// - Handle template library and recurring schedules
/// - Provide analytics metrics (efficiency, focus hours, distribution)
/// - Undo/redo support for deletions
/// - Sort order persistence
/// 
/// ## Architecture:
/// - Extends [ChangeNotifier] for Flutter reactivity
/// - Depends on repository interfaces (not concrete implementations)
/// - Optimistic UI updates followed by persistence
/// 
/// ## State Flow:
/// ```
/// Constructor → _loadData() → Load from repos → Notify listeners
///     ↓
/// User action → Update state → Notify → Persist to repo
/// ```
/// 
/// ## Usage:
/// ```dart
/// // Access in widget
/// final provider = Provider.of<ScheduleProvider>(context);
/// 
/// // Read state
/// final tasks = provider.selectedDay.tasks;
/// final efficiency = provider.efficiency;
/// 
/// // Modify
/// provider.addTask(task);
/// provider.toggleTaskComplete(taskId);
/// ```
/// 
/// ## Dependencies:
/// - [ScheduleRepository]: Day plans + tasks
/// - [TemplateRepository]: Plan templates
/// - [PreferenceRepository]: Sort order persistence
class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _scheduleRepo;
  final TemplateRepository _templateRepo;
  final PreferenceRepository _prefRepo;

  List<DayPlan> _weekPlan = [];
  List<PlanTemplate> _templates = [];
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  final List<_UndoAction> _undoStack = [];
  SortOrder _sortOrder = SortOrder.asc;

  /// Rolling 7-day schedule starting from today.
  List<DayPlan> get weekPlan => _weekPlan;
  
  /// Saved plan templates.
  List<PlanTemplate> get templates => _templates;
  
  /// Currently selected day index (0-6).
  int get selectedDayIndex => _selectedDayIndex;
  
  /// Currently selected day plan (computed from [selectedDayIndex]).
  DayPlan get selectedDay => _weekPlan.isNotEmpty
      ? _weekPlan[_selectedDayIndex]
      : DayPlan(
          id: 'dummy',
          dateStr: '',
          dayOfWeek: '',
          date: DateTime.now(),
          tasks: []);
  
  /// Loading state indicator.
  bool get isLoading => _isLoading;
  
  /// Whether undo is available (stack not empty).
  bool get canUndo => _undoStack.isNotEmpty;
  
  /// Current task sort order (ascending/descending by time).
  SortOrder get sortOrder => _sortOrder;

  ScheduleProvider({
    required ScheduleRepository scheduleRepo,
    required TemplateRepository templateRepo,
    required PreferenceRepository prefRepo,
  })  : _scheduleRepo = scheduleRepo,
        _templateRepo = templateRepo,
        _prefRepo = prefRepo {
    _loadData();
  }

  // ─── Data Loading ─────────────────────────────

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load rolling 7-day plan (Today + 6)
      _weekPlan = await _scheduleRepo.getUpcomingDays(7);

      // Always select Today (index 0)
      _selectedDayIndex = 0;

      // Load templates
      _templates = await _templateRepo.getAllTemplates();

      // If no templates exist, seed defaults
      if (_templates.isEmpty) {
        await _seedDefaultTemplates();
      }

      // Load sort order
      final savedSort = await _prefRepo.get('sort_order');
      _sortOrder = savedSort == 'desc' ? SortOrder.desc : SortOrder.asc;

      // Auto-apply recurring templates to new days
      await _applyRecurringTemplates();
    } catch (e) {
      debugPrint("Error loading data: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _seedDefaultTemplates() async {
    final defaults = [
      PlanTemplate(
        id: const Uuid().v4(),
        name: 'Deep Work Friday',
        description: 'Focus heavy schedule optimized for coding flow state.',
        tasks: [
          Task(
              id: const Uuid().v4(),
              title: 'Deep Work Block 1',
              startTime: '08:00',
              endTime: '12:00',
              type: TaskType.work,
              description: 'Core feature implementation'),
          Task(
              id: const Uuid().v4(),
              title: 'Lunch & Walk',
              startTime: '12:00',
              endTime: '13:00',
              type: TaskType.health,
              description: 'Disconnect completely'),
        ],
      ),
      PlanTemplate(
        id: const Uuid().v4(),
        name: 'Lazy Sunday',
        description: 'Recovery and low-stress activities.',
        tasks: [
          Task(
              id: const Uuid().v4(),
              title: 'Late Breakfast',
              startTime: '10:00',
              endTime: '11:00',
              type: TaskType.personal,
              description: 'Pancakes!'),
          Task(
              id: const Uuid().v4(),
              title: 'Reading',
              startTime: '11:00',
              endTime: '13:00',
              type: TaskType.leisure,
              description: 'Fiction novel'),
        ],
      ),
    ];

    for (final tmpl in defaults) {
      await _templateRepo.addTemplate(tmpl);
    }
    _templates = defaults;
  }

  // ─── Day Selection ────────────────────────────

  void selectDay(int index) {
    _selectedDayIndex = index;
    notifyListeners();
  }

  // ─── Sort Order ───────────────────────────────

  void toggleSortOrder() async {
    _sortOrder = _sortOrder == SortOrder.asc ? SortOrder.desc : SortOrder.asc;
    await _prefRepo.set(
        'sort_order', _sortOrder == SortOrder.desc ? 'desc' : 'asc');
    notifyListeners();
  }

  /// Returns a sorted copy of the tasks for the given day plan.
  List<Task> getSortedTasks(DayPlan dayPlan) {
    final tasks = List<Task>.from(dayPlan.tasks);
    tasks.sort((a, b) => _sortOrder == SortOrder.asc
        ? a.startTime.compareTo(b.startTime)
        : b.startTime.compareTo(a.startTime));
    return tasks;
  }

  // ─── Time Validation ──────────────────────────

  String? validateTimeRange(String startTime, String endTime) {
    try {
      final s = startTime.split(':').map(int.parse).toList();
      final e = endTime.split(':').map(int.parse).toList();
      final startMinutes = s[0] * 60 + s[1];
      final endMinutes = e[0] * 60 + e[1];
      // Only reject if start and end are identical
      if (startMinutes == endMinutes) {
        return 'End time must differ from start time';
      }
      // Overnight ranges (e.g. 22:00–01:00) are valid
      return null;
    } catch (e) {
      return 'Invalid time format';
    }
  }

  // ─── Schedule Task CRUD ───────────────────────

  void addTask(Task task, [DateTime? date]) async {
    // If no date provided, default to currently selected day
    final targetDate = date ?? selectedDay.date;

    // Check if target date matches any currently loaded day
    final existingPlanIndex = _weekPlan.indexWhere((p) =>
        p.date.year == targetDate.year &&
        p.date.month == targetDate.month &&
        p.date.day == targetDate.day);

    if (existingPlanIndex != -1) {
      // Optimistic update if visible
      final dayPlan = _weekPlan[existingPlanIndex];
      dayPlan.tasks.add(task);
      dayPlan.tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
      notifyListeners();
    }

    // Always persist to DB (handles finding/creating day plan)
    await _scheduleRepo.addTaskToDate(targetDate, task);
  }

  void updateTask(String taskId, Task updatedTask) async {
    if (_weekPlan.isEmpty) return;
    final dayPlan = _weekPlan[_selectedDayIndex];
    final index = dayPlan.tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      dayPlan.tasks[index] = updatedTask;
      dayPlan.tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
      notifyListeners();
      await _scheduleRepo.updateTask(dayPlan.id, taskId, updatedTask);
    }
  }

  void toggleTaskComplete(String taskId) async {
    if (_weekPlan.isEmpty) return;
    final dayPlan = _weekPlan[_selectedDayIndex];
    final task = dayPlan.tasks.firstWhere((t) => t.id == taskId);
    task.completed = !task.completed;
    notifyListeners();
    await _scheduleRepo.updateTask(dayPlan.id, taskId, task);
  }

  void deleteTask(String taskId) async {
    if (_weekPlan.isEmpty) return;
    final dayPlan = _weekPlan[_selectedDayIndex];
    final taskIndex = dayPlan.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final removed = dayPlan.tasks.removeAt(taskIndex);
      _undoStack.add(_UndoAction(
        type: _UndoType.deleteTask,
        dayIndex: _selectedDayIndex,
        task: removed,
      ));
      notifyListeners();
      await _scheduleRepo.deleteTask(dayPlan.id, taskId);
    }
  }

  void clearDay() async {
    if (_weekPlan.isEmpty) return;
    final dayPlan = _weekPlan[_selectedDayIndex];
    final clearedTasks = List<Task>.from(dayPlan.tasks);
    if (clearedTasks.isNotEmpty) {
      _undoStack.add(_UndoAction(
        type: _UndoType.clearDay,
        dayIndex: _selectedDayIndex,
        tasks: clearedTasks,
      ));
    }
    dayPlan.tasks.clear();
    notifyListeners();
    await _scheduleRepo.clearDay(dayPlan.id);
  }

  bool undo() {
    if (_undoStack.isEmpty) return false;
    final action = _undoStack.removeLast();

    switch (action.type) {
      case _UndoType.deleteTask:
        if (action.task != null && action.dayIndex < _weekPlan.length) {
          final dayPlan = _weekPlan[action.dayIndex];
          dayPlan.tasks.add(action.task!);
          dayPlan.tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
          notifyListeners();
          _scheduleRepo.addTask(dayPlan.id, action.task!);
        }
        break;
      case _UndoType.clearDay:
        if (action.tasks != null && action.dayIndex < _weekPlan.length) {
          final dayPlan = _weekPlan[action.dayIndex];
          dayPlan.tasks.addAll(action.tasks!);
          dayPlan.tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
          notifyListeners();
          _scheduleRepo.saveDayPlan(dayPlan);
        }
        break;
    }

    return true;
  }

  // ─── Template Operations ──────────────────────

  void applyTemplate(PlanTemplate template) {
    if (_weekPlan.isEmpty) return;
    _applyTemplateToIndex(template, _selectedDayIndex);
  }

  void applyTemplateToDay(PlanTemplate template, int dayIndex) {
    if (_weekPlan.isEmpty || dayIndex < 0 || dayIndex >= _weekPlan.length) {
      return;
    }
    _applyTemplateToIndex(template, dayIndex);
  }

  void applyTemplateToDays(PlanTemplate template, List<int> dayIndices) {
    if (_weekPlan.isEmpty) return;
    for (final idx in dayIndices) {
      if (idx >= 0 && idx < _weekPlan.length) {
        _applyTemplateToIndex(template, idx);
      }
    }
  }

  void _applyTemplateToIndex(PlanTemplate template, int dayIndex,
      {String sourceTemplateId = ''}) {
    final dayPlan = _weekPlan[dayIndex];
    final newTasks = template.tasks
        .map((t) => Task(
              id: const Uuid().v4(),
              title: t.title,
              startTime: t.startTime,
              endTime: t.endTime,
              type: t.type,
              priority: t.priority,
              description: t.description,
              sourceTemplateId: sourceTemplateId,
            ))
        .toList();

    dayPlan.tasks.addAll(newTasks);
    dayPlan.tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    notifyListeners();
    _scheduleRepo.saveDayPlan(dayPlan);
  }

  /// Set a template to recur on specific weekdays.
  /// dayIndices: 0=Monday, 1=Tuesday, ..., 6=Sunday.
  void setTemplateRecurring(String templateId, List<int> days) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index == -1) return;
    _templates[index] = _templates[index].copyWith(activeDays: days);
    notifyListeners();
    await _templateRepo.updateTemplateActiveDays(templateId, days);

    // Immediately apply to matching days in the current week
    for (int i = 0; i < _weekPlan.length; i++) {
      final weekday = _weekPlan[i].date.weekday - 1; // 0-indexed Mon=0
      if (days.contains(weekday)) {
        // Skip if already applied
        final alreadyApplied =
            _weekPlan[i].tasks.any((t) => t.sourceTemplateId == templateId);
        if (!alreadyApplied) {
          _applyTemplateToIndex(_templates[index], i,
              sourceTemplateId: templateId);
        }
      }
    }
  }

  /// Stop a template from recurring.
  void stopTemplateRecurring(String templateId) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index == -1) return;
    _templates[index] = _templates[index].copyWith(activeDays: []);
    notifyListeners();
    await _templateRepo.updateTemplateActiveDays(templateId, []);
  }

  /// Auto-apply recurring templates to new days that haven't received them.
  Future<void> _applyRecurringTemplates() async {
    final recurring = _templates.where((t) => t.isRecurring).toList();
    if (recurring.isEmpty) return;

    for (int i = 0; i < _weekPlan.length; i++) {
      final weekday = _weekPlan[i].date.weekday - 1; // 0-indexed Mon=0
      for (final tmpl in recurring) {
        if (tmpl.activeDays.contains(weekday)) {
          // Check if this template was already applied to this day
          final alreadyApplied =
              _weekPlan[i].tasks.any((t) => t.sourceTemplateId == tmpl.id);
          if (!alreadyApplied) {
            _applyTemplateToIndex(tmpl, i, sourceTemplateId: tmpl.id);
          }
        }
      }
    }
  }

  void addTemplate(PlanTemplate template) async {
    _templates.add(template);
    notifyListeners();
    await _templateRepo.addTemplate(template);
  }

  void removeTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
    await _templateRepo.deleteTemplate(id);
  }

  void updateTemplate(String templateId,
      {String? name, String? description}) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index == -1) return;
    _templates[index] = _templates[index].copyWith(
      name: name,
      description: description,
    );
    notifyListeners();
    await _templateRepo.updateTemplate(templateId,
        name: name, description: description);
  }

  // ─── Template Task CRUD ───────────────────────

  void addTaskToTemplate(String templateId, Task task) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index == -1) return;
    _templates[index].tasks.add(task);
    _templates[index].tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    notifyListeners();
    await _templateRepo.addTaskToTemplate(templateId, task);
  }

  void removeTaskFromTemplate(String templateId, String taskId) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index == -1) return;
    _templates[index].tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _templateRepo.removeTaskFromTemplate(templateId, taskId);
  }

  void updateTaskInTemplate(
      String templateId, String taskId, Task updatedTask) async {
    final tmplIndex = _templates.indexWhere((t) => t.id == templateId);
    if (tmplIndex == -1) return;
    final taskIndex =
        _templates[tmplIndex].tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;
    _templates[tmplIndex].tasks[taskIndex] = updatedTask;
    _templates[tmplIndex]
        .tasks
        .sort((a, b) => a.startTime.compareTo(b.startTime));
    notifyListeners();
    await _templateRepo.updateTaskInTemplate(templateId, taskId, updatedTask);
  }

  void saveCurrentDayAsTemplate(String name, String description) async {
    if (_weekPlan.isEmpty) return;
    final currentTasks = _weekPlan[_selectedDayIndex].tasks;
    final template = PlanTemplate(
      id: const Uuid().v4(),
      name: name,
      description: description,
      tasks: currentTasks
          .map((t) => Task(
                id: const Uuid().v4(),
                title: t.title,
                startTime: t.startTime,
                endTime: t.endTime,
                type: t.type,
                priority: t.priority,
                description: t.description,
                completed: false,
              ))
          .toList(),
    );
    _templates.add(template);
    notifyListeners();
    await _templateRepo.addTemplate(template);
  }

  // ─── Analytics ────────────────────────────────

  int get totalTasks => _weekPlan.fold(0, (sum, day) => sum + day.tasks.length);
  int get completedTasks => _weekPlan.fold(
      0, (sum, day) => sum + day.tasks.where((t) => t.completed).length);
  double get efficiency =>
      totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;

  double get totalFocusHours {
    double hours = 0;
    for (var day in _weekPlan) {
      for (var task in day.tasks) {
        hours += _calculateDuration(task.startTime, task.endTime);
      }
    }
    return hours;
  }

  Map<TaskType, double> get categoryDistribution {
    Map<TaskType, double> dist = {
      TaskType.work: 0,
      TaskType.personal: 0,
      TaskType.health: 0,
      TaskType.leisure: 0,
    };

    for (var day in _weekPlan) {
      for (var task in day.tasks) {
        dist[task.type] = (dist[task.type] ?? 0) +
            _calculateDuration(task.startTime, task.endTime);
      }
    }
    return dist;
  }

  double _calculateDuration(String start, String end) {
    try {
      final s = start.split(':').map(int.parse).toList();
      final e = end.split(':').map(int.parse).toList();
      double startH = s[0] + s[1] / 60.0;
      double endH = e[0] + e[1] / 60.0;
      // Handle overnight tasks (e.g. 22:00–01:00 = 3 hours)
      if (endH <= startH) endH += 24;
      return (endH - startH).clamp(0, 24);
    } catch (e) {
      return 0;
    }
  }
}
