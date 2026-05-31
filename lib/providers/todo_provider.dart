import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;
import 'package:chronosky/data/repositories/todo_repository.dart';

/// State management for standalone todo items (Notes, Timers, Lists).
class TodoProvider extends ChangeNotifier {
  final TodoRepository _repository;

  List<domain.TodoItem> _notes = [];
  List<domain.TodoItem> _timers = [];
  List<domain.TodoItem> _lists = [];
  String? _errorMessage;

  List<domain.TodoItem> get notes => _notes;
  List<domain.TodoItem> get timers => _timers;
  List<domain.TodoItem> get lists => _lists;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<domain.TodoItem>>? _notesSub;
  StreamSubscription<List<domain.TodoItem>>? _timersSub;
  StreamSubscription<List<domain.TodoItem>>? _listsSub;

  TodoProvider(this._repository) {
    _subscribe();
  }

  void _subscribe() {
    _notesSub?.cancel();
    _timersSub?.cancel();
    _listsSub?.cancel();

    _notesSub = _repository.watchByType(domain.TodoItemType.note).listen(
      (items) {
        _notes = items;
        notifyListeners();
      },
      onError: (e) => _handleStreamError('Notes', e),
    );

    _timersSub = _repository.watchByType(domain.TodoItemType.timer).listen(
      (items) {
        _timers = items;
        notifyListeners();
      },
      onError: (e) => _handleStreamError('Timers', e),
    );

    _listsSub = _repository.watchByType(domain.TodoItemType.list).listen(
      (items) {
        _lists = items;
        notifyListeners();
      },
      onError: (e) => _handleStreamError('Lists', e),
    );
  }

  void _handleStreamError(String type, dynamic error) {
    _errorMessage = 'Error loading $type: $error';
    notifyListeners();
    // Recovery: retry subscription after delay
    Future.delayed(const Duration(seconds: 5), _subscribe);
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    _timersSub?.cancel();
    _listsSub?.cancel();
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

  Future<void> addTodo(domain.TodoItem todo) => _handleResult(_repository.addTodo(todo));

  Future<void> addNote(String title, {String description = ''}) {
    return addTodo(domain.TodoItem(
      id: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      itemType: domain.TodoItemType.note,
    ),);
  }

  Future<void> addTimer(String title, {String description = '', int durationMinutes = 25, String audioFilePath = ''}) {
    return addTodo(domain.TodoItem(
      id: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      itemType: domain.TodoItemType.timer,
      durationMinutes: durationMinutes,
      audioFilePath: audioFilePath,
    ),);
  }

  Future<void> addList(String title, {String description = '', List<domain.ChecklistItem> checklist = const []}) {
    return addTodo(domain.TodoItem(
      id: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      itemType: domain.TodoItemType.list,
      checklist: checklist,
    ),);
  }

  Future<void> toggleTodo(domain.TodoItem todo) {
    return _handleResult(_repository.updateTodo(todo.copyWith(completed: !todo.completed)));
  }

  Future<void> updateTodo(domain.TodoItem todo) => _handleResult(_repository.updateTodo(todo));

  Future<void> deleteTodo(String id) => _handleResult(_repository.deleteTodo(id));
}
