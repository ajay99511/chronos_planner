import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/models/day_plan_model.dart';
import '../data/models/plan_template_model.dart';
import '../data/models/task_model.dart';

/// Undo action types for the undo stack.
enum _UndoType { deleteTask, clearDay }

class _UndoAction {
  final _UndoType type;
  final int dayIndex;
  final Task? task;
  final List<Task>? tasks;

  _UndoAction(
      {required this.type, required this.dayIndex, this.task, this.tasks});
}

class ScheduleProvider extends ChangeNotifier {
  List<DayPlan> _weekPlan = [];
  List<PlanTemplate> _templates = [];
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  final List<_UndoAction> _undoStack = [];

  List<DayPlan> get weekPlan => _weekPlan;
  List<PlanTemplate> get templates => _templates;
  int get selectedDayIndex => _selectedDayIndex;
  DayPlan get selectedDay => _weekPlan.isNotEmpty
      ? _weekPlan[_selectedDayIndex]
      : DayPlan(
          id: 'dummy',
          dateStr: '',
          dayOfWeek: '',
          date: DateTime.now(),
          tasks: []);
  bool get isLoading => _isLoading;
  bool get canUndo => _undoStack.isNotEmpty;

  ScheduleProvider() {
    _loadData();
  }

  void _initializeWeek() {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // Mon=1, Sun=7
    final monday = now.subtract(Duration(days: currentWeekday - 1));

    _weekPlan = List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      return DayPlan(
        id: 'day-$index',
        dateStr: DateFormat('MMM d').format(date),
        dayOfWeek: DateFormat('E').format(date),
        date: date,
        tasks: [],
      );
    });

    _selectedDayIndex = currentWeekday - 1;
    if (_selectedDayIndex < 0) _selectedDayIndex = 0;
    if (_selectedDayIndex > 6) _selectedDayIndex = 6;
  }

  /// Checks if the saved week data is stale (belongs to a different week).
  /// Compares the Monday of the saved week to the Monday of the current week.
  bool _isWeekStale(List<DayPlan> savedWeek) {
    if (savedWeek.isEmpty) return true;

    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final savedMonday = savedWeek.first.date;

    // Compare just dates (ignore time)
    return currentMonday.year != savedMonday.year ||
        currentMonday.month != savedMonday.month ||
        currentMonday.day != savedMonday.day;
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      final weekJson = prefs.getString('chronos-week');
      if (weekJson != null) {
        final List<dynamic> decoded = jsonDecode(weekJson);
        final savedWeek = decoded.map((e) => DayPlan.fromJson(e)).toList();

        if (_isWeekStale(savedWeek)) {
          // Week is from a previous week — start fresh
          _initializeWeek();
          _saveWeek();
        } else {
          _weekPlan = savedWeek;
        }
      } else {
        _initializeWeek();
      }

      final templatesJson = prefs.getString('chronos-templates');
      if (templatesJson != null) {
        final List<dynamic> decoded = jsonDecode(templatesJson);
        _templates = decoded.map((e) => PlanTemplate.fromJson(e)).toList();
      } else {
        _templates = [
          PlanTemplate(
              id: 't1',
              name: 'Deep Work Friday',
              description:
                  'Focus heavy schedule optimized for coding flow state.',
              tasks: [
                Task(
                    id: '1',
                    title: 'Deep Work Block 1',
                    startTime: '08:00',
                    endTime: '12:00',
                    type: TaskType.work,
                    description: 'Core feature implementation'),
                Task(
                    id: '2',
                    title: 'Lunch & Walk',
                    startTime: '12:00',
                    endTime: '13:00',
                    type: TaskType.health,
                    description: 'Disconnect completely'),
              ]),
          PlanTemplate(
              id: 't2',
              name: 'Lazy Sunday',
              description: 'Recovery and low-stress activities.',
              tasks: [
                Task(
                    id: '3',
                    title: 'Late Breakfast',
                    startTime: '10:00',
                    endTime: '11:00',
                    type: TaskType.personal,
                    description: 'Pancakes!'),
                Task(
                    id: '4',
                    title: 'Reading',
                    startTime: '11:00',
                    endTime: '13:00',
                    type: TaskType.leisure,
                    description: 'Fiction novel'),
              ]),
        ];
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      _initializeWeek();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_weekPlan.map((e) => e.toJson()).toList());
    await prefs.setString('chronos-week', data);
    notifyListeners();
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_templates.map((e) => e.toJson()).toList());
    await prefs.setString('chronos-templates', data);
    notifyListeners();
  }

  void selectDay(int index) {
    _selectedDayIndex = index;
    notifyListeners();
  }

  /// Validates that start time is before end time.
  /// Returns an error message if invalid, null if valid.
  String? validateTimeRange(String startTime, String endTime) {
    try {
      final s = startTime.split(':').map(int.parse).toList();
      final e = endTime.split(':').map(int.parse).toList();
      final startMinutes = s[0] * 60 + s[1];
      final endMinutes = e[0] * 60 + e[1];
      if (endMinutes <= startMinutes) {
        return 'End time must be after start time';
      }
      return null;
    } catch (e) {
      return 'Invalid time format';
    }
  }

  void addTask(Task task) {
    if (_weekPlan.isEmpty) return;
    _weekPlan[_selectedDayIndex].tasks.add(task);
    _weekPlan[_selectedDayIndex]
        .tasks
        .sort((a, b) => a.startTime.compareTo(b.startTime));
    _saveWeek();
  }

  /// Updates an existing task by replacing it with the updated version.
  void updateTask(String taskId, Task updatedTask) {
    if (_weekPlan.isEmpty) return;
    final tasks = _weekPlan[_selectedDayIndex].tasks;
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index] = updatedTask;
      tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
      _saveWeek();
    }
  }

  void toggleTaskComplete(String taskId) {
    if (_weekPlan.isEmpty) return;
    final task =
        _weekPlan[_selectedDayIndex].tasks.firstWhere((t) => t.id == taskId);
    task.completed = !task.completed;
    _saveWeek();
  }

  void deleteTask(String taskId) {
    if (_weekPlan.isEmpty) return;
    final tasks = _weekPlan[_selectedDayIndex].tasks;
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final removed = tasks.removeAt(taskIndex);
      // Push undo action
      _undoStack.add(_UndoAction(
        type: _UndoType.deleteTask,
        dayIndex: _selectedDayIndex,
        task: removed,
      ));
      _saveWeek();
    }
  }

  void clearDay() {
    if (_weekPlan.isEmpty) return;
    final clearedTasks = List<Task>.from(_weekPlan[_selectedDayIndex].tasks);
    if (clearedTasks.isNotEmpty) {
      _undoStack.add(_UndoAction(
        type: _UndoType.clearDay,
        dayIndex: _selectedDayIndex,
        tasks: clearedTasks,
      ));
    }
    _weekPlan[_selectedDayIndex].tasks.clear();
    _saveWeek();
  }

  /// Undoes the last destructive action (delete task or clear day).
  bool undo() {
    if (_undoStack.isEmpty) return false;
    final action = _undoStack.removeLast();

    switch (action.type) {
      case _UndoType.deleteTask:
        if (action.task != null && action.dayIndex < _weekPlan.length) {
          _weekPlan[action.dayIndex].tasks.add(action.task!);
          _weekPlan[action.dayIndex]
              .tasks
              .sort((a, b) => a.startTime.compareTo(b.startTime));
        }
        break;
      case _UndoType.clearDay:
        if (action.tasks != null && action.dayIndex < _weekPlan.length) {
          _weekPlan[action.dayIndex].tasks.addAll(action.tasks!);
          _weekPlan[action.dayIndex]
              .tasks
              .sort((a, b) => a.startTime.compareTo(b.startTime));
        }
        break;
    }

    _saveWeek();
    return true;
  }

  void applyTemplate(PlanTemplate template) {
    if (_weekPlan.isEmpty) return;

    final newTasks = template.tasks
        .map((t) => Task(
              id: const Uuid().v4(),
              title: t.title,
              startTime: t.startTime,
              endTime: t.endTime,
              type: t.type,
              priority: t.priority,
              description: t.description,
            ))
        .toList();

    _weekPlan[_selectedDayIndex].tasks.addAll(newTasks);
    _weekPlan[_selectedDayIndex]
        .tasks
        .sort((a, b) => a.startTime.compareTo(b.startTime));
    _saveWeek();
  }

  void addTemplate(PlanTemplate template) {
    _templates.add(template);
    _saveTemplates();
  }

  void removeTemplate(String id) {
    _templates.removeWhere((t) => t.id == id);
    _saveTemplates();
  }

  void saveCurrentDayAsTemplate(String name, String description) {
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

    addTemplate(template);
  }

  // Analytics Getters
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
      return (endH - startH).clamp(0, 24);
    } catch (e) {
      return 0;
    }
  }
}
