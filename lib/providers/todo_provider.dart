import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/local/app_database.dart';
import '../data/repositories/todo_repository.dart';

class TodoProvider extends ChangeNotifier {
  final TodoRepository _repository;

  List<TodoItem> _todos = [];
  List<TodoItem> get todos => _todos;

  StreamSubscription<List<TodoItem>>? _subscription;

  TodoProvider(this._repository) {
    _init();
  }

  void _init() {
    _subscription = _repository.watchTodos().listen((newTodos) {
      _todos = newTodos;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addTodo(String title, {String description = ''}) async {
    await _repository.addTodo(title, description: description);
  }

  Future<void> toggleTodo(TodoItem todo) async {
    final updated = todo.copyWith(completed: !todo.completed);
    await _repository.updateTodo(updated);
  }

  Future<void> updateTodoData(
      TodoItem todo, String title, String description) async {
    final updated = todo.copyWith(title: title, description: description);
    await _repository.updateTodo(updated);
  }

  Future<void> deleteTodo(String id) async {
    await _repository.deleteTodo(id);
  }
}
