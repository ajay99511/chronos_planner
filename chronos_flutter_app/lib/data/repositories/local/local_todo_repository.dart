import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../todo_repository.dart';
import '../../local/app_database.dart';
import '../../local/daos/todo_item_dao.dart';

class LocalTodoRepository implements TodoRepository {
  final TodoItemDao _todoItemDao;
  final _uuid = const Uuid();

  LocalTodoRepository(this._todoItemDao);

  @override
  Future<List<TodoItem>> loadTodos() {
    return _todoItemDao.getAllTodos();
  }

  @override
  Stream<List<TodoItem>> watchTodos() {
    return _todoItemDao.watchAllTodos();
  }

  @override
  Future<TodoItem> addTodo(String title, {String description = ''}) async {
    final newId = _uuid.v4();
    final companion = TodoItemsCompanion.insert(
      id: newId,
      title: title,
      description: Value(description),
      createdAt: Value(DateTime.now()),
    );
    await _todoItemDao.insertTodo(companion);
    // Fetch the inserted entity
    final items = await _todoItemDao.getAllTodos();
    return items.firstWhere((item) => item.id == newId);
  }

  @override
  Future<bool> updateTodo(TodoItem todo) {
    return _todoItemDao.updateTodo(todo);
  }

  @override
  Future<void> deleteTodo(String id) async {
    await _todoItemDao.deleteTodoById(id);
  }
}
