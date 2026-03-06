import '../local/app_database.dart';

abstract class TodoRepository {
  Future<List<TodoItem>> loadTodos();
  Stream<List<TodoItem>> watchTodos();
  Future<TodoItem> addTodo(String title, {String description = ''});
  Future<bool> updateTodo(TodoItem todo);
  Future<void> deleteTodo(String id);
}
