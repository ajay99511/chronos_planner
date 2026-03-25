import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/local/app_database.dart';
import '../data/repositories/todo_repository.dart';

/// State management for standalone todo items.
/// 
/// Unlike [ScheduleProvider], this uses a reactive stream-based approach:
/// - Subscribes to database changes via [TodoRepository.watchTodos]
/// - Auto-updates UI on any database modification
/// - No optimistic updates (simpler pattern)
/// 
/// ## Responsibilities:
/// - CRUD operations for todo items
/// - Stream subscription management
/// - Change notification via [ChangeNotifier]
/// 
/// ## Lifecycle:
/// 1. Constructor: Inject repository, call [_init]
/// 2. [_init]: Subscribe to [watchTodos] stream
/// 3. Stream emits: Update [_todos], notify listeners
/// 4. Dispose: Cancel subscription
/// 
/// ## Usage:
/// ```dart
/// // Access
/// final provider = Provider.of<TodoProvider>(context);
/// 
/// // Read
/// final todos = provider.todos;
/// 
/// // Modify
/// await provider.addTodo('Buy milk');
/// await provider.toggleTodo(todo);
/// await provider.deleteTodo(id);
/// ```
/// 
/// Dependencies:
/// - [TodoRepository]: Data access abstraction
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
