import '../local/app_database.dart';

abstract class TodoRepository {
  Future<List<TodoItem>> loadTodos();
  Stream<List<TodoItem>> watchTodos();
  Stream<List<TodoItem>> watchByType(String type);
  Future<TodoItem> addTodo(String title, {String description = ''});
  Future<TodoItem> addTimer(String title,
      {String description = '',
      int durationMinutes = 25,
      String audioFilePath = ''});
  Future<TodoItem> addList(String title,
      {String description = '', String checklistJson = '[]'});
  Future<bool> updateTodo(TodoItem todo);
  Future<void> deleteTodo(String id);
}

