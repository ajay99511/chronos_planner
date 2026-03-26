import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/local/app_database.dart';
import '../data/repositories/todo_repository.dart';

/// State management for standalone todo items (Notes, Timers, Lists).
///
/// Maintains separate filtered streams for each item type and exposes
/// type-specific creation methods. Uses reactive stream-based approach.
class TodoProvider extends ChangeNotifier {
  final TodoRepository _repository;

  List<TodoItem> _notes = [];
  List<TodoItem> _timers = [];
  List<TodoItem> _lists = [];

  List<TodoItem> get notes => _notes;
  List<TodoItem> get timers => _timers;
  List<TodoItem> get lists => _lists;

  StreamSubscription<List<TodoItem>>? _notesSub;
  StreamSubscription<List<TodoItem>>? _timersSub;
  StreamSubscription<List<TodoItem>>? _listsSub;

  TodoProvider(this._repository) {
    _init();
  }

  void _init() {
    _notesSub = _repository.watchByType('note').listen((items) {
      _notes = items;
      notifyListeners();
    });
    _timersSub = _repository.watchByType('timer').listen((items) {
      _timers = items;
      notifyListeners();
    });
    _listsSub = _repository.watchByType('list').listen((items) {
      _lists = items;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    _timersSub?.cancel();
    _listsSub?.cancel();
    super.dispose();
  }

  // ── Notes ──
  Future<void> addNote(String title, {String description = ''}) async {
    await _repository.addTodo(title, description: description);
  }

  // ── Timers ──
  Future<void> addTimer(String title,
      {String description = '',
      int durationMinutes = 25,
      String audioFilePath = ''}) async {
    await _repository.addTimer(title,
        description: description,
        durationMinutes: durationMinutes,
        audioFilePath: audioFilePath);
  }

  // ── Lists ──
  Future<void> addList(String title,
      {String description = '', String checklistJson = '[]'}) async {
    await _repository.addList(title,
        description: description, checklistJson: checklistJson);
  }

  // ── Shared ──
  Future<void> toggleTodo(TodoItem todo) async {
    final updated = todo.copyWith(completed: !todo.completed);
    await _repository.updateTodo(updated);
  }

  Future<void> updateTodoData(
      TodoItem todo, String title, String description) async {
    final updated = todo.copyWith(title: title, description: description);
    await _repository.updateTodo(updated);
  }

  Future<void> updateTodo(TodoItem todo) async {
    await _repository.updateTodo(todo);
  }

  Future<void> deleteTodo(String id) async {
    await _repository.deleteTodo(id);
  }
}

