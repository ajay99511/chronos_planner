import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/todo_item_model.dart';

/// Abstract interface for todo item operations.
abstract class TodoRepository {
  /// Load all todo items.
  Future<Result<List<TodoItem>>> loadTodos();

  /// Watch all todo items (reactive).
  Stream<List<TodoItem>> watchTodos();

  /// Watch todo items by type.
  Stream<List<TodoItem>> watchByType(TodoItemType type);

  /// Add a new todo item.
  Future<Result<void>> addTodo(TodoItem todo);

  /// Update an existing todo item.
  Future<Result<void>> updateTodo(TodoItem todo);

  /// Delete a todo item.
  Future<Result<void>> deleteTodo(String id);
}
