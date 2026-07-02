import 'dart:convert';
import 'package:drift/drift.dart';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;
import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/local/daos/todo_item_dao.dart';
import 'package:chronosky/data/repositories/todo_repository.dart';

/// Drift-backed implementation of [TodoRepository].
class LocalTodoRepository implements TodoRepository {
  final TodoItemDao _todoItemDao;

  LocalTodoRepository(this._todoItemDao);

  Future<Result<T>> _wrap<T>(Future<T> Function() action) async {
    try {
      final value = await action();
      return Success(value);
    } on DriftWrappedException catch (e) {
      return Failure(
          DatabaseFailure('Database operation failed', e.toString()),);
    } on Exception catch (e) {
      return Failure(UnknownFailure('Unexpected error', e.toString()));
    }
  }

  @override
  Future<Result<List<domain.TodoItem>>> loadTodos() {
    return _wrap(() async {
      final dbItems = await _todoItemDao.getAllTodos();
      return dbItems.map(_dbTodoToModel).toList();
    });
  }

  @override
  Stream<List<domain.TodoItem>> watchTodos() {
    return _todoItemDao
        .watchAllTodos()
        .map((list) => list.map(_dbTodoToModel).toList());
  }

  @override
  Stream<List<domain.TodoItem>> watchByType(domain.TodoItemType type) {
    return _todoItemDao
        .watchByType(type.name)
        .map((list) => list.map(_dbTodoToModel).toList());
  }

  @override
  Future<Result<void>> addTodo(domain.TodoItem todo) {
    return _wrap(() async {
      // Validate title 1-200 chars as per Task 5.4
      if (todo.title.isEmpty || todo.title.length > 200) {
        throw Exception('Invalid title length');
      }

      await _todoItemDao.insertTodo(_modelTodoToCompanion(todo));
    });
  }

  @override
  Future<Result<void>> updateTodo(domain.TodoItem todo) {
    return _wrap(() async {
      await _todoItemDao.db
          .update(_todoItemDao.todoItems)
          .replace(_modelTodoToDataClass(todo));
    });
  }

  @override
  Future<Result<void>> deleteTodo(String id) {
    return _wrap(() async {
      await _todoItemDao.deleteTodoById(id);
    });
  }

  // ── Mappers ───────────────────────────────────

  domain.TodoItem _dbTodoToModel(TodoItem dbTodo) {
    List<dynamic> decodedChecklist = [];
    if (dbTodo.checklistJson.isNotEmpty) {
      try {
        decodedChecklist = jsonDecode(dbTodo.checklistJson) as List<dynamic>;
      } catch (e) {
        // Fallback to empty if corrupted
        decodedChecklist = [];
      }
    }
    return domain.TodoItem(
      id: dbTodo.id,
      title: dbTodo.title,
      description: dbTodo.description,
      completed: dbTodo.completed,
      createdAt: dbTodo.createdAt,
      updatedAt: dbTodo.updatedAt,
      itemType: domain.TodoItemType.values.firstWhere(
        (e) => e.name == dbTodo.itemType,
        orElse: () => domain.TodoItemType.note,
      ),
      durationMinutes: dbTodo.durationMinutes,
      checklist: decodedChecklist
          .map((i) => domain.ChecklistItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      audioFilePath: dbTodo.audioFilePath,
    );
  }

  TodoItemsCompanion _modelTodoToCompanion(domain.TodoItem todo) {
    return TodoItemsCompanion.insert(
      id: todo.id,
      title: todo.title,
      description: Value(todo.description),
      completed: Value(todo.completed),
      createdAt: Value(todo.createdAt),
      updatedAt: Value(todo.updatedAt),
      itemType: Value(todo.itemType.name),
      durationMinutes: Value(todo.durationMinutes),
      checklistJson:
          Value(jsonEncode(todo.checklist.map((i) => i.toJson()).toList())),
      audioFilePath: Value(todo.audioFilePath),
    );
  }

  TodoItem _modelTodoToDataClass(domain.TodoItem todo) {
    return TodoItem(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      completed: todo.completed,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
      itemType: todo.itemType.name,
      durationMinutes: todo.durationMinutes,
      checklistJson: jsonEncode(todo.checklist.map((i) => i.toJson()).toList()),
      audioFilePath: todo.audioFilePath,
    );
  }
}
