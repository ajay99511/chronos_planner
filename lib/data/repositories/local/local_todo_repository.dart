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
  Stream<List<TodoItem>> watchByType(String type) {
    return _todoItemDao.watchByType(type);
  }

  @override
  Future<TodoItem> addTodo(String title, {String description = ''}) async {
    final newId = _uuid.v4();
    final companion = TodoItemsCompanion.insert(
      id: newId,
      title: title,
      description: Value(description),
      createdAt: Value(DateTime.now()),
      itemType: const Value('note'),
    );
    await _todoItemDao.insertTodo(companion);
    final items = await _todoItemDao.getAllTodos();
    return items.firstWhere((item) => item.id == newId);
  }

  @override
  Future<TodoItem> addTimer(String title,
      {String description = '',
      int durationMinutes = 25,
      String audioFilePath = ''}) async {
    final newId = _uuid.v4();
    final companion = TodoItemsCompanion.insert(
      id: newId,
      title: title,
      description: Value(description),
      createdAt: Value(DateTime.now()),
      itemType: const Value('timer'),
      durationMinutes: Value(durationMinutes),
      audioFilePath: Value(audioFilePath),
    );
    await _todoItemDao.insertTodo(companion);
    final items = await _todoItemDao.getAllTodos();
    return items.firstWhere((item) => item.id == newId);
  }

  @override
  Future<TodoItem> addList(String title,
      {String description = '', String checklistJson = '[]'}) async {
    final newId = _uuid.v4();
    final companion = TodoItemsCompanion.insert(
      id: newId,
      title: title,
      description: Value(description),
      createdAt: Value(DateTime.now()),
      itemType: const Value('list'),
      checklistJson: Value(checklistJson),
    );
    await _todoItemDao.insertTodo(companion);
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

